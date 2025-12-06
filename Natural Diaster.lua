local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- === TRIGGER ===
local TRIGGER_POS = Vector3.new(-118.1191, 47.4411, 8.2935)
local TRIGGER_RADIUS = 100

-- === COLORS ===
local MAIN_COLOR = Color3.fromRGB(40, 127, 71)    -- Green
local ACCENT_COLOR = Color3.fromRGB(0, 255, 255)  -- Cyan
local OFF_COLOR = Color3.fromRGB(30, 90, 50)

-- === VARIABLES (PERSISTENT) ===
-- Так как Gui.ResetOnSpawn = false, эти переменные НЕ сбросятся при смерти
local isActive = false
local savedCFrame = nil
local isTeleporting = false
local safeBoxFolder = nil

-- === ANTI-AFK ===
player.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)

-- === GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NatDisasterImmortal"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false -- ВАЖНО: GUI не исчезает при смерти

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 170)
frame.Position = UDim2.new(0, 20, 0.5, -85)
frame.BackgroundColor3 = MAIN_COLOR
frame.BorderSizePixel = 3
frame.BorderColor3 = ACCENT_COLOR
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Parent = screenGui

-- Texture
local studTexture = Instance.new("ImageLabel")
studTexture.Name = "StudsPattern"
studTexture.Parent = frame
studTexture.BackgroundTransparency = 1
studTexture.Size = UDim2.new(1, 0, 1, 0)
studTexture.Image = "rbxassetid://6372755229" 
studTexture.ImageColor3 = Color3.new(0, 0, 0)
studTexture.ImageTransparency = 0.85
studTexture.ScaleType = Enum.ScaleType.Tile
studTexture.TileSize = UDim2.new(0, 30, 0, 30)
studTexture.ZIndex = 1

-- Elements
local title = Instance.new("TextLabel")
title.Text = "NATURAL DISASTER AUTO FARM"
title.Size = UDim2.new(0.95, 0, 0, 40)
title.Position = UDim2.new(0.025, 0, 0, 5)
title.BackgroundTransparency = 1
title.TextColor3 = ACCENT_COLOR
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.ZIndex = 2
title.Parent = frame

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0.9, 0, 0, 35)
saveBtn.Position = UDim2.new(0.05, 0, 0.35, 0)
saveBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
saveBtn.Text = "SAVE POSITION"
saveBtn.TextColor3 = Color3.new(0, 0, 0)
saveBtn.Font = Enum.Font.GothamBold
saveBtn.ZIndex = 2
saveBtn.Parent = frame
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)
local stroke1 = Instance.new("UIStroke")
stroke1.Color = ACCENT_COLOR
stroke1.Thickness = 2
stroke1.Parent = saveBtn

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
toggleBtn.Position = UDim2.new(0.05, 0, 0.60, 0)
toggleBtn.BackgroundColor3 = OFF_COLOR
toggleBtn.Text = "AUTO FARM: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.ZIndex = 2
toggleBtn.Parent = frame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
local stroke2 = Instance.new("UIStroke")
stroke2.Color = ACCENT_COLOR
stroke2.Thickness = 2
stroke2.Parent = toggleBtn

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0.88, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready"
statusLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 12
statusLabel.ZIndex = 2
statusLabel.Parent = frame

-- === BUNKER ===
local function BuildBunker(positionCFrame)
	if safeBoxFolder then safeBoxFolder:Destroy() end
	
	safeBoxFolder = Instance.new("Folder")
	safeBoxFolder.Name = "SafetyBunker"
	safeBoxFolder.Parent = Workspace
	
	local size = 15
	local thickness = 1
	local transparency = 0.5
	local color = ACCENT_COLOR
	
	local function makeWall(sizeVec, offsetPos)
		local part = Instance.new("Part")
		part.Size = sizeVec
		part.CFrame = positionCFrame * offsetPos
		part.Anchored = true
		part.CanCollide = true
		part.Transparency = transparency
		part.Color = color
		part.Material = Enum.Material.ForceField
		part.Parent = safeBoxFolder
	end
	
	makeWall(Vector3.new(size, thickness, size), CFrame.new(0, -5, 0))
	makeWall(Vector3.new(size, thickness, size), CFrame.new(0, 5, 0))
	makeWall(Vector3.new(size, size, thickness), CFrame.new(0, 0, size/2))
	makeWall(Vector3.new(size, size, thickness), CFrame.new(0, 0, -size/2))
	makeWall(Vector3.new(thickness, size, size), CFrame.new(size/2, 0, 0))
	makeWall(Vector3.new(thickness, size, size), CFrame.new(-size/2, 0, 0))
end

local function DestroyBunker()
	if safeBoxFolder then
		safeBoxFolder:Destroy()
		safeBoxFolder = nil
	end
end

-- === BUTTON LOGIC ===

saveBtn.MouseButton1Click:Connect(function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		savedCFrame = root.CFrame
		statusLabel.Text = "Pos Saved!"
		saveBtn.Text = "SUCCESS!"
		saveBtn.BackgroundColor3 = ACCENT_COLOR
		task.wait(0.5)
		saveBtn.Text = "SAVE POSITION"
		saveBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
	end
end)

toggleBtn.MouseButton1Click:Connect(function()
	isActive = not isActive
	if isActive then
		if not savedCFrame then
			isActive = false
			statusLabel.Text = "SAVE POSITION FIRST!"
			statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
			return
		end
		toggleBtn.Text = "AUTO FARM: ON"
		toggleBtn.BackgroundColor3 = ACCENT_COLOR
		toggleBtn.TextColor3 = Color3.new(0, 0, 0)
	else
		toggleBtn.Text = "AUTO FARM: OFF"
		toggleBtn.BackgroundColor3 = OFF_COLOR
		toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		DestroyBunker()
	end
end)

-- === MAIN LOOP ===
RunService.Stepped:Connect(function()
	if not isActive or not savedCFrame then return end
	
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	
	if root and hum then
		-- 1. GOD MODE (NO DAMAGE)
		-- Удаляем огонь
		for _, child in pairs(char:GetChildren()) do
			if child.Name == "Fire" or child.Name == "Burning" then child:Destroy() end
		end
		
		-- ОТКЛЮЧАЕМ УРОН ОТ ПАДЕНИЯ
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false) -- Главная причина урона при ТП
		
		-- 2. CHECK TRIGGER
		local dist = (root.Position - TRIGGER_POS).Magnitude
		if dist <= TRIGGER_RADIUS and not isTeleporting then
			isTeleporting = true
			statusLabel.Text = "RETURNING TO BUNKER!"
			statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
			
			-- Мгновенный стоп перед ТП
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = savedCFrame
			
			BuildBunker(savedCFrame)
			
			task.wait(0.5)
			isTeleporting = false
			statusLabel.Text = "Farming..."
			statusLabel.TextColor3 = ACCENT_COLOR
		end
		
		-- 3. ANTI-FLING
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player and other.Character then
				for _, p in pairs(other.Character:GetDescendants()) do
					if p:IsA("BasePart") then 
						p.CanCollide = false 
						p.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)
					end
				end
			end
		end
		
		if root.AssemblyLinearVelocity.Magnitude > 100 then
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end
end)

-- === RESPAWN LOGIC (FIX DEATH) ===
player.CharacterAdded:Connect(function(newChar)
	-- Если скрипт был включен до смерти
	if isActive and savedCFrame then
		-- Ждем загрузки персонажа
		local root = newChar:WaitForChild("HumanoidRootPart", 10)
		local hum = newChar:WaitForChild("Humanoid", 10)
		
		if root and hum then
			statusLabel.Text = "RESPAWNING..."
			task.wait(0.5) -- Маленькая пауза для прогрузки
			
			-- ОТКЛЮЧАЕМ УРОН СРАЗУ
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
			
			-- ТЕЛЕПОРТ ОБРАТНО В БУНКЕР
			root.CFrame = savedCFrame
			root.AssemblyLinearVelocity = Vector3.zero
			BuildBunker(savedCFrame)
			
			statusLabel.Text = "Farming (Respawned)"
		end
	end
end)