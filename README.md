# mac-keys

在 Windows 上叠一层 macOS 风格的键盘快捷键。单文件 AutoHotkey v2 脚本，所有映射集中在一处，不依赖任何应用内配置；不用的时候一键整体禁用。

## 设计

Windows 键盘空格旁的两个修饰键，与 Mac 的两个正好一一对应：

| Windows | Mac | 物理位置 | 本脚本的用法 |
|---|---|---|---|
| **Alt** | Command | 紧挨空格 | 全局生效 |
| **Win** | Option | 再外侧一格 | 仅编辑器（VS Code 等）前台时生效 |

在此之上，终端窗口里再补两个 readline 键。核心机制是"拦截—重发"：AHK 的低级键盘钩子先于应用看到按键，命中映射就吞掉原始按键，再用 SendInput 注入合成按键；配合 `#HotIf` 条件热键按前台窗口分流，同一个物理键在不同窗口走不同路径。

## 快速开始

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)，双击 `mac-keys.ahk` 运行；或编译成独立 exe（见下文）。
2. 首次启动会弹 UAC —— 脚本以管理员自动提权运行，否则发出的按键到不了管理员权限的窗口；拒绝提权则直接退出。
3. 开机自启建议走任务计划程序（免 UAC 弹窗）：创建任务 → 常规勾"使用最高权限运行" → 触发器"登录时" → 操作指向本脚本/exe。直接放 `shell:startup` 也行，但每次登录都会弹一次 UAC。

## 映射明细

### Alt 层（= Command，全局）

| 按键 | 动作 | Mac 等价 |
|---|---|---|
| Alt+C / V / X / A | 复制 / 粘贴 / 剪切 / 全选 | Cmd+C/V/X/A |
| Alt+Z / Alt+Shift+Z | 撤销 / 重做 | Cmd+Z / Cmd+Shift+Z |
| Alt+S / F / N / P | 保存 / 查找 / 新建 / 打印 | Cmd+S/F/N/P |
| Alt+T / W / R | 新标签页 / 关闭标签页 / 刷新 | Cmd+T/W/R |
| Alt+Shift+T | 恢复关闭的标签页 | Cmd+Shift+T |

### 终端层（Windows Terminal / conhost / mintty 前台时）

| 按键 | 实际发送 | 说明 |
|---|---|---|
| Alt+C / Alt+V | Ctrl+Shift+C / Ctrl+Shift+V | 四种终端的默认复制粘贴键，覆盖全局 Alt 层 |
| Ctrl+A / Ctrl+E | Home / End | 行首 / 行尾；Home/End 在 PowerShell、cmd、bash 里都是行首行尾 |

物理 Ctrl+C（中断）、Ctrl+D（EOF）不做任何改动，与 macOS 一致。

### Win 层（VS Code 等编辑器前台时）

| 按键 | 实际发送 | Mac 等价 |
|---|---|---|
| Win+Z | Alt+Z | 自动换行（Option+Z，VS Code 默认键位） |
| Win+Up / Down | Alt+Up / Down | 上移 / 下移代码行 |
| Win+A / Win+E | Home / End | 行首 / 行尾 |

原理：VS Code 在 Windows 上把 Mac 的 Option 系默认键位放在 Alt 上，所以 Win 层只做"换修饰键转发"，功能定义留在 VS Code 的键位表里，不必两边维护。

## 一键开关

- **Ctrl+Alt+F12**：暂停 / 恢复全部映射（暂停后立即回到 Windows 原生键位，无需退出进程）。
- 托盘 H 图标右键 → Suspend Hotkeys / Exit。

## 编译成 exe

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

`build.ps1` 会自动定位本机的 AutoHotkey v2 作为 base，首次运行会从 Ahk2Exe 官方 GitHub release 下载编译器到 `tools\`（已被 .gitignore 忽略）。产物 `mac-keys.exe` 自包含、不依赖 AHK 运行时，可随意移动。注意：修改 `.ahk` 后需要重新编译，exe 不会自动更新。

## 取舍与已知边界

- **GUI 里 Ctrl+A 是"全选"，不抢**。macOS 能 ⌘A 全选 + ⌃A 行首并存是因为它有两个修饰键，Windows 只有一个 Ctrl。编辑器里的行首行尾因此放在 Win 层（Win+A/E）。
- **编辑器前台时，系统的 Win+Z / Win+Up/Down / Win+A / Win+E 被接管**（贴边布局、最大化还原、快速设置、资源管理器）；焦点在别处时全部照常。Win+Left/Right 刻意不占用，留给窗口分屏。
- **VS Code 集成终端是盲区**：它与编辑器同属 Code.exe 的一个窗口，AHK 无法区分焦点在哪个面板，所以那里的 Alt+C/V 仍发 Ctrl+C/V、Ctrl+A 仍是全选整行。
- **PowerShell 里失去 Ctrl+A 全选整行**（被行首取代）；vim/less 等全屏程序里 Ctrl+A 会变成 Home。
- **故意不映射 Ctrl+K/U/D**：Git Bash 的 readline 里它们原生就是对的，硬映射成 PowerShell 的等价键（Ctrl+End/Home/Delete）反而会弄坏 bash 行为。PowerShell 想要完整 readline 层需自行配置 `Set-PSReadLineOption -EditMode Emacs`。
- 极少数程序会把 Alt+C 认成 Ctrl+Alt+C，备用写法见脚本末尾注释。

## 文件

| 文件 | 说明 |
|---|---|
| `mac-keys.ahk` | 全部逻辑与详细注释（覆盖范围、代价、首次运行需确认的事项都写在里面） |
| `build.ps1` | 编译脚本 |
