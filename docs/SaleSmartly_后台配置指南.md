# SaleSmartly iOS 接入配置指南（自建 H5 / WebView）

## 接入方式

iOS 使用 aaPanel 托管的自建 H5 页面，由 App 内的 `WKWebView` 加载。H5 页面在收到
原生 App 的 `service-link-login` 消息后，才加载 SaleSmartly 项目脚本并自动打开聊天窗口。
因此：

| 信息项 | iOS 用途 |
| --- | --- |
| project scriptUrl | 不需要；这是 Android 原生 SDK 初始化参数 |
| 专属链接 / H5 页面地址 | 必需；WebView 的加载地址 |
| 标签名 | 通过 `setLoginInfo` 传递 |
| 自定义字段 ID | 通过 `custom_fields_ext` 传递 |

## 后台需交付的信息

1. aaPanel 中将 `ThrustAppIOS/H5/salesmartly-chat/index.html` 上传到现有站点：

   ```text
   /www/wwwroot/<www站点根目录>/salesmartly-chat/index.html
   ```

   页面地址固定为：

   ```text
   https://www.compoundmatrix.com/salesmartly-chat/
   ```

2. 确认 HTTPS 页面能直接返回 `index.html`，不要被前端路由重写成 404。

3. 在「客户 → 标签管理」预先创建 iOS 将传递的标签。当前默认值为：

   ```text
   ios
   thrust_wealth
   ```

4. 如需上报 App 版本、来源、设备型号，在「项目设置 → 自定义字段」创建字段并记录字段 ID 和字段类型。选择型字段需要按 SaleSmartly 要求传数组。

## 工程侧配置

将 H5 页面地址填入：

`ThrustWealth/Services/ChatConfig.swift`：

```swift
static let serviceLinkURL = "https://www.compoundmatrix.com/salesmartly-chat/"
```

不要把 Android 的 `project_830957_862319_1789665876.js` 直接作为 WebView 地址。打开客服时，iOS 会自动追加 `loginSource=postMessage`，并在页面加载完成后调用：

```javascript
window.postMessage(JSON.stringify({
  type: 'service-link-login',
  version: 1,
  payload: {
    user_id: '稳定访客 ID',
    user_name: 'Thrust Wealth User',
    label_names: ['ios', 'thrust_wealth'],
    custom_fields_ext: {}
  }
}), window.location.origin)
```

这样用户信息不会出现在 URL 或浏览器历史中。工程仅在用户接受隐私政策后才会创建并打开 WebView。

## 联调验收

- [ ] 设定的专属链接可在浏览器中访问。
- [ ] App 内「Contact Support」能够打开聊天页。
- [ ] SaleSmartly 客户资料显示稳定 `user_id`、用户名及 iOS 标签。
- [ ] 在后台发送消息后，App 的悬浮客服按钮显示未读数。
- [ ] 清除 App 数据后，下一次客服会话会使用新的访客 ID。

## 当前能力边界

- iOS 依赖 H5 页面、SaleSmartly 项目脚本和实时连接同时可达；任一域名或长连接被网络环境拦截，聊天登录、发送和接收都会失败。
- App 已提供连接失败提示、重新加载和重新登录；前台恢复时会自动重试。
- 未读数会保存在 App 本地，并在成功打开聊天后清零。
- 当前没有 APNs 远程推送。App 被系统终止后，客服回复不会产生系统通知；如需该能力，还需要 SaleSmartly 或业务后端提供 APNs 推送服务及凭证。

参考：[SaleSmartly 聊天插件 JSSDK 文档](https://help.salesmartly.com/docs/salesmartly-chat-plugin-jssdk-developer-documentation)。
