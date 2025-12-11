local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- === НАСТРОЙКИ ===
local TOGGLE_KEY = Enum.KeyCode.P
local WAIT_AT_DOOR = 9       
local WALK_DISTANCE = 12      
local RESTART_INTERVAL = 60   -- Перезапуск каждую минуту

-- Кухня
local KITCHEN_PATH_1_START = CFrame.new(71.53, 6.6, -8.86)
local KITCHEN_PATH_1_END   = Vector3.new(57.40, 6.6, -9.04)
local KITCHEN_PATH_2_START = CFrame.new(57.95, 6.6, -13.35)
local KITCHEN_PATH_2_END   = Vector3.new(57.82, 6.6, -4.49)

local isActive = false
local CurrentSessionID = 0 -- Идентификатор текущей сессии (для перезапуска)

-- === УВЕДОМЛЕНИЯ ===
local function Notify(title, text)
	StarterGui:SetCore("SendNotification", {
		Title = ("WORK AT PIZZA PLACE AUTO FARM");
		Text = text;
		Duration = 2;
	})
end

-- === ANTI-AFK ===
player.Idled:Connect(function()
	if isActive then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

-- === АВТОМАТИЗАЦИЯ GUI ===
task.spawn(function()
	while true do
		task.wait(1)
		if isActive then
			pcall(function()
				local pg = player.PlayerGui
				
				-- Зарплата
				if pg:FindFirstChild("GuiTop") and pg.GuiTop:FindFirstChild("Paycheck") then
					local btn = pg.GuiTop.Paycheck:FindFirstChild("CashOut")
					if btn and btn.Visible then
						if firesignal then firesignal(btn.MouseButton1Click) end
						if getconnections then
							for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
						end
					end
				end
				
				-- Кик
				if pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("Prompts") then
					local prompts = pg.MainGui.Prompts
					if prompts:FindFirstChild("Question") and prompts.Question.Visible then
						local yes = prompts.Question:FindFirstChild("Yes")
						if yes then 
							VirtualUser:CaptureController()
							VirtualUser:ClickButton1(yes.AbsolutePosition + (yes.AbsoluteSize/2))
						end
					end
				end
			end)
		end
	end
end)

-- === АВТО-УСТРОЙСТВО ===
task.spawn(function()
	while true do
		task.wait(5)
		if isActive then
			pcall(function()
				local jobSystem = ReplicatedStorage:FindFirstChild("Controllers") 
					and ReplicatedStorage.Controllers:FindFirstChild("JobManager")
					and ReplicatedStorage.Controllers.JobManager:FindFirstChild("ChangeJob")
				if jobSystem then jobSystem:InvokeServer("Delivery") end
			end)
			local gui = player.PlayerGui:FindFirstChild("Main")
			if gui and gui:FindFirstChild("ManagerAlert") then gui.ManagerAlert.Visible = false end
		end
	end
end)

-- === АНТИ-ПАДЕНИЕ ===
RunService.Stepped:Connect(function()
	if not isActive then return end
	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if hum then
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
		hum.PlatformStand = false
	end
end)

-- === ФУНКЦИИ ===
local function IsOrder(tool)
	if not tool then return false end
	local n = tool.Name
	return string.len(n) <= 3 or string.match(n, "Box") or string.match(n, "Soda")
end

local function GetOrders()
	local orders = {}
	for _, t in pairs(player.Backpack:GetChildren()) do 
		if IsOrder(t) then table.insert(orders, t) end 
	end
	if player.Character then
		local tool = player.Character:FindFirstChildOfClass("Tool")
		if tool and IsOrder(tool) then table.insert(orders, tool) end
	end
	return orders
end

local function FindGivePizzaPart(houseModel)
	for _, obj in pairs(houseModel:GetDescendants()) do
		if obj.Name == "GivePizza" and obj:IsA("BasePart") then
			return obj
		end
	end
	return nil
end

local function SecureUnequip()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end
	while char:FindFirstChildOfClass("Tool") do
		hum:UnequipTools() 
		RunService.Heartbeat:Wait()
	end
end

-- === ГЛАВНАЯ ФУНКЦИЯ ФАРМА (С ID СЕССИИ) ===
local function FarmSession(sessionID)
	print("🔄 Сессия #" .. sessionID .. " запущена")
	
	-- Сброс состояния при старте сессии
	if player.Character then
		local root = player.Character:FindFirstChild("HumanoidRootPart")
		local hum = player.Character:FindFirstChild("Humanoid")
		if root then root.Anchored = false root.AssemblyLinearVelocity = Vector3.zero end
		if hum then hum:MoveTo(root.Position) end -- Стоп движение
	end
	
	while isActive and sessionID == CurrentSessionID do
		local char = player.Character
		local hum = char and char:FindFirstChild("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		
		if not hum or not root then
			task.wait(1)
			continue
		end
		
		SecureUnequip()
		local myOrders = GetOrders()
		
		-- ==========================================
		--      ЭТАП 1: СБОР
		-- ==========================================
		if #myOrders == 0 then
			local pathIndex = 1
			while isActive and sessionID == CurrentSessionID and #GetOrders() == 0 do
				local startCF = (pathIndex == 1) and KITCHEN_PATH_1_START or KITCHEN_PATH_2_START
				local endPos = (pathIndex == 1) and KITCHEN_PATH_1_END or KITCHEN_PATH_2_END
				
				SecureUnequip()
				root.CFrame = startCF
				root.AssemblyLinearVelocity = Vector3.zero
				task.wait(0.2)
				
				hum:MoveTo(endPos)
				
				local walkTime = 0
				while isActive and sessionID == CurrentSessionID and walkTime < 4 do
					if #GetOrders() > 0 then
						hum:MoveTo(root.Position)
						SecureUnequip()
						task.wait(0.5) 
						break 
					end
					
					if (root.Position - endPos).Magnitude < 2 then break end
					task.wait(0.1)
					walkTime = walkTime + 0.1
				end
				
				if #GetOrders() == 0 then
					pathIndex = (pathIndex == 1) and 2 or 1
				else
					break 
				end
				task.wait(0.1)
			end
			
		-- ==========================================
		--      ЭТАП 2: ДОСТАВКА
		-- ==========================================
		else
			local housesFolder = Workspace:FindFirstChild("Houses")
			if housesFolder then
				local orders = GetOrders()
				
				for _, tool in ipairs(orders) do
					if not isActive or sessionID ~= CurrentSessionID then break end
					SecureUnequip()
					if not tool.Parent then break end 
					
					local code = tool.Name
					local houseFound = false
					
					for _, house in pairs(housesFolder:GetChildren()) do
						local addr = house:FindFirstChild("Address")
						if addr and addr.Value == code then
							houseFound = true
							local targetPart = FindGivePizzaPart(house)
							
							if targetPart then
								hum:UnequipTools()
								
								local startPos = targetPart.CFrame * CFrame.new(0, 0, WALK_DISTANCE)
								local lookAt = CFrame.lookAt(startPos.Position, targetPart.Position)
								
								root.CFrame = lookAt
								root.AssemblyLinearVelocity = Vector3.zero
								task.wait(0.3) 
								
								hum:MoveTo(targetPart.Position)
								task.wait(1.5) 
								
								hum:EquipTool(tool)
								
								local startTime = tick()
								while isActive and sessionID == CurrentSessionID and tool.Parent == char do
									if (tick() - startTime) > WAIT_AT_DOOR then break end
									if (root.Position - targetPart.Position).Magnitude > 4 then
										hum:MoveTo(targetPart.Position)
									end
									task.wait(0.2)
								end
								
								task.wait(0.2)
								break 
							end
						end
					end
					
					if not houseFound then
						tool:Destroy()
						task.wait(0.5)
					end
					break 
				end
			end
		end
		task.wait(0.1)
	end
end

-- === ЦИКЛ ПЕРЕЗАПУСКА (WATCHDOG) ===
task.spawn(function()
	while true do
		task.wait(RESTART_INTERVAL)
		if isActive then
			Notify("🔄 RELOADING...", "Anti-Bug Refresh")
			
			-- 1. Меняем ID сессии (это автоматически остановит старый цикл FarmSession)
			CurrentSessionID = CurrentSessionID + 1
			
			-- 2. Запускаем новый цикл
			task.spawn(function()
				FarmSession(CurrentSessionID)
			end)
		end
	end
end)

-- === ВКЛЮЧЕНИЕ ===
UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == TOGGLE_KEY then
		isActive = not isActive
		
		if isActive then
			Notify("✅ STARTED", "Auto-Restart Active")
			CurrentSessionID = CurrentSessionID + 1
			task.spawn(function()
				FarmSession(CurrentSessionID)
			end)
		else
			Notify("🛑 STOPPED")
			CurrentSessionID = CurrentSessionID + 1 -- Остановит любой текущий цикл
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.Anchored = false
			end
		end
	end

end)
