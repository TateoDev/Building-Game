local controllers = script.Controllers

for _, controller in controllers:GetChildren() do
	if controller:IsA("ModuleScript") then
		local _c = require(controller)
	end
end
