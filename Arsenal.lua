-- =====================================================================
-- 💎 MIKU HUB x ARSENAL INTEGRATION v16.6 (FIXED AUTO FIRE CLICK)
-- Giao diện: Miku Hub | Phím tắt: [P] hoặc nút Mini
-- =====================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local TOGGLE_KEY = Enum.KeyCode.P

-- 📌 Cấu hình Asset ID chuẩn Miku Hub
local MIKU_ICON_ID = "rbxassetid://106578126080237"
local MIKU_BG_ID = "rbxassetid://126622637598764"
local MIKU_COLOR = Color3.fromRGB(57, 197, 187) -- Teal Miku

-- ==========================================================
-- ⚙️ CẤU HÌNH MẶC ĐỊNH LÀ TẮT (FALSE)
-- ==========================================================
_G.EspHighlight = false
_G.AutoGhim = false
_G.AutoFire = false
_G.AutoTeleport = false

local ARSENAL_MAX_DISTANCE = 150
local CLICK_COOLDOWN = 0.001 -- Delay 1ms
local isClicking = false

local highlights = {}

local function isEnemy(p)
    if not player.Team or not p.Team then return true end
    return p.Team ~= player.Team
end

-- 🛠️ HỆ THỐNG QUÉT ĐA ĐIỂM (MULTI-POINT RAYCAST)
local function isVisible(targetCharacter)
    local origin = camera.CFrame.Position
    local partsToCheck = {"Head", "UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart"}
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local filterList = {player.Character}
    for _, p in ipairs(Players:GetPlayers()) do
        if not isEnemy(p) and p.Character then
            table.insert(filterList, p.Character)
        end
    end
    raycastParams.FilterDescendantsInstances = filterList

    for _, partName in ipairs(partsToCheck) do
        local part = targetCharacter:FindFirstChild(partName)
        if part then
            local direction = part.Position - origin
            local result = workspace:Raycast(origin, direction, raycastParams)
            
            if result and result.Instance:IsDescendantOf(targetCharacter) then
                return true, part
            end
        end
    end
    
    return false, nil
end

local function getNearestVisibleEnemy()
    local myCharacter = player.Character
    if not myCharacter then return nil, nil end
    local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
    local myHumanoid = myCharacter:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHumanoid or myHumanoid.Health <= 0 then return nil, nil end

    local nearestEnemy = nil
    local targetPartToAim = nil
    local shortestDistance = ARSENAL_MAX_DISTANCE

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and isEnemy(p) and p.Character then
            local char = p.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and humanoid and humanoid.Health > 0 then
                local distance = (root.Position - myRoot.Position).Magnitude
                if distance < shortestDistance then
                    local visible, visPart = isVisible(char)
                    if visible then
                        shortestDistance = distance
                        nearestEnemy = p
                        targetPartToAim = visPart
                    end
                end
            end
        end
    end
    return nearestEnemy, targetPartToAim
end

local function getNearestEnemyAny()
    local myCharacter = player.Character
    if not myCharacter then return nil end
    local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
    local myHumanoid = myCharacter:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHumanoid or myHumanoid.Health <= 0 then return nil end

    local nearestEnemy = nil
    local shortestDistance = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and isEnemy(p) and p.Character then
            local char = p.Character
            local enemyRoot = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if enemyRoot and humanoid and humanoid.Health > 0 then
                local distance = (enemyRoot.Position - myRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestEnemy = p
                end
            end
        end
    end
    return nearestEnemy
end

local function updateHighlight(p)
    if not p.Character or not isEnemy(p) or not _G.EspHighlight then
        if highlights[p] then
            highlights[p]:Destroy()
            highlights[p] = nil
        end
        return
    end

    local char = p.Character
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 or not myRoot then
        if highlights[p] then
            highlights[p]:Destroy()
            highlights[p] = nil
        end
        return
    end

    if not highlights[p] or highlights[p].Parent ~= char then
        if highlights[p] then highlights[p]:Destroy() end
        local hl = Instance.new("Highlight")
        hl.Name = "MikuHighlight"
        hl.Adornee = char
        hl.Parent = char
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        highlights[p] = hl
    end

    local visible, _ = isVisible(char)
    if visible then
        highlights[p].FillColor = Color3.fromRGB(0, 255, 0)
        highlights[p].OutlineColor = Color3.fromRGB(0, 200, 0)
    else
        highlights[p].FillColor = Color3.fromRGB(255, 0, 0)
        highlights[p].OutlineColor = Color3.fromRGB(200, 0, 0)
    end
end

Players.PlayerRemoving:Connect(function(p)
    if highlights[p] then
        highlights[p]:Destroy()
        highlights[p] = nil
    end
end)

-- Vòng lặp Render chính
RunService.RenderStepped:Connect(function()
    local targetEnemy, aimPart = getNearestVisibleEnemy()

    -- 1. Auto Ghim (Ghim thẳng vào bộ phận lộ diện)
    if _G.AutoGhim then
        if targetEnemy and aimPart then
            local camPos = camera.CFrame.Position
            camera.CFrame = CFrame.new(camPos, aimPart.Position)
        end
    end

    -- 2. Auto Teleport
    if _G.AutoTeleport then
        local targetEnemyAny = getNearestEnemyAny()
        if targetEnemyAny and targetEnemyAny.Character then
            local enemyRoot = targetEnemyAny.Character:FindFirstChild("HumanoidRootPart")
            local myCharacter = player.Character
            if enemyRoot and myCharacter then
                local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local behindCFrame = enemyRoot.CFrame * CFrame.new(0, 0, 1)
                    myRoot.CFrame = behindCFrame
                end
            end
        end
    end

    -- 3. Auto Fire: Sử dụng cách click chuẩn của Arsenal, đổi điều kiện thành "khi đang tìm thấy mục tiêu để ghim"
    if _G.AutoFire and not isClicking then
        if targetEnemy and aimPart then
            isClicking = true
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            task.wait(CLICK_COOLDOWN)
            isClicking = false
        end
    end

    -- 4. Cập nhật Highlight ESP
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            updateHighlight(p)
        end
    end
end)

local function perfectDrag(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ==========================================================
-- 🎨 KHỞI TẠO GIAO DIỆN MIKU HUB
-- ==========================================================
if CoreGui:FindFirstChild("MikuHubArsenal") then CoreGui.MikuHubArsenal:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MikuHubArsenal"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MiniBtn = Instance.new("ImageButton")
MiniBtn.Name = "MiniToggle"
MiniBtn.Parent = ScreenGui
MiniBtn.Position = UDim2.new(0, 15, 0, 15)
MiniBtn.Size = UDim2.new(0, 48, 0, 48)
MiniBtn.Image = MIKU_ICON_ID
MiniBtn.BackgroundColor3 = Color3.fromRGB(15, 30, 35)
MiniBtn.Active = true
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(1, 0)

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Parent = MiniBtn
MiniStroke.Thickness = 2.5
MiniStroke.Color = MIKU_COLOR
perfectDrag(MiniBtn, MiniBtn)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 500, 0, 340)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 22, 26)
MainFrame.BackgroundTransparency = 0.05
MainFrame.Active = true
MainFrame.ClipsDescendants = true 
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local BackgroundImage = Instance.new("ImageLabel")
BackgroundImage.Parent = MainFrame
BackgroundImage.Size = UDim2.new(1, 0, 1, 0)
BackgroundImage.Image = MIKU_BG_ID
BackgroundImage.ImageTransparency = 0.7
BackgroundImage.ScaleType = Enum.ScaleType.Crop
BackgroundImage.BackgroundTransparency = 1
BackgroundImage.ZIndex = 0

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Thickness = 2
MainStroke.Color = MIKU_COLOR

local TopBar = Instance.new("Frame")
TopBar.Parent = MainFrame
TopBar.BackgroundTransparency = 0.2
TopBar.BackgroundColor3 = Color3.fromRGB(15, 30, 35)
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.ZIndex = 2
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
perfectDrag(MainFrame, TopBar)

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "MIKU HUB x ARSENAL (LOCKED AUTO FIRE)"
Title.TextColor3 = MIKU_COLOR
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 2

local SideBar = Instance.new("Frame")
SideBar.Parent = MainFrame
SideBar.BackgroundTransparency = 0.2
SideBar.BackgroundColor3 = Color3.fromRGB(10, 20, 24)
SideBar.Position = UDim2.new(0, 8, 0, 44)
SideBar.Size = UDim2.new(0, 110, 1, -52)
SideBar.ZIndex = 2
Instance.new("UICorner", SideBar).CornerRadius = UDim.new(0, 8)

local UIListLayout_SideTabs = Instance.new("UIListLayout")
UIListLayout_SideTabs.Parent = SideBar
UIListLayout_SideTabs.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout_SideTabs.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_SideTabs.Padding = UDim.new(0, 6)

local SidePadding = Instance.new("UIPadding")
SidePadding.Parent = SideBar
SidePadding.PaddingTop = UDim.new(0, 6)

local function createVerticalTabButton(name, text, order)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = SideBar
    btn.BackgroundColor3 = Color3.fromRGB(18, 35, 40)
    btn.Size = UDim2.new(0.92, 0, 0, 38)
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(140, 185, 190)
    btn.TextSize = 10
    btn.LayoutOrder = order
    btn.ZIndex = 3
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.fromRGB(35, 65, 70)
    s.Thickness = 1
    return btn
end

local BtnTabArsenal = createVerticalTabButton("TabArsenal", "🎯 ARSENAL", 1)

local ContentFrame = Instance.new("Frame")
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 126, 0, 44)
ContentFrame.Size = UDim2.new(1, -134, 1, -52)
ContentFrame.ZIndex = 2

local function createPhoneToggle(parent, titleText, defaultState, callback)
    local SwitchContainer = Instance.new("Frame")
    SwitchContainer.Parent = parent
    SwitchContainer.BackgroundColor3 = Color3.fromRGB(16, 30, 35)
    SwitchContainer.BackgroundTransparency = 0.1
    SwitchContainer.Size = UDim2.new(1, 0, 0, 36)
    SwitchContainer.ZIndex = 2
    Instance.new("UICorner", SwitchContainer).CornerRadius = UDim.new(0, 6)

    local ContainerStroke = Instance.new("UIStroke")
    ContainerStroke.Parent = SwitchContainer
    ContainerStroke.Color = Color3.fromRGB(35, 65, 70)
    ContainerStroke.Thickness = 1

    local Label = Instance.new("TextLabel")
    Label.Parent = SwitchContainer
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Font = Enum.Font.GothamBold
    Label.Text = titleText
    Label.TextColor3 = Color3.fromRGB(220, 240, 240)
    Label.TextSize = 10.5
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 3

    local ToggleTrack = Instance.new("TextButton")
    ToggleTrack.Name = "ToggleTrack"
    ToggleTrack.Parent = SwitchContainer
    ToggleTrack.AnchorPoint = Vector2.new(1, 0.5)
    ToggleTrack.Position = UDim2.new(1, -8, 0.5, 0)
    ToggleTrack.Size = UDim2.new(0, 42, 0, 22)
    ToggleTrack.BackgroundColor3 = defaultState and MIKU_COLOR or Color3.fromRGB(40, 50, 55)
    ToggleTrack.Text = ""
    ToggleTrack.ZIndex = 3
    Instance.new("UICorner", ToggleTrack).CornerRadius = UDim.new(1, 0)

    local Thumb = Instance.new("Frame")
    Thumb.Name = "Thumb"
    Thumb.Parent = ToggleTrack
    Thumb.AnchorPoint = Vector2.new(0, 0.5)
    Thumb.Position = defaultState and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    Thumb.Size = UDim2.new(0, 16, 0, 16)
    Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Thumb.ZIndex = 4
    Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)

    local isOn = defaultState or false
    ToggleTrack.MouseButton1Click:Connect(function()
        isOn = not isOn
        local targetPos = isOn and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        local targetColor = isOn and MIKU_COLOR or Color3.fromRGB(40, 50, 55)
        local strokeColor = isOn and MIKU_COLOR or Color3.fromRGB(35, 65, 70)

        TweenService:Create(Thumb, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(ToggleTrack, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(ContainerStroke, TweenInfo.new(0.2), {Color = strokeColor}):Play()

        callback(isOn)
    end)
end

local PageArsenal = Instance.new("ScrollingFrame")
PageArsenal.Parent = ContentFrame
PageArsenal.BackgroundTransparency = 1
PageArsenal.Size = UDim2.new(1, 0, 1, 0)
PageArsenal.ScrollBarThickness = 2
PageArsenal.ZIndex = 2

local UIListLayout_Arsenal = Instance.new("UIListLayout")
UIListLayout_Arsenal.Parent = PageArsenal
UIListLayout_Arsenal.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Arsenal.Padding = UDim.new(0, 8)

createPhoneToggle(PageArsenal, "✨ Highlight ESP (Đỏ/Xanh)", _G.EspHighlight, function(state)
    _G.EspHighlight = state
    if not state then
        for p, hl in pairs(highlights) do
            hl:Destroy()
            highlights[p] = nil
        end
    end
end)

createPhoneToggle(PageArsenal, "🎯 Auto Ghim Mục Tiêu", _G.AutoGhim, function(state)
    _G.AutoGhim = state
end)

createPhoneToggle(PageArsenal, "📍 Auto Teleport (Beta - Sau Lưng)", _G.AutoTeleport, function(state)
    _G.AutoTeleport = state
end)

createPhoneToggle(PageArsenal, "🔥 Auto Fire (Tự Động Bắn)", _G.AutoFire, function(state)
    _G.AutoFire = state
end)

local isMenuOpen = true
local function toggleMenu()
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        MainFrame.Visible = true
        MainFrame:TweenSize(UDim2.new(0, 500, 0, 340), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.3, true)
    else
        MainFrame:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Back, 0.3, true, function() MainFrame.Visible = false end)
    end
end

MiniBtn.MouseButton1Click:Connect(toggleMenu)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == TOGGLE_KEY then toggleMenu() end
end)

print("🎯 Miku Hub x Arsenal (Locked Auto Fire) đã sẵn sàng!")
