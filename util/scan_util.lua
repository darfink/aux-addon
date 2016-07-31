local m, public, private = Aux.module'scan_util'

function public.default_filter(str)
    return {
        arity = 0,
        test = function()
            return function(auction_record)
                return Aux.util.any(auction_record.tooltip, function(entry)
                    return strfind(strupper(entry.left_text or ''), strupper(str or ''), 1, true) or strfind(strupper(entry.right_text or ''), strupper(str or ''), 1, true)
                end)
            end
        end,
    }
end

public.filters = {

    ['utilizable'] = {
        arity = 0,
        test = function()
            return function(auction_record)
                return auction_record.usable and not Aux.info.tooltip_match(ITEM_SPELL_KNOWN, auction_record.tooltip)
            end
        end,
    },

    ['tooltip'] = {
        arity = 1,
        test = function(str)
            if str then
                return m.default_filter(str).test()
            else
                return false, {}, 'Erroneous tooltip modifier'
            end
        end,
    },

    ['item'] = {
        arity = 1,
        test = function(name)
            if not name then
                return false, aux_auctionable_items, 'Erroneous item modifier'
            end

            return function(auction_record)
                return strlower(Aux.info.item(auction_record.item_id).name) == name
            end
        end
    },

    ['left'] = {
        arity = 1,
        test = function(duration)
            if not duration then
                return false, {'30m', '2h', '8h', '24h'}, 'Erroneous time left modifier'
            end

            local code = ({
                ['30m'] = 1,
                ['2h'] = 2,
                ['8h'] = 3,
                ['24h'] = 4,
            })[duration or '']

            if not code then
                return false, {}, 'Erroneous time left modifier'
            end

            return function(auction_record)
                return auction_record.duration == code
            end
        end
    },

    ['rarity'] = {
        arity = 1,
        test = function(rarity)
            if not rarity then
                return false, {'poor', 'common', 'uncommon', 'rare', 'epic'}, 'Erroneous rarity modifier'
            end

            local code = Aux.util.key(rarity, {'poor', 'common', 'uncommon', 'rare', 'epic'})
            code = code and code - 1

            if not code then
                return false, {}, 'Erroneous rarity modifier'
            end

            return function(auction_record)
                return auction_record.quality == code
            end
        end
    },

    ['min-lvl'] = {
        arity = 1,
        test = function(level)
            level = tonumber(level or '')
            if level then
                return function(auction_record)
                    return auction_record.level >= level
                end
            else
                return false, {}, 'Erroneous min level modifier'
            end
        end
    },

    ['max-lvl'] = {
        arity = 1,
        test = function(level)
            level = tonumber(level or '')
            if level then
                return function(auction_record)
                    return auction_record.level <= level
                end
            else
                return false, {}, 'Erroneous max level modifier'
            end
        end
    },

    ['min-unit-bid'] = {
        arity = 1,
        test = function(amount)
            amount = Aux.money.from_string(amount or '') or 0
            if amount > 0 then
                return function(auction_record)
                    return auction_record.unit_bid_price >= amount
                end
            else
                return false, {}, 'Erroneous min bid modifier'
            end
        end
    },

    ['min-unit-buy'] = {
        arity = 1,
        test = function(amount)
            amount = Aux.money.from_string(amount or '') or 0
            if amount > 0 then
                return function(auction_record)
                    return auction_record.unit_buyout_price >= amount
                end
            else
                return false, {}, 'Erroneous min buyout modifier'
            end
        end
    },

    ['max-unit-bid'] = {
        arity = 1,
        test = function(amount)
            amount = Aux.money.from_string(amount or '') or 0
            if amount > 0 then
                return function(auction_record)
                    return auction_record.unit_bid_price <= amount
                end
            else
                return false, {}, 'Erroneous max bid modifier'
            end
        end
    },

    ['max-unit-buy'] = {
        arity = 1,
        test = function(amount)
            amount = Aux.money.from_string(amount or '') or 0
            if amount > 0 then
                return function(auction_record)
                    return auction_record.buyout_price > 0 and auction_record.unit_buyout_price <= amount
                end
            else
                return false, {}, 'Erroneous max buyout modifier'
            end
        end
    },

    ['bid-pct'] = {
        arity = 1,
        test = function(pct)
            pct = tonumber(pct)
            if pct then
                return function(auction_record)
                    return auction_record.unit_buyout_price > 0
                            and Aux.history.value(auction_record.item_key)
                            and auction_record.unit_buyout_price / Aux.history.value(auction_record.item_key) * 100 <= pct
                end
            else
                return false, {}, 'Erroneous bid percentage modifier'
            end
        end
    },

    ['buy-pct'] = {
        arity = 1,
        test = function(pct)
            pct = tonumber(pct)
            if pct then
                return function(auction_record)
                    return auction_record.unit_buyout_price > 0
                            and Aux.history.value(auction_record.item_key)
                            and auction_record.unit_buyout_price / Aux.history.value(auction_record.item_key) * 100 <= pct
                end
            else
                return false, {}, 'Erroneous buyout percentage modifier'
            end
        end
    },

    ['bid-profit'] = {
        arity = 1,
        test = function(amount)
            amount = Aux.money.from_string(amount or '') or 0
            if amount > 0 then
                return function(auction_record)
                    return Aux.history.value(auction_record.item_key) and Aux.history.value(auction_record.item_key) * auction_record.aux_quantity - auction_record.bid_price >= amount
                end
            else
                return false, {}, 'Erroneous bid profit modifier'
            end
        end
    },

    ['buy-profit'] = {
        arity = 1,
        test = function(amount)
            amount = Aux.money.from_string(amount or '') or 0
            if amount > 0 then
                return function(auction_record)
                    return auction_record.buyout_price > 0 and Aux.history.value(auction_record.item_key) and Aux.history.value(auction_record.item_key) * auction_record.aux_quantity - auction_record.buyout_price >= amount
                end
            else
                return false, {}, 'Erroneous buyout profit modifier'
            end
        end
    },

    ['bid-dis-profit'] = {
        arity = 1,
        test = function(amount)
            amount = Aux.money.from_string(amount or '') or 0
            if amount > 0 then
                return function(auction_record)
                    local disenchant_value = Aux.disenchant.value(auction_record.slot, auction_record.quality, auction_record.level)
                    return disenchant_value and disenchant_value - auction_record.bid_price >= amount
                end
            else
                return false, {}, 'Erroneous bid disenchant profit modifier'
            end
        end
    },

    ['buy-dis-profit'] = {
        arity = 1,
        test = function(amount)
            amount = Aux.money.from_string(amount or '') or 0
            if amount > 0 then
                return function(auction_record)
                    local disenchant_value = Aux.disenchant.value(auction_record.slot, auction_record.quality, auction_record.level)
                    return auction_record.buyout_price > 0 and disenchant_value and disenchant_value - auction_record.buyout_price >= amount
                end
            else
                return false, {}, 'Erroneous buyout disenchant profit modifier'
            end
        end
    },

    ['bid-vend-profit'] = {
        arity = 1,
        test = function(amount)
            amount = Aux.money.from_string(amount or '') or 0
            if amount > 0 then
                return function(auction_record)
                    local vendor_price = Aux.cache.merchant_info(auction_record.item_id)
                    return vendor_price and vendor_price * auction_record.aux_quantity - auction_record.bid_price >= amount
                end
            else
                return false, {}, 'Erroneous bid vendor profit modifier'
            end
        end
    },

    ['buy-vend-profit'] = {
        arity = 1,
        test = function(amount)
            amount = Aux.money.from_string(amount or '') or 0
            if amount > 0 then
                return function(auction_record)
                    local vendor_price = Aux.cache.merchant_info(auction_record.item_id)
                    return auction_record.buyout_price > 0 and vendor_price and vendor_price * auction_record.aux_quantity - auction_record.buyout_price >= amount
                end
            else
                return false, {}, 'Erroneous buyout vendor profit modifier'
            end
        end
    },

    ['discard'] = {
        arity = 0,
        test = function()
            return function()
                return false
            end
        end
    },
}

function public.find(auction_record, status_bar, on_abort, on_failure, on_success)

    local function test(index)
        local auction_info = Aux.info.auction(index, auction_record.query_type)
        return auction_info and auction_info.search_signature == auction_record.search_signature
    end

    local queries = {}
    tinsert(queries, {})

    if auction_record.blizzard_query then

        local blizzard_query1 = Aux.util.copy(auction_record.blizzard_query)
        blizzard_query1.first_page = auction_record.page
        blizzard_query1.last_page = auction_record.page
        tinsert(queries, {
            blizzard_query = blizzard_query1,
        })

        if auction_record.page > 0 then
            local blizzard_query2 = Aux.util.copy(auction_record.blizzard_query)
            blizzard_query2.first_page = auction_record.page - 1
            blizzard_query2.last_page = auction_record.page - 1
            tinsert(queries, {
                blizzard_query = blizzard_query1,
            })
        end

        local item_query = m.item_query(auction_record.item_id, 1, 1)
        if not Aux.util.eq(auction_record.blizzard_query, item_query.blizzard_query) then
            tinsert(queries, item_query)
        end
    end


    local found
    return Aux.scan.start{
        type = auction_record.query_type,
        queries = queries,
        on_scan_start = function()
            status_bar:update_status(0, 0)
            status_bar:set_text('Searching auction...')
        end,
        on_start_query = function(query_index)
            status_bar:update_status((query_index - 1) / getn(queries) * 100, 0)
        end,
        on_auction = function(auction_record, ctrl)
            if test(auction_record.index) then
                found = true
                ctrl.suspend()
                status_bar:update_status(100, 100)
                status_bar:set_text('Auction found')
                return on_success(auction_record.index)
            end
        end,
        on_abort = function()
            if not found then
                status_bar:update_status(100, 100)
                status_bar:set_text('Auction not found')
                return on_abort()
            end
        end,
        on_complete = function()
            status_bar:update_status(100, 100)
            status_bar:set_text('Auction not found')
            return on_failure()
        end,
    }
end

function public.filter_builder()
    local filter = ''
    return {
        append = function(self, modifier)
            modifier = modifier
            filter = filter == '' and modifier or filter..'/'..modifier
        end,
        prepend = function(self, modifier)
            modifier = modifier
            filter = filter == '' and modifier or modifier..'/'..filter
        end,
        get = function(self)
            return filter
        end
    }
end

function public.item_query(item_id, first_page, last_page)

    local item_info = Aux.info.item(item_id)

    if item_info then
        local filter = m.query(item_info.name..'/exact')
        filter.blizzard_query.first_page = first_page
        filter.blizzard_query.last_page = last_page
        return {
            validator = filter.validator,
            blizzard_query = filter.blizzard_query,
        }
    end
end

function public.parse_filter_string(filter_string)
    local parts = Aux.util.split(filter_string, ';')

    local filters = {}
    for _, str in ipairs(parts) do
        str = Aux.util.trim(str)

        local filter, _, error = m.query(str)

        if not filter then
            Aux.log('Invalid filter: '..error)
            return
        elseif filter.name and strlen(filter.name) > 63 then
            Aux.log('Invalid filter: The name may not longer than 63 characters')
            return
        else
            tinsert(filters, filter)
        end
    end

    return filters
end

function public.query(filter_term)
    local parts = Aux.util.map(Aux.util.split(filter_term, '/'), function(part) return strlower(Aux.util.trim(part)) end)

    local blizzard_filters = {}
    local post_filters = {}
    local prettified = m.filter_builder()
    local polish_notation_counter = 0
    local i = 1

    local function post_filter(str)
        local filter = m.filters[str]
        if filter then
            prettified:append('|cffffff00'..str..'|r')
        else
            filter = filter or m.default_filter(str)
            prettified:append('|cffff9218'..str..'|r')
        end

        local args = {}
        for j=1, filter.arity do
            local arg = parts[i - 1 + j]
            if arg then
                tinsert(args, arg)
                prettified:append('|cffff9218'..arg..'|r')
            end
        end
        i = i + filter.arity

        local test, suggestions, error = filter.test(unpack(args))
        if test then
            tinsert(post_filters, test)
        else
            return error, i > getn(parts) and suggestions or {}
        end
    end

    while i <= getn(parts) do
        local str = parts[i]
        i = i + 1

        if str == 'and*' or str == 'or*' then
            if polish_notation_counter > 1 then
                break
            end
            polish_notation_counter = 0
            tinsert(post_filters, str)
            prettified:append('|cffffff00'..str..'|r')
        elseif polish_notation_counter > 0
                or (function(_, _, m) return m == '' or m and tonumber(m) > 2 end)(strfind(str, '^and(%d*)$'))
                or (function(_, _, m) return m == '' or m and tonumber(m) > 2 end)(strfind(str, '^or(%d*)$'))
                or str == 'not'
        then
            polish_notation_counter = polish_notation_counter == 0 and polish_notation_counter + 1 or polish_notation_counter
            if strfind(str, '^and%d*$') or strfind(str, '^or%d*$') then
                local and_match, or_match = {strfind(str, '^(and)(%d*)$')}, {strfind(str, '^(or)(%d*)$') }
                local op = and_match[3] or or_match[3]
                local count = (tonumber(and_match[4]) or tonumber(or_match[4]) or 2) - 1
                polish_notation_counter = polish_notation_counter + count
                for _=1,count do
                    tinsert(post_filters, op)
                end
                prettified:append('|cffffff00'..str..'|r')
            elseif str == 'not' then
                tinsert(post_filters, str)
                prettified:append('|cffffff00'..str..'|r')
            elseif str ~= '' then
                polish_notation_counter = polish_notation_counter - 1
                local error, suggestions = post_filter(str)
                if error then
                    return false, suggestions, error
                end
            end
        elseif tonumber(str) then
            if tonumber(str) < 1 or tonumber(str) > 60 then
                return false, {}, 'Erroneous level range modifier'
            end
            if not blizzard_filters.min_level then
                blizzard_filters.min_level = tonumber(str)
                prettified:append(Aux.gui.inline_color({216, 225, 211, 1})..str..'|r')
            elseif not blizzard_filters.max_level and tonumber(str) >= blizzard_filters.min_level then
                blizzard_filters.max_level = tonumber(str)
                prettified:append(Aux.gui.inline_color({216, 225, 211, 1})..str..'|r')
            else
                return false, {}, 'Erroneous level range modifier'
            end
        elseif Aux.item_class_index(str) and not (blizzard_filters.class and not blizzard_filters.subclass and str == strlower(({ GetAuctionItemClasses() })[10])) then
            if not blizzard_filters.class then
                blizzard_filters.class = Aux.item_class_index(str)
                prettified:append(Aux.gui.inline_color({216, 225, 211, 1})..str..'|r')
            else
                return false, {}, 'Erroneous item class modifier'
            end
        elseif blizzard_filters.class and Aux.item_subclass_index(blizzard_filters.class, str) then
            if not blizzard_filters.subclass then
                blizzard_filters.subclass = Aux.item_subclass_index(blizzard_filters.class, str)
                prettified:append(Aux.gui.inline_color({216, 225, 211, 1})..str..'|r')
            else
                return false, {}, 'Erroneous item subclass modifier'
            end
        elseif blizzard_filters.subclass and Aux.item_slot_index(blizzard_filters.class, blizzard_filters.subclass, str) then
            if not blizzard_filters.slot then
                blizzard_filters.slot = Aux.item_slot_index(blizzard_filters.class, blizzard_filters.subclass, str)
                prettified:append(Aux.gui.inline_color({216, 225, 211, 1})..str..'|r')
            else
                return false, {}, 'Erroneous item slot modifier'
            end
        elseif Aux.item_quality_index(str) then
            if not blizzard_filters.quality then
                blizzard_filters.quality = Aux.item_quality_index(str)
                prettified:append(Aux.gui.inline_color({216, 225, 211, 1})..str..'|r')
            else
                return false, {}, 'Erroneous rarity modifier'
            end
        elseif str == 'usable' then
            if not blizzard_filters.usable then
                blizzard_filters.usable = true
                prettified:append(Aux.gui.inline_color({216, 225, 211, 1})..str..'|r')
            else
                return false, {}, 'Erroneous usable only modifier'
            end
        elseif str == 'exact' then
            if not blizzard_filters.exact then
                blizzard_filters.exact = true
            else
                return false, {}, 'Erroneous exact only modifier'
            end
        elseif i == 2 and not m.filters[str] then
            blizzard_filters.name = str
        elseif str ~= '' then
            local error, suggestions = post_filter(str)
            if error then
                return false, suggestions, error
            end
        else
            return false, {}, 'Empty modifier'
        end
    end

    if polish_notation_counter > 0 then
        local suggestions = {}
        for filter, _ in m.filters do
            tinsert(suggestions, strlower(filter))
        end
        tinsert(suggestions, 'and')
        tinsert(suggestions, 'or')
        tinsert(suggestions, 'not')
        return false, i > getn(parts) and suggestions, 'Malformed expression'
    end

    if blizzard_filters.exact then
        if blizzard_filters.min_level
                or blizzard_filters.max_level
                or blizzard_filters.class
                or blizzard_filters.subclass
                or blizzard_filters.slot
                or blizzard_filters.quality
                or blizzard_filters.usable
                or not blizzard_filters.name
        then
            return false, {}, 'Erroneous exact only modifier'
        else
            prettified:prepend(Aux.info.display_name(Aux.cache.item_id(blizzard_filters.name)) or Aux.gui.inline_color({216, 225, 211, 1})..'['..blizzard_filters.name..']|r')
        end
    elseif blizzard_filters.name then
        if blizzard_filters.name == '' then
            prettified:prepend('|cffff0000'..'No Filter'..'|r')
        else
            prettified:prepend(Aux.gui.inline_color({216, 225, 211, 1})..blizzard_filters.name..'|r')
        end
    end

    return {
        blizzard_query = m.blizzard_query(blizzard_filters),
        validator = m.validator(blizzard_filters, post_filters),
        prettified = prettified:get(),
    }, m.suggestions(blizzard_filters, getn(parts))
end

function public.suggestions(blizzard_filter, num_parts)

    local suggestions = {}

    if blizzard_filter.name
            and not blizzard_filter.min_level
            and not blizzard_filter.max_level
            and not blizzard_filter.class
            and not blizzard_filter.subclass
            and not blizzard_filter.slot
            and not blizzard_filter.quality
            and not blizzard_filter.usable
    then
        tinsert(suggestions, 'exact')
    end

    tinsert(suggestions, 'and')
    tinsert(suggestions, 'or')
    tinsert(suggestions, 'not')
    tinsert(suggestions, 'tt')

    for filter, _ in pairs(m.filters) do
        tinsert(suggestions, strlower(filter))
    end

    -- classes
    if not blizzard_filter.class then
        for _, class in ipairs({ GetAuctionItemClasses() }) do
            tinsert(suggestions, class)
        end
    end

    -- subclasses
    if blizzard_filter.class and not blizzard_filter.subclass then
        for _, subclass in ipairs({ GetAuctionItemSubClasses(blizzard_filter.class) }) do
            tinsert(suggestions, subclass)
        end
    end

    -- slots
    if blizzard_filter.class and blizzard_filter.subclass and not blizzard_filter.slot then
        for _, invtype in ipairs({ GetAuctionInvTypes(blizzard_filter.class, blizzard_filter.subclass) }) do
            tinsert(suggestions, getglobal(invtype))
        end
    end

    -- usable
    if not blizzard_filter.usable then
        tinsert(suggestions, 'usable')
    end

    -- rarities
    if not blizzard_filter.quality then
        for i=0,4 do
            tinsert(suggestions, getglobal('ITEM_QUALITY'..i..'_DESC'))
        end
    end

    -- item names
    if num_parts == 1 and blizzard_filter.name == '' then
        for _, name in aux_auctionable_items do
            tinsert(suggestions, name..'/exact')
        end
    end

    return suggestions
end

function public.blizzard_query(filter)
    local query = { name=filter.name }

    local item_info, class_index, subclass_index, slot_index
    if filter.exact then
        local item_id = Aux.cache.item_id(filter.name)
        item_info = Aux.info.item(item_id)
        class_index = item_info and Aux.item_class_index(item_info.class)
        subclass_index = class_index and item_info.subclass and Aux.item_subclass_index(class_index, item_info.subclass)
        slot_index = subclass_index and item_info.slot and Aux.item_slot_index(class_index, subclass_index, item_info.slot)
    end

    if item_info then
        query.min_level = item_info.level
        query.max_level = item_info.level
        query.class = class_index
        query.subclass = subclass_index
        query.slot = item_info.class
        query.usable = item_info.usable
        query.quality = item_info.quality
    else
        query.min_level = filter.min_level
        query.max_level = filter.max_level
        query.class = filter.class
        query.subclass = filter.subclass
        query.slot = filter.slot
        query.usable = filter.usable and 1
        query.quality = filter.quality
    end

    return query
end

function public.validator(blizzard_filter, post_filter)

    return function(record)
        if blizzard_filter.exact and strlower(Aux.info.item(record.item_id).name) ~= blizzard_filter.name then
            return false
        end
        if getn(post_filter) > 0 then
            local stack = {}
            for i=getn(post_filter),1,-1 do
                local op = post_filter[i]
                if op == 'and' then
                    local a, b = tremove(stack), tremove(stack)
                    tinsert(stack, a and b)
                elseif op == 'or' then
                    local a, b = tremove(stack), tremove(stack)
                    tinsert(stack, a or b)
                elseif op == 'not' then
                    tinsert(stack, not tremove(stack))
                elseif op == 'and*' then
                    stack = {Aux.util.all(stack, Aux.util.id)}
                elseif op == 'or*' then
                    stack = {Aux.util.any(stack, Aux.util.id)}
                else
                    tinsert(stack, op(record) and true or false)
                end
            end
            return Aux.util.all(stack, Aux.util.id)
        end
        return true
    end
end