local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- === НАСТРОЙКИ ===
local TOGGLE_KEY = Enum.KeyCode.P
local WAIT_AT_DOOR = 9        -- Время ожидания у двери
local WALK_DISTANCE = 8       -- Дистанция ходьбы до двери
local STABILIZE_TIME = 1.5    -- ВРЕМЯ "ПРИВАРИВАНИЯ" ПИЦЦЫ (WELD FIX)

-- === МАРШРУТЫ КУХНИ ===
local KITCHEN_PATH_1_START = CFrame.new(71.53, 6.6, -8.86)
local KITCHEN_PATH_1_END   = Vector3.new(57.40, 6.6, -9.04)

local KITCHEN_PATH_2_START = CFrame.new(57.95, 6.6, -13.35)
local KITCHEN_PATH_2_END   = Vector3.new(57.82, 6.6, -4.49)

local isActive = false

-- === УВЕДОМЛЕНИЯ ===
local function Notify(text)
	StarterGui:SetCore("SendNotification", {
		Title = "WAPP AUTO DELIVERY";
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
		
		local myOrders = GetOrders()
		
		-- ==========================================
		--      ЭТАП 1: СБОР (WALK + STABILIZE)
		-- ==========================================
		if #myOrders == 0 then
			local pathIndex = 1
			
			while isActive and #GetOrders() == 0 do
				local startCF, endPos
				if pathIndex == 1 then
					startCF = KITCHEN_PATH_1_START
					endPos = KITCHEN_PATH_1_END
				else
					startCF = KITCHEN_PATH_2_START
					endPos = KITCHEN_PATH_2_END
				end
				
				-- ТП на старт
				root.CFrame = startCF
				root.AssemblyLinearVelocity = Vector3.zero
				task.wait(0.2)
				
				-- Идем
				hum:MoveTo(endPos)
				
				-- Цикл ходьбы
				local walkTime = 0
				while isActive and walkTime < 4 do
					
					-- === WELD SYSTEM (СТАБИЛИЗАЦИЯ) ===
					if #GetOrders() > 0 then
						-- Мы поймали пиццу!
						-- 1. Останавливаемся
						hum:MoveTo(root.Position) 
						root.AssemblyLinearVelocity = Vector3.zero
						
						-- 2. Берем в руки принудительно
						local items = GetOrders()
						if items[1] then hum:EquipTool(items[1]) end
						
						print("🍕 Взял заказ! Стабилизация...")
						
						-- 3. Ждем на месте, чтобы сервер засчитал взятие
						task.wait(STABILIZE_TIME)
						
						break -- Выходим из цикла ходьбы -> идем к доставке
					end
					
					if (root.Position - endPos).Magnitude < 2 then break end
					
					task.wait(0.1)
					walkTime = walkTime + 0.1
				end
				
				-- Если после прохода все еще пусто, меняем линию
				if #GetOrders() == 0 then
					pathIndex = pathIndex + 1
					if pathIndex > 2 then pathIndex = 1 end
				else
					break -- Выходим из цикла сбора
				end
				
				task.wait(0.1)
			end
			
		-- ==========================================
		--      ЭТАП 2: ДОСТАВКА (WALK)
		-- ==========================================
		else
			local housesFolder = Workspace:FindFirstChild("Houses")
			if housesFolder then
				local orders = GetOrders()
				
				for _, tool in ipairs(orders) do
					if not isActive then break end
					local code = tool.Name
					
					for _, house in pairs(housesFolder:GetChildren()) do
						local addr = house:FindFirstChild("Address")
						
						if addr and addr.Value == code then
							local targetPart = FindGivePizzaPart(house)
							
							if targetPart then
								hum:EquipTool(tool)
								
								-- ТП за 8 студов
								local startPos = targetPart.CFrame * CFrame.new(0, 0, WALK_DISTANCE)
								local lookAt = CFrame.lookAt(startPos.Position, targetPart.Position)
								
								root.CFrame = lookAt
								root.AssemblyLinearVelocity = Vector3.zero
								task.wait(0.2) 
								
								-- Идем на плиту
								hum:MoveTo(targetPart.Position)
								task.wait(1.5)
								
								-- Ждем таймер (9 сек)
								local startTime = tick()
								while isActive and (tick() - startTime) < WAIT_AT_DOOR do
									if tool.Parent ~= char then break end
									task.wait(0.1)
								end
								
								break 
							end
						end
					end
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
			Notify("✅ STARTED")
			task.spawn(FarmLoop)
		else
			Notify("🛑 STOPPED")
		end
	end
end)