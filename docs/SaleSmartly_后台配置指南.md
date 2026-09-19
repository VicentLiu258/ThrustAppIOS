# SaleSmartly iOS 接入配置指南（专属链接 / WebView）

## 接入方式

iOS 按项目规划使用 SaleSmartly 的**专属链接（H5）**，由 App 内的 `WKWebView` 加载。因此：

| 信息项 | iOS 用途 |
| --- | --- |
| project scriptUrl | 不需要；这是 Android 原生 SDK 初始化参数 |
| 专属链接 / H5 页面地址 | 必需；WebView 的加载地址 |
| 标签名 | 通过 `setLoginInfo` 传递 |
| 自定义字段 ID | 通过 `custom_fields_ext` 传递 |

## 后台需交付的信息

1. 在 SaleSmartly 控制台的聊天插件配置中创建并复制**专属链接**，格式类似：

   ```text
   https://chat.example.com/service/example-id
   ```

2. 在「客户 → 标签管理」预先创建 iOS 将传递的标签。当前默认值为：

   ```text
   ios
   thrust_wealth
   ```

3. 如需上报 App 版本、来源、设备型号，在「项目设置 → 自定义字段」创建字段并记录字段 ID 和字段类型。选择型字段需要按 SaleSmartly 要求传数组。

## 工程侧配置

将专属链接填入：

`ThrustWealth/Services/ChatConfig.swift`：

```swift
static let serviceLinkURL = "https://chat.example.com/service/example-id"
```

不要将 Android 的 `project_830957_862319_1789665876.js` 填到此项。打开客服时，iOS 会自动追加 `loginSource=postMessage`，并在页面加载完成后调用：

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

参考：[SaleSmartly 聊天插件 JSSDK 文档](https://help.salesmartly.com/docs/salesmartly-chat-plugin-jssdk-developer-documentation)。
