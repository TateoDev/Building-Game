local Services = script.Services

for _, service in Services:GetChildren() do
	if service:IsA("ModuleScript") then
		local _service = require(service)
	end
end
