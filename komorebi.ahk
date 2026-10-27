#Requires AutoHotkey v2.0.2
#SingleInstance Force

Komorebic(cmd) {
    RunWait(format("komorebic.exe {}", cmd), , "Hide")
}

!q::Komorebic("close")
!m::Komorebic("minimize")
!u::Komorebic("promote")

; Focus windows
!a::Komorebic("focus left")
!s::Komorebic("focus down")
!w::Komorebic("focus up")
!d::Komorebic("focus right")

!+j::Komorebic("cycle-focus previous")
!+k::Komorebic("cycle-focus next")

; Move windows
!+a::Komorebic("move left")
!+s::Komorebic("move down")
!+w::Komorebic("move up")
!+d::Komorebic("move right")

; Stack windows
!Left::Komorebic("stack left")
!Down::Komorebic("stack down")
!Up::Komorebic("stack up")
!Right::Komorebic("stack right")
!l::Komorebic("unstack")
!j::Komorebic("cycle-stack previous")
!k::Komorebic("cycle-stack next")

; Resize
!=::Komorebic("resize-axis horizontal increase")
!-::Komorebic("resize-axis horizontal decrease")
!+=::Komorebic("resize-axis vertical increase")
!+_::Komorebic("resize-axis vertical decrease")

; Manipulate windows
!t::Komorebic("toggle-float")
!f::Komorebic("toggle-monocle")

; Window manager options
!r::Komorebic("retile")
!p::Komorebic("toggle-pause")

; Layouts
!x::Komorebic("flip-layout horizontal")
!y::Komorebic("flip-layout vertical")

; Workspaces
!1::Komorebic("focus-workspace 0")
!2::Komorebic("focus-workspace 1")
!3::Komorebic("focus-workspace 2")
!4::Komorebic("focus-workspace 3")
!5::Komorebic("focus-workspace 4")
!6::Komorebic("focus-workspace 5")
!7::Komorebic("focus-workspace 6")
!8::Komorebic("focus-workspace 7")

; Move windows across workspaces
!+1::Komorebic("move-to-workspace 0")
!+2::Komorebic("move-to-workspace 1")
!+3::Komorebic("move-to-workspace 2")
!+4::Komorebic("move-to-workspace 3")
!+5::Komorebic("move-to-workspace 4")
!+6::Komorebic("move-to-workspace 5")
!+7::Komorebic("move-to-workspace 6")
!+8::Komorebic("move-to-workspace 7")

; Move window to the other monitor (works even when that monitor's workspace is empty)
!+m::Komorebic("cycle-move-to-monitor next")

; Zen: Ctrl+J / Ctrl+K go to the next / previous tab in sidebar order
#HotIf WinActive("ahk_exe zen.exe")
^j::Send("^{PgDn}")
^k::Send("^{PgUp}")
#HotIf


+PrintScreen::Volume_Down
+Pause::Volume_Up
ScrollLock::Media_Play_Pause
!Pause::Media_Next
!PrintScreen::Media_Prev

; Keep the Windows taskbar hidden (YASB replaces it). Alt+Shift+B toggles it back.
global taskbarHidden := true

SetTaskbarVisible(visible) {
    DetectHiddenWindows(true)
    for cls in ["Shell_TrayWnd", "Shell_SecondaryTrayWnd"] {
        for hwnd in WinGetList("ahk_class " cls) {
            if visible
                WinShow("ahk_id " hwnd)
            else
                WinHide("ahk_id " hwnd)
        }
    }
    DetectHiddenWindows(false)
}

; Re-hide every couple of seconds in case Explorer restarts and brings it back
KeepTaskbarHidden() {
    if taskbarHidden
        SetTaskbarVisible(false)
}

SetTaskbarVisible(false)
SetTimer(KeepTaskbarHidden, 2000)

!+b:: {
    global taskbarHidden
    taskbarHidden := !taskbarHidden
    SetTaskbarVisible(!taskbarHidden)
}

; Two-row window switcher on Alt+G
#Include %A_LineFile%\..\switcher.ahk



