local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local children = Fusion.Children
local event = Fusion.OnEvent

type UsedAs<t> = Fusion.UsedAs<t>

local function Button(
	scope: Fusion.Scope,
	props: {
		Position: UsedAs<UDim2>?,
		Size: UsedAs<UDim2>?,
		Text: UsedAs<string>?,
		Color: UsedAs<Color3>?,
		OnClick: (() -> ())?,
	}
)
	local goal = scope:Value(1)
	local sizeSpring = scope:Spring(goal, 25, 0.5)

	return scope:New("TextButton")({
		--styling
		Position = props.Position,
		Text = props.Text,

		BackgroundTransparency = 0,
		BackgroundColor3 = props.Color,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = props.Size or UDim2.fromScale(0.1, 0.1),

		[event("MouseEnter")] = function()
			goal:set(1.2)
		end,

		[event("MouseLeave")] = function()
			goal:set(1)
		end,

		[children] = {
			scope:New("UIAspectRatioConstraint")({
				AspectRatio = 1,
			}),
			scope:New("UICorner")({
				CornerRadius = UDim.new(0.3, 0),
			}),
			scope:New("UIScale")({
				Scale = sizeSpring,
			}),
		},

		--functionality
		[event("Activated")] = function()
			sizeSpring:addVelocity(-10)
			if props.OnClick ~= nil then
				props.OnClick()
			end
		end,
	})
end
return Button
