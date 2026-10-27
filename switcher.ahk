; Two-row window switcher (Alt+G), included by komorebi.ahk.
; Row 1 = windows on the current monitor, row 2 = windows on the other monitor.
; Alt+G opens it (and closes it again). H/L move left/right, J/K move down/up a
; row, Enter or a click switches, Esc or clicking elsewhere cancels.

global Sw := {gui: 0, rows: [], cells: [], row: 1, col: 1, titleCtrl: 0}

SW_ICON := 48       ; icon size
SW_CELL := 64       ; tile size
SW_GAP := 8         ; space between tiles
SW_PAD := 14        ; space around the edge
SW_MAX_COLS := 20   ; most windows shown per row

SW_BG := "15141b"
SW_TILE := "1f1d29"
SW_TILE_ACTIVE := "3d375e"
SW_ACCENT := "a277ff"

SwIsOpen() => Sw.gui != 0

; Visible app windows in z-order (most recently used first), with their monitor.
; Includes minimized windows and ones komorebi has cloaked on other workspaces.
SwGetWindows() {
    list := []
    shell := DllCall("GetShellWindow", "ptr")
    ; AutoHotkey treats cloaked windows as hidden, and komorebi cloaks windows on
    ; other workspaces, so list hidden windows too and check WS_VISIBLE ourselves.
    ; (DetectHiddenWindows only lasts for the current hotkey thread.)
    DetectHiddenWindows(true)
    for hwnd in WinGetList() {
        try {
            if hwnd = shell || !(WinGetStyle(hwnd) & 0x10000000)   ; WS_VISIBLE
                continue
            title := WinGetTitle(hwnd)
            if title = ""
                continue
            ex := WinGetExStyle(hwnd)
            if ex & 0x08000020          ; WS_EX_NOACTIVATE / WS_EX_TRANSPARENT (overlays)
                continue
            appWindow := ex & 0x40000   ; WS_EX_APPWINDOW
            if (ex & 0x80) && !appWindow    ; tool windows
                continue
            if DllCall("GetWindow", "ptr", hwnd, "uint", 4, "ptr") && !appWindow   ; owned popups
                continue
            cls := WinGetClass(hwnd)
            if cls ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd|Windows\.UI\.Core\.CoreWindow)$"
                continue
            cloaked := 0
            DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14, "uint*", &cloaked, "uint", 4)
            if cloaked && cls = "ApplicationFrameWindow"   ; suspended Store apps
                continue
            proc := WinGetProcessName(hwnd)
            if proc ~= "i)^(yasb|ShellExperienceHost|SearchHost|StartMenuExperienceHost|TextInputHost)\.exe$"
                continue
            mon := DllCall("MonitorFromWindow", "ptr", hwnd, "uint", 2, "ptr")
            list.Push({hwnd: hwnd, mon: mon, title: title, proc: proc})
        }
    }
    return list
}

SwIcon(hwnd) {
    try {
        h := LoadPicture(WinGetProcessPath(hwnd), "w" SW_ICON " h" SW_ICON " Icon1", &type)
        if h
            return (type = 1 ? "HICON:" : "HBITMAP:") h
    }
    ; Fall back to the window's own icon (not ours to free, hence the *)
    h := 0
    try h := SendMessage(0x7F, 1, 0, , hwnd, , , , 200)   ; WM_GETICON, ICON_BIG
    if !h
        h := DllCall("GetClassLongPtr", "ptr", hwnd, "int", -14, "ptr")   ; GCLP_HICON
    return h ? "HICON:*" h : ""
}

SwOpen() {
    wins := SwGetWindows()
    if !wins.Length
        return

    ; The current monitor is the active window's, or the one under the mouse
    active := WinExist("A")
    if active
        curMon := DllCall("MonitorFromWindow", "ptr", active, "uint", 2, "ptr")
    else {
        DllCall("GetCursorPos", "int64*", &pt := 0)
        curMon := DllCall("MonitorFromPoint", "int64", pt, "uint", 2, "ptr")
    }

    mons := [curMon]
    for w in wins {
        known := false
        for m in mons
            if m = w.mon
                known := true
        if !known
            mons.Push(w.mon)
    }
    rows := []
    for m in mons {
        row := []
        for w in wins
            if w.mon = m && row.Length < SW_MAX_COLS
                row.Push(w)
        if row.Length
            rows.Push(row)
    }

    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +Border")
    g.BackColor := SW_BG
    g.SetFont("s10 cedecee", "Geist Mono")

    maxCols := 0
    cells := []
    for r, row in rows {
        maxCols := Max(maxCols, row.Length)
        y := SW_PAD + (r - 1) * (SW_CELL + 4 + SW_GAP)
        rowCells := []
        for c, w in row {
            x := SW_PAD + (c - 1) * (SW_CELL + SW_GAP)
            tile := g.Add("Text", Format("x{} y{} w{} h{} Background{}", x, y, SW_CELL, SW_CELL, SW_TILE))
            bar := g.Add("Text", Format("x{} y{} w{} h3 Background{}", x, y + SW_CELL + 1, SW_CELL, SW_BG))
            off := (SW_CELL - SW_ICON) // 2
            pic := 0
            if (icon := SwIcon(w.hwnd)) != ""
                try pic := g.Add("Picture", Format("x{} y{} w{} h{} BackgroundTrans", x + off, y + off, SW_ICON, SW_ICON), icon)
            if !pic
                pic := g.Add("Text", Format("x{} y{} w{} h{} BackgroundTrans Center", x + off, y + off + 14, SW_ICON, 20), SubStr(w.proc, 1, 4))
            pic.OnEvent("Click", SwClickCell.Bind(r, c))
            tile.OnEvent("Click", SwClickCell.Bind(r, c))
            rowCells.Push({tile: tile, bar: bar, pic: pic})
        }
        cells.Push(rowCells)
    }

    width := SW_PAD * 2 + maxCols * SW_CELL + (maxCols - 1) * SW_GAP
    titleY := SW_PAD + rows.Length * (SW_CELL + 4 + SW_GAP)
    Sw.titleCtrl := g.Add("Text", Format("x{} y{} w{} h20 Center c{}", SW_PAD, titleY, width - SW_PAD * 2, "61ffca"))
    height := titleY + 20 + SW_PAD

    Sw.gui := g
    Sw.rows := rows
    Sw.cells := cells

    ; Start on the window you're already in
    SwSelect(1, 1)
    for r, row in rows
        for c, w in row
            if w.hwnd = active
                SwSelect(r, c)

    ; Centre on the current monitor
    mi := Buffer(40, 0), NumPut("uint", 40, mi)
    DllCall("GetMonitorInfo", "ptr", curMon, "ptr", mi)
    left := NumGet(mi, 20, "int"), top := NumGet(mi, 24, "int")
    right := NumGet(mi, 28, "int"), bottom := NumGet(mi, 32, "int")
    g.Show(Format("x{} y{} w{} h{}", left + (right - left - width) // 2, top + (bottom - top - height) // 2, width, height))
    WinActivate(g.Hwnd)
}

; Close when it loses focus (clicking somewhere else)
SwOnActivate(wParam, lParam, msg, hwnd) {
    if SwIsOpen() && hwnd = Sw.gui.Hwnd && (wParam & 0xFFFF) = 0
        SetTimer(SwClose, -1)
}
OnMessage(0x0006, SwOnActivate)   ; WM_ACTIVATE

SwSelect(r, c) {
    if Sw.row <= Sw.cells.Length && Sw.col <= Sw.cells[Sw.row].Length
        SwPaint(Sw.cells[Sw.row][Sw.col], false)
    Sw.row := r, Sw.col := c
    SwPaint(Sw.cells[r][c], true)
    w := Sw.rows[r][c]
    Sw.titleCtrl.Value := RegExReplace(w.proc, "i)\.exe$") "  ·  " SubStr(w.title, 1, 80)
}

SwPaint(cell, selected) {
    cell.tile.Opt("+Background" (selected ? SW_TILE_ACTIVE : SW_TILE))
    cell.bar.Opt("+Background" (selected ? SW_ACCENT : SW_BG))
    cell.tile.Redraw(), cell.bar.Redraw(), cell.pic.Redraw()
}

SwStep(dir) {
    r := Sw.row, c := Sw.col + dir
    if c > Sw.rows[r].Length {
        r := Mod(r, Sw.rows.Length) + 1, c := 1
    } else if c < 1 {
        r := r = 1 ? Sw.rows.Length : r - 1, c := Sw.rows[r].Length
    }
    SwSelect(r, c)
}

SwMoveCol(dir) {
    n := Sw.rows[Sw.row].Length
    SwSelect(Sw.row, Mod(Sw.col - 1 + dir + n, n) + 1)
}

SwMoveRow(dir) {
    n := Sw.rows.Length
    r := Mod(Sw.row - 1 + dir + n, n) + 1
    SwSelect(r, Min(Sw.col, Sw.rows[r].Length))
}

SwClickCell(r, c, *) {
    SwSelect(r, c)
    SwCommit()
}

SwClose() {
    if Sw.gui
        Sw.gui.Destroy()
    Sw.gui := 0, Sw.rows := [], Sw.cells := [], Sw.row := 1, Sw.col := 1
}

SwCommit() {
    hwnd := Sw.rows[Sw.row][Sw.col].hwnd
    SwClose()
    DetectHiddenWindows(true)   ; the window may be cloaked on another workspace
    try {
        if WinGetMinMax(hwnd) = -1
            WinRestore(hwnd)
        WinActivate(hwnd)
    }
}

!g:: {
    if SwIsOpen()
        SwClose()
    else
        SwOpen()
}

; Keys work with or without Alt held
#HotIf SwIsOpen()
*h::SwMoveCol(-1)
*l::SwMoveCol(1)
*j::SwMoveRow(1)
*k::SwMoveRow(-1)
*Left::SwMoveCol(-1)
*Right::SwMoveCol(1)
*Down::SwMoveRow(1)
*Up::SwMoveRow(-1)
Tab::SwStep(1)
+Tab::SwStep(-1)
*Enter::SwCommit()
*Space::SwCommit()
*Esc::SwClose()
#HotIf
