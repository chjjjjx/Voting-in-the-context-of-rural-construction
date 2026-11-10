# 安全说明

## 一、本次开源整理做了哪些脱敏

原页面里写死了真实云环境 ID 和一长串 Publishable Key（JWT）。复制成开源版本时已做如下处理：

| 处理项 | 结果 |
| --- | --- |
| 云环境 ID | 从两个页面移除，改为读取 `config.js`，仓库内只留 `YOUR_CLOUDBASE_ENV_ID` 占位 |
| Publishable Key（JWT） | 从两个页面移除，仓库内只留 `YOUR_CLOUDBASE_PUBLISHABLE_KEY` 占位 |
| 地域、村庄 ID、桶名、点位编号 | 抽成可配置项；默认值仅为通用标识，不含账号或项目私有信息 |
| 本地配置 | `config.js` 已加入 `.gitignore`，副本中的该文件也只是占位值 |
| 地图、作品图片、语音、投票记录、CSV | 仓库内一律不含，全部通过云端读取 |
| 个人信息 | 已扫描：无邮箱、手机号、IP、真实姓名、编辑者 UID、账号密码、走访问令 |
| 原始文件 | 保持不动，未修改、未删除 |

页面逻辑本身未做功能重构，只替换了配置来源、页面互链与少量品牌文案。

## 二、与既有线上部署隔离

### 仓库层面已经做到

- 两个页面里的真实环境 ID 与 Publishable Key 已彻底移除，全部改从 `config.js` 读取；仓库只保留 `YOUR_...` 占位值。
- `config.js` 不入库，副本中那份也只是占位值；页面启动前由 `assertConfig()` 校验，遇到占位值直接拒绝，**不向任何云端发起请求**。
- 示例村庄 ID 与桶名统一改为中性的 `demo-*`，不含既有部署的资源名；仓库也不含线上地址、账号、口令、UID 或真实数据。
- 结论：**clone 下来不配置就跑不起来；配置后只能连接配置者自己的环境。** 别人可以部署到自己那边，但拿不到连接既有站点的东西。

### 一个无法靠仓库解决的事实

任何公网静态页面都会把 `config.js` 下发给浏览器，访客按 F12 就能看到**该站点自己的**环境 ID 与 Publishable Key。Publishable Key 是客户端公开密钥，设计上就允许随前端下发，**它不是登录凭证，也不该被当作访问控制手段**。别人拿到它之后能做什么，完全由该环境的 RLS 策略、桶策略与编辑者白名单决定。

所以「别人不能登进我的网站用」要靠线上环境自身的配置保证，而不是靠开源仓库里删掉几行字符串。

### 线上环境核对清单

| 检查项 | 做法 |
| --- | --- |
| RLS 全部开启 | 执行 `database/01_policies.sql`，确认六张表都启用了行级权限 |
| 最小权限 | 访客只能读开放点位、写自己的投票/意见；点位、作品、村庄的写操作只对 `editors` 白名单开放 |
| 编辑者白名单 | `editors` 表里只有你自己的 UID；后台账号密码不外发；后台页面可放在非公开路径并叠加托管侧访问控制 |
| 桶权限 | 图片桶仅编辑者可上传/删除；语音桶私有，仅编辑者可读取、删除、生成签名 URL |
| 匿名登录 | 只用于投票与提交意见；需要防刷时加限流、验证码或现场签到核验 |
| 访问日志 | 检查是否有异常的写入、上传或登录来源 |

可用于核对的 SQL：

```sql
-- 1. 公开表是否全部开启 RLS
select relname, relrowsecurity
  from pg_class
 where relnamespace = 'public'::regnamespace and relkind = 'r'
 order by relname;

-- 2. 现有策略是否符合预期
select tablename, policyname, roles, cmd
  from pg_policies
 where schemaname = 'public'
 order by tablename, policyname;

-- 3. 编辑者白名单里有没有陌生账号
select user_uid, note, created_at from public.editors;
```

### 旧密钥的处理

如果写死真实环境 ID 与 Publishable Key 的**旧版 HTML** 曾经被上传、转发、提交到别处或发给过别人，仓库脱敏只保证「从这里拿不到」，**不能让已经散发出去的旧密钥失效**。此时应当：

1. 在云控制台轮换 / 重新生成 Publishable Key；
2. 更新线上站点自己的 `config.js`，确认旧页面已下线或不再被引用；
3. 检查旧密钥是否出现在其它仓库、网盘、聊天记录或公开网页中；
4. 复查访问日志，确认没有异常数据写入。

## 三、部署者必须知道的安全边界

1. **Publishable Key 会随前端下发，本来就是公开的**。它只能配合数据库 RLS 使用；`01_policies.sql` 才是真正的权限边界。请逐条核对策略后再对外开放。
2. **绝不把 `service_role` / 管理员密钥放进前端、注释、截图或 Issue**。这类密钥会绕过 RLS，一旦泄漏等同于数据库完全开放。
3. **`config.js` 不进仓库**。即使里面只有 Publishable Key，带上真实环境 ID 也会让陌生人连到你的环境、写入数据或被刷流量。
4. **RLS 必须开启**。若表建好了但没执行 `01_policies.sql`，PostgREST 默认策略可能导致数据无法读取或（在配置不当时）被任意读写。
5. **桶权限要收紧**：图片桶公开读但只允许编辑者上传；语音桶私有，仅编辑者可读取与删除，避免录音外泄。
6. **录音涉及个人信息**：现场采集前请明确告知村民用途、保存期限与删除方式，并在活动结束后清理。
7. **后台「清空」是破坏性操作**：`reset_huamu_voting_data()` 使用 `security definer`，请保留函数内的 `is_editor()` 校验，不要图方便去掉。

## 四、已知架构风险（未在本版本修复）

这些是原设计的取舍，公开部署前请评估：

| 风险 | 说明 | 建议 |
| --- | --- | --- |
| 走访问令由前端比对 | `index.html` 从 `villages` 表读出 `visit_passcode` 后在浏览器里比较，任何人都能从网络请求中看到口令 | 改为服务端 RPC 校验（下方给出方案） |
| 「一人一票」只认匿名 UID | 匿名登录的 UID 与浏览器会话绑定，清缓存 / 换设备 / 无痕窗口即可再次投票 | 需要严肃计票时接入实名、短信或现场签到核验 |
| 走访模式可无限投票 | 这是有意设计，票以 `vote_role = 'visitor'` 标记 | 统计时与村民票分开，或导出 CSV 后按角色筛选 |
| 无速率限制 | 投票与语音上传接口可被脚本刷量 | 在网关层加限流 / 验证码 |
| 前端可完全绕过 | 任何客户端校验都能被绕过，包括编辑者模式标记 | 所有写操作依赖 RLS 与 `editors` 白名单，不依赖 `sessionStorage` 里的角色标记 |
| 语音/图片 URL 可传播 | 拿到签名 URL 或公开 URL 的人可在有效期内访问文件 | 缩短签名有效期，活动结束清理语音桶 |

### 可选加固：把走访问令改成服务端校验

思路是把口令从可读的 `villages` 表移到不给前端读权限的私有表，并用 `security definer` 函数比对哈希：

```sql
create table if not exists public.village_secrets (
  village_id    text primary key references public.villages (id) on delete cascade,
  passcode_hash text not null
);
alter table public.village_secrets enable row level security;  -- 不建任何策略 = 前端不可读

-- 写入哈希（口令不落明文，也不进仓库）
-- insert into public.village_secrets (village_id, passcode_hash)
-- values ('demo-village', crypt('REPLACE_WITH_YOUR_PASSCODE', gen_salt('bf')));

create or replace function public.verify_visit_passcode(p_code text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  return exists (
    select 1 from public.village_secrets s
    where s.village_id = 'demo-village'
      and s.passcode_hash = crypt(p_code, s.passcode_hash)
  );
end $$;
revoke all on function public.verify_visit_passcode(text) from public;
grant execute on function public.verify_visit_passcode(text) to anon, authenticated;
```

然后把 `index.html` 中走访登录那段改成调用 RPC（不再读取口令字段）：

```js
const { data, error } = await cloudDb.rpc('verify_visit_passcode', { p_code: code });
if (error) throw cloudError(error, '无法校验走访口令');
if (!data) { alert('走访口令不正确'); return; }
```

同时可删除 `villages.visit_passcode` 列，并把 `01_policies.sql` 中 `villages_public_read` 的注释同步更新。这样前端永远拿不到口令本身。

## 五、推送到 GitHub 前的自查清单

- [ ] `git status` 里没有 `config.js`，也没有 `*.local.html`、备份文件
- [ ] 若用 GitHub 网页端拖拽上传，没有把 `config.js` 一起勾选进去（网页上传不保证遵守 `.gitignore`）
- [ ] 线上环境已按第二节核对 RLS、编辑者白名单与桶权限
- [ ] 若旧版页面曾公开过真实密钥，已在云控制台轮换 Publishable Key
- [ ] 全仓库搜索无真实环境 ID、无 `eyJ` 开头的 JWT、无 `service_role` 密钥
- [ ] 无编辑者账号、密码、UID、走访问令
- [ ] 无地图/作品图片、录音文件、投票导出 CSV、村民意见文本
- [ ] 历史提交里也没有上述内容；若曾提交过，先**轮换 Publishable Key** 并清理 Git 历史再公开
- [ ] 线上环境的 RLS、桶权限、编辑者白名单已按 `database/` 复核
- [ ] 已确认许可证状态（当前仓库**未指定许可证**，见 README 末尾）

## 六、发现问题怎么办

请不要在公开 Issue 里贴配置、密钥或真实数据。先用不含敏感信息的方式描述现象并联系仓库维护者；如涉及线上环境，第一时间在云控制台轮换密钥并检查访问日志。
