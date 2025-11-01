-- FlightWithUI.lua (положить в StarterPlayerScripts как LocalScript)

-- Настройки по умолчанию (можно менять)
local DEFAULT_SPEED = 50          -- максимальная скорость полёта (studs/sec)
local ACCELERATION = 80           -- ускорение (чем больше — тем резче)
local FLY_TOGGLE_KEY = Enum.KeyCode.F
local ASCEND_KEY = Enum.KeyCode.Space
local DESCEND_KEY = Enum.KeyCode.LeftShift
local SINK_TOGGLE_KEY = Enum.KeyCode.G -- Ключ для включения/выключения погружения
local NOCLIP_TOGGLE_KEY = Enum.KeyCode.V -- Ключ для включения/выключения ноуклипа
local UI_TOGGLE_KEY = Enum.KeyCode.RightShift -- Ключ для переключения UI

-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- GUI создание
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlightGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 320, 0, 200)
mainFrame.Position = UDim2.new(1, -340, 0.5, -100)
mainFrame.AnchorPoint = Vector2.new(1, 0.5)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.Visible = false

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

local noclipStatusLabel = Instance.new("TextLabel")
noclipStatusLabel.Parent = mainFrame
noclipStatusLabel.Size = UDim2.new(1, -12, 0, 25)
noclipStatusLabel.Position = UDim2.new(0, 6, 0, 70)
noclipStatusLabel.BackgroundTransparency = 1
noclipStatusLabel.Text = "Noclip: OFF (V)"
noclipStatusLabel.Font = Enum.Font.SourceSans
noclipStatusLabel.TextSize = 18
noclipStatusLabel.TextColor3 = Color3.fromRGB(200,200,200)
noclipStatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local sinkStatusLabel = Instance.new("TextLabel")
sinkStatusLabel.Parent = mainFrame
sinkStatusLabel.Size = UDim2.new(1, -12, 0, 25)
sinkStatusLabel.Position = UDim2.new(0, 6, 0, 98)
sinkStatusLabel.BackgroundTransparency = 1
sinkStatusLabel.Text = "Sink: OFF (G)"
sinkStatusLabel.Font = Enum.Font.SourceSans
sinkStatusLabel.TextSize = 18
sinkStatusLabel.TextColor3 = Color3.fromRGB(200,200,200)
sinkStatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local speedText = Instance.new("TextLabel")
speedText.Parent = mainFrame
speedText.Size = UDim2.new(1, -12, 0, 25)
speedText.Position = UDim2.new(0, 6, 0, 126)
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
sliderBackground.Position = UDim2.new(0, 10, 0, 156)
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

-- Кнопки для управления интерфейсом
local minimizeButton = Instance.new("TextButton")
minimizeButton.Parent = mainFrame
minimizeButton.Size = UDim2.new(0, 20, 0, 20)
minimizeButton.Position = UDim2.new(1, -26, 0, 6)
minimizeButton.BackgroundTransparency = 1
minimizeButton.Text = "-"
minimizeButton.Font = Enum.Font.SourceSans
minimizeButton.TextSize = 18
minimizeButton.TextColor3 = Color3.fromRGB(200,200,200)
minimizeButton.TextXAlignment = Enum.TextXAlignment.Center
minimizeButton.TextYAlignment = Enum.TextYAlignment.Center

local closeButton = Instance.new("TextButton")
closeButton.Parent = mainFrame
closeButton.Size = UDim2.new(0, 20, 0, 20)
closeButton.Position = UDim2.new(1, -56, 0, 6)
closeButton.BackgroundTransparency = 1
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSans
closeButton.TextSize = 18
closeButton.TextColor3 = Color3.fromRGB(200,200,200)
closeButton.TextXAlignment = Enum.TextXAlignment.Center
closeButton.TextYAlignment = Enum.TextYAlignment.Center

-- Вспомогательные переменные
local flying = false
local currentSpeed = DEFAULT_SPEED
local moveVector = Vector3.new(0,0,0)
local verticalInput = 0 -- -1 вниз, 0 нейтраль, 1 вверх
local sinking = false
local noclip = false

local character, humanoid, rootPart
local bodyVelocity, bodyGyro
local particle -- визуальная частица

-- Улучшенная система флая (микро-телепортации)
local lastPosition = nil
local teleportThreshold = 3 -- Максимальное расстояние за кадр (studs)
local flyConnection = nil

local function enableFlight()
    if not rootPart then return end
    clearFlightForces()
    
    lastPosition = rootPart.Position
    
    -- Используем BodyVelocity для плавности, но ограничиваем скорость
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000) -- Меньшая сила для меньшей скорости
    bodyVelocity.Velocity = Vector3.new(0,0,0)
    bodyVelocity.P = 500
    bodyVelocity.Parent = rootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.P = 500
    bodyGyro.Parent = rootPart

    -- Визуализация
    local emitter = Instance.new("ParticleEmitter")
    emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(1,0)})
    emitter.Speed = NumberRange.new(0, 0)
    emitter.Rate = 20
    emitter.Lifetime = NumberRange.new(0.3,0.5)
    emitter.VelocitySpread = 90
    emitter.Parent = rootPart
    particle = emitter
    
    -- Включаем систему микро-телепортации
    if flyConnection then
        flyConnection:Disconnect()
    end
    
    flyConnection = RunService.Heartbeat:Connect(function(dt)
        if not flying or not rootPart then return end
        
        local currentPos = rootPart.Position
        if lastPosition then
            local distance = (currentPos - lastPosition).Magnitude
            
            -- Если переместились слишком далеко, телепортируем обратно на маленькое расстояние
            if distance > teleportThreshold then
                local direction = (currentPos - lastPosition).Unit
                local newPos = lastPosition + direction * math.min(distance, teleportThreshold * 0.8)
                rootPart.CFrame = CFrame.new(newPos)
            else
                lastPosition = currentPos
            end
        else
            lastPosition = currentPos
        end
    end)
end

local function clearFlightForces()
    if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy() end
    if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy() end
    if particle and particle.Parent then particle:Destroy() end
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    bodyVelocity = nil
    bodyGyro = nil
    particle = nil
    lastPosition = nil
end

local function disableFlight()
    clearFlightForces()
    moveVector = Vector3.new(0,0,0)
    verticalInput = 0
end

-- Ноуклип функция
local noclipConnection = nil
local function toggleNoclip()
    noclip = not noclip
    
    if noclip then
        noclipStatusLabel.Text = "Noclip: ON (V)"
        noclipStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        -- Включаем ноуклип
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
        
        -- Следим за новыми частями
        if noclipConnection then
            noclipConnection:Disconnect()
        end
        noclipConnection = character.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end)
        
    else
        noclipStatusLabel.Text = "Noclip: OFF (V)"
        noclipStatusLabel.TextColor3 = Color3.fromRGB(200,200,200)
        
        -- Выключаем ноуклип
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Улучшенная функция синка (только для других игроков)
local originalPositions = {}
local sinkConnections = {}
local fakeParts = {}

local function sinkUnderground()
    if sinking then return end
    
    sinking = true
    sinkStatusLabel.Text = "Sink: ON (G)"
    sinkStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    
    -- Сохраняем оригинальные позиции всех игроков и перемещаем их под землю
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                originalPositions[player] = hrp.Position
                
                -- Создаем невидимую копию на оригинальной позиции
                local fakePart = Instance.new("Part")
                fakePart.Name = "FakePlayer_" .. player.Name
                fakePart.Anchored = true
                fakePart.CanCollide = false
                fakePart.Transparency = 1
                fakePart.Size = Vector3.new(4, 6, 2)
                fakePart.Position = hrp.Position
                fakePart.Parent = workspace
                fakeParts[player] = fakePart
                
                -- Перемещаем реального игрока глубоко под землю
                hrp.CFrame = CFrame.new(hrp.Position.X, -1000, hrp.Position.Z)
                
                -- Отключаем любые движения
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.PlatformStand = true
                end
            end
        end
    end
end

local function bringBackUp()
    if not sinking then return end
    
    sinking = false
    sinkStatusLabel.Text = "Sink: OFF (G)"
    sinkStatusLabel.TextColor3 = Color3.fromRGB(200,200,200)
    
    -- Возвращаем игроков на оригинальные позиции
    for player, originalPos in pairs(originalPositions) do
        if player and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            
            if hrp then
                hrp.CFrame = CFrame.new(originalPos)
            end
            
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end
    
    -- Убираем фейки
    for player, fakePart in pairs(fakeParts) do
        if fakePart and fakePart.Parent then
            fakePart:Destroy()
        end
    end
    
    originalPositions = {}
    fakeParts = {}
    
    -- Отключаем соединения
    for _, connection in pairs(sinkConnections) do
        connection:Disconnect()
    end
    sinkConnections = {}
end

-- Слежение за персонажем
local function setupCharacter(char)
    character = char
    humanoid = char:FindFirstChildOfClass("Humanoid")
    rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    
    -- Применяем ноуклип если он включен
    if noclip and character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
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
    
    local camCFrame = camera.CFrame
    local camForward = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
    if camForward ~= camForward then camForward = Vector3.new(0,0,-1) end
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
        statusLabel.TextColor3 = flying and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200,200,200)
        if flying then
            enableFlight()
        else
            disableFlight()
        end
    elseif input.KeyCode == NOCLIP_TOGGLE_KEY then
        toggleNoclip()
    elseif input.KeyCode == ASCEND_KEY then
        verticalInput = 1
    elseif input.KeyCode == DESCEND_KEY then
        verticalInput = -1
    elseif input.KeyCode == SINK_TOGGLE_KEY then
        if sinking then
            bringBackUp()
        else
            sinkUnderground()
        end
    elseif input.KeyCode == UI_TOGGLE_KEY then
        mainFrame.Visible = not mainFrame.Visible
    elseif input.KeyCode == Enum.KeyCode.W then
        keys.forward = true; updateMoveVector()
    elseif input.KeyCode == Enum.KeyCode.S then
        keys.backward = true; updateMoveVector()
    elseif input.KeyCode == Enum.KeyCode.A then
        keys.left = true; updateMoveVector()
    elseif input.KeyCode == Enum.KeyCode.D then
        keys.right = true; updateMoveVector()
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
    local minS, maxS = 10, 80  -- Ограниченная скорость для безопасности
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

-- Кнопки управления интерфейсом
minimizeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    disableFlight()
    bringBackUp()
    if noclipConnection then
        noclipConnection:Disconnect()
    end
end)

-- Обновление каждого кадра
RunService.Heartbeat:Connect(function(dt)
    if not localPlayer.Character or not localPlayer.Character.Parent then
        localPlayer.CharacterAdded:Wait()
        setupCharacter(localPlayer.Character)
    end

    if not character or not rootPart then
        setupCharacter(localPlayer.Character)
    end

    if flying and bodyVelocity and bodyGyro and rootPart then
        updateMoveVector()
        local targetVelocity = moveVector * currentSpeed
        
        -- Ограниченная вертикальная скорость
        local climbSpeed = 25
        local verticalVel = verticalInput * climbSpeed
        
        -- Плавное изменение скорости
        local curVel = bodyVelocity.Velocity
        local desired = Vector3.new(targetVelocity.X, verticalVel, targetVelocity.Z)
        local t = math.clamp(ACCELERATION * dt, 0, 1)
        local newVel = curVel:Lerp(desired, t)
        
        bodyVelocity.Velocity = Vector3.new(newVel.X, newVel.Y, newVel.Z)

        -- Плавный поворот
        local lookAt = camera.CFrame.LookVector
        local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + lookAt)
        bodyGyro.CFrame = rootPart.CFrame:Lerp(targetCFrame, 0.15)
    end
end)

-- Подключение к CharacterAdded/Removing
local function onCharacterAdded(char)
    setupCharacter(char)
    statusLabel.Text = "Flight: " .. (flying and "ON" or "OFF") .. " (F)"
    statusLabel.TextColor3 = flying and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200,200,200)
    
    if noclip then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)
if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

localPlayer.CharacterRemoving:Connect(function()
    disableFlight()
end)

-- Дополнительно: quick hint
local hint = Instance.new("TextLabel")
hint.Parent = mainFrame
hint.Size = UDim2.new(1, -12, 0, 12)
hint.Position = UDim2.new(0, 6, 1, -16)
hint.BackgroundTransparency = 1
hint.Text = "W/A/S/D + Space/Shift, F - flight, V - noclip, G - sink others, RightShift - UI"
hint.Font = Enum.Font.SourceSans
hint.TextSize = 12
hint.TextColor3 = Color3.fromRGB(170,170,170)
hint.TextXAlignment = Enum.TextXAlignment.Left

-- Инициализация: slider default position
local defaultScale = (DEFAULT_SPEED - 10) / (80 - 10)
sliderFill.Size = UDim2.new(defaultScale, 0, 1, 0)
sliderHandle.Position = UDim2.new(defaultScale, 0, 0, 0)

print("Flight script loaded! Press RightShift to toggle UI")
