local hbar = loadstring(game:HttpGet("https://pastefy.app/wQypL9XX/raw"))()

local repo = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ShowToggleFrameInKeybinds = true -- Make toggle keybinds work inside the keybinds UI (aka adds a toggle to the UI). Good for mobile users (Default value = true)
Library.ShowCustomCursor = true -- Toggles the Linoria cursor globaly (Default value = true)
Library.NotifySide = "Left" -- Changes the side of the notifications globaly (Left, Right) (Default value = Left)

local TweenService = game:GetService("TweenService")
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local function applyRGB(parent)
    for _, obj in pairs(parent:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            obj.TextColor3 = Color3.new(1, 1, 1)
            
            local grad = Instance.new("UIGradient")
            grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            })
            grad.Parent = obj
            
            TweenService:Create(grad, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
        end
    end
end

applyRGB(PlayerGui)


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Remote = ReplicatedStorage.Systems.ActionsSystem.Network.Attack

local attackIndex = 1
local conn = nil
local modified = {}

local function valid(c)
    return c and c:FindFirstChild("Humanoid") and c:FindFirstChild("HumanoidRootPart") and c.Humanoid.Health > 0
end

local function nearest()
    local my = LocalPlayer.Character
    if not valid(my) then return end
    local pos = my.HumanoidRootPart.Position
    local best, dist = nil, 32
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer and valid(p.Character) then
            local d = (p.Character.HumanoidRootPart.Position - pos).Magnitude
            if d < dist then
                best = p.Character
                dist = d
            end
        end
    end
    local entitiesFolder = workspace:FindFirstChild("Entities")
    if entitiesFolder then
        for _, e in pairs(entitiesFolder:GetChildren()) do
            if valid(e) then
                local d = (e.HumanoidRootPart.Position - pos).Magnitude
                if d < dist then
                    best = e
                    dist = d
                end
            end
        end
    end
    return best
end

local function hit(t)
    pcall(function() Remote:InvokeServer(t, attackIndex) end)
    attackIndex = attackIndex == 1 and 2 or 1
end

local function resetHitboxes()
    for hrp, oldSize in pairs(modified) do
        if hrp and hrp.Parent then
            hrp.Size = oldSize
            hrp.Transparency = 0
            hrp.CanCollide = true 
        end
    end
    modified = {}
end

local ReachRunning = false
local function startLoop()
    ReachRunning = true
    task.spawn(function()
        while ReachRunning do
            local currentSize = Options.ReachSlider and Options.ReachSlider.Value or 15
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = plr.Character.HumanoidRootPart
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        if not modified[hrp] then
                            modified[hrp] = hrp.Size
                        end
                        hrp.Size = Vector3.new(currentSize, currentSize, currentSize)
                        hrp.Transparency = 1
                        hrp.CanCollide = false
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

local function stopLoop()
    ReachRunning = false
    resetHitboxes()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP_ENABLED = false
local BOX_COLOR     = Color3.fromRGB(255, 255, 0)
local TRACER_COLOR  = Color3.fromRGB(255, 255, 0)
local TEXT_COLOR    = Color3.fromRGB(255, 255, 255)

local SHOW_BOX      = false
local SHOW_TRACERS  = false
local SHOW_NAME     = false
local SHOW_DISTANCE = false

local espObjects = {}

local function getModelName(model)
    local name = model.Name or "Unknown"
    if name:lower():find("drop") or name:find("Collector") then
        return "DROP"
    end
    return name
end

local function removeESPForModel(model)
    if espObjects[model] then
        for _, drawing in pairs(espObjects[model]) do
            if drawing and drawing.Remove then
                pcall(drawing.Remove, drawing)
            end
        end
        espObjects[model] = nil
    end
end

local function createESP(model)
    if espObjects[model] or model == LocalPlayer.Character then
        return
    end

    local root = model:FindFirstChild("HumanoidRootPart") 
              or model:FindFirstChild("HumanoidoidRootPart") 
              or model:FindFirstChild("TorsoPart")
              or model.PrimaryPart

    local head = model:FindFirstChild("HeadPart") 
              or model:FindFirstChild("HeadLayer") 
              or model:FindFirstChild("Head")

    if not root or not head then return end

    local bottom = root
    for _, name in {"LeftLeg", "RightLeg", "TorsoPart", "VisibleTorso"} do
        local p = model:FindFirstChild(name)
        if p then bottom = p break end
    end

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Transparency = 1
    box.Color = BOX_COLOR

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Transparency = 1
    tracer.Color = TRACER_COLOR

    local nameLabel = Drawing.new("Text")
    nameLabel.Size = 15
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.Color = TEXT_COLOR
    nameLabel.Font = Drawing.Fonts.UI

    espObjects[model] = {
        Box = box,
        Tracer = tracer,
        Name = nameLabel,
        Root = root,
        Head = head,
        Bottom = bottom,
        ModelName = getModelName(model)
    }

    -- Cleanup when model is destroyed/removed
    local ancestryConn
    ancestryConn = model.AncestryChanged:Connect(function(_, newParent)
        if not newParent then
            removeESPForModel(model)
            ancestryConn:Disconnect()
        end
    end)
end

local function updateESP()
    if not ESP_ENABLED then
        for _, data in pairs(espObjects) do
            data.Box.Visible = false
            data.Tracer.Visible = false
            data.Name.Visible = false
        end
        return
    end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local myPos = myRoot.Position

    for model, data in pairs(espObjects) do
        local root = data.Root
        local head = data.Head
        local bottom = data.Bottom

        if not (root and root.Parent and head and head.Parent) then
            data.Box.Visible = false
            data.Tracer.Visible = false
            data.Name.Visible = false
            continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0))
        local bottomPos = Camera:WorldToViewportPoint(bottom.Position - Vector3.new(0, 0.8, 0))

        local depthOk = rootPos.Z > 0

        if not (onScreen and depthOk) then
            data.Box.Visible = false
            data.Tracer.Visible = false
            data.Name.Visible = false
            continue
        end

        local top    = Vector2.new(headPos.X, headPos.Y)
        local bot    = Vector2.new(bottomPos.X, bottomPos.Y)
        local height = math.max((bot.Y - top.Y), 20)
        local width  = height * 0.55

        data.Box.Size     = Vector2.new(width, height)
        data.Box.Position = Vector2.new(rootPos.X - width/2, top.Y)
        data.Box.Visible  = SHOW_BOX

        if SHOW_TRACERS then
            data.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            data.Tracer.To   = Vector2.new(rootPos.X, bot.Y)
            data.Tracer.Visible = true
        else
            data.Tracer.Visible = false
        end

        if SHOW_NAME then
            local text = data.ModelName
            if SHOW_DISTANCE then
                local dist = (root.Position - myPos).Magnitude
                text = text .. " [" .. math.floor(dist) .. "]"
            end
            data.Name.Text     = text
            data.Name.Position = Vector2.new(rootPos.X, top.Y - 18)
            data.Name.Visible  = true
        else
            data.Name.Visible = false
        end
    end
end

local function setupPlayerESP(player)
    if player == LocalPlayer then return end

    local function onCharacterAdded(char)
        task.wait(0.5)

        removeESPForModel(player.Character)

        createESP(char)
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end

    player.CharacterAdded:Connect(onCharacterAdded)

    player.CharacterRemoving:Connect(function(oldChar)
        removeESPForModel(oldChar)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayerESP(player)
end

Players.PlayerAdded:Connect(setupPlayerESP)

task.spawn(function()
    while task.wait(2) do
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character then
                if obj.Name:lower():find("drop") 
                or obj:FindFirstChild("HumanoidRootPart") 
                or obj:FindFirstChild("HumanoidoidRootPart") then
                    createESP(obj)
                end
            end
        end
    end
end)


RunService.RenderStepped:Connect(updateESP)


local Window = Library:CreateWindow({ 
    Title = 'Ravent B', 
    Center = true, 
    AutoShow = true 
})

local Tabs = { 
    Main = Window:AddTab('Main'), 
    ['UI Settings'] = Window:AddTab('UI Settings') 
}

local KillAuraBox = Tabs.Main:AddLeftGroupbox('Kill Aura')
KillAuraBox:AddToggle('KillAura', { 
    Text = 'Kill Aura', 
    Default = false 
}):AddKeyPicker('KillAuraKey', { 
    Default = 'K', 
    SyncToggleState = true, 
    Mode = 'Toggle', 
    Text = 'Kill Aura' 
})

Toggles.KillAura:OnChanged(function()
    if Toggles.KillAura.Value then
        conn = RunService.Heartbeat:Connect(function()
            local t = nearest()
            if t then 
                hit(t) 
                task.wait(math.random(90, 170) / 1000) 
            end
        end)
    else
        if conn then 
            conn:Disconnect() 
            conn = nil 
        end
    end
end)

local FreeStuff = Tabs.Main:AddLeftGroupbox('Free Gamepass')
FreeStuff:AddToggle('VipToggle', { 
    Text = 'VIP Chat', 
    Default = false, 
    Callback = function(v) LocalPlayer:SetAttribute("vip_supporter", v) end 
})
FreeStuff:AddToggle('SkinsToggle', { 
    Text = 'Free Skins', 
    Default = false, 
    Callback = function(v) 
        local LP = game.Players.LocalPlayer
        LP:SetAttribute("skin_noob", v)
        LP:SetAttribute("skin_pack_anime", v)
        LP:SetAttribute("skin_pack_cool", v)
        LP:SetAttribute("skin_pack_girl", v)
    end 
})
FreeStuff:AddToggle('SlotToggle', { 
    Text = 'Extra World Slot', 
    Default = false, 
    Callback = function(v) LocalPlayer:SetAttribute("extra_world_slot", v) end 
})
FreeStuff:AddToggle('ViewToggle', { 
    Text = 'Extended View', 
    Default = false, 
    Callback = function(v) LocalPlayer:SetAttribute("extended_view", v) end 
})

local ReachBox = Tabs.Main:AddLeftGroupbox('Reach (Hitbox)')
ReachBox:AddToggle('ReachToggle', { 
    Text = 'Reach', 
    Default = false, 
    Callback = function(v) 
        if v then startLoop() else stopLoop() end 
    end 
}):AddKeyPicker('ReachKey', { 
    Default = 'R', 
    SyncToggleState = true, 
    Mode = 'Toggle', 
    Text = 'Reach' 
})
ReachBox:AddSlider('ReachSlider', { 
    Text = 'Reach Size', 
    Default = 15, 
    Min = 5, 
    Max = 15, 
    Rounding = 0 
})

local RS = game:GetService("ReplicatedStorage")
local afdEnabled = false
local adEnabled = false

if hookmetamethod then
    if typeof(hookmetamethod) == "function" then
        local FallRemote = RS.Systems.CombatSystem.Network.FallDamage
        local DownRemote = RS.Systems.CombatSystem.Network.DrownDamage

        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" then
                if self == FallRemote and afdEnabled then return nil end
                if self == DownRemote and adEnabled then return nil end
            end
            return oldNamecall(self, ...)
        end)
    end


    local ProtectionBox = Tabs.Main:AddRightGroupbox('Protections')

    ProtectionBox:AddToggle('AntiFall', {
        Text = 'Anti Fall Damage',
        Default = false,
        Callback = function(Value)
            afdEnabled = Value
        end
    })

    ProtectionBox:AddToggle('AntiDrown', {
        Text = 'Anti Drown',
        Default = false,
        Callback = function(Value)
            adEnabled = Value
        end
    })
else
    local ProtectionBox = Tabs.Main:AddRightGroupbox('Protections (Unsupported)')
end

local BATCH = 10
local DELAY = 0.3
local OreColors = {
    iron_ore = Color3.fromRGB(170,170,170),
    gold_ore = Color3.fromRGB(255,215,0),
    sulfer_ore = Color3.fromRGB(200,200,0),
    diamond_ore = Color3.fromRGB(128,0,0),
    coal_ore = Color3.fromRGB(40,40,40)
}

local ores, queue, running, xrayEnabled = {}, {}, false, false

local ores, queue, running, xrayEnabled = {}, {}, false, false

local function addOre(part)
    if not part:FindFirstChild("OreHL") and OreColors[part.MaterialVariant] then
        local hl = Instance.new("Highlight")
        hl.Name = "OreHL"; hl.FillColor = OreColors[part.MaterialVariant]; hl.OutlineColor = hl.FillColor; hl.FillTransparency = 0.5; hl.Parent = part
    end
end

local function processQueue()
    if running or not xrayEnabled then return end
    running = true
    task.spawn(function()
        local count = 0
        while #queue > 0 and count < BATCH and xrayEnabled do
            local part = table.remove(queue, 1)
            if part and part.Parent then addOre(part) end
            count += 1
        end
        running = false
        if #queue > 0 and xrayEnabled then task.delay(DELAY, processQueue) end
    end)
end


local function scanWorld()
    table.clear(ores)
    table.clear(queue)
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and OreColors[v.MaterialVariant] then
            table.insert(ores, v)
            table.insert(queue, v)
        end
    end
    processQueue()
end

workspace.DescendantAdded:Connect(function(v)
    if xrayEnabled and v:IsA("BasePart") and OreColors[v.MaterialVariant] then
        table.insert(ores, v); table.insert(queue, v); processQueue()
    end
end)


local VisualsBox = Tabs.Main:AddRightTabbox() 

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/linemaster2/esp-library/main/library.lua"))();

local EspTab = VisualsBox:AddTab('Visuals')
local DrawingSupported = pcall(function()
    local test = Drawing.new("Square")
    test:Remove()
end)

if not DrawingSupported then
    EspTab:AddLabel('Unsupported')
else
    EspTab:AddToggle('ESPToggle', {
        Text = 'ESP',
        Default = false,
        Tooltip = 'Tracking Players',
        Callback = function(Value)
            ESP_ENABLED = Value
        end
    })

    EspTab:AddDivider()

    EspTab:AddToggle('BoxESPToggle', {
        Text = 'Boxes',
        Default = false,
        Tooltip = 'Create Boxes',
        Callback = function(Value)
            SHOW_BOX = Value
        end
    })

    EspTab:AddToggle('DistanceESPToggle', {
        Text = 'Distance',
        Default = false,
        Tooltip = 'Create Distance',
        Callback = function(Value)
            SHOW_DISTANCE = Value
        end
    })

    EspTab:AddToggle('NameESPToggle', {
        Text = 'Names',
        Default = false,
        Tooltip = 'Create Names',
        Callback = function(Value)
            SHOW_NAME = Value
        end
    })

    EspTab:AddToggle('TracersESPToggle', {
        Text = 'Tracers',
        Default = false,
        Tooltip = 'Create Tracers',
        Callback = function(Value)
            SHOW_TRACERS = Value
        end
    })
end

local XrayTab = VisualsBox:AddTab('Xray')

XrayTab:AddToggle('XrayToggle', {
    Text = 'Xray',
    Default = false,
    Callback = function(v)
        xrayEnabled = v
        if v then
            scanWorld()
        else
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Highlight") and obj.Name == "OreHL" then
                    obj:Destroy()
                end
            end
        end
    end
}):AddKeyPicker('XrayKey', { 
    Default = 'X', 
    SyncToggleState = true, 
    Mode = 'Toggle', 
    Text = 'Xray' 
})

XrayTab:AddSlider('BatchSlider', { 
    Text = 'Batch Size', 
    Default = 10, 
    Min = 1, 
    Max = 100, 
    Rounding = 0,
    CallBack = function(Value)
        BATCH = Value
    end
})



game:GetService("ReplicatedStorage").Client.Events.LocalNotification:Fire("Ravent B Test Ver")

Library.KeybindFrame.Visible = true

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload Ravent B', function() Library:Unload() end)
MenuGroup:AddButton('Anti Lag', function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Biem6ondo/RBX_Minecraft/refs/heads/main/antilag"))() end)
MenuGroup:AddToggle('WatermarkToggle', { 
    Text = 'Show Watermark', 
    Default = true, 
    Callback = function(v) Library:SetWatermarkVisibility(v) end 
})
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { 
    Default = 'End', 
    NoUI = true, 
    Text = 'Menu keybind' 
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder('Ravent B')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1;

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;

    Library:SetWatermark(('Ravent B | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ));
end);

SaveManager:LoadAutoloadConfig()
