; Swap the default audio output (Alt+Shift+H), included by komorebi.ahk.
; Toggles between the devices below (matched by the start of their name) and
; shows the new one briefly. The monitors' HDMI audio outputs are left out.

AUDIO_SWAP := ["Headphones", "Speakers"]

; Active playback devices as [{id, name}], plus the current default's id
AudioOutputs(&defaultId) {
    enum := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
    defaultId := ""
    if ComCall(4, enum, "int", 0, "int", 0, "ptr*", &dev := 0) = 0 {   ; GetDefaultAudioEndpoint(eRender, eConsole)
        defaultId := AudioDeviceId(dev)
        ObjRelease(dev)
    }
    list := []
    ComCall(3, enum, "int", 0, "uint", 1, "ptr*", &coll := 0)   ; EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE)
    ComCall(3, coll, "uint*", &count := 0)
    loop count {
        ComCall(4, coll, "uint", A_Index - 1, "ptr*", &dev := 0)
        list.Push({id: AudioDeviceId(dev), name: AudioDeviceName(dev)})
        ObjRelease(dev)
    }
    ObjRelease(coll)
    return list
}

AudioDeviceId(dev) {
    ComCall(5, dev, "ptr*", &p := 0)   ; IMMDevice::GetId
    id := StrGet(p, "UTF-16")
    DllCall("ole32\CoTaskMemFree", "ptr", p)
    return id
}

AudioDeviceName(dev) {
    ComCall(4, dev, "uint", 0, "ptr*", &store := 0)   ; OpenPropertyStore(STGM_READ)
    key := Buffer(20)                                 ; PKEY_Device_FriendlyName
    DllCall("ole32\CLSIDFromString", "str", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "ptr", key)
    NumPut("uint", 14, key, 16)
    pv := Buffer(24, 0)
    ComCall(5, store, "ptr", key, "ptr", pv)          ; IPropertyStore::GetValue
    name := NumGet(pv, 0, "ushort") = 31 ? StrGet(NumGet(pv, 8, "ptr"), "UTF-16") : "?"   ; VT_LPWSTR
    DllCall("ole32\PropVariantClear", "ptr", pv)
    ObjRelease(store)
    return name
}

; Make a device the default for every role (console, multimedia, communications)
AudioSetDefault(id) {
    policy := ComObject("{870AF99C-171D-4F9E-AF0D-E63DF40C2BC9}", "{F8679F50-850A-41CF-9C72-430F290290C8}")
    loop 3
        ComCall(13, policy, "wstr", id, "int", A_Index - 1)   ; IPolicyConfig::SetDefaultEndpoint
}

AudioSwap() {
    list := []
    for d in AudioOutputs(&cur)
        for prefix in AUDIO_SWAP
            if InStr(d.name, prefix) = 1
                list.Push(d)
    if list.Length < 2 {
        ToolTip("Headphones or speakers aren't connected")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    next := 1
    for i, d in list
        if d.id = cur
            next := Mod(i, list.Length) + 1
    AudioSetDefault(list[next].id)
    ToolTip("🔊 " list[next].name)
    SetTimer(() => ToolTip(), -1500)
}

!+h::AudioSwap()
