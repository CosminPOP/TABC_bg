local tabcbg = CreateFrame("Frame")

tabcbg.hpCheck = CreateFrame("Frame")
tabcbg.hpCheck:Hide()

tabcbg.bg = 'none'

tabcbg:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
tabcbg:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
tabcbg:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")

tabcbg:RegisterEvent("CHAT_MSG_MONSTER_YELL")
tabcbg:RegisterEvent("CHAT_MSG_SYSTEM")

tabcbg:RegisterEvent("CHAT_MSG_SAY")

tabcbg.debug = false

--CHAT_MSG_SAY

tabcbg:SetScript("OnEvent", function()
    if event then
        if event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" or (tabcbg.debug and event == 'CHAT_MSG_SAY') then
            tabcbg:bg_neutral(arg1)
        end
        if event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" or (tabcbg.debug and event == 'CHAT_MSG_SAY') then
            tabcbg:bg_a(arg1)
        end
        if event == "CHAT_MSG_BG_SYSTEM_HORDE" or (tabcbg.debug and event == 'CHAT_MSG_SAY') then
            tabcbg:bg_h(arg1)
        end
        if event == "CHAT_MSG_MONSTER_YELL" or (tabcbg.debug and event == 'CHAT_MSG_SAY') then
            tabcbg:yell(arg1)
        end
        if event == "CHAT_MSG_SYSTEM" or (tabcbg.debug and event == 'CHAT_MSG_SAY') then
            tabcbg:system(arg1)
        end
    end
end)

tabcbg.icon = {
    bannerA = "inv_bannerpvp_02",
    bannerH = "inv_bannerpvp_01",
}

tabcbg.timer = {
    ab = 60,
    av = 60 * 5
}

tabcbg.startingMin = "The battle for (.+) begins in 1 minute."
tabcbg.startingSec = "The battle for (.+) begins in 30 seconds. Prepare yourselves!"

tabcbg.begun = "The battle for (.+) has begun!"

tabcbg.endingMins = "Not enough players. This game will close in (.+) mins."
tabcbg.endingMin = "Not enough players. This game will close in 1 min."
tabcbg.endingSec = "Not enough players. This game will close in (.+) seconds."

tabcbg.defended = "(.+) has defended the (.+)"
tabcbg.assaulted = "(.+) has assaulted the (.+)"
tabcbg.claimed = "(.+) claims the (.+)! If left unchallenged, the (.+) will control it in 1 minute!"

tabcbg.capturedFlag = "(.+) captured the (.+) flag!"


tabcbg.gy_trigger_under_attack = "(.+) is under attack! If left unchecked, the (.+) will capture it!"
tabcbg.tower_trigger_under_attack = "(.+) is under attack! If left unchecked, the (.+) will destroy it!"
tabcbg.defended_trigger = "(.+) was taken by the (.+)!"

local AlteracValleyYellTriggers = {
    "Begone, uncouth scum! The Alliance shall prevail in Alterac Valley!",
    "Filthy Frostwolf cowards! If you want a fight, you'll have to come to me!",
    "Die! Your kind has no place in Alterac Valley!",
    "I'll never fall for that, fool! If you want a battle it will be on my terms and in my lair!"
}


function tabcbg_test()
    tabcbg:bg_neutral("Er has assaulted the farm", "a")
end

function tabcbg:system(msg)

    local _, _, closeMins = string.find(msg, self.endingMins)
    if closeMins then
        --todo fix icon
        self:BGBar("Game Closing", tonumber(closeMins) * 60, 'inv_misc_pocketwatch_02', true)
        return
    end

    if msg == self.endingMin then
        --todo fix icon
        self:BGBar("Game Closing", 60, 'inv_misc_pocketwatch_02', true)
        return
    end

    local _, _, closeSec = string.find(msg, self.endingSec)
    if closeSec then
        --todo fix icon
        self:BGBar("Game Closing", tonumber(closeSec), 'inv_misc_pocketwatch_02', true)
        return
    end

end

function tabcbg:bg_neutral(msg, faction)

    if string.find(msg, 'Arathi Basin') then
        tabcbg.bg = 'ab'
    end
    if string.find(msg, 'farm')
            or string.find(msg, 'stables')
            or string.find(msg, 'blacksmith')
            or string.find(msg, 'lumber mill')
            or string.find(msg, 'gold mine')
    then
        tabcbg.bg = 'ab'
    end

    if tabcbg.bg == 'ab' then
        local icon = tabcbg.icon.bannerA
        if faction == 'h' then
            icon = tabcbg.icon.bannerH
        end
        self:ABEvent(msg, icon)
    end

    local _, _, name, f = string.find(msg, tabcbg.capturedFlag)
    if name and f then
        self:BGBar("Flag respawn", 20, 'inv_banner_03', true)
    end

end

function tabcbg:bg_a(msg)
    self:bg_neutral(msg, 'a')
end

function tabcbg:bg_h(msg)
    self:bg_neutral(msg, 'h')
end

function tabcbg:yell(msg)
    local _, _, graveyard, gfaction = string.find(msg, self.gy_trigger_under_attack)

    if graveyard and gfaction then

        local l_icon = self.icon.bannerA
        if gfaction == 'Horde' then
            l_icon = self.icon.bannerH
        end

        self:BGBar(graveyard, self.timer.av, l_icon, true)
        return
    end

    local _, _, tower, tfaction = string.find(msg, self.tower_trigger_under_attack)

    if tower and tfaction then

        local l_icon = self.icon.bannerA
        if tfaction == 'Horde' then
            l_icon = self.icon.bannerH
        end

        self:BGBar(tower, self.timer.av, l_icon, true)
        return
    end

    local _, _, obj, faction = string.find(msg, self.defended_trigger)
    if obj and faction then
        self:BGBar(obj, nil, nil, false)
        return
    end
end

function start_hp_bar()
    tabcbg:startHpBar("Drekk HP", 100, "inv_bannerpvp_02")
    tabcbg:setHpBar("Drekk HP", 100)
end

function set_hp_bar()
    tabcbg:setHpBar("Drekk HP", 25)
end

function tabcbg:BGBar(name, duration, icon, add_bar)

    if not BigWigs:IsActive() then
        BigWigsOptions:OnClick()
    end

    local L = BigWigs:GetModule("Test")


    L:RemoveBar(fixBase(name))
    if add_bar then
        L:Bar(fixBase(name), duration, icon)
    end

end



tabcbg.hpCheck:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

tabcbg.hpCheck:SetScript("OnHide", function()
end)

tabcbg.hpCheck:SetScript("OnUpdate", function()
    local plus = 1 --seconds
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
    end
end)

function aCheckAddHP()
    local health1, maxhealth1
    local health2, maxhealth2
    if UnitName("playertarget") == L["add1"] then
        health1 = UnitHealth("playertarget")
    elseif UnitName("playertarget") == L["add2"] then
        health2 = UnitHealth("playertarget")
    end

    for i = 1, GetNumRaidMembers(), 1 do
        if UnitName("Raid"..i.."target") == L["add1"] then
            health1 = UnitHealth("Raid"..i.."target")
            maxhealth1 = UnitHealthMax("Raid"..i.."target")
        elseif UnitName("Raid"..i.."target") == L["add2"] then
            health2 = UnitHealth("Raid"..i.."target")
            maxhealth2 = UnitHealthMax("Raid"..i.."target")
        end
        if health1 and health2 then break; end
    end

    if health1 and maxhealth1 then
        self.add1HP = health1 * 100 / maxhealth1
        self:TriggerEvent("BigWigs_SetHPBar", self, L["add1"], 100-self.add1HP)
    end

    if health2 and maxhealth2 then
        self.add2HP = health2 * 100 / maxhealth2
        self:TriggerEvent("BigWigs_SetHPBar", self, L["add2"], 100-self.add2HP)
    end
end

function tabcbg:startHpBar(name, hp, icon)
    if not BigWigs:IsActive() then
        BigWigsOptions:OnClick()
    end

    local L = BigWigs:GetModule("Test")

    L:TriggerEvent("BigWigs_StartHPBar", L, name, hp)
end

function tabcbg:setHpBar(name, hp)
    if not BigWigs:IsActive() then
        BigWigsOptions:OnClick()
    end

    local L = BigWigs:GetModule("Test")

    L:TriggerEvent("BigWigs_SetHPBar", L, name, 100-hp)
end


function tabcbg:ABEvent(msg, bar_icon)

    DEFAULT_CHAT_FRAME:AddMessage("AB Event: " .. msg)

    local _, _, a_player, a_base = string.find(msg, self.assaulted)
    local _, _, d_player, d_base = string.find(msg, self.defended)
    local _, _, c_player, c_base = string.find(msg, self.claimed)

    local base = false
    local add = true

    if a_player and a_base then
        add = true
        base = a_base
    elseif d_player and d_base then
        add = false
        base = d_base
    elseif c_player and c_base then
        add = true
        base = c_base
    end

    if base then
        self:BGBar(base, self.timer.ab, bar_icon, add)
        return
    end

    local _, _, bg1 = string.find(msg, self.startingMin)
    if bg1 then
        self:BGBar("Game Start", 60, 'inv_misc_pocketwatch_01', true)
        return
    end

    local _, _, bg30 = string.find(msg, self.startingSec)
    if bg30 then
        self:BGBar("Game Start", 30, 'inv_misc_pocketwatch_01', true)
        return
    end
end


SLASH_TABCBG1 = "/tabcbg"
SlashCmdList["TABCBG"] = function(cmd)
    if cmd then
        if string.find(cmd, "bg") then
            if TABCbg:IsVisible() then
                TABCbg:Hide()
            else
                TABCbg:Show()
            end
        end
    end
end

function fixBase(f)
    if f == 'lumber mill' then
        return 'Lumber Mill'
    end
    return bw_ucFirst(f)
end

function bw_ucFirst(a)
    return string.upper(string.sub(a, 1, 1)) .. string.lower(string.sub(a, 2, string.len(a)))
end