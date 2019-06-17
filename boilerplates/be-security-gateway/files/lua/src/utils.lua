local _M = {}

function _M.isBearer(str)
    return str:find("Bearer ") == 1
end

function _M.isBasic(str)
    return str:find("Basic ") == 1
end

function _M.isEmpty(str)
    return str == nil or str == ''
end

function _M.getUserFromBasic(str)
    local splitted = string.gmatch(str, '([^:]+)')
    return splitted()
end

function _M.startsWith(str, start)
    return string.sub(str,1,string.len(start)) == start
end

function _M.splitBy(pString, pPattern)
    local tbl = {}  -- NOTE: use {n = 0} in Lua-5.0
    local fpat = "(.-)" .. pPattern
    local last_end = 1

    local s, e, cap = pString:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(tbl,cap)
        end

        last_end = e + 1
        s, e, cap = pString:find(fpat, last_end)
    end

    if last_end <= #pString then
        cap = pString:sub(last_end)
        table.insert(tbl, cap)
    end

    return tbl
end

return _M
