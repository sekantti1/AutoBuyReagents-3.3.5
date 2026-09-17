local ADDON_NAME = "AutoBuyReagents"

-- The predefined items to track and auto-buy, organized by class
local itemsList = {
    -- Mage
    "Arcane Powder",
    "Rune of Portals",
    "Rune of Teleportation",
    
    -- Paladin
    "Symbol of Kings",
    "Symbol of Divinity",
    
    -- Priest
    "Devout Candle",
    
    -- Druid
    "Wild Spineleaf",
    "Starleaf Seed",
    
    -- Shaman
    "Ankh",
    
    -- Warlock
    "Infernal Stone",
    
    -- Hunter
    "Terrorshaft Arrow",
    "Frostbite Bullets",
    
    -- Death Knight
    "Corpse Dust",
    
    -- Rogue
    "Deadly Poison IX",
    "Instant Poison IX",
    "Wound Poison VII",
    "Crippling Poison",
    "Mind-numbing Poison",
    "Anesthetic Poison II",
    
    -- Food & Drink
    "Honeymint Tea",
    "Mead Basted Caribou",
    "Salted Venison"
}

-- Map items to their respective WoW class hex colors
local itemColors = {
    -- Mage (Light Blue)
    ["Arcane Powder"]        = "69CCF0",
    ["Rune of Portals"]      = "69CCF0",
    ["Rune of Teleportation"]= "69CCF0",
    
    -- Paladin (Pink)
    ["Symbol of Kings"]      = "F58CBA",
    ["Symbol of Divinity"]   = "F58CBA",
    
    -- Priest (White)
    ["Devout Candle"]        = "FFFFFF",
    
    -- Druid (Orange)
    ["Wild Spineleaf"]       = "FF7D0A",
    ["Starleaf Seed"]        = "FF7D0A",
    
    -- Shaman (Blue)
    ["Ankh"]                 = "0070DE",
    
    -- Warlock (Purple)
    ["Infernal Stone"]       = "9482C9",
    
    -- Hunter (Green)
    ["Terrorshaft Arrow"]    = "ABD473",
    ["Frostbite Bullets"]    = "ABD473",
    
    -- Death Knight (Red)
    ["Corpse Dust"]          = "C41F3B",
    
    -- Rogue (Yellow)
    ["Deadly Poison IX"]     = "FFF569",
    ["Instant Poison IX"]    = "FFF569",
    ["Wound Poison VII"]     = "FFF569",
    ["Crippling Poison"]     = "FFF569",
    ["Mind-numbing Poison"]  = "FFF569",
    ["Anesthetic Poison II"] = "FFF569",
    
    -- Food & Drink (White)
    ["Honeymint Tea"]        = "FFFFFF",
    ["Mead Basted Caribou"]  = "FFFFFF",
    ["Salted Venison"]       = "FFFFFF"
}

-- Accurate 3.3.5a max stack sizes
local itemStacks = {
    ["Arcane Powder"]        = 100,
    ["Rune of Portals"]      = 20,
    ["Rune of Teleportation"]= 20,
    ["Symbol of Kings"]      = 100,
    ["Symbol of Divinity"]   = 5,
    ["Devout Candle"]        = 20,
    ["Wild Spineleaf"]       = 20,
    ["Starleaf Seed"]        = 20,
    ["Ankh"]                 = 10,
    ["Infernal Stone"]       = 5,
    ["Terrorshaft Arrow"]    = 1000,
    ["Frostbite Bullets"]    = 1000,
    ["Corpse Dust"]          = 20,
    ["Deadly Poison IX"]     = 20,
    ["Instant Poison IX"]    = 20,
    ["Wound Poison VII"]     = 20,
    ["Crippling Poison"]     = 20,
    ["Mind-numbing Poison"]  = 20,
    ["Anesthetic Poison II"] = 20,
    ["Honeymint Tea"]        = 20,
    ["Mead Basted Caribou"]  = 20,
    ["Salted Venison"]       = 20
}

AutoBuyReagentsDB = AutoBuyReagentsDB or {}

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("MERCHANT_SHOW")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        -- Initialize DB for any missing items with a default of 0
        for _, itemName in ipairs(itemsList) do
            if AutoBuyReagentsDB[itemName] == nil then
                AutoBuyReagentsDB[itemName] = 0
            end
        end
        self:SetupOptions()
    elseif event == "MERCHANT_SHOW" then
        -- Only attempt to buy items when level 80
        if UnitLevel("player") == 80 then
            self:DoBuy()
        end
    end
end)

function f:DoBuy()
    local numMerchantItems = GetMerchantNumItems()
    
    for i = 1, numMerchantItems do
        -- `quantity` is the batch size the item is sold in (e.g., 20 for Symbol of Kings, 200 for Arrows, 5 for Water)
        local name, _, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(i)
        
        if name and AutoBuyReagentsDB[name] and AutoBuyReagentsDB[name] > 0 then
            local targetCount = AutoBuyReagentsDB[name]
            local currentCount = GetItemCount(name)
            
            if currentCount < targetCount then
                local neededItems = targetCount - currentCount
                local batchSize = quantity or 1
                
                -- Round down needed items so we never go over the target count
                local remainder = neededItems % batchSize
                neededItems = neededItems - remainder
                
                if neededItems > 0 then
                    -- The WoW API expects the number of BATCHES, not the number of items
                    local batchesNeeded = neededItems / batchSize
                    
                    -- Get the max amount of items we can buy in one transaction
                    local maxItemsPerTx = GetMerchantItemMaxStack(i)
                    if not maxItemsPerTx or maxItemsPerTx <= 0 then
                        maxItemsPerTx = batchSize
                    end
                    
                    -- Convert the max items per transaction into max batches per transaction
                    local maxBatchesPerTx = math.floor(maxItemsPerTx / batchSize)
                    if maxBatchesPerTx < 1 then 
                        maxBatchesPerTx = 1 
                    end
                    
                    local batchesBought = 0
                    while batchesBought < batchesNeeded do
                        local batchesToBuy = math.min(maxBatchesPerTx, batchesNeeded - batchesBought)
                        
                        -- BuyMerchantItem expects the number of batches/clicks, not the raw item count!
                        BuyMerchantItem(i, batchesToBuy)
                        batchesBought = batchesBought + batchesToBuy
                    end
                    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00["..ADDON_NAME.."]|r Restocked " .. neededItems .. "x " .. name)
                end
            end
        end
    end
end

function f:SetupOptions()
    -- Create the Options Panel
    local panel = CreateFrame("Frame", "AutoBuyReagentsOptionsPanel", UIParent)
    panel.name = ADDON_NAME
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("AutoBuyReagents Settings")
    
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Set the target amount to keep in your bags (0 to disable).\nThe addon will automatically restock up to this number.")

    -- Setup a ScrollFrame since we have a fairly large list of items
    local scrollFrame = CreateFrame("ScrollFrame", "AutoBuyReagentsScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", -32, 16)

    local content = CreateFrame("Frame", "AutoBuyReagentsContent", scrollFrame)
    content:SetSize(300, #itemsList * 40 + 20)
    scrollFrame:SetScrollChild(content)

    local yOffset = -10
    for _, itemName in ipairs(itemsList) do
        -- Item name label
        local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", 10, yOffset - 5)
        
        -- Retrieve the class color and hardcoded stack size
        local colorCode = itemColors[itemName] or "FFD100"
        local displayStack = itemStacks[itemName] or 20
        
        label:SetText("|cff" .. colorCode .. itemName .. " (" .. displayStack .. ")|r")

        -- Generate a unique safe name for each editbox (removes spaces and hyphens)
        local safeName = string.gsub(itemName, "[%s%-]", "")
        local boxName = "AutoBuyReagentsEditBox_" .. safeName
        
        -- Editbox to handle custom inputs
        local editBox = CreateFrame("EditBox", boxName, content, "InputBoxTemplate")
        editBox:SetSize(60, 20)
        editBox:SetPoint("TOPLEFT", 250, yOffset)
        editBox:SetAutoFocus(false)
        editBox:SetNumeric(true)
        editBox:SetJustifyH("CENTER")
        editBox:SetText(tostring(AutoBuyReagentsDB[itemName] or 0))
        editBox:SetCursorPosition(0) 
        
        -- Save number to our database table smoothly as you type
        editBox:SetScript("OnTextChanged", function(self)
            local val = tonumber(self:GetText()) or 0
            AutoBuyReagentsDB[itemName] = val
        end)
        
        -- Allow clearing focus with Enter or Escape
        editBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)
        editBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)

        yOffset = yOffset - 35
    end

    -- Add the panel to the game's interface options
    InterfaceOptions_AddCategory(panel)
    
    -- Create a quick slash command to access the menu
    SLASH_AUTOBUYREAGENTS1 = "/autobuyreagents"
    SlashCmdList["AUTOBUYREAGENTS"] = function()
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel) -- Called twice due to a known WotLK menu bug
    end
end