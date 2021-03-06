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
tabcbg:RegisterEvent("CHAT_MSG_ADDON")

tabcbg:RegisterEvent("UPDATE_WORLD_STATES")

-- todo
-- remove hp bars on run out yells, you seek to draw ...

tabcbg.debug = false

tabcbg.ab_rates = {
    [0] = { time = 999999, rate = 999999 },
    [1] = { time = 11, rate = 1.1 },
    [2] = { time = 10, rate = 1 },
    [3] = { time = 6, rate = 0.6 },
    [4] = { time = 3, rate = 0.3 },
    [5] = { time = 1, rate = 0.03333 }
};

tabcbg.ab_faction = 'alliance'

tabcbg.status = {
    ['a'] = {
        score = 0, bases = 0, lastUpdate = 0, updated = false
    },
    ['h'] = {
        score = 0, bases = 0, lastUpdate = 0, updated = false
    },
}

tabcbg.ab_isWinning = { faction = 0, score = 0 }; -- faction: 1-alliance 2-horde

tabcbg.AVBossNames = {
    'Captain Balinda Stonehearth',
    'Captain Galvangar',
    'Vanndar Stormpike',
    'Drek\'Thar'
}

tabcbg.bossHpBarStarted = {false, false, false, false}

function tabcbg:timeToWin(faction)
    if self.status[faction].score >= 2000 then
        return 0
    end

    local timePerTick = self.ab_rates[self.status[faction].bases].time
    local timeToNextTick = timePerTick - (time() - self.status[faction].lastUpdate)
    -- 6 - (0 - 0)

    if self.status[faction].score + 10 == 2000 then
        return timeToNextTick
    end

    return (((2000 - (self.status[faction].score + 10)) / 10) * timePerTick) + timeToNextTick;
end

function score_test(astart, hstart, abases, hbases, timers)
    tabcbg:update_ws(astart, hstart, abases, hbases, timers)
end

tabcbg.lastTimersUpdate = time()

--/run score_test(1000, 500, 3, 2)

function tabcbg:update_ws(astart, hstart, abases, hbases, timers)

    local inAb, inWsg = false, false
    for i = 1, MAX_BATTLEFIELD_QUEUES do
        local status, mapName = GetBattlefieldStatus(i);

        if status == "active" then
            if mapName == "Arathi Basin" then
                inAb = true
                TABCbg:Show()
                TABCbgAB:Show()
            end
            if mapName == "Warsong Gulch" then
                inWsg = true
                TABCbg:Show()
                TABCbgWSG:Show()
            end
        end
    end

    if not inAb and not inWsg then
        TABCbg:Hide()
        TABCbgAB:Hide()
        TABCbgWSG:Hide()
    end

    if not inAb then
        return
    end

    if self.lastTimersUpdate ~= time() or timers then
        self.lastTimersUpdate = time()

        local estimatedAlly, estimatedHorde, timeLeft, needed = 0, 0, 0, 0

        estimatedAlly, estimatedHorde, timeLeft, needed = tabcbg:ab_getData(astart, hstart, abases, hbases)

        --if estimatedAlly == 0 and estimatedHorde == 0 and timeLeft == 0 and needed == 0 then
        --    DEFAULT_CHAT_FRAME:AddMessage("all 0 return")
        --    return
        --end

        if timers then

            local estiAlianceTime = self:timeToWin('a');
            local estiHordeTime = self:timeToWin('h');

            -- need not good
            if needed and needed > 0 then
                if estiAlianceTime < estiHordeTime then
                    DEFAULT_CHAT_FRAME:AddMessage("Alliance needs : " .. needed)
                    DEFAULT_CHAT_FRAME:AddMessage("Horde needs : " .. (5 - needed))
                end
                if estiAlianceTime > estiHordeTime then
                    DEFAULT_CHAT_FRAME:AddMessage("Alliance needs : " .. (5 - needed))
                    DEFAULT_CHAT_FRAME:AddMessage("Horde needs : " .. needed)
                end
            end

            if estiAlianceTime > 0 and estiAlianceTime < 60 * 60 then
                self:BGBar("Alliance win", estiAlianceTime, 'inv_jewelry_trinketpvp_01', true)
            end
            if estiHordeTime > 0 and estiHordeTime < 60 * 60 then
                self:BGBar("Horde win", estiHordeTime, 'inv_jewelry_trinketpvp_02', true)
            end

            -- todo remove timers on "The * wins!"

        end

        --DEFAULT_CHAT_FRAME:AddMessage("eA:" .. estimatedAlly ..
        --        " eH:" .. estimatedHorde ..
        --        " TL:" .. timeLeft ..
        --        " need:" .. needed)


    end
end

function tabcbg:ab_win_bases_needed(a_score, h_score)
    if a_score and h_score then
        a_score = tonumber(a_score)
        h_score = tonumber(h_score)
        if (((2000 - a_score) * self.ab_rates[1].rate) < ((2000 - h_score) * self.ab_rates[4].rate)) then
            return 1
        elseif (((2000 - a_score) * self.ab_rates[2].rate) < ((2000 - h_score) * self.ab_rates[3].rate)) then
            return 2
        elseif (((2000 - a_score) * self.ab_rates[3].rate) < ((2000 - h_score) * self.ab_rates[2].rate)) then
            return 3
        elseif (((2000 - a_score) * self.ab_rates[4].rate) < ((2000 - h_score) * self.ab_rates[1].rate)) then
            return 4
        else
            return 5
        end
    else
        return ;
    end
end

function tabcbg:ab_score_after(faction, seconds)
    --*
    local timePerTick = self.ab_rates[self.status[faction].bases].time;

    local timeToNextTick = timePerTick - (time() - self.status[faction].lastUpdate);

    -- check for no changes until second
    if (timeToNextTick > seconds) then
        return self.status[faction].score;
    end

    return self.status[faction].score + 10 + (floor((seconds - timeToNextTick) / timePerTick) * 10);
end

function tabcbg:ab_getData(astart, hstart, abases, hbases)

    local winner;
    local scoreWinner;
    local estimatedTime, estimatedAlly, estimatedHorde, estiAlianceTime, estiHordeTime;

    local _, _, allyBases, allyScore
    local _, _, hordeBases, hordeScore

    if astart and hstart and abases and hbases then

        allyBases = abases
        allyScore = astart
        hordeBases = hbases
        hordeScore = hstart
    else
        local _, stat1 = GetWorldStateUIInfo(1);
        local _, stat2 = GetWorldStateUIInfo(2);
        _, _, allyBases, allyScore = string.find(stat1, "Bases: (%d+)  Resources: (%d+)/2000");
        _, _, hordeBases, hordeScore = string.find(stat2, "Bases: (%d+)  Resources: (%d+)/2000");
    end

    allyBases = tonumber(allyBases);
    hordeBases = tonumber(hordeBases);
    allyScore = tonumber(allyScore);
    hordeScore = tonumber(hordeScore);

    local needed = self:ab_win_bases_needed(allyScore, hordeScore);

    if not allyScore or not hordeScore or allyScore == 2000 or hordeScore == 2000 then
        --DEFAULT_CHAT_FRAME:AddMessage("1")
        return 0, 0, 0, 0
    end

    self.status['a'].bases = allyBases
    self.status['h'].bases = hordeBases

    if self.status['a'].lastUpdate == 0 then
        self.status['a'].score = allyScore
        self.status['a'].lastUpdate = time()
    end
    if self.status['h'].lastUpdate == 0 then
        self.status['h'].score = hordeScore
        self.status['h'].lastUpdate = time()
    end

    -- check for 5-0
    if allyBases == 5 then
        return 2000, hordeScore, 0, 0;
    end
    if hordeBases == 5 then
        return allyScore, 2000, 0, 0;
    end

    if allyBases == 0 and hordeBases == 0 then
        --DEFAULT_CHAT_FRAME:AddMessage("2")
        return 0, 0, 0, 0;
    end

    if allyBases == 0 then
        self.status['a'].updated = true;
    end

    if hordeBases == 0 then
        self.status['h'].updated = true;
    end

    if allyScore ~= self.status['a'].score then
        self.status['a'].score = allyScore
        self.status['a'].lastUpdate = time()
        self.status['a'].updated = true
    end
    if hordeScore ~= self.status['h'].score then
        self.status['h'].score = hordeScore
        self.status['h'].lastUpdate = time()
        self.status['h'].updated = true
    end

    --if not self.status['a'].updated or not self.status['h'].updated then
    --    DEFAULT_CHAT_FRAME:AddMessage("3")
    --    return 0, 0, 0, 0;
    --end

    estiAlianceTime = self:timeToWin('a');
    estiHordeTime = self:timeToWin('h');
    --DEFAULT_CHAT_FRAME:AddMessage("estiAlianceTime " .. estiAlianceTime)
    --DEFAULT_CHAT_FRAME:AddMessage("estiHordeTime " .. estiHordeTime)

    if (estiHordeTime > estiAlianceTime) or (hordeBases == 0) then
        -- aliance victory
        estimatedAlly = 2000;
        estimatedHorde = self:ab_score_after('h', estiAlianceTime);
        winner = 1;
        scoreWinner = allyScore;
        estimatedTime = estiAlianceTime;
    else
        estimatedHorde = 2000;
        estimatedAlly = self:ab_score_after('a', estiHordeTime);
        winner = 2;
        scoreWinner = hordeScore;
        estimatedTime = estiHordeTime;
    end

    local timeLeft = 0
    local lastLeftTimerUpdate

    if estimatedTime then
        -- only return estimatedTime for resources changes on winner
        if (winner ~= self.ab_isWinning.faction) or (scoreWinner ~= self.ab_isWinning.score) then
            timeLeft = estimatedTime;
            lastLeftTimerUpdate = time();
            self.ab_isWinning.faction = winner;
            self.ab_isWinning.score = scoreWinner;
            --DEFAULT_CHAT_FRAME:AddMessage("4")
            --DEFAULT_CHAT_FRAME:AddMessage("timeleft " .. timeLeft)
            return estimatedAlly, estimatedHorde, estimatedTime, needed;
        else
            --DEFAULT_CHAT_FRAME:AddMessage("5")
            --DEFAULT_CHAT_FRAME:AddMessage("estimatedTime " .. estimatedTime)
            return estimatedAlly, estimatedHorde, timeLeft, needed;
        end
    else
        --DEFAULT_CHAT_FRAME:AddMessage("6")
        return estimatedAlly, estimatedHorde, 0, needed;
    end

end

tabcbg:SetScript("OnEvent", function()
    if event then
        if event == "UPDATE_WORLD_STATES" then
            tabcbg:update_ws()
        end
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
        if event == 'CHAT_MSG_ADDON' and arg1 == "TABCBG" then
            if arg4 ~= UnitName('player') or true then --debug
                tabcbg:addon(arg2)
            end
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

tabcbg.startingMin = "The Battle for (.+) begins in 1 minute."
tabcbg.startingMinLower = "The battle for (.+) begins in 1 minute."

--1 minute untill the battle for Alterac Valley begins.
--30 minute untill the battle for Alterac Valley begins.

tabcbg.startingSec = "The Battle for (.+) begins in 30 seconds. Prepare yourselves!"
tabcbg.startingSecLower = "The battle for (.+) begins in 30 seconds. Prepare yourselves!"

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
        self:BGBar("Flag respawn", 24, 'inv_banner_03', true)
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

    if not BigWigs then
        -- this addon requires bigwigs
        return
    end

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

function TABCBG_AV_checkBossHP()
    local health, maxhealth, hpPercent

    for index, bossName in tabcbg.AVBossNames do

        if UnitName("playertarget") == bossName then
            health = UnitHealth("playertarget")
        end

        for i = 1, GetNumRaidMembers(), 1 do
            if UnitName("Raid" .. i .. "target") == bossName then
                health = UnitHealth("Raid" .. i .. "target")
                maxhealth = UnitHealthMax("Raid" .. i .. "target")
                break
            end
        end

        if health1 then
            hpPercent = math.floor(health * 100 / maxhealth)
            SendAddonMessage("TABCBG", "boss:" .. index .. ":" .. hpPercent, "BATTLEGROUND")
        end

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

    L:TriggerEvent("BigWigs_SetHPBar", L, name, 100 - hp)
end

function tabcbg:ABEvent(msg, bar_icon)

    --DEFAULT_CHAT_FRAME:AddMessage("AB Event: " .. msg)

    self:update_ws(nil, nil, nil, nil, true)

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

    local _, _, bg1l = string.find(msg, self.startingMinLower)
    if bg1l then
        self:BGBar("Game Start", 60, 'inv_misc_pocketwatch_01', true)
        return
    end

    local _, _, bg30l = string.find(msg, self.startingSecLower)
    if bg30l then
        self:BGBar("Game Start", 30, 'inv_misc_pocketwatch_01', true)
        return
    end
end

function tabcbg:addon(msg)
    --boss:1:20
    local m = string.split(msg, ':')
    if m[3] then
        if not self.bossHpBarStarted[tonumber(m[2])] then
            self:startHpBar(self.AVBossNames[tonumber(m[2])], 100, "inv_bannerpvp_02")
            self:setHpBar(self.AVBossNames[tonumber(m[2])], 100)
            self.bossHpBarStarted[tonumber(m[2])] = true
        else
            self:setHpBar(self.AVBossNames[tonumber(m[2])], tonumber(m[3]))
        end
    end
end

-- hp timers
tabcbg.hpCheck = CreateFrame("Frame")
tabcbg.hpCheck:Hide()
tabcbg.hpCheck:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
tabcbg.hpCheck:SetScript("OnUpdate", function()
    local plus = 1 --seconds
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        TABCBG_AV_checkBossHP()
    end
end)

SLASH_TABCBG1 = "/tabcbg"
SlashCmdList["TABCBG"] = function(cmd)
    if cmd then
        if string.find(cmd, "wsg") then
            if TABCbgWSG:IsVisible() then
                TABCbg:Hide()
                TABCbgWSG:Hide()
            else
                TABCbg:Show()
                TABCbgWSG:Show()
            end
        end
        if string.find(cmd, "ab") then
            if TABCbgAB:IsVisible() then
                TABCbg:Hide()
                TABCbgAB:Hide()
            else
                TABCbg:Show()
                TABCbgAB:Show()
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