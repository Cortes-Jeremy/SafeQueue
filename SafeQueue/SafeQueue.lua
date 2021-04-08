
-- SafeQueue by Jordon

local SafeQueue = CreateFrame("Frame", "SafeQueue", UIParent)
local queueTime
local queue = 0
local remaining = 0
SafeQueueDB = SafeQueueDB or { announce = "self" }
SafeQueue:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
SafeQueue:SetScript("OnUpdate", function(self) self:Timer() end)
SafeQueue:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].button2 = nil
StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"].hideOnEscape = false

function SafeQueue:UPDATE_BATTLEFIELD_STATUS()
	local queued
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status = GetBattlefieldStatus(i)
		if status == "queued" then
			queued = true
			if not queueTime then queueTime = GetTime() end
		elseif status == "confirm" then
			if queueTime then
				self:TimeWaited()
				queueTime = nil
				remaining = 0
				queue = i
			end
		end
		break
	end
	if not queued and queueTime then queueTime = nil end
end

function SafeQueue:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SafeQueue|r: " .. msg)
end

function SafeQueue:TimeWaited()
	if SafeQueueDB.announce == "off" then return end
	local secs, str, mins = floor(GetTime() - queueTime), "Queue popped "
	if secs < 1 then
		str = str .. "instantly!"
	else
		str = str .. "after "
		if secs >= 60 then
			mins = floor(secs/60)
			str = str .. mins .. "m "
			secs = secs%60
		end
		if secs%60 ~= 0 then
			str = str .. secs .. "s"
		end
	end
	if SafeQueueDB.announce == "self" then
		self:Print(str)
	else
		local group = IsInRaid() and "RAID" or "PARTY"
		SendChatMessage(str, group)
	end
end

function SafeQueue:Timer()
	local secs = GetBattlefieldPortExpiration(queue)
	if secs > 0 then
		local p = StaticPopup_Visible("CONFIRM_BATTLEFIELD_ENTRY")
		if p and remaining ~= secs then
			remaining = secs
			local color = secs > 20 and "f20ff20" or secs > 10 and "fffff00" or "fff0000"
			_G[p .. "Text"]:SetText(string.gsub(
				_G[p .. "Text"]:GetText(),
				".+ to enter",
				"You have |cf"..color.. SecondsToTime(secs) .. "|r to enter"))
		end
	end
end

function SafeQueue:Command(msg)
	msg = msg or ""
	local cmd, arg = string.split(" ", msg, 2)
	cmd = string.lower(cmd or "")
	arg = string.lower(arg or "")
	if cmd == "announce" then
		if arg == "off" or arg == "self" or arg == "group" then
			SafeQueueDB.announce = arg
			self:Print("Announce set to " .. arg)
		else
			self:Print("Announce set to " .. SafeQueueDB.announce)
			self:Print("Announce types are \"off\", \"self\", and \"group\"")
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SafeQueue v1.8|r")
		self:Print("/sq announce : " .. SafeQueueDB.announce)
	end
end

SlashCmdList["SafeQueue"] = function(...) SafeQueue:Command(...) end
SLASH_SafeQueue1 = "/safequeue"
SLASH_SafeQueue2 = "/sq"
