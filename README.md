# Remote control peripherals
This is a project to allow peripherals to be accessed/controlled over encrypted rednet. This uses my [encrypted rednet project](https://github.com/MasonGulu/cc-rednet-encrypt).

To install simply run `wget run https://raw.githubusercontent.com/MasonGulu/cc-remote-peripheral/master/installer.lua`.

To use this project, install the `server` files on the host computer (the one with the peripheral), and the `client` files on the computer you want to access the peripheral from. Then run `rhost` on the server after configuring the password and hostname you'd like (you *can* run without a password).

To use on the client simply require `rperipheral`, and call the `wrap` method (or you can call `rperipheral` itself.)

```lua
local monitor = require "rperipheral" "password@host:monitor_0"
monitor.write("Hello World")
```

The `wrap` function expects a string of the format `[password@]{id|hostname}:peripheral`, where you can use `id` (the computer ID) or `hostname` (the rednet hostname).
