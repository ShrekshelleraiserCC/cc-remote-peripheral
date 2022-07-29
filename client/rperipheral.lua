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

--- decode an address
-- @return[1] true isAddress
-- @treturn[1] nil/string password
-- @treturn[1] nil/string hostname
-- @treturn[1] nil/int id
-- @treturn[1] string peripheralName
-- @return[2] false is not address
-- @treturn[2] string same as address input
local function decodeAddress(address)
  expect(1, address, "string")
  local tmp = split(address, "@") -- attempt to seperate password from rest of arg
  local password
  if (#tmp == 2) then
    password = tmp[1]
    tmp = split(tmp[2], ":") -- attempt to seperate id/hostname from peripheral
  else
    tmp = split(tmp[1], ":")
  end
  if (#tmp == 1) then
    return false, address
  end
  local hostname, id, peripheralName
  id = tonumber(tmp[1])
  if not id then
    hostname = tmp[1]
  end
  peripheralName = tmp[2]
  return true, password, hostname, id, peripheralName
end

local peripheralBackup = peripheral

rperipheral.lookup = {} -- Lookup table to translate shorter names to long address form
-- i.e. {left="password@host:monitor_0"}

rperipheral.passthrough = true -- allow passthrough to base peripheral functions

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
  address = rperipheral.lookup[address] or address
  local isAddress, password, hostname, id, peripheralName = decodeAddress(address)
  if (not isAddress) and rperipheral.passthrough then
    return peripheralBackup.wrap(address)
  end
  assert(isAddress, "Invalid address format, expects [password@]{id|hostname}:peripheral")
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
  setmetatable(T, pT.meta)
  pT.meta = nil
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

--- Call a method on a remote peripheral
function rperipheral.call(side, method, ...)
  side = rperipheral.lookup[side] or side
  local isAddress, password, hostname, id, peripheralName = decodeAddress(side)
  if (not isAddress) and rperipheral.passthrough then
    return peripheralBackup.call(side, method, table.unpack(arg))
  end
  assert(isAddress, "Invalid address format, expects [password@]{id|hostname}:peripheral")
  c = client.new("rperipheral", {hostId = id, hostname=hostname})
  if type(password ~= "nil") then
    local status, response = c:sendReq({"authorize",password})
    assert(status, response) -- this will cause an error anytime this is not able to reach the server
    assert(response[1], "Password incorrect")
  end
  local stat, returnT = c:sendReq({"call", peripheralName, method, arg})
  assert(stat, returnT)
  assert(returnT[1] ~= "Unauthorized", "Unauthorized")
  return table.unpack(returnT)
end

--- Call isPresent on a remote peripheral
function rperipheral.isPresent(name)
  name = rperipheral.lookup[name] or name
  local isAddress, password, hostname, id, peripheralName = decodeAddress(name)
  if (not isAddress) and rperipheral.passthrough then
    return peripheralBackup.isPresent(name)
  end
  assert(isAddress, "Invalid address format, expects [password@]{id|hostname}:peripheral")
  c = client.new("rperipheral", {hostId = id, hostname=hostname})
  if type(password ~= "nil") then
    local status, response = c:sendReq({"authorize",password})
    assert(status, response) -- this will cause an error anytime this is not able to reach the server
    assert(response[1], "Password incorrect")
  end
  local stat, returnT = c:sendReq({"isPresent", peripheralName})
  assert(stat, returnT)
  assert(returnT[1] ~= "Unauthorized", "Unauthorized")
  return table.unpack(returnT)
end

function rperipheral.getMethods(name)
  -- address will either be
  -- password@hostname:peripheral
  -- or password@id:peripheral
  name = rperipheral.lookup[name] or name
  local isAddress, password, hostname, id, peripheralName = decodeAddress(name)
  if (not isAddress) and rperipheral.passthrough then
    return peripheralBackup.getMethods(name)
  end
  assert(isAddress, "Invalid address format, expects [password@]{id|hostname}:peripheral")
  c = client.new("rperipheral", {hostId=id, hostname=hostname})
  if type(password) ~= "nil" then
    local status, response = c:sendReq({"authorize",password})
    assert(status, response) -- this will cause an error anytime this is not able to reach the server
    assert(response[1], "Password incorrect")
  end
  local status, pT = c:sendReq({"get", peripheralName})
  assert(status, pT)
  assert(pT[1] ~= "Unauthorized", "Unauthorized")
  pT.meta = nil
  return pT
end

function rperipheral.getType(name)
  if type(name) == "table" then
    return getmetatable(name).type
  elseif type(name) == "string" then
    name = rperipheral.lookup[name] or name
    local isAddress, password, hostname, id, peripheralName = decodeAddress(name)
    if (not isAddress) and rperipheral.passthrough then
      return peripheralBackup.getType(name)
    end
    assert(isAddress, "Invalid address format, expects [password@]{id|hostname}:peripheral")
    c = client.new("rperipheral", {hostId=id, hostname=hostname})
    if type(password) ~= "nil" then
      local status, response = c:sendReq({"authorize",password})
      assert(status, response) -- this will cause an error anytime this is not able to reach the server
      assert(response[1], "Password incorrect")
    end
    local status, pT = c:sendReq({"getType", peripheralName})
    assert(status, pT)
    assert(pT[1] ~= "Unauthorized", "Unauthorized")
    return pT[1]
  end
end

function rperipheral.hasType(name, peripehral_type)
  return peripehral_type == rperipheral.getType(name)
end

setmetatable(rperipheral, {__call=rperipheral.wrap, __index=peripheralBackup})

return rperipheral