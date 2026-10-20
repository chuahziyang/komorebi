#Requires AutoHotkey v2.0.2
#SingleInstance Force
!a::MsgBox("a")
!b::MsgBox("b")
!c::MsgBox("c")
!d::MsgBox("d")
!e::MsgBox("e")
!f::MsgBox("f")
!g::MsgBox("g")
!h::MsgBox("h")

try {
    Hotkey("!i", (*) => MsgBox("i works"))
} catch Error as err {
    MsgBox("Failed to register Alt+I: " . err.Message)
}

try {
    Hotkey("!a", (*) => MsgBox("i works"))
} catch Error as err {
    MsgBox("Failed to register Alt+I: " . err.Message)
}
!i::MsgBox("i")
!j::MsgBox("j")
!k::MsgBox("k")
!l::MsgBox("l")
!m::MsgBox("m")
!n::MsgBox("n")
!o::MsgBox("o")
!p::MsgBox("p")
!q::MsgBox("q")
!r::MsgBox("r")
!s::MsgBox("s")
!t::MsgBox("t")
!u::MsgBox("u")
!v::MsgBox("v")
!w::MsgBox("w")
!x::MsgBox("x")
!y::MsgBox("y")
!z::MsgBox("z")
