# 巨魔商店 Lite（TrollStore Lite）· roothide 适配 + 全中文版

面向 **roothide 越狱**（如 **Relaxin**，iOS 17.0–17.3.1，A15+）的巨魔商店 Lite。
在官方版本无法工作的 roothide 环境下，本版本可以正常安装 IPA，并且**界面全中文**。

> 本项目基于 opa334 的开源 [TrollStore](https://github.com/opa334/TrollStore) 修改，仅供学习与个人使用，**严禁用于盗版**。

---

## 这是什么

巨魔商店 Lite 是"越狱版"的巨魔商店：它不依赖 CoreTrust 漏洞，而是借助越狱环境提供的 ldid 对 IPA 重新签名，从而永久安装任意 IPA。

问题在于：**opa334 官方只发布 rootless 版本的安装包**。在 roothide 越狱上（Relaxin 就是 roothide），越狱根目录 `jbroot` 是**随机路径**、没有固定的 `/var/jb`，导致官方包里写死的 ldid 路径失效，安装 IPA 时报错：

```
Failed to sign the app. ldid returned a non zero status code.
ldid: /var/tmp/xxxx.plist: No such file or directory
```

本仓库把它**适配到 roothide 并汉化**，重新编译出可用的 roothide `.deb`。

## 适用范围

- 越狱类型：**roothide**（如 Relaxin，以及其它使用 roothide bootstrap 的环境）
- 系统/机型：以你的越狱工具支持范围为准（Relaxin：iOS 17.0–17.3.1，A15+）
- 依赖：`ldid`（roothide 的 procursus bootstrap 自带，deb 已声明依赖，会自动安装）

> 注意：这是 **roothide 专用包**。rootless（如多巴胺 Dopamine）请用官方 rootless 版，不要混用。

## 安装

1. 从本仓库的 **Actions 制品** 或 **Releases** 下载 `com.opa334.trollstorelite_*_iphoneos-arm64e.deb`
2. 用 **Sileo** 或 **Zebra** 打开并安装该 deb
3. 桌面出现「**巨魔商店 Lite**」，打开后点开 IPA 即可安装

如果之前装过其它版本的巨魔商店 Lite，请先卸载再安装本版本。

## 自己编译

本仓库自带 GitHub Actions，无需本地环境：

1. Fork 或直接使用本仓库
2. 进入 **Actions → Build TrollStore Lite (roothide) → Run workflow** 手动触发
3. 也可以推送一个 `roothide-*` 开头的 tag，编译产物会自动挂到 Release
4. 编译完成后在该次运行的 Artifacts 里下载 deb

工作流在 macOS runner 上使用 **roothide 版 theos** + 补丁 SDK，以 `THEOS_PACKAGE_SCHEME=roothide` 打包。

## 相比官方版改了什么

- **roothide 路径适配**：在 roothide 方案下改用 roothide 的 `jbroot()` API 定位 ldid，替代 rootless 写死的 `/var/jb`
- **修复 IPA 签名失败**：传给 ldid 的 entitlements plist、目标二进制路径经 `rootfs()` 转换为 jbroot 相对路径，解决 "No such file or directory"
- **roothide 打包**：新增 `make_trollstore_lite_roothide` 构建目标，链接 `-lroothide`
- **全中文界面**：品牌名、安装/卸载弹窗、错误提示、设置页、应用信息页等均已汉化
- **持续集成**：提供 GitHub Actions 一键出包

以上改动仅在 roothide 构建下生效，不影响原有的 rootless / rootful 构建。

## 致谢

- [opa334](https://github.com/opa334) — 巨魔商店 / TrollStore 原作者
- [roothide](https://github.com/roothide) — roothide 越狱框架、theos 与开发文档
- Lakr233 / OwnGoal Studio — Relaxin 越狱
- @alfiecg_dev、Google TAG — CoreTrust 漏洞
- ProcursusTeam — uicache、ldid

## 声明

本项目为社区适配版，与官方无关。请仅安装你拥有合法授权的应用，**切勿用于盗版**。使用风险自负。
