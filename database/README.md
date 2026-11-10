# 数据库脚本

适用环境：腾讯云 CloudBase PostgreSQL（兼容 Supabase PostgREST 风格，使用 `auth.uid()` 与行级权限 RLS）。若你的环境不支持 `auth.uid()`，需要把 `votes.voter_uid`、`feedback.voter_uid` 的默认值改成触发器写入。

在云控制台的 SQL 编辑器中按顺序执行：

| 顺序 | 文件 | 作用 |
| --- | --- | --- |
| 00 | `00_schema.sql` | 建表、索引、村民「一点位一票」的部分唯一索引 |
| 01 | `01_policies.sql` | 开启 RLS，配置访客 / 编辑者权限与 `is_editor()` 函数 |
| 02 | `02_functions.sql` | 后台「清空重新投票」调用的 `reset_huamu_voting_data()` |
| 03 | `03_storage.sql` | 存储桶权限说明（**需在控制台配置或取消注释后执行**） |
| 04 | `04_seed.sql` | 可选：两个示例点位与作品，方便跑通流程 |

全部脚本可重复执行（`if not exists` / `drop policy if exists` / `on conflict`）。

## 建完之后还要做的三件事

1. **创建两个存储桶**：`demo-images`（公开读）、`demo-voice`（私有），权限见 `03_storage.sql` 末尾清单。桶名要与 `config.js` 中的 `buckets` 一致。
2. **登记编辑者**：在云控制台用「用户名 + 密码」创建账号，拿到用户 UID 后执行（UID 属于个人数据，不要写进仓库）：
   ```sql
   insert into public.editors (user_uid, note)
   values ('REPLACE_WITH_EDITOR_UID', '现场编辑者');
   ```
3. **设置走访问令**（可选）：执行 `04_seed.sql` 中被注释的那条 `update`，口令自行保管。

> 前端只使用 Publishable Key，不要在任何页面、脚本或 Issue 里放 `service_role` / 管理员密钥。安全边界完全由本目录的 RLS 策略决定，部署前务必逐条核对。
