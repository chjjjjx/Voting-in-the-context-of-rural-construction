# 贡献指南

欢迎提 Issue 和 Pull Request：Bug 修复、移动端适配、可访问性改进、文档补全、部署经验都很有价值。

## 开始之前

- 本项目是纯静态页面，没有构建步骤。改动 `index.html` / `admin.html` 后，用本地服务器预览即可：
  ```bash
  python -m http.server 8080
  ```
- 需要连云端验证时，先按 [DEPLOYMENT.md](docs/DEPLOYMENT.md) 建好数据库，`config.js` 用你自己的环境配置。
- 提交前请确认 `config.js` 不在 `git status` 里。

## 提交规范

- 一个 PR 聚焦一件事，说明改了什么、为什么改、怎么验证；涉及 UI 时附截图（**截图里不要带真实环境 ID、密钥或村民数据**）。
- 保持现有代码风格：原生 JS、不引入框架和构建工具；新增配置项放在 `config.example.js` 并同步文档。
- 涉及数据库表或权限的改动，请同时更新 `database/` 里的 SQL 和 `database/README.md`。
- 涉及页面行为的改动，请同步更新 `README-开源整理版.md`、`CHANGELOG.md`；涉及安全边界的改动同步更新 `docs/SECURITY.md`。

## 不要提交的内容

- `config.js`、`.env`、任何真实环境 ID / Publishable Key / `service_role` 密钥
- 编辑者账号、密码、UID、走访问令
- 真实地图、作品图片、录音、投票记录、CSV 导出、村民意见文本
- 含个人信息的截图或日志

## 报告问题

请说明：浏览器与系统、复现步骤、期望与实际结果、控制台报错（**脱敏后**）。安全相关的问题不要公开贴细节，参见 [SECURITY.md](docs/SECURITY.md) 第六节。

## 许可证状态

仓库目前**未指定许可证**。在维护者补充 `LICENSE` 之前，默认保留所有权利；提交 PR 前请知悉这一点。
