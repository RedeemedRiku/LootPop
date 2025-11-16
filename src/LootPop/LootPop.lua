local f = CreateFrame("Frame")
local lootFrames = {}
local lootData = {}
local lastDisenchantItem = nil
local settings = {
    spacing = 0,
    scale = 1.0,
    maxEntries = 10,
    frameStrata = "DIALOG",
    growUp = true,
}

LootPopDB = LootPopDB or {
    anchorX = 842,
    anchorY = -300,
    scale = 1.0,
    spacing = 0,
    maxEntries = 10,
    frameStrata = "DIALOG",
    growUp = true,
}

local anchor, anchor2, configFrame
local timerFrame = CreateFrame("Frame")
local activeTimers = {}

local function CreateTimer(delay, callback)
    table.insert(activeTimers, { timeLeft = delay, callback = callback })
end

timerFrame:SetScript("OnUpdate", function(self, elapsed)
    for i = #activeTimers, 1, -1 do
        local timer = activeTimers[i]
        timer.timeLeft = timer.timeLeft - elapsed
        if timer.timeLeft <= 0 then
            timer.callback()
            table.remove(activeTimers, i)
        end
    end
end)

local function SaveAllSettings()
    local left, top = anchor:GetLeft(), anchor:GetTop()
    if left and top then
        LootPopDB.anchorX = math.floor(left * 100 + 0.5) / 100
        LootPopDB.anchorY = math.floor((top - UIParent:GetHeight()) * 100 + 0.5) / 100
    end
    LootPopDB.scale = settings.scale
    LootPopDB.spacing = settings.spacing
    LootPopDB.maxEntries = settings.maxEntries
    LootPopDB.frameStrata = settings.frameStrata
    LootPopDB.growUp = settings.growUp
end

local function LoadAllSettings()
    anchor:ClearAllPoints()
    local x = type(LootPopDB.anchorX) == "number" and LootPopDB.anchorX or 842
    local y = type(LootPopDB.anchorY) == "number" and LootPopDB.anchorY or -300
    anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
    anchor:SetScale(LootPopDB.scale or 1.0)
    
    settings.scale = type(LootPopDB.scale) == "number" and LootPopDB.scale or 1.0
    settings.spacing = type(LootPopDB.spacing) == "number" and LootPopDB.spacing or 0
    settings.maxEntries = type(LootPopDB.maxEntries) == "number" and LootPopDB.maxEntries or 10
    settings.frameStrata = type(LootPopDB.frameStrata) == "string" and LootPopDB.frameStrata or "DIALOG"
    settings.growUp = LootPopDB.growUp ~= false
    
    if anchor2 then
        anchor2:ClearAllPoints()
        if settings.growUp then
            anchor2:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, 32 + settings.spacing)
        else
            anchor2:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -(32 + settings.spacing))
        end
    end
end

anchor = CreateFrame("Frame", nil, UIParent)
anchor:SetSize(250, 32)
anchor:SetScale(settings.scale)
anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", LootPopDB.anchorX or 842, LootPopDB.anchorY or -300)
anchor:SetMovable(true)
anchor:EnableMouse(false)
anchor:RegisterForDrag("LeftButton")
anchor:SetScript("OnDragStart", function(self) self:StartMoving() end)
anchor:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveAllSettings()
end)

anchor:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
anchor:SetBackdropColor(0, 0, 0, 1)
anchor:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

local anchorIcon = anchor:CreateTexture(nil, "ARTWORK")
anchorIcon:SetSize(16, 16)
anchorIcon:SetPoint("LEFT", 7.5, 0)
anchorIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

local anchorText = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
anchorText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
anchorText:SetJustifyH("LEFT")
anchorText:SetPoint("LEFT", anchorIcon, "RIGHT", 4, 1)
anchorText:SetText("Loot Anchor - Drag to Move")
anchorText:SetTextColor(1, 1, 1)

anchor2 = CreateFrame("Frame", nil, anchor)
anchor2:SetSize(250, 32)
anchor2:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, 32 + settings.spacing)
anchor2:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
anchor2:SetBackdropColor(0, 0, 0, 1)
anchor2:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

local anchor2Icon = anchor2:CreateTexture(nil, "ARTWORK")
anchor2Icon:SetSize(16, 16)
anchor2Icon:SetPoint("LEFT", 7.5, 0)
anchor2Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

local anchor2Text = anchor2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
anchor2Text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
anchor2Text:SetJustifyH("LEFT")
anchor2Text:SetPoint("LEFT", anchor2Icon, "RIGHT", 4, 1)
anchor2Text:SetText("Second Loot Item")
anchor2Text:SetTextColor(1, 1, 1)

anchor:Hide()

local addonFrame = CreateFrame("Frame")
addonFrame:RegisterEvent("ADDON_LOADED")
addonFrame:RegisterEvent("PLAYER_LOGOUT")
addonFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "LootPop" then
        LoadAllSettings()
    elseif event == "PLAYER_LOGOUT" then
        SaveAllSettings()
    end
end)

configFrame = CreateFrame("Frame", "LootPopConfig", UIParent)
configFrame:SetSize(300, 340)
configFrame:SetPoint("CENTER")
configFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
configFrame:SetMovable(true)
configFrame:EnableMouse(true)
configFrame:RegisterForDrag("LeftButton")
configFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
configFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
configFrame:Hide()
table.insert(UISpecialFrames, "LootPopConfig")
configFrame:SetScript("OnHide", function()
    SaveAllSettings()
    anchor:Hide()
    anchor:EnableMouse(false)
end)

local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", 0, -16)
title:SetText("LootPop Configuration")

local function CreateSlider(parent, name, width, x, y, minVal, maxVal, currentVal, step, labelText)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetSize(width, 17)
    slider:SetPoint("TOP", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValue(currentVal)
    slider:SetValueStep(step)
    
    getglobal(name.."Low"):SetText(tostring(minVal))
    getglobal(name.."High"):SetText(tostring(maxVal))
    getglobal(name.."Text"):SetText(labelText .. ": " .. (step < 1 and string.format("%.1f", currentVal) or currentVal))
    
    return slider
end

local scaleSlider = CreateSlider(configFrame, "LootPopScaleSlider", 200, 0, -50, 0.5, 2.0, settings.scale, 0.1, "Scale")
scaleSlider:SetScript("OnValueChanged", function(self, value)
    settings.scale = value
    getglobal(self:GetName().."Text"):SetText("Scale: " .. string.format("%.1f", value))
    if anchor:IsShown() then
        anchor:SetScale(value)
    end
    SaveAllSettings()
end)

local spacingSlider = CreateSlider(configFrame, "LootPopSpacingSlider", 200, 0, -80, 0, 20, settings.spacing, 1, "Spacing")
spacingSlider:SetScript("OnValueChanged", function(self, value)
    settings.spacing = value
    getglobal(self:GetName().."Text"):SetText("Spacing: " .. value)
    if anchor:IsShown() and anchor2 then
        anchor2:ClearAllPoints()
        if settings.growUp then
            anchor2:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, 32 + value)
        else
            anchor2:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -(32 + value))
        end
    end
    SaveAllSettings()
end)

local maxEntriesLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
maxEntriesLabel:SetPoint("TOP", 0, -105)
maxEntriesLabel:SetText("Max Entries:")

local maxEntriesEditBox = CreateFrame("EditBox", nil, configFrame, "InputBoxTemplate")
maxEntriesEditBox:SetSize(60, 20)
maxEntriesEditBox:SetPoint("TOP", 0, -125)
maxEntriesEditBox:SetText(tostring(settings.maxEntries))
maxEntriesEditBox:SetAutoFocus(false)
maxEntriesEditBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value and value > 0 and value <= 50 then
        settings.maxEntries = math.floor(value)
        self:SetText(tostring(settings.maxEntries))
        SaveAllSettings()
    else
        self:SetText(tostring(settings.maxEntries))
    end
    self:ClearFocus()
end)

local frameStrataLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frameStrataLabel:SetPoint("TOP", 0, -150)
frameStrataLabel:SetText("Frame Strata:")

local frameStrataDropdown = CreateFrame("Frame", "LootPopFrameStrataDropdown", configFrame, "UIDropDownMenuTemplate")
frameStrataDropdown:SetPoint("TOP", 0, -165)
local strataOptions = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP"}

UIDropDownMenu_Initialize(frameStrataDropdown, function()
    local info = {}
    for _, strata in ipairs(strataOptions) do
        info.text = strata
        info.value = strata
        info.func = function()
            settings.frameStrata = strata
            UIDropDownMenu_SetText(frameStrataDropdown, strata)
            if anchor:IsShown() then
                anchor:SetFrameStrata(strata)
            end
            SaveAllSettings()
        end
        info.checked = (settings.frameStrata == strata)
        UIDropDownMenu_AddButton(info)
    end
end)
UIDropDownMenu_SetWidth(frameStrataDropdown, 120)
UIDropDownMenu_SetText(frameStrataDropdown, settings.frameStrata)

local growthLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
growthLabel:SetPoint("TOP", 0, -195)
growthLabel:SetText("Growth Direction:")

local growthDropdown = CreateFrame("Frame", "LootPopGrowthDropdown", configFrame, "UIDropDownMenuTemplate")
growthDropdown:SetPoint("TOP", 0, -210)

UIDropDownMenu_Initialize(growthDropdown, function()
    local info = {}
    
    info.text = "Grow Up"
    info.value = true
    info.func = function()
        settings.growUp = true
        UIDropDownMenu_SetText(growthDropdown, "Grow Up")
        if anchor2 then
            anchor2:ClearAllPoints()
            if settings.growUp then
                anchor2:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, 32 + settings.spacing)
            else
                anchor2:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -(32 + settings.spacing))
            end
        end
        SaveAllSettings()
    end
    info.checked = settings.growUp
    UIDropDownMenu_AddButton(info)
    
    info.text = "Grow Down"
    info.value = false
    info.func = function()
        settings.growUp = false
        UIDropDownMenu_SetText(growthDropdown, "Grow Down")
        if anchor2 then
            anchor2:ClearAllPoints()
            if settings.growUp then
                anchor2:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, 32 + settings.spacing)
            else
                anchor2:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -(32 + settings.spacing))
            end
        end
        SaveAllSettings()
    end
    info.checked = not settings.growUp
    UIDropDownMenu_AddButton(info)
end)
UIDropDownMenu_SetWidth(growthDropdown, 120)
UIDropDownMenu_SetText(growthDropdown, settings.growUp and "Grow Up" or "Grow Down")

local centerBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
centerBtn:SetSize(160, 22)
centerBtn:SetPoint("BOTTOM", 0, 68)
centerBtn:SetText("Return to Center")
centerBtn:SetScript("OnClick", function()
    anchor:ClearAllPoints()
    anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    SaveAllSettings()
end)

local posBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
posBtn:SetSize(160, 22)
posBtn:SetPoint("BOTTOM", 0, 43)
posBtn:SetText("Show/Move Anchor")
posBtn:SetScript("OnClick", function()
    if anchor:IsShown() then
        anchor:Hide()
        anchor:EnableMouse(false)
    else
        anchor:SetScale(settings.scale)
        anchor:Show()
        anchor:EnableMouse(true)
    end
end)

local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
closeBtn:SetSize(80, 22)
closeBtn:SetPoint("BOTTOM", 0, 18)
closeBtn:SetText("Close")
closeBtn:SetScript("OnClick", function()
    configFrame:Hide()
end)

configFrame:SetScript("OnShow", function()
    scaleSlider:SetValue(settings.scale)
    spacingSlider:SetValue(settings.spacing)
    maxEntriesEditBox:SetText(tostring(settings.maxEntries))
    UIDropDownMenu_SetText(frameStrataDropdown, settings.frameStrata)
    UIDropDownMenu_SetText(growthDropdown, settings.growUp and "Grow Up" or "Grow Down")
end)

SLASH_LOOTPOP1 = "/lootpop"
SlashCmdList["LOOTPOP"] = function(msg)
    if msg == "config" then
        configFrame:Show()
    end
end

local itemColors = {
    [0] = {0.62, 0.62, 0.62}, 
    [1] = {1, 1, 1}, 
    [2] = {0.12, 1, 0},
    [3] = {0, 0.44, 0.87}, 
    [4] = {0.64, 0.21, 0.93}, 
    [5] = {1, 0.5, 0}, 
    [6] = {0.9, 0.8, 0.5}
}

local scanTooltip = CreateFrame("GameTooltip", "LootPopScanTooltip", UIParent, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local function GetForgeType(itemLink)
    scanTooltip:ClearLines()
    scanTooltip:SetHyperlink(itemLink)
    for i = 1, scanTooltip:NumLines() do
        local line = getglobal("LootPopScanTooltipTextLeft" .. i)
        if line then
            local text = line:GetText()
            if text then
                local lower = text:lower()
                if lower:find("titanforged") then return "titanforged"
                elseif lower:find("warforged") then return "warforged"
                elseif lower:find("lightforged") then return "lightforged" end
            end
        end
    end
end

local function GetLootKey(itemLink)
    return itemLink:match("^(.-)x%d+$") or itemLink
end

local function RepositionFrames()
    for i, frameData in ipairs(lootFrames) do
        local frame = frameData.frame
        if settings.growUp then
            local targetY = (i - 1) * (frame:GetHeight() + settings.spacing)
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, targetY)
        else
            local targetY = -(i - 1) * (frame:GetHeight() + settings.spacing)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, targetY)
        end
    end
end

local function CreateFadeAnimation(frame, fadeIn, callback)
    local fadeTimer = 0
    local fadeFrame = CreateFrame("Frame")
    fadeFrame:SetScript("OnUpdate", function(self, elapsed)
        fadeTimer = fadeTimer + elapsed
        local alpha = fadeIn and (fadeTimer / 0.3) or (1 - fadeTimer / 0.3)
        if (fadeIn and alpha >= 1) or (not fadeIn and alpha <= 0) then
            frame:SetAlpha(fadeIn and 1 or 0)
            fadeFrame:SetScript("OnUpdate", nil)
            if callback then callback() end
        else
            frame:SetAlpha(alpha)
        end
    end)
end

local function RemoveOldestFrame()
    if #lootFrames > settings.maxEntries then
        local oldestFrame = lootFrames[1]
        CreateFadeAnimation(oldestFrame.frame, false, function()
            oldestFrame.frame:Hide()
            oldestFrame.frame:SetParent(nil)
            table.remove(lootFrames, 1)
            for key, data in pairs(lootData) do
                if data.frame == oldestFrame.frame then
                    lootData[key] = nil
                    break
                end
            end
            RepositionFrames()
        end)
    end
end

local function CreateLootFrame(itemLink, texture, quantity)
    quantity = quantity or 1
    local lootKey = GetLootKey(itemLink)
    
    if lootData[lootKey] then
        local existingData = lootData[lootKey]
        existingData.quantity = existingData.quantity + quantity
        
        if existingData.timerId then
            for i, timer in ipairs(activeTimers) do
                if timer.id == existingData.timerId then
                    table.remove(activeTimers, i)
                    break
                end
            end
        end
        
        local baseLink = itemLink:match("^(.-)x%d*$") or itemLink
        local displayText = existingData.quantity > 1 and (baseLink .. "|cFFFFFFFF x" .. existingData.quantity .. "|r") or baseLink
        existingData.textObj:SetText(displayText)
        
        existingData.textObj:SetWidth(0)
        existingData.frame:SetWidth(math.max(50, existingData.textObj:GetStringWidth() + 33))
        
        local timerId = math.random(1000000)
        existingData.timerId = timerId
        CreateTimer(5, function()
            if existingData.timerId == timerId then
                lootData[lootKey] = nil
                for i, data in ipairs(lootFrames) do
                    if data.frame == existingData.frame then
                        table.remove(lootFrames, i)
                        break
                    end
                end
                CreateFadeAnimation(existingData.frame, false, function()
                    existingData.frame:Hide()
                    existingData.frame:SetParent(nil)
                    RepositionFrames()
                end)
            end
        end)
        return
    end
    
    RemoveOldestFrame()
    
    local lootFrame = CreateFrame("Frame", nil, UIParent)
    lootFrame:SetScale(settings.scale)
    lootFrame:SetFrameStrata(settings.frameStrata)
    
    local baseLink = itemLink:match("^(.-)x%d*$") or itemLink
    local displayText = quantity > 1 and (baseLink .. "|cFFFFFFFF x" .. quantity .. "|r") or baseLink
    
    local textColor = {1, 1, 1}
    local itemID = itemLink:match("item:(%d+)")
    if itemID then
        local _, _, quality = GetItemInfo(itemID)
        if quality and itemColors[quality] then 
            textColor = itemColors[quality]
        end
    end
    
    local forgeType = GetForgeType(itemLink)
    
    local text = lootFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    text:SetJustifyH("LEFT")
    text:SetText(displayText)
    text:SetTextColor(textColor[1], textColor[2], textColor[3])
    
    text:SetWidth(0)
    local frameWidth = math.max(50, text:GetStringWidth() + 33)
    
    lootFrame:SetSize(frameWidth, 32)
    lootFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    local forgeColors = {
        titanforged = {{0.35, 0.35, 0.7, 1}, {0.42, 0.49, 0.63, 1}},
        warforged = {{0.7, 0.36, 0.31, 1}, {0.7, 0.36, 0.31, 1}},
        lightforged = {{0.67, 0.67, 0.49, 1}, {0.67, 0.67, 0.49, 1}}
    }
    
    if forgeType and forgeColors[forgeType] then
        lootFrame:SetBackdropColor(unpack(forgeColors[forgeType][1]))
        lootFrame:SetBackdropBorderColor(unpack(forgeColors[forgeType][2]))
    else
        lootFrame:SetBackdropColor(0, 0, 0, 1)
        lootFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end
    
    local icon = lootFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", 7.5, 0)
    icon:SetTexture(texture)
    
    text:SetPoint("LEFT", icon, "RIGHT", 4, 1)
    
    local frameData = { frame = lootFrame, key = lootKey }
    local timerId = math.random(1000000)
    
    lootData[lootKey] = {
        frame = lootFrame,
        textObj = text,
        quantity = quantity,
        timerId = timerId,
    }
    
    table.insert(lootFrames, 1, frameData)
    RepositionFrames()
    CreateFadeAnimation(lootFrame, true)
    lootFrame:Show()
    
    CreateTimer(5, function()
        if lootData[lootKey] and lootData[lootKey].timerId == timerId then
            lootData[lootKey] = nil
            for i, data in ipairs(lootFrames) do
                if data.frame == lootFrame then
                    table.remove(lootFrames, i)
                    break
                end
            end
            CreateFadeAnimation(lootFrame, false, function()
                lootFrame:Hide()
                lootFrame:SetParent(nil)
                RepositionFrames()
            end)
        end
    end)
end

f:RegisterEvent("CHAT_MSG_LOOT")
f:SetScript("OnEvent", function(self, event, arg1)
    if arg1:find("You sell:") or arg1:find("You destroy:") or arg1:find("passed on:") or arg1:find("passes on:") or arg1:find("Roll -") then 
        return 
    end
    
    if arg1:find("selected Disenchant") then
        local itemLink = arg1:match("|c%x+|Hitem.-|h%[.-%]|h|r")
        if itemLink then
            lastDisenchantItem = itemLink
            CreateTimer(0.5, function()
                lastDisenchantItem = nil
            end)
        end
        return
    end
    
    if arg1:find("selected Greed") or arg1:find("selected Need") then
        return
    end
    
    if arg1:find("You won:") then
        local itemLink = arg1:match("|c%x+|Hitem.-|h%[.-%]|h|r")
        if itemLink then
            if lastDisenchantItem and itemLink == lastDisenchantItem then
                return
            end
            local itemID = itemLink:match("item:(%d+)")
            if itemID then
                local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
                if texture then CreateLootFrame(itemLink, texture, 1) end
            end
        end
        return
    end
    
    if arg1:find("You receive loot:") or arg1:find("You receive item:") or arg1:find("You create:") then
        local itemLink = arg1:match("|c%x+|Hitem.-|h%[.-%]|h|r")
        if itemLink then
            local quantity = tonumber(arg1:match("x(%d+)")) or 1
            local itemID = itemLink:match("item:(%d+)")
            if itemID then
                local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
                if texture then CreateLootFrame(itemLink, texture, quantity) end
            end
        end
        return
    end
    
    local copper = arg1:match("(%d+) Copper")
    local silver = arg1:match("(%d+) Silver")
    local gold = arg1:match("(%d+) Gold")
    if copper or silver or gold then
        local totalCopper = (tonumber(gold) or 0) * 10000 + (tonumber(silver) or 0) * 100 + (tonumber(copper) or 0)
        if totalCopper > 0 then
            CreateLootFrame("Money", "Interface\\Icons\\INV_Misc_Coin_01", totalCopper)
        end
    end
end)
