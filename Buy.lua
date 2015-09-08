local processScanResults
local processedData;

function AuctionatorBuySearchButton_OnClick()
	
	Auctionator_Scan_Start(Auctionator_Scan_CreateQuery{
		name = AuctionatorBuySearchBox:GetText(),
		exactMatch = true,
		onComplete = function(data)
			table.sort(data, function(a,b) return a.buyoutPrice < b.buyoutPrice end)
			scanData = data
		end
	})
	
end

function processScanResults(rawData, auctionItemName)

	processedData = {}
	
	----- Condense the scan rawData into a table that has only a single entry per stacksize/price combo
	
	local condData = {}

	for _,rawDatum in ipairs(rawData) do
	
		local key = "_"..rawDatum.stackSize.."_"..rawDatum.buyoutPrice
				
		if condData[key] then
			condData[key].count = condData[key].count + 1
		else			
			condData[key] = {
					stackSize 	= rawDatum.stackSize,
					buyoutPrice	= rawDatum.buyoutPrice,
					itemPrice		= rawDatum.buyoutPrice / rawDatum.stackSize,
					count			= 1,
					numYours		= rawDatum.owner == UnitName("player") and 1 or 0
			}
		end
	end

	----- create a table of these entries sorted by itemPrice
	
	local n = 1
	for _,condDatum in pairs(condData) do
		processedData[n] = condDatum
		n = n + 1
	end
	
	table.sort(processedData, function(a,b) return a.itemPrice < b.itemPrice end)
end

-----------------------------------------

-- These functions were meant to be used for a search sorted by buyout price but that actually seems impossible to implement nicely with the vanilla interface

-- function Auctionator_AuctionFrameBrowse_Update()
	-- local numBatchAuctions = getn(searchResults)
	-- local totalAuctions = numBatchAuctions
	-- local button, buttonName, iconTexture, itemName, color, itemCount, moneyFrame, buyoutMoneyFrame, buyoutText, buttonHighlight
	-- local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)
	-- local index
	-- local isLastSlotEmpty
	-- local name, texture, count, quality, canUse, minBid, minIncrement, buyoutPrice, duration, bidAmount, highBidder
	-- BrowseBidButton:Disable()
	-- BrowseBuyoutButton:Disable()
	-- -- Update sort arrows
	-- SortButton_UpdateArrow(BrowseQualitySort, "list", "quality")
	-- SortButton_UpdateArrow(BrowseLevelSort, "list", "level")
	-- SortButton_UpdateArrow(BrowseDurationSort, "list", "duration")
	-- SortButton_UpdateArrow(BrowseHighBidderSort, "list", "status")
	-- SortButton_UpdateArrow(BrowseCurrentBidSort, "list", "bid")

	-- -- Show the no results text if no items found
	-- if numBatchAuctions == 0 then
		-- BrowseNoResultsText:Show()
	-- else
		-- BrowseNoResultsText:Hide()
	-- end

	-- for i=1, NUM_BROWSE_TO_DISPLAY do
		-- index = offset + i
		-- button = getglobal("BrowseButton"..i)
		-- -- Show or hide auction buttons
		-- if index > numBatchAuctions then
			-- button:Hide()
			-- -- If the last button is empty then set isLastSlotEmpty var
			-- if i == NUM_BROWSE_TO_DISPLAY then
				-- isLastSlotEmpty = 1
			-- end
		-- else
			-- button:Show()

			-- buttonName = "BrowseButton"..i
			-- local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder =  GetAuctionItemInfo("list", index);
			-- -- duration = GetAuctionItemTimeLeft("list", offset + i)
			-- -- Resize button if there isn't a scrollbar
			-- buttonHighlight = getglobal("BrowseButton"..i.."Highlight")
			-- if numBatchAuctions < NUM_BROWSE_TO_DISPLAY then
				-- button:SetWidth(557)
				-- buttonHighlight:SetWidth(523)
				-- BrowseCurrentBidSort:SetWidth(173)
			-- else
				-- button:SetWidth(532)
				-- buttonHighlight:SetWidth(502)
				-- BrowseCurrentBidSort:SetWidth(157)
			-- end
			-- -- Set name and quality color
			-- color = ITEM_QUALITY_COLORS[searchResults[i].quality]
			-- itemName = getglobal(buttonName.."Name")
			-- itemName:SetText(searchResults[i].name)
			-- itemName:SetVertexColor(color.r, color.g, color.b)
			-- -- Set level
			-- if searchResults[i].level > UnitLevel("player") then
				-- getglobal(buttonName.."Level"):SetText(RED_FONT_COLOR_CODE..level..FONT_COLOR_CODE_CLOSE)
			-- else
				-- getglobal(buttonName.."Level"):SetText(searchResults[i].level)
			-- end
			-- -- Set high bidder
			-- getglobal(buttonName.."HighBidder"):SetText(searchResults[i].highBidder)
			-- -- Set closing time
			-- getglobal(buttonName.."ClosingTimeText"):SetText(AuctionFrame_GetTimeLeftText(searchResults[i].duration))
			-- getglobal(buttonName.."ClosingTime").tooltip = AuctionFrame_GetTimeLeftTooltipText(searchResults[i].duration)
			-- -- Set item texture, count, and usability
			-- iconTexture = getglobal(buttonName.."ItemIconTexture")
			-- iconTexture:SetTexture(searchResults[i].texture)
			-- if not searchResults[i].canUse then
				-- iconTexture:SetVertexColor(1.0, 0.1, 0.1)
			-- else
				-- iconTexture:SetVertexColor(1.0, 1.0, 1.0)
			-- end
			-- itemCount = getglobal(buttonName.."ItemCount")
			-- if searchResults[i].stackSize > 1 then
				-- itemCount:SetText(searchResults[i].stackSize)
				-- itemCount:Show()
			-- else
				-- itemCount:Hide()
			-- end
			-- -- Set high bid
			-- moneyFrame = getglobal(buttonName.."MoneyFrame")
			-- buyoutMoneyFrame = getglobal(buttonName.."BuyoutMoneyFrame")
			-- buyoutText = getglobal(buttonName.."BuyoutText")
			-- -- If not bidAmount set the bid amount to the min bid
			-- if searchResults[i].bidAmount == 0 then
				-- MoneyFrame_Update(moneyFrame:GetName(), searchResults[i].minBid)
			-- else
				-- MoneyFrame_Update(moneyFrame:GetName(), searchResults[i].bidAmount)
			-- end
			
			-- if searchResults[i].buyoutPrice > 0 then
				-- moneyFrame:SetPoint("RIGHT", buttonName, "RIGHT", 10, 10)
				-- MoneyFrame_Update(buyoutMoneyFrame:GetName(), searchResults[i].buyoutPrice)
				-- buyoutMoneyFrame:Show()
				-- buyoutText:Show()
			-- else
				-- moneyFrame:SetPoint("RIGHT", buttonName, "RIGHT", 10, 3)
				-- buyoutMoneyFrame:Hide()
				-- buyoutText:Hide()
			-- end
			-- -- Set high bidder
			-- local highBidder = searchResults[i].highBidder
			-- if not highBidder then
				-- highBidder = RED_FONT_COLOR_CODE..NO_BIDS..FONT_COLOR_CODE_CLOSE
			-- end
			-- getglobal(buttonName.."HighBidder"):SetText(highBidder)
			-- -- Set highlight
			-- if GetSelectedAuctionItem("list") and (offset + i) == GetSelectedAuctionItem("list") then
				-- button:LockHighlight()
				-- if highBidder ~= UnitName("player") then
					-- BrowseBidButton:Enable()
				-- end
				
				-- if searchResults[i].buyoutPrice > 0 and searchResults[i].buyoutPrice >= searchResults[i].minBid then
					-- BrowseBuyoutButton:Enable()
					-- AuctionFrame.buyoutPrice = searchResults[i].buyoutPrice
				-- else
					-- AuctionFrame.buyoutPrice = nil
				-- end
				-- -- Set bid
				-- local bidAmount = searchResults[i].bidAmount
				-- if bidAmount > 0 then
					-- bidAmount = bidAmount + searchResults[i].minIncrement
					-- MoneyInputFrame_SetCopper(BrowseBidPrice, bidAmount)
				-- else
					-- MoneyInputFrame_SetCopper(BrowseBidPrice, searchResults[i].minBid)
				-- end
				
			-- else
				-- button:UnlockHighlight()
			-- end
		-- end
	-- end
	
	-- BrowsePrevPageButton:Hide()
	-- BrowseNextPageButton:Hide()
	-- BrowseScanCountText:Hide()
	-- FauxScrollFrame_Update(BrowseScrollFrame, numBatchAuctions, NUM_BROWSE_TO_DISPLAY, AUCTIONS_BUTTON_HEIGHT)
-- end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnUpdate", function()

end)
-- eventFrame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
-- eventFrame:SetScript("OnEvent", function(event)
	-- if state == STATE_POSTQUERY then
		-- processQueryResults()
	-- end
-- end)