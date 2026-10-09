#Requires AutoHotkey v2.0
#SingleInstance Force
; =====================================================================
;  Mac 手感快捷键 for Windows —— 全部集中在本脚本，不依赖任何其它配置
;
;  一键开关：Ctrl+Alt+F12 暂停 / 恢复全部映射。
;           托盘 H 图标右键也有 "Suspend Hotkeys" / "Exit"。
;           暂停后立即回到 Windows 原生键位，不需要卸载或改配置文件。
;
;  映射分三层，每层的物理位置都对着 Mac：
;    Alt 层  = Mac 的 Command（紧挨空格键左侧）     -> 全局生效
;    Win 层  = Mac 的 Option （再外侧一格）         -> 只在编辑器里生效
;    Ctrl 层 = Mac 的 readline/Emacs 键位           -> 只在终端里补几个键
;
;  需要以管理员身份运行（见下方自动提权），启动时会弹一次 UAC。
;  用法：双击运行（托盘出现绿色 H 图标）。
;  开机自启：见文末【开机自启】一节。
; =====================================================================

; ---------- 必须以管理员运行（自动提权，本段必须在所有函数/热键之前）----
; 只有进程本身是管理员，注入的按键才能到达管理员权限的窗口。
; 非管理员启动时自动弹 UAC 重启自己；拒绝提权就直接退出（等于没开）。
if !A_IsAdmin {
    try {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '" /restart'
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    }
    ExitApp
}

; ---------- 生效范围的判定 --------------------------------------------
isEditor() {
    return WinActive("ahk_exe Code.exe")
        || WinActive("ahk_exe Code - Insiders.exe")
        || WinActive("ahk_exe Cursor.exe")
        || WinActive("ahk_exe Windsurf.exe")
}
isConsole() {
    return WinActive("ahk_class ConsoleWindowClass")   ; 经典 conhost 窗口（cmd / powershell）
        || WinActive("ahk_exe WindowsTerminal.exe")     ; Windows Terminal（含 WSL 标签页）
        || WinActive("ahk_class mintty")                ; Git Bash / MSYS2
}

; ---------- Alt 层：Mac 的 Command，全局生效 --------------------------
; 剪贴板
!c::Send("^c")          ; 复制        Cmd+C（终端里的版本见下方终端层）
!v::Send("^v")          ; 粘贴        Cmd+V（终端里的版本见下方终端层）
!x::Send("^x")          ; 剪切        Cmd+X
!a::Send("^a")          ; 全选        Cmd+A

; 撤销 / 重做
!z::Send("^z")          ; 撤销        Cmd+Z
!+z::Send("^y")         ; 重做        Cmd+Shift+Z（部分程序只认 Ctrl+Shift+Z）

; 文件 / 查找 / 标签页
!s::Send("^s")          ; 保存        Cmd+S
!f::Send("^f")          ; 查找        Cmd+F
!n::Send("^n")          ; 新建        Cmd+N
!p::Send("^p")          ; 打印        Cmd+P
!t::Send("^t")          ; 新标签页    Cmd+T
!+t::Send("^+t")        ; 恢复标签页  Cmd+Shift+T
!w::Send("^w")          ; 关闭标签页  Cmd+W
!r::Send("^r")          ; 刷新        Cmd+R

; ---------- 终端层：复制/粘贴 + Ctrl+A(行首) / Ctrl+E(行尾) ------------
; 这里的 !c / !v 覆盖全局 Alt 层的同名热键（带 #HotIf 的变体优先于无条件的）。
; 复制/粘贴统一发 Ctrl+Shift+C / Ctrl+Shift+V，四种终端的默认键都是它：
;   Windows Terminal、conhost（默认开启 Ctrl 快捷键）、PSReadLine（实测
;   Ctrl+Shift+C = Copy）、mintty/Git Bash。不能直接发 Ctrl+C/Ctrl+V：
;   Ctrl+C 是中断(SIGINT)，Ctrl+V 在 mintty 里是 readline 的"原样插入"。
; 行首/行尾退化成 Home/End 发送，因为 Home/End 在三种终端里都已经是行首/行尾
;   （PowerShell 实测 Home=BeginningOfLine、End=EndOfLine，而 Windows 模式下
;   Ctrl+A 反而是"全选整行"、Ctrl+E 完全没绑定；cmd 的行编辑器认 Home/End；
;   Git Bash 的 readline 两个键都认）。
; 代价：① PowerShell 里失去 Ctrl+A 全选整行；② vim/less 这类全屏程序里
;   Ctrl+A 会变成 Home（vim 插入模式下的"重复上次插入内容"就用不了了）。
#HotIf isConsole()
!c::Send("^+c")         ; 复制        Cmd+C
!v::Send("^+v")         ; 粘贴        Cmd+V
^a::Send("{Home}")      ; 行首        Mac: Ctrl+A
^e::Send("{End}")       ; 行尾        Mac: Ctrl+E
#HotIf

; ---------- Win 层：Mac 的 Option，仅编辑器前台时生效 ------------------
; VS Code 在 Windows 上把 Mac 的 Option 系默认键位放在 alt 上
;   toggleWordWrap = alt+z，moveLinesUp/Down = alt+up/down
; 所以这里把 Win+X 原样转成 Alt+X 交给编辑器自己处理，键位不用在 VS Code 里改。
#HotIf isEditor()
#z::Send("!z")          ; 自动换行      Mac: Option+Z
#Up::Send("!{Up}")      ; 上移代码行    Mac: Option+Up
#Down::Send("!{Down}")  ; 下移代码行    Mac: Option+Down

; 行首 / 行尾：GUI 里 Ctrl+A 被"全选"占死（见文末说明），只能放到 Win 层。
; 代价是编辑器前台时 Win+A 的"快速设置"面板、Win+E 的资源管理器失效；
; 焦点不在编辑器时这两个系统快捷键照常。不想要就注释掉对应行。
#a::Send("{Home}")      ; 行首        Mac: Ctrl+A
#e::Send("{End}")       ; 行尾        Mac: Ctrl+E
; 另一种选择：用方向键（语义更接近 Mac 的 Cmd+Left/Right，代价是窗口分屏）
; #Left::Send("{Home}")
; #Right::Send("{End}")
#HotIf
; 注意 Send 里方向键必须写成 {Up}，写 "!up" 会变成 Alt+U、Alt+P 两个字母。

; ---------- 一键暂停 / 恢复 ------------------------------------------
#SuspendExempt          ; 让这个热键在暂停状态下依然可用
^!F12:: {
    Suspend(-1)
    ToolTip(A_IsSuspended ? "Mac 键位已暂停：全部恢复 Windows 原生" : "Mac 键位已启用")
    SetTimer(() => ToolTip(), -1500)
}
#SuspendExempt False

; =====================================================================
;  覆盖范围 / 已知代价
; =====================================================================
; 【终端】Ctrl+C(中断) / Ctrl+D(EOF) 一行都没动，Win 和 Mac 本来就一致。
;   Alt+C / Alt+V 在终端里就是复制 / 粘贴（见终端层说明）。
;
; 【终端 Ctrl+A / Ctrl+E】已覆盖（退化成 Home/End）。两种 shell 的默认情况
;   实测如下：
;   - PowerShell(PSReadLine 2.0.0，Windows 模式)：Ctrl+A=全选整行(Ctrl+E 无绑定)，
;     所以必须补；顺带一提它已有 Ctrl+W 删词、Ctrl+R 反向搜索、Ctrl+V 粘贴、
;     Ctrl+X/C、Ctrl+Left/Right 按词跳。缺的是 Ctrl+D 删字符（等价物 Delete）、
;     Ctrl+K 删到行尾（等价物 Ctrl+End）、Ctrl+U 删到行首（等价物 Ctrl+Home）。
;   - Git Bash(装在 C:\Program Files\Git)：readline 原生就支持 Ctrl+A/E/K/U/W/D，
;     不需要映射。也正因如此，本脚本故意不映射 Ctrl+K/U/D —— 在 bash 里它们本来
;     就对，硬把它们改成 Ctrl+End/Ctrl+Home 反而会弄坏 bash 的原生行为。
;   - 若要 PowerShell 里也有完整的 Ctrl+K/U/D，只能配 shell 自己：
;       Set-PSReadLineOption -EditMode Emacs
;       Set-PSReadLineKeyHandler -Key Ctrl+v -Function Paste   ; Emacs 模式下粘贴会失效
;       Set-PSReadLineKeyHandler -Key Ctrl+Shift+c -Function Copy
;     本脚本不采用这条路线，因为它是 shell 全局配置，没法跟着本脚本一起禁用。
;
; 【VS Code 集成终端：盲区】集成终端是 Code.exe 窗口的一部分，AHK 无法区分
;   焦点在编辑器还是终端面板，所以那里 Alt+C/V 仍发 Ctrl+C/Ctrl+V（Alt+C 是
;   中断、Alt+V 在 PSReadLine 里恰好是粘贴）、Ctrl+A 仍是"全选整行"。
;   要补只能走 VS Code 自己的键位（keybindings.json），与本脚本"全走 AHK、
;   一键禁用"的目标冲突，故留作盲区。
;
; 【GUI 里的 Ctrl+A(行首)】覆盖不了，只能挪到 Win 层（见上面的 #a / #e）。
;   Windows 全平台的 Ctrl+A 都是"全选"，抢掉它会让所有程序的全选变成行首；
;   Mac 能共存是因为它有 Cmd 和 Ctrl 两个修饰键，Windows 只有一个 Ctrl。
;   Ctrl+E 情况相反：VS Code 官方默认键位表里没有它，Windows 文本框里通常也
;   没定义，按下去只是没反应，不是冲突。
;
; 【VS Code 的 Alt 层】Alt+Z(撤销) 与 Win+Z(自动换行) 互不干扰，因为自己发出
;   的键不会被自己的热键吃掉：Send 走 SendInput 时键盘钩子会临时停用，且
;   SendLevel 0 的注入事件默认不触发钩子热键。另外注入时会临时释放物理按住的
;   Win 修饰键，所以 VS Code 收到的是干净的 Alt+Z，不会变成 Win+Alt+Z。
;
; 【代价】编辑器前台时，系统的 Win+Z(贴边布局)、Win+Up/Down(最大化/还原)、
;   Win+A(快速设置)、Win+E(资源管理器) 被接管；焦点在别处时全部照常。
;   Win+Left/Right 没有动，留给你键盘分屏窗口用。焦点在 VS Code 集成终端里时，
;   Win+Up/Down 会把 Alt+Up/Down 发给 shell（移动代码行此时不生效）。
;
; 【没覆盖】Alt+Left/Right 保持注释：它会顶掉浏览器的前进/后退，以及 VS Code
;   官方默认的 Alt+Left/Right = Go Back / Go Forward。
; !Left::Send("{Home}")
; !Right::Send("{End}")
;
; 【开机自启】脚本要求管理员，直接放进 shell:startup 每次登录都会弹 UAC。
;   想免弹窗：任务计划程序 -> 创建任务 -> 常规勾"使用最高权限运行"，
;   触发器选"登录时"，操作指向本 exe。这样启动既提权又不弹窗。
;
; 【首次运行请确认三件事】① 启动时弹的 UAC 是本脚本自动提权，选"是"；
;   ② 按 Win+Z 只切换自动换行，不弹出系统的"贴边布局"面板；
;   ③ 不会顺带弹出开始菜单。②③ 是 AHK 在键盘钩子层拦截系统组合键，文档上
;   拦得住，但值得实测确认一次。若 ② 仍弹面板：设置 -> 系统 -> 多任务处理
;   里关掉"贴靠窗口"（代价是 Win+方向键的窗口分屏也没了）。
;
; 【备用写法】极少数程序会把 Alt+C 认成 Ctrl+Alt+C（因为 Alt 物理上还按着），
;   把该行改成显式释放 Alt 的写法：
;   !c::Send("{Alt up}^c{Alt down}")   ; 会短暂闪烁菜单栏，尽量少用
