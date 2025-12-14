local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local TARGET_NAME = "Gingerbread"

local isFarming = false
local snowflakes = {}


local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MiniTpFarmUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainCard"
mainFrame.Size = UDim2.new(0, 200, 0, 120)
mainFrame.Position = UDim2.new(0.5, -100, 0.85, -60)
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 16)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 3
uiStroke.Color = Color3.fromRGB(255, 215, 0)
uiStroke.Parent = mainFrame

local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 10, 10)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 40, 40))
}
bgGradient.Rotation = 45
bgGradient.Parent = mainFrame

local snowContainer = Instance.new("Frame")
snowContainer.Name = "SnowContainer"
snowContainer.Size = UDim2.new(1, 0, 1, 0)
snowContainer.BackgroundTransparency = 1
snowContainer.ZIndex = 1
snowContainer.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -30, 0, 30) 
titleLabel.Position = UDim2.new(0, 5, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🍪АВТО ФАРМ ПРЯНИКОВ РГЧ🍪"
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextScaled = true
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.ZIndex = 2
titleLabel.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "PanicBtn"
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -25, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.ZIndex = 10 -- Поверх всего
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

local btn = Instance.new("TextButton")
btn.Name = "ActionBtn"
btn.Size = UDim2.new(0.8, 0, 0, 40)
btn.Position = UDim2.new(0.1, 0, 0.45, 0)
btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
btn.Text = "START"
btn.Font = Enum.Font.GothamBlack
btn.TextSize = 20
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.AutoButtonColor = true
btn.ZIndex = 2
btn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = btn

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(1, 0, 0, 15)
subLabel.Position = UDim2.new(0, 0, 0.85, 0)
subLabel.BackgroundTransparency = 1
subLabel.Text = "Drag me!"
subLabel.Font = Enum.Font.GothamMedium
subLabel.TextSize = 10
subLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
subLabel.ZIndex = 2
subLabel.Parent = mainFrame

closeBtn.MouseButton1Click:Connect(function()
	isFarming = false
	screenGui:Destroy()
	script:Destroy()
end)

local function makeDraggable(frame)
	local dragging, dragInput, dragStart, startPos

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

makeDraggable(mainFrame)

local function createSnowflake()
	local flake = Instance.new("Frame")
	flake.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
	flake.Position = UDim2.new(math.random(), 0, -0.1, 0) 
	flake.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flake.BackgroundTransparency = math.random(2, 6) / 10
	flake.BorderSizePixel = 0
	local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(1, 0) corner.Parent = flake
	flake.Parent = snowContainer
	local speed = math.random(10, 30) / 100
	return {GUI = flake, Speed = speed}
end

for i = 1, 15 do table.insert(snowflakes, createSnowflake()) end

RunService.RenderStepped:Connect(function()
	if not screenGui.Parent then return end
	for _, flakeData in pairs(snowflakes) do
		local f = flakeData.GUI
		local newY = f.Position.Y.Scale + (flakeData.Speed * 0.01)
		if newY > 1.1 then newY = -0.1 f.Position = UDim2.new(math.random(), 0, -0.1, 0) else f.Position = UDim2.new(f.Position.X.Scale, 0, newY, 0) end
	end
end)

local function toggleFarm()
	isFarming = not isFarming
	
	if isFarming then
		btn.Text = "STOP"
		btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
		TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(0.75, 0, 0, 38)}):Play()
	else
		btn.Text = "START"
		btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
		TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(0.8, 0, 0, 40)}):Play()
	end
end

btn.MouseButton1Click:Connect(toggleFarm)

RunService.RenderStepped:Connect(function()
	if not isFarming then return end
	
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local myCFrame = root.CFrame
	
	for i, v in pairs(Workspace:GetDescendants()) do
		if v.Name == TARGET_NAME and v:IsA("BasePart") then
			v.CFrame = myCFrame
			v.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			v.CanCollide = false
		end
	end
end)
