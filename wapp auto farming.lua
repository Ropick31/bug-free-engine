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

-- Кухня
local KITCHEN_PATH_1_START = CFrame.new(71.53, 6.6, -8.86)
local KITCHEN_PATH_1_END   = Vector3.new(57.40, 6.6, -9.04)
local KITCHEN_PATH_2_START = CFrame.new(57.95, 6.6, -13.35)
local KITCHEN_PATH_2_END   = Vector3.new(57.82, 6.6, -4.49)

local isActive = false

-- === УВЕДОМЛЕНИЯ ===
local function Notify(text)
	StarterGui:SetCore("SendNotification", {
		Title = "WORK AT PIZZA PLACE AUTO FARM";
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

-- === КЛИКЕР ПО КНОПКАМ GUI ===
local function ClickGuiButton(btn)
	if not btn or not btn.Visible then return end
	
	if firesignal then 
		pcall(function() firesignal(btn.MouseButton1Click) end)
	end
	if getconnections then
		for _, c in pairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
	end
	
	-- Виртуальный клик (как запасной вариант)
	local absPos = btn.AbsolutePosition
	local absSize = btn.AbsoluteSize
	local center = absPos + (absSize / 2)
	VirtualUser:CaptureController()
	VirtualUser:ClickButton1(center)
end

-- === 🔥 АВТО-ЗАРПЛАТА И КИК (ОБНОВЛЕНО) 🔥 ===
task.spawn(function()
	while true do
		task.wait(1)
		if isActive then
			pcall(function()
				local pg = player.PlayerGui
				
				-- 1. ЗАРПЛАТА (GuiTop -> Paycheck)
				if pg:FindFirstChild("GuiTop") and pg.GuiTop:FindFirstChild("Paycheck") then
					local btn = pg.GuiTop.Paycheck:FindFirstChild("CashOut")
					if btn and btn.Visible then
						print("💰 CashOut!")
						ClickGuiButton(btn)
					end
				end
				
				-- 2. ГОЛОСОВАНИЕ ЗА КИК (MainGui -> Prompts)
				-- В этой игре основные окна лежат в MainGui
				if pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("Prompts") then
					local prompts = pg.MainGui.Prompts
					
					-- Вариант А: Стандартный вопрос (Question -> Yes)
					if prompts:FindFirstChild("Question") and prompts.Question.Visible then
						local yes = prompts.Question:FindFirstChild("Yes")
						if yes then 
							print("🔨 VOTING (Question)")
							ClickGuiButton(yes) 
						end
					end
					
					-- Вариант Б: Твой путь (Ban -> KickPlayer)
					if prompts:FindFirstChild("Ban") and prompts.Ban.Visible then
						-- Пробуем найти кнопку KickPlayer или Yes внутри Ban
						local btn1 = prompts.Ban:FindFirstChild("KickPlayer")
						local btn2 = prompts.Ban:FindFirstChild("Yes")
						local btn3 = prompts.Ban:FindFirstChild("Confirm")
						
						if btn1 then ClickGuiButton(btn1) end
						if btn2 then ClickGuiButton(btn2) end
						if btn3 then ClickGuiButton(btn3) end
						print("🔨 VOTING (Ban)")
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
			-- Менеджера удалил, как ты просил
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

-- === ФУНКЦИИ: СТЕРИЛЬНЫЕ РУКИ ===
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

-- === ФУНКЦИИ ПОИСКА ===
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

-- === ГЛАВНЫЙ ЦИКЛ ===
local function FarmLoop()
	while isActive do
		local char = player.Character
		local hum = char and char:FindFirstChild("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		
		if not hum or not root then
			task.wait(1)
			continue
		end
		
		SecureUnequip() -- Всегда прячем пиццу перед действием
		
		local myOrders = GetOrders()
		
		-- ==========================================
		--      ЭТАП 1: СБОР
		-- ==========================================
		if #myOrders == 0 then
			local pathIndex = 1
			while isActive and #GetOrders() == 0 do
				local startCF = (pathIndex == 1) and KITCHEN_PATH_1_START or KITCHEN_PATH_2_START
				local endPos = (pathIndex == 1) and KITCHEN_PATH_1_END or KITCHEN_PATH_2_END
				
				SecureUnequip()
				root.CFrame = startCF
				root.AssemblyLinearVelocity = Vector3.zero
				task.wait(0.2)
				
				hum:MoveTo(endPos)
				
				local walkTime = 0
				while isActive and walkTime < 4 do
					if #GetOrders() > 0 then
						hum:MoveTo(root.Position) -- Стоп
						SecureUnequip() -- ПРЯЧЕМ В РЮКЗАК
						print("Заказ пойман")
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
					if not isActive then break end
					SecureUnequip() -- Убеждаемся, что руки пусты
					if not tool.Parent then break end 
					
					local code = tool.Name
					local houseFound = false
					
					for _, house in pairs(housesFolder:GetChildren()) do
						local addr = house:FindFirstChild("Address")
						if addr and addr.Value == code then
							houseFound = true
							local targetPart = FindGivePizzaPart(house)
							
							if targetPart then
								-- 1. ТП к дому (С пустыми руками!)
								local startPos = targetPart.CFrame * CFrame.new(0, 0, WALK_DISTANCE)
								local lookAt = CFrame.lookAt(startPos.Position, targetPart.Position)
								
								root.CFrame = lookAt
								root.AssemblyLinearVelocity = Vector3.zero
								task.wait(0.3) 
								
								-- 2. Идем к коврику
								hum:MoveTo(targetPart.Position)
								task.wait(1.5) 
								
								-- 3. Достаем пиццу
								hum:EquipTool(tool)
								
								-- 4. Ждем
								local startTime = tick()
								while isActive and tool.Parent == char do
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

-- === ВКЛЮЧЕНИЕ ===
UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == TOGGLE_KEY then
		isActive = not isActive
		if isActive then
			Notify("✅ FARM ON")
			task.spawn(FarmLoop)
		else
			Notify("🛑 STOPPED")
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.Anchored = false
			end
		end
	end
end)