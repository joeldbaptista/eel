local pt = require "pt"

local function xerror(...)
    error(string.format(...))
end

--
local bop = {
    -- Arithmetic
    ["add"] = function(a, b) return a + b end,
    ["sub"] = function(a, b) return a - b end,
    ["mul"] = function(a, b) return a * b end,
    ["div"] = function(a, b) 
        if (b == 0) then 
            xerror("Division by zero not allowed") 
        end
        return a / b 
    end,
    ["mod"] = function(a, b) return a % b end,
    ["pow"] = function(a, b) return a ^ b end,

    ["rbs"]  = function(a, b) return a >> b end,
    ["lbs"]  = function(a, b) return a << b end,
    ["band"] = function(a, b) return a & b end,
    ["bor"]  = function(a, b) return a | b end,
    ["bxor"] = function(a, b) return a ~ b end,

    -- Boolean
    ["land"] = function(a, b) return (a ~=0 and b ~=0) and 1 or 0 end,
    ["lor"]  = function(a, b) return (a ~=0 or b ~= 0) and 1 or 0 end,

    -- Comparison
    ["eq"] = function(a, b) return a == b and 1 or 0 end,
    ["ne"] = function(a, b) return a ~= b and 1 or 0 end,
    ["le"] = function(a, b) return a <= b and 1 or 0 end,
    ["ge"] = function(a, b) return a >= b and 1 or 0 end,
    ["lt"] = function(a, b) return a <  b and 1 or 0 end,
    ["gt"] = function(a, b) return a >  b and 1 or 0 end,
}

local uop = {
    ["neg"]  = function(a) return -a  end,
    ["pos"]  = function(a) return  a  end,
    ["bnot"] = function(a) return ~a  end,
    ["inc"]  = function(a) return a+1 end,
    ["dec"]  = function(a) return a-1 end,
    ["lnot"] = function(a) return a == 0 and 1 or 0 end,
}

local function binop(stack, op)
    -- TODO no need for double pop; pop one, operate & replace
    local rs = stack.pop()
    local ls = stack.pop()
    if bop[op] then
        local e = bop[op](ls, rs)
        stack.push(e)
        return
    end
    xerror("Unknown instruction `%s`", op)
end

local function unop(stack, op)
    -- TODO no need to pop & push back;
    local o = stack.pop()
    if uop[op] then
        local e = uop[op](o)
        stack.push(e)
        return
    end
    xerror("Unknown instruction `%s`", op)
end

-- Ancillary function to print arrays
local function prntarr(arr, l)
    l = l or 0
    local indent = string.rep("  ", l)
    for key, val in pairs(arr) do
        if type(val) == "table" then
            if key ~= "sizes" then
                 print(indent .. tostring(key) .. ": ")
                 prntarr(val, l + 1)
            end
        else
            print(indent .. tostring(key) .. ": " .. tostring(val))
        end
    end
end

--
local function run(code, mem, stack, top)
    local pc = 1
    local base = top
    while true do
        --print("pc = ", pc)
        --stack.print(); io.read()
        --
        if code[pc] == "ret" then
            local n = code[pc + 1] -- the number of active local variables
            local e = stack.pop()
            for _ = 1, n do
                stack.pop()
            end
            stack.push(e)
            return stack.tidx()
        elseif code[pc] == "call" then
            pc = pc + 1
            local fcode = code[pc]
            top = run(fcode, mem, stack, top)
        elseif code[pc] == "fcall" then
            local fcode = stack.pop()
            top = stack.tidx() -- update top index
            top = run(fcode, mem, stack, top)
        elseif code[pc] == "nop" then
            --------------------
            -- do nothing here
            --------------------

        -- Stack manipulation 
        elseif code[pc] == "pop" then
            pc = pc + 1
            local nop = code[pc]
            for _ = 1, nop do
                stack.pop()
            end
        elseif code[pc] == "push" then
            pc = pc + 1
            stack.push(code[pc])
        elseif code[pc] == "dup" then
            stack.push(stack.top())

        -- Data movements
        ----- memory based
        elseif code[pc] == "load" then
            pc = pc + 1
            local idx = code[pc]
            stack.push(mem[idx])
        elseif code[pc] == "store" then
            pc = pc + 1
            local idx = code[pc]
            mem[idx] = stack.pop()
        ---- stack based
        elseif code[pc] == "sstore" then
            pc = pc + 1
            local n = code[pc]
            stack.data[base + n] = stack.pop()
        elseif code[pc] == "sload" then
            pc = pc + 1
            local n = code[pc]
            stack.push(stack.data[base + n])

        -- function load
        elseif code[pc] == "fnld" then
            pc = pc + 1
            local n = code[pc]
            local o = stack.data[base + n]
            stack.push(o.code)
        -- store context
        elseif code[pc] == "scntx" then
            local code = stack.pop()
            local ncntx = stack.pop()
            local cntx = {}
            for i = 1, ncntx do
                cntx[i] = stack.pop()
            end
            -- store funval
            stack.push({ cntx=cntx, code=code })
        -- load context
        elseif code[pc] == "lcntx" then
            pc = pc + 1
            local n = code[pc]
            local o = stack.data[base + n]
            for i = 1, #o.cntx do
                stack.push(o.cntx[i])
            end

        -- Jumps
        elseif code[pc] == "jz" then
            pc = pc + 1
            local o = stack.pop()
            if o == 0 or not o then
                pc = pc + code[pc]
            end
        elseif code[pc] == "jnz" then
            pc = pc + 1
            local o = stack.pop()
            if o ~= 0 and not o then
                pc = pc + code[pc]
            end
        elseif code[pc] == "jzp" then
            pc = pc + 1
            local o = stack.top()
            if o == 0 then
                pc = pc + code[pc]
            else
                -- do nothing with it
                o = stack.pop()
            end
        elseif code[pc] == "jnzp" then
            pc = pc + 1
            local o = stack.top()
            if o ~= 0 then
                pc = pc + code[pc]
            else
                -- do nothing with it
                o = stack.pop()
            end
        elseif code[pc] == "jmp" then
            pc = pc + 1
            pc = pc + code[pc]

        -- Binary operators
        elseif code[pc] == "add" then
            binop(stack, code[pc])
        elseif code[pc] == "sub" then
            binop(stack, code[pc])
        elseif code[pc] == "mul" then
            binop(stack, code[pc])
        elseif code[pc] == "div" then
            binop(stack, code[pc])
        elseif code[pc] == "mod" then
            binop(stack, code[pc])
        elseif code[pc] == "pow" then
            binop(stack, code[pc])
        elseif code[pc] == "rbs" then
            binop(stack, code[pc])
        elseif code[pc] == "lbs" then
            binop(stack, code[pc])
        elseif code[pc] == "band" then
            binop(stack, code[pc])
        elseif code[pc] == "bor" then
            binop(stack, code[pc])
        elseif code[pc] == "land" then
            binop(stack, code[pc])
        elseif code[pc] == "lor" then
            binop(stack, code[pc])

        -- Unary operators
        elseif code[pc] == "inc" then
            unop(stack, code[pc])
        elseif code[pc] == "dec" then
            unop(stack, code[pc])
        elseif code[pc] == "lnot" then
            unop(stack, code[pc])
        elseif code[pc] == "bnot" then
            unop(stack, code[pc])
        elseif code[pc] == "neg" then
            unop(stack, code[pc])
        elseif code[pc] == "pos" then
            unop(stack, code[pc])

        -- Comparisons
        elseif code[pc] == "eq" then
            binop(stack, code[pc])
        elseif code[pc] == "ne" then
            binop(stack, code[pc])
        elseif code[pc] == "lt" then
            binop(stack, code[pc])
        elseif code[pc] == "gt" then
            binop(stack, code[pc])
        elseif code[pc] == "le" then
            binop(stack, code[pc])
        elseif code[pc] == "ge" then
            binop(stack, code[pc])

        -- Arrays and lists
        elseif code[pc] == "narr" then 
            local sizes = {}
            local ndims = stack.pop()
            for k = ndims, 1, -1 do
                sizes[k] = stack.pop()
            end
            stack.push({ sizes=sizes })
        elseif code[pc] == "garr" then
            local ndims = stack.pop()
            local dims = {}
            for k = 1, ndims do
                dims[k] = stack.pop()
            end
            local a = stack.pop()
            local sizes = a.sizes
            -- TODO refactor this; put in an external function
            -- validate
            if type(sizes) == "table" then
                if #sizes ~= ndims then
                    error(
                        string.format("Incompatible name of dims (%s) for size %s", ndims, #sizes)
                    )
                end
                for k = 1, #sizes do
                    if dims[k]+1 > sizes[k] then -- arrays are zero based
                        error (
                            string.format("Dimension %s is %s elements long; %s exceeds", k, sizes[k], dims[k])
                        )
                    end
                    if dims[k] < 0 then
                        error (
                            string.format("Dimension %s is negative; %s", k, dims[k])
                        )
                    end
                end
            end
            -- all good
            for k = 1, ndims do
                local d = dims[k]+1 -- arrays are zero based
                if k < ndims then
                    a = a[d] and a[d] or {}
                else
                    -- if requesting data from an index
                    -- that was not initialised
                    a = a[d] and a[d] or 0
                end
            end
            stack.push(a)
        elseif code[pc] == "sarr" then
            local ndims = stack.pop()
            local val = stack.pop()
            local dims = {}
            for k = 1, ndims do
                dims[k] = stack.pop()
            end
            local a = stack.pop()
            -- TODO refactor this; put in an external function
            -- validate
            local sizes = a.sizes
            if type(sizes) == "table" then
                if #sizes ~= ndims then
                    error(
                        string.format("Incompatible number of dims (%s) for size %s", ndims, #sizes)
                    )
                end
                for k = 1, #sizes do
                    if dims[k]+1 > sizes[k] then -- arrays are zero based
                        error (
                            string.format("Index in dimension %s is %s elements long; %s exceeds", k, sizes[k], dims[k])
                        )
                    end
                    if dims[k] < 0 then
                        error (
                            string.format("Index in dimension %s is negative; %s", k, dims[k])
                        )
                    end
                end
            else -- assume number
                if ndims > 1 then
                    error (
                        string.format("Incompatible number of dims (%s) for size 1", ndims)
                    )
                end
            end
            -- all good
            -- set the value in coordinates
            local r = a
            for k = 1, ndims do
                local d = dims[k]+1 -- arrays are zero based
                if k == ndims then
                    r[d] = val
                elseif not r[d] then
                    r[d] = {}
                end
                r = r[d]
            end
        elseif code[pc] == "nlst" then
            local len = stack.pop()
            local e = {}
            for k = 1, len do
                e[k] = stack.pop()
            end
            e.sizes = len > 0 and { len } or -1 -- -1 == as long as wished
            stack.push(e)
        elseif code[pc] == "gsz" then
            local e = stack.pop()
            local s = 1 -- a number/scalar
            if type(e) == "table" then
                if e.sizes == -1 then
                    s = 0
                    for _ = 1, #e do
                        s = s + 1
                    end
                else
                    for k = 1, #e.sizes do
                        s = s * e.sizes[k]
                    end
                end
            end
            stack.push(s)

        -- new hash
        -- TODO: new hashmap
        --elseif code[pc] == "nhsh" then
        ----

        -- Misc
        elseif code[pc] == "print" then
            local argc = stack.pop()
            local frmt = stack.pop()
            local args = {}
            for k = 1, argc do
                args[k] = stack.pop()
            end
            print(string.format(frmt, table.unpack(args)))
        elseif code[pc] == "atprt" then
            local e = stack.pop()
            if type(e) == "table" then
                prntarr(e)
            -- assume simple element, i.e. not array
            else
                print(e)
            end
        --
        else
            error (
                string.format("Unknow instruction `%s` (%s)", code[pc], pc)
            )
        end
        --
        pc = pc + 1
        top = stack.tidx()
    end
end

--
return {
    run=run
}
