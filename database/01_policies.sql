-- 花木共创 · 行级权限（RLS）
-- 适用：腾讯云 CloudBase PostgreSQL / 兼容 Supabase PostgREST 的环境
-- 角色约定：anon = 匿名访客，authenticated = 已登录账号，service_role 绕过 RLS。
-- 安全前提：所有前端请求都使用 Publishable Key，真正的边界是这里的策略，
--           切勿把 service_role 密钥写入前端。详见 docs/SECURITY.md。

-- 编辑者判定函数。security definer 用于避免 editors 表自身 RLS 造成递归。
create or replace function public.is_editor()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.editors e where e.user_uid = auth.uid()
  );
$$;

revoke all on function public.is_editor() from public;
grant execute on function public.is_editor() to anon, authenticated;

alter table public.villages  enable row level security;
alter table public.spots     enable row level security;
alter table public.works     enable row level security;
alter table public.votes     enable row level security;
alter table public.feedback  enable row level security;
alter table public.editors   enable row level security;

-- ---------- villages ----------
-- 注意：anon 可读整行，意味着 visit_passcode 也会被读到。
-- 这是当前版本「前端比对口令」的已知缺陷，加固方案见 docs/SECURITY.md。
drop policy if exists villages_public_read on public.villages;
create policy villages_public_read on public.villages
  for select to anon, authenticated using (true);

drop policy if exists villages_editor_write on public.villages;
create policy villages_editor_write on public.villages
  for all to authenticated
  using (public.is_editor())
  with check (public.is_editor());

-- ---------- editors ----------
-- 登录后的编辑者需要能查到自己的那一行，用于前端校验
drop policy if exists editors_read_self on public.editors;
create policy editors_read_self on public.editors
  for select to authenticated using (user_uid = auth.uid());

-- editors 表的增删请通过控制台 / service_role 完成，不开放前端写权限。

-- ---------- spots ----------
-- 访客只能看到开放点位；编辑者可看到全部（含已关闭点位）
drop policy if exists spots_public_read on public.spots;
create policy spots_public_read on public.spots
  for select to anon, authenticated
  using (is_open or public.is_editor());

drop policy if exists spots_editor_write on public.spots;
create policy spots_editor_write on public.spots
  for all to authenticated
  using (public.is_editor())
  with check (public.is_editor());

-- ---------- works ----------
drop policy if exists works_public_read on public.works;
create policy works_public_read on public.works
  for select to anon, authenticated using (true);

drop policy if exists works_editor_write on public.works;
create policy works_editor_write on public.works
  for all to authenticated
  using (public.is_editor())
  with check (public.is_editor());

-- ---------- votes ----------
-- 村民只能读自己的投票（用于判断「已投过」），编辑者可读全部用于统计
drop policy if exists votes_read_own on public.votes;
create policy votes_read_own on public.votes
  for select to anon, authenticated using (voter_uid = auth.uid());

drop policy if exists votes_read_editor on public.votes;
create policy votes_read_editor on public.votes
  for select to authenticated using (public.is_editor());

drop policy if exists votes_insert_self on public.votes;
create policy votes_insert_self on public.votes
  for insert to anon, authenticated
  with check (voter_uid = auth.uid());

-- 投票不开放前端 update / delete；改票或清票由编辑者通过后台的清空功能处理。

-- ---------- feedback ----------
drop policy if exists feedback_insert on public.feedback;
create policy feedback_insert on public.feedback
  for insert to anon, authenticated with check (true);

drop policy if exists feedback_read_editor on public.feedback;
create policy feedback_read_editor on public.feedback
  for select to authenticated using (public.is_editor());

-- 村民意见含录音，不对访客开放读取。
