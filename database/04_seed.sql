-- 花木共创 · 可选示例数据（不含任何真实村庄、图片或个人信息）
-- 只想跑通流程时执行；已有数据的环境请勿执行。

insert into public.villages (id, name, visit_passcode)
values ('demo-village', '示例村庄', null)
on conflict (id) do nothing;

-- 走访问令不要写进仓库。部署后在控制台单独执行（把口令换成你自己的）：
-- update public.villages
--    set visit_passcode = 'REPLACE_WITH_YOUR_PASSCODE'
--  where id = 'demo-village';
-- 未设置口令时，前端「走访登录」会提示尚未配置。

-- 两个示例点位，各带三个候选作品；已存在点位时整段跳过，可重复执行
with new_spot as (
  insert into public.spots (village_id, name, x, y, sort_order)
  select 'demo-village', t.name, t.x, t.y, t.sort_order
  from (values
    ('示例点位一', 30.0000, 40.0000, 1),
    ('示例点位二', 65.0000, 60.0000, 2)
  ) as t(name, x, y, sort_order)
  where not exists (
    select 1 from public.spots s where s.village_id = 'demo-village'
  )
  returning id
)
insert into public.works (spot_id, title, sort_order)
select s.id, w.title, w.sort_order
from new_spot s
cross join (values ('作品一', 1), ('作品二', 2), ('作品三', 3)) as w(title, sort_order);

-- 地图图片由编辑者登录后，在页面点「上传地图」写入 villages.map_image_url。
-- 作品图片同样由编辑者在投票面板中点击卡片上传。
