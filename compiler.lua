--
local pt = require "pt"
local stk = require "stack"


local function cerror(...)
	error(string.format(...))
end

-------------------------------------------
-- Instructions
-------------------------------------------

local bops = {
	["+"] = "add",
	["-"] = "sub",
	["*"] = "mul",
	["/"] = "div",
	["**"] = "pow",
	["%"] = "mod",

    [">>"] = "rbs",
	["<<"] = "lbs",

	["&"] = "band",
	["^"] = "bxor",
	["|"] = "bor",

	["=="] = "eq",
	["!="] = "ne",
	[">"] = "gt",
	["<"] = "lt",
	[">="] = "ge",
	["<="] = "le",

	["&&"] = "land",
	["||"] = "lor",

    ["+="] = "add",
	["-="] = "sub",
	["*="] = "mul",
	["/="] = "div",
	["**="] = "pow",
	["%="] = "mod",
    [">>="] = "rbs",
	["<<="] = "lbs",
	["&="] = "band",
	["^="] = "bxor",
	["|="] = "bor",
    ["&&="] = "land",
	["||="] = "lor",
}

local uops = {
    ["-"]="neg", 
    ["+"]="pos",
	["~"] = "bnot",
	["!"] = "lnot",
    ["++"] = "inc",
	["--"] = "dec",
}

--
local compiler = { 
    funs = {},
    cntx = {}, 
    nvars = 0,
    locals = {}, 

    --
    bs = stk.stack(),  -- stack for breaks
    cs = stk.stack(),  -- stack for continue
}

function compiler:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.funs = {}
    o.cntx = {}
    o.nvars = 0
    o.locals = {}

    o.bs = stk.stack()
    o.cs = stk.stack()
   return o
end

--------------------------------------------------------------
-- Ancilary methods
--------------------------------------------------------------

-- add a op code
function compiler:addop(op)
    self.code[#self.code + 1] = op
end

-- the current position
function compiler:cpos() 
    return #self.code
end

-- "jump from there to some place a head, that will be defined later"
-- creates a jmp at current position, and adds a temp step zero 
-- to next position to be fixed later; returns the pointer of the 
-- current position
function compiler:jmpfwd(jmp)
    self:addop(jmp)
    self:addop(0)
    return self:cpos()
end

-- "jump from there (previously defined) to here"
-- fixes the jmp created by `jmpfwd` with label at address `adr`;
-- that is, replaces the tmp step with the step necessary to land 
-- in the current position; 
function compiler:jmphere(adr)
    self.code[adr] = self:cpos() - adr
end

-- "jump from here to there"
-- jumps from current position to a previous (thus, known) position
function compiler:jmpbwd(jmp, adr)
    self:addop(jmp)
    self:addop(adr - self:cpos() - 1)
end

-- From-to
function compiler:fixjmp(fadr, tadr)
    self.code[fadr] = tadr - fadr
end

--------------------------------------------------------------
-- Variable indexing
--------------------------------------------------------------

-- context
function compiler:getcntx(id)
    local idx = self.cntx[id]
    if not idx then
        idx = self.nvars + 1
        self.nvars = idx
        self.cntx[id] = { idx=idx }
    end
    return idx
end

function compiler:getlidx(id, mkv) 
    -- check if it is a local var
    local vars = self.locals
    for i = #vars, 1, -1 do
        if vars[i] == id then
            return i
        end
    end
    -- check if it's a param
    local params = self.params
    for i = 1, #params do
        if id == params[i] then
            return -(#params - i)
        end
    end
    --
    if mkv then
		-- thus local
		local idx = #vars + 1
		vars[idx] = id
		return idx
    end
end

function compiler:getidx(id, mkv)
	-- mkv = make var?
    -- test if id is local or param
    local idx = self:getlidx(id, mkv)
    if idx then
        return { idx=idx, st="sstore", ld="sload" }
    end
	cerror("Undeclared variable `%s`", id) 
end

--------------------------------------------------------------
-- Compilation methods
--------------------------------------------------------------

--------------------------------------------------------------
------ Expressions
--------------------------------------------------------------

function compiler:cfuncall(ast)
    local fun = self.funs[ast.name]
    if fun then
        if not fun then
            cerror("Undefined function `%s`", ast.name)
        end
        local args = ast.args
        local has_default = false
        if #args ~= #fun.params then
			if #args == #fun.params-1 and fun.params.default then	
				has_default = true
			else
				cerror("Wrong number of arguments for function `%s`", ast.name)
			end

        end
        for i = 1, #args do
            self:cexpr(args[i])
        end
		if has_default then
			self:cexpr(fun.params.default)
		end
        self:addop("call")
        self:addop(fun.code)
    else -- this is funval
        local id = ast.name
        local o = self:getidx(id) 
        local idx = o.idx
        local ld = o.ld
        -- load cntx vars
        self:addop("lcntx") 
        self:addop(idx)
        -- inject arguments
        local args = ast.args
        for i = 1, #args do
            self:cexpr(args[i])
        end
        --
        self:addop("fnld")
        self:addop(idx)
        self:addop("fcall")
    end
end

-- traverses the tree, and collects the variables that are 
-- utilised
function compiler:exvars(ast)
    local l = {}
    local s = stk.stack(ast)
    while  not s.isempty() do
        ast = s.pop()
        for k, v in pairs(ast) do
            if type(v) == "table" then
                if v.tag == "var" then
                    l[v.id] = l[v.id] and l[v.id]+1 or 1
                elseif v.tag == "funcall" then
                    l[v.name] = l[v.name] and l[v.name]+1 or 1
                -- fetch function parameters
                elseif k == "params" then
                    for i = 1, #v do
                        l[v[i]] = l[v[i]] and l[v[i]]+1 or 1
                    end
                else
                    s.push(v)
                end
            end
        end
    end
    -- the list with the variables used in ast
    local o = {}
    for k, _ in pairs(l) do
        o[#o+1] = k
    end
    return o
end

function compiler:cfvexpr(ast)
    -- extract the variables utilised in the funval body
    local body = ast.body
    local vars = self:exvars(body)

    -- is v in list w ?
    local isin = function(v, w) 
        for k = 1, #w do
            if w[k] == v then
                return true
            end
        end
        return false
    end

    -- combines params & locals of outter scope
    -- with funval params
    local params = {}
    local cntx = {}

    for i = 1, #self.params do
        local v = self.params[i]
        if isin(v, vars) then
            params[#params+1] = v
            cntx[#cntx+1] = v
        end
    end
    for i = 1, #self.locals do
        local v = self.locals[i]
        if isin(v, vars) then
            params[#params+1] = v
            cntx[#cntx+1] = v
        end
    end
    for i = 1, #ast.params do
        params[#params+1] = ast.params[i]
    end
    
    -- compiles funval's body
    local code = {} 
    local c = compiler:new()
    c.code = code
    c.params = params
    c:cstmt(body)
    c:addop("push")
    c:addop(0)
    c:addop("ret")
    c:addop(#c.locals + #c.params)

    -- creates the funval
    for i = #cntx, 1, -1 do
        local cidx = self:getidx(cntx[i])
        self:addop(cidx.ld) 
        self:addop(cidx.idx)
    end
    self:addop("push")
    self:addop(#cntx)
    self:addop("push")
    self:addop(code)
    self:addop("scntx")
end

function compiler:cexpr(ast)
    if ast.tag == "num" then
        self:addop("push")
        self:addop(ast.val)
        return
    end
    if ast.tag == "str" then
        self:addop("push")
        self:addop(ast.val)
        return
    end
    if ast.tag == "bool" then
        self:addop("push")
        self:addop(ast.val)
        return
    end
    if ast.tag == "var" then
        local o = self:getidx(ast.id)
        local idx = o.idx
        local ld = o.ld
        self:addop(ld)
        self:addop(idx)
        return
    end
    if ast.tag == "lval" then
        local l = ast.lst
        for k=#l, 1, -1 do
            self:cexpr(l[k])
        end
        self:addop("push")
        self:addop(#l)
        self:addop("nlst")
        return
    end
    if ast.tag == "ternary" then
        self:cexpr(ast.cnd)
        local f = self:jmpfwd("jz")
        self:cexpr(ast.ths)
        local t = self:jmpfwd("jmp")
        self:jmphere(f)
        self:cexpr(ast.els)
        self:jmphere(t)
        return
    end
    if ast.tag == "binop" then
        self:cexpr(ast.lop)
        self:cexpr(ast.rop)
        self:addop(bops[ast.op])
        return
    end
    if ast.tag == "unop" then
        self:cexpr(ast.exp)
        self:addop(uops[ast.op])
        return
    end
    if ast.tag == "pfix" then
        local id = ast.id
        local scope = ast.scope
        local o = self:getidx(id)
        local idx = o.idx
        local ld = o.ld
        local st = o.st
        if ast.pos == "pre" then 
            self:addop(ld)
            self:addop(idx)
            self:addop(uops[ast.op])
            self:addop(st)  -- stack to mem
            self:addop(idx)
            self:addop(ld)
            self:addop(idx)
        else -- ast.ord === "post"
            self:addop(ld)
            self:addop(idx)
            self:addop("dup")   -- duplicates the top
            self:addop(uops[ast.op])
            self:addop(st)  -- stack to mem
            self:addop(idx)
        end
        return
    end
    if ast.tag == "indexed" then
        local id = ast.var.id
        local sizes = ast.sizes
        local o = self:getidx(id) 
        local idx = o.idx
        local ld = o.ld
        self:addop(ld)
        self:addop(idx)
        for k = #sizes, 1, -1 do
            self:cexpr(sizes[k])
        end
        self:addop("push")
        self:addop(#sizes)
        self:addop("garr")
        return
    end
    if ast.tag == "hshval" then
        local hshval = ast.kvals
        for k = 1, #hshval do
            local e = hshval[k]
            self:cexpr(e.val)
            self:cexpr(e.key)
        end
        self:addop("push")
        self:addop(#hshval)
        self:addop("nhsh")
        return
    end
    if ast.tag == "asize" then
        local id = ast.var.id
        local o = self:getidx(id) 
        local idx = o.idx
        local ld = o.ld
        self:addop(ld)
        self:addop(idx)
        self:addop("gsz")
        return
    end
    if ast.tag == "funval" then
        self:cfvexpr(ast)  
        return
    end
    if ast.tag == "funcall" then
        self:cfuncall(ast)
        return
    end
    cerror("Unknown expression tag `%s`", ast.tag)
end


--------------------------------------------------------------
------ Statements
--------------------------------------------------------------

function compiler:chckidvar(bid, id)
	local vars = self.blkvars[bid] -- vars in scope
	if vars then
		local v = vars[id]
		if v then
			cerror("Redeclaration of variable `%s` at scope level (%s)", id, bid)
		end
		-- check variables in scope chain
		local bv = self.blkvars
		for key, val in pairs(bv) do
			local issubstr = string.find(bid, key) ~= nil
			if issubstr and bid ~= key then
				local w = val[id]
				if w then
					cerror("Redeclaration of variable `%s` at scope level (%s vs %s)", id, bid, key)
				end
			end
		end
		-- new variable
		vars[id] = 1
	else
		self.blkvars[bid] = self.blkvars[bid] and self.blkvars[bid] or {}
		self.blkvars[bid][id] = 1 -- let
	end 
end


function compiler:setconst(bid, id)
	self.blkvars[bid][id] = 2 -- const
end

function compiler:isconst(bid, id)
	return self.blkvars[bid][id] == 2
end

function compiler:cdeclr(ast)
	local bid = ast.scope
    local qual = ast.qual
    local isconst = qual=="const"
    for _, s in pairs(ast.stmts) do
        if s.var.tag == "indexed" then
            local sizes = s.var.sizes
            local id = s.var.var.id
            self:chckidvar(bid, id)
            local o = self:getidx(id, true)
            local idx = o.idx
            local st = o.st
            --
            for k = 1, #sizes do
                self:cexpr(sizes[k])
            end
            self:addop("push")
            self:addop(#sizes)
            self:addop("narr") 
            self:addop(st) 
            self:addop(idx)
            if isconst then
				self:setconst(bid, id)
            end
        else -- if s.var.tag == "var"
            local id = s.var.id
            self:chckidvar(bid, id)
            local rhs = s.rhs
            local o = self:getidx(id, true)
            local idx = o.idx
            local st = o.st
            if rhs then
                self:cexpr(rhs)
                self:addop(st) 
                self:addop(idx)
            else
                -- add default value
                self:addop("push")
                self:addop(0)       
                self:addop(st) 
                self:addop(idx)
            end
			if isconst then
				self:setconst(bid, id)
            end
        end
    end
end

function compiler:cassgn(ast)
	local scp = ast.scope
    for _, s in pairs(ast.stmts) do
        local lhs = s.lhs     
        local rhs = s.rhs     
        local op = s.op
        if s.tag == "pfix" then
            -- it does not matter if the op is pre or post
            local id = s.id
			if self:isconst(scp, id) then
				cerror("Variable `%s` is read-only", id)
            end
            local o = self:getidx(id)
            local idx = o.idx
            local ld = o.ld
            local st = o.st
            self:addop(ld) 
            self:addop(idx) 
            self:addop(uops[op]) 
            self:addop(st)
            self:addop(idx)
        elseif s.lhs.tag == "indexed" then
            local rhs = s.rhs
            local id = s.lhs.var.id
            if self:isconst(scp, id) then
				cerror("Variable `%s` is read-only", id)
            end
            local sizes = s.lhs.sizes
            local o = self:getidx(id)
            local idx = o.idx
            local ld = o.ld
            local st = o.st
            if op == "=" then
                self:addop(ld)
                self:addop(idx)
                for k = #sizes, 1, -1 do
                    self:cexpr(sizes[k])
                end
                self:cexpr(rhs)
                self:addop("push")
                self:addop(#sizes)
                self:addop("sarr")
            else -- op=
                self:addop(ld)
                self:addop(idx)
                for k = #sizes, 1, -1 do
                    self:cexpr(sizes[k])
                end
                self:cexpr(lhs)
                self:cexpr(rhs)
                self:addop(bops[op])
                self:addop("push")
                self:addop(#sizes)
                self:addop("sarr")
            end
        --[[
        elseif s.rhs and s.rhs.tag == "funval" then
            self:cfunval(s)
        ]]--
        else -- variable
            local id = s.lhs.id
			if self:isconst(scp, id) then
				cerror("Variable `%s` is read-only", id)
            end
            local lhs = s.lhs
            local rhs = s.rhs
            local o = self:getidx(id)
            local idx = o.idx
            local st = o.st
            if op == "=" then
                self:cexpr(rhs)
                self:addop(st) 
                self:addop(idx)
            else -- op=
                self:cexpr(lhs)
                self:cexpr(rhs)
                self:addop(bops[op])
                self:addop(st)
                self:addop(idx)
            end
        end
    end
end

function compiler:getnlocals()
    return #self.locals
end

function compiler:rmlocals(nlv)
    -- Remove local vars if they exist
    local d = #self.locals - nlv
    if d > 0 then
        for _ = 1, d do
            table.remove(self.locals)
        end
        self:addop("pop")
        self:addop(d)
    end
end

function compiler:cblock(ast)
	local bid = ast.scope
    local nv = self:getnlocals()
    for k = 1, #ast.stmts do
        local stmt = ast.stmts[k]
		if stmt.tag ~= "block" then
			stmt.bid = bid
		end
        self:cstmt(stmt)
    end
    self:rmlocals(nv)
end

function compiler:cstmt(ast)
    if ast.tag == "block" then
        self:cblock(ast)
        return
    end
    if ast.tag == "declaration" then
        self:cdeclr(ast)
        return
    end
    if ast.tag == "assignment" then
        self:cassgn(ast)
        return
    end
    if ast.tag == "if" then
        self:cexpr(ast.cond)
        local f = self:jmpfwd("jz")
        self:cstmt(ast.thn)
        if ast.els then
            local t = self:jmpfwd("jmp")
            self:jmphere(f)
            self:cstmt(ast.els)
            self:jmphere(t)
        else
            self:jmphere(f)
        end
        return
    end
    if ast.tag == "while" then
        local bow = self:cpos()
        self:cexpr(ast.cond)
        local f = self:jmpfwd("jz")
        self:cstmt(ast.body)
        self:jmpbwd("jmp", bow)
        self:jmphere(f)
        -- fix break jumps if present
        while not self.bs.isempty() do
            self:jmphere(self.bs.pop())
        end
        -- fix continue if present
        while not self.cs.isempty() do
            self:fixjmp(self.cs.pop(), bow)
        end
        return
    end
    if ast.tag == "for" then
        local nlv = self:getnlocals()
        if ast.strt then
        self:cstmt(ast.strt)
        end
        local bow = self:cpos()
        if ast.cond then
           self:cexpr(ast.cond)
        else
           -- infinite loop
           self:addop("push") 
           self:addop(1)
        end
        local f = self:jmpfwd("jz")
        self:cstmt(ast.body)
        local cjmp = self:cpos()
        if ast.itrt then
			self:cstmt(ast.itrt)
        end
        self:jmpbwd("jmp", bow)
        self:jmphere(f)
        -- fix breaks if present
        while not self.bs.isempty() do
           self:jmphere(self.bs.pop())
        end
        -- fix continue if present
        while not self.cs.isempty() do
           self:fixjmp(self.cs.pop(), cjmp)
        end
        self:rmlocals(nlv)
        return
    end
    if ast.tag == "switch" then
        local nlv = self:getnlocals()
        local s = stk.stack()
        self:cexpr(ast.expr) 
        for k = 1, #ast.cases do
            local case = ast.cases[k]
            if case.tag == "case" then
                self:addop("dup")
                self:cexpr(case.expr)
                self:addop("eq")
                local eoc = self:jmpfwd("jz") -- end of case
                for i = 1, #case.seq do
                    self:cstmt(case.seq[i])
                end
                local eos = self:jmpfwd("jmp") -- end of switch
                s.push(eos)
                self:jmphere(eoc)
            else
                -- default block
                for i = 1, #case.seq do
                    self:cstmt(case.seq[i])
                end
            end
        end
        -- Once a case is finish, the switch is done
        while not s.isempty() do
           self:jmphere(s.pop())
        end
        self:rmlocals(nlv)
        return
    end
    if ast.tag == "default" then
        for k,v in pairs(ast.seq) do
            self:cstmt(v)
        end
        return
    end
    if ast.tag == "case" then
        for k,v in pairs(ast.seq) do
            self:cstmt(v)
        end
        return
    end
    if ast.tag == "break" then
        local bp = self:jmpfwd("jmp")
        self.bs.push(bp)
        return
    end
    if ast.tag == "continue" then
        local cp = self:jmpfwd("jmp")
        self.cs.push(cp)
        return
    end
    if ast.tag == "funcall" then
        self:cfuncall(ast)
        self:addop("pop")
        self:addop(1)
        return
    end
    if ast.tag == "print" then
        for k = #ast.args, 1, -1 do
            self:cexpr(ast.args[k])
        end
        self:cexpr(ast.str)
        self:addop("push")
        self:addop(#ast.args)
        self:addop("print")
        return
    end
    if ast.tag == "atprint" then
		self:cexpr(ast.expr)
		self:addop("atprt")
		return
    end
    if ast.tag == "ret" then
       if ast.exp then
            self:cexpr(ast.exp)
        else
            -- if no return expression is given, return zero
            self:addop("push")
            self:addop(0)
        end
        self:addop("ret")
        self:addop(#self.locals + #self.params)
        return
    end
    cerror("Unknown statement tag `%s`", ast.tag)
end

function compiler:cfun(ast)
    local code = {} 
    local fname = self.funs[ast.name]
    if not fname then
		self.funs[ast.name] = { code=code, params=ast.params }
		self.code = code
		self.params = ast.params
		-- No shadowing for parameters
		self.blkvars = {}
		local scope = ast.body.scope
		for k = 1, #ast.params do
			local id = ast.params[k]
			self:chckidvar(scope, id)
		end
		--
		self:cstmt(ast.body)
		self:addop("push")
		self:addop(0)
		self:addop("ret")
		self:addop(#self.locals + #self.params)
		self.blkvars = nil
		return
    end
    cerror("Redeclaration of function `%s`", fname)
end

local function compile(ast)
    for i = 1, #ast do
        compiler:cfun(ast[i])
    end
    local main = compiler.funs["main"]
    if not main then
        error("No function main")
    end
    if #main.params > 0 then
		error("Main function cannot have parameter")
    end
	return main.code
end

--
return {
    compile = compile
}
