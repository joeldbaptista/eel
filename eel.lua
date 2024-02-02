--
local s = require "stack"
local p = require "parser"
local c = require "compiler"
local m = require "machine"

--
local function read_src(fname)
    local file, error = io.open(fname, "r")
    if not file then
        error(string.format("Unable to open file `%s`"), fname)
    end
	-- 
    local content = file:read("*a")
    file:close()
    return content
end

--
local function eel(fname)
	local mem = {} -- not actually being used
	local stack = s.stack()
	local top = 0
	--
	local src = read_src(fname)
	local ast = p.parse(src)
	local asm = c.compile(ast)
	m.run(asm, mem, stack, top)
	-- 
	return stack.top()
end

--
if #arg == 0 then
    error("No arguments provided. Run: lua eel.lua <script-here>.eel")
end

--
eel(arg[1])
