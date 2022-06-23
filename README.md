# Remote control peripherals
This is a project to allow peripherals to be accessed/controlled over encrypted rednet. This uses my [encrypted rednet project](https://github.com/MasonGulu/cc-rednet-encrypt).

To install simply run `wget run https://raw.githubusercontent.com/MasonGulu/cc-remote-peripheral/master/installer.lua`.

To use this project, install the `server` files on the host computer (the one with the peripheral), and the `client` files on the computer you want to access the peripheral from. Then run `rhost` on the server after configuring the password and hostname you'd like (you *can* run without a password, and the password is stored in plaintext {but transmitted over an encrypted connection}).

Use on the client is very simple, as this can be used as a drop in replacement for `peripheral`.

```lua
peripheral = require "rperipheral"
local monitor = peripheral.wrap("password@host:monitor_0")
monitor.write("Hello World")
```

Any function that you can normally pass a side or peripheral name into can instead be given a string of the format `[password@]{id|hostname}:peripheral`, where you can use `id` (the computer ID) or `hostname` (the rednet hostname). Any normal peripheral names will instead be passed through to the original `peripheral` class.

## Use with existing programs
You can simply replace peripheral with the client `rperipheral`, then you can add an entry to `rperipheral.lookup`. For example if your program expects a monitor on the top, and wraps that monitor based on the name "top", you can add en entry to `rperipheral.lookup` like so:

```lua
peripheral = require "rperipheral"
periphreal.lookup.top = "password@host:monitor_0"
```

Then anytime "top" is passed into a peripheral function, it will instead be substituted for "password@host:monitor_0"

## Considerations
A request -> response can take up to 200ms. This means for every method you call on a remote peripheral you will be delaying the execution of your program by about 200ms. This WILL be worse if you use `peripheral.call`, as that does not save the key exchange you do with the server, adding *another* 200ms to each call. I heavily suggest using `peripheral.wrap` if you plan on using a peripheral more than a single time, as that will return a table of functions that all use the same client object, and will save significant time by not performing a new key exchange every use.