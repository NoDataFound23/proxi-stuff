--[[
	https://github.com/leme6156/proxi-stuff
]]

local WasCalled = false

hook.Add("CreateMove", "_", function(cmd)
	WasCalled = true
		hook.Run("CreateMoveEx", cmd)
	WasCalled = false
end)

hook.Add("CreateMoveEx", "_", function(cmd)
	if WasCalled then
		-- Run whatever needed to be sped up in here
	else
		-- Run regular logic in here + return for bSendPacket in here 
	end
end)
