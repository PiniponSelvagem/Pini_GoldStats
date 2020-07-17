if (IsAddOnLoaded("ElvUI")) then

    local E, L, V, P, G = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
    local DT = E:GetModule('DataTexts')
    local format = format

    local enteredFrame = false
    local initialUpdateTimer = 5
    local updateTimer = initialUpdateTimer

    local text = {
        PLUS = "|cFF00FF00+ |r",
        NEG  = "|cFFFF0000- |r",

        PLUS_P_H = "|cFF00FF00 / h|r",
        ZERO_P_H = "|r / h|r",
        NEG_P_H  = "|cFFFF0000 / h|r",

        MAIN_TITLE = "Pini - GoldStats",

        PER_HOUR     = "Per hour:",
        EARNED       = "Earned:",
        DEFICIT      = "Deficit:",
        STATUS       = "Status:",
        NAME         = "Name:",
        DIFFICULTY   = "Difficulty:",
        RUN_TIME     = "Run time:",
        TIME         = "Time:",
        
        SESSION  = "Session:",
        INSTANCE = "Instance:",

        INSTANCE_DONE = "Done",
        INSTANCE_IN_PROGRESS = "In progress..."
    }

    local function onEvent(self, event, ...)
        local textOnly = not E.db.datatexts.goldCoins and true or false
        local style = E.db.datatexts.goldFormat or 'BLIZZARD'
        local session = PiniGS.session()

        if session.moneyPerHour > 0 then
            self.text:SetText(text.PLUS .. E:FormatMoney(session.moneyPerHour, style, textOnly) .. text.PLUS_P_H)
        elseif session.moneyPerHour < 0 then
            self.text:SetText(text.NEG .. E:FormatMoney(session.moneyPerHour, style, textOnly) .. text.NEG_P_H)
        else
            self.text:SetText(E:FormatMoney(session.moneyPerHour, style, textOnly) .. text.ZERO_P_H)
        end
    end

    local function onEnter(self)
        local session  = PiniGS.session()
        local instance = PiniGS.instance()

        enteredFrame = true

        DT:SetupTooltip(self)

        local textOnly = not E.db.datatexts.goldCoins and true or false
        local style = E.db.datatexts.goldFormat or 'BLIZZARD'

        DT.tooltip:AddLine(L[text.MAIN_TITLE])
        DT.tooltip:AddLine(" ")

        --[[ ---- SESSION ---- ]]
        DT.tooltip:AddLine(L[text.SESSION])
        DT.tooltip:AddDoubleLine(L[text.TIME], session.time, 1, 1, 1, 1, 1, 1)

        if session.money >= 0 then
            DT.tooltip:AddDoubleLine(L[text.EARNED], E:FormatMoney(session.money, style, textOnly), 1, 1, 1, 1, 1, 1)
        else
            DT.tooltip:AddDoubleLine(L[text.DEFICIT], E:FormatMoney(session.money, style, textOnly), 1, 0, 0, 1, 1, 1)
        end

        if session.moneyPerHour > 0 then
            DT.tooltip:AddDoubleLine(L[text.PER_HOUR], E:FormatMoney(session.moneyPerHour, style, textOnly), 0, 1, 0, 1, 1, 1)
        elseif session.moneyPerHour < 0 then
            DT.tooltip:AddDoubleLine(L[text.PER_HOUR], "- " .. E:FormatMoney(session.moneyPerHour, style, textOnly), 1, 0, 0, 1, 1, 1)
        else
            DT.tooltip:AddDoubleLine(L[text.PER_HOUR], E:FormatMoney(session.moneyPerHour, style, textOnly), 1, 1, 1, 1, 1, 1)
        end

        DT.tooltip:AddLine(" ")

        --[[ ---- INSTANCE ---- ]]
        DT.tooltip:AddLine(L[text.INSTANCE])
        if instance.inProgress then
            DT.tooltip:AddDoubleLine(L[text.STATUS], text.INSTANCE_IN_PROGRESS, 1, 1, 1, 1, 0, 1)
        else
            DT.tooltip:AddDoubleLine(L[text.STATUS], text.INSTANCE_DONE, 1, 1, 1, 0, 1, 0)
        end
        DT.tooltip:AddDoubleLine(L[text.NAME], instance.name, 1, 1, 1, 0, 1, 1)
        DT.tooltip:AddDoubleLine(L[text.DIFFICULTY], instance.difficultyName, 1, 1, 1, 1, 1, 1)
        DT.tooltip:AddDoubleLine(L[text.RUN_TIME], instance.time, 1, 1, 1, 1, 1, 1)

        if instance.money >= 0 then
            DT.tooltip:AddDoubleLine(L[text.EARNED], E:FormatMoney(instance.money, style, textOnly), 1, 1, 1, 1, 1, 1)
        else
            DT.tooltip:AddDoubleLine(L[text.DEFICIT], E:FormatMoney(instance.money, style, textOnly), 1, 0, 0, 1, 1, 1)
        end
        
        if instance.moneyPerHour > 0 then
            DT.tooltip:AddDoubleLine(L[text.PER_HOUR], E:FormatMoney(instance.moneyPerHour, style, textOnly), 0, 1, 0, 1, 1, 1)
        elseif instance.moneyPerHour < 0 then
            DT.tooltip:AddDoubleLine(L[text.PER_HOUR], "- " .. E:FormatMoney(instance.moneyPerHour, style, textOnly), 1, 0, 0, 1, 1, 1)
        else
            DT.tooltip:AddDoubleLine(L[text.PER_HOUR], E:FormatMoney(instance.moneyPerHour, style, textOnly), 1, 1, 1, 1, 1, 1)
        end

        DT.tooltip:AddLine(" ")
        DT.tooltip:Show()
    end

    local function onLeave()
        enteredFrame = false
        DT.tooltip:Hide()
    end

    local function update(self, frametime)
        updateTimer = updateTimer - frametime

        if updateTimer < 0 then
            local textOnly = not E.db.datatexts.goldCoins and true or false
            local style = E.db.datatexts.goldFormat or 'BLIZZARD'
            local session = PiniGS.session()

            if session.moneyPerHour > 0 then
                self.text:SetText(text.PLUS .. E:FormatMoney(session.moneyPerHour, style, textOnly) .. text.PLUS_P_H)
            elseif session.moneyPerHour < 0 then
                self.text:SetText(text.NEG .. E:FormatMoney(session.moneyPerHour, style, textOnly) .. text.NEG_P_H)
            else
                self.text:SetText(E:FormatMoney(session.moneyPerHour, style, textOnly) .. text.ZERO_P_H)
            end

            updateTimer = initialUpdateTimer
        end
    end
        
    --[[
        DT:RegisterDatatext(name, events, eventFunc, updateFunc, clickFunc, onEnterFunc, onLeaveFunc)

        name - name of the datatext (required)
        events - must be a table with string values of event names to register
        eventFunc - function that gets fired when an event gets triggered
        updateFunc - onUpdate script target function
        click - function to fire when clicking the datatext
        onEnterFunc - function to fire OnEnter
        onLeaveFunc - function to fire OnLeave, if not provided one will be set for you that hides the tooltip.
    ]]
    DT:RegisterDatatext('PGS - session gold/h', nil, {"PLAYER_ENTERING_WORLD", "PLAYER_MONEY"}, onEvent, update, nil, onEnter, onLeave)
end