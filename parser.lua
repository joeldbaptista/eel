--
local pt = require "pt"
local lpeg = require "lpeg"
local nodes = require "nodes"

--
local function I(msg)
    return lpeg.P(function() print(msg); return true end)
end


local function syntax_error(input, max)
    local _, line = string.gsub(string.sub(input, 1, max), "\n", "")
    line = line + 1
    io.stderr:write("Error at line ", line, "\n")
    io.stderr:write(
        string.sub(input, max - 10, max - 1), " <|> ", string.sub(input, max, max + 11), "\n"
    )
end

--
local space = lpeg.V"space"
local T = function(p) return p * space end

local any = lpeg.P(1)
local nl = lpeg.P"\n"
local blank = lpeg.S" \n\t"
local soc = lpeg.P"/*"
local eoc = lpeg.P"*/"
local not_nl = any - nl
local not_eoc = any - eoc
local slcomment = "//" * not_nl^0
local mlcomment = soc * not_eoc^0 * eoc

local dquote = lpeg.P('"')
local escseq = lpeg.P("\\") * any
local nescchar = any - lpeg.S('"\\')
local sign = T(lpeg.S"-+"^-1)
local digits = T(lpeg.R"09"^1)
local dot = T(".")
local E = T(lpeg.S"eE")
local hexhead = lpeg.S("0x", "0X")
local hexdigits = lpeg.R"09" + lpeg.R"az" + lpeg.R"AZ"
local alpha = lpeg.R"az" + lpeg.R"AZ" + lpeg.P"_"
local alphnum = alpha + lpeg.R"09"

local integer = sign * digits
local float = sign * (digits^-1 * dot * digits +  digits * dot * digits^-1)
local float_enotation = (float + integer) * E * integer
local hexdecimal = sign * T(hexhead * hexdigits)

local TC = function(p) return T(lpeg.C(p)) end

local num = TC(float_enotation + float + hexdecimal + integer)
local str = dquote * TC((nescchar + escseq)^0) * dquote

-- Reserved words
local reserved = {
    "if", "else", "unless", "while", "do", "for", "return", "function", 
    "let", "const", "break", "continue", "true", "false", "switch",
    "case", "default", "print"
}
local excluded = lpeg.P(false)
for i = 1, #reserved do
    excluded = excluded + reserved[i]
end
excluded = excluded * -alphnum

local Rw = function(t, c) 
    assert(excluded:match(t))
    if c then
        return lpeg.C(t) * -alphnum * space
    end
    return t * -alphnum * space
end

-- Operators
local luop = TC(lpeg.P"!")
local lbop = TC(lpeg.P"&&" + "||")
local cop  = TC(lpeg.P"==" + "!=" + "<=" + ">=" + "<" + ">")
local auop = TC(lpeg.P"-" + "+" + "~")
local abop = TC(lpeg.P"|" + "^" + "+" + "-" + "<<" + ">>")
local mbop = TC(lpeg.P"&" + "*" + "/" + "%")
local pbop = TC(lpeg.P"**")
local pfop = TC(lpeg.P"++" + "--")
local asgn_eq = TC(lpeg.P"=")
local asgn_op = asgn_eq + TC(lpeg.P"+=" + "-=" + "*=" + "/=" 
              + "%=" + "**=" + "&=" + "|=" + "^=" + ">>=" + "<<=" + "||=" + "&&=")

-- Grammar
local program = lpeg.V"program"
local stmts = lpeg.V"stmts"
local stmt = lpeg.V"stmt"
local block = lpeg.V"block"

local empty = lpeg.V"empty"
local retstmt = lpeg.V"retstmt"
local retval = lpeg.V"retval"
local brkstmt = lpeg.V"brkstmt"
local cntstmt = lpeg.V"cntstmt"
local prtstmt = lpeg.V"prtstmt"
local atprtstmt = lpeg.V"atprtstmt" -- simple print; using @
local prtval = lpeg.V"prtval"

local declr = lpeg.V"declr"
local delm = lpeg.V"delm"

local assgn = lpeg.V"assgn"
local aselm = lpeg.V"aselm"   -- assign element; simple or pfexp
local sasgn = lpeg.V"sasgn"   -- simple assignment; var op= expr

local fundef = lpeg.V"fundef"
local funval = lpeg.V"funval"
local params = lpeg.V"params"
local fvparams = lpeg.V"fvparams"
local funcall = lpeg.V"funcall"
local args = lpeg.V"args"

local ifstmt = lpeg.V"ifstmt"
local unlessstmt = lpeg.V"unlessstmt"
local whlstmt = lpeg.V"whlstmt"
local dostmt = lpeg.V"dostmt"
local forstmt = lpeg.V"forstmt"
local strt = lpeg.V"strt"
local itrt = lpeg.V"itrt"
local swtstmt = lpeg.V"swtstmt"
local casestmt = lpeg.V"casestmt"
local deflstmt = lpeg.V"deflstmt"

local lhs = lpeg.V"lhs"
local rhs = lpeg.V"rhs"

local expr = lpeg.V"expr"  -- general expression
local bexp = lpeg.V"bexp"  -- binary (numeric) expression
local lexp = lpeg.V"lexp"  -- logical expression
local cexp = lpeg.V"cexp"  -- comparison expression
local aexp = lpeg.V"aexp"  -- additive expression
local mexp = lpeg.V"mexp"  -- multiplicative expression
local pexp = lpeg.V"pexp"  -- power expression, for **
local texp = lpeg.V"texp"  -- ternary expression
local pfex = lpeg.V"pfex"  -- prefix/postfix expression

local ID = lpeg.V"ID"
local var = lpeg.V"var"
local idxelm = lpeg.V"idxelm"
local lstval = lpeg.V"lstval"
-- TODO
--local hshval = lpeg.V"hshval"
--local kvpair = lpeg.V"kvpair"
local lelms = lpeg.V"lelms"
local asize = lpeg.V"asize"
local idxparams = lpeg.V"idxparams"
local number = lpeg.V"number"
local string = lpeg.V"string"
local bool = lpeg.V"bool"


local maxmatch = 0
local node = nodes.node

local grammar = lpeg.P {
    "program",

    --
    program = space * lpeg.Ct(fundef^1) * -1,

    -- Statements
    stmt = empty
         + declr * T";"
         + assgn * T";"
         + funcall * T";"
         + fundef
         + retstmt
         + brkstmt
         + cntstmt
         + ifstmt
         + unlessstmt
         + whlstmt
         + dostmt
         + forstmt
         + swtstmt
         + prtstmt
         + atprtstmt
         + block
         ,

    stmts = lpeg.Ct(stmt^0) / node("seq"),
    block = T"{" * stmts * T"}" / node("block"),
    empty = (space * T";" + T"{" * space * T"}") / node("nop"),

    -- Flow breaking & print
    retstmt = Rw"return" * lpeg.Ct(retval^-1) * T";"/ node("return"),
    retval = funval + asize + expr,
    brkstmt = Rw"break" * T";" / node("break"),
    cntstmt = Rw"continue" * T";"/ node("continue"),
    prtstmt = lpeg.Ct(Rw"print" * T"(" * string * (T"," * prtval)^0) * T")" * T";" / node("print"),
    atprtstmt = T"@" * expr * T";" / node("atprint"),
    prtval = expr + bool + string,

    -- Declarations & assignments
    declr = lpeg.Ct((Rw("let", 1) + Rw("const", 1)) * (delm * (T"," * delm)^0)) / node("declr"),
    delm = lpeg.Ct(idxelm + var * (asgn_eq * rhs)^-1) / node("delm"),

    assgn = lpeg.Ct(aselm * (T"," * aselm)^0) / node("assign"),
    aselm = sasgn + pfex,
    sasgn = lpeg.Ct(lhs * asgn_op * rhs) / node("sasgn"),

    lhs = idxelm + var,
    rhs = lstval + asize + funval + string + bool + expr,

    -- Functions
    --fundef = lpeg.Ct(Rw"function" * ID * T"(" * params * T")" * block) / node("fundef"),
    fundef = lpeg.Ct(ID * T"(" * params * T")" * block) / node("fundef"),
    params = lpeg.Ct(ID * (T"," * ID)^0) * (T"=" * expr)^-1 / function (s, d) s.default = d; return s end
           + lpeg.Cc({}), 
   
    funval = lpeg.Ct(T"(" * fvparams * T")" * block) / node("funval"),
    fvparams = lpeg.Ct(ID * (T"," * ID)^0) + lpeg.Cc({}),

    funcall = lpeg.Ct(ID * T"(" * args * T")") / node("funcall"),
    args = lpeg.Ct((expr * (T"," * expr)^0)^-1),

    -- Control structures
    ifstmt = lpeg.Ct(Rw"if" * T"(" * expr * T")" * stmt * (Rw"else" * stmt)^-1) / node("if"),
    unlessstmt = lpeg.Ct(Rw"unless" * T"(" * expr * T")" * stmt * (Rw"else" * stmt)^-1) / node("unless"),
    
    whlstmt = lpeg.Ct(Rw"while" * T"(" * expr * T")" * stmt) / node("while"),
    dostmt = lpeg.Ct(Rw"do" * stmt * Rw"while" * T"(" * expr * T")") * T";" / node("do"),

    forstmt = lpeg.Ct(
        Rw"for" * T"(" * (strt + lpeg.Cc(""))* T";" * 
            (expr + lpeg.Cc("")) * T";" * (itrt + lpeg.Cc("")) * T")" * stmt
    ) / node("for"),
    strt = declr + assgn,
    itrt = assgn,

    swtstmt = lpeg.Ct(Rw"switch" * T"(" * expr * T")" * T"{" * (casestmt + deflstmt)^1 * T"}") / node("switch"),
    casestmt = lpeg.Ct(Rw"case" * expr * T":" * lpeg.Ct(stmt^0)) / node("case"),
    deflstmt = lpeg.Ct(Rw"default" * T":" * lpeg.Ct(stmt^0)) / node("default"),

    -- Arrays & lists
    idxelm = lpeg.Ct(var * T"[" * idxparams * T"]") / node("idxelm"),
    lstval = lpeg.Ct(T"[" * lelms * T"]") / node("lstval"),
    idxparams = (expr * (T"," * expr)^0),
	lelms = ((expr + lstval + string) * (T"," * (expr + lstval + string))^0)^-1,
	asize = T"#" * var / node("asize"),

	-- TODO Maps
	--[[
	hshval = lpeg.Ct(T"{" * kvpair * (T"," * kvpair)^0 * T"}") / node("hshval"),
	kvpair = lpeg.Ct(string * T":" * rhs) / node("kvpair"),
	]]--

    -- Expressions
    expr = texp + bexp,

	texp = lpeg.Ct(bexp * T"?" * bexp * T":" * bexp) / node("ternary"),
	bexp = lpeg.Ct(lexp * (lbop * lexp)^0) / node("binop") 
	     + lpeg.Ct(luop * lexp) / node("unary") + bool,
	lexp = lpeg.Ct(cexp * (cop * cexp)^-1) / node("binop"),
	cexp = lpeg.Ct(aexp * (abop * aexp)^0) / node("binop"),
	aexp = lpeg.Ct(mexp * (mbop * mexp)^0) / node("binop") 
	     + lpeg.Ct(auop * aexp) / node("unary"),
	mexp = lpeg.Ct(pexp * (pbop * pexp)^0) / node("binop"),

    pexp = asize + bool + number + pfex + idxelm + funcall + var + T"(" * expr * T")",
    pfex = lpeg.Ct(pfop * var + var * pfop) / node("pfix"),

    -- Misc
    bool = lpeg.C(Rw"true" + Rw"false") / node("boolean"),
    string = str / node("string"),
    number = num / node("number"),
    var = ID / node("variable"),

    ID = (lpeg.C(alpha * alphnum^0) - excluded) * space,
    space = (blank + slcomment + mlcomment)^0 * lpeg.P (
        function(_, p)
            maxmatch = math.max(maxmatch, p)
            return true
        end
    )
}

--
local sibs = {}
local function setup_scopes(tbl, p, force_in)
	local np = nil
	local is_block_structure = tbl.tag == "block" 
							or tbl.tag == "case" 
							or tbl.tag == "default" 
							or force_in
	if is_block_structure then
		sibs[p] = (sibs[p] or 0) + 1
		local ns = sibs[p]
		np = p == "" and tostring(sibs[p]) or p.."."..sibs[p]
		tbl.scope = np
		-- iterate over its elements and recursively setup scopes
		for k,v in pairs(tbl.stmts) do
			v.scope = np 
			setup_scopes(v, np)	
		end
		return
	else
		tbl.scope = p
	end
	if tbl.tag == "fundef" then
	    setup_scopes(tbl.body, p)
	    return
	end
    if tbl.tag == "funval" then
		setup_scopes(tbl.body, p)
		return
	end
	if tbl.tag == "declaration" then
	    for _, s in pairs(tbl.stmts) do
            setup_scopes(s, p)
            if s.rhs then
                setup_scopes(s.rhs, p)
            end
        end
	end
	if tbl.tag == "if" then
		setup_scopes(tbl.thn, p)	
		if tbl.els then
			setup_scopes(tbl.els, p)
		end
		return
	end
    if tbl.tag == "unless" then
		setup_scopes(tbl.thn, p)	
		if tbl.els then
			setup_scopes(tbl.els, p)
		end
		return
	end
	if tbl.tag == "for" then
		setup_scopes(tbl.body, p)
		if tbl.strt then
		    setup_scopes(tbl.strt, tbl.body.scope)	
		end
		if tbl.itrt then
		    setup_scopes(tbl.itrt, tbl.body.scope)	
		end
		return
	end
	if tbl.tag == "while" then
		setup_scopes(tbl.body, p)	
		return
	end
	if tbl.tag == "do" then
		setup_scopes(tbl.body, p)	
		return
	end
	if tbl.tag == "switch" then
		if tbl.cases then
			for k,v in pairs(tbl.cases) do
				setup_scopes(v, p)
			end
		end
		return
	end
	if tbl.tag == "return" then
		if tbl.exp then
			setup_scopes(tbl.exp, p)
		end
		return
	end
end

--
return {
    parse = function(input)
        local ast = grammar:match(input) 
        if ast then
            for k = 1, #ast do
                local fn = ast[k]
                setup_scopes(fn, "")
            end
            return ast
        end
        syntax_error(input, maxmatch)
    end
}
