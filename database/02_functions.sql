-- 花木共创 · 后台「清空重新投票」所用的数据库函数
-- 前端 admin.html 调用 db.rpc('reset_huamu_voting_data')，返回删除条数。

create or replace function public.reset_huamu_voting_data()
returns table (deleted_votes integer, deleted_feedback integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
  f_count integer;
begin
  -- 二次鉴权：即使有人直接调用 RPC，也必须是登记过的编辑者
  if not public.is_editor() then
    raise exception '只有已登记的编辑者可以清空投票数据';
  end if;

  delete from public.votes;
  get diagnostics v_count = row_count;

  delete from public.feedback;
  get diagnostics f_count = row_count;

  return query select v_count, f_count;
end;
$$;

revoke all on function public.reset_huamu_voting_data() from public;
grant execute on function public.reset_huamu_voting_data() to authenticated;

comment on function public.reset_huamu_voting_data() is
  '清空投票与村民意见，保留村庄、点位、作品与图片；语音文件由前端单独清理存储桶。';
