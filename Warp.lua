--[[
	Doubletap warp
]]

require("proxi")

local Next = 0
local LastCharge = 0
local LastChargeSequence = proxi.GetSequenceNumber()
local sv_maxusrcmdprocessticks = proxi.GetConVar("sv_maxusrcmdprocessticks")

hook.Add("CreateMoveEx", "Warp", function(Command)
	local CurTime = CurTime()

	if input.IsButtonDown(KEY_HOME) then -- Release charged ticks
		if CurTime >= Next then
			proxi.SetSequenceNumber(proxi.GetSequenceNumber() + (sv_maxusrcmdprocessticks:GetInt() - 1))

			Next = CurTime + 1
			return true, true
		end
	else
		if CurTime < Next then -- Recharge ticks
			if CurTime - LastCharge >= 0.1 then
				LastChargeSequence = proxi.GetSequenceNumber()
				LastCharge = CurTime
			else
				proxi.SetSequenceNumber(LastChargeSequence)
			end

			return true, true
		end
	end
end)
