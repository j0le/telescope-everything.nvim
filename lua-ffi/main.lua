-- main.lua


print("start")

local ffi = require('ffi')

ffi.cdef([[
int get_magenta(void)
]])

local lib
if ffi.os == "Windows" then
	lib = ffi.load([[.\murks.dll]])
else
	lib = ffi.load('./main.so')
	assert(lib.get_magenta() == 16711935)
end

print(lib.get_magenta())
print("finish")
