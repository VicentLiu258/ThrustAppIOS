# SaleSmartly iOS H5 聊天页

这个目录是 iOS `WKWebView` 使用的静态页面。页面会在收到原生 App 的
`service-link-login` `postMessage` 后，加载项目脚本并自动打开聊天窗口；用户身份
不会出现在 URL 中。

电话留资埋点依赖此页面注册的 `onCollectionInfo` 回调。发布 iOS App 更新时，
也要上传最新版 `index.html`；页面只向原生层发送完成信号，不传电话号码。

## aaPanel 部署

将 `index.html` 上传到现有 `www.compoundmatrix.com` 站点根目录下的：

```text
/salesmartly-chat/index.html
```

部署后先用浏览器确认：

```text
https://www.compoundmatrix.com/salesmartly-chat/
```

不要把页面放到 `api.compoundmatrix.com` 的 Go API 反向代理容器目录中，也不要把
SaleSmartly 的项目脚本地址写入后端环境变量。该脚本只能在浏览器/WebView 页面中加载。

## aaPanel 傻瓜步骤

1. aaPanel → **网站** → 找到 `www.compoundmatrix.com` → **文件**。
2. 进入网站根目录，新建文件夹 `salesmartly-chat`。
3. 上传本目录的 `index.html` 到该文件夹。
4. 文件权限保持 `644`，文件夹权限保持 `755`。
5. 浏览器打开上面的 HTTPS 地址，确认返回页面而不是 404。
6. iOS 工程中的 `ChatConfig.serviceLinkURL` 已指向该地址，重新编译 App 即可测试。

如果 aaPanel 为 `www.compoundmatrix.com` 配置了“前端路由全部重写到某个入口”，请新增
静态文件例外，确保 `/salesmartly-chat/index.html` 能直接返回该文件。
