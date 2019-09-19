-- Author      : PiniponSelvagem
-- Create Date : 2019/06/30
-- Updated     : 2019/06/30
-- Based of    : xp_timer by jjacob (Jeff Jacob)

-- ENABLE lua debug errors: /console scriptErrors 1

local pgs = {};
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
    valid = false,
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
        colors.YELLOW .. "Pini GoldStats usage:|r",
        colors.YELLOW .. " /pgs|r -- Get information about gold earned",
        colors.YELLOW .. " /pgs help|r -- this help",
        colors.YELLOW .. " /pgs hour|r -- gold earned last hour",
        colors.YELLOW .. " /pgs instance|r -- last instance run gold stats",
        colors.YELLOW .. " /pgs reset|r -- reset your gold stats",
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


local pgs_frame = CreateFrame("Frame");
pgs_frame:RegisterEvent("ADDON_LOADED");
pgs_frame:RegisterEvent("PLAYER_LOGIN");
pgs_frame:RegisterEvent("PLAYER_MONEY");
pgs_frame:RegisterEvent("PLAYER_ENTERING_WORLD");

pgs_frame:SetScript("OnEvent",
    function(self,event,...)
        if pgs[event] and type(pgs[event]) == "function" then
            return pgs[event](pgs,...)
        end
    end
)

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
    hours   = math.floor(seconds / 3600);
    seconds = seconds - (hours * 3600);
    minutes = math.floor(seconds / 60);
    seconds = math.floor(seconds - (minutes * 60));
    return hours,minutes,seconds;
end
local function hmsToString(seconds)
    return string.format("%d:%.2d:%.2d", secondsToHMS(seconds));
end --to_hms_string

local function moneyToGSC(copper)
    local positive = 1;
    if copper < 0 then
        positive = -1;
    end
    copper = copper * positive;
    gold = math.floor(copper / 10000);
    copper = copper - (gold * 10000);
    silver = math.floor(copper / 100);
    copper = math.floor(copper - (silver * 100));
    return gold,silver,copper;
end
local function gscToString(copper)
    local ret = string.format("%d" .. colors.GOLD .. "g|r %d" .. colors.SILVER .. "s|r %d" .. colors.COPPER .."c|r", moneyToGSC(copper));
    if (copper < 0) then
        ret = "-" .. ret;
    end
    return ret;
end

local function moneyPerHour(money, seconds)
    return (money / seconds) * 3600;
end

function pgs:ADDON_LOADED(...)
    local addon = ...
    if addon == "Pini_GoldStats" then
        SlashCmdList["PINIGOLDSTATS"] = function(msg)
            pgs:handleSlashes(msg);
        end -- end function
        SLASH_PINIGOLDSTATS1 = "/pgs";
        SLASH_PINIGOLDSTATS2 = "/pini_goldstats";
    end
end

function pgs:PLAYER_LOGIN(...)
    --self:cash_timer_setup()
    self:reset();
end -- TODO

function pgs:handleSlashes(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$");
    --DEFAULT_CHAT_FRAME:AddMessage("^"..command.."^");
    --DEFAULT_CHAT_FRAME:AddMessage(rest);
    if command == "" then
        self:default();
    --elseif command == "on" or command == "off" then
    --    self:ctdefault(msg);
    else
        if self[command] and type(self[command]) == "function"  then
            return self[command](self,rest)
        else
            self:help(msg);
        end
    end
end

function pgs:default()
    local sessionTime  = GetTime()  - session.startTime;
    local sessionMoney = GetMoney() - session.startMoney;
    DEFAULT_CHAT_FRAME:AddMessage(strings.session.title);
    DEFAULT_CHAT_FRAME:AddMessage(string.format(strings.session.sessionTime, hmsToString(sessionTime)));
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
            strings.session.moneyTotal,
            gscToString(sessionMoney),
            gscToString(moneyPerHour(sessionMoney, sessionTime))
        )
    );
end

function pgs:help(msg)
    for v in arrayValues(strings["help"]) do
        DEFAULT_CHAT_FRAME:AddMessage(v);
    end
end

function pgs:hour()
    --[[
    local time_diff = GetTime() - self.start_time;
    if time_diff >= (3600) then
        local xp_per_hour = (self.xp_gained / time_diff) * 3600;
        DEFAULT_CHAT_FRAME:AddMessage("XP per hour: "..xp_per_hour);
    else
        DEFAULT_CHAT_FRAME:AddMessage("You have not been logged in without a reset for an hour");
        DEFAULT_CHAT_FRAME:AddMessage("Time Logged IN: "..xp_util.to_hms_string(time_diff));
    end
    ]]
end --TODO

function pgs:PLAYER_MONEY(...)
    --[[
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
    ]]
end -- TODO

function pgs:PLAYER_ENTERING_WORLD(...)
    --self:cash_timer_setup()
    if IsInInstance() then
        local name, type, difficultyIndex, difficultyName, maxPlayers,
            dynamicDifficulty, isDynamic, instanceMapId, lfgID = GetInstanceInfo();

        instance.valid = true;
        instance.inProgress = true;
        instance.wasShownOnLeave = false;
        instance.name = name;
        instance.difficultyName  = difficultyName;
        instance["time"].startT  = GetTime();
        instance["money"].startM = GetMoney();
    else
        if instance.wasShownOnLeave == false then
            instance.inProgress = false;
            instance["time"].endT  = GetTime();
            instance["money"].endM = GetMoney();
            pgs:instance();
            instance.wasShownOnLeave = true;
        end
    end
end

function pgs:instance()
    local instanceTitle;
    if instance.inProgress then
        instanceTitle = string.format(strings.instance.title,
                instance.name,
                instance.difficultyName,
                strings.instance.inProgress
        );
        instance["time"].endT  = GetTime();
        instance["money"].endM = GetMoney();
    else
        instanceTitle = string.format(strings.instance.title,
                instance.name,
                instance.difficultyName,
                strings.instance.done
        );
    end

    if instance.valid then
        local moneyTotal = instance["money"].endM - instance["money"].startM;
        local timeTotal  = instance["time"].endT - instance["time"].startT;
        DEFAULT_CHAT_FRAME:AddMessage(instanceTitle);
        DEFAULT_CHAT_FRAME:AddMessage(
                string.format(strings["instance"].info,
                    hmsToString(timeTotal),
                    gscToString(moneyTotal),
                    gscToString(moneyPerHour(moneyTotal, timeTotal))
                )
        );
    else
        DEFAULT_CHAT_FRAME:AddMessage(strings["instance"].invalid);
    end
end

function pgs:reset()
    session.startMoney = GetMoney();
    session.startTime  = GetTime();
    DEFAULT_CHAT_FRAME:AddMessage(strings["info"].RESET);
end