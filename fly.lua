-- FlightWithUI.lua (положить в StarterPlayerScripts как LocalScript)

-- Настройки по умолчанию (можно менять)
local DEFAULT_SPEED = 80          -- максимальная скорость полёта (studs/sec)
local ACCELERATION = 120          -- ускорение (чем больше — тем резче)
local FLY_TOGGLE_KEY = Enum.KeyCode.F
local ASCEND_KEY = Enum.KeyCode.Space
local DESCEND_KEY = Enum.KeyCode.LeftShift
local SINK_TOGGLE_KEY = Enum.KeyCode.G -- Ключ для включения/выключения погружения

-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- GUI создание
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlightGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 300, 0, 150)
mainFrame.Position = UDim2.new(0.5, -150, 0.85, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.Visible = true

local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.Size = UDim2.new(1, -12, 0, 30)
title.Position = UDim2.new(0, 6, 0, 6)
title.BackgroundTransparency = 1
title.Text = "Flight Controls"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.SourceSansSemibold
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(240,240,240)

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = mainFrame
statusLabel.Size = UDim2.new(1, -12, 0, 25)
statusLabel.Position = UDim2.new(0, 6, 0, 42)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Flight: OFF (F)"
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 18
statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

local sinkStatusLabel = Instance.new("TextLabel")
sinkStatusLabel.Parent = mainFrame
sinkStatusLabel.Size = UDim2.new(1, -12, 0, 25)
sinkStatusLabel.Position = UDim2.new(0, 6, 0, 70)
sinkStatusLabel.BackgroundTransparency = 1
sinkStatusLabel.Text = "Sink: OFF (G)"
sinkStatusLabel.Font = Enum.Font.SourceSans
sinkStatusLabel.TextSize = 18
sinkStatusLabel.TextColor3 = Color3.fromRGB(200,200,200)
sinkStatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local speedText = Instance.new("TextLabel")
speedText.Parent = mainFrame
speedText.Size = UDim2.new(1, -12, 0, 25)
speedText.Position = UDim2.new(0, 6, 0, 98)
speedText.BackgroundTransparency = 1
speedText.Text = "Speed: " .. tostring(DEFAULT_SPEED)
speedText.Font = Enum.Font.SourceSans
speedText.TextSize = 18
speedText.TextColor3 = Color3.fromRGB(200,200,200)
speedText.TextXAlignment = Enum.TextXAlignment.Left

-- Slider (простой)
local sliderBackground = Instance.new("Frame")
sliderBackground.Parent = mainFrame
sliderBackground.Size = UDim2.new(1, -20, 0, 20)
sliderBackground.Position = UDim2.new(0, 10, 0, 128)
sliderBackground.BackgroundColor3 = Color3.fromRGB(50,50,60)
sliderBackground.BorderSizePixel = 0
sliderBackground.AnchorPoint = Vector2.new(0,0)

local sliderFill = Instance.new("Frame")
sliderFill.Parent = sliderBackground
sliderFill.Size = UDim2.new(0.5, 0, 1, 0) -- по умолчанию 50%
sliderFill.Position = UDim2.new(0, 0, 0, 0)
sliderFill.BorderSizePixel = 0
sliderFill.BackgroundColor3 = Color3.fromRGB(100,180,255)

local sliderHandle = Instance.new("ImageLabel")
sliderHandle.Parent = sliderBackground
sliderHandle.Size = UDim2.new(0, 12, 0, 20)
sliderHandle.Position = UDim2.new(0.5, -6, 0, 0)
sliderHandle.BackgroundTransparency = 1
sliderHandle.Image = "rbxassetid://0" -- пустой
sliderHandle.AnchorPoint = Vector2.new(0.5, 0)

-- Вспомогательные переменные
local flying = false
local currentSpeed = DEFAULT_SPEED
local moveVector = Vector3.new(0,0,0)
local verticalInput = 0 -- -1 вниз, 0 нейтраль, 1 вверх
local sinking = false

local character, humanoid, rootPart
local bodyVelocity, bodyGyro
local particle -- визуальная частица

-- Слежение за персонажем
local function setupCharacter(char)
    character = char
    humanoid = char:FindFirstChildOfClass("Humanoid")
    rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function clearFlightForces()
    if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy() end
    if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy() end
    if particle and particle.Parent then particle:Destroy() end
    bodyVelocity = nil
    bodyGyro = nil
    particle = nil
end

local function enableFlight()
    if not rootPart then return end
    clearFlightForces()

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(9e5, 9e5, 9e5)
    bodyVelocity.Velocity = Vector3.new(0,0,0)
    bodyVelocity.P = 1e4
    bodyVelocity.Parent = rootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(9e5, 9e5, 9e5)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.P = 1e4
    bodyGyro.Parent = rootPart

    -- Простая визуализация частиц на корне
    local emitter = Instance.new("ParticleEmitter")
    emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,0)})
    emitter.Speed = NumberRange.new(0, 0)
    emitter.Rate = 40
    emitter.Lifetime = NumberRange.new(0.4,0.7)
    emitter.VelocitySpread = 90
    emitter.Parent = rootPart
    particle = emitter
end

local function disableFlight()
    clearFlightForces()
    moveVector = Vector3.new(0,0,0)
    verticalInput = 0
end

-- Привязка ввода для управления
local keys = {
    forward = false,
    backward = false,
    left = false,
    right = false,
}

local function updateMoveVector()
    local forward = (keys.forward and 1 or 0) - (keys.backward and 1 or 0)
    local right = (keys.right and 1 or 0) - (keys.left and 1 or 0)
    -- Вектор в системе камеры (здесь игнорируем вертикаль)
    local camCFrame = camera.CFrame
    local camForward = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
    if camForward ~= camForward then camForward = Vector3.new(0,0,-1) end -- NaN guard
    local camRight = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit

    moveVector = (camForward * forward) + (camRight * right)
    if moveVector.Magnitude > 1 then moveVector = moveVector.Unit end
end

-- Input handlers
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == FLY_TOGGLE_KEY then
        flying = not flying
        statusLabel.Text = "Flight: " .. (flying and "ON" or "OFF") .. " (F)"
        if flying then
            enableFlight()
        else
            disableFlight()
        end
    end

    if input.KeyCode == ASCEND_KEY then
        verticalInput = 1
    elseif input.KeyCode == DESCEND_KEY then
        verticalInput = -1
    elseif input.KeyCode == Enum.KeyCode.W then
        keys.forward = true; updateMoveVector()
    elseif input.KeyCode == Enum.KeyCode.S then
        keys.backward = true; updateMoveVector()
    elseif input.KeyCode == Enum.KeyCode.A then
        keys.left = true; updateMoveVector()
    elseif input.KeyCode == Enum.KeyCode.D then
        keys.right = true; updateMoveVector()
    elseif input.KeyCode == SINK_TOGGLE_KEY then
        sinking = not sinking
        sinkStatusLabel.Text = "Sink: " .. (sinking and "ON" or "OFF") .. " (G)"
        if sinking then
            sinkOthers()
        else
            bringOthersBack()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == ASCEND_KEY or input.KeyCode == DESCEND_KEY then
        verticalInput = 0
    elseif input.KeyCode == Enum.KeyCode.W then
        keys.forward = false; updateMoveVector()
    elseif input.KeyCode == Enum.KeyCode.S then
        keys.backward = false; updateMoveVector()
    elseif input.KeyCode == Enum.KeyCode.A then
        keys.left = false; updateMoveVector()
    elseif input.KeyCode == Enum.KeyCode.D then
        keys.right = false; updateMoveVector()
    end
end)

-- Slider drag handling
local dragging = false
local function sliderToSpeed(scale)
    -- scale: 0..1 -> speed range
    local minS, maxS = 20, 200
    return math.floor(minS + (maxS - minS) * math.clamp(scale, 0, 1))
end

sliderBackground.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local absPos = UserInputService:GetMouseLocation()
        local guiPos = sliderBackground.AbsolutePosition
        local relX = absPos.X - guiPos.X
        local width = sliderBackground.AbsoluteSize.X
        local scale = relX / width
        scale = math.clamp(scale, 0, 1)
        sliderFill.Size = UDim2.new(scale, 0, 1, 0)
        sliderHandle.Position = UDim2.new(scale, 0, 0, 0)
        currentSpeed = sliderToSpeed(scale)
        speedText.Text = "Speed: " .. tostring(currentSpeed)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Обновление каждого кадра
local lastDelta = 0
RunService.RenderStepped:Connect(function(dt)
    if not localPlayer.Character or not localPlayer.Character.Parent then
        localPlayer.CharacterAdded:Wait()
        setupCharacter(localPlayer.Character)
    end

    if not character or not rootPart then
        setupCharacter(localPlayer.Character)
    end

    if flying and bodyVelocity and bodyGyro and rootPart then
        -- цельная скорость (горизонтальная часть)
        updateMoveVector()
        local targetVelocity = moveVector * currentSpeed
        -- добавляем вертикальную составляющую
        local climbSpeed = 40 -- базовая скорость подъёма/спуска
        local verticalVel = verticalInput * climbSpeed
        -- сглаживание: интерполяция текущей к новой
        local curVel = bodyVelocity.Velocity
        local desired = Vector3.new(targetVelocity.X, verticalVel, targetVelocity.Z)
        -- приближаем с учётом ускорения
        local t = math.clamp(ACCELERATION * dt, 0, 1)
        local newVel = curVel:Lerp(desired, t)
        bodyVelocity.Velocity = Vector3.new(newVel.X, newVel.Y, newVel.Z)

        -- ориентация: смотрим в направлении движения камеры (либо направление полёта)
        local lookAt = camera.CFrame.LookVector
        local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + lookAt)
        bodyGyro.CFrame = rootPart.CFrame:Lerp(targetCFrame, 0.2)
    end
end)

-- Подключение к CharacterAdded/Removing
local function onCharacterAdded(char)
    setupCharacter(char)
    statusLabel.Text = "Flight: " .. (flying and "ON" or "OFF") .. " (F)"
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)
if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

-- при уходе игрока/спавне GUI сохранится благодаря ResetOnSpawn=false выше — но можно сбрасывать
localPlayer.CharacterRemoving:Connect(function()
    disableFlight()
end)

-- Дополнительно: quick hint
local hint = Instance.new("TextLabel")
hint.Parent = mainFrame
hint.Size = UDim2.new(1, -12, 0, 12)
hint.Position = UDim2.new(0, 6, 1, -16)
hint.BackgroundTransparency = 1
hint.Text = "W/A/S/D + Space/Shift, F - toggle, G - sink toggle"
hint.Font = Enum.Font.SourceSans
hint.TextSize = 12
hint.TextColor3 = Color3.fromRGB(170,170,170)
hint.TextXAlignment = Enum.TextXAlignment.Left

-- Инициализация: slider default position
local defaultScale = (DEFAULT_SPEED - 20) / (200 - 20)
sliderFill.Size = UDim2.new(defaultScale, 0, 1, 0)
sliderHandle.Position = UDim2.new(defaultScale, 0, 0, 0)

-- Ноуклип с игнорированием текстур
local function noClip()
    local function ignoreTextures(part)
        part.CanCollide = false
        part.Transparency = 1
    end

    for _, part in pairs(workspace:GetChildren()) do
        if part:IsA("BasePart") then
            ignoreTextures(part)
        end
    end

    workspace.ChildAdded:Connect(function(child)
        if child:IsA("BasePart") then
            ignoreTextures(child)
        end
    end)
end

noClip()

-- Функция для погружения всех игроков под землю, кроме вас
local function sinkOthers()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.PlatformStand = true
                    char:SetPrimaryPartCFrame(CFrame.new(0, -50, 0)) -- погружаем под землю
                end
            end
        end
    end
end

-- Функция для возвращения всех игроков на поверхность
local function bringOthersBack()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.PlatformStand = false
                end
            end
        end
    end
end

-- Предотвращение кика с сервера
local function preventKick()
    local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end
end

preventKick()

-- Обновление положения игрока каждую секунду, чтобы избежать кика
RunService.Heartbeat:Connect(function()
    if flying then
        preventKick()
    end
end)
