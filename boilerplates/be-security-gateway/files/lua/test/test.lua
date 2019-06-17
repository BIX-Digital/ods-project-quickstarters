local luaunit = require("luaunit")
local utils_test = require("../src/utils")
-- local any_other_test = require("../src/any-other")


local clientID = "testID"
local authBasic = "Basic dGVzdElEOnRlc3RTRUM="
local authBearer = "Bearer dGVzdElEOnRlc3RTRUM="


testUtils = {} --class
function testUtils:testIsBasic()
    luaunit.assertTrue( utils_test.isBasic(authBasic) )
    luaunit.assertFalse( utils_test.isBasic(authBearer) )
end

function testUtils:testIsBearer()
    luaunit.assertTrue( utils_test.isBearer(authBearer) )
    luaunit.assertFalse( utils_test.isBearer(authBasic) )
end

function testUtils:testIsEmpty()
    local empty
    luaunit.assertTrue( utils_test.isEmpty(empty) )
    luaunit.assertTrue( utils_test.isEmpty("") )
    luaunit.assertFalse( utils_test.isEmpty("empty") )
end

function testUtils:testGetUserFromBasic()
    local decAuth = ngx.decode_base64(utils_test.splitBy(authBasic, " ")[2])
    luaunit.assertEquals( utils_test.getUserFromBasic(decAuth), clientID )
end

function testUtils:testStartsWith()
    luaunit.assertTrue( utils_test.startsWith(authBasic, "Basic") )
    luaunit.assertFalse( utils_test.startsWith(authBasic, "Bearer") )
end

function testUtils:testSplitBy()
    local decAuth = utils_test.splitBy(authBasic, " ")
    luaunit.assertEquals( table.getn(decAuth), 2 )
end

-- testAnyOther = {} --class
-- function testAnyOther:testSomething()
--     assertTrue( any_other_test.someFunc() )
-- end

os.exit( luaunit.LuaUnit.run() )
