-- ╔══════════════════════════════════════════════════════════╗
-- ║       macOS GUI  •  Finder-Style  •  v2                 ║
-- ║  Toggle  : RightShift   |  Destroy : RShift + Delete    ║
-- ║  Aimbot  : Hold X (default)                             ║
-- ║  NEW: Rivals speed/jump fix, global accent, ESP preview ║
-- ║       Character TP while aimbot key held                ║
-- ╚══════════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

-- ============================================================
--  CONFIG
-- ============================================================
local Config = {
    ESP = {
        Enabled=false, ShowBox=true, ShowName=true, ShowTracer=false,
        ShowFill=false, ShowHealthBar=false, ShowSkeleton=false,
        ShowDistance=false, ShowItem=false, Chams=false,
        BoxColor=Color3.fromRGB(255,255,255), NameColor=Color3.fromRGB(255,255,255),
        TracerColor=Color3.fromRGB(255,80,80), FillColor=Color3.fromRGB(255,255,255),
        SkeletonColor=Color3.fromRGB(255,255,255), ChamsColor=Color3.fromRGB(0,170,255),
        ChamsTransp=0.5, BoxThick=1, MaxDist=500,
    },
    Movement = {
        SpeedEnabled=false, Speed=32, SpeedMode="Rivals",
        JumpEnabled=false, JumpPower=100, JumpMode="Rivals",
        Noclip=false, NoclipMode="Normal",
        Fly=false, FlySpeed=60, InfJump=false,
    },
    Rivals = {
        ThirdPerson=false, ThirdPersonDist=12,
        DeviceSpoofEnabled=false, DeviceType="Mobile",
    },
    Aimbot = {
        Enabled=false, Smoothing=10, FovRadius=150,
        Key=Enum.KeyCode.X, TracerEnabled=false,
        TracerColor=Color3.fromRGB(255,60,60),
        SilentAim=false, SilentAimMode="Toggle",
        SilentAimKey=Enum.KeyCode.Z, SilentAimToggled=false,
        SilentAimFov=false, SilentAimFovRadius=150, AimType="MouseMove",
        CharTP=false, -- NEW: teleport above target while holding key
    },
    Weapons = {
        RapidFire=false, RapidFireSpeed=0.01, InstantReload=false,
        NoRecoil=false, RecoilReduction=100, NoSpread=false,
        NoWeaponBob=false, InstantADS=false, InstantEquip=false,
        NoEquipAnimation=false, InfiniteAmmo=false,
        InstantBulletTravel=false, ProjectileSpeed=false,
        ProjectileSpeedMultiplier=5,
        GunModule=nil, GameplayUtility=nil,
        OriginalStartShooting=nil, OriginalStartReloading=nil,
        OriginalRecoil=nil, OriginalGetSpread=nil,
        OriginalStartAiming=nil, OriginalGetAimSpeed=nil,
        OriginalEquip=nil, OriginalLocalTracers=nil,
        OriginalProjectileEffect=nil, OriginalGetRayOrigin=nil,
    },
}

-- ============================================================
--  SCREEN GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "MacOSGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer.PlayerGui
end

-- ============================================================
--  ACCENT REGISTRY  — every UI element tagged so global recolor works
-- ============================================================
local AccentElements = {
    -- tables of {object, property}  added by widgets
    navActive   = {},   -- nav btn BackgroundColor3 when active
    sliderFill  = {},   -- slider fill BackgroundColor3
    sliderVal   = {},   -- slider value TextColor3
    keybindText = {},   -- keybind TextColor3
    toggleOn    = {},   -- pill BackgroundColor3 when ON (stored refs)
    navBtnRef   = {},   -- all nav btn refs for active state update
}

-- ============================================================
--  macOS COLOUR PALETTE
-- ============================================================
local M = {
    Win        = Color3.fromRGB(236, 236, 236),
    Sidebar    = Color3.fromRGB(210, 210, 215),
    TitleBar   = Color3.fromRGB(220, 220, 223),
    Separator  = Color3.fromRGB(185, 185, 190),
    Row        = Color3.fromRGB(236, 236, 236),
    RowActive  = Color3.fromRGB(9,   101, 224),
    TextDark   = Color3.fromRGB(30,  30,  30),
    TextMid    = Color3.fromRGB(90,  90,  100),
    TextLight  = Color3.fromRGB(150, 150, 160),
    TextWhite  = Color3.fromRGB(255, 255, 255),
    Accent     = Color3.fromRGB(9,   101, 224),
    Red        = Color3.fromRGB(255, 59,  48),
    Yellow     = Color3.fromRGB(255, 189, 46),
    Green      = Color3.fromRGB(40,  200, 64),
    Content    = Color3.fromRGB(245, 245, 247),
    ToggleOff  = Color3.fromRGB(190, 190, 195),
    ToggleOn   = Color3.fromRGB(52,  199, 89),
    SliderBg   = Color3.fromRGB(200, 200, 205),
    SectionBg  = Color3.fromRGB(226, 226, 230),
    Border     = Color3.fromRGB(170, 170, 178),
}

-- Global recolor function — call after M.Accent changes
local function ApplyAccent(col)
    M.Accent    = col
    M.RowActive = col
    for _, obj in ipairs(AccentElements.sliderFill)  do pcall(function() obj.BackgroundColor3 = col end) end
    for _, obj in ipairs(AccentElements.sliderVal)   do pcall(function() obj.TextColor3       = col end) end
    for _, obj in ipairs(AccentElements.keybindText) do pcall(function() obj.TextColor3       = col end) end
    -- update active nav button
    for _, info in ipairs(AccentElements.navBtnRef) do
        if info.active then
            pcall(function() info.btn.BackgroundColor3 = col end)
        end
    end
end

local function R(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 6); return c
end
local function Stroke(parent, col, th)
    local s = Instance.new("UIStroke", parent)
    s.Color = col or M.Border; s.Thickness = th or 1; return s
end
local function Pad(parent, t, b, l, r)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop=UDim.new(0,t or 0); p.PaddingBottom=UDim.new(0,b or 0)
    p.PaddingLeft=UDim.new(0,l or 0); p.PaddingRight=UDim.new(0,r or 0)
end

-- ============================================================
--  WINDOW
-- ============================================================
local WIN_W, WIN_H = 560, 380
local SIDEBAR_W    = 155

local Shadow = Instance.new("Frame", ScreenGui)
Shadow.Size             = UDim2.new(0, WIN_W+8, 0, WIN_H+8)
Shadow.Position         = UDim2.new(0, 56, 0.5, -WIN_H/2-4)
Shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
Shadow.BackgroundTransparency = 0.7
Shadow.BorderSizePixel  = 0; Shadow.ZIndex = 1; R(Shadow, 14)

local Window = Instance.new("Frame", ScreenGui)
Window.Name             = "Window"
Window.Size             = UDim2.new(0, WIN_W, 0, WIN_H)
Window.Position         = UDim2.new(0, 60, 0.5, -WIN_H/2)
Window.BackgroundColor3 = M.Win
Window.BorderSizePixel  = 0; Window.ZIndex = 2
Window.Active = true; Window.Draggable = true
R(Window, 12); Stroke(Window, M.Border, 1)

-- Title bar
local TitleBar = Instance.new("Frame", Window)
TitleBar.Size             = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = M.TitleBar
TitleBar.BorderSizePixel  = 0; TitleBar.ZIndex = 3; R(TitleBar, 12)
local TFix = Instance.new("Frame", TitleBar)
TFix.Size=UDim2.new(1,0,0,12); TFix.Position=UDim2.new(0,0,1,-12)
TFix.BackgroundColor3=M.TitleBar; TFix.BorderSizePixel=0; TFix.ZIndex=3
local TSep = Instance.new("Frame", TitleBar)
TSep.Size=UDim2.new(1,0,0,1); TSep.Position=UDim2.new(0,0,1,-1)
TSep.BackgroundColor3=M.Separator; TSep.BorderSizePixel=0; TSep.ZIndex=4

local function TrafficBtn(parent, color, xOff)
    local b = Instance.new("TextButton", parent)
    b.Size=UDim2.new(0,13,0,13); b.Position=UDim2.new(0,xOff,0.5,-6)
    b.BackgroundColor3=color; b.Text=""; b.BorderSizePixel=0; b.ZIndex=5
    R(b,99); Stroke(b, Color3.new(0,0,0), 0.3); return b
end
local CloseBtn    = TrafficBtn(TitleBar, M.Red,    12)
local MinimizeBtn = TrafficBtn(TitleBar, M.Yellow, 30)
local MaximizeBtn = TrafficBtn(TitleBar, M.Green,  48)

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size=UDim2.new(1,-140,1,0); TitleLbl.Position=UDim2.new(0,70,0,0)
TitleLbl.BackgroundTransparency=1; TitleLbl.Text="MacOS GUI"
TitleLbl.TextColor3=M.TextDark; TitleLbl.Font=Enum.Font.GothamBold
TitleLbl.TextSize=13; TitleLbl.TextXAlignment=Enum.TextXAlignment.Center; TitleLbl.ZIndex=4

local function TBtn(parent, icon, x)
    local b=Instance.new("TextButton",parent)
    b.Size=UDim2.new(0,24,0,22); b.Position=UDim2.new(1,x,0.5,-11)
    b.BackgroundColor3=Color3.fromRGB(200,200,205); b.Text=icon
    b.TextColor3=M.TextMid; b.Font=Enum.Font.GothamBold; b.TextSize=11
    b.BorderSizePixel=0; b.ZIndex=5; R(b,5); return b
end
TBtn(TitleBar,"⚙",-32); TBtn(TitleBar,"↑↓",-60)

-- Sidebar
local Sidebar = Instance.new("Frame", Window)
Sidebar.Size=UDim2.new(0,SIDEBAR_W,1,-38); Sidebar.Position=UDim2.new(0,0,0,38)
Sidebar.BackgroundColor3=M.Sidebar; Sidebar.BorderSizePixel=0; Sidebar.ZIndex=3; R(Sidebar,12)
local SBTopFix=Instance.new("Frame",Sidebar)
SBTopFix.Size=UDim2.new(1,0,0,12); SBTopFix.BackgroundColor3=M.Sidebar; SBTopFix.BorderSizePixel=0; SBTopFix.ZIndex=3
local SBSep=Instance.new("Frame",Sidebar)
SBSep.Size=UDim2.new(0,1,1,0); SBSep.Position=UDim2.new(1,-1,0,0)
SBSep.BackgroundColor3=M.Separator; SBSep.BorderSizePixel=0; SBSep.ZIndex=4

local SBScroll=Instance.new("ScrollingFrame",Sidebar)
SBScroll.Size=UDim2.new(1,-1,1,0); SBScroll.BackgroundTransparency=1
SBScroll.BorderSizePixel=0; SBScroll.ScrollBarThickness=0
SBScroll.CanvasSize=UDim2.new(0,0,0,0); SBScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; SBScroll.ZIndex=4
local SBLayout=Instance.new("UIListLayout",SBScroll); SBLayout.SortOrder=Enum.SortOrder.LayoutOrder
Pad(SBScroll,6,6,0,0)

-- Content area
local ContentArea=Instance.new("Frame",Window)
ContentArea.Size=UDim2.new(1,-SIDEBAR_W,1,-38); ContentArea.Position=UDim2.new(0,SIDEBAR_W,0,38)
ContentArea.BackgroundColor3=M.Content; ContentArea.BorderSizePixel=0; ContentArea.ZIndex=3; R(ContentArea,12)
local CATopFix=Instance.new("Frame",ContentArea)
CATopFix.Size=UDim2.new(1,0,0,12); CATopFix.BackgroundColor3=M.Content; CATopFix.BorderSizePixel=0; CATopFix.ZIndex=3
local Pages=Instance.new("Frame",ContentArea)
Pages.Size=UDim2.new(1,0,1,0); Pages.BackgroundTransparency=1; Pages.BorderSizePixel=0; Pages.ZIndex=4

-- ============================================================
--  WIDGET HELPERS
-- ============================================================
local function MakeSection(parent, text, order)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,0,0,22); f.BackgroundColor3=M.SectionBg
    f.BorderSizePixel=0; f.LayoutOrder=order or 0; f.ZIndex=5
    local lbl=Instance.new("TextLabel",f)
    lbl.Size=UDim2.new(1,-16,1,0); lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=M.TextLight
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6; return lbl
end

local function MakeSep(parent, order)
    local s=Instance.new("Frame",parent)
    s.Size=UDim2.new(1,-10,0,1); s.Position=UDim2.new(0,5,1,-1)
    s.BackgroundColor3=M.Separator; s.BorderSizePixel=0
    s.BackgroundTransparency=0.5; s.ZIndex=5; if order then s.LayoutOrder=order end
    return s
end

local function MakeToggle(parent, label, default, callback, order)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=M.Win
    row.BorderSizePixel=0; row.LayoutOrder=order or 0; row.ZIndex=5
    MakeSep(row)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-68,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=M.TextDark
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6
    local pill=Instance.new("Frame",row)
    pill.Size=UDim2.new(0,44,0,26); pill.Position=UDim2.new(1,-54,0.5,-13)
    pill.BackgroundColor3=default and M.ToggleOn or M.ToggleOff
    pill.BorderSizePixel=0; pill.ZIndex=6; R(pill,99)
    local knob=Instance.new("Frame",pill)
    knob.Size=UDim2.new(0,22,0,22)
    knob.Position=default and UDim2.new(1,-24,0.5,-11) or UDim2.new(0,2,0.5,-11)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255); knob.BorderSizePixel=0; knob.ZIndex=7; R(knob,99)
    local state=default
    local hit=Instance.new("TextButton",row)
    hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=8
    hit.MouseButton1Click:Connect(function()
        state=not state
        pill.BackgroundColor3=state and M.ToggleOn or M.ToggleOff
        knob.Position=state and UDim2.new(1,-24,0.5,-11) or UDim2.new(0,2,0.5,-11)
        if callback then callback(state) end
    end)
    return row, pill, knob
end

local function MakeSlider(parent, label, min, max, default, callback, order)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,50); row.BackgroundColor3=M.Win
    row.BorderSizePixel=0; row.LayoutOrder=order or 0; row.ZIndex=5
    MakeSep(row)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.6,0,0,18); lbl.Position=UDim2.new(0,12,0,6)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=M.TextDark
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6
    local valLbl=Instance.new("TextLabel",row)
    valLbl.Size=UDim2.new(0.4,-12,0,18); valLbl.Position=UDim2.new(0.6,0,0,6)
    valLbl.BackgroundTransparency=1; valLbl.Text=tostring(default)
    valLbl.TextColor3=M.Accent; valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=13
    valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.ZIndex=6
    table.insert(AccentElements.sliderVal, valLbl)
    local track=Instance.new("Frame",row)
    track.Size=UDim2.new(1,-24,0,4); track.Position=UDim2.new(0,12,1,-16)
    track.BackgroundColor3=M.SliderBg; track.BorderSizePixel=0; track.ZIndex=6; R(track,99)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3=M.Accent; fill.BorderSizePixel=0; fill.ZIndex=7; R(fill,99)
    table.insert(AccentElements.sliderFill, fill)
    local dragging=false
    local hit=Instance.new("TextButton",track)
    hit.Size=UDim2.new(1,0,0,28); hit.Position=UDim2.new(0,0,0.5,-14)
    hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=8
    local function apply(ax)
        local rel=math.clamp((ax-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local val=math.floor(min+rel*(max-min))
        fill.Size=UDim2.new(rel,0,1,0); valLbl.Text=tostring(val)
        if callback then callback(val) end
    end
    hit.MouseButton1Down:Connect(function() dragging=true end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then apply(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    return row
end

local function MakeCycle(parent, label, options, default, callback, order)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=M.Win
    row.BorderSizePixel=0; row.LayoutOrder=order or 0; row.ZIndex=5
    MakeSep(row)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.5,0,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=M.TextDark
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6
    local cb2=Instance.new("TextButton",row)
    cb2.Size=UDim2.new(0,106,0,22); cb2.Position=UDim2.new(1,-116,0.5,-11)
    cb2.BackgroundColor3=Color3.fromRGB(220,220,225); cb2.Text=default.."  ▾"
    cb2.TextColor3=M.TextDark; cb2.Font=Enum.Font.Gotham; cb2.TextSize=12
    cb2.BorderSizePixel=0; cb2.ZIndex=7; R(cb2,6); Stroke(cb2,M.Border,1)
    local idx=1
    for i,v in ipairs(options) do if v==default then idx=i break end end
    cb2.MouseButton1Click:Connect(function()
        idx=(idx%#options)+1; cb2.Text=options[idx].."  ▾"
        if callback then callback(options[idx]) end
    end)
    return row
end

local function MakeKeybind(parent, label, default, callback, order)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=M.Win
    row.BorderSizePixel=0; row.LayoutOrder=order or 0; row.ZIndex=5
    MakeSep(row)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.52,0,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=M.TextDark
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6
    local kb=Instance.new("TextButton",row)
    kb.Size=UDim2.new(0,60,0,22); kb.Position=UDim2.new(1,-70,0.5,-11)
    kb.BackgroundColor3=Color3.fromRGB(220,220,225)
    kb.Text=tostring(default):gsub("Enum.KeyCode.","")
    kb.TextColor3=M.Accent; kb.Font=Enum.Font.GothamBold; kb.TextSize=12
    kb.BorderSizePixel=0; kb.ZIndex=7; R(kb,6); Stroke(kb,M.Border,1)
    table.insert(AccentElements.keybindText, kb)
    local listening=false
    kb.MouseButton1Click:Connect(function()
        if listening then return end; listening=true
        kb.Text="..."; kb.TextColor3=Color3.fromRGB(255,150,0)
        local conn
        conn=UserInputService.InputBegan:Connect(function(input,gpe)
            if gpe then return end
            local skip={[Enum.KeyCode.LeftShift]=1,[Enum.KeyCode.RightShift]=1,
                        [Enum.KeyCode.LeftControl]=1,[Enum.KeyCode.RightControl]=1}
            if input.UserInputType==Enum.UserInputType.Keyboard and not skip[input.KeyCode] then
                kb.Text=tostring(input.KeyCode):gsub("Enum.KeyCode.","")
                kb.TextColor3=M.Accent; listening=false; conn:Disconnect()
                if callback then callback(input.KeyCode) end
            end
        end)
    end)
    return kb
end

local function MakeColorPicker(parent, label, defaultColor, callback, startOrder)
    local r0=math.floor(defaultColor.R*255)
    local g0=math.floor(defaultColor.G*255)
    local b0=math.floor(defaultColor.B*255)
    local cr,cg,cb2=r0,g0,b0
    local hdr=Instance.new("Frame",parent)
    hdr.Size=UDim2.new(1,0,0,30); hdr.BackgroundColor3=M.SectionBg
    hdr.BorderSizePixel=0; hdr.LayoutOrder=startOrder or 0; hdr.ZIndex=5
    local hdrLbl=Instance.new("TextLabel",hdr)
    hdrLbl.Size=UDim2.new(1,-44,1,0); hdrLbl.Position=UDim2.new(0,12,0,0)
    hdrLbl.BackgroundTransparency=1; hdrLbl.Text=label; hdrLbl.TextColor3=M.TextMid
    hdrLbl.Font=Enum.Font.GothamBold; hdrLbl.TextSize=11
    hdrLbl.TextXAlignment=Enum.TextXAlignment.Left; hdrLbl.ZIndex=6
    local swatch=Instance.new("Frame",hdr)
    swatch.Size=UDim2.new(0,26,0,16); swatch.Position=UDim2.new(1,-36,0.5,-8)
    swatch.BackgroundColor3=defaultColor; swatch.BorderSizePixel=0; swatch.ZIndex=6
    R(swatch,5); Stroke(swatch,M.Border,1)
    local function fire()
        local col=Color3.fromRGB(cr,cg,cb2)
        swatch.BackgroundColor3=col; if callback then callback(col) end
    end
    local channels={
        {name="R",getV=function() return cr end,setV=function(v) cr=v end,col=Color3.fromRGB(200,50,50), def=r0,order=startOrder+1},
        {name="G",getV=function() return cg end,setV=function(v) cg=v end,col=Color3.fromRGB(50,185,80), def=g0,order=startOrder+2},
        {name="B",getV=function() return cb2 end,setV=function(v) cb2=v end,col=Color3.fromRGB(60,120,220),def=b0,order=startOrder+3},
    }
    for _,ch in ipairs(channels) do
        local row=Instance.new("Frame",parent)
        row.Size=UDim2.new(1,0,0,28); row.BackgroundColor3=M.Win
        row.BorderSizePixel=0; row.LayoutOrder=ch.order; row.ZIndex=5
        MakeSep(row)
        local cLbl=Instance.new("TextLabel",row)
        cLbl.Size=UDim2.new(0,16,1,0); cLbl.Position=UDim2.new(0,12,0,0)
        cLbl.BackgroundTransparency=1; cLbl.Text=ch.name; cLbl.TextColor3=ch.col
        cLbl.Font=Enum.Font.GothamBold; cLbl.TextSize=12; cLbl.ZIndex=6
        local vLbl=Instance.new("TextLabel",row)
        vLbl.Size=UDim2.new(0,28,1,0); vLbl.Position=UDim2.new(1,-34,0,0)
        vLbl.BackgroundTransparency=1; vLbl.Text=tostring(ch.def); vLbl.TextColor3=M.TextMid
        vLbl.Font=Enum.Font.GothamBold; vLbl.TextSize=11
        vLbl.TextXAlignment=Enum.TextXAlignment.Right; vLbl.ZIndex=6
        local track=Instance.new("Frame",row)
        track.Size=UDim2.new(1,-62,0,4); track.Position=UDim2.new(0,30,0.5,-2)
        track.BackgroundColor3=M.SliderBg; track.BorderSizePixel=0; track.ZIndex=6; R(track,99)
        local fill=Instance.new("Frame",track)
        fill.Size=UDim2.new(ch.def/255,0,1,0); fill.BackgroundColor3=ch.col
        fill.BorderSizePixel=0; fill.ZIndex=7; R(fill,99)
        local dragging=false
        local hit=Instance.new("TextButton",track)
        hit.Size=UDim2.new(1,0,0,24); hit.Position=UDim2.new(0,0,0.5,-12)
        hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=8
        local function applyAt(ax)
            local rel=math.clamp((ax-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local val=math.floor(rel*255)
            fill.Size=UDim2.new(rel,0,1,0); vLbl.Text=tostring(val); ch.setV(val); fire()
        end
        hit.MouseButton1Down:Connect(function() dragging=true end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then applyAt(i.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
        end)
    end
end

-- ============================================================
--  PAGE / NAV SYSTEM
-- ============================================================
local ActivePage=nil; local ActiveNavBtn=nil; local pageOrder=0

local function MakePage(populateFn)
    local page=Instance.new("ScrollingFrame",Pages)
    page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1
    page.BorderSizePixel=0; page.ScrollBarThickness=4
    page.ScrollBarImageColor3=Color3.fromRGB(170,170,180)
    page.CanvasSize=UDim2.new(0,0,0,0); page.AutomaticCanvasSize=Enum.AutomaticSize.Y
    page.Visible=false; page.ZIndex=4
    local layout=Instance.new("UIListLayout",page); layout.SortOrder=Enum.SortOrder.LayoutOrder
    Pad(page,4,10,0,4); populateFn(page); return page
end

local function AddNavEntry(icon, name, page)
    pageOrder=pageOrder+1
    local btn=Instance.new("TextButton",SBScroll)
    btn.Size=UDim2.new(1,-8,0,30); btn.Position=UDim2.new(0,4,0,0)
    btn.BackgroundColor3=Color3.fromRGB(0,0,0); btn.BackgroundTransparency=1
    btn.Text=""; btn.BorderSizePixel=0; btn.LayoutOrder=pageOrder; btn.ZIndex=5; R(btn,6)
    local iconL=Instance.new("TextLabel",btn)
    iconL.Size=UDim2.new(0,22,1,0); iconL.Position=UDim2.new(0,8,0,0)
    iconL.BackgroundTransparency=1; iconL.Text=icon; iconL.TextColor3=M.Accent
    iconL.Font=Enum.Font.GothamBold; iconL.TextSize=14; iconL.ZIndex=6
    local nameL=Instance.new("TextLabel",btn)
    nameL.Size=UDim2.new(1,-36,1,0); nameL.Position=UDim2.new(0,32,0,0)
    nameL.BackgroundTransparency=1; nameL.Text=name; nameL.TextColor3=M.TextDark
    nameL.Font=Enum.Font.Gotham; nameL.TextSize=13
    nameL.TextXAlignment=Enum.TextXAlignment.Left; nameL.ZIndex=6
    local info={btn=btn,nameL=nameL,iconL=iconL,active=false}
    table.insert(AccentElements.navBtnRef, info)
    if pageOrder==1 then
        btn.BackgroundTransparency=0; btn.BackgroundColor3=M.RowActive
        nameL.TextColor3=M.TextWhite; iconL.TextColor3=M.TextWhite
        page.Visible=true; ActivePage=page; ActiveNavBtn=info; info.active=true
    end
    btn.MouseButton1Click:Connect(function()
        if ActiveNavBtn then
            ActiveNavBtn.btn.BackgroundTransparency=1
            ActiveNavBtn.nameL.TextColor3=M.TextDark; ActiveNavBtn.iconL.TextColor3=M.Accent
            ActiveNavBtn.active=false
        end
        if ActivePage then ActivePage.Visible=false end
        btn.BackgroundTransparency=0; btn.BackgroundColor3=M.RowActive
        nameL.TextColor3=M.TextWhite; iconL.TextColor3=M.TextWhite
        page.Visible=true; ActivePage=page; ActiveNavBtn=info; info.active=true
    end)
    return btn
end

local function SBSection(text, order)
    local f=Instance.new("Frame",SBScroll)
    f.Size=UDim2.new(1,-8,0,18); f.Position=UDim2.new(0,4,0,0)
    f.BackgroundTransparency=1; f.BorderSizePixel=0; f.LayoutOrder=order; f.ZIndex=5
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-8,1,0); l.Position=UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1; l.Text=text; l.TextColor3=M.TextLight
    l.Font=Enum.Font.GothamBold; l.TextSize=10
    l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=6
end

-- ============================================================
--  BUILD PAGES
-- ============================================================
SBSection("VISUALS", 0)

-- ── ESP OBJECTS (declared early so ESP page can reference them in preview) ────
local ESPObjects={}; local ChamObjects={}

-- ── ESP PAGE with inline preview ──────────────────────────
local espPage=MakePage(function(s)
    MakeSection(s, "ESP", 1)
    MakeToggle(s,"Enable ESP",   false,function(v) Config.ESP.Enabled      =v end,2)
    MakeToggle(s,"Boxes",        true, function(v) Config.ESP.ShowBox      =v end,3)
    MakeToggle(s,"Box Fill",     false,function(v) Config.ESP.ShowFill     =v end,4)
    MakeToggle(s,"Names",        true, function(v) Config.ESP.ShowName     =v end,5)
    MakeToggle(s,"Tracers",      false,function(v) Config.ESP.ShowTracer   =v end,6)
    MakeToggle(s,"Health Bar",   false,function(v) Config.ESP.ShowHealthBar=v end,7)
    MakeToggle(s,"Skeleton",     false,function(v) Config.ESP.ShowSkeleton =v end,8)
    MakeToggle(s,"Distance",     false,function(v) Config.ESP.ShowDistance =v end,9)
    MakeToggle(s,"Item Held",    false,function(v) Config.ESP.ShowItem     =v end,10)
    MakeToggle(s,"Chams",        false,function(v)
        Config.ESP.Chams=v
        if not v then for plr,hl in pairs(ChamObjects) do pcall(function() hl:Destroy() end); ChamObjects[plr]=nil end end
    end,11)

    -- ── ESP PREVIEW PANEL ──────────────────────────────────
    MakeSection(s,"ESP PREVIEW",12)
    local previewRow=Instance.new("Frame",s)
    previewRow.Size=UDim2.new(1,0,0,160); previewRow.BackgroundColor3=Color3.fromRGB(18,18,22)
    previewRow.BorderSizePixel=0; previewRow.LayoutOrder=13; previewRow.ZIndex=5
    R(previewRow,6)

    -- Dark "game world" background
    local previewBg=Instance.new("Frame",previewRow)
    previewBg.Size=UDim2.new(1,-4,1,-4); previewBg.Position=UDim2.new(0,2,0,2)
    previewBg.BackgroundColor3=Color3.fromRGB(30,35,45); previewBg.BorderSizePixel=0; previewBg.ZIndex=5; R(previewBg,4)

    -- Ground line
    local ground=Instance.new("Frame",previewBg)
    ground.Size=UDim2.new(1,0,0,1); ground.Position=UDim2.new(0,0,1,-30)
    ground.BackgroundColor3=Color3.fromRGB(60,65,75); ground.BorderSizePixel=0; ground.ZIndex=6

    -- Avatar silhouette (simplified Roblox R15 block figure)
    local avatarCX=0.5  -- center X fraction of previewBg

    local function AvatarPart(px,py,pw,ph,col)
        local p=Instance.new("Frame",previewBg)
        -- px,py in fraction coords from center-bottom of avatar (feet at ground)
        -- avatar is ~110px tall; ground is 30px from bottom
        local avatarH=110; local groundY=30
        p.Size=UDim2.new(0,pw,0,ph)
        p.Position=UDim2.new(avatarCX,px-pw/2,1,-(groundY+py+ph))
        p.BackgroundColor3=col; p.BorderSizePixel=0; p.ZIndex=7; R(p,2)
        return p
    end

    -- Body parts (rough R15 silhouette)
    local skinTone=Color3.fromRGB(255,200,160)
    local clothTop=Color3.fromRGB(90,130,200)
    local clothBot=Color3.fromRGB(60,80,150)
    local shoe    =Color3.fromRGB(40,40,40)

    -- feet
    AvatarPart(-10, 0, 12, 10, shoe)
    AvatarPart( 10, 0, 12, 10, shoe)
    -- lower legs
    AvatarPart(-10,10, 11, 22, clothBot)
    AvatarPart( 10,10, 11, 22, clothBot)
    -- upper legs
    AvatarPart(-10,32, 12, 22, clothBot)
    AvatarPart( 10,32, 12, 22, clothBot)
    -- torso
    AvatarPart(  0,54, 28, 32, clothTop)
    -- left arm
    AvatarPart(-22,54, 10, 28, clothTop)
    -- right arm
    AvatarPart( 22,54, 10, 28, clothTop)
    -- neck
    AvatarPart(  0,86,  8,  6, skinTone)
    -- head
    local headPart=AvatarPart(0,92, 24, 22, skinTone)

    -- ── PREVIEW OVERLAYS (Drawing-like UI overlays) ────────
    -- We use Frames/TextLabels on top of the preview to simulate ESP

    -- Box outline (4 lines via frames)
    local bx,by,bw,bh = 0.5-0.135, 1-(30+5)/156, 0.27, 0.72
    -- convert to absolute-ish within previewBg using UDim2
    local boxLeft   = Instance.new("Frame",previewBg)
    local boxRight  = Instance.new("Frame",previewBg)
    local boxTop    = Instance.new("Frame",previewBg)
    local boxBottom = Instance.new("Frame",previewBg)
    local function SetBoxColor(c)
        boxLeft.BackgroundColor3=c; boxRight.BackgroundColor3=c
        boxTop.BackgroundColor3=c; boxBottom.BackgroundColor3=c
    end
    local function ShowBox(v) boxLeft.Visible=v; boxRight.Visible=v; boxTop.Visible=v; boxBottom.Visible=v end
    -- left
    boxLeft.Size=UDim2.new(0,1,0,116); boxLeft.Position=UDim2.new(0.5,-19,0,12)
    boxLeft.BackgroundColor3=Config.ESP.BoxColor; boxLeft.BorderSizePixel=0; boxLeft.ZIndex=9
    -- right
    boxRight.Size=UDim2.new(0,1,0,116); boxRight.Position=UDim2.new(0.5,18,0,12)
    boxRight.BackgroundColor3=Config.ESP.BoxColor; boxRight.BorderSizePixel=0; boxRight.ZIndex=9
    -- top
    boxTop.Size=UDim2.new(0,38,0,1); boxTop.Position=UDim2.new(0.5,-19,0,12)
    boxTop.BackgroundColor3=Config.ESP.BoxColor; boxTop.BorderSizePixel=0; boxTop.ZIndex=9
    -- bottom
    boxBottom.Size=UDim2.new(0,38,0,1); boxBottom.Position=UDim2.new(0.5,-19,0,128)
    boxBottom.BackgroundColor3=Config.ESP.BoxColor; boxBottom.BorderSizePixel=0; boxBottom.ZIndex=9

    -- Name tag
    local nameTag=Instance.new("TextLabel",previewBg)
    nameTag.Size=UDim2.new(0,80,0,14); nameTag.Position=UDim2.new(0.5,-40,0,0)
    nameTag.BackgroundTransparency=1; nameTag.Text="Player"
    nameTag.TextColor3=Config.ESP.NameColor; nameTag.Font=Enum.Font.GothamBold
    nameTag.TextSize=11; nameTag.TextXAlignment=Enum.TextXAlignment.Center; nameTag.ZIndex=9

    -- Health bar
    local hpBg=Instance.new("Frame",previewBg)
    hpBg.Size=UDim2.new(0,4,0,116); hpBg.Position=UDim2.new(0.5,-26,0,12)
    hpBg.BackgroundColor3=Color3.fromRGB(20,20,20); hpBg.BorderSizePixel=0; hpBg.ZIndex=9
    local hpFill=Instance.new("Frame",hpBg)
    hpFill.Size=UDim2.new(1,0,0.8,0); hpFill.Position=UDim2.new(0,0,0.2,0)
    hpFill.BackgroundColor3=Color3.fromRGB(50,220,80); hpFill.BorderSizePixel=0; hpFill.ZIndex=10

    -- Distance label
    local distTag=Instance.new("TextLabel",previewBg)
    distTag.Size=UDim2.new(0,80,0,12); distTag.Position=UDim2.new(0.5,-40,1,-28)
    distTag.BackgroundTransparency=1; distTag.Text="42m"
    distTag.TextColor3=Color3.fromRGB(200,200,200); distTag.Font=Enum.Font.Gotham
    distTag.TextSize=10; distTag.TextXAlignment=Enum.TextXAlignment.Center; distTag.ZIndex=9

    -- Tracer (line from bottom center to avatar feet)
    local tracer=Instance.new("Frame",previewBg)
    tracer.Size=UDim2.new(0,1,0,30); tracer.Position=UDim2.new(0.5,0,1,-30)
    tracer.BackgroundColor3=Config.ESP.TracerColor; tracer.BorderSizePixel=0; tracer.ZIndex=9

    -- Skeleton lines (simplified: just a few key lines as thin frames)
    local skelLines={}
    local function SkelLine(x1f,y1,x2f,y2)
        -- very rough: just draw small dots at joints
        local ln=Instance.new("Frame",previewBg)
        local cx=(x1f+x2f)/2; local cy=(y1+y2)/2
        local len=math.sqrt(((x2f-x1f)*38)^2+(y2-y1)^2)
        ln.Size=UDim2.new(0,math.max(1,math.floor(len)),0,1)
        ln.Position=UDim2.new(0.5,math.floor(cx)-math.floor(len/2),0,math.floor(cy))
        ln.BackgroundColor3=Config.ESP.SkeletonColor; ln.BorderSizePixel=0; ln.ZIndex=9
        table.insert(skelLines,ln)
        return ln
    end
    -- spine
    SkelLine(0,20,0,92)
    -- shoulders
    SkelLine(-0.5,60,0.5,60)
    -- left arm
    SkelLine(-0.3,60,-0.5,84)
    -- right arm
    SkelLine(0.3,60,0.5,84)
    -- left leg
    SkelLine(-0.15,20,-0.25,54)
    -- right leg
    SkelLine(0.15,20,0.25,54)

    -- Update preview every frame based on current Config
    local previewConn
    previewConn=RunService.RenderStepped:Connect(function()
        if not previewRow.Parent then previewConn:Disconnect(); return end
        ShowBox(Config.ESP.ShowBox)
        SetBoxColor(Config.ESP.BoxColor)
        nameTag.Visible=Config.ESP.ShowName; nameTag.TextColor3=Config.ESP.NameColor
        hpBg.Visible=Config.ESP.ShowHealthBar; hpFill.Visible=Config.ESP.ShowHealthBar
        distTag.Visible=Config.ESP.ShowDistance
        tracer.Visible=Config.ESP.ShowTracer; tracer.BackgroundColor3=Config.ESP.TracerColor
        for _,ln in ipairs(skelLines) do
            ln.Visible=Config.ESP.ShowSkeleton; ln.BackgroundColor3=Config.ESP.SkeletonColor
        end
        -- Box fill overlay (semi-transparent tint on the avatar area)
        previewBg.BackgroundColor3 = Config.ESP.ShowFill
            and Color3.fromRGB(
                math.floor(Config.ESP.FillColor.R*255*0.3+30*0.7),
                math.floor(Config.ESP.FillColor.G*255*0.3+35*0.7),
                math.floor(Config.ESP.FillColor.B*255*0.3+45*0.7))
            or Color3.fromRGB(30,35,45)
    end)

    MakeSection(s,"COLOURS",20)
    MakeColorPicker(s,"Box",     Config.ESP.BoxColor,     function(c) Config.ESP.BoxColor     =c; for _,e in pairs(ESPObjects) do if e.Box    then e.Box.Color=c    end end end,21)
    MakeColorPicker(s,"Fill",    Config.ESP.FillColor,    function(c) Config.ESP.FillColor    =c; for _,e in pairs(ESPObjects) do if e.BoxFill then e.BoxFill.Color=c end end end,25)
    MakeColorPicker(s,"Name",    Config.ESP.NameColor,    function(c) Config.ESP.NameColor    =c; for _,e in pairs(ESPObjects) do if e.Name   then e.Name.Color=c   end end end,29)
    MakeColorPicker(s,"Tracer",  Config.ESP.TracerColor,  function(c) Config.ESP.TracerColor  =c; for _,e in pairs(ESPObjects) do if e.Tracer then e.Tracer.Color=c end end end,33)
    MakeColorPicker(s,"Skeleton",Config.ESP.SkeletonColor,function(c)
        Config.ESP.SkeletonColor=c
        for _,e in pairs(ESPObjects) do if e.Skeleton then for _,ln in ipairs(e.Skeleton) do ln.Color=c end end end
    end,37)
    MakeColorPicker(s,"Chams",Config.ESP.ChamsColor,function(c)
        Config.ESP.ChamsColor=c; for _,hl in pairs(ChamObjects) do hl.FillColor=c; hl.OutlineColor=c end
    end,41)
end)
AddNavEntry("👁","ESP",espPage)

-- ── AIMBOT ────────────────────────────────────────────────
local TargetTracer
local aimbotPage=MakePage(function(s)
    local secLbl=MakeSection(s,"AIMBOT  —  hold X to lock on",1)
    MakeToggle(s,"Enable Aimbot",  false,function(v) Config.Aimbot.Enabled      =v end,2)
    MakeToggle(s,"Target Tracer",  false,function(v) Config.Aimbot.TracerEnabled=v end,3)
    MakeToggle(s,"Character TP",   false,function(v) Config.Aimbot.CharTP       =v end,4)
    MakeCycle(s, "Aim Type",{"MouseMove","CFrame"},"MouseMove",function(v) Config.Aimbot.AimType=v end,5)
    MakeKeybind(s,"Lock Key",Enum.KeyCode.X,function(k)
        Config.Aimbot.Key=k
        secLbl.Text="AIMBOT  —  hold "..tostring(k):gsub("Enum.KeyCode.","").." to lock on"
    end,6)
    MakeSlider(s,"Smoothing",  1, 30, 10, function(v) Config.Aimbot.Smoothing =v end,7)
    MakeSlider(s,"FOV Radius",10,800,150, function(v) Config.Aimbot.FovRadius =v end,8)
    MakeSection(s,"SILENT AIM",9)
    MakeToggle(s,"Silent Aim",       false,function(v) Config.Aimbot.SilentAim   =v end,10)
    MakeToggle(s,"Silent FOV",       false,function(v) Config.Aimbot.SilentAimFov=v end,11)
    MakeSlider(s,"Silent FOV Radius",10,800,150,function(v) Config.Aimbot.SilentAimFovRadius=v end,12)
    MakeCycle(s,"Silent Mode",{"Always","Toggle","Hold"},"Toggle",function(v)
        Config.Aimbot.SilentAimMode=v; Config.Aimbot.SilentAimToggled=false
    end,13)
    MakeKeybind(s,"Silent Key",Enum.KeyCode.Z,function(k) Config.Aimbot.SilentAimKey=k end,14)
    MakeSection(s,"COLOURS",15)
    MakeColorPicker(s,"Tracer Colour",Color3.fromRGB(255,60,60),function(c)
        Config.Aimbot.TracerColor=c; if TargetTracer then TargetTracer.Color=c end
    end,16)
end)
AddNavEntry("🎯","Aimbot",aimbotPage)

SBSection("CHARACTER",40)

-- ── MOVEMENT ──────────────────────────────────────────────
local movPage=MakePage(function(s)
    MakeSection(s,"WALK SPEED",1)
    MakeToggle(s,"Enable Speed",  false,function(v) Config.Movement.SpeedEnabled=v end,2)
    MakeCycle(s, "Speed Mode",{"Normal","Rivals"},"Rivals",function(v) Config.Movement.SpeedMode=v end,3)
    MakeSlider(s,"Walk Speed",16,200,32,function(v) Config.Movement.Speed=v end,4)
    MakeSection(s,"JUMP POWER",5)
    MakeToggle(s,"Enable Jump",   false,function(v) Config.Movement.JumpEnabled=v end,6)
    MakeCycle(s, "Jump Mode",{"Normal","Rivals"},"Rivals",function(v) Config.Movement.JumpMode=v end,7)
    MakeSlider(s,"Jump Power",50,300,100,function(v) Config.Movement.JumpPower=v end,8)
    MakeSection(s,"NOCLIP",9)
    MakeToggle(s,"Enable Noclip",false,function(v) Config.Movement.Noclip=v end,10)
    MakeCycle(s, "Noclip Mode",{"Normal","Rivals"},"Normal",function(v) Config.Movement.NoclipMode=v end,11)
    MakeSection(s,"FLY",12)
    MakeToggle(s,"Fly [WASD+Space/LCtrl]",false,function(v) Config.Movement.Fly=v end,13)
    MakeSlider(s,"Fly Speed",10,200,60,function(v) Config.Movement.FlySpeed=v end,14)
    MakeSection(s,"MISC",15)
    MakeToggle(s,"Infinite Jump",false,function(v) Config.Movement.InfJump=v end,16)
end)
AddNavEntry("⚡","Movement",movPage)

-- ── WEAPONS ───────────────────────────────────────────────
local weapPage=MakePage(function(s)
    MakeSection(s,"SHOOTING",1)
    MakeToggle(s,"Rapid Fire",           false,function(v) Config.Weapons.RapidFire          =v end,2)
    MakeSlider(s,"Fire Cooldown (ms)",1,500,10, function(v) Config.Weapons.RapidFireSpeed     =v/1000 end,3)
    MakeToggle(s,"Infinite Ammo",        false,function(v) Config.Weapons.InfiniteAmmo        =v end,4)
    MakeToggle(s,"No Spread",            false,function(v) Config.Weapons.NoSpread            =v end,5)
    MakeToggle(s,"Instant Bullet Travel",false,function(v) Config.Weapons.InstantBulletTravel =v end,6)
    MakeToggle(s,"Projectile Speed",     false,function(v) Config.Weapons.ProjectileSpeed     =v end,7)
    MakeSlider(s,"Speed Multiplier",1,20,5,    function(v) Config.Weapons.ProjectileSpeedMultiplier=v end,8)
    MakeSection(s,"RECOIL & ADS",9)
    MakeToggle(s,"No Recoil",            false,function(v) Config.Weapons.NoRecoil            =v end,10)
    MakeSlider(s,"Recoil Reduction",0,100,100, function(v) Config.Weapons.RecoilReduction     =v end,11)
    MakeToggle(s,"No Weapon Bob",        false,function(v) Config.Weapons.NoWeaponBob         =v end,12)
    MakeToggle(s,"Instant ADS",          false,function(v) Config.Weapons.InstantADS          =v end,13)
    MakeSection(s,"EQUIP",14)
    MakeToggle(s,"Instant Reload",       false,function(v) Config.Weapons.InstantReload       =v end,15)
    MakeToggle(s,"Instant Equip",        false,function(v) Config.Weapons.InstantEquip        =v end,16)
    MakeToggle(s,"No Equip Animation",   false,function(v) Config.Weapons.NoEquipAnimation    =v end,17)
end)
AddNavEntry("🔫","Weapons",weapPage)

SBSection("GAME",50)

-- ── RIVALS ────────────────────────────────────────────────
local rivPage=MakePage(function(s)
    MakeSection(s,"CAMERA",1)
    MakeToggle(s,"3rd Person",  false,function(v) Config.Rivals.ThirdPerson       =v end,2)
    MakeSlider(s,"Camera Dist",4,40,12,function(v) Config.Rivals.ThirdPersonDist  =v end,3)
    MakeSection(s,"DEVICE SPOOFER",4)
    MakeToggle(s,"Spoof Device",false,function(v) Config.Rivals.DeviceSpoofEnabled=v end,5)
    MakeCycle(s, "Device Type",{"Mobile","Console","PC"},"Mobile",function(v) Config.Rivals.DeviceType=v end,6)
end)
AddNavEntry("🎮","Rivals",rivPage)

-- ── INFO ──────────────────────────────────────────────────
local infoPage=MakePage(function(s)
    MakeSection(s,"ACCOUNT",1)
    local function InfoRow(parent,labelText,value,order)
        local row=Instance.new("Frame",parent)
        row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=M.Win
        row.BorderSizePixel=0; row.LayoutOrder=order; row.ZIndex=5
        MakeSep(row)
        local lbl=Instance.new("TextLabel",row)
        lbl.Size=UDim2.new(0.48,0,1,0); lbl.Position=UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=labelText; lbl.TextColor3=M.TextMid
        lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6
        local val=Instance.new("TextLabel",row)
        val.Size=UDim2.new(0.52,-12,1,0); val.Position=UDim2.new(0.48,0,0,0)
        val.BackgroundTransparency=1; val.Text=tostring(value); val.TextColor3=M.Accent
        val.Font=Enum.Font.Gotham; val.TextSize=12
        val.TextXAlignment=Enum.TextXAlignment.Right; val.TextTruncate=Enum.TextTruncate.AtEnd; val.ZIndex=6
        table.insert(AccentElements.sliderVal,val)
        return val
    end
    InfoRow(s,"Username",    LocalPlayer.Name,       2)
    InfoRow(s,"Display Name",LocalPlayer.DisplayName,3)
    local av=InfoRow(s,"Account Age","",4); av.Text=LocalPlayer.AccountAge.."d"
    MakeSection(s,"LIVE STATS",5)
    local hv=InfoRow(s,"Health","—",6)
    RunService.Heartbeat:Connect(function()
        local char=LocalPlayer.Character; local hum=char and char:FindFirstChild("Humanoid")
        if hum then
            hv.Text=math.floor(hum.Health).." / "..math.floor(hum.MaxHealth)
            local pct=hum.Health/math.max(hum.MaxHealth,1)
            hv.TextColor3=pct>0.6 and Color3.fromRGB(34,180,60) or (pct>0.3 and Color3.fromRGB(230,160,0) or M.Red)
        else hv.Text="Dead"; hv.TextColor3=M.Red end
    end)
end)
AddNavEntry("👤","Info",infoPage)

SBSection("SETTINGS",60)

-- ── SETTINGS ──────────────────────────────────────────────
local setPage=MakePage(function(s)
    MakeSection(s,"ACCENT COLOUR — changes entire UI",1)
    -- We hook into MakeColorPicker callback to call ApplyAccent
    MakeColorPicker(s,"Accent",M.Accent,function(col)
        ApplyAccent(col)
    end,2)
end)
AddNavEntry("⚙","Settings",setPage)

-- ============================================================
--  TRAFFIC LIGHTS
-- ============================================================
local minimized=false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    Sidebar.Visible=not minimized; ContentArea.Visible=not minimized
    Window.Size   =minimized and UDim2.new(0,WIN_W,0,38)    or UDim2.new(0,WIN_W,0,WIN_H)
    Shadow.Size   =minimized and UDim2.new(0,WIN_W+8,0,46)  or UDim2.new(0,WIN_W+8,0,WIN_H+8)
end)
CloseBtn.MouseButton1Click:Connect(function()
    Window.Visible=false; Shadow.Visible=false
end)
MaximizeBtn.MouseButton1Click:Connect(function()
    Window.Visible=true; Shadow.Visible=true
    if minimized then
        minimized=false; Sidebar.Visible=true; ContentArea.Visible=true
        Window.Size=UDim2.new(0,WIN_W,0,WIN_H); Shadow.Size=UDim2.new(0,WIN_W+8,0,WIN_H+8)
    end
end)

-- ============================================================
--  RSHIFT TOGGLE
-- ============================================================
local _guiVisible=true
UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode==Enum.KeyCode.RightShift then
        _guiVisible=not _guiVisible
        Window.Visible=_guiVisible; Shadow.Visible=_guiVisible
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not Config.Aimbot.Enabled then return end
    if not UserInputService:IsKeyDown(Config.Aimbot.Key) then return end
    if input.UserInputType==Enum.UserInputType.MouseWheel then
        Config.Aimbot.FovRadius=math.clamp(Config.Aimbot.FovRadius+input.Position.Z*10,10,800)
    end
end)

UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.UserInputType~=Enum.UserInputType.Keyboard then return end
    if input.KeyCode==Config.Aimbot.SilentAimKey and Config.Aimbot.SilentAimMode=="Toggle" then
        Config.Aimbot.SilentAimToggled=not Config.Aimbot.SilentAimToggled
    end
end)

-- ============================================================
--  RIVALS WEAPON HOOKS
-- ============================================================
local RS=game:GetService("ReplicatedStorage")
local W=Config.Weapons

task.spawn(function()
    local ok,GM=pcall(function() return require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun) end)
    if not ok or not GM then return end
    W.GunModule=GM
    if GM.StartShooting then
        W.OriginalStartShooting=GM.StartShooting
        GM.StartShooting=function(self,p1,p2)
            if W.InfiniteAmmo and self:Get("Ammo")<=0 then self:SetReplicate("Ammo",self.Info.MaxAmmo) end
            local oSC,oBC
            if W.RapidFire then oSC=self.Info.ShootCooldown; oBC=self.Info.ShootBurstCooldown; self.Info.ShootCooldown=W.RapidFireSpeed; self.Info.ShootBurstCooldown=W.RapidFireSpeed end
            local res={W.OriginalStartShooting(self,p1,p2)}
            if W.RapidFire then self.Info.ShootCooldown=oSC; self.Info.ShootBurstCooldown=oBC end
            return unpack(res)
        end
    end
    if GM.StartReloading then
        W.OriginalStartReloading=GM.StartReloading
        GM.StartReloading=function(self,p1,p2,p3)
            if W.InstantReload then
                self:_ResetReloadState()
                local cur,max2,res2=self:Get("Ammo"),self.Info.MaxAmmo,self:Get("AmmoReserve")
                if cur<max2 and res2>0 then local need=math.min(max2-cur,res2); self:SetReplicate("Ammo",cur+need); self:SetReplicate("AmmoReserve",res2-need) end
                return true,"StartReloading",self:ToEnum("Reload")
            end
            return W.OriginalStartReloading(self,p1,p2,p3)
        end
    end
    if GM._Recoil then
        W.OriginalRecoil=GM._Recoil
        GM._Recoil=function(self,mult)
            if W.NoRecoil then local r=mult*(1-W.RecoilReduction/100); if r<=0.001 then return end; return W.OriginalRecoil(self,r) end
            return W.OriginalRecoil(self,mult)
        end
    end
    if GM.StartAiming then
        W.OriginalStartAiming=GM.StartAiming
        GM.StartAiming=function(self,p1)
            if W.InstantADS then self:SetReplicate("IsAiming",true); self.StopSprinting:Fire(); self.ViewModel:SetAiming(true); self:SetReplicate("FOVOffset",self.Info.AimFOVOffset); if self.ViewModel.CurrentAimValue then self.ViewModel.CurrentAimValue=1 end; return true,"StartAiming" end
            return W.OriginalStartAiming(self,p1)
        end
    end
    if GM.GetAimSpeed then
        W.OriginalGetAimSpeed=GM.GetAimSpeed
        GM.GetAimSpeed=function(self) if W.InstantADS then return 999 end; return W.OriginalGetAimSpeed(self) end
    end
    if GM.Equip then
        W.OriginalEquip=GM.Equip
        GM.Equip=function(self,...)
            if W.InstantEquip then self._is_revolver_quick_shooting=nil; self._shoot_cooldown=0; self:_ResetReloadState(); return end
            if W.NoEquipAnimation then local res={W.OriginalEquip(self,...)}; if self.ViewModel then self.ViewModel:StopAnimation("Equip"); self.ViewModel:StopAnimation("EquipEmpty") end; return unpack(res) end
            return W.OriginalEquip(self,...)
        end
    end
    if GM._ProjectileEffect then
        W.OriginalProjectileEffect=GM._ProjectileEffect
        GM._ProjectileEffect=function(self,proj,p2)
            if W.ProjectileSpeed and proj and proj.Velocity then proj.Velocity=proj.Velocity*W.ProjectileSpeedMultiplier end
            return W.OriginalProjectileEffect(self,proj,p2)
        end
    end
    if GM._LocalTracers then
        W.OriginalLocalTracers=GM._LocalTracers
        GM._LocalTracers=function(self,p1,p2)
            if W.InstantBulletTravel then
                local oP,oB,oA=self.Info.RaycastPierceCount,self.Info.RaycastBounceCount,self.Info.RaycastBounceRedirectionAngle
                self.Info.RaycastPierceCount=999; self.Info.RaycastBounceCount=0; self.Info.RaycastBounceRedirectionAngle=0
                local res={W.OriginalLocalTracers(self,p1,p2)}
                self.Info.RaycastPierceCount=oP; self.Info.RaycastBounceCount=oB; self.Info.RaycastBounceRedirectionAngle=oA
                return unpack(res)
            end
            return W.OriginalLocalTracers(self,p1,p2)
        end
    end
end)

task.spawn(function()
    local ok,GU=pcall(function() return require(RS.Modules.GameplayUtility) end)
    if not ok or not GU or not GU.GetSpread then return end
    W.GameplayUtility=GU; W.OriginalGetSpread=GU.GetSpread
    GU.GetSpread=function(sp,am,ia,ic,pl,tot,con)
        if W.NoSpread then return CFrame.new() end
        return W.OriginalGetSpread(sp,am,ia,ic,pl,tot,con)
    end
end)

task.spawn(function()
    local ok,VM=pcall(function() return require(LocalPlayer.PlayerScripts.Modules.ViewModel) end)
    if not ok or not VM or not VM.new then return end
    local origNew=VM.new
    VM.new=function(...)
        local vm=origNew(...)
        if vm.Update then
            local origUpd=vm.Update
            vm.Update=function(self,...)
                if W.NoWeaponBob then if self.BobSpeed then self.BobSpeed=0 end; if self.BobIntensity then self.BobIntensity=0 end end
                return origUpd(self,...)
            end
        end
        return vm
    end
end)

-- ============================================================
--  RIVALS SPEED / JUMP FIX
--  Rivals stores speed/jump in its own Character module not hum
--  We hook the Character module AND set humanoid as backup
-- ============================================================
local RivalsCharModule=nil; local RivalsOrigGetSpeed=nil; local RivalsOrigGetJump=nil

task.spawn(function()
    -- Try to find Rivals character stats module
    local paths={
        function() return require(LocalPlayer.PlayerScripts.Modules.Character) end,
        function() return require(LocalPlayer.PlayerScripts.Modules.CharacterController) end,
        function() return require(LocalPlayer.PlayerScripts.Modules.Player) end,
    }
    for _,fn in ipairs(paths) do
        local ok,mod=pcall(fn)
        if ok and mod then RivalsCharModule=mod; break end
    end
    -- Hook GetSpeed if available
    if RivalsCharModule then
        if RivalsCharModule.GetSpeed then
            RivalsOrigGetSpeed=RivalsCharModule.GetSpeed
            RivalsCharModule.GetSpeed=function(self,...)
                if Config.Movement.SpeedEnabled and Config.Movement.SpeedMode=="Rivals" then
                    return Config.Movement.Speed
                end
                return RivalsOrigGetSpeed(self,...)
            end
        end
        if RivalsCharModule.GetJumpPower then
            RivalsOrigGetJump=RivalsCharModule.GetJumpPower
            RivalsCharModule.GetJumpPower=function(self,...)
                if Config.Movement.JumpEnabled and Config.Movement.JumpMode=="Rivals" then
                    return Config.Movement.JumpPower
                end
                return RivalsOrigGetJump(self,...)
            end
        end
    end
end)

-- ============================================================
--  ESP SKELETON
-- ============================================================
local BONES={
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}

-- ============================================================
--  ESP CREATE / REMOVE
-- ============================================================
local function RemoveESP(player)
    if ESPObjects[player] then
        local e=ESPObjects[player]
        for _,key in ipairs({"Box","BoxFill","Name","Tracer","HealthBarBG","HealthBarFill","Distance","Item"}) do
            pcall(function() e[key]:Remove() end)
        end
        if e.Skeleton then for _,ln in ipairs(e.Skeleton) do pcall(function() ln:Remove() end) end end
        ESPObjects[player]=nil
    end
    if ChamObjects[player] then pcall(function() ChamObjects[player]:Destroy() end); ChamObjects[player]=nil end
end

local function CreateESP(player)
    if player==LocalPlayer then return end
    RemoveESP(player)
    local sk={}
    for i=1,#BONES do
        local ln=Drawing.new("Line"); ln.Visible=false; ln.Thickness=1; ln.Color=Config.ESP.SkeletonColor; sk[i]=ln
    end
    local e={
        Box=Drawing.new("Square"),BoxFill=Drawing.new("Square"),
        Name=Drawing.new("Text"),Tracer=Drawing.new("Line"),
        HealthBarBG=Drawing.new("Square"),HealthBarFill=Drawing.new("Square"),
        Distance=Drawing.new("Text"),Item=Drawing.new("Text"),Skeleton=sk,
    }
    e.Box.Visible=false; e.Box.Filled=false; e.Box.Color=Config.ESP.BoxColor; e.Box.Thickness=Config.ESP.BoxThick
    e.BoxFill.Visible=false; e.BoxFill.Filled=true; e.BoxFill.Color=Config.ESP.FillColor; e.BoxFill.Transparency=0.75
    e.Name.Visible=false; e.Name.Center=true; e.Name.Outline=true; e.Name.Size=13; e.Name.Font=Drawing.Fonts.UI; e.Name.Color=Config.ESP.NameColor
    e.Tracer.Visible=false; e.Tracer.Color=Config.ESP.TracerColor; e.Tracer.Thickness=1
    e.HealthBarBG.Visible=false; e.HealthBarBG.Filled=true; e.HealthBarBG.Color=Color3.fromRGB(20,20,20); e.HealthBarBG.Transparency=1
    e.HealthBarFill.Visible=false; e.HealthBarFill.Filled=true; e.HealthBarFill.Color=Color3.fromRGB(50,220,80); e.HealthBarFill.Transparency=1
    e.Distance.Visible=false; e.Distance.Center=true; e.Distance.Outline=true; e.Distance.Size=12; e.Distance.Font=Drawing.Fonts.UI; e.Distance.Color=Color3.fromRGB(220,220,220)
    e.Item.Visible=false; e.Item.Center=true; e.Item.Outline=true; e.Item.Size=12; e.Item.Font=Drawing.Fonts.UI; e.Item.Color=Color3.fromRGB(255,210,80)
    ESPObjects[player]=e
end

for _,p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(function(p) CreateESP(p); p.CharacterAdded:Connect(function() task.wait(0.1); CreateESP(p) end) end)
Players.PlayerRemoving:Connect(RemoveESP)
for _,p in ipairs(Players:GetPlayers()) do
    if p~=LocalPlayer then p.CharacterAdded:Connect(function() task.wait(0.1); CreateESP(p) end) end
end

-- ============================================================
--  FLY
-- ============================================================
local flyConn
local function StartFly()
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local bp=Instance.new("BodyVelocity",root); bp.MaxForce=Vector3.new(1e5,1e5,1e5); bp.Velocity=Vector3.zero
    local bg=Instance.new("BodyGyro",root); bg.MaxTorque=Vector3.new(1e5,1e5,1e5); bg.D=100
    flyConn=RunService.RenderStepped:Connect(function()
        if not Config.Movement.Fly then pcall(function() bp:Destroy(); bg:Destroy() end); flyConn:Disconnect(); return end
        local dir=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)           then dir+=Camera.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)           then dir-=Camera.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)           then dir-=Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)           then dir+=Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir+=Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir-=Vector3.new(0,1,0) end
        bp.Velocity=dir.Magnitude>0 and dir.Unit*Config.Movement.FlySpeed or Vector3.zero
        bg.CFrame=Camera.CFrame
    end)
end
local _pFly=false
RunService.Heartbeat:Connect(function()
    if Config.Movement.Fly~=_pFly then _pFly=Config.Movement.Fly; if Config.Movement.Fly then StartFly() end end
end)

-- ============================================================
--  FOV DRAWINGS
-- ============================================================
local FovFill=Drawing.new("Circle")
FovFill.Visible=false; FovFill.Radius=Config.Aimbot.FovRadius; FovFill.Color=Color3.fromRGB(255,255,255); FovFill.Transparency=0.2; FovFill.Thickness=1; FovFill.Filled=true
local FovCircle=Drawing.new("Circle")
FovCircle.Visible=false; FovCircle.Radius=Config.Aimbot.FovRadius; FovCircle.Color=Color3.fromRGB(205,205,205); FovCircle.Thickness=1; FovCircle.Filled=false
TargetTracer=Drawing.new("Line")
TargetTracer.Visible=false; TargetTracer.Color=Config.Aimbot.TracerColor; TargetTracer.Thickness=1; TargetTracer.Transparency=1
local FovCirclePos=UserInputService:GetMouseLocation()

-- ============================================================
--  CHARACTER TP STATE
-- ============================================================
local charTPActive=false
local charTPOrigPos=nil   -- original CFrame before TP
local charTPTarget=nil    -- current target HRP

local function CharTPStart(targetHRP)
    local myChar=LocalPlayer.Character; if not myChar then return end
    local myRoot=myChar:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
    if not charTPActive then
        charTPOrigPos=myRoot.CFrame
        charTPActive=true
    end
    charTPTarget=targetHRP
    -- Teleport 5 studs above their head each frame (done in render loop)
end

local function CharTPStop()
    if not charTPActive then return end
    charTPActive=false
    charTPTarget=nil
    -- Restore original position
    local myChar=LocalPlayer.Character
    local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myRoot and charTPOrigPos then
        pcall(function() myRoot.CFrame=charTPOrigPos end)
    end
    charTPOrigPos=nil
end

-- ============================================================
--  RENDER LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    -- ESP
    for player,d in pairs(ESPObjects) do
        local char=player.Character
        local hum=char and char:FindFirstChild("Humanoid")
        local root=char and char:FindFirstChild("HumanoidRootPart")
        local ok=Config.ESP.Enabled and char and root and hum and hum.Health>0
        if Config.ESP.Chams and ok then
            if not ChamObjects[player] then
                local hl=Instance.new("Highlight")
                hl.FillColor=Config.ESP.ChamsColor; hl.FillTransparency=Config.ESP.ChamsTransp
                hl.OutlineColor=Config.ESP.ChamsColor; hl.OutlineTransparency=0.3
                hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee=char; hl.Parent=char
                ChamObjects[player]=hl
            end
        elseif ChamObjects[player] then pcall(function() ChamObjects[player]:Destroy() end); ChamObjects[player]=nil end
        local function hideAll()
            d.Box.Visible=false; d.BoxFill.Visible=false; d.Name.Visible=false; d.Tracer.Visible=false
            d.HealthBarBG.Visible=false; d.HealthBarFill.Visible=false; d.Distance.Visible=false; d.Item.Visible=false
            if d.Skeleton then for _,ln in ipairs(d.Skeleton) do ln.Visible=false end end
        end
        if not ok then hideAll(); continue end
        local dist=(Camera.CFrame.Position-root.Position).Magnitude
        if dist>Config.ESP.MaxDist then hideAll(); continue end
        local rp,onS=Camera:WorldToViewportPoint(root.Position)
        if not onS then hideAll(); continue end
        local tp2=Camera:WorldToViewportPoint(root.Position+Vector3.new(0,3.2,0))
        local bp3=Camera:WorldToViewportPoint(root.Position-Vector3.new(0,3.2,0))
        local bH=math.abs(tp2.Y-bp3.Y); local bW=bH*0.55
        local bX=rp.X-bW/2; local bY=tp2.Y
        if Config.ESP.ShowBox then d.Box.Size=Vector2.new(bW,bH); d.Box.Position=Vector2.new(bX,bY); d.Box.Color=Config.ESP.BoxColor; d.Box.Visible=true else d.Box.Visible=false end
        if Config.ESP.ShowFill then d.BoxFill.Size=Vector2.new(bW,bH); d.BoxFill.Position=Vector2.new(bX,bY); d.BoxFill.Color=Config.ESP.FillColor; d.BoxFill.Transparency=0.75; d.BoxFill.Visible=true else d.BoxFill.Visible=false end
        if Config.ESP.ShowHealthBar then
            local pct=hum.Health/math.max(hum.MaxHealth,1); local bx2=bX-7
            d.HealthBarBG.Size=Vector2.new(4,bH); d.HealthBarBG.Position=Vector2.new(bx2,bY); d.HealthBarBG.Transparency=1; d.HealthBarBG.Visible=true
            local fH=math.max(1,bH*pct); d.HealthBarFill.Size=Vector2.new(4,fH); d.HealthBarFill.Position=Vector2.new(bx2,bY+bH-fH); d.HealthBarFill.Transparency=1
            d.HealthBarFill.Color=pct>0.6 and Color3.fromRGB(50,220,80) or (pct>0.3 and Color3.fromRGB(230,180,40) or Color3.fromRGB(220,50,50)); d.HealthBarFill.Visible=true
        else d.HealthBarBG.Visible=false; d.HealthBarFill.Visible=false end
        if Config.ESP.ShowName then
            local np=Camera:WorldToViewportPoint(root.Position+Vector3.new(0,3.8,0))
            d.Name.Text=player.Name; d.Name.Position=Vector2.new(np.X,np.Y); d.Name.Color=Config.ESP.NameColor; d.Name.Visible=true
        else d.Name.Visible=false end
        if Config.ESP.ShowTracer then
            d.Tracer.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y); d.Tracer.To=Vector2.new(rp.X,rp.Y); d.Tracer.Color=Config.ESP.TracerColor; d.Tracer.Visible=true
        else d.Tracer.Visible=false end
        local textY=bY+bH+2
        if Config.ESP.ShowDistance then d.Distance.Text=math.floor(dist).."m"; d.Distance.Position=Vector2.new(rp.X,textY); d.Distance.Visible=true; textY=textY+14 else d.Distance.Visible=false end
        if Config.ESP.ShowItem then
            local tool=char:FindFirstChildOfClass("Tool")
            if tool then d.Item.Text="🔧 "..tool.Name; d.Item.Position=Vector2.new(rp.X,textY); d.Item.Visible=true else d.Item.Visible=false end
        else d.Item.Visible=false end
        if Config.ESP.ShowSkeleton then
            for i,pair in ipairs(BONES) do
                local ln=d.Skeleton[i]; local pA=char:FindFirstChild(pair[1]); local pB=char:FindFirstChild(pair[2])
                if pA and pB then
                    local sA,okA=Camera:WorldToViewportPoint(pA.Position); local sB,okB=Camera:WorldToViewportPoint(pB.Position)
                    if okA and okB then ln.From=Vector2.new(sA.X,sA.Y); ln.To=Vector2.new(sB.X,sB.Y); ln.Color=Config.ESP.SkeletonColor; ln.Visible=true else ln.Visible=false end
                else ln.Visible=false end
            end
        else if d.Skeleton then for _,ln in ipairs(d.Skeleton) do ln.Visible=false end end end
    end

    -- FOV
    local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    local mousePos=UserInputService:GetMouseLocation()
    FovCirclePos=FovCirclePos:Lerp(mousePos,0.18)
    FovFill.Position=FovCirclePos; FovFill.Radius=Config.Aimbot.FovRadius; FovFill.Visible=Config.Aimbot.Enabled
    FovCircle.Position=FovCirclePos; FovCircle.Radius=Config.Aimbot.FovRadius; FovCircle.Visible=Config.Aimbot.Enabled

    local function GetTarget(fovR,useMouse)
        local ref=useMouse and mousePos or center; local best,bestD=nil,fovR
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl==LocalPlayer then continue end
            local ch=pl.Character; if not ch then continue end
            local hd=ch:FindFirstChild("Head"); local hm=ch:FindFirstChild("Humanoid")
            if not hd or not hm or hm.Health<=0 then continue end
            local sp,onS=Camera:WorldToViewportPoint(hd.Position); if not onS then continue end
            local dd=(Vector2.new(sp.X,sp.Y)-ref).Magnitude
            if dd<bestD then bestD=dd; best={head=hd,char=ch} end
        end
        return best
    end

    -- Aimbot + Character TP
    local keyHeld=Config.Aimbot.Enabled and UserInputService:IsKeyDown(Config.Aimbot.Key)
    if keyHeld then
        local tdata=GetTarget(Config.Aimbot.FovRadius,true)
        if tdata then
            local target=tdata.head
            local hp,onS=Camera:WorldToViewportPoint(target.Position)
            if onS then
                local sm=math.max(1,Config.Aimbot.Smoothing)
                if Config.Aimbot.AimType=="MouseMove" then
                    local delta=Vector2.new(hp.X,hp.Y)-center
                    mousemoverel(math.clamp(delta.X/sm,-50,50), math.clamp(delta.Y/sm,-50,50))
                else Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,target.Position),1/sm) end
                TargetTracer.Color=Config.Aimbot.TracerColor; TargetTracer.From=Vector2.new(hp.X,hp.Y); TargetTracer.To=mousePos; TargetTracer.Visible=Config.Aimbot.TracerEnabled
            else TargetTracer.Visible=false end

            -- Character TP: teleport 5 studs above target's head each frame
            if Config.Aimbot.CharTP then
                local targetChar=tdata.char
                local targetRoot=targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local myChar=LocalPlayer.Character
                    local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        if not charTPActive then
                            charTPOrigPos=myRoot.CFrame
                            charTPActive=true
                        end
                        -- Sit 5 studs above their head, matching their rotation
                        local abovePos=targetRoot.Position+Vector3.new(0,9,0)
                        pcall(function()
                            myRoot.CFrame=CFrame.new(abovePos,abovePos+Camera.CFrame.LookVector)
                        end)
                    end
                end
            end
        else
            TargetTracer.Visible=false
        end
    else
        TargetTracer.Visible=false
        -- Restore position when key released
        if charTPActive then CharTPStop() end
    end
end)

-- ============================================================
--  SILENT AIM
-- ============================================================
local function SilentAimActive()
    if not Config.Aimbot.SilentAim then return false end
    local m=Config.Aimbot.SilentAimMode
    if m=="Always" then return true end
    if m=="Toggle" then return Config.Aimbot.SilentAimToggled end
    if m=="Hold"   then return UserInputService:IsKeyDown(Config.Aimbot.SilentAimKey) end
    return false
end

local function GetSilentTarget()
    if not SilentAimActive() then return nil end
    local mp=UserInputService:GetMouseLocation(); local best,bestD=nil,math.huge
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==LocalPlayer then continue end
        local ch=pl.Character; if not ch then continue end
        local hd=ch:FindFirstChild("Head"); local hm=ch:FindFirstChild("Humanoid")
        if not hd or not hm or hm.Health<=0 then continue end
        local sp,onS=Camera:WorldToViewportPoint(hd.Position); if not onS then continue end
        local dd=(Vector2.new(sp.X,sp.Y)-mp).Magnitude
        if Config.Aimbot.SilentAimFov and dd>Config.Aimbot.SilentAimFovRadius then continue end
        if dd<bestD then bestD=dd; best=hd end
    end
    return best
end

local _silentActive=false; local _silentCF=nil; local _origCamIdx=nil
pcall(function()
    local mt=getrawmetatable(Camera); if not mt then return end
    local oldIdx=rawget(mt,"__index"); if not oldIdx then return end
    _origCamIdx=oldIdx; setreadonly(mt,false)
    mt.__index=newcclosure(function(self,key)
        if _silentActive and key=="CFrame" and _silentCF then return _silentCF end
        return oldIdx(self,key)
    end)
    setreadonly(mt,true)
end)

local _silentHooked=false
task.spawn(function()
    local deadline=tick()+10
    while tick()<deadline do if W.GunModule and W.GunModule.StartShooting then break end; task.wait(0.2) end
    local GM=W.GunModule; if not GM or not GM.StartShooting or _silentHooked then return end
    _silentHooked=true
    local prev=GM.StartShooting
    GM.StartShooting=function(self,p1,p2)
        if SilentAimActive() then
            local tgt=GetSilentTarget()
            if tgt then
                local realCF=Camera.CFrame
                _silentCF=CFrame.new(realCF.Position,tgt.Position+Vector3.new(0,0.15,0))
                _silentActive=true; local res={prev(self,p1,p2)}; _silentActive=false; _silentCF=nil
                return unpack(res)
            end
        end
        return prev(self,p1,p2)
    end
end)

-- ============================================================
--  MOVEMENT SYSTEM
-- ============================================================
local noclipConns={}; local _normalNoclipConn=nil; local _speedConn=nil; local _jumpConn=nil

local function ClearNoclipConns()
    for _,c in ipairs(noclipConns) do pcall(function() c:Disconnect() end) end; noclipConns={}
end
local function RestoreCollision()
    local char=LocalPlayer.Character; if not char then return end
    for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide=true end) end end
end
local function DisableNoclip()
    ClearNoclipConns()
    if _normalNoclipConn then pcall(function() _normalNoclipConn:Disconnect() end); _normalNoclipConn=nil end
    RestoreCollision()
end
local function HookPart(part)
    if not part:IsA("BasePart") then return end
    pcall(function() part.CanCollide=false end)
    local ok,conn=pcall(function()
        return part:GetPropertyChangedSignal("CanCollide"):Connect(function()
            if Config.Movement.Noclip and Config.Movement.NoclipMode=="Rivals" then pcall(function() part.CanCollide=false end) end
        end)
    end)
    if ok and conn then table.insert(noclipConns,conn) end
end
local function EnableNoclip()
    DisableNoclip()
    if Config.Movement.NoclipMode=="Rivals" then
        local char=LocalPlayer.Character; if not char then return end
        for _,p in ipairs(char:GetDescendants()) do HookPart(p) end
        table.insert(noclipConns,char.DescendantAdded:Connect(function(d) if Config.Movement.Noclip then HookPart(d) end end))
    else
        _normalNoclipConn=RunService.Stepped:Connect(function()
            if not Config.Movement.Noclip then pcall(function() _normalNoclipConn:Disconnect() end); _normalNoclipConn=nil; RestoreCollision(); return end
            local char=LocalPlayer.Character; if not char then return end
            for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide=false end) end end
        end)
    end
end

local function StopSpeed()
    if _speedConn then pcall(function() _speedConn:Disconnect() end); _speedConn=nil end
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then pcall(function() hum.WalkSpeed=16 end) end
end

local function StartSpeedLoop()
    StopSpeed()
    _speedConn=RunService.Heartbeat:Connect(function()
        if not Config.Movement.SpeedEnabled then StopSpeed(); return end
        local char=LocalPlayer.Character; if not char then return end
        local hum=char:FindFirstChild("Humanoid"); if not hum then return end
        if Config.Movement.SpeedMode=="Rivals" then
            -- Rivals mode: set both humanoid AND try to find Rivals' internal velocity cap
            pcall(function() hum.WalkSpeed=Config.Movement.Speed end)
            -- Also try to find and override the character's velocity directly
            local root=char:FindFirstChild("HumanoidRootPart")
            if root then
                -- If moving, scale the velocity to desired speed
                local vel=root.AssemblyLinearVelocity
                local flat=Vector3.new(vel.X,0,vel.Z)
                if flat.Magnitude>0.5 then
                    local targetSpeed=Config.Movement.Speed
                    local newFlat=flat.Unit*targetSpeed
                    pcall(function()
                        root.AssemblyLinearVelocity=Vector3.new(newFlat.X,vel.Y,newFlat.Z)
                    end)
                end
            end
        else
            pcall(function() hum.WalkSpeed=Config.Movement.Speed end)
        end
    end)
end

local function StopJump()
    if _jumpConn then pcall(function() _jumpConn:Disconnect() end); _jumpConn=nil end
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then pcall(function() hum.JumpPower=50; hum.JumpHeight=7.2 end) end
end

local function StartJumpLoop()
    StopJump()
    _jumpConn=RunService.Heartbeat:Connect(function()
        if not Config.Movement.JumpEnabled then StopJump(); return end
        local char=LocalPlayer.Character; if not char then return end
        local hum=char:FindFirstChild("Humanoid"); if not hum then return end
        pcall(function()
            hum.JumpPower=Config.Movement.JumpPower
            hum.JumpHeight=Config.Movement.JumpPower*0.56
            -- Rivals mode: also try to hook UseJump state
            if Config.Movement.JumpMode=="Rivals" then
                local root=char:FindFirstChild("HumanoidRootPart")
                if root then
                    -- When jump is pressed, boost Y velocity
                    if hum:GetState()==Enum.HumanoidStateType.Jumping then
                        local vel=root.AssemblyLinearVelocity
                        if vel.Y>0 and vel.Y<Config.Movement.JumpPower then
                            pcall(function()
                                root.AssemblyLinearVelocity=Vector3.new(vel.X,Config.Movement.JumpPower*0.5,vel.Z)
                            end)
                        end
                    end
                end
            end
        end)
    end)
end

-- Rivals Infinite Jump: hook via CharacterAdded + JumpRequest
local function SetupInfJump(char)
    local hum=char:FindFirstChild("Humanoid"); if not hum then return end
    hum.StateChanged:Connect(function(old,new)
        if new==Enum.HumanoidStateType.Landed and Config.Movement.InfJump then
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
        end
    end)
end

UserInputService.JumpRequest:Connect(function()
    if not Config.Movement.InfJump then return end
    local char=LocalPlayer.Character; if not char then return end
    local hum=char:FindFirstChild("Humanoid"); if not hum then return end
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    -- Rivals specific: also add upward impulse
    local root=char:FindFirstChild("HumanoidRootPart")
    if root then
        pcall(function()
            local vel=root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity=Vector3.new(vel.X,math.max(vel.Y,40),vel.Z)
        end)
    end
end)

local _pSpeed=false; local _pJump=false; local _pNoclip=false
RunService.Heartbeat:Connect(function()
    if Config.Movement.SpeedEnabled~=_pSpeed then _pSpeed=Config.Movement.SpeedEnabled; if _pSpeed then StartSpeedLoop() else StopSpeed() end end
    if Config.Movement.JumpEnabled~=_pJump   then _pJump=Config.Movement.JumpEnabled;   if _pJump  then StartJumpLoop()  else StopJump()  end end
    if Config.Movement.Noclip~=_pNoclip       then _pNoclip=Config.Movement.Noclip;      if _pNoclip then EnableNoclip() else DisableNoclip() end end
end)

-- ============================================================
--  3RD PERSON
-- ============================================================
local _tpConn=nil
local function EnableThirdPerson()
    if _tpConn then pcall(function() _tpConn:Disconnect() end) end
    _tpConn=RunService.RenderStepped:Connect(function()
        if not Config.Rivals.ThirdPerson then
            pcall(function() _tpConn:Disconnect() end); _tpConn=nil
            pcall(function() LocalPlayer.CameraMaxZoomDistance=400; LocalPlayer.CameraMinZoomDistance=0.5 end); return
        end
        local char=LocalPlayer.Character; if not char then return end
        local hum=char:FindFirstChild("Humanoid"); if not hum then return end
        pcall(function()
            Camera.CameraType=Enum.CameraType.Custom; Camera.CameraSubject=hum
            LocalPlayer.CameraMaxZoomDistance=Config.Rivals.ThirdPersonDist; LocalPlayer.CameraMinZoomDistance=0.5
        end)
    end)
end
local _pTP=false
RunService.Heartbeat:Connect(function()
    if Config.Rivals.ThirdPerson~=_pTP then
        _pTP=Config.Rivals.ThirdPerson
        if _pTP then EnableThirdPerson()
        else if _tpConn then pcall(function() _tpConn:Disconnect() end); _tpConn=nil end; pcall(function() LocalPlayer.CameraMaxZoomDistance=400; LocalPlayer.CameraMinZoomDistance=0.5 end) end
    end
end)

-- ============================================================
--  DEVICE SPOOFER
-- ============================================================
local _spoofMap={}; local _devHooked=false; local _origUISIdx=nil
local function BuildSpoofMap(dt)
    if dt=="Mobile" then _spoofMap={TouchEnabled=true,GamepadEnabled=false,KeyboardEnabled=false,MouseEnabled=false}
    elseif dt=="Console" then _spoofMap={TouchEnabled=false,GamepadEnabled=true,KeyboardEnabled=false,MouseEnabled=false}
    else _spoofMap={TouchEnabled=false,GamepadEnabled=false,KeyboardEnabled=true,MouseEnabled=true} end
end
local function InstallDeviceSpoof()
    if _devHooked then return end
    local ok,mt=pcall(getrawmetatable,UserInputService); if not ok or not mt then return end
    local oldIdx=rawget(mt,"__index"); if not oldIdx then return end
    _origUISIdx=oldIdx
    pcall(function()
        setreadonly(mt,false)
        mt.__index=newcclosure(function(self,key)
            if Config.Rivals.DeviceSpoofEnabled and _spoofMap[key]~=nil then return _spoofMap[key] end
            return oldIdx(self,key)
        end)
        setreadonly(mt,true)
    end)
    _devHooked=true
end
local function RemoveDeviceSpoof()
    if not _origUISIdx then return end
    local ok,mt=pcall(getrawmetatable,UserInputService); if not ok or not mt then return end
    pcall(function() setreadonly(mt,false); mt.__index=_origUISIdx; setreadonly(mt,true) end)
    _origUISIdx=nil; _devHooked=false
end
RunService.Heartbeat:Connect(function()
    if Config.Rivals.DeviceSpoofEnabled then BuildSpoofMap(Config.Rivals.DeviceType); if not _devHooked then pcall(InstallDeviceSpoof) end end
end)

-- ============================================================
--  RESPAWN
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum=char:WaitForChild("Humanoid")
    if Config.Movement.SpeedEnabled then pcall(function() hum.WalkSpeed=Config.Movement.Speed end) end
    if Config.Movement.JumpEnabled  then pcall(function() hum.JumpPower=Config.Movement.JumpPower end) end
    SetupInfJump(char)
    for _,p in ipairs(Players:GetPlayers()) do CreateESP(p) end
    if Config.Movement.Fly    then StartFly()     end
    if Config.Movement.Noclip then EnableNoclip() end
    charTPActive=false; charTPOrigPos=nil
end)

-- Setup inf jump for existing character
if LocalPlayer.Character then task.spawn(function() SetupInfJump(LocalPlayer.Character) end) end

-- ============================================================
--  DESTROY ALL
-- ============================================================
local function DestroyAll()
    charTPActive=false; charTPOrigPos=nil
    Config.ESP.Enabled=false; Config.Movement.Fly=false; Config.Movement.Noclip=false
    Config.Movement.SpeedEnabled=false; Config.Movement.JumpEnabled=false; Config.Movement.InfJump=false
    Config.Aimbot.Enabled=false; Config.Aimbot.CharTP=false
    Config.Rivals.ThirdPerson=false; Config.Rivals.DeviceSpoofEnabled=false
    if _speedConn  then pcall(function() _speedConn:Disconnect()  end); _speedConn=nil  end
    if _jumpConn   then pcall(function() _jumpConn:Disconnect()   end); _jumpConn=nil   end
    if _tpConn     then pcall(function() _tpConn:Disconnect()     end); _tpConn=nil     end
    DisableNoclip(); pcall(RemoveDeviceSpoof)
    if RivalsCharModule then
        if RivalsOrigGetSpeed then RivalsCharModule.GetSpeed    =RivalsOrigGetSpeed end
        if RivalsOrigGetJump  then RivalsCharModule.GetJumpPower=RivalsOrigGetJump  end
    end
    if W.GunModule then
        local G=W.GunModule
        if W.OriginalStartShooting    then G.StartShooting    =W.OriginalStartShooting    end
        if W.OriginalStartReloading   then G.StartReloading   =W.OriginalStartReloading   end
        if W.OriginalRecoil           then G._Recoil          =W.OriginalRecoil           end
        if W.OriginalStartAiming      then G.StartAiming      =W.OriginalStartAiming      end
        if W.OriginalGetAimSpeed      then G.GetAimSpeed      =W.OriginalGetAimSpeed      end
        if W.OriginalEquip            then G.Equip            =W.OriginalEquip            end
        if W.OriginalLocalTracers     then G._LocalTracers    =W.OriginalLocalTracers     end
        if W.OriginalProjectileEffect then G._ProjectileEffect=W.OriginalProjectileEffect end
    end
    if W.GameplayUtility and W.OriginalGetSpread then W.GameplayUtility.GetSpread=W.OriginalGetSpread end
    for _,e in pairs(ESPObjects) do
        for _,key in ipairs({"Box","BoxFill","Name","Tracer","HealthBarBG","HealthBarFill","Distance","Item"}) do pcall(function() e[key]:Remove() end) end
        if e.Skeleton then for _,ln in ipairs(e.Skeleton) do pcall(function() ln:Remove() end) end end
    end
    ESPObjects={}
    for _,hl in pairs(ChamObjects) do pcall(function() hl:Destroy() end) end
    ChamObjects={}
    _silentActive=false; _silentCF=nil
    pcall(function()
        if _origCamIdx then
            local mt=getrawmetatable(Camera)
            if mt then setreadonly(mt,false); mt.__index=_origCamIdx; setreadonly(mt,true) end
            _origCamIdx=nil
        end
    end)
    pcall(function() FovFill:Remove() end)
    pcall(function() FovCircle:Remove() end)
    pcall(function() TargetTracer:Remove() end)
    ScreenGui:Destroy(); Shadow:Destroy()
end

CloseBtn.MouseButton1Click:Connect(DestroyAll)
UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode==Enum.KeyCode.Delete and UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
        DestroyAll()
    end
end)

print("[MacOS GUI v2] Loaded ✓  |  RShift=toggle  |  X(hold)=aimbot  |  RShift+Del=destroy")
