green_t = module

local next, setn, type, setmetatable = next, table.setn, type, setmetatable
local wipe, release, acquire, acquire_temp

local pool, pool_size, overflow_pool, tmp = {}, 0, setmetatable({}, {__mode='k'}), {}

CreateFrame('Frame'):SetScript('OnUpdate', function()
	for t in tmp do release(t) end; wipe(tmp)
end)

function wipe(t)
	setmetatable(t, nil); setn(t, 0)
	for k in t do t[k] = nil end
	t.reset, t.reset = nil, 1
	return t
end
public.wipe = wipe

function release(t)
	wipe(t); tmp[t] = nil
	if pool_size < 50 then
		pool_size = pool_size + 1
		pool[pool_size] = t
	else
		overflow_pool[t] = true
	end
end
public.release = release

function acquire()
	if pool_size > 0 then
		pool_size = pool_size - 1
		return pool[pool_size + 1]
	end
	local t = next(overflow_pool)
	if t then overflow_pool[t] = nil; return t end
	return {}
end
public.t.get = acquire

function acquire_temp() local t = acquire(); tmp[t] = true; return t end
public.tt.get = acquire_temp

do local mt = {__newindex=nop}
	function public.empty.get() return setmetatable(acquire_temp(), mt) end
end

do local f, mt
	f = function(_, v) if type(v) == 'table' then tmp[v] = true end return v end
	mt = {__call=f, __sub=f}
	public.temp {get=function() return setmetatable(acquire_temp(), mt) end, set=function(t) tmp[t] = true end}
end
do local f, mt
	f = function(_, v) if type(v) == 'table' then tmp[v] = nil end return v end
	mt = {__call=f, __sub=f}
	public.perm {get=function() return setmetatable(acquire_temp(), mt) end, set=function(t) tmp[t] = nil end}
end

--T :kek(5) :foo(1) :bar{} :moo 'trump' TODO possible alternative constructor syntax, but high overhead, more elegant because not limited, sometimes better looking.

do  local SET, ARRAY, ARRAY0, TABLE = 1, 2, 3, 4
	local function insert(type)
		local chunk = 'local setmetatable, setn, error = setmetatable, table.setn, error; return function(t'
		for i = 1, 98 do chunk = chunk..',a'..i end
		chunk = chunk..',overflow) setmetatable(t, nil)'
		if type == SET then
			for i = 1, 98 do chunk = format('%s; if a%d == nil then return t end; t[a%d] = true', chunk, i, i) end
		elseif type == ARRAY then
			chunk = chunk..'; setn(t, 98); if a1 == nil then return t end; t[1] = a1'
			for i = 2, 98 do chunk = format('%s; if a%d == nil then setn(t, %d); return t end; t[%d] = a%d', chunk, i, i - 1, i, i) end
		elseif type == ARRAY0 then
			chunk = chunk..'; setn(t, 98)'
			for i = 1, 98 do chunk = format('%s; t[%d] = a%d', chunk, i, i) end
		elseif type == TABLE then
			for i = 1, 97, 2 do chunk = format('%s; if a%d == nil then return t end; t[a%d] = a%d', chunk, i, i, i + 1) end
		end
		chunk = chunk..'; return (overflow == nil or error "Overflow.") and t end'
		local f = loadstring(chunk); setfenv(f, M); return f()
	end
	local function getter(type)
		local mt = {__newindex=nop, __call=insert(type)}
		function mt:__index(t) release(self); return setmetatable(t, mt) end
		return function() return setmetatable(t, mt) end
	end
	public(); S.get = getter(SET); A.get = getter(ARRAY); A0.get = getter(ARRAY0); T.get = getter(TABLE)
end