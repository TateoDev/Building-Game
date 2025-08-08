local ReplicatedStorage = game:GetService("ReplicatedStorage")
local promise = require(ReplicatedStorage.Packages.promise)

local RoundService = {
	StartRound = function() end,
}

while true do
	print("Intermission")
	promise.delay(3):andThen(RoundService.StartRound):andThenCall(promise.delay, 5):finally()
end

return RoundService
