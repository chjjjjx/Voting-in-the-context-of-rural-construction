/**
 * 花木共创 · 前端配置模板
 *
 * 使用方法：
 *   1. 复制本文件为 config.js
 *   2. 把下面的占位值换成你自己的 CloudBase 参数
 *   3. config.js 已被 .gitignore 忽略，请不要提交、不要写进任何页面
 *
 * 说明：
 *   - publishableKey 是「客户端公开密钥」，设计上会随前端下发，但必须配合
 *     数据库行级权限（RLS）使用；本仓库仍不提交真实值，避免他人连到你的环境。
 *   - 填的是谁的环境，页面就连接谁的数据库和存储桶。请只填你自己新建的
 *     环境，不要借用、也不要把别人的环境 ID / 密钥填进来。
 *   - 绝对不要把 service_role / 管理员密钥、账号密码放进这个文件。
 */
window.HUAMU_CONFIG = {
  // CloudBase 环境 ID，例如 your-env-1234567890
  envId: 'YOUR_CLOUDBASE_ENV_ID',

  // CloudBase Publishable Key（客户端公开密钥）
  publishableKey: 'YOUR_CLOUDBASE_PUBLISHABLE_KEY',

  // 环境所在地域
  region: 'ap-shanghai',

  // villages 表中的村庄主键，需与 database/04_seed.sql 保持一致
  villageId: 'demo-village',

  // 对象存储桶名；如需改名，请同时修改 database/03_storage.sql
  buckets: {
    images: 'demo-images', // 地图与作品图片，公开读
    voice: 'demo-voice'    // 语音意见，私有读 + 签名 URL
  }
};
