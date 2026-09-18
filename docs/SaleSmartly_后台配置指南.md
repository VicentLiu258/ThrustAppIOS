# SaleSmartly 后台配置指南（Thrust Wealth iOS）

本文档供后台管理员使用，用于完成 SaleSmartly 平台侧配置，并把必要信息交给 iOS 开发团队。  
iOS 端已按**原生 SDK（SalesmartlyChat 1.0.0）**方案接入，不再依赖 WebView / H5 专属链接作为主路径。

参考文档：

- [产品介绍](https://help.salesmartly.com/docs/product-introduction)
- [iOS SDK 仓库与接入说明](https://github.com/SaleSmartly-Mobile/Mobile-SDK)
- [聊天插件 JSSDK（字段规范可参考）](https://help.salesmartly.com/docs/salesmartly-chat-plugin-jssdk-developer-documentation)
- [原生 SDK 合规配置指引](https://help.salesmartly.com/docs/SaleSmartly-yuan-sheng-SDK-he-gui-pei-zhi-zhi-yin)

---

## 1. 规划表核对结论（给产品 / 后台）

原规划表中 iOS 列「走 H5 / 专属链接必需」在 **WebView 方案**下成立，但当前推荐改为原生 SDK：

| 信息项 | 原规划（iOS） | 更正后（原生 SDK） |
| --- | --- | --- |
| project scriptUrl | 不需要（走 H5） | **必需**，用于 `SalesmartlyChat.initialize(scriptURL:)` |
| 专属链接 / H5 | 必需 | **可选备用**；仅在回退 WebView 时需要 |
| aar 包及 Demo | 不适用 | 正确（aar 仅 Android） |
| 标签名列表 | `setLoginInfo` 传参 | 正确；原生字段为 `LoginInfo.labelNames` |
| 自定义字段 ID 及类型 | `custom_fields_ext` | 正确；原生为 `customFieldsExt`，key 为字段 ID |
| 用户身份字段 | 登录信息传递 | 正确；`userId` / `userName` / `phone` / `email` 等 |

**请后台优先提供 scriptURL、标签名、自定义字段 ID。**

---

## 2. 获取 Project Script URL（必需）

1. 登录 [SaleSmartly 后台](https://app.salesmartly.com)
2. 进入 **设置 → 项目设置**（或聊天插件安装代码页）
3. 复制项目 JS 地址，形如：

```text
https://assets.salesmartly.com/js/project_XXXXX_XXXXX_XXXXXXXXXX.js
```

4. 发给 iOS 开发，填入工程文件：

`ThrustWealth/Services/ChatConfig.swift` → `ChatConfig.scriptURL`

---

## 3. 创建标签（必需）

1. 进入 **客户 → 标签管理**
2. 创建以下标签（名称需与 App 传参完全一致）：

| 标签名 | 用途 |
| --- | --- |
| `ios` | 标识 iOS 端用户 |
| `thrust-wealth` | 标识来自 Thrust Wealth App |

3. 如需业务标签（如 `vip`、`trial`），先在后台创建，再通知开发追加到 `ChatConfig.labelNames`。

> 注意：未在后台创建的标签值会被忽略。

---

## 4. 创建自定义字段（必需）

1. 进入 **设置 → 自定义字段**
2. 建议创建：

| 字段显示名 | 类型 | App 用途 |
| --- | --- | --- |
| App Version | 文本 | 当前 App 版本号 |
| Source | 文本 | 固定传 `ios-app` |
| Device Model | 文本 | 设备型号 |

3. 记录系统分配的**字段 ID**（数字或字符串 ID），发给开发，填入：

`ChatConfig.CustomFieldID.appVersion / source / deviceModel`

App 会通过 `customFieldsExt[字段ID] = 值` 上报。

---

## 5. 专属链接（仅 WebView 备用方案）

若未来需要 H5 WebView 兜底：

1. **设置 → 聊天插件** 获取专属链接
2. iOS 加载时追加：`?loginSource=postMessage`
3. 页面加载完成后 3 秒内通过 `window.postMessage` 发送 `service-link-login` 身份信息

当前主路径**不需要**专属链接。

---

## 6. 聊天插件与客服运营配置（建议）

1. **设置 → 聊天插件 → 编辑**
   - 主题色对齐 App 品牌色
   - 欢迎语使用英文（App 文案为英文）
   - 配置工作时间 / 离线留资表单
2. **团队 → 团队管理**：添加客服并分配权限
3. **机器人 → AI 机器人**（可选）：配置自动回复
4. **设置 → 聊天设置**：配置自动分配规则

---

## 7. 交付给 iOS 开发的信息清单

请后台按下列表格回填后发给开发：

| 信息项 | 是否必需 | 填写值 |
| --- | --- | --- |
| scriptURL（project_*.js） | 必需 | |
| 标签列表 | 必需 | 例：`ios`, `thrust-wealth` |
| App Version 字段 ID | 必需 | |
| Source 字段 ID | 必需 | |
| Device Model 字段 ID | 建议 | |
| 专属链接（WebView 备用） | 可选 | |

---

## 8. 合规提醒（后台 / 法务）

- App 仅在用户同意隐私政策后初始化 SDK
- 隐私政策已披露 SaleSmartly SDK 名称、收集字段、用途与官方隐私链接
- App Store Connect 隐私标签需补充 SDK 相关数据类型
- SaleSmartly 原生 SDK 隐私政策：  
  https://www.salesmartly.com/html/sdk/privacy_native_cn.html

---

## 9. 联调验收清单

- [ ] scriptURL 可在浏览器打开且返回有效 JS
- [ ] 标签已创建，App 打开客服后后台客户资料可见标签
- [ ] 自定义字段 ID 正确，客户资料可见 App Version / Source
- [ ] Settings → Contact Support 可打开聊天窗
- [ ] 首次安装弹出隐私同意；同意后才出现联网客服能力
- [ ] 清除 App 数据后再次启动会重新征求隐私同意
