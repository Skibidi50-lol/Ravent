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

local Window = Library:CreateWindow({ 
    Title = 'RaventSolara', 
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


local EspTab = VisualsBox:AddTab('Visuals')

EspTab:AddToggle('ESPToggle', { Text = 'soon', Default = false, Callback = function(v) 

end })

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



game:GetService("ReplicatedStorage").Client.Events.LocalNotification:Fire("RaventSolara V1")

Library.KeybindFrame.Visible = true

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload RaventSolara', function() Library:Unload() end)
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
SaveManager:SetFolder('RaventSolara')
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

    Library:SetWatermark(('RaventSolara | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ));
end);

SaveManager:LoadAutoloadConfig()
