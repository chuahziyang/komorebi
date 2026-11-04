; Keep Zen fullscreen after switching away and back. komorebi resizes every window in
; a stack to fit the tile, including a fullscreen one, so it comes back short and the
; bar shows. Zen is still fullscreen then (no title bar or resize frame), so put it back
; over the whole monitor.
FULLSCREEN_CHECK_MS := 200
WS_CAPTION_OR_FRAME := 0xC40000

RestoreFullscreen() {
    try {
        hwnd := WinActive("ahk_exe zen.exe ahk_class MozillaWindowClass")
        if !hwnd || (WinGetStyle(hwnd) & WS_CAPTION_OR_FRAME)
            return

        monitor := DllCall("MonitorFromWindow", "Ptr", hwnd, "UInt", 2, "Ptr")
        info := Buffer(40)
        NumPut("UInt", 40, info)
        DllCall("GetMonitorInfo", "Ptr", monitor, "Ptr", info)
        left := NumGet(info, 4, "Int")
        top := NumGet(info, 8, "Int")
        width := NumGet(info, 12, "Int") - left
        height := NumGet(info, 16, "Int") - top

        WinGetPos(&x, &y, &w, &h, hwnd)
        if (x != left || y != top || w != width || h != height)
            WinMove(left, top, width, height, hwnd)
    }
}

SetTimer(RestoreFullscreen, FULLSCREEN_CHECK_MS)
