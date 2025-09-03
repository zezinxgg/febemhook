
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local WatermarkLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/AxerRe/ProSite/refs/heads/main/views/Axrewatermark.lib"))()
local Window = Fluent:CreateWindow({
    Title = "febemhook " .. Fluent.Version,
    SubTitle = "private cheat",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Rage = Window:AddTab({ Title = "Rage", Icon = "locate-fixed" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "move" }),
    Mods = Window:AddTab({ Title = "Mods", Icon = "rocket" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

WatermarkLib:Create({
    Hotkey = Enum.KeyCode.Home,
    CustomText = "febemhook | {FPS} fps | priv cheat"
})

local Main = Tabs.Main
local Rage = Tabs.Rage
local Movement = Tabs.Movement

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

-- Services para Movement
local tweenService = game:GetService("TweenService")

local espSettings = {
    boxEnabled = false,
    boxFillEnabled = false,
    fillColor = Color3.fromRGB(96, 205, 255),
    fillTransparency = 0.5,
    healthBarEnabled = false,
    nameEnabled = false,
    distanceEnabled = false,
    headEspEnabled = false,
    crosshairEnabled = false,
    crosshairColor = Color3.fromRGB(96, 205, 255),
    crosshairSize = 24,
    crosshairThickness = 2,
    crosshairAnimSpeed = 2,
    teamCheck = false,
    maxDistance = 500,
}

local aimbotSettings = {
    enabled = false,
    fovEnabled = false,
    fov = 120,
    fovColor = Color3.fromRGB(255, 255, 255),
    smoothness = 10,
    lockOnTarget = false,
    teamCheck = false,
    visibleCheck = true,
    maxDistance = 500,
    visibilityAccuracy = 0.25,
    multiPointCheck = true,
}

-- Enhanced Third Person Settings
local thirdPersonSettings = {
    enabled = false,
    distance = 10,
    height = 5,
    sensitivity = 2,
    smoothing = 0.1,
    collisionDetection = true,
    autoRotate = true,
    lockY = false,
    angle = {x = 0, y = 0}
}

-- Movement Settings
local movementSettings = {
    flyEnabled = false,
    flySpeed = 15,
    noclipEnabled = false,
    jumpFakeEnabled = false,
    jumpFakeSpeed = 50,
    jumpFakeHeight = 7.5,
    bhopEnabled = false
}

-- Cache para otimização do visible check
local visibilityCache = {}
local cacheTimeout = 0.1

local function newDrawing(type)
    return Drawing.new(type)
end

local function round(...)
    local a = {}; for i,v in next, table.pack(...) do a[i] = math.round(v); end return unpack(a);
end

local function wtvp(...)
    local a, b = camera:WorldToViewportPoint(...)
    return Vector2.new(a.X, a.Y), b, a.Z
end

local espCache = {}

local function createEsp(player)
    local drawings = {}

    -- Box
    drawings.box = newDrawing("Square")
    drawings.box.Thickness = 1
    drawings.box.Filled = false
    drawings.box.Color = espSettings.fillColor
    drawings.box.Visible = false
    drawings.box.ZIndex = 2

    -- Box Fill
    drawings.boxfill = newDrawing("Square")
    drawings.boxfill.Thickness = 0
    drawings.boxfill.Filled = true
    drawings.boxfill.Color = espSettings.fillColor
    drawings.boxfill.Visible = false
    drawings.boxfill.Transparency = espSettings.fillTransparency
    drawings.boxfill.ZIndex = 0

    -- Health bar
    drawings.healthbar = newDrawing("Square")
    drawings.healthbar.Thickness = 0
    drawings.healthbar.Filled = true
    drawings.healthbar.Color = Color3.fromRGB(0,255,0)
    drawings.healthbar.Visible = false
    drawings.healthbar.ZIndex = 10

    -- Head ESP Circle
    drawings.headcircle = newDrawing("Circle")
    drawings.headcircle.Thickness = 2
    drawings.headcircle.Filled = false
    drawings.headcircle.Color = espSettings.fillColor
    drawings.headcircle.Visible = false
    drawings.headcircle.ZIndex = 5

    -- Name ESP
    drawings.nametext = newDrawing("Text")
    drawings.nametext.Size = 17
    drawings.nametext.Center = true
    drawings.nametext.Outline = true
    drawings.nametext.Font = 2
    drawings.nametext.Color = Color3.fromRGB(255,255,255)
    drawings.nametext.Visible = false
    drawings.nametext.ZIndex = 10

    -- Distance ESP
    drawings.disttext = newDrawing("Text")
    drawings.disttext.Size = 15
    drawings.disttext.Center = true
    drawings.disttext.Outline = true
    drawings.disttext.Font = 2
    drawings.disttext.Color = Color3.fromRGB(255,255,0)
    drawings.disttext.Visible = false
    drawings.disttext.ZIndex = 10

    espCache[player] = drawings
end

-- // Serviços
local wsp = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

local freeCamSettings = {
    enabled = false,
    speed = 50, -- Velocidade de movimento
    partName = "FreeCamPart"
}

local freeCamPart = nil
local freeCamConnection = nil
local moveDirection = Vector3.new(0, 0, 0)
local savedPosition = nil

local inputBeganConn, inputEndedConn

-- Ativa FreeCam
local function enableFreeCam()
    if freeCamConnection then return end
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    moveDirection = Vector3.new(0,0,0) -- sempre reseta

    -- Salva posição inicial
    savedPosition = localPlayer.Character.HumanoidRootPart.CFrame

    -- Manda player bem pra baixo do mapa
    localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(savedPosition.Position - Vector3.new(0, 1000, 0))

    -- Cria part da câmera
    freeCamPart = Instance.new("Part")
    freeCamPart.Name = freeCamSettings.partName
    freeCamPart.Anchored = true
    freeCamPart.CanCollide = false
    freeCamPart.Transparency = 1
    freeCamPart.Size = Vector3.new(2, 2, 2)
    freeCamPart.CFrame = wsp.CurrentCamera.CFrame
    freeCamPart.Parent = wsp

    wsp.CurrentCamera.CameraSubject = freeCamPart

    -- Conexões de input (garante que só cria uma vez)
    inputBeganConn = UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.W then moveDirection = moveDirection + Vector3.new(0,0,-1) end
        if input.KeyCode == Enum.KeyCode.S then moveDirection = moveDirection + Vector3.new(0,0,1) end
        if input.KeyCode == Enum.KeyCode.A then moveDirection = moveDirection + Vector3.new(-1,0,0) end
        if input.KeyCode == Enum.KeyCode.D then moveDirection = moveDirection + Vector3.new(1,0,0) end
        if input.KeyCode == Enum.KeyCode.Space then moveDirection = moveDirection + Vector3.new(0,1,0) end
        if input.KeyCode == Enum.KeyCode.LeftShift then moveDirection = moveDirection + Vector3.new(0,-1,0) end
    end)

    inputEndedConn = UIS.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.W then moveDirection = moveDirection - Vector3.new(0,0,-1) end
        if input.KeyCode == Enum.KeyCode.S then moveDirection = moveDirection - Vector3.new(0,0,1) end
        if input.KeyCode == Enum.KeyCode.A then moveDirection = moveDirection - Vector3.new(-1,0,0) end
        if input.KeyCode == Enum.KeyCode.D then moveDirection = moveDirection - Vector3.new(1,0,0) end
        if input.KeyCode == Enum.KeyCode.Space then moveDirection = moveDirection - Vector3.new(0,1,0) end
        if input.KeyCode == Enum.KeyCode.LeftShift then moveDirection = moveDirection - Vector3.new(0,-1,0) end
    end)

    -- Loop de movimento da câmera
    freeCamConnection = RunService.RenderStepped:Connect(function(deltaTime)
        if freeCamPart then
            local move = wsp.CurrentCamera.CFrame:VectorToWorldSpace(moveDirection) * freeCamSettings.speed * deltaTime
            freeCamPart.CFrame = freeCamPart.CFrame + move
        end
    end)
end

-- Desativa FreeCam
local function disableFreeCam()
    if freeCamConnection then
        freeCamConnection:Disconnect()
        freeCamConnection = nil
    end
    if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn = nil end
    if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn = nil end
    moveDirection = Vector3.new(0,0,0)

    if freeCamPart then
        freeCamPart:Destroy()
        freeCamPart = nil
    end

    -- Volta player
    if savedPosition and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        localPlayer.Character.HumanoidRootPart.CFrame = savedPosition
    end

    -- Volta câmera pro player
    if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
        wsp.CurrentCamera.CameraSubject = localPlayer.Character.Humanoid
    end
end



local function removeEsp(player)
    if rawget(espCache, player) then
        for _, drawing in next, espCache[player] do
            drawing:Remove()
        end
        espCache[player] = nil
    end
end

local function hideAllDrawings(esp)
    for _, d in pairs(esp) do
        d.Visible = false
    end
end

local function isValidEspTarget(player)
    if player == localPlayer then return false end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    
    if espSettings.teamCheck then
        if player.Team and localPlayer.Team and player.Team == localPlayer.Team then
            return false
        end
        if player.TeamColor == localPlayer.TeamColor then
            return false
        end
    end
    
    return true
end

local function isValidAimbotTarget(player)
    if player == localPlayer then return false end
    if not player.Character or not player.Character:FindFirstChild("Head") then return false end
    
    if aimbotSettings.teamCheck then
        if player.Team and localPlayer.Team and player.Team == localPlayer.Team then
            return false
        end
        if player.TeamColor == localPlayer.TeamColor then
            return false
        end
    end
    
    return true
end

local function getHeadPosition(character)
    local head = character:FindFirstChild("Head")
    return head and head.Position or nil
end

local function updateEsp(player, esp)
    local character = player and player.Character
    if not isValidEspTarget(player) then
        hideAllDrawings(esp)
        return
    end

    local localChar = localPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
        hideAllDrawings(esp)
        return
    end

    local dist = (localChar.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
    if dist > espSettings.maxDistance then
        hideAllDrawings(esp)
        return
    end

    local cframe = character:GetModelCFrame()
    local position, visible, depth = wtvp(cframe.Position)
    if not visible then
        hideAllDrawings(esp)
        return
    end

    local scaleFactor = 1 / (depth * math.tan(math.rad(camera.FieldOfView / 2)) * 2) * 1000
    local width, height = round(4 * scaleFactor, 5 * scaleFactor)
    local x, y = round(position.X, position.Y)
    local boxPos = Vector2.new(round(x - width / 2, y - height / 2))

    -- Box Fill
    esp.boxfill.Visible = espSettings.boxFillEnabled
    esp.boxfill.Size = Vector2.new(width, height)
    esp.boxfill.Position = boxPos
    esp.boxfill.Color = espSettings.fillColor
    esp.boxfill.Transparency = espSettings.fillTransparency

    -- Box
    esp.box.Visible = espSettings.boxEnabled
    esp.box.Size = Vector2.new(width, height)
    esp.box.Position = boxPos
    esp.box.Color = espSettings.fillColor

    -- Head ESP Circle
    esp.headcircle.Visible = espSettings.headEspEnabled
    if espSettings.headEspEnabled then
        local headPos = getHeadPosition(character)
        if headPos then
            local headScreenPos, headVisible = wtvp(headPos)
            if headVisible then
                local headRadius = scaleFactor * 1.5
                esp.headcircle.Position = Vector2.new(headScreenPos.X, headScreenPos.Y)
                esp.headcircle.Radius = headRadius
                esp.headcircle.Color = espSettings.fillColor
            else
                esp.headcircle.Visible = false
            end
        end
    end

    -- Health Bar
    esp.healthbar.Visible = espSettings.healthBarEnabled
    if espSettings.healthBarEnabled then
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        local hp = humanoid and humanoid.Health or 0
        local mhp = humanoid and humanoid.MaxHealth or 100
        local percent = math.clamp(hp / mhp, 0, 1)
        local barH = height * percent
        local barW = 4
        local barX = boxPos.X - barW - 2
        local barY = boxPos.Y + height - barH
        esp.healthbar.Size = Vector2.new(barW, barH)
        esp.healthbar.Position = Vector2.new(barX, barY)
        esp.healthbar.Color = Color3.fromRGB(255 - math.floor(255*percent), math.floor(255*percent), 0)
    end

    -- Name ESP
    esp.nametext.Visible = espSettings.nameEnabled
    if espSettings.nameEnabled then
        esp.nametext.Text = player.Name
        esp.nametext.Position = Vector2.new(x, boxPos.Y - 16)
        esp.nametext.Color = Color3.fromRGB(255,255,255)
    end

    -- Distance ESP
    esp.disttext.Visible = espSettings.distanceEnabled
    if espSettings.distanceEnabled then
        esp.disttext.Text = tostring(math.floor(dist)).."m"
        esp.disttext.Position = Vector2.new(x, boxPos.Y + height + 12)
        esp.disttext.Color = Color3.fromRGB(255,255,0)
    end
end

-- Crosshair Drawing
local crosshair = {
    lines = {},
    rotation = 0,
}

local function createCrosshair()
    crosshair.lines = {}
    for i = 1, 4 do
        local line = newDrawing("Line")
        line.Thickness = espSettings.crosshairThickness
        line.Color = espSettings.crosshairColor
        line.Visible = false
        line.ZIndex = 999
        table.insert(crosshair.lines, line)
    end
end

local function updateCrosshair(targetPos)
    if not espSettings.crosshairEnabled then
        for _, line in ipairs(crosshair.lines) do
            line.Visible = false
        end
        return
    end
    
    local res = camera.ViewportSize
    local cx, cy = res.X/2, res.Y/2
    
    if aimbotSettings.enabled and aimbotSettings.lockOnTarget and targetPos then
        cx, cy = targetPos.X, targetPos.Y
    end
    
    local len = espSettings.crosshairSize
    local rot = crosshair.rotation
    local pi2 = math.pi*2

    for i, line in ipairs(crosshair.lines) do
        line.Visible = true
        line.Thickness = espSettings.crosshairThickness
        line.Color = espSettings.crosshairColor

        local angle = rot + ((i-1)*pi2)/4
        local sx = cx + math.cos(angle)*len
        local sy = cy + math.sin(angle)*len
        local ex = cx + math.cos(angle)*(len/2)
        local ey = cy + math.sin(angle)*(len/2)
        line.From = Vector2.new(sx, sy)
        line.To = Vector2.new(ex, ey)
    end
end

-- FOV Circle
local fovCircle = newDrawing("Circle")
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Color = aimbotSettings.fovColor
fovCircle.Visible = false
fovCircle.ZIndex = 1

local function updateFovCircle()
    if aimbotSettings.fovEnabled then
        local res = camera.ViewportSize
        fovCircle.Position = Vector2.new(res.X/2, res.Y/2)
        fovCircle.Radius = aimbotSettings.fov
        fovCircle.Color = aimbotSettings.fovColor
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end

-- Sistema de Visible Check Melhorado
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true
raycastParams.RespectCanCollide = true

local function isPlayerVisible(targetPlayer)
    if not aimbotSettings.visibleCheck then
        return true
    end
    
    local localChar = localPlayer.Character
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local targetChar = targetPlayer.Character
    if not targetChar or not targetChar:FindFirstChild("Head") then
        return false
    end
    
    -- Verificar cache primeiro
    local cacheKey = targetPlayer.UserId
    local currentTime = tick()
    if visibilityCache[cacheKey] and 
       visibilityCache[cacheKey].time + cacheTimeout > currentTime then
        return visibilityCache[cacheKey].visible
    end
    
    local checkPoints = {}
    
    if aimbotSettings.multiPointCheck then
        -- Múltiplos pontos de verificação para melhor precisão
        checkPoints = {
            targetChar.Head.Position, -- Cabeça
            targetChar.HumanoidRootPart.Position, -- Torso
            targetChar.HumanoidRootPart.Position + Vector3.new(0, 1, 0), -- Peito
            targetChar.HumanoidRootPart.Position + Vector3.new(0, -1, 0), -- Cintura
        }
    else
        -- Apenas verificar a cabeça para melhor performance
        checkPoints = {targetChar.Head.Position}
    end
    
    -- Múltiplos pontos de origem da câmera
    local cameraOrigins = {
        camera.CFrame.Position,
        camera.CFrame.Position + camera.CFrame.LookVector * 2,
    }
    
    -- Filtros para raycast
    local ignoreList = {localChar}
    
    -- Adicionar acessórios à lista de ignorados
    for _, accessory in pairs(localChar:GetChildren()) do
        if accessory:IsA("Accessory") then
            table.insert(ignoreList, accessory)
        end
    end
    
    -- Adicionar ferramenta equipada se existir
    local tool = localChar:FindFirstChildOfClass("Tool")
    if tool then
        table.insert(ignoreList, tool)
    end
    
    raycastParams.FilterDescendantsInstances = ignoreList
    
    local visibleCount = 0
    local totalChecks = 0
    
    -- Verificar visibilidade de múltiplos pontos
    for _, origin in pairs(cameraOrigins) do
        for _, targetPos in pairs(checkPoints) do
            totalChecks = totalChecks + 1
            
            local direction = (targetPos - origin)
            local distance = direction.Magnitude
            local unitDirection = direction.Unit
            
            local raycastResult = workspace:Raycast(origin, unitDirection * distance, raycastParams)
            
            if not raycastResult then
                visibleCount = visibleCount + 1
            else
                local hitPart = raycastResult.Instance
                if hitPart and (hitPart.Parent == targetChar or hitPart.Parent.Parent == targetChar) then
                    visibleCount = visibleCount + 1
                end
            end
        end
    end
    
    -- Considerar visível baseado na precisão configurada
    local isVisible = (visibleCount / totalChecks) >= aimbotSettings.visibilityAccuracy
    
    -- Atualizar cache
    visibilityCache[cacheKey] = {
        visible = isVisible,
        time = currentTime
    }
    
    return isVisible
end

-- Aimbot Functions
local currentTarget = nil

local function getClosestPlayerToCenter()
    local closestPlayer = nil
    local closestDistance = math.huge
    local screenCenter = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    local localChar = localPlayer.Character
    
    if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return nil end

    for _, player in pairs(players:GetPlayers()) do
        if isValidAimbotTarget(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                -- Checagem de distância
                local dist = (localChar.HumanoidRootPart.Position - head.Position).Magnitude
                if dist > aimbotSettings.maxDistance then
                    continue
                end

                -- Checagem de visibilidade melhorada
                if not isPlayerVisible(player) then
                    continue
                end

                local headPos, visible = wtvp(head.Position)
                if visible then
                    local distanceOnScreen = (screenCenter - headPos).Magnitude
                    if distanceOnScreen <= aimbotSettings.fov and distanceOnScreen < closestDistance then
                        closestDistance = distanceOnScreen
                        closestPlayer = player
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function aimAtTarget(target)
    if not target or not target.Character then return end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    local headPos, visible = wtvp(head.Position)
    if not visible then return end
    
    local cameraCFrame = camera.CFrame
    local targetPosition = head.Position
    local cameraPosition = cameraCFrame.Position
    
    local newCFrame = CFrame.lookAt(cameraPosition, targetPosition)
    
    -- Smooth interpolation
    local smoothFactor = math.clamp(1 - (aimbotSettings.smoothness / 100), 0.01, 1)
    camera.CFrame = cameraCFrame:Lerp(newCFrame, 1 - smoothFactor)
    
    return headPos
end

-- ENHANCED THIRD PERSON SYSTEM
local thirdPersonConn = nil
local thirdPersonPart = nil
local mouseConn = nil
local originalCameraCFrame = nil

local function raycastForCollision(origin, direction, distance)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localPlayer.Character}
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction * distance, raycastParams)
    return result
end

local function updateThirdPerson()
    local character = localPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local humanoidRootPart = character.HumanoidRootPart
    local currentCFrame = humanoidRootPart.CFrame
    
    -- Calcular posição da câmera baseada nos ângulos
    local yaw = math.rad(thirdPersonSettings.angle.y)
    local pitch = math.rad(math.clamp(thirdPersonSettings.angle.x, -80, 80))
    
    local distance = thirdPersonSettings.distance
    
    -- Se collision detection estiver ativado, verificar obstáculos
    if thirdPersonSettings.collisionDetection then
        local direction = Vector3.new(
            math.sin(yaw) * math.cos(pitch),
            math.sin(pitch),
            math.cos(yaw) * math.cos(pitch)
        )
        
        local rayResult = raycastForCollision(
            currentCFrame.Position + Vector3.new(0, thirdPersonSettings.height, 0),
            direction,
            distance
        )
        
        if rayResult then
            distance = math.max(rayResult.Distance - 1, 2)
        end
    end
    
    -- Calcular posição final da câmera
    local cameraOffset = Vector3.new(
        math.sin(yaw) * math.cos(pitch) * distance,
        math.sin(pitch) * distance + thirdPersonSettings.height,
        math.cos(yaw) * math.cos(pitch) * distance
    )
    
    local targetCFrame = CFrame.lookAt(
        currentCFrame.Position + cameraOffset,
        currentCFrame.Position + Vector3.new(0, thirdPersonSettings.height, 0)
    )
    
    -- Aplicar suavização
    if originalCameraCFrame then
        camera.CFrame = originalCameraCFrame:Lerp(targetCFrame, thirdPersonSettings.smoothing)
    else
        camera.CFrame = targetCFrame
    end
    
    originalCameraCFrame = camera.CFrame
end

local function enableThirdPerson()
    if thirdPersonConn then return end
    
    -- Conectar ao mouse para controles
    mouseConn = userInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Delta
            thirdPersonSettings.angle.y = thirdPersonSettings.angle.y + (delta.X * thirdPersonSettings.sensitivity * 0.1)
            thirdPersonSettings.angle.x = thirdPersonSettings.angle.x - (delta.Y * thirdPersonSettings.sensitivity * 0.1)
            
            -- Limitar pitch para evitar flip da câmera
            thirdPersonSettings.angle.x = math.clamp(thirdPersonSettings.angle.x, -80, 80)
        end
    end)
    
    thirdPersonConn = runService.RenderStepped:Connect(updateThirdPerson)
    originalCameraCFrame = camera.CFrame
end

local function disableThirdPerson()
    if thirdPersonConn then
        thirdPersonConn:Disconnect()
        thirdPersonConn = nil
    end
    
    if mouseConn then
        mouseConn:Disconnect()
        mouseConn = nil
    end
    
    -- Resetar câmera para primeira pessoa
    if localPlayer.Character and localPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
        camera.CameraSubject = localPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        camera.CameraType = Enum.CameraType.Custom
    end
    
    originalCameraCFrame = nil
end

-- MOVEMENT SYSTEMS
local flyBodyVelocity = nil
local flyBodyAngularVelocity = nil
local flyConnection = nil
local noclipConnection = nil
local jumpFakeConnection = nil

-- FLY SYSTEM
local function enableFly()
    local character = localPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local humanoidRootPart = character.HumanoidRootPart
    
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = humanoidRootPart
    
    flyBodyAngularVelocity = Instance.new("BodyAngularVelocity")
    flyBodyAngularVelocity.MaxTorque = Vector3.new(0, math.huge, 0)
    flyBodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    flyBodyAngularVelocity.Parent = humanoidRootPart
    
    flyConnection = runService.RenderStepped:Connect(function()
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            local moveVector = humanoid.MoveDirection
            local cameraDirection = camera.CFrame.LookVector
            local cameraRight = camera.CFrame.RightVector
            
            local velocity = Vector3.new(0, 0, 0)
            
            -- Movimento baseado na direção da câmera
            if moveVector.Magnitude > 0 then
                velocity = velocity + (cameraDirection * moveVector.Z + cameraRight * moveVector.X) * movementSettings.flySpeed
            end
            
            -- Controles de subir/descer
            if userInputService:IsKeyDown(Enum.KeyCode.Space) then
                velocity = velocity + Vector3.new(0, movementSettings.flySpeed, 0)
            end
            if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                velocity = velocity - Vector3.new(0, movementSettings.flySpeed, 0)
            end
            
            flyBodyVelocity.Velocity = velocity
        end
    end)
end

local function disableFly()
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    
    if flyBodyAngularVelocity then
        flyBodyAngularVelocity:Destroy()
        flyBodyAngularVelocity = nil
    end
    
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
end

-- NOCLIP SYSTEM
local function enableNoclip()
    noclipConnection = runService.Stepped:Connect(function()
        local character = localPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    -- Restaurar colisão
    local character = localPlayer.Character
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

-- JUMP FAKE/BHOP SYSTEM
local bhopVelocity = nil
local jumpCount = 0
local lastJumpTime = 0

local function enableJumpFake()
    jumpFakeConnection = runService.RenderStepped:Connect(function()
        local character = localPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local humanoidRootPart = character.HumanoidRootPart
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        
        if humanoid and humanoid.MoveDirection.Magnitude > 0 then
            local currentTime = tick()
            
            -- Bhop automático
            if currentTime - lastJumpTime > (1 / movementSettings.jumpFakeSpeed) then
                lastJumpTime = currentTime
                jumpCount = jumpCount + 1
                
                -- Criar efeito de jump prediction/fake
                if not bhopVelocity then
                    bhopVelocity = Instance.new("BodyVelocity")
                    bhopVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                    bhopVelocity.Parent = humanoidRootPart
                end
                
                -- Calcular direção do movimento
                local moveDirection = humanoid.MoveDirection
                local cameraLook = camera.CFrame.LookVector
                local cameraRight = camera.CFrame.RightVector
                
                local forwardVelocity = (cameraLook * moveDirection.Z + cameraRight * moveDirection.X)
                forwardVelocity = Vector3.new(forwardVelocity.X, 0, forwardVelocity.Z).Unit
                
                -- Aplicar velocidade com efeito jump
                local jumpHeight = movementSettings.jumpFakeHeight + math.sin(jumpCount * 0.5) * 2
                local horizontalSpeed = movementSettings.jumpFakeSpeed * 0.5
                
                bhopVelocity.Velocity = Vector3.new(
                    forwardVelocity.X * horizontalSpeed,
                    jumpHeight,
                    forwardVelocity.Z * horizontalSpeed
                )
                
                -- Remover velocidade após curto período
                spawn(function()
                    wait(0.1)
                    if bhopVelocity then
                        bhopVelocity.Velocity = Vector3.new(0, 0, 0)
                    end
                end)
            end
        else
            -- Parar bhop quando não estiver se movendo
            if bhopVelocity then
                bhopVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end

local function disableJumpFake()
    if jumpFakeConnection then
        jumpFakeConnection:Disconnect()
        jumpFakeConnection = nil
    end
    
    if bhopVelocity then
        bhopVelocity:Destroy()
        bhopVelocity = nil
    end
    
    jumpCount = 0
    lastJumpTime = 0
end

createCrosshair()

-- Inicializar ESP para todos jogadores
for _, player in next, players:GetPlayers() do
    if player ~= localPlayer then
        createEsp(player)
    end
end

players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        createEsp(player)
    end
end)

players.PlayerRemoving:Connect(function(player)
    removeEsp(player)
    -- Limpar cache de visibilidade
    if visibilityCache[player.UserId] then
        visibilityCache[player.UserId] = nil
    end
end)

local targetHeadPos = nil

-- Sistema de limpeza do cache para otimização
spawn(function()
    while true do
        wait(5)
        local currentTime = tick()
        for key, data in pairs(visibilityCache) do
            if data.time + 5 < currentTime then
                visibilityCache[key] = nil
            end
        end
    end
end)

-- Loop principal
runService:BindToRenderStep("AimbotEspUpdate", Enum.RenderPriority.Camera.Value + 1, function(dt)
    for player, drawings in next, espCache do
        if player ~= localPlayer then
            updateEsp(player, drawings)
        end
    end
    
    -- Aimbot Logic
    if aimbotSettings.enabled then
        currentTarget = getClosestPlayerToCenter()
        if currentTarget then
            aimbotSettings.lockOnTarget = true
            targetHeadPos = aimAtTarget(currentTarget)
        else
            aimbotSettings.lockOnTarget = false
            targetHeadPos = nil
        end
    else
        aimbotSettings.lockOnTarget = false
        currentTarget = nil
        targetHeadPos = nil
    end
    
    crosshair.rotation = (crosshair.rotation + espSettings.crosshairAnimSpeed*dt) % (math.pi*2)
    updateCrosshair(targetHeadPos)
    updateFovCircle()
end)

-- MENU FLUENT - VISUALS TAB
Main:AddToggle("Box", {
    Title = "ESP Box",
    Description = "Ativa/desativa o box ESP",
    Default = false,
    Callback = function(state)
        espSettings.boxEnabled = state
    end
})

Main:AddToggle("Box Fill", {
    Title = "Box Fill",
    Description = "Preenche o box do ESP com transparência",
    Default = false,
    Callback = function(state)
        espSettings.boxFillEnabled = state
    end
})

Main:AddToggle("Health Bar", {
    Title = "Health Bar",
    Description = "Barra de vida lateral",
    Default = false,
    Callback = function(state)
        espSettings.healthBarEnabled = state
    end
})

Main:AddToggle("Head ESP", {
    Title = "Head ESP",
    Description = "Círculo na cabeça do player",
    Default = false,
    Callback = function(state)
        espSettings.headEspEnabled = state
    end
})

Main:AddToggle("Name ESP", {
    Title = "Name ESP",
    Description = "Mostra o nome do player",
    Default = false,
    Callback = function(state)
        espSettings.nameEnabled = state
    end
})

Main:AddToggle("Distance ESP", {
    Title = "Distance ESP",
    Description = "Mostra a distância até o player",
    Default = false,
    Callback = function(state)
        espSettings.distanceEnabled = state
    end
})

Main:AddToggle("Crosshair", {
    Title = "Crosshair",
    Description = "Crosshair animada no centro da tela",
    Default = false,
    Callback = function(state)
        espSettings.crosshairEnabled = state
    end
})

Main:AddSlider("ESPDistance", {
    Title = "Distância Máxima (ESP)",
    Description = "Distância máxima para o ESP aparecer",
    Default = espSettings.maxDistance,
    Min = 50,
    Max = 2000,
    Rounding = 0,
    Callback = function(val)
        espSettings.maxDistance = val
    end
})

Main:AddColorpicker("BoxFillColor", {
    Title = "Cor do ESP",
    Description = "Cor do box e do preenchimento do ESP",
    Default = Color3.fromRGB(96, 205, 255),
    Callback = function(color)
        espSettings.fillColor = color
        for _, drawings in pairs(espCache) do
            if drawings.box then drawings.box.Color = color end
            if drawings.boxfill then drawings.boxfill.Color = color end
            if drawings.headcircle then drawings.headcircle.Color = color end
        end
    end
})

Main:AddSlider("FillTransparency", {
    Title = "Transparência do Fill",
    Description = "0 = opaco, 1 = invisível",
    Default = espSettings.fillTransparency,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(val)
        espSettings.fillTransparency = val
        for _, drawings in pairs(espCache) do
            if drawings.boxfill then
                drawings.boxfill.Transparency = val
            end
        end
    end
})

Main:AddColorpicker("CrosshairColor", {
    Title = "Cor do Crosshair",
    Description = "Personalize a cor do crosshair",
    Default = Color3.fromRGB(96,205,255),
    Callback = function(color)
        espSettings.crosshairColor = color
        for _, line in ipairs(crosshair.lines) do
            line.Color = color
        end
    end
})

Main:AddSlider("CrosshairSize", {
    Title = "Tamanho do Crosshair",
    Description = "Personalize o tamanho do crosshair",
    Default = espSettings.crosshairSize,
    Min = 8,
    Max = 64,
    Rounding = 0,
    Callback = function(val)
        espSettings.crosshairSize = val
    end
})

Main:AddSlider("CrosshairThickness", {
    Title = "Espessura do Crosshair",
    Description = "Personalize a espessura do crosshair",
    Default = espSettings.crosshairThickness,
    Min = 1,
    Max = 8,
    Rounding = 0,
    Callback = function(val)
        espSettings.crosshairThickness = val
    end
})

Main:AddSlider("CrosshairAnimSpeed", {
    Title = "Velocidade de rotação do Crosshair",
    Description = "Personalize a velocidade da animação",
    Default = espSettings.crosshairAnimSpeed,
    Min = 0,
    Max = 8,
    Rounding = 2,
    Callback = function(val)
        espSettings.crosshairAnimSpeed = val
    end
})

Main:AddToggle("Team Check", {
    Title = "Team Check (ESP)",
    Description = "Não mostra ESP em players do mesmo time",
    Default = false,
    Callback = function(state)
        espSettings.teamCheck = state
        for player, drawings in pairs(espCache) do
            if player ~= localPlayer then
                updateEsp(player, drawings)
            end
        end
    end
})

-- RAGE TAB


Rage:AddToggle("Aimbot", {
    Title = "Aimbot",
    Description = "Aimbot automático na cabeça do player mais próximo",
    Default = false,
    Callback = function(state)
        aimbotSettings.enabled = state
    end
})

Rage:AddToggle("Visible Check", {
    Title = "Visible Check",
    Description = "Aimbot só mira em players visíveis",
    Default = true,
    Callback = function(state)
        aimbotSettings.visibleCheck = state
        visibilityCache = {}
    end
})

Rage:AddToggle("Multi Point Check", {
    Title = "Multi Point Check",
    Description = "Verificação de visibilidade em múltiplos pontos (mais preciso, mas usa mais CPU)",
    Default = true,
    Callback = function(state)
        aimbotSettings.multiPointCheck = state
        visibilityCache = {}
    end
})

Rage:AddToggle("FOV Show", {
    Title = "FOV Show",
    Description = "Mostra o círculo do campo de visão do aimbot",
    Default = false,
    Callback = function(state)
        aimbotSettings.fovEnabled = state
    end
})

Rage:AddSlider("AimbotDistance", {
    Title = "Distância Máxima (Aimbot)",
    Description = "Distância máxima para o aimbot funcionar",
    Default = aimbotSettings.maxDistance,
    Min = 50,
    Max = 2000,
    Rounding = 0,
    Callback = function(val)
        aimbotSettings.maxDistance = val
    end
})

Rage:AddSlider("FOV Size", {
    Title = "FOV Size",
    Description = "Tamanho do campo de visão do aimbot",
    Default = aimbotSettings.fov,
    Min = 30,
    Max = 500,
    Rounding = 0,
    Callback = function(val)
        aimbotSettings.fov = val
    end
})

Rage:AddColorpicker("FOV Color", {
    Title = "Cor do FOV",
    Description = "Cor do círculo FOV",
    Default = Color3.fromRGB(255,255,255),
    Callback = function(color)
        aimbotSettings.fovColor = color
        fovCircle.Color = color
    end
})

Rage:AddSlider("Aimbot Smoothness", {
    Title = "Suavidade do Aimbot",
    Description = "Quanto menor, mais rápido o aimbot. (0 = instantâneo)",
    Default = aimbotSettings.smoothness,
    Min = 0,
    Max = 99,
    Rounding = 1,
    Callback = function(val)
        aimbotSettings.smoothness = val
    end
})

Rage:AddToggle("Team Check", {
    Title = "Team Check (Aimbot)",
    Description = "Não mira em players do mesmo time",
    Default = false,
    Callback = function(state)
        aimbotSettings.teamCheck = state
    end
})

-- MOVEMENT TAB: Fly, Noclip, Jump Fake
Movement:AddToggle("Fly (!)", {
    Title = "Fly",
    Description = "Permite voar usando WASD + Space/Shift",
    Default = false,
    Callback = function(state)
        movementSettings.flyEnabled = state
        if state then
            enableFly()
        else
            disableFly()
        end
    end
})

Movement:AddSlider("Fly Speed", {
    Title = "Velocidade do Fly",
    Description = "Velocidade do movimento no modo fly",
    Default = movementSettings.flySpeed,
    Min = 5,
    Max = 100,
    Rounding = 0,
    Callback = function(val)
        movementSettings.flySpeed = val
    end
})

Movement:AddToggle("Noclip (!)", {
    Title = "Noclip",
    Description = "Atravessa paredes e objetos",
    Default = false,
    Callback = function(state)
        movementSettings.noclipEnabled = state
        if state then
            enableNoclip()
        else
            disableNoclip()
        end
    end
})

-- Toggle Free Camera
Rage:AddToggle("FreeCam", {
    Title = "Free Camera rage",
    Description = "Ande livremente com a câmera",
    Default = false,
    Callback = function(state)
        freeCamSettings.enabled = state
        if state then
            enableFreeCam()
        else
            disableFreeCam()
        end
    end
})


-- Toggle velocidade opcional (pode ajustar dinamicamente)
Rage:AddSlider("FreeCamSpeed", {
    Title = "Velocidade da FreeCam",
	Description = "veolicty camera",
    Min = 10,
    Max = 200,
    Default = 50,
	Rounding = 1,
    Callback = function(value)
        freeCamSettings.speed = value
    end
})

-- Na parte onde tem os outros cleanups
players.PlayerRemoving:Connect(function(player)
    if player == localPlayer then
        disableThirdPerson()
        disableFly()
        disableNoclip()
        disableJumpFake()
        disablePlayerPull() -- Adicione esta linha
    end
end)


-- Limpeza quando o personagem respawna
localPlayer.CharacterAdded:Connect(function()
    wait(1)
    
    -- Reativar sistemas se estavam ativos
    if thirdPersonSettings.enabled then
        disableThirdPerson()
        wait(0.1)
        enableThirdPerson()
    end

	if playerPullSettings.enabled then
        disablePlayerPull()
        wait(0.1)
        enablePlayerPull()
    end
    
    if movementSettings.flyEnabled then
        disableFly()
        wait(0.1)
        enableFly()
    end
    
    if movementSettings.noclipEnabled then
        disableNoclip()
        wait(0.1)
        enableNoclip()
    end
    
    if movementSettings.jumpFakeEnabled then
        disableJumpFake()
        wait(0.1)
        enableJumpFake()
    end
end)

spawn(function()
    wait(1)
    local lighting = game:GetService("Lighting")
    for _, effect in pairs(lighting:GetChildren()) do
        if effect:IsA("BlurEffect") then
            effect.Enabled = false
        end
    end
    lighting.ChildAdded:Connect(function(child)
        if child:IsA("BlurEffect") then
            child.Enabled = false
        end
    end)
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
