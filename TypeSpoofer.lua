--[[
  Spoofs your typing text to something
]]

require("proxi")

hook.Add("CreateMoveEx", "IAmTypingBroISwear", function(Command)
	Command:SetIsTyping(true) -- So Player:IsTyping returns true
	hook.Run("ChatTextChanged", "Hello I am typing this text yeah") -- Call the game's typing hook to trick addons into thinking you're typing something
end)
