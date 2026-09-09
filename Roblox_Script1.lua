--// CONFIG
local OWNER_IDS = {
    2648350308, -- << put your UserId(s) here
}

local PANEL_PASSWORD = "JASPY" -- << set your password here

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Owner check
local function isOwner()
    for _, id in ipairs(OWNER_IDS) do
        if LocalPlayer.UserId == id then
            return true
        end
    end
    return false
end

if not isOwner() then
    return -- non-owners get nothing, script silently does nothing
end

--// LOAD RAYFIELD
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// ================= PASSWORD GATE =================
-- Small prompt window shown before the real panel loads
local PromptWindow = Rayfield:CreateWindow({
    Name = "Verification",
    LoadingTitle = "Jaspy Hub",
    LoadingSubtitle = "Locked",
    ConfigurationSaving = { Enabled = false },
})

local LockTab = PromptWindow:CreateTab("Enter Password", 4483362458)
local enteredPassword = ""

LockTab:CreateInput({
    Name = "Password",
    PlaceholderText = "Enter password...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value)
        enteredPassword = Value
    end,
})

LockTab:CreateButton({
    Name = "Unlock",
    Callback = function()
        if enteredPassword == PANEL_PASSWORD then
            Rayfield:Notify({
                Title = "Access Granted",
                Content = "Loading owner panel...",
                Duration = 2,
            })
            task.wait(1)
            Rayfield:Destroy() -- close the lock window
            loadOwnerPanel()
        else
            Rayfield:Notify({
                Title = "Access Denied",
                Content = "Incorrect password.",
                Duration = 3,
            })
        end
    end,
})

--// ================= MAIN PANEL (only runs after correct password) =================
function loadOwnerPanel()
    local Window = Rayfield:CreateWindow({
        Name = "Jaspy Hub",
        LoadingTitle = "Owner Tools",
        LoadingSubtitle = "by You",
        ConfigurationSaving = {
            Enabled = false
        }
    })

    --// ================= HIGHLIGHT TAB =================
    local HighlightTab = Window:CreateTab("Highlight", 4483362458)

    local highlights = {}

    local function clearHighlights()
        for _, h in pairs(highlights) do
            if h then h:Destroy() end
        end
        highlights = {}
    end

    local function highlightAllPlayers(fillColor, outlineColor)
        clearHighlights()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local h = Instance.new("Highlight")
                h.FillColor = fillColor
                h.OutlineColor = outlineColor
                h.FillTransparency = 0.5
                h.OutlineTransparency = 0
                h.Adornee = plr.Character
                h.Parent = plr.Character
                table.insert(highlights, h)
            end
        end
    end

    local function highlightAllEntities(fillColor, outlineColor, folderName)
        clearHighlights()
        local scanRoot = folderName ~= "" and workspace:FindFirstChild(folderName) or workspace
        if not scanRoot then return end

        for _, obj in ipairs(scanRoot:GetDescendants()) do
            if obj:IsA("Humanoid") then
                local model = obj.Parent
                local h = Instance.new("Highlight")
                h.FillColor = fillColor
                h.OutlineColor = outlineColor
                h.FillTransparency = 0.5
                h.OutlineTransparency = 0
                h.Adornee = model
                h.Parent = model
                table.insert(highlights, h)
            end
        end
    end

    HighlightTab:CreateToggle({
        Name = "Highlight All Players",
        CurrentValue = false,
        Flag = "HighlightPlayers",
        Callback = function(Value)
            if Value then
                highlightAllPlayers(Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 255, 255))
            else
                clearHighlights()
            end
        end,
    })

    HighlightTab:CreateInput({
        Name = "Entities Folder (optional, blank = whole workspace)",
        PlaceholderText = "e.g. Enemies",
        RemoveTextAfterFocusLost = false,
        Flag = "EntitiesFolder",
        Callback = function() end,
    })

    HighlightTab:CreateToggle({
        Name = "Highlight All Entities (Humanoids)",
        CurrentValue = false,
        Flag = "HighlightEntities",
        Callback = function(Value)
            if Value then
                local folderName = Rayfield:GetFlagValue("EntitiesFolder") or ""
                highlightAllEntities(Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 0), folderName)
            else
                clearHighlights()
            end
        end,
    })

    HighlightTab:CreateButton({
        Name = "Refresh Highlights",
        Callback = function()
            if Rayfield:GetFlagValue("HighlightPlayers") then
                highlightAllPlayers(Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 255, 255))
            elseif Rayfield:GetFlagValue("HighlightEntities") then
                local folderName = Rayfield:GetFlagValue("EntitiesFolder") or ""
                highlightAllEntities(Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 0), folderName)
            end
        end,
    })

    --// ================= MOVEMENT TAB =================
    local MoveTab = Window:CreateTab("Movement", 4483362458)

    -- FLY
    local flying = false
    local flySpeed = 50
    local bodyVelocity, bodyGyro
    local flyConnection

    local function getHumanoidRootPart()
        local char = LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local function startFly()
        local hrp = getHumanoidRootPart()
        if not hrp or flying then return end
        flying = true

        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1, 1, 1) * math.huge
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = hrp

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1, 1, 1) * math.huge
        bodyGyro.P = 10000
        bodyGyro.Parent = hrp

        local camera = workspace.CurrentCamera

        flyConnection = RunService.RenderStepped:Connect(function()
            if not flying then return end
            local rootPart = getHumanoidRootPart()
            if not rootPart then return end

            local moveVector = Vector3.new(0, 0, 0)
            local cf = camera.CFrame

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveVector += cf.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveVector -= cf.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveVector -= cf.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveVector += cf.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveVector += Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveVector -= Vector3.new(0, 1, 0)
            end

            if moveVector.Magnitude > 0 then
                moveVector = moveVector.Unit * flySpeed
            end

            bodyVelocity.Velocity = moveVector
            bodyGyro.CFrame = cf
        end)
    end

    local function stopFly()
        flying = false
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
    end

    MoveTab:CreateToggle({
        Name = "Fly",
        CurrentValue = false,
        Flag = "FlyToggle",
        Callback = function(Value)
            if Value then
                startFly()
            else
                stopFly()
            end
        end,
    })

    MoveTab:CreateSlider({
        Name = "Fly Speed",
        Range = {10, 300},
        Increment = 5,
        CurrentValue = 50,
        Flag = "FlySpeed",
        Callback = function(Value)
            flySpeed = Value
        end,
    })

    -- HIP HEIGHT
    MoveTab:CreateSlider({
        Name = "Hip Height",
        Range = {0, 20},
        Increment = 0.5,
        CurrentValue = 0,
        Flag = "HipHeight",
        Callback = function(Value)
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.HipHeight = Value
            end
        end,
    })

    --// ================= GOD MODE TAB =================
    local GodTab = Window:CreateTab("God Mode", 4483362458)

    local godModeEnabled = false
    local godConnection

    local function enableGodMode()
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge

        -- Keep health topped off / block damage every heartbeat
        if godConnection then godConnection:Disconnect() end
        godConnection = RunService.Heartbeat:Connect(function()
            if not godModeEnabled then return end
            local currentChar = LocalPlayer.Character
            local hum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.MaxHealth ~= math.huge then
                    hum.MaxHealth = math.huge
                end
                if hum.Health < hum.MaxHealth then
                    hum.Health = hum.MaxHealth
                end
            end
        end)
    end

    local function disableGodMode()
        if godConnection then
            godConnection:Disconnect()
            godConnection = nil
        end
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end
    end

    GodTab:CreateToggle({
        Name = "God Mode",
        CurrentValue = false,
        Flag = "GodMode",
        Callback = function(Value)
            godModeEnabled = Value
            if Value then
                enableGodMode()
            else
                disableGodMode()
            end
        end,
    })

    -- Re-apply god mode / fly / hip height on respawn if toggled on
    LocalPlayer.CharacterAdded:Connect(function()
        stopFly()
        task.wait(1)
        if flying then
            startFly()
        end
        if godModeEnabled then
            enableGodMode()
        end
        local hh = Rayfield:GetFlagValue("HipHeight")
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid and hh then
            humanoid.HipHeight = hh
        end
    end)
        --// ================= PLAYER COMMANDS TAB =================
    local PlayerTab = Window:CreateTab("Player Commands", 4483362458)

    local selectedPlayerName = ""

    local function getPlayerList()
        local names = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            table.insert(names, plr.Name)
        end
        return names
    end

    local PlayerDropdown = PlayerTab:CreateDropdown({
        Name = "Select Player",
        Options = getPlayerList(),
        CurrentOption = {},
        Flag = "SelectedPlayer",
        Callback = function(Option)
            selectedPlayerName = Option[1]
        end,
    })

    -- Keep dropdown list fresh as players join/leave
    Players.PlayerAdded:Connect(function()
        PlayerDropdown:Refresh(getPlayerList())
    end)
    Players.PlayerRemoving:Connect(function()
        task.wait(0.1)
        PlayerDropdown:Refresh(getPlayerList())
    end)

    local function getTargetPlayer()
        return Players:FindFirstChild(selectedPlayerName)
    end

    PlayerTab:CreateButton({
        Name = "Teleport To Player",
        Callback = function()
            local target = getTargetPlayer()
            local myHrp = getHumanoidRootPart()
            if target and target.Character and myHrp then
                local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 0, 3)
                end
            end
        end,
    })

    PlayerTab:CreateButton({
        Name = "Bring Player",
        Callback = function()
            local target = getTargetPlayer()
            local myHrp = getHumanoidRootPart()
            if target and target.Character and myHrp then
                local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    targetHrp.CFrame = myHrp.CFrame + Vector3.new(0, 0, 3)
                end
            end
        end,
    })

    -- NOTE: Kill / Freeze / Unfreeze only affect what YOUR client can touch.
    -- To actually kill, freeze, or otherwise affect OTHER players, you need
    -- a server script + RemoteEvent (see note below the code).
    PlayerTab:CreateButton({
        Name = "Kill Selected Player (self-only unless server-side)",
        Callback = function()
            local target = getTargetPlayer()
            if target and target.Character then
                local hum = target.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = 0 end
            end
        end,
    })

    PlayerTab:CreateButton({
        Name = "Respawn Me",
        Callback = function()
            LocalPlayer:LoadCharacter()
        end,
    })

    MoveTab:CreateSlider({
        Name = "Walk Speed",
        Range = {16, 500},
        Increment = 1,
        CurrentValue = 16,
        Flag = "WalkSpeed",
        Callback = function(Value)
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = Value end
        end,
    })

    MoveTab:CreateSlider({
        Name = "Jump Power",
        Range = {50, 500},
        Increment = 5,
        CurrentValue = 50,
        Flag = "JumpPower",
        Callback = function(Value)
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.UseJumpPower = true
                humanoid.JumpPower = Value
            end
        end,
    })

    --// ================= UTILITIES TAB =================
    local UtilTab = Window:CreateTab("Utilities", 4483362458)

    -- NOCLIP
    local noclipEnabled = false
    local noclipConnection

    local function startNoclip()
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end

    local function stopNoclip()
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end

    UtilTab:CreateToggle({
        Name = "Noclip",
        CurrentValue = false,
        Flag = "Noclip",
        Callback = function(Value)
            noclipEnabled = Value
            if Value then startNoclip() else stopNoclip() end
        end,
    })

    -- INVISIBLE (client-side visual only)
    UtilTab:CreateToggle({
        Name = "Invisible (local view only)",
        CurrentValue = false,
        Flag = "Invisible",
        Callback = function(Value)
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    part.Transparency = Value and 1 or 0
                end
            end
        end,
    })

    -- FREEZE / UNFREEZE (self)
    UtilTab:CreateToggle({
        Name = "Freeze Myself",
        CurrentValue = false,
        Flag = "FreezeSelf",
        Callback = function(Value)
            local hrp = getHumanoidRootPart()
            if not hrp then return end
            hrp.Anchored = Value
        end,
    })

    -- COMMAND BAR (Infinite Yield style text commands)
    UtilTab:CreateInput({
        Name = "Command Bar",
        PlaceholderText = ":speed 50, :tp PlayerName, :fly, :god, :respawn",
        RemoveTextAfterFocusLost = true,
        Callback = function(Text)
            local args = {}
            for word in Text:gmatch("%S+") do
                table.insert(args, word)
            end
            local cmd = args[1]

            if cmd == ":speed" and args[2] then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = tonumber(args[2]) or 16 end

            elseif cmd == ":tp" and args[2] then
                local target = Players:FindFirstChild(args[2])
                local myHrp = getHumanoidRootPart()
                if target and target.Character and myHrp then
                    local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
                    if targetHrp then
                        myHrp.CFrame = targetHrp.CFrame + Vector3.new(0, 0, 3)
                    end
                end

            elseif cmd == ":fly" then
                if flying then stopFly() else startFly() end

            elseif cmd == ":god" then
                godModeEnabled = not godModeEnabled
                if godModeEnabled then enableGodMode() else disableGodMode() end

            elseif cmd == ":respawn" then
                LocalPlayer:LoadCharacter()

            elseif cmd == ":noclip" then
                noclipEnabled = not noclipEnabled
                if noclipEnabled then startNoclip() else stopNoclip() end

            else
                Rayfield:Notify({
                    Title = "Unknown Command",
                    Content = tostring(cmd) .. " is not recognized",
                    Duration = 3,
                })
            end
        end,
    })
    Rayfield:Notify({
        Title = "Jaspy Hub Loaded",
        Content = "Welcome, thx for using Jaspy Hub.",
        Duration = 4,
    })
end0

