local ADDON_NAME, ns = ...
_G.TSM_BRIDGE_VERSION = "0.0.1"

-- Backfill empty items using TSM's existing price database
local function BackfillItemHistory(itemString)
    if not AuctionPriceGraphDB or not TSM_API or not TSM_API.GetCustomPriceValue then return end

    local itemName = TSM_API.GetItemName and TSM_API.GetItemName(itemString) or GetItemInfo(itemString)
    if not itemName then return end

    local realmKey = GetRealmName()
    local faction = UnitFactionGroup("player")
    local dbKey = realmKey .. " - " .. faction
    AuctionPriceGraphDB[dbKey] = AuctionPriceGraphDB[dbKey] or {}

    local itemKey = itemName:lower()
    AuctionPriceGraphDB[dbKey][itemKey] = AuctionPriceGraphDB[dbKey][itemKey] or {}
    local history = AuctionPriceGraphDB[dbKey][itemKey]

    if #history < 2 then
        local currentMin = TSM_API.GetCustomPriceValue("minbuyout", itemString)
        local marketVal  = TSM_API.GetCustomPriceValue("dbmarket", itemString)
        local histVal    = TSM_API.GetCustomPriceValue("dbhistorical", itemString)

        local now = time()

        if histVal and histVal > 0 then
            table.insert(history, { t = now - 172800, p = histVal })
        end
        if marketVal and marketVal > 0 then
            table.insert(history, { t = now - 86400, p = marketVal })
        end
        local latestPrice = currentMin or marketVal or histVal
        if latestPrice and latestPrice > 0 then
            table.insert(history, { t = now, p = latestPrice })
        end
    end
end

-- Sync TSM Groups directly into Auctionator's real Shopping Lists & Backfill
local function SyncTSMGroupsToAuctionator()
    if not (TSM_API and TSM_API.GetGroupPaths and TSM_API.GetGroupItems) then return end

    local groupPaths = {}
    TSM_API.GetGroupPaths(groupPaths)

    for _, path in ipairs(groupPaths) do
        local groupItems = {}
        -- Argument 1: groupPath (string)
        -- Argument 2: includeSubGroups (boolean)
        -- Argument 3: result (table)
        TSM_API.GetGroupItems(path, true, groupItems)

        local items = {}
        for _, itemString in ipairs(groupItems) do
            local itemName = (TSM_API.GetItemName and TSM_API.GetItemName(itemString)) or GetItemInfo(itemString)
            if itemName then
                table.insert(items, '"' .. itemName .. '"')
            end
            BackfillItemHistory(itemString)
        end

        if #items > 0 then
            local displayPath = TSM_API.FormatGroupPath and TSM_API.FormatGroupPath(path) or path
            local listName = "TSM: " .. displayPath

            -- Method A: Modern Auctionator ListManager API
            if Auctionator and Auctionator.Shopping and Auctionator.Shopping.ListManager then
                local lm = Auctionator.Shopping.ListManager
                if lm.GetIndexForName and lm:GetIndexForName(listName) == nil and lm.Create then
                    lm:Create(listName)
                end
                if lm.GetByName then
                    local listObj = lm:GetByName(listName)
                    if listObj and listObj.SetItems then
                        listObj:SetItems(items)
                    elseif listObj and listObj.items then
                        listObj.items = items
                    end
                end
            end

            -- Method B: Legacy / SavedVariables table (AUCTIONATOR_SHOPPING_LISTS)
            if type(AUCTIONATOR_SHOPPING_LISTS) == "table" then
                local found = false
                for _, list in ipairs(AUCTIONATOR_SHOPPING_LISTS) do
                    if list.name == listName then
                        list.items = items
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(AUCTIONATOR_SHOPPING_LISTS, {
                        name = listName,
                        items = items,
                        isRecents = false
                    })
                end
            end
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    print("|cFF00FF00[TSM PriceGraph Bridge] v3.1 Loaded - Syncing TSM Groups.|r")

    C_Timer.After(2, function()
        SyncTSMGroupsToAuctionator()
        if AuctionPriceGraph and AuctionPriceGraph.RefreshGraph then
            AuctionPriceGraph:RefreshGraph()
        end
    end)
end)