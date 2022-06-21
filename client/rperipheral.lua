local rperipheral = {}
local client = require("client")
local expect=require"cc.expect".expect

--- Split a string by it's separator.
-- @tparam string inputstr String to split.
-- @tparam string sep Separator to split the string by.
-- @treturn table Table containing the split string
local function split(inputstr, sep)
  expect(1,inputstr,"string")
  expect(1,sep,"string","nil")
  sep = sep or ","
  local t={}
  for str in inputstr:gmatch("([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

--- Wrap a remote peripheral
-- @tparam string address [password@]{id|hostname}:peripheral
-- @treturn table function table; same as calling peripheral.wrap()
function rperipheral.wrap(address, ...)
  -- address will either be
  -- password@hostname:peripheral
  -- or password@id:peripheral
  if type(address) == "table" then
    address = arg[1] -- manually adjust this so when you call the table, it gets rid of self
  end
  expect(1, address, "string")
  local tmp = split(address, "@") -- attempt to seperate password from rest of arg
  local password
  if (#tmp == 2) then
    password = tmp[1]
    tmp = split(tmp[2], ":") -- attempt to seperate id/hostname from peripheral
  else
    tmp = split(tmp[1], ":")
  end
  local hostname, id, peripheralName
  id = tonumber(tmp[1])
  if not id then
    hostname = tmp[1]
  end
  peripheralName = tmp[2]
  c = client.new("rperipheral", {hostId=id, hostname=hostname})
  local function auth()
    if type(password) ~= "nil" then
      local status, response = c:sendReq({"authorize",password})
      assert(status, response) -- this will cause an error anytime this is not able to reach the server
      assert(response[1], "Password incorrect")
    end
  end
  auth()
  c.onKeyExchange = auth
  local status, pT = c:sendReq({"get", peripheralName})
  assert(status, pT)
  assert(pT[1] ~= "Unauthorized", "Unauthorized")
  local T = {}
  for k,v in pairs(pT) do
    T[v] = function (...)
      local stat, returnT = c:sendReq({"call", peripheralName, v, arg})
      assert(stat, returnT)
      assert(returnT[1] ~= "Unauthorized", "Unauthorized")
      return table.unpack(returnT)
    end
  end

  return T
end

setmetatable(rperipheral, {__call=rperipheral.wrap})

return rperipheral