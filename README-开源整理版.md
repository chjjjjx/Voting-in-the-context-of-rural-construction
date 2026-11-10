# 花木共创 · 乡村地图点位投票

一个为乡村公共空间共创活动做的**地图点位投票网站**：把村庄地图铺在页面上，村民点击地图上的点位，浏览该点位的设计方案，投票并留下语音意见；编辑者在后台汇总票数、查看意见、导出 CSV，也可以一键清空数据重新开始。

纯静态前端（两个 HTML 页面 + 一个配置文件），数据放在腾讯云 CloudBase PostgreSQL，图片与语音放在 CloudBase 对象存储。无需构建、无需 Node.js，上传到静态网站托管即可运行。

> 说明：本文档为整理版说明（`README-开源整理版.md`），部署请以本文档与 `docs/DEPLOYMENT.md` 为准。
>
> 本项目从一个现场使用的版本整理而来。**仓库内不含任何真实环境 ID、密钥、地图、作品图片、录音或村民数据**，示例数据全部是占位内容。仓库是「参考实现 + 自行部署」：任何人都可以把它部署到自己的云环境，但无法用它连接任何已经部署好的站点。

## 功能

**村民端 `index.html`**

- 地图可拖拽、双指/滚轮缩放，点位按百分比坐标叠加，支持移动端横竖屏
- 点位名称自动避让排布，区域点位可聚合选择（如「林木园」「百果园」）
- 每个点位展示多个候选方案，支持大图预览与左右切换
- 匿名登录后投票，一点位限投一票；可录制语音意见并多次提交
- 适配浅色/深色系统主题，地图与投票面板响应式布局

**走访与编辑模式**

- 「走访登录」输入口令后进入走访人员模式，可无限次投票（票会标记 `vote_role = 'visitor'`）
- 编辑者登录后可在地图上新增/重命名/删除点位、上传地图与作品图片
- 删除点位会一并清理关联的投票、意见和存储文件

**后台 `admin.html`**

- 编辑者账号登录 + `editors` 白名单校验
- 按点位汇总票数、占比与作品缩略图，播放语音意见，导出 CSV
- 「清空重新投票」只删除投票与意见，保留地图、点位、作品与图片

## 目录结构

```
huamu-voting/
├── index.html              # 村民投票页（原 huamu-map-point-design-visitor-unlimited-vote.html）
├── admin.html              # 编辑者后台（原 records-dashboard-reset-with-work-thumbnails.html）
├── config.example.js       # 配置模板：入库，只有占位值
├── config.js               # 本地配置：占位值，已被 .gitignore 忽略，不入库
├── .gitignore
├── README-开源整理版.md   # 整理版说明文档
├── CHANGELOG.md
├── CONTRIBUTING.md
├── database/               # 建库、权限、存储桶、示例数据
│   ├── README.md           # 执行顺序与后续配置
│   ├── 00_schema.sql
│   ├── 01_policies.sql
│   ├── 02_functions.sql
│   ├── 03_storage.sql
│   └── 04_seed.sql
└── docs/
    ├── DEPLOYMENT.md       # 部署与验收清单
    └── SECURITY.md         # 脱敏说明、安全边界与已知风险
```

## 快速开始

1. **建库**：按 [`database/README.md`](database/README.md) 依次执行 5 个 SQL 脚本，创建两个存储桶并登记编辑者账号。
2. **配置**：复制 `config.example.js` 为 `config.js`，填入你自己的 CloudBase 环境 ID 与 Publishable Key。
   ```bash
   cp config.example.js config.js
   ```
   `config.js` 不会进入 Git；部署到静态托管时需要单独上传（见 [DEPLOYMENT.md](docs/DEPLOYMENT.md)）。若用 GitHub 网页端拖拽上传文件，请**不要勾选 `config.js`**——网页上传不一定遵守 `.gitignore`。
3. **部署**：把 `index.html`、`admin.html`、`config.js` 上传到支持 HTTPS 的静态网站托管根目录，村民访问 `/index.html`，后台访问 `/admin.html`。

本地预览：

```bash
python -m http.server 8080
# 浏览器打开 http://localhost:8080/index.html
```

> 麦克风录音要求 HTTPS 或 `localhost`。用 `file://` 直接双击打开页面时，CloudBase SDK 与登录通常无法正常工作，请用本地服务器或静态托管。

## 与线上部署隔离

**这个仓库不能用来访问任何已经部署好的网站。** 别人 clone 下来后：

- `config.js` 不在仓库里，模板 `config.example.js` 只有 `YOUR_...` 占位值。两个页面启动时会先校验配置，遇到占位值直接提示「尚未配置云端参数」，**不会向任何云端发起请求**。
- 仓库不含线上站点地址、环境 ID、Publishable Key、账号密码、走访问令、编辑者 UID、真实地图/图片/录音/投票数据；示例村庄 ID 与桶名都是中性的 `demo-*`。
- 想跑起来，必须自己建一个 CloudBase 环境，填自己的 `envId` / `publishableKey`，并按 `database/` 建库和桶。也就是：**可以部署到自己那边，连不到别人的部署。**

有一件事要分清：如果你已经把页面部署到公网，访客查看页面源码时**本来就能看到你那份 `config.js` 里的 Publishable Key**。它是客户端公开密钥，靠仓库是藏不住的，也不该靠它做鉴权。真正决定别人能不能越权「用你的网站」的是线上环境自身的权限配置：

1. 按 `database/01_policies.sql` 开启 RLS：访客只能读开放点位、只能写自己的投票与意见；修改点位/作品/村庄仅限 `editors` 白名单。
2. 后台入口不放进公开导航；编辑者账号与密码只在你自己手里，`editors` 表只登记你自己的 UID。
3. 桶权限收紧：图片桶仅编辑者可上传；语音桶私有，仅编辑者可读取与删除。
4. 匿名登录只用于投票与提交意见；需要防刷时加限流、验证码或现场签到核验。
5. 若整站不希望外部访问，在静态托管侧加访问控制（域名/IP 白名单、访问口令等），而不是依赖前端隐藏配置。

> 如果此前把写死真实密钥的旧版 HTML 上传、转发或提交到过别处，建议在云控制台**轮换 Publishable Key** 并清理那些公开副本。仓库脱敏只能保证「从这里拿不到」，无法让已经散发出去的旧密钥失效。详细清单见 [SECURITY.md](docs/SECURITY.md)。

## 配置说明

`config.js`（由 `config.example.js` 复制而来）提供以下字段，两个页面共用：

| 字段 | 说明 |
| --- | --- |
| `envId` | CloudBase 环境 ID |
| `publishableKey` | 客户端公开密钥（Publishable Key），**不是**管理员密钥 |
| `region` | 地域，默认 `ap-shanghai` |
| `villageId` | `villages` 表中的村庄主键，默认 `demo-village` |
| `buckets.images` | 图片桶名，默认 `demo-images` |
| `buckets.voice` | 语音桶名，默认 `demo-voice` |

未填写配置时页面会给出明确提示，而不是静默失败。任何情况下都**不要**把 `service_role` / 管理员密钥、编辑者账号密码、走访问令写进前端或提交到仓库。

## 三种角色

| 角色 | 进入方式 | 能做什么 |
| --- | --- | --- |
| 村民 | 打开页面自动匿名登录 | 浏览点位与方案、每点位投一票、多次提交语音意见 |
| 走访人员 | 点击「走访登录」输入口令 | 同村民，但可无限投票，票标记为 `visitor` |
| 编辑者 | 点击「编辑者登录」输入账号密码 | 编辑地图与点位、上传图片、查看后台、导出 CSV、清空数据 |

「走访问令」在当前版本由前端比对，**只是现场引导，不是安全边界**，详见 [SECURITY.md](docs/SECURITY.md)。

## 数据模型

| 表 | 用途 | 主要字段 |
| --- | --- | --- |
| `villages` | 村庄与地图 | `id`, `name`, `map_image_url`, `visit_passcode` |
| `spots` | 地图点位 | `village_id`, `name`, `x`, `y`, `is_open`, `sort_order` |
| `works` | 候选方案 | `spot_id`, `title`, `image_url`, `description`, `sort_order` |
| `votes` | 投票 | `spot_id`, `work_id`, `voter_uid`, `vote_role`, `created_at` |
| `feedback` | 村民意见 | `spot_id`, `message`, `voice_url`, `created_at` |
| `editors` | 编辑者白名单 | `user_uid` |

村民「一点位一票」依靠**部分唯一索引**实现：`(spot_id, voter_uid)` 唯一，但排除 `vote_role = 'visitor'` 的走访票。若改成普通唯一约束，走访模式会失效。

## 技术栈

- 原生 HTML / CSS / JavaScript，无框架、无构建步骤
- 腾讯云 CloudBase JS SDK（CDN 引入）、CloudBase Auth 匿名登录、PostgreSQL（`rdb()` / PostgREST 风格）、对象存储
- `MediaRecorder` 录音，后台用签名 URL 播放语音

## 已知限制

- 匿名登录产生的 UID 与浏览器会话绑定，清理缓存或换设备即可再次投票；本项目适合现场活动收集意见，**不适合严肃选举或需要实名审计的场景**。
- 语音意见可能包含村民声音，属于个人信息，采集前应现场告知并征得同意；仓库不含任何录音。
- 当前前端只提交语音意见；后台的 `message` 字段用于兼容文字意见与历史数据。
- 页面中的品牌文案（花木共创、点位名称等）是示例，部署时请替换为你自己的内容。
- 未指定开源许可证，详见下方「许可证」。

## 参与贡献

见 [CONTRIBUTING.md](CONTRIBUTING.md)。提交前请确认没有把 `config.js`、真实数据或密钥带进提交。

## 许可证

**尚未指定许可证。** 在添加 `LICENSE` 文件之前，本仓库默认「保留所有权利」，他人不能合法地复制、修改或再分发代码。若目标是公开开源，建议补一份 `LICENSE`（MIT 或 Apache-2.0 是常见选择），并在 README 与本段同步更新。

## 建议的 GitHub 仓库信息

- 仓库描述：面向乡村公共空间共创的地图点位投票网站，支持语音意见与后台统计
- Topics：`static-site` `javascript` `cloudbase` `postgresql` `voting` `community-engagement` `rural-design`
- 首次推送前再检查一遍：[SECURITY.md](docs/SECURITY.md) 的「推送前自查清单」
