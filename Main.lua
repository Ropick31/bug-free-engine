local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local RUNNER_TEAM = "Runners"
local BANANA_TEAM = "Banana"
local MONEY_NAME = "Token"

-- === ПЕРЕМЕННЫЕ ===
local isScriptActive = false
local currentMode = "None"
local hasEscaped = false
local myPlatform = nil

-- Физика
local holdBodyPos = nil
local holdGyro = nil

-- Ссылки на карту
local gameClock = nil
local exitsFolder = nil

-- === GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BananaBackupEscape"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 130)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -65)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 35, 10) 
mainFrame.BorderSizePixel = 3
mainFrame.BorderColor3 = Color3.fromRGB(255, 230, 0) 
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🍌BANANA EATS AUTO FARM🍌"
titleLabel.TextColor3 = Color3.fromRGB(255, 230, 0)
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextSize = 14
titleLabel.Parent = mainFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
toggleBtn.Position = UDim2.new(0.1, 0, 0.35, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 220, 0) 
toggleBtn.Text = "СТАРТ"
toggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0) 
toggleBtn.Font = Enum.Font.GothamBlack
toggleBtn.TextSize = 20
toggleBtn.Parent = mainFrame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0.8, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Статус: Ожидание..."
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 14
statusLabel.Parent = mainFrame

-- === ANTI-AFK ===
player.Idled:Connect(function()
	if isScriptActive then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

-- ==========================================
--      ПОИСК КАРТЫ
-- ==========================================
local function UpdateMapReferences()
	if not gameClock then
		local gp = Workspace:FindFirstChild("GameProperties")
		if gp then gameClock = gp:FindFirstChild("GameClock") end
	end
	if not exitsFolder then
		local gk = Workspace:FindFirstChild("GameKeeper")
		if gk then exitsFolder = gk:FindFirstChild("Exits") end
	end
end

-- ==========================================
--      ФИЗИКА И ПЛАТФОРМА
-- ==========================================
local function CleanUpPhysics()
	if holdBodyPos then holdBodyPos:Destroy() holdBodyPos = nil end
	if holdGyro then holdGyro:Destroy() holdGyro = nil end
	if myPlatform then myPlatform:Destroy() myPlatform = nil end
	
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.PlatformStand = false
	end
end

local function ActivatePlatform(root)
	CleanUpPhysics()
	
	local targetPos = root.Position + Vector3.new(0, 60, 0)
	
	myPlatform = Instance.new("Part")
	myPlatform.Name = "SafeBase"
	myPlatform.Size = Vector3.new(50, 1, 50)
	myPlatform.Anchored = true
	myPlatform.CanCollide = true
	myPlatform.Transparency = 0.6
	myPlatform.Color = Color3.fromRGB(255, 255, 0)
	myPlatform.Material = Enum.Material.Neon
	myPlatform.CFrame = CFrame.new(targetPos)
	myPlatform.Parent = Workspace
	
	local hum = player.Character:FindFirstChild("Humanoid")
	if hum then hum.PlatformStand = true end
	
	holdGyro = Instance.new("BodyGyro")
	holdGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	holdGyro.CFrame = CFrame.new()
	holdGyro.Parent = root
	
	holdBodyPos = Instance.new("BodyPosition")
	holdBodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	holdBodyPos.P = 10000
	holdBodyPos.D = 500
	holdBodyPos.Position = targetPos + Vector3.new(0, 3, 0)
	holdBodyPos.Parent = root
	
	print("✅ Платформа создана!")
end

-- ==========================================
--      BANANA ОХОТА
-- ==========================================
local function BananaLoop()
	task.spawn(function()
		while isScriptActive and currentMode == "Banana" do
			statusLabel.Text = "🍌 Охота..."
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 0)
			
			local targets = {}
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and p.Team and p.Team.Name == RUNNER_TEAM then
					if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
						table.insert(targets, p)
					end
				end
			end
			
			if #targets > 0 then
				for _, target in ipairs(targets) do
					if not isScriptActive or currentMode ~= "Banana" then break end
					local startTime = tick()
					while tick() - startTime < 2 do
						if not isScriptActive or currentMode ~= "Banana" then break end
						if target.Character and target.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							player.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
							player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
							for _, p in pairs(player.Character:GetDescendants()) do
								if p:IsA("BasePart") then p.CanCollide = false end
							end
						else
							break
						end
						RunService.Heartbeat:Wait()
					end
					task.wait(0.1)
				end
			else
				task.wait(1)
			end
		end
	end)
end

-- ==========================================
--      КОНТРОЛЛЕР КОМАНД (С ЗАДЕРЖКОЙ 8с)
-- ==========================================
local function OnTeamChanged()
	if not isScriptActive then return end
	
	local team = player.Team
	local teamName = team and team.Name or "None"
	
	if teamName == "Lobby" or teamName == "Spectators" or teamName == "None" then
		currentMode = "Lobby"
		CleanUpPhysics()
		statusLabel.Text = "В Лобби (Очистка)"
		statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		
	elseif teamName == RUNNER_TEAM then
		currentMode = "Runner"
		hasEscaped = false
		CleanUpPhysics()
		
		task.spawn(function()
			for i = 8, 1, -1 do
				if currentMode ~= "Runner" or not isScriptActive then return end
				statusLabel.Text = "Загрузка карты: " .. i .. "с..."
				statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
				task.wait(1)
			end
			
			if currentMode == "Runner" and isScriptActive then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					ActivatePlatform(root)
					statusLabel.Text = "✅ Фарм активен"
					statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
				end
			end
		end)
		
	elseif teamName == BANANA_TEAM then
		currentMode = "Banana"
		CleanUpPhysics()
		BananaLoop()
	end
end

player:GetPropertyChangedSignal("Team"):Connect(OnTeamChanged)

-- ==========================================
--      ФУНКЦИЯ ТЕЛЕПОРТА (SPAM TP)
-- ==========================================
local function SpamTeleport(targetCFrame, duration)
	local startTime = tick()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	
	if root then
		root.Anchored = true
		while tick() - startTime < duration do
			if root then
				root.CFrame = targetCFrame
				root.AssemblyLinearVelocity = Vector3.zero
			end
			RunService.Heartbeat:Wait()
		end
		if root then root.Anchored = false end
	end
end

-- ==========================================
--      ГЛАВНЫЙ ЦИКЛ
-- ==========================================
RunService.Stepped:Connect(function()
	if not isScriptActive then return end
	UpdateMapReferences()
	
	-- Магнит денег
	if currentMode == "Runner" and myPlatform and not hasEscaped then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then 
			for _, obj in pairs(Workspace:GetDescendants()) do
				if obj.Name == MONEY_NAME then
					if obj:IsA("BasePart") then
						obj.CanCollide = false; obj.CFrame = root.CFrame; obj.AssemblyLinearVelocity = Vector3.zero
					elseif obj:IsA("Model") and obj.PrimaryPart then
						obj.PrimaryPart.CanCollide = false; obj.PrimaryPart.AssemblyLinearVelocity = Vector3.zero; obj:PivotTo(root.CFrame)
					elseif obj:IsA("Tool") and obj:FindFirstChild("Handle") then
						obj.Handle.CanCollide = false; obj.Handle.CFrame = root.CFrame
					end
				end
			end
		end
	end
	
	-- === ЛОГИКА ПОБЕГА ===
	if currentMode == "Runner" and gameClock and gameClock.Value <= 60 and gameClock.Value > 50 and not hasEscaped then
		hasEscaped = true -- Чтобы сработало один раз
		
		CleanUpPhysics() -- Убираем платформу
		
		-- 1. ПОПЫТКА №1: ВТОРОЙ ВЫХОД (ОСНОВНОЙ)
		if exitsFolder then
			local exits = exitsFolder:GetChildren()
			local primaryExit = exits[2] -- Второй выход по списку
			
			local targetPart = nil
			if primaryExit then
				targetPart = primaryExit:FindFirstChild("Neon") or primaryExit.PrimaryPart
			end
			
			if targetPart then
				statusLabel.Text = "🏃 ПОБЕГ: ВЫХОД 2"
				statusLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
				
				-- Телепортируемся туда и держимся 3 секунды
				task.spawn(function()
					SpamTeleport(targetPart.CFrame + Vector3.new(0, 3, 0), 3)
				end)
			end
			
			-- 2. ЗАПУСКАЕМ ПЛАН "Б" ЧЕРЕЗ 13 СЕКУНД
			task.delay(13, function()
				-- Если мы все еще в игре (не в лобби), значит выход не сработал
				if isScriptActive and player.Team and player.Team.Name == RUNNER_TEAM then
					
					statusLabel.Text = "⚠ ПЛАН Б: ESCAPE DOOR"
					statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
					
					local backupExit = exitsFolder:FindFirstChild("EscapeDoor")
					if backupExit then
						local backupPart = backupExit:FindFirstChild("Neon") or backupExit.PrimaryPart or backupExit:FindFirstChildWhichIsA("BasePart")
						
						if backupPart then
							SpamTeleport(backupPart.CFrame + Vector3.new(0, 3, 0), 5) -- Держимся 5 секунд
						else
							print("EscapeDoor найден, но внутри нет частей!")
						end
					else
						print("EscapeDoor не найден!")
					end
				end
			end)
		end
	end
end)

-- Кнопка
toggleBtn.MouseButton1Click:Connect(function()
	isScriptActive = not isScriptActive
	if isScriptActive then
		toggleBtn.Text = "СТОП"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
		OnTeamChanged()
	else
		toggleBtn.Text = "СТАРТ"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 220, 0)
		statusLabel.Text = "Выключено"
		currentMode = "None"
		CleanUpPhysics()
	end
end)

player.CharacterAdded:Connect(function()
	if isScriptActive then
		CleanUpPhysics()
		task.delay(1, OnTeamChanged)
	end
end)