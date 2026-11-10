-- 花木共创 · 数据表结构
-- 适用：腾讯云 CloudBase PostgreSQL / 兼容 Supabase PostgREST 的环境
-- 执行顺序：00 -> 01 -> 02 -> 03 -> 04（04 为可选示例数据）
-- 全部语句可重复执行（IF NOT EXISTS / IF EXISTS）。

create extension if not exists pgcrypto;

-- 村庄：一个环境可以放多个村庄，前端按 villageId 读取其中一个
create table if not exists public.villages (
  id              text primary key,
  name            text not null default '未命名村庄',
  map_image_url   text,
  visit_passcode  text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

comment on column public.villages.visit_passcode is
  '走访问令。当前版本由前端比对，仅用于现场引导，不是安全边界，见 docs/SECURITY.md';

-- 点位：x / y 是相对地图图片的百分比坐标（0-100）
create table if not exists public.spots (
  id          uuid primary key default gen_random_uuid(),
  village_id  text not null references public.villages (id) on delete cascade,
  name        text not null default '未命名点位',
  x           numeric(7,4) not null default 0 check (x between 0 and 100),
  y           numeric(7,4) not null default 0 check (y between 0 and 100),
  is_open     boolean not null default true,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 作品/候选方案：每个点位通常 3 个
create table if not exists public.works (
  id          uuid primary key default gen_random_uuid(),
  spot_id     uuid not null references public.spots (id) on delete cascade,
  title       text not null default '未命名作品',
  image_url   text,
  description text,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 投票：voter_uid 由匿名登录产生，vote_role 区分村民与走访人员
create table if not exists public.votes (
  id          uuid primary key default gen_random_uuid(),
  spot_id     uuid not null references public.spots (id) on delete cascade,
  work_id     uuid not null references public.works (id) on delete cascade,
  voter_uid   uuid not null default auth.uid(),
  vote_role   text not null default 'villager'
              check (vote_role in ('villager', 'visitor')),
  created_at  timestamptz not null default now()
);

comment on column public.votes.voter_uid is
  '默认取 auth.uid()。若你的环境没有 auth.uid()，请改用触发器写入当前用户。';

-- 关键：村民每点位限投一票，走访人员（vote_role = visitor）不受此约束。
-- 前端提示的「部分唯一索引」即指这条索引，请勿改成全表唯一约束。
create unique index if not exists votes_one_vote_per_villager
  on public.votes (spot_id, voter_uid)
  where vote_role <> 'visitor';

-- 村民意见：当前前端只写 voice_url；message 字段兼容文字意见与历史数据
create table if not exists public.feedback (
  id          uuid primary key default gen_random_uuid(),
  spot_id     uuid not null references public.spots (id) on delete cascade,
  voter_uid   uuid default auth.uid(),
  message     text,
  voice_url   text,
  created_at  timestamptz not null default now()
);

-- 编辑者白名单：只有登记在此表的账号才能进入后台、编辑点位、清空数据
create table if not exists public.editors (
  user_uid    uuid primary key,
  note        text,
  created_at  timestamptz not null default now()
);

create index if not exists spots_village_order_idx  on public.spots (village_id, sort_order);
create index if not exists works_spot_order_idx     on public.works (spot_id, sort_order);
create index if not exists votes_spot_work_idx      on public.votes (spot_id, work_id);
create index if not exists votes_voter_idx          on public.votes (voter_uid);
create index if not exists votes_created_idx        on public.votes (created_at desc);
create index if not exists feedback_spot_created_idx on public.feedback (spot_id, created_at desc);
