# AGENTS.md — All_My_Gold 魔兽世界插件

## 项目概述

**All_My_Gold** 是一个魔兽世界（World of Warcraft）插件，用于追踪并展示玩家所有角色、所有服务器的金币总和。插件以一个可拖动的迷你 UI 条形式常驻屏幕，鼠标悬浮时展示详细的分服务器、分角色金币明细，同时支持战团银行金币和时光徽章当前价格的实时显示。

- **作者**: Bambi
- **版本**: 2.1.4
- **接口版本**: 120001（The War Within / TWW）
- **CurseForge 项目 ID**: 1072198
- **SavedVariables**: `All_My_Gold_Database`

---

## 目录结构

```
All_My_Gold/
├── All_My_Gold.toc          # 插件元信息、加载顺序声明
├── All_My_Gold.lua          # 插件主逻辑（唯一 Lua 文件）
├── Locales/
│   └── LoadLocales.xml      # 本地化文件加载入口（含 zhCN、enUS 等）
└── Libs/
    └── imports.xml          # 第三方库加载入口
```

---

## 依赖库

插件使用以下 Ace3 系列及 LibDataBroker 生态库，均通过 `Libs/imports.xml` 加载：

| 库名                | 用途                                                        |
| ------------------- | ----------------------------------------------------------- |
| `AceAddon-3.0`      | 插件主框架，生命周期管理（OnInitialize / OnEnable）         |
| `AceConsole-3.0`    | 注册聊天命令（`/goldtracker`）                              |
| `AceEvent-3.0`      | 事件系统（目前已 mixin，备用）                              |
| `LibDataBroker-1.1` | 创建 LDB 数据源对象，供 LDB 显示插件使用（如 ChocolateBar） |
| `LibDBIcon-1.0`     | 注册小地图按钮                                              |

> **注意**：修改依赖库时，须同步更新 `Libs/imports.xml`，不要直接在 `All_My_Gold.lua` 中 require 外部文件。

---

## 核心架构

### 插件对象

```lua
MyGoldTracker = LibStub("AceAddon-3.0"):NewAddon("All_My_Gold", "AceConsole-3.0", "AceEvent-3.0")
```

所有功能方法均挂载在 `MyGoldTracker` 命名空间上。本地化字符串通过文件顶部的 `local _, MyGoldTracker = ... ; local L = MyGoldTracker.L` 访问。

### 数据库结构（SavedVariables）

数据通过 WoW 的 SavedVariables 机制持久化，结构如下：

```lua
All_My_Gold_Database = {
    position = {          -- 迷你UI的屏幕位置
        point,            -- 锚点（如 "CENTER"）
        relativePoint,    -- 相对锚点
        x,                -- X 偏移
        y                 -- Y 偏移
    },
    data = {              -- 金币数据，按服务器 → 角色 两层嵌套
        ["服务器名"] = {
            ["角色名"] = 12345678,  -- 单位：铜币（integer）
        }
    }
}
```

> **金币单位**：WoW API 中所有金币值均以**铜币**为单位（1 金 = 10000 铜）。显示时统一使用 `C_CurrencyInfo.GetCoinTextureString(copper)` 转换。

---

## 功能模块

### 1. 数据更新（`UpdateGoldData`）

- 在 `OnEnable` 时触发一次
- 读取 `GetRealmName()`、`UnitName("player")`、`GetMoney()` 写入数据库
- 每次登录角色自动更新该角色的金币快照

### 2. 总金币计算（`UpdateTotalGold`）

- 遍历 `All_My_Gold_Database.data` 所有服务器、所有角色求和
- 结果存入模块级变量 `totalGold`（局部变量，不持久化）
- 数据异常时会 `print` 警告（但当前有一个 bug：`("").format(...)` 应改为 `string.format(...)`）

### 3. 迷你 UI 条（`GenerateGoldTrackerMiniUI`）

- 尺寸：200×20 像素，可拖动，锁定在屏幕内
- 显示：`总金币: [金币图标]`
- 悬浮（OnEnter）Tooltip 展示：
  - 各服务器 / 各角色金币明细
  - 所有角色金币总和
  - 战团银行金币（`C_Bank.FetchDepositedMoney(Enum.BankType.Account)`）
  - 时光徽章当前市场价格（`C_WowTokenPublic.GetCurrentMarketPrice()`）
- 位置通过 `All_My_Gold_Database.position` 持久化，跨登录保留

### 4. LDB 数据源 + 小地图按钮

- 左键单击：切换金币摘要浮窗（`ShowGoldSummary`）
- 右键单击：重置数据库（`ResetDatabase`）
- Tooltip 显示左右键提示文字

### 5. 金币摘要浮窗（`ShowGoldSummary`）

- 首次调用时创建（懒加载），尺寸 300×150，含滚动框
- 展示所有服务器、角色金币 + 底部总计
- **已知问题**：浮窗内容在创建后不会动态刷新，再次 `Show()` 显示的是旧数据

### 6. 聊天命令（`/goldtracker`）

| 命令                 | 效果             |
| -------------------- | ---------------- |
| `/goldtracker show`  | 打开金币摘要浮窗 |
| `/goldtracker reset` | 清空所有金币数据 |
| 其他                 | 打印用法提示     |

---

## 本地化（Locales）

本地化字符串通过 `MyGoldTracker.L` 访问，在 `Locales/LoadLocales.xml` 中加载对应语言文件。

当前代码中用到的 L 键名：

| 键名                   | 用途                 |
| ---------------------- | -------------------- |
| `TOOLTIP_GOLD_SUMMARY` | LDB Tooltip 标题     |
| `LEFT_CLICK_TOOLTIP`   | LDB Tooltip 左键说明 |
| `RIGHT_CLICK_TOOLTIP`  | LDB Tooltip 右键说明 |
| `COMMAND_USAGE`        | 聊天命令用法提示     |
| `GOLD_TOTAL`           | "总金币" 标签        |
| `WAR_BAND_TOTAL`       | "战团银行" 标签      |
| `CURRENT_WOW_TOKEN`    | "时光徽章" 标签      |

> 新增功能若需要文字，必须先在所有语言的 Locale 文件中添加对应的键值，再在代码中通过 `L["KEY"]` 引用。

---

## 已知 Bug / 技术债

| 位置                        | 问题描述                                             | 建议修复                                                  |
| --------------------------- | ---------------------------------------------------- | --------------------------------------------------------- |
| `UpdateTotalGold`           | `("").format(...)` 是错误写法，会报错                | 改为 `string.format(...)`                                 |
| `ShowGoldSummary`           | 浮窗懒加载后不刷新，数据陈旧                         | 每次 Show 前销毁重建，或动态更新 FontString               |
| `GenerateGoldTrackerMiniUI` | `text` FontString 只在创建时赋值，金币更新后 UI 不变 | 将 `text` 提升为模块级变量，在 `UpdateTotalGold` 末尾刷新 |
| `OnEnter` tooltip           | 标题 `"金币统计"` 为硬编码中文                       | 改为 `L["TOOLTIP_GOLD_SUMMARY"]` 保持本地化一致性         |

---

## 开发环境 & 参考资源

### VSCode 扩展

本项目依赖以下三个 VSCode / Antigravity 扩展配合使用，缺一不可：

#### 1. Lua（`sumneko.lua`）

- **Marketplace**: https://marketplace.visualstudio.com/items?itemName=sumneko.lua
- **GitHub**: https://github.com/LuaLS/vscode-lua
- **作用**: Lua 语言服务器（LuaLS），提供语法检查、补全、类型推断、注解支持（`@param`、`@return`、`@class` 等）
- **与 WoW API 扩展的关系**: WoW API 扩展以 LuaLS 的 annotation 格式生成类型定义，**必须先安装此扩展**，WoW API 扩展才能工作
- WoW 插件使用 Lua 5.1 环境，需在 `.vscode/settings.json` 中配置：
  ```json
  {
    "Lua.runtime.version": "Lua 5.1"
  }
  ```

#### 2. WoW API（`ketho.wow-api`）

- **Marketplace**: https://marketplace.visualstudio.com/items?itemName=ketho.wow-api
- **GitHub**: https://github.com/Ketho/vscode-wow-api
- **Wiki（使用文档）**: https://github.com/Ketho/vscode-wow-api/wiki
- **作用**: 为 WoW 插件开发提供完整的 IntelliSense 支持，包括：
  - WoW Lua 5.1 运行时环境
  - 官方 Blizzard API 文档（来源：[Blizzard_APIDocumentationGenerated](https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_APIDocumentationGenerated)）
  - [Warcraft Wiki](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) API 文档解析
  - Widget API、Events、CVars、Enums、GlobalStrings 的自动补全
- **激活方式**: 打开含 `.toc` 文件的文件夹时自动激活；或手动执行命令 `Activate WoW API extension`

#### 3. WoW TOC（`stanzilla.vscode-wow-toc`）

- **Marketplace**: https://marketplace.visualstudio.com/items?itemName=stanzilla.vscode-wow-toc
- **GitHub**: https://github.com/Stanzilla/vscode-wow-toc
- **作用**: 为 `.toc` 文件提供语法高亮和代码补全，支持：
  - 标准关键字（`## Interface`、`## Author`、`## Version` 等）
  - X 扩展关键字（`## X-Curse-Project-ID`、`## X-Date` 等）
  - 新建 `.toc` 的起始代码片段（snippet）

> **Antigravity 安装说明**：Antigravity IDE 使用 OpenVSX 注册表，部分扩展需手动安装 `.vsix`。可从 VS Code Marketplace 下载对应 `.vsix` 文件后，通过 Antigravity CLI 安装：
>
> ```bash
> .../Antigravity.app/Contents/Resources/app/bin/antigravity --install-extension <file>.vsix
> ```

---

### WoW API 参考

开发时常用的相关 API（均可通过 WoW API 扩展获得 IntelliSense 补全和文档提示）：

```lua
GetMoney()                                          -- 返回当前角色铜币数（integer）
GetRealmName()                                      -- 返回服务器名（string）
UnitName("player")                                  -- 返回角色名（string）
C_CurrencyInfo.GetCoinTextureString(copper)         -- 铜币数转带图标的格式化字符串
C_Bank.FetchDepositedMoney(Enum.BankType.Account)   -- 战团银行铜币总量
C_WowTokenPublic.GetCurrentMarketPrice()            -- 时光徽章当前市场价（铜币）
```

查阅具体 API 签名和说明的方式：

| 资源                      | 地址                                                                                                 | 用途                                                        |
| ------------------------- | ---------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| Warcraft Wiki API         | https://warcraft.wiki.gg/wiki/World_of_Warcraft_API                                                  | 函数签名、参数说明、版本信息                                |
| Warcraft Wiki Widget      | https://warcraft.wiki.gg/wiki/Widget_API                                                             | Frame、FontString、Texture 等 UI 对象方法                   |
| Warcraft Wiki Events      | https://warcraft.wiki.gg/wiki/Events                                                                 | 所有可注册的游戏事件                                        |
| Blizzard 客户端源码       | https://github.com/Gethe/wow-ui-source                                                               | 官方 UI 源码镜像，查阅 Blizzard 内置实现和 API 文档生成文件 |
| Blizzard API 文档生成文件 | https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_APIDocumentationGenerated | WoW API 扩展的数据来源，包含最新 API 的完整类型定义         |

---

## 开发规范

1. **不要破坏 SavedVariables 结构**：`data` 和 `position` 的键名是向后兼容的约定，修改会导致用户数据丢失。
2. **金币值始终用铜币（integer）存储**，仅在显示层调用 `GetCoinTextureString` 转换。
3. **新增 UI 元素**：参考现有的 `BackdropTemplate` 风格（深色半透明背景 `0.08, 0.08, 0.08, 0.95`），保持视觉一致性。
4. **本地化优先**：所有面向用户的字符串都必须通过 `L["KEY"]` 引用，不允许硬编码中文或英文。
5. **测试**：WoW 插件无法单元测试，修改后需在游戏客户端内 `/reload` 验证，注意查看 Lua 错误（可用 BugSack / !BugGrabber 捕获）。

---

## 快速上手（给 Antigravity Agent 的指引）

- **主要逻辑文件**：`All_My_Gold.lua`（唯一需要修改业务逻辑的文件）
- **本地化文件**：`Locales/` 目录下（新增字符串时同步修改）
- **插件入口**：`All_My_Gold.toc`（新增 Lua 文件时在此声明）
- **调试命令**：游戏内 `/goldtracker show` 或 `/reload`
- **不要修改** `Libs/` 目录下的第三方库文件
