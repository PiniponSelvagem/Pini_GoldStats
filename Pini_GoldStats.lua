-- Author      : PiniponSelvagem
-- Create Date : 2019/06/30
-- Updated     : 2020/06/23
-- Based of    : xp_timer by jjacob (Jeff Jacob)

-- ENABLE lua debug errors: /console scriptErrors 1


PiniGS = {} -- exported functions in this object
local pgs = {}
local colors = {
    --|cAARRGGBB |r
    RED     = "|cFFFF0000",
    YELLOW  = "|cFFFFFF00",
    GREEN   = "|cFF00FF00",
    CYAN    = "|cFF00FFFF",
    BLUE    = "|cFF0000FF",
    PINK    = "|cFFFF00FF",

    GOLD    = "|cFFFFD700",
    SILVER  = "|cFFC0C0C0",
    COPPER  = "|cFFB87333",
}

local session = {
    startTime  = GetTime(),
    startMoney = GetMoney(),
}

local instance = {
    isValid = false,
    inProgress = false,
    wasShownOnLeave = true, -- starts at true to not show instance stats on login
    name = "N/A",
    difficultyName = "N/A",
    ["time"] = {
        startT = 0,
        endT   = 0,
    },
    ["money"] = {
        startM = 0,
        endM   = 0,
    },
}

local strings = {
    ["info"] = {
        RESET = colors.YELLOW .. "Pini GoldStats reseted and ready|r",
    },
    ["help"] = {
        colors.YELLOW .. "Pini GoldStats:|r",
        colors.RED    .. " ----- |rCommands" .. colors.RED .. " -----|r",
        colors.YELLOW .. " /pgs|r -- Get information about gold earned",
        colors.YELLOW .. " /pgs help|r -- this help",
        --colors.YELLOW .. " /pgs hour|r -- gold earned last hour",
        colors.YELLOW .. " /pgs instance|r -- last instance run gold stats",
        colors.YELLOW .. " /pgs reset|r -- reset your gold stats",
        colors.RED    .. " --- |rElvUI datatext" .. colors.RED .. " ---|r",
        colors.GREEN  .. " SET one at:|r " .. colors.CYAN .. "ElvUI|r > DataTexts > Panels",
        colors.YELLOW .. " PGS - session gold/h|r -- show session gold per hour"
    },
    ["session"] = {
        title = colors.YELLOW .. "Pini GoldStats current session:|r",
        sessionTime = "Time: %s hms",
        moneyTotal  = "Total: %s (%s g/hour)",
        --moneyLt15m  = "Last 15min: %s (%s g/hour)",
        --moneyLt1h   = "Last 1hour: %s",
    },
    ["instance"] = {
        inProgress = colors.PINK .. "In progress...|r",
        done       = colors.GREEN .. "Done|r",
        title      = colors.CYAN .. "%s|r %s %s",
        info       = "%s - %s (%s per hour)",
        invalid    = colors.RED .. "You need to run an instance before using this command|r",
    }
}


local pgs_frame = CreateFrame("Frame")
pgs_frame:RegisterEvent("ADDON_LOADED")
pgs_frame:RegisterEvent("PLAYER_LOGIN")
--pgs_frame:RegisterEvent("PLAYER_MONEY")
pgs_frame:RegisterEvent("PLAYER_ENTERING_WORLD")

pgs_frame:SetScript("OnEvent",
    function(self,event,...)
        if pgs[event] and type(pgs[event]) == "function" then
            return pgs[event](pgs,...)
        end
    end
)



--[[
    ---------------------
        AUX functions
    ---------------------
]]

local function getSessionTime()
    return GetTime() - session.startTime
end
local function getSessionMoney()
    return GetMoney() - session.startMoney
end

local function getInstanceTime()
    return instance["time"].endT - instance["time"].startT
end
local function getInstanceMoney()
    return instance["money"].endM - instance["money"].startM
end

local function tryUpdateInstanceInfo()
    if instance.inProgress then
        instance["time"].endT  = GetTime()
        instance["money"].endM = GetMoney()
    end
end
local function setNewInstanceInfo()
    instance["time"].startT  = GetTime();
    instance["money"].startM = GetMoney();
end

local function reset()
    session.startMoney = GetMoney()
    session.startTime  = GetTime()
end

local function printToChat(...)
    DEFAULT_CHAT_FRAME:AddMessage(string.format(...))
end

--[[
Usage:
    for v in arrayValues(somearray) do
        print(v);
    end
]]
local function arrayValues(t)
    local i = 0
    return function() i = i + 1; return t[i] end
end

local function secondsToHMS(seconds)
    hours   = math.floor(seconds / 3600)
    seconds = seconds - (hours * 3600)
    minutes = math.floor(seconds / 60)
    seconds = math.floor(seconds - (minutes * 60))
    return hours,minutes,seconds
end
local function hmsToString(seconds)
    return string.format("%d:%.2d:%.2d", secondsToHMS(seconds))
end --to_hms_string

local function moneyToGSC(copper)
    local positive = 1
    if copper < 0 then
        positive = -1
    end
    copper = copper * positive
    gold = math.floor(copper / 10000)
    copper = copper - (gold * 10000)
    silver = math.floor(copper / 100)
    copper = math.floor(copper - (silver * 100))
    return gold,silver,copper
end
local function gscToString(copper)
    local ret = string.format("%d" .. colors.GOLD .. "g|r %d" .. colors.SILVER .. "s|r %d" .. colors.COPPER .."c|r", moneyToGSC(copper))
    if (copper < 0) then
        ret = "-" .. ret
    end
    return ret
end

local function moneyPerHour(money, seconds)
    if seconds > 0 then
        return (money / seconds) * 3600
    end
    return 0
end



function pgs:handleSlashes(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    if command == "" then
        self:default()
    else
        if self[command] and type(self[command]) == "function"  then
            return self[command](self,rest)
        else
            self:help(msg)
        end
    end
end

--[[
    This is called X time after entering an instance, since for some reason
    difficultyName gets its update delayed by the WoW client.
    It can be called by the player/you, either if you managed to type it by luck
    or came here and check the source code xD.
    No problem in calling this command outside of an instance.
]]
function pgs:updateInstaceDifficultyName()
    if IsInInstance() then
        local name, type, difficultyIndex, difficultyName, maxPlayers,
            dynamicDifficulty, isDynamic, instanceMapId, lfgID = GetInstanceInfo()
        
        if difficultyName == "" then
            difficultyName = "N/A"
        end
        instance.difficultyName = difficultyName
    end
end

--[[
    ---------------------
       Event functions
    ---------------------
]]

function pgs:ADDON_LOADED(...)
    local addon = ...
    if addon == "Pini_GoldStats" then
        SlashCmdList["PINIGOLDSTATS"] = function(msg)
            pgs:handleSlashes(msg)
        end -- end function
        SLASH_PINIGOLDSTATS1 = "/pgs"
        SLASH_PINIGOLDSTATS2 = "/pini_goldstats"
    end
end

function pgs:PLAYER_LOGIN(...)
    self:reset();
end

--[[
function pgs:PLAYER_MONEY(...)
    local current_time = math.floor(GetTime());
    --DEFAULT_CHAT_FRAME:AddMessage("You where paid at "..xp_util.to_hms_string(current_time));
    local cash_time_diff = current_time - self.cash_time_last_paid ;
    self.cash_time_last_paid = current_time;
    xpt_character_data.cash_running_time = xpt_character_data.cash_running_time + cash_time_diff;
    --DEFAULT_CHAT_FRAME:AddMessage("You where last paid "..xp_util.to_hms_string(cash_time_diff).." ago.");
    local current_cash = GetMoney();
    local cash_diff = current_cash - self.cash_last_known ;
    self.cash_last_known = current_cash;
    if xpt_global_data["show_cash_on_earn"] then
        if ( cash_diff > 0) then
            DEFAULT_CHAT_FRAME:AddMessage("You just made "..xp_util.to_gsc_string(cash_diff));
        else
            DEFAULT_CHAT_FRAME:AddMessage("You just lost "..xp_util.to_gsc_string(cash_diff));
        end
    end
    --DEFAULT_CHAT_FRAME:AddMessage("You have "..xp_util.to_gsc_string(GetMoney()));
    if (xpt_character_data.cash_values_array[xpt_character_data.cash_running_time] == nil) then
        xpt_character_data.cash_values_array[xpt_character_data.cash_running_time] = cash_diff
    else
        xpt_character_data.cash_values_array[xpt_character_data.cash_running_time] = xpt_character_data.cash_values_array[xpt_character_data.cash_running_time]+ cash_diff;
    end
    --DEFAULT_CHAT_FRAME:AddMessage("You recieved "..xp_util.to_gsc_string(xpt_character_data.cash_values_array[xpt_character_data.cash_running_time]).."this second.");
end -- TODO
]]

function pgs:PLAYER_ENTERING_WORLD(...)
    if IsInInstance() then
        local name, type, difficultyIndex, difficultyName, maxPlayers,
            dynamicDifficulty, isDynamic, instanceMapId, lfgID = GetInstanceInfo()

        C_Timer.After(1, pgs.updateInstaceDifficultyName)

        instance.isValid = true
        instance.inProgress = true
        instance.wasShownOnLeave = false
        instance.name = name
        instance.difficultyName = difficultyName
        setNewInstanceInfo()
    else
        if instance.wasShownOnLeave == false then
            tryUpdateInstanceInfo()
            instance.inProgress = false
            pgs:instance()
            instance.wasShownOnLeave = true
        end
    end
end



--[[
    ---------------------
      Command functions
    ---------------------
]]

function pgs:default()
    local sessionTime  = getSessionTime()
    local sessionMoney = getSessionMoney()
    printToChat(strings.session.title)
    printToChat(strings.session.sessionTime, hmsToString(sessionTime))
    printToChat(
        strings.session.moneyTotal,
        gscToString(sessionMoney),
        gscToString(moneyPerHour(sessionMoney, sessionTime))
    )
end

function pgs:help(msg)
    for v in arrayValues(strings["help"]) do
        printToChat(v)
    end
end

--[[
function pgs:hour()
    local time_diff = GetTime() - self.start_time;
    if time_diff >= (3600) then
        local xp_per_hour = (self.xp_gained / time_diff) * 3600;
        printToChat("XP per hour: "..xp_per_hour);
    else
        printToChat("You have not been logged in without a reset for an hour");
        printToChat("Time Logged IN: "..xp_util.to_hms_string(time_diff));
    end
end --TODO
]]

function pgs:instance()
    tryUpdateInstanceInfo()
    local instanceTitle = string.format(strings.instance.title,
        instance.name,
        instance.difficultyName,
        instance.inProgress and strings.instance.inProgress or strings.instance.done
    )

    if instance.isValid then
        local moneyTotal = getInstanceMoney()
        local timeTotal  = getInstanceTime()
        printToChat(instanceTitle);
        printToChat(
            strings["instance"].info,
            hmsToString(timeTotal),
            gscToString(moneyTotal),
            gscToString(moneyPerHour(moneyTotal, timeTotal))
        )
    else
        printToChat(strings["instance"].invalid)
    end
end

function pgs:reset()
    reset()
    printToChat(strings["info"].RESET)
end



--[[
    ---------------------
      Exported functions
    ---------------------
]]
function PiniGS:session()
    local _time  = getSessionTime()
    local _money = getSessionMoney()
    return {
        time  = _time,
        money = _money,
        moneyPerHour = moneyPerHour(_money, _time)
    }
end

function PiniGS:instance()
    tryUpdateInstanceInfo()
    local _time = 0
    local _money = 0
    
    if instance.isValid then
        _time  = getInstanceTime()
        _money = getInstanceMoney()
    end

    _moneyPerHour = moneyPerHour(_money, _time)
    _time = hmsToString(_time)

    return {
        inProgress = instance.inProgress,
        name = instance.name,
        difficultyName = instance.difficultyName,
        time  = _time,
        money = _money,
        moneyPerHour = _moneyPerHour
    }
end
