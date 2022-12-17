--[[
	Hit or miss rapidfire / doubletap (I probably need to tweak my numbers better, oh well)
]]

require("proxi")

local TICK_INTERVAL = engine.TickInterval()
local DownLast = false

local function TimeToTick(Time)
	return math.floor(0.5 + (Time / TICK_INTERVAL))
end

hook.Add("CreateMoveEx", "RapidFire", function(cmd)
	local Down = cmd:KeyDown(IN_ATTACK)

	if Down then
		if DownLast then
			proxi.SetSequenceNumber(proxi.GetSequenceNumber() + math.floor(1 / TICK_INTERVAL) - 1) -- I had more success in my testing with this math over TimeToTick(1) in here
			cmd:SetTickCount(cmd:TickCount() + TimeToTick(1) + 1) -- Spin-off of how CS:GO rapidfire and doubletap work
		end

		DownLast = not DownLast
	end
end)
