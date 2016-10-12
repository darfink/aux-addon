module 'aux.tabs.search'

aux_autobuy_filters = t
aux_favorite_searches = t
aux_recent_searches = t

function private.update_search_listings()
	local autobuy_filter_rows = t
	for i, autobuy_filter in aux_autobuy_filters do
		local name = strsub(autobuy_filter.prettified, 1, 250)
		tinsert(autobuy_filter_rows, {
			cols = {{ value=name }},
			search = autobuy_filter,
			index = i,
		})
	end
	autobuy_listing:SetData(autobuy_filter_rows)

	local favorite_search_rows = t
	for i, favorite_search in aux_favorite_searches do
		local name = strsub(favorite_search.prettified, 1, 250)
		tinsert(favorite_search_rows, {
			cols = {{ value=name }},
			search = favorite_search,
			index = i,
		})
	end
	favorite_searches_listing:SetData(favorite_search_rows)

	local recent_search_rows = t
	for i, recent_search in aux_recent_searches do
		local name = strsub(recent_search.prettified, 1, 250)
		tinsert(recent_search_rows, {
			cols = {{ value=name }},
			search = recent_search,
			index = i,
		})
	end
	recent_searches_listing:SetData(recent_search_rows)
end

function private.new_recent_search(filter_string, prettified)
	tinsert(aux_recent_searches, 1, {
		filter_string = filter_string,
		prettified = prettified,
	})
	while getn(aux_recent_searches) > 50 do
		tremove(aux_recent_searches)
	end
	update_search_listings()
end

private.handlers = {
	OnClick = function(st, data, _, button)
		if not data then return end
		if button == 'LeftButton' and IsShiftKeyDown() then
			search_box:SetText(data.search.filter_string)
		elseif button == 'RightButton' and IsShiftKeyDown() then
			add_filter(data.search.filter_string)
		elseif button == 'LeftButton' and IsControlKeyDown() then
			if st == favorite_searches_listing and data.index > 1 then
				local temp = aux_favorite_searches[data.index - 1]
				aux_favorite_searches[data.index - 1] = data.search
				aux_favorite_searches[data.index] = temp
				update_search_listings()
			end
		elseif button == 'RightButton' and IsControlKeyDown() then
			if st == favorite_searches_listing and data.index < getn(aux_favorite_searches) then
				local temp = aux_favorite_searches[data.index + 1]
				aux_favorite_searches[data.index + 1] = data.search
				aux_favorite_searches[data.index] = temp
				update_search_listings()
			end
		elseif button == 'RightButton' and IsAltKeyDown() then
			if st ~= autobuy_listing then
				tinsert(aux_autobuy_filters, 1, data.search)
				update_search_listings()
			end
		elseif button == 'LeftButton' then
			search_box:SetText(data.search.filter_string)
			execute()
		elseif button == 'RightButton' then
			if st == autobuy_listing then
				tremove(aux_autobuy_filters, data.index)
			elseif st == recent_searches_listing then
				tinsert(aux_favorite_searches, 1, data.search)
			elseif st == favorite_searches_listing then
				tremove(aux_favorite_searches, data.index)
			end
			update_search_listings()
		end
	end,
	OnEnter = function(st, data, self)
		if not data then return end
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		GameTooltip:AddLine(gsub(data.search.prettified, ';', '\n\n'), 255/255, 254/255, 250/255, true)
		GameTooltip:Show()
	end,
	OnLeave = function()
		GameTooltip:ClearLines()
		GameTooltip:Hide()
	end
}