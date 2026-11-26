--[[
    GreedMeter - UI / Skin_pfUI
    Optional pfUI-synchronized skin for GreedMeter windows and header buttons.
    Keeps pfUI upstream files completely untouched.
    Strict Lua 5.0 (Vanilla-Safe Mode).
]]

local OM = GreedMeter
local UI = OM and OM.UI
if not OM or not UI then return end

local Skin = {}
UI.PfUISkin = Skin

local TOOLTIP_WINDOW_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local TOOLTIP_BTN_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function HasPfUI()
    return pfUI and pfUI.api and type(pfUI.api.CreateBackdrop) == "function"
end

function Skin:IsEnabled()
    if not HasPfUI() then return false end
    return OM.GetSetting and OM:GetSetting("pfuiSkin") == true
end

local function ParsePfUIColor(str, dr, dg, db, da)
    if str and pfUI and pfUI.api and type(pfUI.api.GetStringColor) == "function" then
        local r, g, b, a = pfUI.api.GetStringColor(str)
        r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
        if r and g and b then
            return r, g, b, a or da or 1
        end
    end
    return dr, dg, db, da
end

local function GetPfUIColors()
    local borderCfg = pfUI_config and pfUI_config.appearance and pfUI_config.appearance.border
    local br, bg, bb, ba = ParsePfUIColor(borderCfg and borderCfg.background, 0.08, 0.08, 0.08, 0.75)
    local er, eg, eb, ea = ParsePfUIColor(borderCfg and borderCfg.color, 0.20, 0.20, 0.20, 1.00)
    return br, bg, bb, ba, er, eg, eb, ea
end

local function ApplyButtonFont(label, isPfUI)
    if not label or not label.SetFont then return end
    if isPfUI and pfUI and pfUI.font_default then
        local size = (pfUI_config and pfUI_config.global and tonumber(pfUI_config.global.font_size)) or 10
        if size > 11 then size = 11 end
        label:SetFont(pfUI.font_default, size, "OUTLINE")
    else
        local font, size = GameFontHighlightSmall:GetFont()
        if font then
            label:SetFont(font, size or 10, "")
        end
    end
end

local function SkinHeaderButton(btn, label, modeCol, colorWithMode)
    if not btn then return end
    local br, bg, bb, ba, er, eg, eb, ea = GetPfUIColors()

    if not btn._pfuiSkinned then
        pfUI.api.CreateBackdrop(btn, -1, true, 0.75)
        btn._pfuiSkinned = true
    else
        -- Re-apply pfUI flat backdrop if something reset it
        pfUI.api.CreateBackdrop(btn, -1, true, 0.75)
    end

    if colorWithMode and modeCol then
        btn:SetBackdropColor(modeCol[1], modeCol[2], modeCol[3], 0.35)
        btn:SetBackdropBorderColor(modeCol[1], modeCol[2], modeCol[3], 0.90)
    else
        btn:SetBackdropColor(br, bg, bb, ba)
        btn:SetBackdropBorderColor(er, eg, eb, ea)
    end

    if label then
        ApplyButtonFont(label, true)
    end

    if not btn._pfuiHoverHooked then
        local origEnter = btn:GetScript("OnEnter")
        local origLeave = btn:GetScript("OnLeave")
        btn:SetScript("OnEnter", function()
            if origEnter then origEnter() end
            if Skin:IsEnabled() then
                this:SetBackdropBorderColor(1, 1, 1, 1)
            end
        end)
        btn:SetScript("OnLeave", function()
            if origLeave then origLeave() end
            if Skin:IsEnabled() then
                local parent = this:GetParent()
                local cwm = OM.GetSetting and OM:GetSetting("buttonsColorWithMode") == true
                local mc = cwm and parent and UI.GetModeColor and UI.GetModeColor(parent.mode or "damage")
                if mc then
                    this:SetBackdropBorderColor(mc[1], mc[2], mc[3], 0.90)
                else
                    local _, _, _, _, r, g, b, a = GetPfUIColors()
                    this:SetBackdropBorderColor(r, g, b, a)
                end
            end
        end)
        btn._pfuiHoverHooked = true
    end
end

local function RestoreHeaderButton(btn, label)
    if not btn then return end
    if btn._pfuiSkinned then
        btn:SetBackdrop(TOOLTIP_BTN_BACKDROP)
        btn:SetBackdropColor(0.15, 0.15, 0.15, 0.75)
        btn:SetBackdropBorderColor(0.55, 0.55, 0.55, 1)
        btn._pfuiSkinned = nil
    end
    if label then
        ApplyButtonFont(label, false)
    end
end

local HEADER_BUTTON_FIELDS = {
    { btn = "resetBtn",    lbl = "resetLabel" },
    { btn = "nameBtn",     lbl = "nameLabel" },
    { btn = "announceBtn", lbl = "announceLabel" },
    { btn = "addBtn",      lbl = "addLabel" },
    { btn = "removeBtn",   lbl = "removeLabel" },
    { btn = "segBtn",      lbl = "segLabel" },
    { btn = "modeBtn",     lbl = "modeLabel" },
}

function Skin:ApplyToFrame(f)
    if not f then return end

    if not self:IsEnabled() then
        if f._pfuiWindowSkinned then
            if f.backdrop then
                f.backdrop:Hide()
            end
            f:SetBackdrop(TOOLTIP_WINDOW_BACKDROP)
            f._pfuiWindowSkinned = nil
            local i
            for i = 1, table.getn(HEADER_BUTTON_FIELDS) do
                local pair = HEADER_BUTTON_FIELDS[i]
                RestoreHeaderButton(f[pair.btn], f[pair.lbl])
            end
        end
        return
    end

    local br, bg, bb, ba, er, eg, eb, ea = GetPfUIColors()

    -- Window backdrop: use pfUI backdrop and hide stock tooltip frame
    if not f._pfuiWindowSkinned then
        pfUI.api.CreateBackdrop(f, nil, nil, ba)
        f._pfuiWindowSkinned = true
    end
    f:SetBackdrop(nil)

    if f.backdrop then
        f.backdrop:Show()
        local pct = (OM.GetSetting and tonumber(OM:GetSetting("frameOpacity"))) or 100
        if pct < 0 then pct = 0 end
        if pct > 100 then pct = 100 end
        local a = (ba or 0.75) * (pct / 100)
        local borderA = ea or 1
        if pct <= 0 then
            borderA = 0
        elseif pct < 30 then
            borderA = borderA * (pct / 30)
        end
        f.backdrop:SetBackdropColor(br, bg, bb, a)
        f.backdrop:SetBackdropBorderColor(er, eg, eb, borderA)
    end

    -- Header buttons
    local colorWithMode = OM.GetSetting and OM:GetSetting("buttonsColorWithMode") == true
    local modeCol = colorWithMode and UI.GetModeColor and UI.GetModeColor(f.mode or "damage")
    local i
    for i = 1, table.getn(HEADER_BUTTON_FIELDS) do
        local pair = HEADER_BUTTON_FIELDS[i]
        SkinHeaderButton(f[pair.btn], f[pair.lbl], modeCol, colorWithMode)
    end
end

function Skin:ApplyAll()
    if not UI.frames then return end
    local i
    for i = 1, table.getn(UI.frames) do
        local f = UI.frames[i]
        if f then
            self:ApplyToFrame(f)
        end
    end
end

function Skin:InstallHooks()
    if self._hooksInstalled then return end
    self._hooksInstalled = true

    if type(UI.CreateMeterFrame) == "function" then
        local orig = UI.CreateMeterFrame
        UI.CreateMeterFrame = function(selfArg, isPrimary)
            local f = orig(selfArg, isPrimary)
            Skin:ApplyToFrame(f)
            return f
        end
    end

    if type(UI.ApplyFrameBackgroundOpacity) == "function" then
        local orig = UI.ApplyFrameBackgroundOpacity
        UI.ApplyFrameBackgroundOpacity = function(f)
            orig(f)
            if Skin:IsEnabled() then
                Skin:ApplyToFrame(f)
            end
        end
    end

    if type(UI.ApplyHeaderLayout) == "function" then
        local orig = UI.ApplyHeaderLayout
        UI.ApplyHeaderLayout = function(selfArg, f, hideTitle, duration)
            orig(selfArg, f, hideTitle, duration)
            if Skin:IsEnabled() then
                Skin:ApplyToFrame(f)
            end
        end
    end

    if type(UI.ApplySettingsToFrames) == "function" then
        local orig = UI.ApplySettingsToFrames
        UI.ApplySettingsToFrames = function(selfArg)
            orig(selfArg)
            Skin:ApplyAll()
        end
    end

    if type(UI.RefreshFrame) == "function" then
        local orig = UI.RefreshFrame
        UI.RefreshFrame = function(selfArg, f)
            orig(selfArg, f)
            if Skin:IsEnabled() then
                Skin:ApplyToFrame(f)
            end
        end
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    Skin:InstallHooks()
    if Skin:IsEnabled() then
        Skin:ApplyAll()
    end
    this:UnregisterAllEvents()
end)
