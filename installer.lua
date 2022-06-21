print("This will install rperipheral, select either client or server.")
print("[1] Client")
print("[2] Server")
print("Anything else to exit")
local selection = io.read()

local function install(url, toInstall)
  for k,v in ipairs(toInstall) do
    local file = fs.open(v, "w")
    print(url..v)
    local web = http.get(url..v)
    print("Installing "..v.."...")
    if type(file) == "nil" then
      term.clear()
      term.setCursorPos(1,1)
      error("Unable to open "..v)
    end
    if (not web) or web.getResponseCode() ~= 200 then
      term.clear()
      term.setCursorPos(1,1)
      error("Unable to download, got "..tostring(web.getResponseCode()).." as response.")
    end
    file.write(web.readAll())
    file.close()
    web.close()
  end
end

if selection == "1" then
  -- Client
  print("Installing client..")
  install("https://raw.githubusercontent.com/MasonGulu/cc-rednet-encrypt/master/", {"client.lua", "common.lua", "ecc.lua"})
  install("https://raw.githubusercontent.com/MasonGulu/cc-remote-peripheral/master/client/", {"rperipheral.lua"})
elseif selection == "2" then
  -- Server
  print("Installing server..")
  install("https://raw.githubusercontent.com/MasonGulu/cc-rednet-encrypt/master/", {"server.lua", "common.lua", "ecc.lua"})
  install("https://raw.githubusercontent.com/MasonGulu/cc-remote-peripheral/master/server/", {"rhost.lua"})
end