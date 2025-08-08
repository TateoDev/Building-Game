local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Fusion = require(ReplicatedStorage.Shared.Fusion)
local children = Fusion.Children
local scoped = Fusion.scoped

local shared = ReplicatedStorage:WaitForChild("Shared")
local colorsTable = require(shared.Collection.Colors)
local placeBlockEvent: RemoteEvent = ReplicatedStorage.Remotes.PlaceBlock
local deleteBlockEvent: RemoteEvent = ReplicatedStorage.Remotes.DeleteBlock

type BuildingMode = "Building" | "Eraser"

local GRID_SIZE = 2

local player = Players.LocalPlayer
local playerGui = player:FindFirstChildWhichIsA("PlayerGui")
player:SetAttribute("SelectedColor", colorsTable[1])

local camera = workspace.CurrentCamera

local ghostBlock: BasePart = ReplicatedStorage.Assets.Block:Clone()
ghostBlock.Color = player:GetAttribute("SelectedColor") or colorsTable[1]
ghostBlock.Transparency = 0.5
ghostBlock.Parent = workspace
ghostBlock.CanCollide = false
ghostBlock.CanQuery = false
ghostBlock.CanTouch = false

local Mode: BuildingMode

local highlightScope = scoped(Fusion)
local validEraser = highlightScope:Value(false)

local function createParams(): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	for _, plr in Players:GetPlayers() do
		if plr.Character then
			params:AddToFilter(plr.Character)
		end
	end
	return params
end

local eraserHighlight = highlightScope:New("Highlight")({
	Parent = workspace,
	FillTransparency = 1,
	OutlineTransparency = 0,
	Enabled = validEraser,

	OutlineColor = highlightScope:Computed(function()
		if validEraser then
			return Color3.new(1, 1, 1)
		else
			return Color3.new(1, 0, 0)
		end
	end),
})

local PlacementController = {
	placeBlock = function(_ActionName, UserInputState, _InputObject)
		if UserInputState ~= Enum.UserInputState.Begin then
			return
		end

		local cloneTween = ghostBlock:Clone()
		cloneTween.CanCollide = true
		cloneTween.Parent = workspace
		cloneTween.Transparency = 0
		cloneTween.Size = Vector3.zero
		local t = TweenService:Create(cloneTween, TweenInfo.new(0.2), { Size = ghostBlock.Size })
		t:Play()
		t.Completed:Connect(function()
			placeBlockEvent:FireServer({
				Position = cloneTween.Position,
				Color = cloneTween.Color,
			})
			task.delay(0.3, function()
				cloneTween:Destroy()
			end)
		end)
	end,
	eraseBlock = function(_ActionName, UserInputState, _InputObject)
		if UserInputState ~= Enum.UserInputState.Begin then
			return
		end

		local mousePosition = UserInputService:GetMouseLocation()
		local unitRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

		local results = workspace:Raycast(unitRay.Origin, unitRay.Direction * 300, createParams())
		if results then
			local blockToDestroy = results.Instance
			if blockToDestroy:GetAttribute("Owner") == player.Name then
				local cloneTween = blockToDestroy:Clone()
				cloneTween.Parent = workspace
				deleteBlockEvent:FireServer(results.Instance.Name)
				TweenService:Create(cloneTween, TweenInfo.new(0.2), { Size = Vector3.zero }):Play()
			end
		end
	end,
	updateGhost = function()
		local mousePosition = UserInputService:GetMouseLocation()
		local unitRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

		local results = workspace:Raycast(unitRay.Origin, unitRay.Direction * 300, createParams())
		if results then
			local blockPosition = results.Position

			local snappedPosition = Vector3.new(
				(blockPosition.X // GRID_SIZE),
				(blockPosition.Y // GRID_SIZE),
				(blockPosition.Z // GRID_SIZE)
			) * GRID_SIZE

			local normalCFrame = CFrame.lookAlong(blockPosition, results.Normal)
			local relativeSnapped = normalCFrame:PointToObjectSpace(snappedPosition)
			local xVector = normalCFrame:VectorToWorldSpace(Vector3.xAxis * -math.sign(relativeSnapped.X))
			local yVector = normalCFrame:VectorToWorldSpace(Vector3.yAxis * -math.sign(relativeSnapped.Y))

			local cf = CFrame.fromMatrix(snappedPosition, xVector, yVector, results.Normal)

			ghostBlock.Position = cf:PointToWorldSpace(Vector3.one * (GRID_SIZE / 2))
		end
	end,
	updateHighlight = function()
		local mousePosition = UserInputService:GetMouseLocation()
		local unitRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

		local results = workspace:Raycast(unitRay.Origin, unitRay.Direction * 300, createParams())
		if results and results.Instance:GetAttribute("Owner") == player.Name then
			validEraser:set(true)
			eraserHighlight.Parent = results.Instance
		else
			validEraser:set(false)
		end
	end,
	updateMode = function(self, newMode: BuildingMode)
		if newMode == Mode then
			return
		end

		Mode = newMode

		if newMode == "Building" then
			ContextActionService:BindAction(
				"PlaceBlock",
				self.placeBlock,
				false,
				Enum.UserInputType.MouseButton1,
				Enum.UserInputType.Touch
			)
			RunService:BindToRenderStep("UpdateGhost", Enum.RenderPriority.Input.Value, self.updateGhost)
			ghostBlock.Transparency = 0.5
			ContextActionService:UnbindAction("EraseBlock")
			RunService:UnbindFromRenderStep("UpdateHighlight")
		elseif newMode == "Eraser" then
			ContextActionService:BindAction(
				"EraseBlock",
				self.eraseBlock,
				false,
				Enum.UserInputType.MouseButton1,
				Enum.UserInputType.Touch
			)
			RunService:BindToRenderStep("UpdateHighlight", Enum.RenderPriority.Input.Value, self.updateHighlight)
			ContextActionService:UnbindAction("PlaceBlock")
			RunService:UnbindFromRenderStep("UpdateGhost")
			ghostBlock.Transparency = 1
		end
	end,
}

PlacementController:updateMode("Building")

player:GetAttributeChangedSignal("SelectedColor"):Connect(function()
	ghostBlock.Color = player:GetAttribute("SelectedColor")
end)

local scope = scoped(Fusion, {
	Button = require(script.Parent.Parent.Button),
})

local _ui = scope:New("ScreenGui")({
	Parent = playerGui,
	Name = "PlacementGui",
	IgnoreGuiInset = true,

	[children] = {
		scope:New("ScrollingFrame")({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.5, 0, 0.2, 30),
			Position = UDim2.fromScale(0.5, 0.85),

			BackgroundColor3 = Color3.new(0.929412, 0.917647, 0.917647),
			BackgroundTransparency = 1,

			ScrollingDirection = Enum.ScrollingDirection.X,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ClipsDescendants = true,

			[children] = {
				scope:New("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 2),
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				scope:Button({
					Color = Color3.new(1, 0.721569, 0.721569),
					Text = "Eraser",
					Size = UDim2.fromOffset(75, 75),

					OnClick = function()
						PlacementController:updateMode("Eraser")
					end,
				}),

				scope:ForValues(colorsTable, function(_use, _scope, color)
					return scope:Button({
						Color = color,
						Size = UDim2.fromOffset(75, 75),
						OnClick = function()
							PlacementController:updateMode("Building")
							player:SetAttribute("SelectedColor", color)
						end,
					})
				end),
			},
		}),
	},
})

return PlacementController
