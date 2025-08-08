--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local placeBlockEvent: RemoteEvent = ReplicatedStorage.Remotes.PlaceBlock
local deleteBlockEvent: RemoteEvent = ReplicatedStorage.Remotes.DeleteBlock

local PlacementService = {
	placeBlock = function(player: Player, data: { Position: Vector3, Color: Color3 })
		local block: BasePart = ReplicatedStorage.Assets.Block:Clone()
		block.Position = data.Position
		block.Color = data.Color
		block.Parent = workspace
		block.Name = HttpService:GenerateGUID(false)
		block:SetAttribute("Owner", player.Name)
	end,
	deleteBlock = function(player: Player, blockName: string)
		local block = workspace:FindFirstChild(blockName)
		if block then
			if block:GetAttribute("Owner") == player.Name then
				block:Destroy()
			end
		end
	end,
}

placeBlockEvent.OnServerEvent:Connect(PlacementService.placeBlock)
deleteBlockEvent.OnServerEvent:Connect(PlacementService.deleteBlock)

return PlacementService
