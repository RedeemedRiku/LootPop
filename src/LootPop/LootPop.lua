local f = CreateFrame("Frame")
local lootFrames = {}
local lootData = {} 
local settings = {
    posX = 842,
    posY = -300,
    spacing = 0,
    scale = 0.8,
    frameWidth = 250,
    iconSize = 16,
    growUpward = true,
    maxEntries = 10,
    dynamicWidth = true,
    frameStrata = "DIALOG",
}

LootPopDB = LootPopDB or {
    anchorX = 842,
    anchorY = -300,
    scale = 0.8,
    spacing = 0,
    maxEntries = 10,
    dynamicWidth = true,
    frameStrata = "DIALOG",
}

-- Declare variables that will be defined later
local anchor, configFrame, xCoordEditBox, yCoordEditBox

-- Timer system
local timerFrame = CreateFrame("Frame")
local activeTimers = {}
local function CreateTimer(delay, callback, lootKey)
    table.insert(activeTimers, { timeLeft = delay, callback = callback, lootKey = lootKey })
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

-- Helper function to round coordinates to nearest hundredth
local function RoundCoordinate(value)
    return math.floor(value * 100 + 0.5) / 100
end

-- Anchor functions
local function SaveAllSettings()
    local left, top = anchor:GetLeft(), anchor:GetTop()
    if left and top then
        LootPopDB.anchorX = RoundCoordinate(left)
        LootPopDB.anchorY = RoundCoordinate(top - UIParent:GetHeight())
    end
    LootPopDB.scale = settings.scale
    LootPopDB.spacing = settings.spacing
    LootPopDB.maxEntries = settings.maxEntries
    LootPopDB.dynamicWidth = settings.dynamicWidth
    LootPopDB.frameStrata = settings.frameStrata
end

local function LoadAllSettings()
    anchor:ClearAllPoints()
    local x = type(LootPopDB.anchorX) == "number" and LootPopDB.anchorX or 842
    local y = type(LootPopDB.anchorY) == "number" and LootPopDB.anchorY or -300
    anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
    
    settings.scale = type(LootPopDB.scale) == "number" and LootPopDB.scale or 0.8
    settings.spacing = type(LootPopDB.spacing) == "number" and LootPopDB.spacing or 0
    settings.maxEntries = type(LootPopDB.maxEntries) == "number" and LootPopDB.maxEntries or 10
    settings.dynamicWidth = type(LootPopDB.dynamicWidth) == "boolean" and LootPopDB.dynamicWidth or true
    settings.frameStrata = type(LootPopDB.frameStrata) == "string" and LootPopDB.frameStrata or "DIALOG"
end

local function UpdateCoordinateDisplay()
    if configFrame and configFrame:IsShown() and xCoordEditBox and yCoordEditBox then
        local left, top = anchor:GetLeft(), anchor:GetTop()
        if left and top then
            local currentX = RoundCoordinate(left)
            local currentY = RoundCoordinate(top - UIParent:GetHeight())
            
            -- Only update if the edit box doesn't have focus (so typing isn't interrupted)
            if not xCoordEditBox:HasFocus() then
                xCoordEditBox:SetText(string.format("%.2f", currentX))
            end
            if not yCoordEditBox:HasFocus() then
                yCoordEditBox:SetText(string.format("%.2f", currentY))
            end
        end
    end
end

-- Frame to update coordinate display in real-time
local coordUpdateFrame = CreateFrame("Frame")
coordUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    UpdateCoordinateDisplay()
end)

-- Create anchor
anchor = CreateFrame("Frame", nil, UIParent)
anchor:SetSize(200, 30)
anchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", LootPopDB.anchorX or 842, LootPopDB.anchorY or -300)
anchor:SetMovable(true)
anchor:EnableMouse(false)
anchor:RegisterForDrag("LeftButton")
anchor:SetScript("OnDragStart", function(self) self:StartMoving() end)
anchor:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveAllSettings()
    UpdateCoordinateDisplay()
end)

local anchorBg = anchor:CreateTexture(nil, "BACKGROUND")
anchorBg:SetAllPoints()
anchorBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
anchorBg:SetVertexColor(0, 1, 0, 0.8)

local anchorBorder = CreateFrame("Frame", nil, anchor)
anchorBorder:SetAllPoints()
anchorBorder:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
anchorBorder:SetBackdropBorderColor(0, 1, 0, 1)

local anchorText = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
anchorText:SetPoint("CENTER")
anchorText:SetText("LOOT ANCHOR - DRAG TO MOVE")
anchorText:SetTextColor(1, 1, 1, 1)

local cornerIndicator = anchor:CreateTexture(nil, "OVERLAY")
cornerIndicator:SetSize(8, 8)
cornerIndicator:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 2, 2)
cornerIndicator:SetTexture("Interface\\Buttons\\WHITE8X8")
cornerIndicator:SetVertexColor(1, 0, 0, 1)
anchor:Hide()

-- Event handler
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

-- Config frame
configFrame = CreateFrame("Frame", "LootPopConfig", UIParent)
configFrame:SetSize(350, 380)
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

-- Helper function for sliders
local function CreateSlider(parent, name, width, height, x, y, minVal, maxVal, currentVal, step, labelText)
    local slider = CreateFrame("Slider", name, parent)
    slider:SetSize(width, height)
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValue(currentVal)
    slider:SetValueStep(step)
    slider:EnableMouseWheel(true)
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    })
    
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumb:SetSize(32, 32)
    slider:SetThumbTexture(thumb)
    
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("BOTTOM", slider, "TOP", 0, 5)
    text:SetText(labelText .. ": " .. (step < 1 and string.format("%.1f", currentVal) or currentVal))
    
    local lowText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lowText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -5)
    lowText:SetText(tostring(minVal))
    
    local highText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    highText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -5)
    highText:SetText(tostring(maxVal))
    
    return slider, text
end

-- Scale slider
local scaleSlider, scaleText = CreateSlider(configFrame, "LootPopScaleSlider", 200, 20, 20, -50, 0.5, 2.0, settings.scale, 0.1, "Scale")
scaleSlider:SetScript("OnValueChanged", function(self, value)
    settings.scale = value
    scaleText:SetText("Scale: " .. string.format("%.1f", value))
    SaveAllSettings()
end)

-- Spacing slider
local spacingSlider, spacingText = CreateSlider(configFrame, "LootPopSpacingSlider", 200, 20, 20, -100, 0, 20, settings.spacing, 1, "Spacing")
spacingSlider:SetScript("OnValueChanged", function(self, value)
    settings.spacing = value
    spacingText:SetText("Spacing: " .. value)
    SaveAllSettings()
end)

-- Max entries
local maxEntriesLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
maxEntriesLabel:SetPoint("TOPLEFT", 20, -140)
maxEntriesLabel:SetText("Max Entries:")

local maxEntriesEditBox = CreateFrame("EditBox", "LootPopMaxEntriesEditBox", configFrame, "InputBoxTemplate")
maxEntriesEditBox:SetSize(60, 20)
maxEntriesEditBox:SetPoint("LEFT", maxEntriesLabel, "RIGHT", 10, 0)
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

-- Dynamic width checkbox
local dynamicWidthCheckbox = CreateFrame("CheckButton", "LootPopDynamicWidthCheckbox", configFrame, "UICheckButtonTemplate")
dynamicWidthCheckbox:SetPoint("TOPLEFT", 20, -170)
dynamicWidthCheckbox:SetChecked(settings.dynamicWidth)
getglobal(dynamicWidthCheckbox:GetName() .. "Text"):SetText("Dynamic Width")
dynamicWidthCheckbox:SetScript("OnClick", function(self)
    settings.dynamicWidth = self:GetChecked()
    SaveAllSettings()
end)

-- Frame strata dropdown
local frameStrataLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frameStrataLabel:SetPoint("TOPLEFT", 20, -200)
frameStrataLabel:SetText("Frame Strata:")

local frameStrataDropdown = CreateFrame("Frame", "LootPopFrameStrataDropdown", configFrame, "UIDropDownMenuTemplate")
frameStrataDropdown:SetPoint("LEFT", frameStrataLabel, "RIGHT", 10, -2)
local strataOptions = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP"}

local function InitializeStrataDropdown()
    local info = {}
    for i, strata in ipairs(strataOptions) do
        info.text = strata
        info.value = strata
        info.func = function()
            settings.frameStrata = strata
            UIDropDownMenu_SetText(frameStrataDropdown, strata)
            SaveAllSettings()
        end
        info.checked = (settings.frameStrata == strata)
        UIDropDownMenu_AddButton(info)
    end
end
UIDropDownMenu_Initialize(frameStrataDropdown, InitializeStrataDropdown)
UIDropDownMenu_SetWidth(frameStrataDropdown, 120)
UIDropDownMenu_SetText(frameStrataDropdown, settings.frameStrata)

-- X/Y Coordinate inputs
local xCoordLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
xCoordLabel:SetPoint("TOPLEFT", 20, -240)
xCoordLabel:SetText("Anchor X:")

xCoordEditBox = CreateFrame("EditBox", "LootPopXCoordEditBox", configFrame, "InputBoxTemplate")
xCoordEditBox:SetSize(80, 20)
xCoordEditBox:SetPoint("LEFT", xCoordLabel, "RIGHT", 10, 0)
xCoordEditBox:SetAutoFocus(false)
xCoordEditBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        LootPopDB.anchorX = value
        LoadAllSettings()
    else
        self:SetText(string.format("%.2f", LootPopDB.anchorX or 842))
    end
    self:ClearFocus()
end)

local yCoordLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
yCoordLabel:SetPoint("LEFT", xCoordEditBox, "RIGHT", 20, 0)
yCoordLabel:SetText("Anchor Y:")

yCoordEditBox = CreateFrame("EditBox", "LootPopYCoordEditBox", configFrame, "InputBoxTemplate")
yCoordEditBox:SetSize(80, 20)
yCoordEditBox:SetPoint("LEFT", yCoordLabel, "RIGHT", 10, 0)
yCoordEditBox:SetAutoFocus(false)
yCoordEditBox:SetScript("OnEnterPressed", function(self)
    local value = tonumber(self:GetText())
    if value then
        LootPopDB.anchorY = value
        LoadAllSettings()
    else
        self:SetText(string.format("%.2f", LootPopDB.anchorY or -300))
    end
    self:ClearFocus()
end)

-- Buttons
local resetPosBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
resetPosBtn:SetSize(100, 22)
resetPosBtn:SetPoint("TOPLEFT", 20, -270)
resetPosBtn:SetText("Reset Position")
resetPosBtn:SetScript("OnClick", function()
    LootPopDB.anchorX = 842
    LootPopDB.anchorY = -300
    LoadAllSettings()
    xCoordEditBox:SetText("842.00")
    yCoordEditBox:SetText("-300.00")
end)

local posBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
posBtn:SetSize(120, 22)
posBtn:SetPoint("TOPLEFT", 130, -270)
posBtn:SetText("Show/Move Anchor")
posBtn:SetScript("OnClick", function()
    if anchor:IsShown() then
        anchor:Hide()
        anchor:EnableMouse(false)
    else
        anchor:Show()
        anchor:EnableMouse(true)
    end
end)

local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
closeBtn:SetSize(80, 22)
closeBtn:SetPoint("TOPRIGHT", -20, -270)
closeBtn:SetText("Close")
closeBtn:SetScript("OnClick", function()
    SaveAllSettings()
    configFrame:Hide()
    anchor:Hide()
    anchor:EnableMouse(false)
end)

local accountInfo = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
accountInfo:SetPoint("BOTTOM", 0, 15)
accountInfo:SetText("Anchor position is saved between sessions")
accountInfo:SetTextColor(0.7, 0.7, 1, 1)

configFrame:SetScript("OnShow", function()
    scaleSlider:SetValue(settings.scale)
    scaleText:SetText("Scale: " .. string.format("%.1f", settings.scale))
    spacingSlider:SetValue(settings.spacing)
    spacingText:SetText("Spacing: " .. settings.spacing)
    maxEntriesEditBox:SetText(tostring(settings.maxEntries))
    dynamicWidthCheckbox:SetChecked(settings.dynamicWidth)
    UIDropDownMenu_SetText(frameStrataDropdown, settings.frameStrata)
    UpdateCoordinateDisplay()  -- This will set the current coordinates when opening the config
end)

-- Slash commands
SLASH_LOOTPOP1 = "/lootpop"
SlashCmdList["LOOTPOP"] = function(msg)
    if msg == "config" then
        configFrame:Show()
    end
end

-- Helper functions
local itemColors = {
    [0] = {0.62, 0.62, 0.62}, [1] = {1, 1, 1}, [2] = {0.12, 1, 0},
    [3] = {0, 0.44, 0.87}, [4] = {0.64, 0.21, 0.93}, [5] = {1, 0.5, 0}, [6] = {0.9, 0.8, 0.5}
}
local function GetItemColor(quality)
    return unpack(itemColors[quality] or {1, 1, 1})
end

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
                text = text:lower()
                if text:find("titanforged") then return "titanforged"
                elseif text:find("warforged") then return "warforged"
                elseif text:find("lightforged") then return "lightforged" end
            end
        end
    end
    return nil
end

local function GetTextWidth(text, fontString)
    fontString:SetText(text)
    return fontString:GetStringWidth()
end

local function GetLootKey(itemLink, isMoney, moneyAmount)
    if isMoney then return "money_" .. (moneyAmount or 0) end
    return itemLink:match("^(.-)x%d+$") or itemLink
end

local function RepositionFrames()
    for i, frameData in ipairs(lootFrames) do
        local frame = frameData.frame
        local targetY = (i - 1) * (frame:GetHeight() + settings.spacing)
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, targetY)
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
        
        -- Clear existing timer
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
        
        if settings.dynamicWidth then
            local textWidth = GetTextWidth(displayText, existingData.textObj)
            existingData.frame:SetWidth(textWidth + settings.iconSize + 17)
        end
        
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
    
    local tempText = lootFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tempText:SetJustifyH("LEFT")
    
    local baseLink = itemLink:match("^(.-)x%d*$") or itemLink
    local displayText = quantity > 1 and (baseLink .. "|cFFFFFFFF x" .. quantity .. "|r") or baseLink
    
    local textColor = {1, 1, 1}
    local itemID = itemLink:match("item:(%d+)")
    if itemID then
        local _, _, quality = GetItemInfo(itemID)
        if quality then textColor = {GetItemColor(quality)} end
    end
    
    local forgeType = GetForgeType(itemLink)
    local frameWidth = settings.frameWidth
    
    if settings.dynamicWidth then
        local textWidth = GetTextWidth(displayText, tempText)
        frameWidth = math.max(100, textWidth + settings.iconSize + 1)
    end
    
    local frameHeight = math.max(settings.iconSize + 16, 32)
    lootFrame:SetSize(frameWidth, frameHeight)
    lootFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Set forge-specific colors
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
    icon:SetSize(settings.iconSize, settings.iconSize)
    icon:SetPoint("LEFT", 7.5, 0)
    icon:SetTexture(texture)
    
    local text = lootFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    text:SetPoint("LEFT", icon, "RIGHT", 4, 1)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("MIDDLE")
    text:SetText(displayText)
    text:SetTextColor(unpack(textColor))
    
    if settings.dynamicWidth then
        text:SetWidth(1000)
        local fullTextWidth = text:GetStringWidth()
        lootFrame:SetWidth(fullTextWidth + settings.iconSize + 17)
    end
    
    tempText:Hide()
    
    local frameData = { frame = lootFrame, key = lootKey }
    local timerId = math.random(1000000)
    
    lootData[lootKey] = {
        frame = lootFrame,
        textObj = text,
        iconObj = icon,
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

-- Event registration
f:RegisterEvent("CHAT_MSG_LOOT")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "CHAT_MSG_LOOT" then
        -- Filter out messages where items are not actually received
        if arg1:find("You sell:") or arg1:find("You disenchant:") or arg1:find("You destroy:") then 
            return 
        end
        
        local itemLink = arg1:match("|c%x+|Hitem.-|h%[.-%]|h|r")
        if itemLink then
            local quantity = tonumber(arg1:match("x(%d+)")) or 1
            local itemID = itemLink:match("item:(%d+)")
            if itemID then
                local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
                if texture then CreateLootFrame(itemLink, texture, quantity) end
            end
        else
            local copper = arg1:match("(%d+) Copper")
            local silver = arg1:match("(%d+) Silver")
            local gold = arg1:match("(%d+) Gold")
            if copper or silver or gold then
                local totalCopper = (tonumber(gold) or 0) * 10000 + (tonumber(silver) or 0) * 100 + (tonumber(copper) or 0)
                if totalCopper > 0 then
                    CreateLootFrame("Money", "Interface\\Icons\\INV_Misc_Coin_01", totalCopper)
                end
            end
        end
    end
end)