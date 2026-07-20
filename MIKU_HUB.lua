-- =====================================================================
-- 💎 MIKU HUB V13.0: CLEAN TITLE & UI FIX
-- Tác giả: Gemini | Phím tắt: [P] hoặc Bấm nút Mini trên màn hình
-- Phiên bản: v13.0
-- =====================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PhysicsService = game:GetService("PhysicsService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local TOGGLE_KEY = Enum.KeyCode.P

-- 📌 Cấu hình Asset ID chuẩn V13.0
local MIKU_ICON_ID = "rbxassetid://106578126080237"
local MIKU_BG_ID = "rbxassetid://126622637598764"
local MIKU_COLOR = Color3.fromRGB(57, 197, 187) -- Teal Miku

-- ==========================================================
-- 🛡️ KHỞI TẠO HỆ THỐNG VA CHẠM (COLLISION GROUPS)
-- ==========================================================
local function pcallCollision(func)
    local c, e = pcall(func)
    return c
end

pcallCollision(function() PhysicsService:RegisterCollisionGroup("PlayersGroup") end)
pcallCollision(function() PhysicsService:RegisterCollisionGroup("NpcsGroup") end)
pcallCollision(function() PhysicsService:CollisionGroupSetCollidable("PlayersGroup", "NpcsGroup", false) end)
pcallCollision(function() PhysicsService:CollisionGroupSetCollidable("PlayersGroup", "PlayersGroup", false) end)

local function setCollisionGroup(model, groupName)
    if model and model:IsA("Model") then
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                pcallCollision(function() part.CollisionGroup = groupName end)
            end
        end
    end
end

local function setupLocalPlayerCollision(char)
    if char then
        setCollisionGroup(char, "PlayersGroup")
        char.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then
                pcallCollision(function() part.CollisionGroup = "PlayersGroup" end)
            end
        end)
    end
end
if player.Character then setupLocalPlayerCollision(player.Character) end
player.CharacterAdded:Connect(setupLocalPlayerCollision)

local function setupOtherPlayerCollision(plr)
    plr.CharacterAdded:Connect(function(char)
        setCollisionGroup(char, "PlayersGroup")
    end)
    if plr.Character then setCollisionGroup(plr.Character, "PlayersGroup") end
end
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then setupOtherPlayerCollision(plr) end
end
game:GetService("Players").PlayerAdded:Connect(setupOtherPlayerCollision)

-- ==========================================================
-- ⚙️ CẤU HÌNH AUTO FARM & CÁC TÙY CHỌN HỆ THỐNG
-- ==========================================================
local CLICK_DELAY = 0.1       
local MIXER_INTERVAL = 60.0 
local FRUIT_INTERVAL = 3.0   
local COMPASS_INTERVAL = 1.0 
local RESPAWN_INTERVAL = 6.0

local SPAM_KEY_DELAY = 0.001
local MONSTER_CLICK_DELAY = 10.0
local NORMAL_FARM_CLICK_DELAY = 0.3 

_G.MonsterDistance = 25
_G.BossDistances = {
    ["Lv20000 Whitebeard"] = 120,
    ["Lv8000 Gunner Captain"] = 100,
    ["Lv2000 Crocodile"] = 120,
    ["Lv2000 Vokun"] = 94
}

_G.autoFarm = false
_G.autoFruitRemote = false
_G.autoCompass = false 
_G.autoMonsterFarm = false
_G.autoBossFarm = false 
_G.autoRespawn = false
_G.FarmMode = "Spam C"

_G.SpamSkillsState = {
    [Enum.KeyCode.Z] = false, [Enum.KeyCode.X] = false, [Enum.KeyCode.C] = false,
    [Enum.KeyCode.V] = false, [Enum.KeyCode.B] = false, [Enum.KeyCode.N] = false,
    [Enum.KeyCode.F] = false, [Enum.KeyCode.G] = false, [Enum.KeyCode.H] = false,
    [Enum.KeyCode.J] = false, [Enum.KeyCode.K] = false, [Enum.KeyCode.L] = false
}

_G.SelectedFarmItem = ""     
_G.AutoEquipItem = false     

_G.isFlying = false
_G.FlySpeed = 80

local selectedTargetPlayer = nil
_G.autoKillPlayer = false
local spectatingPlayer = false

local task_wait = task.wait
local task_spawn = task.spawn
local Vector3_new = Vector3.new
local CFrame_new = CFrame.new
local pcall = pcall

-- ==========================================================
-- 📊 DATABASE MONSTER & ISLAND
-- ==========================================================
local MonsterGroups = {
    ["Lv1 - Lv200"] = {
        "Lv1 Crab", "Lv2 Angry Bob", "Lv3 Crab", "Lv4 Boar", "Lv4 Angry Freddy", "Lv4 Crab", "Lv5 Crab", 
        "Lv9 Bandit Traitor", "Lv11 Boar", "Lv12 Boar", "Lv12 Thug", "Lv14 Bandit", "Lv14 Boar", "Lv15 Bandit", 
        "Lv15 Boar", "Lv15 Thug", "Lv16 Boar", "Lv17 Thug", "Lv20 Thief", "Lv22 Angry Bobby", "Lv23 Thug", 
        "Lv24 Angry Bobbi", "Lv24 Fred", "Lv24 Thug", "Lv28 Fredde", "Lv28 Freyd", "Lv28 Friedrich", 
        "Lv29 Angry Bobber", "Lv29 Frued", "Lv30 Thug", "Lv32 Fredric", "Lv32 Thief", "Lv34 Freddi", 
        "Lv35 Angry Bobb", "Lv40 Cave Demon [Weakened]",
        "Lv186 Cave Demon", "Lv188 Cave Demon", "Lv198 Cave Demon"
    },
    ["Lv200 - Lv300"] = {},
    ["Lv300 - Lv400"] = { "Lv360 Bruno", "Lv440 Buster" },
    ["Farm Toàn Bộ"] = {}
}

for _, group in pairs({"Lv1 - Lv200", "Lv200 - Lv300", "Lv300 - Lv400"}) do
    for _, name in ipairs(MonsterGroups[group]) do 
        table.insert(MonsterGroups["Farm Toàn Bộ"], name) 
    end
end

local bossListOrder = {"Lv20000 Whitebeard", "Lv8000 Gunner Captain", "Lv2000 Crocodile", "Lv2000 Vokun"}

_G.SelectedBosses = {}
for _, bName in ipairs(bossListOrder) do
    _G.SelectedBosses[bName] = false
end

local currentBossTarget = nil
local bossFarmConnection = nil
local currentSelectedGroup = "Farm Toàn Bộ"
local currentTarget = nil
local monsterIndex = 1
local farmConnection = nil
local juiceList = {
    "Coconut Milk", "Fruit Juice", "Pumpkin Juice",
    "Sour Juice", "Pear Juice", "Banana Juice", "Apple Juice", "Golden Apple"
}

local islandData = {
    {name = "Đảo Alabata", key = "A", getTarget = function() return workspace.MapFolder.Alabata end},
    {name = "Đảo Boss Aura", key = "B", getTarget = function() return workspace.MapFolder.IslandKai.Folder.FourIce end},
    {name = "Đảo Boss Kiếm", key = "B", getTarget = function() return workspace.MapFolder.Island12 end},
    {name = "Đảo Bar", key = "B", getTarget = function() return workspace.MapFolder.Island13.Grass:GetChildren()[21] end},
    {name = "Đảo Bí Mật", key = "B", getTarget = function() return workspace.MapFolder.AliceCastle end},
    {name = "Đảo Cannon", key = "C", getTarget = function() return workspace.MapFolder.Island11.Folder.Board:GetChildren()[2] end},
    {name = "Đảo Cua", key = "C", getTarget = function() return workspace.MapFolder.Island15.Union end},
    {name = "Đảo Câu Cá", key = "C", getTarget = function() return workspace.MapFolder.Z_Island222:GetChildren()[6] end},
    {name = "Đảo Cave", key = "C", getTarget = function() return workspace.MapFolder.Cave end},
    {name = "Đảo Cát Mini", key = "C", getTarget = function() return workspace.MapFolder.Island1 end},
    {name = "Đảo Cliffs", key = "C", getTarget = function() return workspace.MapFolder.IslandCliffs end},
    {name = "Đảo Cát Mua Kiếm", key = "C", getTarget = function() return workspace.MapFolder.IslandSandCastle end},
    {name = "Đảo Cây", key = "C", getTarget = function() return workspace.MapFolder.IslandTREEA end},
    {name = "Đảo Cát Mini 2", key = "C", getTarget = function() return workspace.MapFolder.IslandTiny end},
    {name = "Đảo Dừa", key = "D", getTarget = function() return workspace.MapFolder.Island6.Model.Bush end},
    {name = "Đảo Đá Mini", key = "D", getTarget = function() return workspace.MapFolder.IslandRocky end},
    {name = "Đảo Không Cây", key = "K", getTarget = function() return workspace.MapFolder.IslandSenna.Grass:GetChildren()[1252] end},
    {name = "Đảo Khối Xây Gió", key = "K", getTarget = function() return workspace.MapFolder.IslandWindmill.Windmill end},
    {name = "Đảo Kiếm Thợ Rèn", key = "K", getTarget = function() return workspace.MapFolder.IslandCaver end},
    {name = "Đảo Nấu Ăn", key = "N", getTarget = function() return workspace.MapFolder.Island8.Kitchen:GetChildren()[7] end},
    {name = "Đảo Núi Cao", key = "N", getTarget = function() return workspace.MapFolder.Mountains:GetChildren()[72] end},
    {name = "Đảo Núi Tầng", key = "N", getTarget = function() return workspace.MapFolder.IslandCrescent.Mountain:GetChildren()[7] end},
    {name = "Đảo Nhà", key = "N", getTarget = function() return workspace.MapFolder.IslandGrassy end},
    {name = "Đảo Nút Đen", key = "N", getTarget = function() return workspace.MapFolder.IslandMountain end},
    {name = "Đảo Rừng", key = "R", getTarget = function() return workspace.MapFolder.IslandForest end},
    {name = "Đảo Sam", key = "S", getTarget = function() return workspace.MapFolder.IslandPirate.Cider end},
    {name = "Đảo Tổng Bộ", key = "T", getTarget = function() return workspace.MapFolder.Marine:GetChildren()[32]:GetChildren()[11] end},
    {name = "Đảo Tuyết Mua Súng", key = "T", getTarget = function() return workspace.MapFolder:GetChildren()[19] end},
    {name = "Đảo Tím", key = "T", getTarget = function() return workspace.MapFolder.IslandEvil end},
    {name = "Đảo Tuyết Núi Lớn", key = "T", getTarget = function() return workspace.MapFolder.IslandSnowyMountains.Stone:GetChildren()[2] end}
}
local orderKeys = {"A", "B", "C", "D", "K", "N", "R", "S", "T"}

local NPC_Data = {
	["DailyQuest"] = {Icon = "📜", Count = 5, NPCs = {"C0", "Cooker", "Fisherman", "Gemologist", "Sam"}},
	["Information"] = {Icon = "ℹ️", Count = 1, NPCs = {"Bart Nospmis"}},
	["Quest"] = {Icon = "❓", Count = 7, NPCs = {"Bandits Leader", "Chill Billy", "Demon Hunter", "Explorer", "Fallen Captain", "Guard Captain", "Joe", "Marge Nospmis", "Old Beggar", "Rayleigh", "Traceur"}},
	["Secret"] = {Icon = "🔒", Count = 2, NPCs = {"Lord", "Strange Dealer"}},
	["Shop"] = {Icon = "💰", Count = 10, NPCs = {"Anna", "Better Drink Merchant", "Boat Merchant", "Dancer", "Drink Merchant", "Fred The Blacksmith", "Lucy", "Mad Scientist", "Sniper Merchant", "Sword Merchant"}}
}

-- ==========================================================
-- 🛠️ LOGIC CORES VÀ HÀM PHỤ TRỢ
-- ==========================================================
local function getHRP()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getPosition(obj)
    if not obj or not obj.Parent then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        return pp and pp.Position
    end
    return nil
end

local function getSnowSafetyPosition()
    local snowFolder = workspace:FindFirstChild("MapFolder") 
        and workspace.MapFolder:FindFirstChild("IslandSnowyMountains")
        and workspace.MapFolder.IslandSnowyMountains:FindFirstChild("Snow")
    if snowFolder then
        local children = snowFolder:GetChildren()
        local targetPart = children[46]
        if targetPart and targetPart:IsA("BasePart") then return targetPart.Position end
    end
    return nil
end

local function teleportTo(pos, anchorAfterTele)
    local hrp = getHRP()
    if hrp and pos then
        hrp.Anchored = true
        hrp.CFrame = CFrame_new(pos + Vector3_new(0, 3.5, 0))
        hrp.AssemblyLinearVelocity = Vector3_new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3_new(0,0,0)
        task_wait(0.05)
        if not anchorAfterTele then hrp.Anchored = false end
        return true
    end
    return false
end

local function checkHasJuice()
    local backpack = player:FindFirstChild("Backpack")
    local char = player.Character
    for i = 1, #juiceList do
        if backpack and backpack:FindFirstChild(juiceList[i]) then return true end
        if char and char:FindFirstChild(juiceList[i]) then return true end
    end
    return false
end

local function getSmartTargets()
    local safeList = {}
    local barrelsFolder = workspace:FindFirstChild("Barrels")
    if barrelsFolder then
        local crates = barrelsFolder:FindFirstChild("Crates")
        if crates then
            local children = crates:GetChildren()
            for i = 1, #children do
                local item = children[i]
                if item:FindFirstChildWhichIsA("ClickDetector", true) then table.insert(safeList, item) end
            end
        end
        local barrels = barrelsFolder:FindFirstChild("Barrels")
        if barrels then
            local children = barrels:GetChildren()
            for i = 1, #children do
                local item = children[i]
                if item:FindFirstChildWhichIsA("ClickDetector", true) then table.insert(safeList, item) end
            end
        end
    end
    return safeList
end

local function islandTeleport(targetFunc, islandName)
    local hrp = getHRP()
    if not hrp then return end
    local success, obj = pcall(targetFunc)
    if success and obj then
        local targetPos = getPosition(obj)
        if targetPos then
            hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 15, 0))
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end
end

local function getNextLoopTarget()
    local aliveFolder = workspace:FindFirstChild("Alive")
    if not aliveFolder then return nil end
    local currentList = MonsterGroups[currentSelectedGroup]
    if not currentList or #currentList == 0 then return nil end

    local attempts = 0
    while attempts < #currentList do
        if monsterIndex > #currentList then monsterIndex = 1 end
        local monsterName = currentList[monsterIndex]
        local monster = aliveFolder:FindFirstChild(monsterName)
        if monster and monster:FindFirstChild("HumanoidRootPart") then
            local humanoid = monster:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                monsterIndex = monsterIndex + 1
                return monster
            end
        end
        monsterIndex = monsterIndex + 1
        attempts = attempts + 1
    end
    return nil
end

local function TeleportToNPC(categoryName, npcName)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local categoryFolder = workspace:FindFirstChild("Ignore") and workspace.Ignore:FindFirstChild("NPCs") and workspace.Ignore.NPCs:FindFirstChild(categoryName)
	if not categoryFolder then return end
	local npc = categoryFolder:FindFirstChild(npcName)
	if npc then
		local targetPart = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("PrimaryPart") or npc:FindFirstChildOfClass("Part")
		if targetPart then char.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 0, -3) end
	end
end

local function executeSelectedSkillsSpam()
    for keyCode, enabled in pairs(_G.SpamSkillsState) do
        if enabled then
            task_spawn(function()
                VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
                task_wait(0.001)
                VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
            end)
        end
    end
end

local function equipSelectedFarmItem()
    if not _G.AutoEquipItem or _G.SelectedFarmItem == "" then return end
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    
    if not char:FindFirstChild(_G.SelectedFarmItem) then
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChild(_G.SelectedFarmItem)
            if tool and tool:IsA("Tool") then
                pcall(function() hum:EquipTool(tool) end)
            end
        end
    end
end

task_spawn(function()
    while true do
        if _G.AutoEquipItem and (_G.autoMonsterFarm or _G.autoBossFarm) then
            pcall(equipSelectedFarmItem)
        end
        task_wait(0.5)
    end
end)

-- ==========================================================
-- 🚀 FLY SYSTEM
-- ==========================================================
local flyRenderConnection = nil
local function stopFlyingMechanics()
    if flyRenderConnection then flyRenderConnection:Disconnect(); flyRenderConnection = nil end
    local hrp = getHRP()
    if hrp then
        local bv = hrp:FindFirstChild("FlyVelocity")
        if bv then bv:Destroy() end
        local bg = hrp:FindFirstChild("FlyGyro")
        if bg then bg:Destroy() end
    end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function startFlyingMechanics()
    stopFlyingMechanics()
    if not _G.isFlying then return end

    local char = player.Character
    local hrp = getHRP()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyGyro"
    bg.maxTorque = Vector3_new(9e9, 9e9, 9e9)
    bg.P = 9e4
    bg.cframe = hrp.CFrame
    bg.Parent = hrp

    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyVelocity"
    bv.velocity = Vector3_new(0, 0.1, 0)
    bv.maxForce = Vector3_new(9e9, 9e9, 9e9)
    bv.Parent = hrp

    hum.PlatformStand = true

    flyRenderConnection = RunService.RenderStepped:Connect(function()
        if not _G.isFlying or not player.Character or not hrp.Parent then
            stopFlyingMechanics()
            return
        end
        local currentCamCFrame = camera.CFrame
        bg.cframe = currentCamCFrame
        local direction = Vector3_new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + currentCamCFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - currentCamCFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - currentCamCFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + currentCamCFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3_new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction = direction - Vector3_new(0, 1, 0) end

        if direction.Magnitude > 0 then
            bv.velocity = direction.Unit * (_G.FlySpeed or 80)
        else
            bv.velocity = Vector3_new(0, 0, 0)
        end
    end)
end

-- ==========================================================
-- 👤 PLAYER CONTROL
-- ==========================================================
local killPlayerConnection = nil
local function stopKillPlayer()
    if killPlayerConnection then killPlayerConnection:Disconnect(); killPlayerConnection = nil end
    local hrp = getHRP()
    if hrp then hrp.Anchored = false end
end

local function startKillPlayerMechanics()
    stopKillPlayer()
    if not _G.autoKillPlayer or not selectedTargetPlayer then return end

    task_spawn(function()
        while _G.autoKillPlayer and selectedTargetPlayer do
            if player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
                if selectedTargetPlayer.Character and selectedTargetPlayer.Character:FindFirstChildOfClass("Humanoid") and selectedTargetPlayer.Character.Humanoid.Health > 0 then
                    executeSelectedSkillsSpam()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                    task_wait(0.001)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                end
            end
            task_wait(SPAM_KEY_DELAY)
        end
    end)

    killPlayerConnection = RunService.Heartbeat:Connect(function()
        if not _G.autoKillPlayer or not selectedTargetPlayer then stopKillPlayer() return end
        local hrp = getHRP()
        if not hrp or not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") or player.Character.Humanoid.Health <= 0 then return end

        if selectedTargetPlayer.Character and selectedTargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = selectedTargetPlayer.Character.HumanoidRootPart
            local targetHum = selectedTargetPlayer.Character:FindFirstChildOfClass("Humanoid")
            if targetHum and targetHum.Health > 0 then
                hrp.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3_new(0, 0, 0)
                hrp.CFrame = targetHRP.CFrame * CFrame_new(0, 0, 1)
                return
            end
        end
        _G.autoKillPlayer = false
        stopKillPlayer()
    end)
end

-- ==========================================================
-- 🔄 FARM QUÁI & BOSS MECHANICS
-- ==========================================================
local function stopMonsterFarm()
    if farmConnection then farmConnection:Disconnect(); farmConnection = nil end
    currentTarget = nil
    local hrp = getHRP()
    if hrp then hrp.Anchored = false end
end

local function startMonsterFarmMechanics()
    stopMonsterFarm()
    if not _G.autoMonsterFarm then return end

    task_spawn(function()
        while _G.autoMonsterFarm do
            if player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
                if not currentTarget or not currentTarget.Parent or not currentTarget:FindFirstChild("HumanoidRootPart") or (currentTarget:FindFirstChildOfClass("Humanoid") and currentTarget:FindFirstChildOfClass("Humanoid").Health <= 0) then
                    currentTarget = getNextLoopTarget()
                end
                
                if currentTarget then
                    if _G.AutoEquipItem then pcall(equipSelectedFarmItem) end
                    executeSelectedSkillsSpam()

                    if _G.FarmMode == "Spam C" then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                        task_wait(0.001)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                        task_wait(SPAM_KEY_DELAY)
                    elseif _G.FarmMode == "Normal" or _G.FarmMode == "Bring Monsters" then
                        local viewSize = camera.ViewportSize
                        VirtualInputManager:SendMouseButtonEvent(viewSize.X - 100, viewSize.Y - 100, 0, true, game, 0)
                        task_wait(0.02)
                        VirtualInputManager:SendMouseButtonEvent(viewSize.X - 100, viewSize.Y - 100, 0, false, game, 0)
                        task_wait(NORMAL_FARM_CLICK_DELAY)
                    end
                else
                    task_wait(0.1)
                end
            else
                task_wait(0.1)
            end
        end
    end)

    task_spawn(function()
        while _G.autoMonsterFarm do
            if (_G.FarmMode == "Spam C" or _G.FarmMode == "Bring Monsters") and currentTarget and currentTarget.Parent and player.Character then
                local viewSize = camera.ViewportSize
                VirtualInputManager:SendMouseButtonEvent(viewSize.X - 100, viewSize.Y - 100, 0, true, game, 0)
                task_wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(viewSize.X - 100, viewSize.Y - 100, 0, false, game, 0)
            end
            task_wait(MONSTER_CLICK_DELAY) 
        end
    end)

    farmConnection = RunService.Heartbeat:Connect(function()
        if not _G.autoMonsterFarm then return end
        local hrp = getHRP()
        if not hrp or not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") or player.Character.Humanoid.Health <= 0 then return end

        local aliveFolder = workspace:FindFirstChild("Alive")

        if currentTarget and currentTarget.Parent and currentTarget:FindFirstChild("HumanoidRootPart") then
            local targetHRP = currentTarget.HumanoidRootPart
            hrp.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3_new(0, 0, 0)
            
            if _G.FarmMode == "Normal" or _G.FarmMode == "Bring Monsters" then
                setCollisionGroup(currentTarget, "NpcsGroup")
                hrp.CFrame = CFrame_new((targetHRP.CFrame * CFrame_new(0, 0, 1.3)).Position, targetHRP.Position)
            else
                local targetHeight = _G.MonsterDistance or 25
                hrp.CFrame = CFrame_new(targetHRP.Position + Vector3_new(0, targetHeight, 0), targetHRP.Position)
            end

            if _G.FarmMode == "Bring Monsters" and aliveFolder then
                local playerPos = hrp.Position
                for _, m in ipairs(aliveFolder:GetChildren()) do
                    if m ~= currentTarget and m:FindFirstChild("HumanoidRootPart") then
                        local mHrp = m.HumanoidRootPart
                        local mHum = m:FindFirstChildOfClass("Humanoid")
                        if mHum and mHum.Health > 0 then
                            if (mHrp.Position - playerPos).Magnitude <= 50 then
                                setCollisionGroup(m, "NpcsGroup")
                                mHrp.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
                                mHrp.CFrame = hrp.CFrame * CFrame_new(0, 0, -1.2)
                            end
                        end
                    end
                end
            end
            return
        end
        hrp.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
    end)
end

local function stopBossFarm()
    if bossFarmConnection then bossFarmConnection:Disconnect(); bossFarmConnection = nil end
    currentBossTarget = nil
    local hrp = getHRP()
    if hrp then hrp.Anchored = false end
end

local function startBossFarmMechanics()
    stopBossFarm()
    if not _G.autoBossFarm then return end

    task_spawn(function()
        while _G.autoBossFarm do
            if player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
                if currentBossTarget and currentBossTarget.Parent and currentBossTarget:FindFirstChildOfClass("Humanoid") and currentBossTarget:FindFirstChildOfClass("Humanoid").Health > 0 then
                    if _G.AutoEquipItem then pcall(equipSelectedFarmItem) end
                    executeSelectedSkillsSpam()
                    
                    if _G.FarmMode == "Spam C" then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                        task_wait(0.001)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                        task_wait(SPAM_KEY_DELAY)
                    elseif _G.FarmMode == "Normal" or _G.FarmMode == "Bring Monsters" then
                        local viewSize = camera.ViewportSize
                        VirtualInputManager:SendMouseButtonEvent(viewSize.X - 100, viewSize.Y - 100, 0, true, game, 0)
                        task_wait(0.02)
                        VirtualInputManager:SendMouseButtonEvent(viewSize.X - 100, viewSize.Y - 100, 0, false, game, 0)
                        task_wait(NORMAL_FARM_CLICK_DELAY)
                    end
                else
                    task_wait(0.1)
                end
            else
                task_wait(0.1)
            end
        end
    end)

    task_spawn(function()
        while _G.autoBossFarm do
            if (_G.FarmMode == "Spam C" or _G.FarmMode == "Bring Monsters") and currentBossTarget and currentBossTarget.Parent and player.Character then
                local viewSize = camera.ViewportSize
                VirtualInputManager:SendMouseButtonEvent(viewSize.X - 100, viewSize.Y - 100, 0, true, game, 0)
                task_wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(viewSize.X - 100, viewSize.Y - 100, 0, false, game, 0)
            end
            task_wait(MONSTER_CLICK_DELAY) 
        end
    end)

    bossFarmConnection = RunService.Heartbeat:Connect(function()
        if not _G.autoBossFarm then return end
        local hrp = getHRP()
        if not hrp or not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") or player.Character.Humanoid.Health <= 0 then return end

        local aliveFolder = workspace:FindFirstChild("Alive")
        if not aliveFolder then hrp.AssemblyLinearVelocity = Vector3_new(0, 0, 0) return end

        if currentBossTarget and currentBossTarget.Parent and currentBossTarget:FindFirstChild("HumanoidRootPart") then
            local humanoid = currentBossTarget:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                hrp.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3_new(0, 0, 0)
                
                if _G.FarmMode == "Normal" or _G.FarmMode == "Bring Monsters" then
                    setCollisionGroup(currentBossTarget, "NpcsGroup")
                    local targetHRP = currentBossTarget.HumanoidRootPart
                    hrp.CFrame = CFrame_new((targetHRP.CFrame * CFrame_new(0, 0, 1.3)).Position, targetHRP.Position)
                else
                    local targetHeight = _G.BossDistances[currentBossTarget.Name] or 70
                    hrp.CFrame = CFrame_new(currentBossTarget.HumanoidRootPart.Position + Vector3_new(0, targetHeight, 0), currentBossTarget.HumanoidRootPart.Position)
                end

                if _G.FarmMode == "Bring Monsters" then
                    local playerPos = hrp.Position
                    for _, m in ipairs(aliveFolder:GetChildren()) do
                        if m ~= currentBossTarget and m:FindFirstChild("HumanoidRootPart") then
                            local mHrp = m.HumanoidRootPart
                            local mHum = m:FindFirstChildOfClass("Humanoid")
                            if mHum and mHum.Health > 0 then
                                if (mHrp.Position - playerPos).Magnitude <= 50 then
                                    setCollisionGroup(m, "NpcsGroup")
                                    mHrp.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
                                    mHrp.CFrame = hrp.CFrame * CFrame_new(0, 0, -1.2)
                                end
                            end
                        end
                    end
                end
                return
            end
        end

        currentBossTarget = nil
        for _, bName in ipairs(bossListOrder) do
            if _G.SelectedBosses[bName] then
                local boss = aliveFolder:FindFirstChild(bName)
                if boss and boss:FindFirstChild("HumanoidRootPart") then
                    local humanoid = boss:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        currentBossTarget = boss
                        break 
                    end
                end
            end
        end
        hrp.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
    end)
end

local function startFruitLoop()
    while _G.autoFruitRemote do
        for _, obj in ipairs(workspace:GetChildren()) do
            if not _G.autoFruitRemote then break end
            if string.sub(obj.Name, -5) == "Fruit" then
                local cd = obj:FindFirstChildWhichIsA("ClickDetector", true)
                if cd then pcall(fireclickdetector, cd) end
                for _, child in ipairs(obj:GetChildren()) do
                    local subCd = child:FindFirstChildWhichIsA("ClickDetector", true)
                    if subCd then pcall(fireclickdetector, subCd) end
                end
            end
        end
        task_wait(FRUIT_INTERVAL)
    end
end

local function startMixerLoop()
    while _G.autoFarm do
        task_wait(MIXER_INTERVAL)
        if not _G.autoFarm then break end
        pcall(function()
            local strangeTent = workspace:FindFirstChild("MapFolder") and workspace.MapFolder:FindFirstChild("StrangeTent") and workspace.MapFolder.StrangeTent.Model:FindFirstChild("JuicingBowl")
            if strangeTent then
                local mixer1 = strangeTent:FindFirstChild("Mixer1")
                local mixer2 = strangeTent:FindFirstChild("Mixer2")
                local cd1 = mixer1 and mixer1:FindFirstChildWhichIsA("ClickDetector")
                local cd2 = mixer2 and mixer2:FindFirstChildWhichIsA("ClickDetector")
                if cd1 then fireclickdetector(cd1) end
                task_wait(0.05)
                if cd2 then fireclickdetector(cd2) end
            end
        end)
    end
end

local function mainFarmEngine()
    while _G.autoFarm do
        if checkHasJuice() then
            local snowPos = getSnowSafetyPosition()
            if snowPos then
                teleportTo(snowPos, true)
                while _G.autoFarm and checkHasJuice() do
                    local backpack = player:FindFirstChild("Backpack")
                    local char = player.Character
                    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                    if backpack and humanoid then
                        local drankInThisTurn = false
                        for i = 1, #juiceList do
                            local name = juiceList[i]
                            local tool = backpack:FindFirstChild(name) or char:FindFirstChild(name)
                            if tool then
                                if tool.Parent == backpack then
                                    pcall(function() humanoid:EquipTool(tool) end)
                                    task_wait(0.1)
                                end
                                pcall(function() tool:Activate() end)
                                task_wait(0.2)
                                pcall(function() tool:Deactivate() end)
                                drankInThisTurn = true
                                break 
                            end
                        end
                        if not drankInThisTurn then task_wait(0.1) end
                    else
                        task_wait(0.5)
                    end
                    task_wait(0.1)
                end
                local hrp = getHRP()
                if hrp then hrp.Anchored = false end
            else
                task_wait(1)
            end
        else
            local targets = getSmartTargets()
            if #targets > 0 then
                for i = 1, #targets do
                    if not _G.autoFarm or checkHasJuice() then break end
                    local obj = targets[i]
                    if obj and obj.Parent then
                        local cd = obj:FindFirstChildWhichIsA("ClickDetector", true)
                        local pos = getPosition(obj)
                        if cd and pos then
                            teleportTo(pos, false) 
                            for clickCount = 1, 4 do
                                pcall(fireclickdetector, cd)
                                task_wait(0.02)
                            end
                            task_wait(CLICK_DELAY)
                        end
                    end
                end
                table.clear(targets)
                targets = nil
            else
                task_wait(0.5) 
            end
        end
        task_wait(0.05)
    end
end

local function startCompassLoop()
    while _G.autoCompass do
        local hrp = getHRP()
        if hrp then
            local targets = {}
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj.Name == "Compass" and obj:FindFirstChild("CompassNeedle") then
                    table.insert(targets, obj.CompassNeedle)
                end
            end
            if #targets > 0 then
                local originalCFrame = hrp.CFrame
                local originalVelocity = hrp.AssemblyLinearVelocity
                for i, needle in ipairs(targets) do
                    if not _G.autoCompass then break end
                    if needle and needle.Parent then
                        hrp.AssemblyLinearVelocity = Vector3_new(0, 0, 0)
                        if needle:IsA("BasePart") then hrp.CFrame = needle.CFrame else hrp.CFrame = needle:GetPivot() end
                        task_wait(0.2) 
                    end
                end
                if _G.autoCompass then
                    hrp.CFrame = originalCFrame
                    hrp.AssemblyLinearVelocity = originalVelocity
                end
            end
        end
        task_wait(COMPASS_INTERVAL)
    end
end

local function startAutoRespawnLoop()
    while _G.autoRespawn do
        pcall(function()
            local playerGui = player:FindFirstChild("PlayerGui")
            local loadGui = playerGui and playerGui:FindFirstChild("Load")
            local frame = loadGui and loadGui:FindFirstChild("Frame")
            local loadButton = frame and frame:FindFirstChild("Load")
            if loadButton then
                task_wait(0.1)
                local x = loadButton.AbsolutePosition.X + (loadButton.AbsoluteSize.X / 2)
                local y = loadButton.AbsolutePosition.Y + (loadButton.AbsoluteSize.Y / 2) + 58
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                task_wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            end
        end)
        task_wait(RESPAWN_INTERVAL)
    end
end

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
-- 🎨 KHỞI TẠO GIAO DIỆN HATSUNE MIKU STYLE HUB v13.0
-- ==========================================================
if CoreGui:FindFirstChild("MikuHubV13") then CoreGui.MikuHubV13:Destroy() end
if CoreGui:FindFirstChild("MikuHubV12") then CoreGui.MikuHubV12:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MikuHubV13"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 🔘 NÚT MINI TOGGLE MIKU (FIXED ICON V13.0)
local MiniBtn = Instance.new("ImageButton")
MiniBtn.Name = "MiniToggle"
MiniBtn.Parent = ScreenGui
MiniBtn.Position = UDim2.new(0, 15, 0, 15)
MiniBtn.Size = UDim2.new(0, 48, 0, 48)
MiniBtn.Image = MIKU_ICON_ID
MiniBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
MiniBtn.BackgroundTransparency = 0
MiniBtn.BackgroundColor3 = Color3.fromRGB(15, 30, 35)
MiniBtn.Active = true
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(1, 0)

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Parent = MiniBtn
MiniStroke.Thickness = 2.5
MiniStroke.Color = MIKU_COLOR
perfectDrag(MiniBtn, MiniBtn)

-- 🖼️ FRAME CHÍNH (MAIN FRAME)
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

-- Nền Miku (Fix Asset ID V13.0)
local BackgroundImage = Instance.new("ImageLabel")
BackgroundImage.Name = "MikuBackground"
BackgroundImage.Parent = MainFrame
BackgroundImage.Size = UDim2.new(1, 0, 1, 0)
BackgroundImage.Image = MIKU_BG_ID
BackgroundImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
BackgroundImage.ImageTransparency = 0.7
BackgroundImage.ScaleType = Enum.ScaleType.Crop
BackgroundImage.BackgroundTransparency = 1
BackgroundImage.ZIndex = 0

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Thickness = 2
MainStroke.Color = MIKU_COLOR

-- 🔝 THANH TOPBAR DRAG
local TopBar = Instance.new("Frame")
TopBar.Parent = MainFrame
TopBar.BackgroundTransparency = 0.2
TopBar.BackgroundColor3 = Color3.fromRGB(15, 30, 35)
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 2
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
perfectDrag(MainFrame, TopBar)

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "MIKU HUB v13.0"
Title.TextColor3 = MIKU_COLOR
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 2

-- ==========================================================
-- 📌 SIDEBAR TABS
-- ==========================================================
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
UIListLayout_SideTabs.FillDirection = Enum.FillDirection.Vertical
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

local BtnTabFarm = createVerticalTabButton("TabFarm", "⚔️ ĐẠO TẶC", 1)
local BtnTabMonster = createVerticalTabButton("TabMonster", "👹 QUÁI & BOSS", 2)
local BtnTabPlayer = createVerticalTabButton("TabPlayer", "👤 NGƯỜI CHƠI", 3) 
local BtnTabNPC = createVerticalTabButton("TabNPC", "📍 NPC TELE", 4)
local BtnTabIsland = createVerticalTabButton("TabIsland", "🗺️ BẢN ĐỒ ĐẢO", 5)

-- CONTAINER CONTENT AREA
local ContentFrame = Instance.new("Frame")
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 126, 0, 44)
ContentFrame.Size = UDim2.new(1, -134, 1, -52)
ContentFrame.ZIndex = 2

-- ==========================================================
-- 📲 SMART TOGGLE & SLIDER
-- ==========================================================
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

    local function setToggleState(state)
        isOn = state
        local targetPos = isOn and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        local targetColor = isOn and MIKU_COLOR or Color3.fromRGB(40, 50, 55)
        local strokeColor = isOn and MIKU_COLOR or Color3.fromRGB(35, 65, 70)

        TweenService:Create(Thumb, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
        TweenService:Create(ToggleTrack, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(ContainerStroke, TweenInfo.new(0.2), {Color = strokeColor}):Play()

        callback(isOn)
    end

    ToggleTrack.MouseButton1Click:Connect(function()
        setToggleState(not isOn)
    end)

    return SwitchContainer, setToggleState
end

local function createDistanceSlider(parent, labelText, startVal, maxVal, callback)
    local maxLimit = maxVal or 300
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, 0, 0, 30)
    SliderFrame.BackgroundTransparency = 1
    SliderFrame.Parent = parent
    SliderFrame.ZIndex = 2

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 110, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamSemibold
    Label.Text = labelText
    Label.TextColor3 = Color3.fromRGB(180, 220, 225)
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 2
    Label.Parent = SliderFrame

    local SliderBar = Instance.new("Frame")
    SliderBar.Position = UDim2.new(0, 115, 0, 12)
    SliderBar.Size = UDim2.new(1, -165, 0, 6)
    SliderBar.BackgroundColor3 = Color3.fromRGB(25, 50, 55)
    SliderBar.BorderSizePixel = 0
    SliderBar.ZIndex = 2
    SliderBar.Parent = SliderFrame
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((startVal - 1) / (maxLimit - 1), 0, 1, 0)
    Fill.BackgroundColor3 = MIKU_COLOR
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 2
    Fill.Parent = SliderBar
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Trigger = Instance.new("TextButton")
    Trigger.Size = UDim2.new(0, 14, 0, 14)
    Trigger.AnchorPoint = Vector2.new(0.5, 0.5)
    Trigger.Position = UDim2.new((startVal - 1) / (maxLimit - 1), 0, 0.5, 0)
    Trigger.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Trigger.Text = ""
    Trigger.ZIndex = 3
    Trigger.Parent = SliderBar
    Instance.new("UICorner", Trigger).CornerRadius = UDim.new(1, 0)

    local Box = Instance.new("TextBox")
    Box.Position = UDim2.new(1, -45, 0, 3)
    Box.Size = UDim2.new(0, 42, 0, 22)
    Box.BackgroundColor3 = Color3.fromRGB(15, 30, 35)
    Box.Font = Enum.Font.GothamBold
    Box.Text = tostring(startVal)
    Box.TextColor3 = MIKU_COLOR
    Box.TextSize = 10
    Box.ZIndex = 2
    Box.Parent = SliderFrame
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
    local BoxStroke = Instance.new("UIStroke", Box)
    BoxStroke.Color = Color3.fromRGB(40, 80, 85)

    local function updateValue(val)
        val = math.clamp(math.round(val), 1, maxLimit)
        Box.Text = tostring(val)
        local ratio = (val - 1) / (maxLimit - 1)
        Trigger.Position = UDim2.new(ratio, 0, 0.5, 0)
        Fill.Size = UDim2.new(ratio, 0, 1, 0)
        callback(val)
    end

    local activeDrag = false
    Trigger.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then activeDrag = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then activeDrag = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if activeDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relativeX = input.Position.X - SliderBar.AbsolutePosition.X
            local ratio = math.clamp(relativeX / SliderBar.AbsoluteSize.X, 0, 1)
            updateValue(1 + (ratio * (maxLimit - 1)))
        end
    end)
    Box.FocusLost:Connect(function()
        local num = tonumber(Box.Text)
        if num then updateValue(num) else Box.Text = tostring(startVal) end
    end)
end

-- ==================== TRANG 1: FARM ĐẠO TẶC ====================
local PageFarm = Instance.new("ScrollingFrame")
PageFarm.Parent = ContentFrame
PageFarm.BackgroundTransparency = 1
PageFarm.Size = UDim2.new(1, 0, 1, 0)
PageFarm.ScrollBarThickness = 2
PageFarm.BorderSizePixel = 0
PageFarm.ZIndex = 2

local UIListLayout_Farm = Instance.new("UIListLayout")
UIListLayout_Farm.Parent = PageFarm
UIListLayout_Farm.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Farm.Padding = UDim.new(0, 8)

UIListLayout_Farm:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PageFarm.CanvasSize = UDim2.new(0, 0, 0, UIListLayout_Farm.AbsoluteContentSize.Y + 10)
end)

createPhoneToggle(PageFarm, "⚙️ Tự Động Gom Thùng & Mix Nước", _G.autoFarm, function(state)
    _G.autoFarm = state
    if _G.autoFarm then
        task_spawn(mainFarmEngine)
        task_spawn(startMixerLoop)
    else
        local hrp = getHRP()
        if hrp then hrp.Anchored = false end
    end
end)

createPhoneToggle(PageFarm, "🍓 Tự Động Nhặt Trái Ác Quỷ", _G.autoFruitRemote, function(state)
    _G.autoFruitRemote = state
    if _G.autoFruitRemote then task_spawn(startFruitLoop) end
end)

createPhoneToggle(PageFarm, "🧭 Tự Động Gom La Bàn Siêu Tốc", _G.autoCompass, function(state)
    _G.autoCompass = state
    if _G.autoCompass then task_spawn(startCompassLoop) end
end)

createPhoneToggle(PageFarm, "♻️ Tự Động Hồi Sinh (Mỗi 6 Giây)", _G.autoRespawn, function(state)
    _G.autoRespawn = state
    if _G.autoRespawn then task_spawn(startAutoRespawnLoop) end
end)

createPhoneToggle(PageFarm, "🚀 Kích Hoạt Tính Năng Fly (Bay)", _G.isFlying, function(state)
    _G.isFlying = state
    if _G.isFlying then startFlyingMechanics() else stopFlyingMechanics() end
end)

createDistanceSlider(PageFarm, "⚡ Tốc Độ Bay Max", _G.FlySpeed, 350, function(val) _G.FlySpeed = val end)

-- ==================== TRANG 2: FARM QUÁI & BOSS (FIX BỐ CỤC CHỐNG ĐÈ) ====================
local PageMonster = Instance.new("ScrollingFrame")
PageMonster.Parent = ContentFrame
PageMonster.BackgroundTransparency = 1
PageMonster.Size = UDim2.new(1, 0, 1, 0)
PageMonster.ScrollBarThickness = 3
PageMonster.BorderSizePixel = 0
PageMonster.Visible = false
PageMonster.ZIndex = 2

local UIListLayout_Monster = Instance.new("UIListLayout")
UIListLayout_Monster.Parent = PageMonster
UIListLayout_Monster.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Monster.Padding = UDim.new(0, 10)

UIListLayout_Monster:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PageMonster.CanvasSize = UDim2.new(0, 0, 0, UIListLayout_Monster.AbsoluteContentSize.Y + 30)
end)

local setMonsterFarmState, setBossFarmState

_, setMonsterFarmState = createPhoneToggle(PageMonster, "⚔️ Auto Farm Quái", _G.autoMonsterFarm, function(state)
    _G.autoMonsterFarm = state
    if _G.autoMonsterFarm then
        if _G.autoBossFarm then
            _G.autoBossFarm = false
            if setBossFarmState then setBossFarmState(false) end
            stopBossFarm()
        end
        startMonsterFarmMechanics()
    else
        stopMonsterFarm()
    end
end)

-- ⚡ ACCORDION CHIA QUÁI THEO LEVEL (KHÔI PHỤC VÀ TỐI ƯU CÂN BẰNG)
local MonsterListAccordionFrame = Instance.new("Frame")
MonsterListAccordionFrame.Name = "MonsterAccordion"
MonsterListAccordionFrame.Parent = PageMonster
MonsterListAccordionFrame.Size = UDim2.new(1, 0, 0, 30)
MonsterListAccordionFrame.BackgroundTransparency = 1
MonsterListAccordionFrame.ClipsDescendants = true

local AccordionLayout = Instance.new("UIListLayout")
AccordionLayout.Parent = MonsterListAccordionFrame
AccordionLayout.SortOrder = Enum.SortOrder.LayoutOrder
AccordionLayout.Padding = UDim.new(0, 6)

local AccordionHeader = Instance.new("TextButton")
AccordionHeader.Parent = MonsterListAccordionFrame
AccordionHeader.Size = UDim2.new(1, 0, 0, 30)
AccordionHeader.BackgroundColor3 = Color3.fromRGB(20, 35, 40)
AccordionHeader.Font = Enum.Font.GothamBold
AccordionHeader.Text = "  ►  CHIA QUÁI THEO LEVEL (" .. currentSelectedGroup .. ")"
AccordionHeader.TextColor3 = Color3.fromRGB(220, 240, 240)
AccordionHeader.TextSize = 10
AccordionHeader.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", AccordionHeader).CornerRadius = UDim.new(0, 5)
local AccordionStroke = Instance.new("UIStroke", AccordionHeader)
AccordionStroke.Color = Color3.fromRGB(45, 75, 80)

local LevelGridContainer = Instance.new("Frame")
LevelGridContainer.Parent = MonsterListAccordionFrame
LevelGridContainer.BackgroundTransparency = 1
LevelGridContainer.Size = UDim2.new(1, 0, 0, 0)
LevelGridContainer.AutomaticSize = Enum.AutomaticSize.Y
LevelGridContainer.Visible = false

local GridMonsterLayout = Instance.new("UIGridLayout")
GridMonsterLayout.Parent = LevelGridContainer
GridMonsterLayout.CellSize = UDim2.new(0, 172, 0, 26)
GridMonsterLayout.CellPadding = UDim2.new(0, 6, 0, 6)

local levelButtons = {"Lv1 - Lv200", "Lv200 - Lv300", "Lv300 - Lv400", "Farm Toàn Bộ"}
local levelButtonsCache = {}

for _, groupName in ipairs(levelButtons) do
    local btn = Instance.new("TextButton")
    btn.Parent = LevelGridContainer
    btn.BackgroundColor3 = (groupName == currentSelectedGroup) and Color3.fromRGB(25, 80, 90) or Color3.fromRGB(20, 35, 40)
    btn.Font = Enum.Font.GothamBold
    btn.Text = groupName
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local s = Instance.new("UIStroke")
    s.Parent = btn
    s.Color = (groupName == currentSelectedGroup) and MIKU_COLOR or Color3.fromRGB(45, 65, 70)
    
    levelButtonsCache[groupName] = {Button = btn, Stroke = s}

    btn.MouseButton1Click:Connect(function()
        currentSelectedGroup = groupName
        monsterIndex = 1
        AccordionHeader.Text = "  ▼  CHIA QUÁI THEO LEVEL (" .. currentSelectedGroup .. ")"
        for name, cache in pairs(levelButtonsCache) do
            cache.Button.BackgroundColor3 = Color3.fromRGB(20, 35, 40)
            cache.Stroke.Color = Color3.fromRGB(45, 65, 70)
        end
        btn.BackgroundColor3 = Color3.fromRGB(25, 80, 90)
        s.Color = MIKU_COLOR
        if _G.autoMonsterFarm then startMonsterFarmMechanics() end
    end)
end

local isAccordionOpen = false
AccordionHeader.MouseButton1Click:Connect(function()
    isAccordionOpen = not isAccordionOpen
    if isAccordionOpen then
        AccordionHeader.Text = "  ▼  CHIA QUÁI THEO LEVEL (" .. currentSelectedGroup .. ")"
        AccordionHeader.TextColor3 = MIKU_COLOR
        AccordionStroke.Color = MIKU_COLOR
        LevelGridContainer.Visible = true
        MonsterListAccordionFrame.Size = UDim2.new(1, 0, 0, 36 + GridMonsterLayout.AbsoluteContentSize.Y)
    else
        AccordionHeader.Text = "  ►  CHIA QUÁI THEO LEVEL (" .. currentSelectedGroup .. ")"
        AccordionHeader.TextColor3 = Color3.fromRGB(220, 240, 240)
        AccordionStroke.Color = Color3.fromRGB(45, 75, 80)
        LevelGridContainer.Visible = false
        MonsterListAccordionFrame.Size = UDim2.new(1, 0, 0, 30)
    end
end)

-- ⚡ CẤU HÌNH CÁC NÚT SPAM SKILL
local SkillSectionTitle = Instance.new("TextLabel")
SkillSectionTitle.Parent = PageMonster
SkillSectionTitle.BackgroundTransparency = 1
SkillSectionTitle.Size = UDim2.new(1, 0, 0, 18)
SkillSectionTitle.Font = Enum.Font.GothamBold
SkillSectionTitle.Text = "⚡ TÙY CHỌN SPAM SKILL (1MS):"
SkillSectionTitle.TextColor3 = MIKU_COLOR
SkillSectionTitle.TextSize = 10.5
SkillSectionTitle.TextXAlignment = Enum.TextXAlignment.Left

local SkillsGridContainer = Instance.new("Frame")
SkillsGridContainer.Parent = PageMonster
SkillsGridContainer.BackgroundTransparency = 1
SkillsGridContainer.Size = UDim2.new(1, 0, 0, 0)
SkillsGridContainer.AutomaticSize = Enum.AutomaticSize.Y

local GridSkillLayout = Instance.new("UIGridLayout")
GridSkillLayout.Parent = SkillsGridContainer
GridSkillLayout.CellSize = UDim2.new(0.48, -2, 0, 34)
GridSkillLayout.CellPadding = UDim2.new(0, 6, 0, 6)

local skillKeysList = {
    {Name = "Spam Skill [Z]", Key = Enum.KeyCode.Z},
    {Name = "Spam Skill [X]", Key = Enum.KeyCode.X},
    {Name = "Spam Skill [C]", Key = Enum.KeyCode.C},
    {Name = "Spam Skill [V]", Key = Enum.KeyCode.V},
    {Name = "Spam Skill [B]", Key = Enum.KeyCode.B},
    {Name = "Spam Skill [N]", Key = Enum.KeyCode.N},
    {Name = "Spam Skill [F]", Key = Enum.KeyCode.F},
    {Name = "Spam Skill [G]", Key = Enum.KeyCode.G},
    {Name = "Spam Skill [H]", Key = Enum.KeyCode.H},
    {Name = "Spam Skill [J]", Key = Enum.KeyCode.J},
    {Name = "Spam Skill [K]", Key = Enum.KeyCode.K},
    {Name = "Spam Skill [L]", Key = Enum.KeyCode.L}
}

for _, item in ipairs(skillKeysList) do
    createPhoneToggle(SkillsGridContainer, item.Name, _G.SpamSkillsState[item.Key], function(state)
        _G.SpamSkillsState[item.Key] = state
    end)
end

-- 🎒 CẤU HÌNH CHỌN WEAPON VÀ REFRESH WEAPON
local ItemSectionTitle = Instance.new("TextLabel")
ItemSectionTitle.Parent = PageMonster
ItemSectionTitle.BackgroundTransparency = 1
ItemSectionTitle.Size = UDim2.new(1, 0, 0, 18)
ItemSectionTitle.Font = Enum.Font.GothamBold
ItemSectionTitle.Text = "🎒 CẤU HÌNH VẬT PHẨM FARM:"
ItemSectionTitle.TextColor3 = MIKU_COLOR
ItemSectionTitle.TextSize = 10.5
ItemSectionTitle.TextXAlignment = Enum.TextXAlignment.Left

local ItemControlContainer = Instance.new("Frame")
ItemControlContainer.Parent = PageMonster
ItemControlContainer.BackgroundTransparency = 1
ItemControlContainer.Size = UDim2.new(1, 0, 0, 32)

local BtnRefreshItems = Instance.new("TextButton")
BtnRefreshItems.Parent = ItemControlContainer
BtnRefreshItems.BackgroundColor3 = Color3.fromRGB(24, 46, 50)
BtnRefreshItems.Size = UDim2.new(0, 110, 1, 0)
BtnRefreshItems.Font = Enum.Font.GothamBold
BtnRefreshItems.Text = "🔄 Refresh Items"
BtnRefreshItems.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnRefreshItems.TextSize = 10
Instance.new("UICorner", BtnRefreshItems).CornerRadius = UDim.new(0, 5)
local StrokeRefresh = Instance.new("UIStroke", BtnRefreshItems)
StrokeRefresh.Color = Color3.fromRGB(45, 90, 95)

local BtnToggleAutoEquip = Instance.new("TextButton")
BtnToggleAutoEquip.Parent = ItemControlContainer
BtnToggleAutoEquip.Position = UDim2.new(0, 118, 0, 0)
BtnToggleAutoEquip.Size = UDim2.new(1, -118, 1, 0)
BtnToggleAutoEquip.BackgroundColor3 = Color3.fromRGB(20, 35, 40)
BtnToggleAutoEquip.Font = Enum.Font.GothamBold
BtnToggleAutoEquip.Text = "Auto Equip: OFF"
BtnToggleAutoEquip.TextColor3 = Color3.fromRGB(240, 110, 110)
BtnToggleAutoEquip.TextSize = 10
Instance.new("UICorner", BtnToggleAutoEquip).CornerRadius = UDim.new(0, 5)
local StrokeAutoEquip = Instance.new("UIStroke", BtnToggleAutoEquip)
StrokeAutoEquip.Color = Color3.fromRGB(150, 60, 60)

local CurrentItemLabel = Instance.new("TextLabel")
CurrentItemLabel.Parent = PageMonster
CurrentItemLabel.BackgroundTransparency = 1
CurrentItemLabel.Size = UDim2.new(1, 0, 0, 16)
CurrentItemLabel.Font = Enum.Font.GothamSemibold
CurrentItemLabel.Text = "Đang chọn: Chưa có vật phẩm"
CurrentItemLabel.TextColor3 = Color3.fromRGB(160, 190, 195)
CurrentItemLabel.TextSize = 9.5
CurrentItemLabel.TextXAlignment = Enum.TextXAlignment.Left

local ItemScrollList = Instance.new("Frame")
ItemScrollList.Parent = PageMonster
ItemScrollList.BackgroundColor3 = Color3.fromRGB(15, 26, 30)
ItemScrollList.Size = UDim2.new(1, 0, 0, 65)
Instance.new("UICorner", ItemScrollList).CornerRadius = UDim.new(0, 5)
local StrokeScrollList = Instance.new("UIStroke", ItemScrollList)
StrokeScrollList.Color = Color3.fromRGB(35, 65, 70)

local ItemInnerScroll = Instance.new("ScrollingFrame")
ItemInnerScroll.Parent = ItemScrollList
ItemInnerScroll.BackgroundTransparency = 1
ItemInnerScroll.Position = UDim2.new(0, 5, 0, 5)
ItemInnerScroll.Size = UDim2.new(1, -10, 1, -10)
ItemInnerScroll.ScrollBarThickness = 3
ItemInnerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local GridItemLayout = Instance.new("UIGridLayout")
GridItemLayout.Parent = ItemInnerScroll
GridItemLayout.CellSize = UDim2.new(0, 110, 0, 24)
GridItemLayout.CellPadding = UDim2.new(0, 5, 0, 5)

local function updateInventoryUI()
    for _, child in ipairs(ItemInnerScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local itemsFound = {}
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, obj in ipairs(backpack:GetChildren()) do
            if obj:IsA("Tool") and not table.find(juiceList, obj.Name) and not itemsFound[obj.Name] then
                itemsFound[obj.Name] = true
            end
        end
    end
    local char = player.Character
    if char then
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") and not table.find(juiceList, obj.Name) and not itemsFound[obj.Name] then
                itemsFound[obj.Name] = true
            end
        end
    end

    for itemName, _ in pairs(itemsFound) do
        local btn = Instance.new("TextButton")
        btn.Parent = ItemInnerScroll
        btn.BackgroundColor3 = (_G.SelectedFarmItem == itemName) and Color3.fromRGB(25, 95, 90) or Color3.fromRGB(20, 32, 36)
        btn.Font = Enum.Font.GothamSemibold
        btn.Text = itemName
        btn.TextColor3 = Color3.fromRGB(235, 250, 250)
        btn.TextSize = 9.5
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        local s = Instance.new("UIStroke", btn)
        s.Color = (_G.SelectedFarmItem == itemName) and MIKU_COLOR or Color3.fromRGB(40, 65, 70)
        
        btn.MouseButton1Click:Connect(function()
            _G.SelectedFarmItem = itemName
            CurrentItemLabel.Text = "Đang chọn: " .. itemName
            updateInventoryUI()
            if _G.AutoEquipItem then pcall(equipSelectedFarmItem) end
        end)
    end
    ItemInnerScroll.CanvasSize = UDim2.new(0, 0, 0, GridItemLayout.AbsoluteContentSize.Y + 5)
end

BtnRefreshItems.MouseButton1Click:Connect(updateInventoryUI)
BtnToggleAutoEquip.MouseButton1Click:Connect(function()
    _G.AutoEquipItem = not _G.AutoEquipItem
    if _G.AutoEquipItem then
        BtnToggleAutoEquip.Text = "Auto Equip: ON"
        BtnToggleAutoEquip.BackgroundColor3 = Color3.fromRGB(35, 120, 110)
        BtnToggleAutoEquip.TextColor3 = Color3.fromRGB(255, 255, 255)
        StrokeAutoEquip.Color = MIKU_COLOR
        pcall(equipSelectedFarmItem)
    else
        BtnToggleAutoEquip.Text = "Auto Equip: OFF"
        BtnToggleAutoEquip.BackgroundColor3 = Color3.fromRGB(20, 35, 40)
        BtnToggleAutoEquip.TextColor3 = Color3.fromRGB(240, 110, 110)
        StrokeAutoEquip.Color = Color3.fromRGB(150, 60, 60)
    end
end)
updateInventoryUI()

local ModeTitle = Instance.new("TextLabel")
ModeTitle.Parent = PageMonster
ModeTitle.BackgroundTransparency = 1
ModeTitle.Size = UDim2.new(1, 0, 0, 16)
ModeTitle.Font = Enum.Font.GothamBold
ModeTitle.Text = "⚡ CHỌN CÁCH FARM:"
ModeTitle.TextColor3 = MIKU_COLOR
ModeTitle.TextSize = 10.5
ModeTitle.TextXAlignment = Enum.TextXAlignment.Left

local ModeGridContainer = Instance.new("Frame")
ModeGridContainer.Parent = PageMonster
ModeGridContainer.BackgroundTransparency = 1
ModeGridContainer.Size = UDim2.new(1, 0, 0, 30)

local GridModeLayout = Instance.new("UIGridLayout")
GridModeLayout.Parent = ModeGridContainer
GridModeLayout.CellSize = UDim2.new(0, 112, 0, 28)
GridModeLayout.CellPadding = UDim2.new(0, 6, 0, 0)

local modeButtons = {"Spam C", "Normal", "Bring Monsters"}
local modeButtonsCache = {}

for _, modeName in ipairs(modeButtons) do
    local btn = Instance.new("TextButton")
    btn.Parent = ModeGridContainer
    btn.BackgroundColor3 = (modeName == _G.FarmMode) and Color3.fromRGB(30, 100, 95) or Color3.fromRGB(20, 35, 40)
    btn.Font = Enum.Font.GothamBold
    if modeName == "Normal" then
        btn.Text = "Farm Thường"
    elseif modeName == "Bring Monsters" then
        btn.Text = "🔮 Bring Quái"
    else
        btn.Text = "Spam Phím [C]"
    end
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 9.5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    
    local s = Instance.new("UIStroke")
    s.Parent = btn
    s.Thickness = 1
    s.Color = (modeName == _G.FarmMode) and MIKU_COLOR or Color3.fromRGB(45, 65, 70)
    
    modeButtonsCache[modeName] = {Button = btn, Stroke = s}

    btn.MouseButton1Click:Connect(function()
        _G.FarmMode = modeName
        for name, cache in pairs(modeButtonsCache) do
            cache.Button.BackgroundColor3 = Color3.fromRGB(20, 35, 40)
            cache.Stroke.Color = Color3.fromRGB(45, 65, 70)
        end
        btn.BackgroundColor3 = Color3.fromRGB(30, 100, 95)
        s.Color = MIKU_COLOR
        if _G.autoMonsterFarm then startMonsterFarmMechanics() end
        if _G.autoBossFarm then startBossFarmMechanics() end
    end)
end

createDistanceSlider(PageMonster, "📏 K.Cách Quái", _G.MonsterDistance, 300, function(val) _G.MonsterDistance = val end)

local Divider = Instance.new("Frame")
Divider.Parent = PageMonster
Divider.BackgroundColor3 = Color3.fromRGB(45, 80, 85)
Divider.Size = UDim2.new(1, 0, 0, 1)

-- 💀 MỤC BOSS GIỮ NGUYÊN BẢN CHUẨN
_, setBossFarmState = createPhoneToggle(PageMonster, "💀 Auto Kill Boss (Xoay Tua)", _G.autoBossFarm, function(state)
    _G.autoBossFarm = state
    if _G.autoBossFarm then
        if _G.autoMonsterFarm then
            _G.autoMonsterFarm = false
            if setMonsterFarmState then setMonsterFarmState(false) end
            stopMonsterFarm()
        end
        startBossFarmMechanics()
    else
        stopBossFarm()
    end
end)

local BossGridContainer = Instance.new("Frame")
BossGridContainer.Parent = PageMonster
BossGridContainer.BackgroundTransparency = 1
BossGridContainer.Size = UDim2.new(1, 0, 0, 60)

local GridBossLayout = Instance.new("UIGridLayout")
GridBossLayout.Parent = BossGridContainer
GridBossLayout.CellSize = UDim2.new(0, 172, 0, 26)
GridBossLayout.CellPadding = UDim2.new(0, 6, 0, 6)

for _, bName in ipairs(bossListOrder) do
    local btn = Instance.new("TextButton")
    btn.Parent = BossGridContainer
    btn.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
    btn.Font = Enum.Font.GothamBold
    btn.Text = "⬜ " .. bName  
    btn.TextColor3 = Color3.fromRGB(220, 235, 235)
    btn.TextSize = 9.5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local s = Instance.new("UIStroke")
    s.Parent = btn
    s.Color = Color3.fromRGB(50, 60, 65)

    btn.MouseButton1Click:Connect(function()
        _G.SelectedBosses[bName] = not _G.SelectedBosses[bName]
        if _G.SelectedBosses[bName] then
            btn.Text = "✅ " .. bName 
            btn.BackgroundColor3 = Color3.fromRGB(110, 40, 40)
            s.Color = Color3.fromRGB(240, 110, 110)
        else
            btn.Text = "⬜ " .. bName 
            btn.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
            s.Color = Color3.fromRGB(50, 60, 65)
        end
        if _G.autoBossFarm then startBossFarmMechanics() end
    end)
end

-- ==================== TRANG 3: TAB NGƯỜI CHƠI ====================
local PagePlayer = Instance.new("ScrollingFrame")
PagePlayer.Parent = ContentFrame
PagePlayer.BackgroundTransparency = 1
PagePlayer.Size = UDim2.new(1, 0, 1, 0)
PagePlayer.ScrollBarThickness = 3
PagePlayer.BorderSizePixel = 0
PagePlayer.Visible = false
PagePlayer.ZIndex = 2

local UIListLayout_Player = Instance.new("UIListLayout")
UIListLayout_Player.Parent = PagePlayer
UIListLayout_Player.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Player.Padding = UDim.new(0, 8)

UIListLayout_Player:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PagePlayer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout_Player.AbsoluteContentSize.Y + 20)
end)

local BtnTeleportPlayer = Instance.new("TextButton")
BtnTeleportPlayer.Parent = PagePlayer
BtnTeleportPlayer.BackgroundColor3 = Color3.fromRGB(20, 42, 46)
BtnTeleportPlayer.Size = UDim2.new(1, 0, 0, 32)
BtnTeleportPlayer.Font = Enum.Font.GothamBold
BtnTeleportPlayer.Text = "⚡ Dịch Chuyển Đến Người Chơi Này"
BtnTeleportPlayer.TextColor3 = MIKU_COLOR
BtnTeleportPlayer.TextSize = 10.5
Instance.new("UICorner", BtnTeleportPlayer).CornerRadius = UDim.new(0, 6)
local StrokeTPPlr = Instance.new("UIStroke", BtnTeleportPlayer)
StrokeTPPlr.Color = Color3.fromRGB(40, 80, 85)

createPhoneToggle(PagePlayer, "👁️ Xem Trộm Góc Nhìn (Spectate)", spectatingPlayer, function(state)
    spectatingPlayer = state
    if spectatingPlayer and selectedTargetPlayer and selectedTargetPlayer.Character and selectedTargetPlayer.Character:FindFirstChildOfClass("Humanoid") then
        camera.CameraSubject = selectedTargetPlayer.Character:FindFirstChildOfClass("Humanoid")
    else
        spectatingPlayer = false
        if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
        end
    end
end)

createPhoneToggle(PagePlayer, "⚔️ Auto Săn Người Chơi (Kill)", _G.autoKillPlayer, function(state)
    _G.autoKillPlayer = state
    if _G.autoKillPlayer then
        if not selectedTargetPlayer then _G.autoKillPlayer = false; return end
        startKillPlayerMechanics()
    else
        stopKillPlayer()
    end
end)

local ListTitle = Instance.new("TextLabel")
ListTitle.Parent = PagePlayer
ListTitle.BackgroundTransparency = 1
ListTitle.Size = UDim2.new(1, 0, 0, 18)
ListTitle.Font = Enum.Font.GothamBold
ListTitle.Text = "📋 DANH SÁCH NGƯỜI CHƠI TRONG SERVER:"
ListTitle.TextColor3 = Color3.fromRGB(220, 240, 240)
ListTitle.TextSize = 10.5
ListTitle.TextXAlignment = Enum.TextXAlignment.Left

local PlayerListContainer = Instance.new("Frame")
PlayerListContainer.Parent = PagePlayer
PlayerListContainer.BackgroundTransparency = 1
PlayerListContainer.Size = UDim2.new(1, 0, 0, 0)
PlayerListContainer.AutomaticSize = Enum.AutomaticSize.Y

local GridPlayerLayout = Instance.new("UIGridLayout")
GridPlayerLayout.Parent = PlayerListContainer
GridPlayerLayout.CellSize = UDim2.new(0, 114, 0, 28)
GridPlayerLayout.CellPadding = UDim2.new(0, 5, 0, 5)

local playerButtonsCache = {}
local function updatePlayerListUI()
    for _, child in ipairs(PlayerListContainer:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    table.clear(playerButtonsCache)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local btn = Instance.new("TextButton")
            btn.Parent = PlayerListContainer
            btn.BackgroundColor3 = (selectedTargetPlayer == p) and Color3.fromRGB(25, 85, 80) or Color3.fromRGB(18, 30, 34)
            btn.Font = Enum.Font.GothamSemibold
            btn.Text = p.DisplayName or p.Name
            btn.TextColor3 = Color3.fromRGB(230, 245, 245)
            btn.TextSize = 9.5
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            local s = Instance.new("UIStroke", btn)
            s.Color = (selectedTargetPlayer == p) and MIKU_COLOR or Color3.fromRGB(40, 60, 65)

            playerButtonsCache[p] = {Button = btn, Stroke = s}

            btn.MouseButton1Click:Connect(function()
                selectedTargetPlayer = p
                for pl, cache in pairs(playerButtonsCache) do
                    cache.Button.BackgroundColor3 = Color3.fromRGB(18, 30, 34)
                    cache.Stroke.Color = Color3.fromRGB(40, 60, 65)
                end
                btn.BackgroundColor3 = Color3.fromRGB(25, 85, 80)
                s.Color = MIKU_COLOR
                
                if spectatingPlayer then camera.CameraSubject = p.Character:FindFirstChildOfClass("Humanoid") end
                if _G.autoKillPlayer then startKillPlayerMechanics() end
            end)
        end
    end
end

BtnTeleportPlayer.MouseButton1Click:Connect(function()
    if selectedTargetPlayer and selectedTargetPlayer.Character and selectedTargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = getHRP()
        if hrp then hrp.CFrame = selectedTargetPlayer.Character.HumanoidRootPart.CFrame * CFrame_new(0, 4, 0) end
    end
end)

Players.PlayerAdded:Connect(updatePlayerListUI)
Players.PlayerRemoving:Connect(updatePlayerListUI)
updatePlayerListUI()

-- ==================== TRANG 4: TAB NPC TELEPORT ====================
local PageNPC = Instance.new("ScrollingFrame")
PageNPC.Parent = ContentFrame
PageNPC.BackgroundTransparency = 1
PageNPC.Size = UDim2.new(1, 0, 1, 0)
PageNPC.ScrollBarThickness = 2
PageNPC.BorderSizePixel = 0
PageNPC.Visible = false
PageNPC.ZIndex = 2

local UIListLayout_NPC = Instance.new("UIListLayout")
UIListLayout_NPC.Parent = PageNPC
UIListLayout_NPC.SortOrder = Enum.SortOrder.Name
UIListLayout_NPC.Padding = UDim.new(0, 8)

UIListLayout_NPC:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PageNPC.CanvasSize = UDim2.new(0, 0, 0, UIListLayout_NPC.AbsoluteContentSize.Y + 15)
end)

for category, data in pairs(NPC_Data) do
	local npcs = data.NPCs
	local CategoryFrame = Instance.new("Frame")
	CategoryFrame.Name = category .. "_Container"
	CategoryFrame.Size = UDim2.new(1, 0, 0, 30)
	CategoryFrame.BackgroundTransparency = 1
	CategoryFrame.ClipsDescendants = true
	CategoryFrame.Parent = PageNPC
	
	local SubListLayout = Instance.new("UIListLayout")
	SubListLayout.Padding = UDim.new(0, 5)
	SubListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SubListLayout.Parent = CategoryFrame

	local CategoryButton = Instance.new("TextButton")
	CategoryButton.Size = UDim2.new(1, 0, 0, 30)
	CategoryButton.Text = "   " .. data.Icon .. "   [" .. category:upper() .. "]"
	CategoryButton.TextColor3 = Color3.fromRGB(170, 200, 205)
	CategoryButton.BackgroundColor3 = Color3.fromRGB(20, 35, 40)
	CategoryButton.Font = Enum.Font.GothamSemibold
	CategoryButton.TextSize = 10.5
	CategoryButton.TextXAlignment = Enum.TextXAlignment.Left
	CategoryButton.Parent = CategoryFrame
	Instance.new("UICorner", CategoryButton).CornerRadius = UDim.new(0, 5)
	local CatStroke = Instance.new("UIStroke", CategoryButton)
	CatStroke.Color = Color3.fromRGB(40, 70, 75)

	local SideInfo = Instance.new("TextLabel")
	SideInfo.Size = UDim2.new(0, 50, 1, 0)
	SideInfo.Position = UDim2.new(1, -60, 0, 0)
	SideInfo.Text = data.Count .. "   ❯"
	SideInfo.TextColor3 = Color3.fromRGB(120, 150, 155)
	SideInfo.Font = Enum.Font.Gotham
	SideInfo.TextSize = 10
	SideInfo.TextXAlignment = Enum.TextXAlignment.Right
	SideInfo.BackgroundTransparency = 1
	SideInfo.Parent = CategoryButton

	local GridFrame = Instance.new("Frame")
	GridFrame.Size = UDim2.new(1, 0, 0, 0)
	GridFrame.BackgroundTransparency = 1
	GridFrame.LayoutOrder = 1
	GridFrame.Visible = false
	GridFrame.Parent = CategoryFrame
	
	local UIGridLayout = Instance.new("UIGridLayout")
	UIGridLayout.CellSize = UDim2.new(0.5, -4, 0, 26)
	UIGridLayout.CellPadding = UDim2.new(0, 6, 0, 5)
	UIGridLayout.Parent = GridFrame

	for i, npcName in ipairs(npcs) do
		local NPCButton = Instance.new("TextButton")
		NPCButton.Text = "[" .. npcName .. "]"
		NPCButton.TextColor3 = Color3.fromRGB(140, 210, 205)
		NPCButton.BackgroundColor3 = Color3.fromRGB(15, 32, 36)
		NPCButton.Font = Enum.Font.Gotham
		NPCButton.TextSize = 9.5
		NPCButton.Parent = GridFrame
		Instance.new("UICorner", NPCButton).CornerRadius = UDim.new(0, 5)
		local NpcStroke = Instance.new("UIStroke", NPCButton)
		NpcStroke.Color = Color3.fromRGB(35, 65, 70)

		NPCButton.MouseEnter:Connect(function()
			TweenService:Create(NPCButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25, 80, 85), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		end)
		NPCButton.MouseLeave:Connect(function()
			TweenService:Create(NPCButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(15, 32, 36), TextColor3 = Color3.fromRGB(140, 210, 205)}):Play()
		end)
		NPCButton.MouseButton1Click:Connect(function() TeleportToNPC(category, npcName) end)
	end

	UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		GridFrame.Size = UDim2.new(1, 0, 0, UIGridLayout.AbsoluteContentSize.Y)
	end)

	local isOpen = false
	CategoryButton.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			SideInfo.Text = data.Count .. "   ▼"
			CategoryButton.TextColor3 = MIKU_COLOR
			CatStroke.Color = MIKU_COLOR
			GridFrame.Visible = true
			CategoryFrame.Size = UDim2.new(1, 0, 0, SubListLayout.AbsoluteContentSize.Y + 4)
		else
			SideInfo.Text = data.Count .. "   ❯"
			CategoryButton.TextColor3 = Color3.fromRGB(170, 200, 205)
			CatStroke.Color = Color3.fromRGB(40, 70, 75)
			GridFrame.Visible = false
			CategoryFrame.Size = UDim2.new(1, 0, 0, 30)
		end
	end)
end

-- ==================== TRANG 5: BẢN ĐỒ ĐẢO ====================
local PageIsland = Instance.new("ScrollingFrame")
PageIsland.Parent = ContentFrame
PageIsland.BackgroundTransparency = 1
PageIsland.Size = UDim2.new(1, 0, 1, 0)
PageIsland.ScrollBarThickness = 3
PageIsland.BorderSizePixel = 0
PageIsland.Visible = false
PageIsland.ZIndex = 2

local UIListLayout_Island = Instance.new("UIListLayout")
UIListLayout_Island.Parent = PageIsland
UIListLayout_Island.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Island.Padding = UDim.new(0, 8)

UIListLayout_Island:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PageIsland.CanvasSize = UDim2.new(0, 0, 0, UIListLayout_Island.AbsoluteContentSize.Y + 15)
end)

for _, key in ipairs(orderKeys) do
    local groupItems = {}
    for _, island in ipairs(islandData) do
        if island.key == key then table.insert(groupItems, island) end
    end
    
    if #groupItems > 0 then
        local GroupFrame = Instance.new("Frame")
        GroupFrame.Parent = PageIsland
        GroupFrame.BackgroundTransparency = 1
        GroupFrame.Size = UDim2.new(1, 0, 0, 0)
        GroupFrame.AutomaticSize = Enum.AutomaticSize.Y
        
        local GroupHeader = Instance.new("TextLabel")
        GroupHeader.Parent = GroupFrame
        GroupHeader.BackgroundTransparency = 1
        GroupHeader.Size = UDim2.new(1, 0, 0, 20)
        GroupHeader.Font = Enum.Font.GothamBold
        GroupHeader.Text = "📌 NHÓM CHỮ " .. key
        GroupHeader.TextColor3 = MIKU_COLOR
        GroupHeader.TextSize = 10.5
        GroupHeader.TextXAlignment = Enum.TextXAlignment.Left
        
        local GridContainer = Instance.new("Frame")
        GridContainer.Parent = GroupFrame
        GridContainer.BackgroundTransparency = 1
        GridContainer.Position = UDim2.new(0, 0, 0, 22)
        GridContainer.Size = UDim2.new(1, 0, 0, 0)
        GridContainer.AutomaticSize = Enum.AutomaticSize.Y
        
        local GridLayout = Instance.new("UIGridLayout")
        GridLayout.Parent = GridContainer
        GridLayout.CellSize = UDim2.new(0, 114, 0, 26)
        GridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
        
        for _, island in ipairs(groupItems) do
            local Btn = Instance.new("TextButton")
            Btn.Parent = GridContainer
            Btn.BackgroundColor3 = Color3.fromRGB(18, 34, 38)
            Btn.Font = Enum.Font.GothamSemibold
            Btn.Text = island.name
            Btn.TextColor3 = Color3.fromRGB(220, 240, 240)
            Btn.TextSize = 9.5
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)
            local btnStroke = Instance.new("UIStroke")
            btnStroke.Parent = Btn
            btnStroke.Color = Color3.fromRGB(40, 70, 75)
            
            Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 85, 90)}):Play() end)
            Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(18, 34, 38)}):Play() end)
            Btn.MouseButton1Click:Connect(function() islandTeleport(island.getTarget, island.name) end)
        end
    end
end

-- ==========================================================
-- 🔄 LOGIC CHUYỂN TAB
-- ==========================================================
local function switchTab(tabName)
    PageFarm.Visible = (tabName == "Farm")
    PageMonster.Visible = (tabName == "Monster")
    PagePlayer.Visible = (tabName == "Player")
    PageNPC.Visible = (tabName == "NPC")
    PageIsland.Visible = (tabName == "Island")
    
    if tabName == "Monster" then updateInventoryUI() end 

    local activeBg = Color3.fromRGB(30, 95, 90)
    local inactiveBg = Color3.fromRGB(18, 35, 40)
    local activeText = Color3.fromRGB(255, 255, 255)
    local inactiveText = Color3.fromRGB(140, 185, 190)

    local tabs = {
        Farm = BtnTabFarm,
        Monster = BtnTabMonster,
        Player = BtnTabPlayer,
        NPC = BtnTabNPC,
        Island = BtnTabIsland
    }

    for name, btn in pairs(tabs) do
        local isActive = (name == tabName)
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = isActive and activeBg or inactiveBg,
            TextColor3 = isActive and activeText or inactiveText
        }):Play()
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        if stroke then
            TweenService:Create(stroke, TweenInfo.new(0.2), {
                Color = isActive and MIKU_COLOR or Color3.fromRGB(35, 65, 70)
            }):Play()
        end
    end
end

switchTab("Farm")
BtnTabFarm.MouseButton1Click:Connect(function() switchTab("Farm") end)
BtnTabMonster.MouseButton1Click:Connect(function() switchTab("Monster") end)
BtnTabPlayer.MouseButton1Click:Connect(function() switchTab("Player") end)
BtnTabNPC.MouseButton1Click:Connect(function() switchTab("NPC") end)
BtnTabIsland.MouseButton1Click:Connect(function() switchTab("Island") end)

-- ==========================================================
-- 🛠️ ĐÓNG / MỞ MENU [P]
-- ==========================================================
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

player.CharacterAdded:Connect(function(newCharacter)
    local hrp = newCharacter:WaitForChild("HumanoidRootPart", 10)
    if hrp then
        task_wait(1.5)
        updateInventoryUI()
        if _G.autoMonsterFarm then startMonsterFarmMechanics() end
        if _G.autoBossFarm then startBossFarmMechanics() end
        if _G.autoFarm then task_spawn(mainFarmEngine) end
        if _G.isFlying then startFlyingMechanics() end
        if _G.autoKillPlayer then startKillPlayerMechanics() end
    end
end)

print("🎧 MIKU HUB v13.0 được kích hoạt thành công!")