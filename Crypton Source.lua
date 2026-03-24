-- ╔══════════════════════════════════╗
-- ║  Crypton Hub v3  —  Vape Style   ║
-- ║  Toggle   : Right Shift          ║
-- ║  Aimbot   : Hold X (default)     ║
-- ║  Destroy  : RShift + Delete      ║
-- ╚══════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ============================================================
--  CONFIG
-- ============================================================
local Config = {
    ESP = {
        Enabled     = false,
        ShowBox     = true,
        ShowName    = true,
        ShowTracer  = false,
        BoxColor    = Color3.fromRGB(255, 255, 255),
        NameColor   = Color3.fromRGB(255, 255, 255),
        TracerColor = Color3.fromRGB(255, 80, 80),
        BoxThick    = 1,
        MaxDist     = 500,
    },
    Movement = {
        Speed     = 16,
        JumpPower = 50,
        Fly       = false,
        FlySpeed  = 60,
        Noclip    = false,
    },
    Aimbot = {
        Enabled           = false,
        Smoothing         = 10,
        FovRadius         = 150,
        Key               = Enum.KeyCode.X,
        TracerEnabled     = false,
        TracerColor       = Color3.fromRGB(255, 60, 60),
        SilentAim         = false,
        SilentAimMode     = "Toggle",  -- "Always" / "Toggle" / "Hold"
        SilentAimKey      = Enum.KeyCode.Z,
        SilentAimHeld     = false,     -- runtime: is hold key currently down
        SilentAimToggled  = false,     -- runtime: toggle state
        SilentAimFov      = false,     -- use FOV limit for silent aim
        SilentAimFovRadius= 150,
        AimType           = "MouseMove",
    },
    Weapons = {
        RapidFire                 = false,
        RapidFireSpeed            = 0.01,
        InstantReload             = false,
        NoRecoil                  = false,
        RecoilReduction           = 100,
        NoSpread                  = false,
        NoWeaponBob               = false,
        InstantADS                = false,
        InstantEquip              = false,
        NoEquipAnimation          = false,
        InfiniteAmmo              = false,
        InstantBulletTravel       = false,
        ProjectileSpeed           = false,
        ProjectileSpeedMultiplier = 5,
        -- internal module refs
        GunModule                 = nil,
        GameplayUtility           = nil,
        ViewModelModule           = nil,
        OriginalStartShooting     = nil,
        OriginalStartReloading    = nil,
        OriginalRecoil            = nil,
        OriginalGetSpread         = nil,
        OriginalStartAiming       = nil,
        OriginalGetAimSpeed       = nil,
        OriginalEquip             = nil,
        OriginalLocalTracers      = nil,
        OriginalProjectileEffect  = nil,
        OriginalGetRayOrigin      = nil,
    },
}

-- ============================================================
--  SCREEN GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "TestGUI"
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
--  THEME
-- ============================================================
local T = {
    BG        = Color3.fromRGB(20, 20, 20),
    Sidebar   = Color3.fromRGB(15, 15, 15),
    Panel     = Color3.fromRGB(22, 22, 22),
    Row       = Color3.fromRGB(26, 26, 26),
    RowActive = Color3.fromRGB(0, 160, 125),
    Header    = Color3.fromRGB(14, 14, 14),
    Text      = Color3.fromRGB(220, 220, 220),
    TextDim   = Color3.fromRGB(120, 120, 120),
    Accent    = Color3.fromRGB(0, 185, 145),
    AccentDim = Color3.fromRGB(0, 110, 88),
    Red       = Color3.fromRGB(200, 55, 55),
    Border    = Color3.fromRGB(38, 38, 38),
    Sep       = Color3.fromRGB(30, 30, 30),
}

local function Corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 4)
end
local function Stroke(p, col, th)
    local s = Instance.new("UIStroke", p)
    s.Color = col or T.Border; s.Thickness = th or 1
end

-- ============================================================
--  SIDEBAR
-- ============================================================
local Sidebar = Instance.new("Frame", ScreenGui)
Sidebar.Name             = "Sidebar"
Sidebar.Size             = UDim2.new(0, 145, 0, 0)
Sidebar.Position         = UDim2.new(0, 16, 0.5, -80)
Sidebar.BackgroundColor3 = T.Sidebar
Sidebar.BorderSizePixel  = 0
Sidebar.AutomaticSize    = Enum.AutomaticSize.Y
Sidebar.Active           = true
Sidebar.Draggable        = true
Corner(Sidebar, 5); Stroke(Sidebar, T.Border, 1)

-- Title bar
local SBTitle = Instance.new("Frame", Sidebar)
SBTitle.Size             = UDim2.new(1, 0, 0, 30)
SBTitle.BackgroundColor3 = T.Header
SBTitle.BorderSizePixel  = 0
Corner(SBTitle, 5)

local SBTitleMask = Instance.new("Frame", SBTitle)
SBTitleMask.Size             = UDim2.new(1, 0, 0, 6)
SBTitleMask.Position         = UDim2.new(0, 0, 1, -6)
SBTitleMask.BackgroundColor3 = T.Header
SBTitleMask.BorderSizePixel  = 0

local SBTitleLbl = Instance.new("TextLabel", SBTitle)
SBTitleLbl.Size                   = UDim2.new(1, -28, 1, 0)
SBTitleLbl.Position               = UDim2.new(0, 10, 0, 0)
SBTitleLbl.BackgroundTransparency = 1
SBTitleLbl.Text                   = "✦  Crypton Hub"
SBTitleLbl.TextColor3             = T.Accent
SBTitleLbl.Font                   = Enum.Font.GothamBold
SBTitleLbl.TextSize               = 12
SBTitleLbl.TextXAlignment         = Enum.TextXAlignment.Left

-- Destroy button
local DestroyBtn = Instance.new("TextButton", SBTitle)
DestroyBtn.Size             = UDim2.new(0, 18, 0, 18)
DestroyBtn.Position         = UDim2.new(1, -22, 0.5, -9)
DestroyBtn.BackgroundColor3 = Color3.fromRGB(45, 18, 18)
DestroyBtn.Text             = "✕"
DestroyBtn.TextColor3       = T.Red
DestroyBtn.Font             = Enum.Font.GothamBold
DestroyBtn.TextSize         = 10
DestroyBtn.BorderSizePixel  = 0
DestroyBtn.ZIndex           = 10
Corner(DestroyBtn, 3)

-- Nav list
local NavList = Instance.new("Frame", Sidebar)
NavList.Size                  = UDim2.new(1, 0, 0, 0)
NavList.Position              = UDim2.new(0, 0, 0, 30)
NavList.BackgroundTransparency = 1
NavList.AutomaticSize         = Enum.AutomaticSize.Y
NavList.BorderSizePixel       = 0

local NavLayout = Instance.new("UIListLayout", NavList)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder

local NavPad = Instance.new("UIPadding", NavList)
NavPad.PaddingBottom = UDim.new(0, 6)

-- ============================================================
--  PANEL FACTORY
-- ============================================================
local OpenPanels   = {}
local panelOffsetX = 170

local function MakePanel(title, spawnPos)
    local panel = Instance.new("Frame", ScreenGui)
    panel.Size             = UDim2.new(0, 200, 0, 0)
    panel.Position         = spawnPos
    panel.BackgroundColor3 = T.Panel
    panel.BorderSizePixel  = 0
    panel.AutomaticSize    = Enum.AutomaticSize.Y
    panel.Active           = true
    panel.Draggable        = true
    panel.Visible          = false
    Corner(panel, 5); Stroke(panel, T.Border, 1)

    local hdr = Instance.new("Frame", panel)
    hdr.Size             = UDim2.new(1, 0, 0, 26)
    hdr.BackgroundColor3 = T.Header
    hdr.BorderSizePixel  = 0
    Corner(hdr, 5)

    local hdrMask = Instance.new("Frame", hdr)
    hdrMask.Size             = UDim2.new(1, 0, 0, 6)
    hdrMask.Position         = UDim2.new(0, 0, 1, -6)
    hdrMask.BackgroundColor3 = T.Header
    hdrMask.BorderSizePixel  = 0

    local hdrLbl = Instance.new("TextLabel", hdr)
    hdrLbl.Size                   = UDim2.new(1, -44, 1, 0)
    hdrLbl.Position               = UDim2.new(0, 10, 0, 0)
    hdrLbl.BackgroundTransparency = 1
    hdrLbl.Text                   = title
    hdrLbl.TextColor3             = T.Accent
    hdrLbl.Font                   = Enum.Font.GothamBold
    hdrLbl.TextSize               = 12
    hdrLbl.TextXAlignment         = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", hdr)
    closeBtn.Size             = UDim2.new(0, 16, 0, 16)
    closeBtn.Position         = UDim2.new(1, -20, 0.5, -8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    closeBtn.Text             = "—"
    closeBtn.TextColor3       = T.TextDim
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.TextSize         = 9
    closeBtn.BorderSizePixel  = 0
    Corner(closeBtn, 3)
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
        if OpenPanels[title] then
            local d = OpenPanels[title]
            d.navBtn.BackgroundColor3 = T.Row
            if d.nameLbl then d.nameLbl.TextColor3 = T.Text    end
            if d.iconLbl then d.iconLbl.TextColor3 = T.Accent  end
            if d.arrow   then d.arrow.TextColor3   = T.TextDim end
        end
    end)

    local scroll = Instance.new("ScrollingFrame", panel)
    scroll.Size                   = UDim2.new(1, 0, 0, 0)
    scroll.Position               = UDim2.new(0, 0, 0, 26)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel        = 0
    scroll.ScrollBarThickness     = 3
    scroll.ScrollBarImageColor3   = T.AccentDim
    scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    scroll.AutomaticSize          = Enum.AutomaticSize.Y

    Instance.new("UIListLayout", scroll).SortOrder = Enum.SortOrder.LayoutOrder

    return panel, scroll
end

-- ============================================================
--  WIDGET HELPERS
-- ============================================================
local function AddSection(scroll, label)
    local f = Instance.new("Frame", scroll)
    f.Size             = UDim2.new(1, 0, 0, 20)
    f.BackgroundColor3 = T.Header
    f.BorderSizePixel  = 0

    local lbl = Instance.new("TextLabel", f)
    lbl.Size                   = UDim2.new(1, -10, 1, 0)
    lbl.Position               = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = label
    lbl.TextColor3             = T.TextDim
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 10
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    return lbl
end

local function AddToggle(scroll, label, default, callback)
    local row = Instance.new("Frame", scroll)
    row.Size             = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = default and T.RowActive or T.Row
    row.BorderSizePixel  = 0

    local lbl = Instance.new("TextLabel", row)
    lbl.Size                   = UDim2.new(1, -24, 1, 0)
    lbl.Position               = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = label
    lbl.TextColor3             = default and Color3.fromRGB(255,255,255) or T.Text
    lbl.Font                   = Enum.Font.Gotham
    lbl.TextSize               = 12
    lbl.TextXAlignment         = Enum.TextXAlignment.Left

    local dots = Instance.new("TextLabel", row)
    dots.Size                   = UDim2.new(0, 18, 1, 0)
    dots.Position               = UDim2.new(1, -20, 0, 0)
    dots.BackgroundTransparency = 1
    dots.Text                   = "⋮"
    dots.TextColor3             = T.TextDim
    dots.Font                   = Enum.Font.GothamBold
    dots.TextSize               = 14

    local sep = Instance.new("Frame", row)
    sep.Size             = UDim2.new(1, 0, 0, 1)
    sep.Position         = UDim2.new(0, 0, 1, -1)
    sep.BackgroundColor3 = T.Sep
    sep.BorderSizePixel  = 0

    local state = default
    local btn   = Instance.new("TextButton", row)
    btn.Size             = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text             = ""
    btn.MouseButton1Click:Connect(function()
        state = not state
        row.BackgroundColor3 = state and T.RowActive or T.Row
        lbl.TextColor3       = state and Color3.fromRGB(255,255,255) or T.Text
        callback(state)
    end)
end

local function AddSlider(scroll, label, min, max, default, callback)
    local row = Instance.new("Frame", scroll)
    row.Size             = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = T.Row
    row.BorderSizePixel  = 0

    local lbl = Instance.new("TextLabel", row)
    lbl.Size                   = UDim2.new(0.62, 0, 0, 18)
    lbl.Position               = UDim2.new(0, 10, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = label
    lbl.TextColor3             = T.Text
    lbl.Font                   = Enum.Font.Gotham
    lbl.TextSize               = 12
    lbl.TextXAlignment         = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size                   = UDim2.new(0.38, -10, 0, 18)
    valLbl.Position               = UDim2.new(0.62, 0, 0, 5)
    valLbl.BackgroundTransparency = 1
    valLbl.Text                   = tostring(default)
    valLbl.TextColor3             = T.Accent
    valLbl.Font                   = Enum.Font.GothamBold
    valLbl.TextSize               = 12
    valLbl.TextXAlignment         = Enum.TextXAlignment.Right

    local track = Instance.new("Frame", row)
    track.Size             = UDim2.new(1, -20, 0, 3)
    track.Position         = UDim2.new(0, 10, 1, -13)
    track.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    track.BorderSizePixel  = 0
    Corner(track, 2)

    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = T.Accent
    fill.BorderSizePixel  = 0
    Corner(fill, 2)

    local dragging = false
    local hit = Instance.new("TextButton", track)
    hit.Size             = UDim2.new(1, 0, 0, 26)
    hit.Position         = UDim2.new(0, 0, 0.5, -13)
    hit.BackgroundTransparency = 1
    hit.Text             = ""

    local function apply(ax)
        local rel = math.clamp((ax - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + rel*(max-min))
        fill.Size   = UDim2.new(rel, 0, 1, 0)
        valLbl.Text = tostring(val)
        callback(val)
    end
    hit.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then apply(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local sep = Instance.new("Frame", row)
    sep.Size             = UDim2.new(1, 0, 0, 1)
    sep.Position         = UDim2.new(0, 0, 1, -1)
    sep.BackgroundColor3 = T.Sep
    sep.BorderSizePixel  = 0
end

local function AddKeybind(scroll, label, default, callback)
    local row = Instance.new("Frame", scroll)
    row.Size             = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = T.Row
    row.BorderSizePixel  = 0

    local lbl = Instance.new("TextLabel", row)
    lbl.Size                   = UDim2.new(0.52, 0, 1, 0)
    lbl.Position               = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = label
    lbl.TextColor3             = T.Text
    lbl.Font                   = Enum.Font.Gotham
    lbl.TextSize               = 12
    lbl.TextXAlignment         = Enum.TextXAlignment.Left

    local keyBtn = Instance.new("TextButton", row)
    keyBtn.Size             = UDim2.new(0, 52, 0, 18)
    keyBtn.Position         = UDim2.new(1, -58, 0.5, -9)
    keyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    keyBtn.Text             = tostring(default):gsub("Enum.KeyCode.", "")
    keyBtn.TextColor3       = T.Accent
    keyBtn.Font             = Enum.Font.GothamBold
    keyBtn.TextSize         = 11
    keyBtn.BorderSizePixel  = 0
    Corner(keyBtn, 3); Stroke(keyBtn, T.Border, 1)

    local listening = false
    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."; keyBtn.TextColor3 = Color3.fromRGB(255,200,50)
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            local skip = {[Enum.KeyCode.LeftShift]=1,[Enum.KeyCode.RightShift]=1,
                          [Enum.KeyCode.LeftControl]=1,[Enum.KeyCode.RightControl]=1,
                          [Enum.KeyCode.LeftAlt]=1,[Enum.KeyCode.RightAlt]=1}
            if input.UserInputType == Enum.UserInputType.Keyboard and not skip[input.KeyCode] then
                local kn = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                keyBtn.Text = kn; keyBtn.TextColor3 = T.Accent
                listening = false; conn:Disconnect(); callback(input.KeyCode)
            end
        end)
    end)

    local sep = Instance.new("Frame", row)
    sep.Size             = UDim2.new(1, 0, 0, 1)
    sep.Position         = UDim2.new(0, 0, 1, -1)
    sep.BackgroundColor3 = T.Sep
    sep.BorderSizePixel  = 0

    return keyBtn
end

-- Cycle button: click to step through a list of options
local function AddCycle(scroll, label, options, default, callback)
    local row = Instance.new("Frame", scroll)
    row.Size             = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = T.Row
    row.BorderSizePixel  = 0

    local lbl = Instance.new("TextLabel", row)
    lbl.Size                   = UDim2.new(0.5, 0, 1, 0)
    lbl.Position               = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = label
    lbl.TextColor3             = T.Text
    lbl.Font                   = Enum.Font.Gotham
    lbl.TextSize               = 12
    lbl.TextXAlignment         = Enum.TextXAlignment.Left

    local cycleBtn = Instance.new("TextButton", row)
    cycleBtn.Size             = UDim2.new(0, 90, 0, 18)
    cycleBtn.Position         = UDim2.new(1, -96, 0.5, -9)
    cycleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    cycleBtn.Text             = default
    cycleBtn.TextColor3       = T.Accent
    cycleBtn.Font             = Enum.Font.GothamBold
    cycleBtn.TextSize         = 10
    cycleBtn.BorderSizePixel  = 0
    Corner(cycleBtn, 3); Stroke(cycleBtn, T.Border, 1)

    local idx = 1
    for i, v in ipairs(options) do if v == default then idx = i break end end

    cycleBtn.MouseButton1Click:Connect(function()
        idx = (idx % #options) + 1
        cycleBtn.Text = options[idx]
        callback(options[idx])
    end)

    local sep = Instance.new("Frame", row)
    sep.Size             = UDim2.new(1, 0, 0, 1)
    sep.Position         = UDim2.new(0, 0, 1, -1)
    sep.BackgroundColor3 = T.Sep
    sep.BorderSizePixel  = 0
end
local function AddColorPicker(scroll, label, defaultColor, callback)
    local r0, g0, b0 = math.floor(defaultColor.R*255), math.floor(defaultColor.G*255), math.floor(defaultColor.B*255)
    local cr, cg, cb = r0, g0, b0

    local wrapper = Instance.new("Frame", scroll)
    wrapper.Size             = UDim2.new(1, 0, 0, 0)
    wrapper.BackgroundTransparency = 1
    wrapper.AutomaticSize    = Enum.AutomaticSize.Y
    wrapper.BorderSizePixel  = 0

    local wLayout = Instance.new("UIListLayout", wrapper)
    wLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Header row with colour preview swatch
    local hdr = Instance.new("Frame", wrapper)
    hdr.Size             = UDim2.new(1, 0, 0, 24)
    hdr.BackgroundColor3 = T.Header
    hdr.BorderSizePixel  = 0
    hdr.LayoutOrder      = 0

    local hdrLbl = Instance.new("TextLabel", hdr)
    hdrLbl.Size                   = UDim2.new(1, -34, 1, 0)
    hdrLbl.Position               = UDim2.new(0, 8, 0, 0)
    hdrLbl.BackgroundTransparency = 1
    hdrLbl.Text                   = label
    hdrLbl.TextColor3             = T.TextDim
    hdrLbl.Font                   = Enum.Font.GothamBold
    hdrLbl.TextSize               = 10
    hdrLbl.TextXAlignment         = Enum.TextXAlignment.Left

    local swatch = Instance.new("Frame", hdr)
    swatch.Size             = UDim2.new(0, 22, 0, 14)
    swatch.Position         = UDim2.new(1, -28, 0.5, -7)
    swatch.BackgroundColor3 = defaultColor
    swatch.BorderSizePixel  = 0
    Corner(swatch, 3)

    local function fireCallback()
        local col = Color3.fromRGB(cr, cg, cb)
        swatch.BackgroundColor3 = col
        callback(col)
    end

    local channels = {
        { name="R", get=function() return cr end, set=function(v) cr=v end, col=Color3.fromRGB(200,50,50),  def=r0, order=1 },
        { name="G", get=function() return cg end, set=function(v) cg=v end, col=Color3.fromRGB(50,185,80),  def=g0, order=2 },
        { name="B", get=function() return cb end, set=function(v) cb=v end, col=Color3.fromRGB(60,120,220), def=b0, order=3 },
    }

    for _, ch in ipairs(channels) do
        local row = Instance.new("Frame", wrapper)
        row.Size             = UDim2.new(1, 0, 0, 22)
        row.BackgroundColor3 = T.Row
        row.BorderSizePixel  = 0
        row.LayoutOrder      = ch.order

        local chLbl = Instance.new("TextLabel", row)
        chLbl.Size                   = UDim2.new(0, 14, 1, 0)
        chLbl.Position               = UDim2.new(0, 8, 0, 0)
        chLbl.BackgroundTransparency = 1
        chLbl.Text                   = ch.name
        chLbl.TextColor3             = ch.col
        chLbl.Font                   = Enum.Font.GothamBold
        chLbl.TextSize               = 11

        local valLbl = Instance.new("TextLabel", row)
        valLbl.Size                   = UDim2.new(0, 26, 1, 0)
        valLbl.Position               = UDim2.new(1, -30, 0, 0)
        valLbl.BackgroundTransparency = 1
        valLbl.Text                   = tostring(ch.def)
        valLbl.TextColor3             = T.TextDim
        valLbl.Font                   = Enum.Font.GothamBold
        valLbl.TextSize               = 10
        valLbl.TextXAlignment         = Enum.TextXAlignment.Right

        local track = Instance.new("Frame", row)
        track.Size             = UDim2.new(1, -54, 0, 3)
        track.Position         = UDim2.new(0, 24, 0.5, -1)
        track.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
        track.BorderSizePixel  = 0
        Corner(track, 2)

        local fill = Instance.new("Frame", track)
        fill.Size             = UDim2.new(ch.def/255, 0, 1, 0)
        fill.BackgroundColor3 = ch.col
        fill.BorderSizePixel  = 0
        Corner(fill, 2)

        local dragging = false
        local hit = Instance.new("TextButton", track)
        hit.Size             = UDim2.new(1, 0, 0, 20)
        hit.Position         = UDim2.new(0, 0, 0.5, -10)
        hit.BackgroundTransparency = 1
        hit.Text             = ""

        local function applyAt(ax)
            local rel = math.clamp((ax - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(rel * 255)
            fill.Size   = UDim2.new(rel, 0, 1, 0)
            valLbl.Text = tostring(val)
            ch.set(val)
            fireCallback()
        end

        hit.MouseButton1Down:Connect(function() dragging = true end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then applyAt(i.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        local sep = Instance.new("Frame", row)
        sep.Size             = UDim2.new(1, 0, 0, 1)
        sep.Position         = UDim2.new(0, 0, 1, -1)
        sep.BackgroundColor3 = T.Sep
        sep.BorderSizePixel  = 0
    end

    -- bottom gap
    local gap = Instance.new("Frame", wrapper)
    gap.Size             = UDim2.new(1, 0, 0, 4)
    gap.BackgroundColor3 = T.Panel
    gap.BorderSizePixel  = 0
    gap.LayoutOrder      = 4
end
local function AddNavEntry(icon, name, order, populateFn)
    local navBtn = Instance.new("TextButton", NavList)
    navBtn.Size             = UDim2.new(1, 0, 0, 28)
    navBtn.BackgroundColor3 = T.Row
    navBtn.BorderSizePixel  = 0
    navBtn.Text             = ""
    navBtn.LayoutOrder      = order

    local iconLbl = Instance.new("TextLabel", navBtn)
    iconLbl.Name                  = "Icon"
    iconLbl.Size                  = UDim2.new(0, 22, 1, 0)
    iconLbl.Position              = UDim2.new(0, 6, 0, 0)
    iconLbl.BackgroundTransparency= 1
    iconLbl.Text                  = icon
    iconLbl.TextColor3            = T.Accent
    iconLbl.Font                  = Enum.Font.GothamBold
    iconLbl.TextSize              = 13

    local nameLbl = Instance.new("TextLabel", navBtn)
    nameLbl.Name                  = "Label"
    nameLbl.Size                  = UDim2.new(1, -50, 1, 0)
    nameLbl.Position              = UDim2.new(0, 30, 0, 0)
    nameLbl.BackgroundTransparency= 1
    nameLbl.Text                  = name
    nameLbl.TextColor3            = T.Text
    nameLbl.Font                  = Enum.Font.Gotham
    nameLbl.TextSize              = 12
    nameLbl.TextXAlignment        = Enum.TextXAlignment.Left

    local arrow = Instance.new("TextLabel", navBtn)
    arrow.Size                   = UDim2.new(0, 14, 1, 0)
    arrow.Position               = UDim2.new(1, -16, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text                   = "›"
    arrow.TextColor3             = T.TextDim
    arrow.Font                   = Enum.Font.GothamBold
    arrow.TextSize               = 14

    local sep = Instance.new("Frame", navBtn)
    sep.Size             = UDim2.new(1, 0, 0, 1)
    sep.Position         = UDim2.new(0, 0, 1, -1)
    sep.BackgroundColor3 = T.Sep
    sep.BorderSizePixel  = 0

    local spawnPos = UDim2.new(0, panelOffsetX, 0, 60)
    panelOffsetX = panelOffsetX + 210

    local panel, scroll = MakePanel(icon .. "  " .. name, spawnPos)
    populateFn(scroll)

    -- open by default
    panel.Visible           = true
    navBtn.BackgroundColor3 = T.RowActive
    nameLbl.TextColor3      = Color3.fromRGB(255,255,255)
    iconLbl.TextColor3      = Color3.fromRGB(255,255,255)
    arrow.TextColor3        = Color3.fromRGB(255,255,255)

    OpenPanels[name] = { panel = panel, navBtn = navBtn, nameLbl = nameLbl, iconLbl = iconLbl, arrow = arrow }

    navBtn.MouseButton1Click:Connect(function()
        local vis = not panel.Visible
        panel.Visible           = vis
        navBtn.BackgroundColor3 = vis and T.RowActive or T.Row
        nameLbl.TextColor3      = vis and Color3.fromRGB(255,255,255) or T.Text
        iconLbl.TextColor3      = vis and Color3.fromRGB(255,255,255) or T.Accent
        arrow.TextColor3        = vis and Color3.fromRGB(255,255,255) or T.TextDim
    end)
end

-- ============================================================
--  POPULATE TABS
-- ============================================================
AddNavEntry("👁", "ESP", 1, function(s)
    AddSection(s, "VISUALS")
    AddToggle(s, "Enable ESP",   false, function(v) Config.ESP.Enabled    = v end)
    AddToggle(s, "Show Boxes",   true,  function(v) Config.ESP.ShowBox    = v end)
    AddToggle(s, "Show Names",   true,  function(v) Config.ESP.ShowName   = v end)
    AddToggle(s, "Show Tracers", false, function(v) Config.ESP.ShowTracer = v end)
    AddSection(s, "COLOURS")
    AddColorPicker(s, "Tracer Colour", Config.ESP.TracerColor, function(col)
        Config.ESP.TracerColor = col
        for _, e in pairs(ESPObjects) do
            if e.Tracer then e.Tracer.Color = col end
        end
    end)
end)

AddNavEntry("⚡", "Movement", 2, function(s)
    AddSection(s, "MOVEMENT")
    AddToggle(s, "Fly  [WASD+Space/LCtrl]", false, function(v) Config.Movement.Fly    = v end)
    AddToggle(s, "Noclip",                  false, function(v) Config.Movement.Noclip = v end)
    AddSlider(s, "Walk Speed", 16,  200, 16, function(v)
        Config.Movement.Speed = v
        local c = LocalPlayer.Character
        if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = v end
    end)
    AddSlider(s, "Jump Power", 50,  300, 50, function(v)
        Config.Movement.JumpPower = v
        local c = LocalPlayer.Character
        if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = v end
    end)
    AddSlider(s, "Fly Speed",  10,  200, 60, function(v) Config.Movement.FlySpeed = v end)
end)

AddNavEntry("🎯", "Aimbot", 3, function(s)
    local sec = AddSection(s, "AIMBOT  —  hold X to lock on")
    AddToggle(s, "Enable Aimbot",   false, function(v) Config.Aimbot.Enabled       = v end)
    AddToggle(s, "Target Tracer",   false, function(v) Config.Aimbot.TracerEnabled = v end)
    AddCycle(s,  "Aim Type", {"MouseMove", "CFrame"}, "MouseMove", function(v)
        Config.Aimbot.AimType = v
    end)
    AddKeybind(s, "Lock Key", Enum.KeyCode.X, function(key)
        Config.Aimbot.Key = key
        sec.Text = "AIMBOT  —  hold "..tostring(key):gsub("Enum.KeyCode.","").." to lock on"
    end)
    AddSlider(s, "Smoothing",  1,   30,  10, function(v) Config.Aimbot.Smoothing = v end)
    AddSlider(s, "FOV Radius", 10, 800, 150, function(v) Config.Aimbot.FovRadius = v end)
    AddSection(s, "SILENT AIM")
    AddToggle(s, "Silent Aim",       false, function(v) Config.Aimbot.SilentAim     = v end)
    AddToggle(s, "Silent FOV",       false, function(v) Config.Aimbot.SilentAimFov  = v end)
    AddSlider(s, "Silent FOV Radius",10, 800, 150, function(v) Config.Aimbot.SilentAimFovRadius = v end)
    AddCycle(s,  "Silent Mode", {"Always", "Toggle", "Hold"}, "Toggle", function(v)
        Config.Aimbot.SilentAimMode    = v
        Config.Aimbot.SilentAimToggled = false  -- reset toggle state on mode change
    end)
    AddKeybind(s, "Silent Key", Enum.KeyCode.Z, function(key)
        Config.Aimbot.SilentAimKey = key
    end)
    AddSection(s, "COLOURS")
    AddColorPicker(s, "Tracer Colour", Color3.fromRGB(255, 60, 60), function(col)
        Config.Aimbot.TracerColor  = col
        TargetTracer.Color         = col
    end)
end)

AddNavEntry("👤", "Info", 4, function(s)
    AddSection(s, "ACCOUNT")

    -- Username
    local function InfoRow(scroll, label, value)
        local row = Instance.new("Frame", scroll)
        row.Size             = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = T.Row
        row.BorderSizePixel  = 0

        local lbl = Instance.new("TextLabel", row)
        lbl.Size                   = UDim2.new(0.45, 0, 1, 0)
        lbl.Position               = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text                   = label
        lbl.TextColor3             = T.TextDim
        lbl.Font                   = Enum.Font.GothamBold
        lbl.TextSize               = 11
        lbl.TextXAlignment         = Enum.TextXAlignment.Left

        local val = Instance.new("TextLabel", row)
        val.Size                   = UDim2.new(0.55, -10, 1, 0)
        val.Position               = UDim2.new(0.45, 0, 0, 0)
        val.BackgroundTransparency = 1
        val.Text                   = tostring(value)
        val.TextColor3             = T.Accent
        val.Font                   = Enum.Font.Gotham
        val.TextSize               = 11
        val.TextXAlignment         = Enum.TextXAlignment.Right
        val.TextTruncate           = Enum.TextTruncate.AtEnd

        local sep = Instance.new("Frame", row)
        sep.Size             = UDim2.new(1, 0, 0, 1)
        sep.Position         = UDim2.new(0, 0, 1, -1)
        sep.BackgroundColor3 = T.Sep
        sep.BorderSizePixel  = 0

        return val
    end

    InfoRow(s, "Username",     LocalPlayer.Name)
    InfoRow(s, "Display Name", LocalPlayer.DisplayName)
    local ageVal = InfoRow(s, "Account Age", LocalPlayer.AccountAge .. " days")
    -- account age is static, set it once
    ageVal.Text = LocalPlayer.AccountAge .. "d"

    AddSection(s, "LIVE")
    -- Health row — updated every frame
    local healthVal = InfoRow(s, "Health", "—")

    RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                healthVal.Text = math.floor(hum.Health).." / "..math.floor(hum.MaxHealth)
                -- colour based on health %
                local pct = hum.Health / math.max(hum.MaxHealth, 1)
                if pct > 0.6 then
                    healthVal.TextColor3 = T.Green
                elseif pct > 0.3 then
                    healthVal.TextColor3 = Color3.fromRGB(230, 180, 40)
                else
                    healthVal.TextColor3 = T.Red
                end
            end
        else
            healthVal.Text       = "Dead"
            healthVal.TextColor3 = T.Red
        end
    end)
end)

AddNavEntry("🔫", "Weapons", 5, function(s)    AddSection(s, "SHOOTING")
    AddToggle(s, "Rapid Fire",           false, function(v) Config.Weapons.RapidFire           = v end)
    AddSlider(s, "Fire Cooldown", 1, 500, 10, function(v) Config.Weapons.RapidFireSpeed       = v / 1000 end)
    AddToggle(s, "Infinite Ammo",        false, function(v) Config.Weapons.InfiniteAmmo        = v end)
    AddToggle(s, "No Spread",            false, function(v) Config.Weapons.NoSpread            = v end)
    AddToggle(s, "Instant Bullet Travel",false, function(v) Config.Weapons.InstantBulletTravel = v end)
    AddToggle(s, "Projectile Speed",     false, function(v) Config.Weapons.ProjectileSpeed     = v end)
    AddSlider(s, "Speed Multiplier", 1, 20, 5,  function(v) Config.Weapons.ProjectileSpeedMultiplier = v end)
    AddSection(s, "RECOIL & ADS")
    AddToggle(s, "No Recoil",            false, function(v) Config.Weapons.NoRecoil            = v end)
    AddSlider(s, "Recoil Reduction", 0, 100, 100, function(v) Config.Weapons.RecoilReduction   = v end)
    AddToggle(s, "No Weapon Bob",        false, function(v) Config.Weapons.NoWeaponBob         = v end)
    AddToggle(s, "Instant ADS",          false, function(v) Config.Weapons.InstantADS          = v end)
    AddSection(s, "EQUIP")
    AddToggle(s, "Instant Reload",       false, function(v) Config.Weapons.InstantReload       = v end)
    AddToggle(s, "Instant Equip",        false, function(v) Config.Weapons.InstantEquip        = v end)
    AddToggle(s, "No Equip Animation",   false, function(v) Config.Weapons.NoEquipAnimation    = v end)
end)

-- ============================================================
--  RIVALS WEAPON HOOKS
--  Hooks into Rivals' internal Gun / GameplayUtility / ViewModel
--  modules. Runs async so it doesn't block the rest of the GUI.
-- ============================================================
local RS = game:GetService("ReplicatedStorage")
local W  = Config.Weapons   -- shorthand

task.spawn(function()
    local ok, GunModule = pcall(function()
        return require(LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun)
    end)
    if not ok or not GunModule then return end
    W.GunModule = GunModule

    -- StartShooting  (RapidFire + InfiniteAmmo)
    if GunModule.StartShooting then
        W.OriginalStartShooting = GunModule.StartShooting
        GunModule.StartShooting = function(self, p1, p2)
            if W.InfiniteAmmo then
                if self:Get("Ammo") <= 0 then
                    self:SetReplicate("Ammo", self.Info.MaxAmmo)
                end
            end
            local oldSC, oldBC
            if W.RapidFire then
                oldSC = self.Info.ShootCooldown
                oldBC = self.Info.ShootBurstCooldown
                self.Info.ShootCooldown      = W.RapidFireSpeed
                self.Info.ShootBurstCooldown = W.RapidFireSpeed
            end
            local res = { W.OriginalStartShooting(self, p1, p2) }
            if W.RapidFire then
                self.Info.ShootCooldown      = oldSC
                self.Info.ShootBurstCooldown = oldBC
            end
            return unpack(res)
        end
    end

    -- StartReloading  (InstantReload)
    if GunModule.StartReloading then
        W.OriginalStartReloading = GunModule.StartReloading
        GunModule.StartReloading = function(self, p1, p2, p3)
            if W.InstantReload then
                self:_ResetReloadState()
                local cur  = self:Get("Ammo")
                local max  = self.Info.MaxAmmo
                local res  = self:Get("AmmoReserve")
                if cur < max and res > 0 then
                    local need = math.min(max - cur, res)
                    self:SetReplicate("Ammo", cur + need)
                    self:SetReplicate("AmmoReserve", res - need)
                end
                return true, "StartReloading", self:ToEnum("Reload")
            end
            return W.OriginalStartReloading(self, p1, p2, p3)
        end
    end

    -- _Recoil  (NoRecoil / RecoilReduction)
    if GunModule._Recoil then
        W.OriginalRecoil = GunModule._Recoil
        GunModule._Recoil = function(self, multiplier)
            if W.NoRecoil then
                local reduced = multiplier * (1 - W.RecoilReduction / 100)
                if reduced <= 0.001 then return end
                return W.OriginalRecoil(self, reduced)
            end
            return W.OriginalRecoil(self, multiplier)
        end
    end

    -- StartAiming  (InstantADS)
    if GunModule.StartAiming then
        W.OriginalStartAiming = GunModule.StartAiming
        GunModule.StartAiming = function(self, p1)
            if W.InstantADS then
                self:SetReplicate("IsAiming", true)
                self.StopSprinting:Fire()
                self.ViewModel:SetAiming(true)
                self:SetReplicate("FOVOffset", self.Info.AimFOVOffset)
                if self.ViewModel.CurrentAimValue then
                    self.ViewModel.CurrentAimValue = 1
                end
                return true, "StartAiming"
            end
            return W.OriginalStartAiming(self, p1)
        end
    end

    -- GetAimSpeed  (InstantADS)
    if GunModule.GetAimSpeed then
        W.OriginalGetAimSpeed = GunModule.GetAimSpeed
        GunModule.GetAimSpeed = function(self)
            if W.InstantADS then return 999 end
            return W.OriginalGetAimSpeed(self)
        end
    end

    -- Equip  (InstantEquip / NoEquipAnimation)
    if GunModule.Equip then
        W.OriginalEquip = GunModule.Equip
        GunModule.Equip = function(self, ...)
            if W.InstantEquip then
                self._is_revolver_quick_shooting = nil
                self._shoot_cooldown = 0
                self:_ResetReloadState()
                return
            end
            if W.NoEquipAnimation then
                local res = { W.OriginalEquip(self, ...) }
                if self.ViewModel then
                    self.ViewModel:StopAnimation("Equip")
                    self.ViewModel:StopAnimation("EquipEmpty")
                end
                return unpack(res)
            end
            return W.OriginalEquip(self, ...)
        end
    end

    -- _ProjectileEffect  (ProjectileSpeed)
    if GunModule._ProjectileEffect then
        W.OriginalProjectileEffect = GunModule._ProjectileEffect
        GunModule._ProjectileEffect = function(self, proj, p2)
            if W.ProjectileSpeed and proj and proj.Velocity then
                proj.Velocity = proj.Velocity * W.ProjectileSpeedMultiplier
            end
            return W.OriginalProjectileEffect(self, proj, p2)
        end
    end

    -- _LocalTracers  (InstantBulletTravel)
    if GunModule._LocalTracers then
        W.OriginalLocalTracers = GunModule._LocalTracers
        GunModule._LocalTracers = function(self, p1, p2)
            if W.InstantBulletTravel then
                local oP = self.Info.RaycastPierceCount
                local oB = self.Info.RaycastBounceCount
                local oA = self.Info.RaycastBounceRedirectionAngle
                self.Info.RaycastPierceCount             = 999
                self.Info.RaycastBounceCount             = 0
                self.Info.RaycastBounceRedirectionAngle  = 0
                local res = { W.OriginalLocalTracers(self, p1, p2) }
                self.Info.RaycastPierceCount             = oP
                self.Info.RaycastBounceCount             = oB
                self.Info.RaycastBounceRedirectionAngle  = oA
                return unpack(res)
            end
            return W.OriginalLocalTracers(self, p1, p2)
        end
    end

    -- Silent Aim: hook GetRayOrigin / shoot direction to snap toward target head
    local function GetSilentAimTarget()
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local closest, closestDist = nil, math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character; if not char then continue end
            local head = char:FindFirstChild("Head")
            local hum  = char:FindFirstChild("Humanoid")
            if not head or not hum or hum.Health <= 0 then continue end
            local sp, onS = Camera:WorldToViewportPoint(head.Position)
            if not onS then continue end
            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
            if d < closestDist then closestDist = d; closest = head end
        end
        return closest
    end

    -- Hook _Shoot or the raycast direction via GetRayOrigin if it exists
    local shootFns = { "_Shoot", "Shoot", "_Fire", "Fire" }
    for _, fnName in ipairs(shootFns) do
        if GunModule[fnName] then
            local orig = GunModule[fnName]
            W["OriginalGetRayOrigin"] = orig
            GunModule[fnName] = function(self, ...)
                if Config.Aimbot.SilentAim then
                    local target = GetSilentAimTarget()
                    if target then
                        -- Temporarily point camera at head so the game's own
                        -- raycast origin lands on the target, then restore.
                        local origCF = Camera.CFrame
                        Camera.CFrame = CFrame.new(origCF.Position,
                            target.Position + Vector3.new(0, 0.1, 0))
                        local res = { orig(self, ...) }
                        Camera.CFrame = origCF
                        return unpack(res)
                    end
                end
                return orig(self, ...)
            end
            break
        end
    end
end)

-- GameplayUtility  (NoSpread)
task.spawn(function()
    local ok, GU = pcall(function() return require(RS.Modules.GameplayUtility) end)
    if not ok or not GU or not GU.GetSpread then return end
    W.GameplayUtility  = GU
    W.OriginalGetSpread = GU.GetSpread
    GU.GetSpread = function(spread, aimMul, isAiming, isCrouching, pellet, total, consistent)
        if W.NoSpread then return CFrame.new() end
        return W.OriginalGetSpread(spread, aimMul, isAiming, isCrouching, pellet, total, consistent)
    end
end)

-- ViewModel  (NoWeaponBob)
task.spawn(function()
    local ok, VM = pcall(function() return require(LocalPlayer.PlayerScripts.Modules.ViewModel) end)
    if not ok or not VM or not VM.new then return end
    local origNew = VM.new
    VM.new = function(...)
        local vm = origNew(...)
        if vm.Update then
            local origUpdate = vm.Update
            vm.Update = function(self, ...)
                if W.NoWeaponBob then
                    if self.BobSpeed     then self.BobSpeed     = 0 end
                    if self.BobIntensity then self.BobIntensity = 0 end
                end
                return origUpdate(self, ...)
            end
        end
        return vm
    end
end)
-- RShift: hide everything, restore on reopen
local _savedPanelStates = nil
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode ~= Enum.KeyCode.RightShift then return end
    if Sidebar.Visible then
        -- save panel states then hide all
        _savedPanelStates = {}
        for name, data in pairs(OpenPanels) do
            _savedPanelStates[name] = data.panel.Visible
            data.panel.Visible = false
        end
        Sidebar.Visible = false
    else
        -- restore
        Sidebar.Visible = true
        if _savedPanelStates then
            for name, data in pairs(OpenPanels) do
                local wasVisible = _savedPanelStates[name]
                data.panel.Visible           = wasVisible
                data.navBtn.BackgroundColor3 = wasVisible and T.RowActive or T.Row
                data.nameLbl.TextColor3      = wasVisible and Color3.fromRGB(255,255,255) or T.Text
                data.iconLbl.TextColor3      = wasVisible and Color3.fromRGB(255,255,255) or T.Accent
                data.arrow.TextColor3        = wasVisible and Color3.fromRGB(255,255,255) or T.TextDim
            end
        end
    end
end)

-- Scroll wheel resizes FOV while aimbot key held
UserInputService.InputChanged:Connect(function(input)
    if not Config.Aimbot.Enabled then return end
    if not UserInputService:IsKeyDown(Config.Aimbot.Key) then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        Config.Aimbot.FovRadius = math.clamp(Config.Aimbot.FovRadius + input.Position.Z * 10, 10, 800)
    end
end)

-- ============================================================
--  ESP DRAWINGS
-- ============================================================
local ESPObjects = {}

local function RemoveESP(player)
    if ESPObjects[player] then
        for _, d in pairs(ESPObjects[player]) do pcall(function() d:Remove() end) end
        ESPObjects[player] = nil
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    RemoveESP(player)
    local e = {
        Box    = Drawing.new("Square"),
        Name   = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
    }
    e.Box.Visible    = false; e.Box.Filled = false
    e.Box.Color      = Config.ESP.BoxColor; e.Box.Thickness = Config.ESP.BoxThick
    e.Name.Visible   = false; e.Name.Center = true; e.Name.Outline = true
    e.Name.Size      = 13;    e.Name.Font   = Drawing.Fonts.UI
    e.Name.Color     = Config.ESP.NameColor
    e.Tracer.Visible = false; e.Tracer.Color = Config.ESP.TracerColor
    e.Tracer.Thickness = 1
    ESPObjects[player] = e
end

for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- ============================================================
--  FLY
-- ============================================================
local flyConn
local function StartFly()
    local char = LocalPlayer.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local bp = Instance.new("BodyVelocity", root)
    bp.MaxForce = Vector3.new(1e5,1e5,1e5); bp.Velocity = Vector3.zero
    local bg = Instance.new("BodyGyro", root)
    bg.MaxTorque = Vector3.new(1e5,1e5,1e5); bg.D = 100
    flyConn = RunService.RenderStepped:Connect(function()
        if not Config.Movement.Fly then
            pcall(function() bp:Destroy(); bg:Destroy() end)
            flyConn:Disconnect(); return
        end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        bp.Velocity = dir.Magnitude > 0 and dir.Unit * Config.Movement.FlySpeed or Vector3.zero
        bg.CFrame   = Camera.CFrame
    end)
end

local prevFly = false
RunService.Heartbeat:Connect(function()
    if Config.Movement.Fly ~= prevFly then
        prevFly = Config.Movement.Fly
        if Config.Movement.Fly then StartFly() end
    end
end)

-- ============================================================
--  FOV DRAWINGS
-- ============================================================
local FovFill = Drawing.new("Circle")
FovFill.Visible      = false
FovFill.Radius       = Config.Aimbot.FovRadius
FovFill.Color        = Color3.fromRGB(255, 255, 255)
FovFill.Transparency = 0.2
FovFill.Thickness    = 1
FovFill.Filled       = true

local FovCircle = Drawing.new("Circle")
FovCircle.Visible   = false
FovCircle.Radius    = Config.Aimbot.FovRadius
FovCircle.Color     = Color3.fromRGB(205, 205, 205)
FovCircle.Thickness = 1
FovCircle.Filled    = false

local TargetTracer = Drawing.new("Line")
TargetTracer.Visible      = false
TargetTracer.Color        = Config.Aimbot.TracerColor
TargetTracer.Thickness    = 1
TargetTracer.Transparency = 1

local FovCirclePos = UserInputService:GetMouseLocation()

-- ============================================================
--  RENDER LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    -- ESP
    for player, d in pairs(ESPObjects) do
        local ok = Config.ESP.Enabled
            and player.Character
            and player.Character:FindFirstChild("HumanoidRootPart")
            and player.Character:FindFirstChild("Humanoid")
            and player.Character.Humanoid.Health > 0
        if ok then
            local root = player.Character.HumanoidRootPart
            local dist = (Camera.CFrame.Position - root.Position).Magnitude
            if dist <= Config.ESP.MaxDist then
                local rp, onS = Camera:WorldToViewportPoint(root.Position)
                if Config.ESP.ShowBox and onS then
                    local tp  = Camera:WorldToViewportPoint(root.Position + Vector3.new(0,3.2,0))
                    local bp2 = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3.2,0))
                    local h = math.abs(tp.Y - bp2.Y); local w = h * 0.55
                    d.Box.Size = Vector2.new(w,h); d.Box.Position = Vector2.new(rp.X-w/2, tp.Y)
                    d.Box.Visible = true
                else d.Box.Visible = false end
                if Config.ESP.ShowName and onS then
                    local np = Camera:WorldToViewportPoint(root.Position + Vector3.new(0,3.8,0))
                    d.Name.Text = player.Name.."  ["..math.floor(dist).."m]"
                    d.Name.Position = Vector2.new(np.X, np.Y); d.Name.Visible = true
                else d.Name.Visible = false end
                if Config.ESP.ShowTracer and onS then
                    local sc = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    d.Tracer.From = sc; d.Tracer.To = Vector2.new(rp.X,rp.Y); d.Tracer.Visible = true
                else d.Tracer.Visible = false end
            else d.Box.Visible=false; d.Name.Visible=false; d.Tracer.Visible=false end
        else
            if d.Box    then d.Box.Visible    = false end
            if d.Name   then d.Name.Visible   = false end
            if d.Tracer then d.Tracer.Visible = false end
        end
    end

    -- FOV circle follows mouse with lerp
    local center   = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local mousePos = UserInputService:GetMouseLocation()
    FovCirclePos   = FovCirclePos:Lerp(mousePos, 0.18)

    FovFill.Position   = FovCirclePos; FovFill.Radius   = Config.Aimbot.FovRadius; FovFill.Visible   = Config.Aimbot.Enabled
    FovCircle.Position = FovCirclePos; FovCircle.Radius = Config.Aimbot.FovRadius; FovCircle.Visible = Config.Aimbot.Enabled

    -- find closest target within FOV (shared by aimbot + silent aim)
    local function GetTarget()
        local best, bestDist = nil, Config.Aimbot.FovRadius
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character; if not char then continue end
            local head = char:FindFirstChild("Head")
            local hum  = char:FindFirstChild("Humanoid")
            if not head or not hum or hum.Health <= 0 then continue end
            local sp, onS = Camera:WorldToViewportPoint(head.Position)
            if not onS then continue end
            local dd = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
            if dd < bestDist then bestDist = dd; best = head end
        end
        return best
    end

    -- Aimbot: smoothly rotate camera toward target head
    if Config.Aimbot.Enabled and UserInputService:IsKeyDown(Config.Aimbot.Key) then
        local target = GetTarget()
        if target then
            local hp, onS = Camera:WorldToViewportPoint(target.Position)
            if onS then
                local sm = math.max(1, Config.Aimbot.Smoothing)

                if Config.Aimbot.AimType == "MouseMove" then
                    -- MouseMove: move the real mouse cursor toward the target
                    -- This drives Rivals' own camera system naturally in first person
                    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                    local targetScreen = Vector2.new(hp.X, hp.Y)
                    local delta        = targetScreen - screenCenter
                    local moveX        = delta.X / sm
                    local moveY        = delta.Y / sm
                    -- clamp per-frame movement so it doesn't snap
                    local maxMove = 50
                    moveX = math.clamp(moveX, -maxMove, maxMove)
                    moveY = math.clamp(moveY, -maxMove, maxMove)
                    mousemoverel(moveX, moveY)
                else
                    -- CFrame: directly set camera (works in third person / unlocked cameras)
                    local cf     = Camera.CFrame
                    local goalCF = CFrame.new(cf.Position, target.Position)
                    Camera.CFrame = cf:Lerp(goalCF, 1 / sm)
                end

                TargetTracer.Color   = Config.Aimbot.TracerColor
                TargetTracer.From    = Vector2.new(hp.X, hp.Y)
                TargetTracer.To      = mousePos
                TargetTracer.Visible = Config.Aimbot.TracerEnabled
            else
                TargetTracer.Visible = false
            end
        else
            TargetTracer.Visible = false
        end
    else
        TargetTracer.Visible = false
    end

    -- Silent Aim: every frame, if enabled, keep a target locked.
    -- We store the target and redirect the camera only during the
    -- actual shoot frame via InputBegan (handled below).
    if Config.Aimbot.SilentAim then
        _G.__SilentAimTarget = GetTarget()
    else
        _G.__SilentAimTarget = nil
    end
end)

-- ============================================================
--  SILENT AIM  — Rivals-specific approach
--  Hooks into the GunModule's shoot functions to redirect the
--  raycast origin CFrame right before the bullet is cast,
--  then restores it immediately after. This happens synchronously
--  inside the same call so Rivals sees the spoofed direction.
-- ============================================================
local function SilentAimActive()
    if not Config.Aimbot.SilentAim then return false end
    local mode = Config.Aimbot.SilentAimMode
    if mode == "Always" then return true end
    if mode == "Toggle" then return Config.Aimbot.SilentAimToggled end
    if mode == "Hold"   then return UserInputService:IsKeyDown(Config.Aimbot.SilentAimKey) end
    return false
end

local function GetSilentTarget()
    if not SilentAimActive() then return nil end
    local mousePos   = UserInputService:GetMouseLocation()
    local useFov     = Config.Aimbot.SilentAimFov
    local fovRadius  = Config.Aimbot.SilentAimFovRadius
    local best, bestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character; if not char then continue end
        local head = char:FindFirstChild("Head")
        local hum  = char:FindFirstChild("Humanoid")
        if not head or not hum or hum.Health <= 0 then continue end
        local sp, onS = Camera:WorldToViewportPoint(head.Position)
        if not onS then continue end
        local dd = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
        -- if FOV is enabled, skip targets outside the radius entirely
        if useFov and dd > fovRadius then continue end
        if dd < bestDist then bestDist = dd; best = head end
    end
    return best
end

-- Handle Toggle/Hold key presses
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Config.Aimbot.SilentAimKey then
        if Config.Aimbot.SilentAimMode == "Toggle" then
            Config.Aimbot.SilentAimToggled = not Config.Aimbot.SilentAimToggled
        end
    end
end)

-- Handle Toggle/Hold key presses
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Config.Aimbot.SilentAimKey then
        if Config.Aimbot.SilentAimMode == "Toggle" then
            Config.Aimbot.SilentAimToggled = not Config.Aimbot.SilentAimToggled
        end
    end
end)

-- ============================================================
--  SILENT AIM
--  Uses hookfunction on the GunModule's StartShooting to spoof
--  the bullet direction without ever touching Camera.CFrame.
--  Camera.CFrame writes cause Rivals' FPS controller to snap
--  your view which is what was killing you.
--
--  How it works:
--    1. We wait for GunModule to be hooked (done in the Weapons
--       task.spawn above).
--    2. We wrap StartShooting a second time. Before calling the
--       original, we temporarily set a fake CFrame on the camera
--       only inside a __index metatable hook — so Rivals' raycast
--       reads our spoofed direction but the visual camera is
--       untouched.
--    3. We immediately tear down the spoof after the call returns
--       synchronously — no delay needed.
-- ============================================================
local _silentActive  = false
local _silentCF      = nil
local _origCameraIdx = nil
local _silentHooked  = false

local function InstallCameraIndexHook()
    local ok, mt = pcall(getrawmetatable, Camera)
    if not ok or not mt then return false end
    local oldIndex = rawget(mt, "__index")
    if not oldIndex then return false end
    _origCameraIdx = oldIndex
    local ok2 = pcall(function()
        setreadonly(mt, false)
        mt.__index = newcclosure(function(self, key)
            if _silentActive and key == "CFrame" and _silentCF then
                return _silentCF
            end
            return oldIndex(self, key)
        end)
        setreadonly(mt, true)
    end)
    return ok2
end

local function RemoveCameraIndexHook()
    if not _origCameraIdx then return end
    local ok, mt = pcall(getrawmetatable, Camera)
    if not ok or not mt then return end
    pcall(function()
        setreadonly(mt, false)
        mt.__index = _origCameraIdx
        setreadonly(mt, true)
    end)
    _origCameraIdx = nil
end

pcall(InstallCameraIndexHook)

-- Wrap GunModule.StartShooting for silent aim once it's available.
-- We poll until the Weapons task.spawn has finished loading the module.
task.spawn(function()
    -- wait up to 10s for GunModule to be set
    local deadline = tick() + 10
    while tick() < deadline do
        if Config.Weapons.GunModule and Config.Weapons.GunModule.StartShooting then
            break
        end
        task.wait(0.2)
    end

    local GunModule = Config.Weapons.GunModule
    if not GunModule or not GunModule.StartShooting then return end
    if _silentHooked then return end
    _silentHooked = true

    -- Wrap on top of whatever hook is already there (rapid fire etc.)
    local prevShoot = GunModule.StartShooting
    GunModule.StartShooting = function(self, p1, p2)
        if SilentAimActive() then
            local target = GetSilentTarget()
            if target then
                local realCF = Camera.CFrame
                -- Build spoof pointing from camera pos to target head
                _silentCF    = CFrame.new(realCF.Position,
                    target.Position + Vector3.new(0, 0.15, 0))
                _silentActive = true
                local res = { prevShoot(self, p1, p2) }
                -- Tear down immediately — synchronous, no delay
                _silentActive = false
                _silentCF     = nil
                return unpack(res)
            end
        end
        return prevShoot(self, p1, p2)
    end
end)
local noclipConns = {}
local function ClearNoclipConns()
    for _, c in ipairs(noclipConns) do c:Disconnect() end; noclipConns = {}
end
local function RestoreCollision()
    local char = LocalPlayer.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end
end
local function HookPart(part)
    if not part:IsA("BasePart") then return end
    part.CanCollide = false
    table.insert(noclipConns, part:GetPropertyChangedSignal("CanCollide"):Connect(function()
        if Config.Movement.Noclip then part.CanCollide = false end
    end))
end
local function EnableNoclip()
    ClearNoclipConns()
    local char = LocalPlayer.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do HookPart(p) end
    table.insert(noclipConns, char.DescendantAdded:Connect(function(d)
        if Config.Movement.Noclip then HookPart(d) end
    end))
end
local function DisableNoclip()
    ClearNoclipConns(); RestoreCollision()
end
local prevNoclip = false
RunService.Heartbeat:Connect(function()
    if Config.Movement.Noclip ~= prevNoclip then
        prevNoclip = Config.Movement.Noclip
        if Config.Movement.Noclip then EnableNoclip() else DisableNoclip() end
    end
end)

-- ============================================================
--  RESPAWN
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = Config.Movement.Speed
    hum.JumpPower = Config.Movement.JumpPower
    for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
    if Config.Movement.Fly    then StartFly()      end
    if Config.Movement.Noclip then EnableNoclip()  end
end)

print("[Crypton Hub] Loaded ✓  |  RShift = toggle  |  X (hold) = aimbot lock")

-- ============================================================
--  DESTROY
-- ============================================================
local function DestroyAll()
    Config.ESP.Enabled     = false
    Config.Movement.Fly    = false
    Config.Movement.Noclip = false
    Config.Aimbot.Enabled  = false
    DisableNoclip()

    -- Restore Rivals weapon hooks
    local Wc = Config.Weapons
    if Wc.GunModule then
        local G = Wc.GunModule
        if Wc.OriginalStartShooting    then G.StartShooting    = Wc.OriginalStartShooting    end
        if Wc.OriginalStartReloading   then G.StartReloading   = Wc.OriginalStartReloading   end
        if Wc.OriginalRecoil           then G._Recoil          = Wc.OriginalRecoil           end
        if Wc.OriginalStartAiming      then G.StartAiming      = Wc.OriginalStartAiming      end
        if Wc.OriginalGetAimSpeed      then G.GetAimSpeed      = Wc.OriginalGetAimSpeed      end
        if Wc.OriginalEquip            then G.Equip            = Wc.OriginalEquip            end
        if Wc.OriginalLocalTracers     then G._LocalTracers    = Wc.OriginalLocalTracers     end
        if Wc.OriginalProjectileEffect then G._ProjectileEffect= Wc.OriginalProjectileEffect end
        if Wc.OriginalGetRayOrigin then
            local shootFns = { "_Shoot", "Shoot", "_Fire", "Fire" }
            for _, fn in ipairs(shootFns) do
                if G[fn] then G[fn] = Wc.OriginalGetRayOrigin; break end
            end
        end
    end
    if Wc.GameplayUtility and Wc.OriginalGetSpread then
        Wc.GameplayUtility.GetSpread = Wc.OriginalGetSpread
    end

    for _, d in pairs(ESPObjects) do
        for _, drawing in pairs(d) do pcall(function() drawing:Remove() end) end
    end
    ESPObjects = {}
    _silentActive = false
    _silentCF     = nil
    pcall(RemoveCameraIndexHook)

    pcall(function() FovFill:Remove()      end)
    pcall(function() FovCircle:Remove()    end)
    pcall(function() TargetTracer:Remove() end)
    ScreenGui:Destroy()
end

DestroyBtn.MouseButton1Click:Connect(DestroyAll)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Delete
    and UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
        DestroyAll()
    end
end)
