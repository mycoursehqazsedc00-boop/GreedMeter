--[[
    GreedMeter - CombatHub Adapter
    Routes Nampower combat/roster events through CombatHub without modifying
    Backend_Nampower.lua.
    Strict Lua 5.0.
]]

if not CombatHub or type(CombatHub.OnPostLogin) ~= "function" then
    return
end

CombatHub:OnPostLogin(function()
    local GM = GreedMeter
    local NS = GM and GM.ParserNS
    local NP = NS and NS.Backends and NS.Backends.Nampower
    if not NS or NS.combatBackend ~= "nampower" or not NP or not NP.frame then
        return
    end

    local events = {
        "AUTO_ATTACK_SELF",
        "AUTO_ATTACK_OTHER",
        "SPELL_DAMAGE_EVENT_SELF",
        "SPELL_DAMAGE_EVENT_OTHER",
        "SPELL_MISS_SELF",
        "SPELL_MISS_OTHER",
        "SPELL_HEAL_BY_SELF",
        "SPELL_HEAL_BY_OTHER",
        "SPELL_DISPEL_BY_SELF",
        "SPELL_DISPEL_BY_OTHER",
        "AURA_CAST_ON_SELF",
        "AURA_CAST_ON_OTHER",
        "BUFF_ADDED_SELF",
        "BUFF_ADDED_OTHER",
        "BUFF_REMOVED_SELF",
        "BUFF_REMOVED_OTHER",
        "DEBUFF_ADDED_SELF",
        "DEBUFF_ADDED_OTHER",
        "DEBUFF_REMOVED_SELF",
        "DEBUFF_REMOVED_OTHER",
        "DAMAGE_SHIELD_SELF",
        "DAMAGE_SHIELD_OTHER",
        "ENVIRONMENTAL_DMG_SELF",
        "ENVIRONMENTAL_DMG_OTHER",
        "UNIT_DIED",
        "UNIT_PET",
        "PLAYER_ENTERING_WORLD",
        "PARTY_MEMBERS_CHANGED",
        "RAID_ROSTER_UPDATE",
    }

    local function Attach()
        if not NS or NS.combatBackend ~= "nampower" or not NP or not NP.frame then
            return
        end
        local f = NP.frame
        local origOnEvent = f:GetScript("OnEvent")
        if type(origOnEvent) ~= "function" then return end

        f:UnregisterAllEvents()

        CombatHub:Subscribe("GreedMeter", "GreedMeter (Raid)", events, function(ev, a1, a2, a3, a4, a5, a6, a7, a8, a9)
            CombatHub:InvokeFrameOnEvent(f, origOnEvent, ev, a1, a2, a3, a4, a5, a6, a7, a8, a9)
        end, nil)
    end

    Attach()

    if type(NP.Disable) == "function" and not NP._combatHubDisableHooked then
        local origDisable = NP.Disable
        NP.Disable = function()
            CombatHub:Unsubscribe("GreedMeter")
            return origDisable()
        end
        NP._combatHubDisableHooked = true
    end

    if type(NP.Enable) == "function" and not NP._combatHubEnableHooked then
        local origEnable = NP.Enable
        NP.Enable = function()
            local ok = origEnable()
            if ok then
                Attach()
            end
            return ok
        end
        NP._combatHubEnableHooked = true
    end
end)
