local cjson = require("cjson")

local _M = {}

function _M.run (server_signature)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.header.content_type = "application/json; charset=utf-8"
    ngx.say(cjson.encode({ timestamp = os.time(os.date("!*t")), status = ngx.HTTP_INTERNAL_SERVER_ERROR, error = "Internal Server Error", message = "An error occurred", server = server_signature }))
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

return _M
