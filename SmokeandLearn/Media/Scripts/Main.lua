-- Function to check if a player is sitting and smoking
local function isSittingAndSmoking(player)
    return player:getModData().isSitting and player:isCurrentState("IsSmoking")
end

-- Function to check if players are within a 3x3 area
local function arePlayersInProximity(player1, player2)
    local x1, y1, z1 = player1:getX(), player1:getY(), player1:getZ()
    local x2, y2, z2 = player2:getX(), player2:getY(), player2:getZ()
    return math.abs(x1 - x2) <= 1.5 and math.abs(y1 - y2) <= 1.5 and z1 == z2
end

-- Function to calculate experience multiplier
local function calculateExperience(level)
    local multiplier = math.floor(level / 3)
    return 100 * (5 ^ multiplier)
end

-- Function to give experience to all attributes
local function giveExperience(player)
    local xpAmount = calculateExperience(player:getPerkLevel(Perks.FromString("all")))
    local stats = player:getStats()
    
    for i = 1, stats:size() do
        local stat = stats:get(i - 1)
        player:getXp():AddXP(stat, xpAmount)
    end
end

-- Function to handle player stats increase
local function increasePlayerStats(player)
    player:getStats():setHealth(player:getStats():getHealth() + 0.1)
    player:getStats():setHunger(player:getStats():getHunger() - 0.01)
    player:getStats():setThirst(player:getStats():getThirst() - 0.001)
end

-- Function to share skills among players in a session
local function shareSkills(players)
    local sharedSkills = {}

    -- Collect skills from all players
    for _, player in ipairs(players) do
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            local perkName = perk:getName()
            if not sharedSkills[perkName] then
                sharedSkills[perkName] = {totalXP = 0, count = 0}
            end
            local perkLevel = player:getPerkLevel(perk)
            local perkXP = player:getXp():getXP(perk)
            sharedSkills[perkName].totalXP = sharedSkills[perkName].totalXP + perkXP
            sharedSkills[perkName].count = sharedSkills[perkName].count + 1
        end
    end

    -- Share average skills with all players
    for _, player in ipairs(players) do
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            local perkName = perk:getName()
            if sharedSkills[perkName] then
                local averageXP = sharedSkills[perkName].totalXP / sharedSkills[perkName].count
                local currentXP = player:getXp():getXP(perk)
                if currentXP < averageXP then
                    player:getXp():setXPToLevel(perk, averageXP)
                end
            end
        end
    end
end

-- Function to check nearby players and form sessions
local function checkAndGiveXP()
    local players = getOnlinePlayers()
    local sessions = {}

    for i = 1, players:size() do
        local player = players:get(i - 1)

        if isSittingAndSmoking(player) then
            local foundSession = false

            for _, session in ipairs(sessions) do
                if #session < 4 and arePlayersInProximity(player, session[1]) then
                    table.insert(session, player)
                    foundSession = true
                    break
                end
            end

            if not foundSession then
                table.insert(sessions, {player})
            end
        end
    end

    for _, session in ipairs(sessions) do
        if #session < 2 then
            -- Do nothing for sessions with less than 2 players
        elseif #session > 4 then
            for _, player in ipairs(session) do
                player:Say("No Randos")
            end
        else
            for _, player in ipairs(session) do
                giveExperience(player)
                increasePlayerStats(player)
            end
            shareSkills(session)
        end
    end
end

-- Hook the function to the game's update event
Events.OnTick.Add(checkAndGiveXP)
