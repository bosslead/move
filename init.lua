-- Carregar Luna Interface 
local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/main/source.lua", true))()

-- Criação da janela principal
local Window = Luna:CreateWindow({
    Name = "Bey Hub",
    Subtitle = "Movement Capture",
    LogoID = "121039026093305",
    LoadingEnabled = true,
    LoadingTitle = "damn, it's Bey Hub",
    LoadingSubtitle = "by zBeyond",
    ConfigSettings = {
        RootFolder = nil,
        ConfigFolder = "MovementCaptureConfig"
    },
    KeySystem = false,
})

-- Dashboard (Home Tab)
Window:CreateHomeTab({
    SupportedExecutors = {"Synapse X", "Krnl", "ScriptWare"},
    DiscordInvite = "https://discord.gg/ehVju5Uu",
    Icon = 1
})

------------------------------------------------
-- Aba "Main" - Funcionalidades Principais
------------------------------------------------
local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "directions_run",
    ImageSource = "Material",
    ShowTitle = true
})

-- Seção: Capture Control
MainTab:CreateSection("Capture Control")

local capturedMoves = {}
local capturing = false
local loopPlayback = false -- Toggle para reprodução em loop
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local currentWalkSpeed = Humanoid.WalkSpeed or 16
local currentJumpPower = Humanoid.JumpPower or 50

local function startCapturing()
    capturedMoves = {}  -- Limpa movimentos anteriores
    capturing = true
    Luna:Notification({
        Title = "Capture Started",
        Icon = "fiber_manual_record",
        ImageSource = "Material",
        Content = "Movements are being captured..."
    })
end

local function stopCapturing()
    capturing = false
    Luna:Notification({
        Title = "Capture Stopped",
        Icon = "stop",
        ImageSource = "Material",
        Content = "Movement capture ended."
    })
end

local function replayMoves()
    if #capturedMoves > 0 then
        Luna:Notification({
            Title = "Playback Started",
            Icon = "play_arrow",
            ImageSource = "Material",
            Content = "Playing captured movements..."
        })
        repeat
            for _, targetPos in ipairs(capturedMoves) do
                if Character.PrimaryPart then
                    local currentPos = Character.PrimaryPart.Position
                    local distance = (targetPos - currentPos).Magnitude
                    local tweenTime = distance / (currentWalkSpeed > 0 and currentWalkSpeed or 16)
                    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
                    local tween = TweenService:Create(Character.PrimaryPart, tweenInfo, {CFrame = CFrame.new(targetPos)})
                    tween:Play()
                    tween.Completed:Wait()
                end
            end
        until not loopPlayback
    else
        Luna:Notification({
            Title = "Error",
            Icon = "error",
            ImageSource = "Material",
            Content = "No movement captured."
        })
    end
end

RunService.Heartbeat:Connect(function()
    if capturing and Character.PrimaryPart then
        table.insert(capturedMoves, Character.PrimaryPart.Position)
    end
end)

MainTab:CreateButton({
    Name = "Start Capture",
    Description = "Begins capturing the player's movements.",
    Callback = startCapturing
})
MainTab:CreateButton({
    Name = "Stop Capture",
    Description = "Ends the movement capture.",
    Callback = stopCapturing
})
MainTab:CreateButton({
    Name = "Replay Movements",
    Description = "Plays the captured movements with smooth interpolation.",
    Callback = replayMoves
})
MainTab:CreateToggle({
    Name = "Loop Playback",
    Description = "Enables/Disables loop playback of captured movements.",
    CurrentValue = false,
    Callback = function(state)
        loopPlayback = state
        Luna:Notification({
            Title = "Loop Playback " .. (state and "Enabled" or "Disabled"),
            Icon = state and "autorenew" or "pause_circle_filled",
            ImageSource = "Material",
            Content = "Loop Playback " .. (state and "Enabled" or "Disabled")
        })
    end
}, "ToggleLoopPlayback")

-- Seção: Controles de Atributos
MainTab:CreateSection("Player")

MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {0, 500},
    Increment = 1,
    CurrentValue = currentWalkSpeed,
    Callback = function(Value)
        currentWalkSpeed = Value
        if Humanoid then
            Humanoid.WalkSpeed = Value
        end
        Luna:Notification({
            Title = "WalkSpeed Updated",
            Icon = "directions_run",
            ImageSource = "Material",
            Content = "WalkSpeed: " .. Value
        })
    end
}, "SliderWalkSpeed")

MainTab:CreateSlider({
    Name = "JumpPower",
    Range = {0, 200},
    Increment = 1,
    CurrentValue = currentJumpPower,
    Callback = function(Value)
        currentJumpPower = Value
        if Humanoid then
            Humanoid.JumpPower = Value
        end
        Luna:Notification({
            Title = "JumpPower Updated",
            Icon = "arrow_upward",
            ImageSource = "Material",
            Content = "JumpPower: " .. Value
        })
    end
}, "SliderJumpPower")

MainTab:CreateToggle({
    Name = "Infinite Jump",
    Description = "Enables/Disables Infinite Jump (using the player's JumpPower).",
    CurrentValue = false,
    Callback = function(state)
        _G.infinjump = state
        Luna:Notification({
            Title = "Infinite Jump " .. (state and "Enabled" or "Disabled"),
            Icon = state and "check_circle" or "cancel",
            ImageSource = "Material",
            Content = "Infinite Jump " .. (state and "Enabled" or "Disabled")
        })
    end
}, "ToggleInfiniteJump")

local flyToggleState = false
local flightSpeed = 50

MainTab:CreateSlider({
    Name = "Flight Speed",
    Range = {10, 500},
    Increment = 1,
    CurrentValue = flightSpeed,
    Callback = function(Value)
        flightSpeed = Value
        Luna:Notification({
            Title = "Flight Speed Updated",
            Icon = "speed",
            ImageSource = "Material",
            Content = "Flight Speed: " .. Value
        })
    end
}, "SliderFlightSpeed")

local function startFly()
    _G.fly = true
    local plr = game.Players.LocalPlayer
    local char = plr.Character
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not torso then return end
    local mouse = plr:GetMouse()
    local ctrl = {f = 0, b = 0, l = 0, r = 0}
    local lastctrl = {f = 0, b = 0, l = 0, r = 0}
    local maxspeed = flightSpeed
    local speed = 0

    local bg = Instance.new("BodyGyro", torso)
    bg.P = 9e4
    bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.cframe = torso.CFrame
    local bv = Instance.new("BodyVelocity", torso)
    bv.velocity = Vector3.new(0,0.1,0)
    bv.maxForce = Vector3.new(9e9, 9e9, 9e9)

    local keyDownConn, keyUpConn
    keyDownConn = mouse.KeyDown:Connect(function(key)
        key = key:lower()
        if key == "e" then
            _G.fly = not _G.fly
        elseif key == "w" then
            ctrl.f = 1
        elseif key == "s" then
            ctrl.b = -1
        elseif key == "a" then
            ctrl.l = -1
        elseif key == "d" then
            ctrl.r = 1
        end
    end)
    keyUpConn = mouse.KeyUp:Connect(function(key)
        key = key:lower()
        if key == "w" then
            ctrl.f = 0
        elseif key == "s" then
            ctrl.b = 0
        elseif key == "a" then
            ctrl.l = 0
        elseif key == "d" then
            ctrl.r = 0
        end
    end)

    spawn(function()
        while _G.fly do
            char.Humanoid.PlatformStand = true
            if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                speed = speed + 0.5 + (speed/maxspeed)
                if speed > maxspeed then speed = maxspeed end
            else
                speed = speed - 1
                if speed < 0 then speed = 0 end
            end
            if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                bv.velocity = ((workspace.CurrentCamera.CFrame.lookVector * (ctrl.f + ctrl.b)) + 
                ((workspace.CurrentCamera.CFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b)*0.2, 0).p) - workspace.CurrentCamera.CFrame.p)) * speed
                lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
            elseif speed ~= 0 then
                bv.velocity = ((workspace.CurrentCamera.CFrame.lookVector * (lastctrl.f + lastctrl.b)) + 
                ((workspace.CurrentCamera.CFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b)*0.2, 0).p) - workspace.CurrentCamera.CFrame.p)) * speed
            else
                bv.velocity = Vector3.new(0,0.1,0)
            end
            bg.cframe = workspace.CurrentCamera.CFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed), 0, 0)
            wait()
        end
        bg:Destroy()
        bv:Destroy()
        char.Humanoid.PlatformStand = false
        keyDownConn:Disconnect()
        keyUpConn:Disconnect()
    end)
end

local function stopFly()
    _G.fly = false
end

MainTab:CreateToggle({
    Name = "Fly",
    Description = "Enables/Disables Fly.",
    CurrentValue = false,
    Callback = function(state)
        flyToggleState = state
        if state then
            startFly()
            Luna:Notification({
                Title = "Fly Enabled",
                Icon = "flight_takeoff",
                ImageSource = "Material",
                Content = "Fly enabled."
            })
        else
            stopFly()
            Luna:Notification({
                Title = "Fly Disabled",
                Icon = "flight_land",
                ImageSource = "Material",
                Content = "Fly disabled."
            })
        end
    end
}, "ToggleFly")

local function setupInfiniteJump()
    local plr = game:GetService("Players").LocalPlayer
    local m = plr:GetMouse()
    m.KeyDown:Connect(function(k)
        if _G.infinjump and k:byte() == 32 then
            local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.JumpPower = currentJumpPower 
                hum:ChangeState("Jumping")
                wait()
                hum:ChangeState("Seated")
            end
        end
    end)
end
setupInfiniteJump()

MainTab:CreateSection("Others")

MainTab:CreateToggle({
    Name = "Noclip",
    Description = "Enables/Disables Noclip.",
    CurrentValue = false,
    Callback = function(state)
        toggleNoclip(state)
        Luna:Notification({
            Title = "Noclip " .. (state and "Enabled" or "Disabled"),
            Icon = state and "check_circle" or "cancel",
            ImageSource = "Material",
            Content = "Noclip " .. (state and "Enabled" or "Disabled")
        })
    end
}, "ToggleNoclip")

-- Botão: Restart Character
MainTab:CreateButton({
    Name = "Restart Character",
    Description = "Restarts the player's character.",
    Callback = function()
        if Player and Player.Character then
            local humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0 -- Mata o personagem
                Luna:Notification({
                    Title = "Character Restarted",
                    Icon = "autorenew",
                    ImageSource = "Material",
                    Content = "The character has been restarted."
                })
            end
        end
    end
})

------------------------------------------------
-- Aba "Misc" - Funcionalidades Diversas
------------------------------------------------
local MiscTab = Window:CreateTab({
    Name = "Misc",
    Icon = "build",
    ImageSource = "Material",
    ShowTitle = true
})

-- Botão: Music Player
MiscTab:CreateButton({
    Name = "Music Player",
    Description = "Loads the Music Player script.",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/qdbi/Rave-Hub/refs/heads/main/Rave%20Hub%20Language%20Selection", true))()
    end
})

-- Botão: Anti-afk
MiscTab:CreateButton({
    Name = "Anti-afk",
    Description = "Prevents the player from being kicked for inactivity.",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hassanxzayn-lua/Anti-afk/main/antiafkbyhassanxzyn"))();
    end
})

-- Botão: ESP
local ESP_Skeletons = {}
local ESP_RenderConnections = {}
local ESP_NameTags = {}
local ESP_Connection -- Variável para armazenar a conexão de PlayerAdded

MiscTab:CreateToggle({
    Name = "ESP",
    Description = "Enables the ESP skeleton overlay.",
    Default = false,
    Callback = function(state)
        if state then
            local settings = {
                Color = Color3.fromRGB(0, 255, 0), -- Cor verde para o texto
                Size = 15,
                Transparency = 1, -- 1 = Visível, 0 = Invisível
                AutoScale = true
            }

            local space = game:GetService("Workspace")
            local player = game:GetService("Players").LocalPlayer
            local camera = space.CurrentCamera

            local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Blissful4992/ESPs/main/UniversalSkeleton.lua"))()

            local function NewText(color, size, transparency)
                local text = Drawing.new("Text")
                text.Visible = false
                text.Text = ""
                text.Position = Vector2.new(0, 0)
                text.Color = color
                text.Size = size
                text.Center = true
                text.Transparency = transparency
                return text
            end

            local function CreateSkeleton(plr)
                local skeleton = Library:NewSkeleton(plr, true)
                skeleton.Size = 50 -- Largura aumentada para melhor visibilidade
                skeleton.Static = true
                table.insert(ESP_Skeletons, skeleton)

                local nameTag = NewText(settings.Color, settings.Size, settings.Transparency)
                table.insert(ESP_NameTags, nameTag)

                local conn = game:GetService("RunService").RenderStepped:Connect(function()
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local hrpPos, onScreen = camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                        local distance = (player.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                
                        if onScreen and distance <= maxESPDistance then
                            nameTag.Text = string.format("%s [%d Studs]", plr.Name, math.floor(distance))
                            nameTag.Position = Vector2.new(hrpPos.X, hrpPos.Y - 50)
                            nameTag.Visible = true
                            skeleton.Visible = true
                        else
                            nameTag.Visible = false
                            skeleton.Visible = false
                        end
                    else
                        nameTag.Visible = false
                        skeleton.Visible = false
                    end
                end)
                
                table.insert(ESP_RenderConnections, conn)
            end

            for _, plr in pairs(game.Players:GetPlayers()) do
                if plr.Name ~= player.Name then
                    CreateSkeleton(plr)
                end
            end

            -- Armazena a conexão e permite desconectá-la depois
            ESP_Connection = game.Players.PlayerAdded:Connect(function(plr)
                if plr.Name ~= player.Name then
                    CreateSkeleton(plr)
                end
            end)

        else
            -- Desconecta a conexão de PlayerAdded para não criar ESP em novos jogadores
            if ESP_Connection then
                ESP_Connection:Disconnect()
                ESP_Connection = nil
            end

            -- Desconecta as conexões do RenderStepped
            for _, conn in pairs(ESP_RenderConnections) do
                conn:Disconnect()
            end
            ESP_RenderConnections = {}

            -- Remove todos os skeletons criados
            for _, skeleton in pairs(ESP_Skeletons) do
                if skeleton then
                    if skeleton.Remove then
                        skeleton:Remove()
                    elseif skeleton.Destroy then
                        skeleton:Destroy()
                    else
                        if skeleton.Part then
                            skeleton.Part:Destroy()
                        end
                        if skeleton.Drawings then
                            for _, drawing in pairs(skeleton.Drawings) do
                                if drawing.Remove then
                                    drawing:Remove()
                                end
                            end
                        end
                    end
                end
            end
            ESP_Skeletons = {}

            -- Remove os objetos de texto (nameTags)
            for _, tag in pairs(ESP_NameTags) do
                if tag.Remove then
                    tag:Remove()
                else
                    tag.Visible = false
                end
            end
            ESP_NameTags = {}
        end
    end
})

MiscTab:CreateSlider({
    Name = "ESP Line Thickness",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 1,
    Callback = function(Value)
        for _, skeleton in pairs(ESP_Skeletons) do
            if skeleton and skeleton.SetThickness then
                skeleton:SetThickness(Value)
            end
        end
        Luna:Notification({
            Title = "ESP Updated",
            Icon = "build",
            ImageSource = "Material",
            Content = "ESP line thickness set to " .. Value
        })
    end
}, "SliderESPThickness")



-- Botão: Misc Appearance
MiscTab:CreateToggle({
    Name = "Misc Appearance",
    Description = "Changes the appearance of BaseParts to Black/White with Motor surfaces.",
    CurrentValue = false,
    Callback = function(state)
        if state then
            for i, x in pairs(Player.Character:GetChildren()) do
                if x:IsA("BasePart") then
                    x.BrickColor = BrickColor.Black() or BrickColor.White()
                    x.BackSurface = Enum.SurfaceType.Motor
                    x.BottomSurface = Enum.SurfaceType.Motor
                    x.FrontSurface = Enum.SurfaceType.Motor
                    x.LeftSurface = Enum.SurfaceType.Motor
                    x.RightSurface = Enum.SurfaceType.Motor
                    x.TopSurface = Enum.SurfaceType.Motor
                end
            end
            Luna:Notification({
                Title = "Appearance Changed",
                Icon = "brush",
                ImageSource = "Material",
                Content = "Appearance changed with Motor surfaces."
            })
        else
            Luna:Notification({
                Title = "Appearance Reset",
                Icon = "restore",
                ImageSource = "Material",
                Content = "Appearance kept or manually reset."
            })
        end
    end
}, "ToggleMiscAppearance")
