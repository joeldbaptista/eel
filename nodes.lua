--
local pt = require "pt"

-- node lookup table
local lut = {
    --
    ["block"] = function(s)
        return { tag="block", stmts=s.seq }
    end,
    ["seq"] = function(s)
        return { tag="seq", seq=s }
    end,
    ["nop"] = function(s)
        return { tag="nop" }
    end,

    -- Elements
    ["number"] = function(n)
        return { tag="num", val=tonumber(n) }
    end,
    ["string"] = function(s)
        return { tag="str", val=s }
    end,
    ["boolean"] = function(b)
        return { tag="bool", val= b=="true" and 1 or 0 }
    end,
    ["variable"] = function(v)
        return { tag="var", id=v }
    end,

    -- Expressions
    ["ternary"] = function(s)
        return { tag="ternary", cnd=s[1], ths=s[2], els=s[3] }
    end,
    ["binop"] = function(s)
        local t = s[1]
        for k = 2, #s, 2 do
            t = { tag="binop", lop=t, op=s[k], rop=s[k+1] }
        end
        return t
    end,
    ["unary"] = function(s)
        return { tag="unop", op=s[1], exp=s[2] }
    end,
    ["pfix"] = function(s)
        local o = s[1]
        local v = s[2]
        local p = "pre"
        -- got it wrong; it's post, correct it
        if v == "++" or v == "--" then
            o, v, p = v, o, "post"
        end
        return { tag="pfix", pos=p, op=o, id=v.id }
    end,

    -- Return et al
    ["return"] = function(s)
        return { tag="ret", exp=s[1] }
    end,
    ["break"] = function(s)
        return { tag="break" }
    end,
    ["continue"] = function(s)
        return { tag="continue" }
    end,
    ["print"] = function(s)
        local str = s[1]
        local args = {}
        local i = 1
        for k=2, #s do
            args[i] = s[k]
            i = i + 1
        end
        return { tag="print", str=str, args=args }
    end,
    ["atprint"] = function(s)
        return { tag="atprint", expr=s }
    end,

    -- Declarations & assignments
    ["declr"] = function(s)
        local dclr = {}
        local i = 1
        for k = 2, #s do
            dclr[i] = s[k]
            i = i + 1
        end
        return { tag="declaration", qual=s[1], stmts=dclr }
    end,
    ["delm"] = function(s)
        return { var=s[1], rhs=s[3] }
    end,
    ["assign"] = function(s)
        return { tag="assignment", stmts=s }
    end,
    ["sasgn"] = function(s)
        return { lhs=s[1], op=s[2], rhs=s[3] }
    end,

    -- Control structures
    ["if"] = function(s)
        return { tag="if", cond=s[1], thn=s[2], els=s[3] }
    end,
    ["unless"] = function(s)
        return { tag="unless", cond=s[1], thn=s[2], els=s[3] }
    end,
    ["while"] = function(s)
        return { tag="while", cond=s[1], body=s[2] }
    end,
    ["for"] = function(s)
        local strt = s[1] ~= "" and s[1] or nil
        local cond = s[2] ~= "" and s[2] or nil
        local itrt = s[3] ~= "" and s[3] or nil
        local body = s[4]
        return { tag="for", strt=strt, cond=cond, itrt=itrt, body=body }
    end,
    ["do"] = function(s)
        return { tag="do", body=s[1], cond=s[2] }
    end,
    ["default"] = function(s)
	    return { tag="default", stmts=s[1] }
    end,
    ["case"] = function(s)
	    return { tag="case", expr=s[1], stmts=s[2] }
    end,
    ["switch"] = function(s)
        local cases = {}
        local i = 1
        for k=2,#s do
            cases[i] = s[k]
            i = i + 1
        end
        return { tag="switch", expr=s[1], cases=cases }
    end,

    -- Functions
    ["fundef"] = function(s)
        return { tag="fundef", name=s[1], params=s[2], body=s[3] }
    end,
    ["funcall"] = function(s)
        return { tag="funcall", name=s[1], args=s[2] }
    end,
    ["funval"] = function(s)
        return { tag="funval", params=s[1], body=s[2] }
    end,

    -- Arrays
    ["idxelm"] = function(s)
        local v = s[1]
        local i = 1
        local sizes = {}
        for k = 2, #s do
            sizes[i] = s[k]
            i = i + 1
        end
        return { tag="indexed", var=s[1], sizes=sizes }
    end,
    ["lstval"] = function(s)
        return { tag="lval", lst=s }
    end,
    ["asize"] = function(s)
        return { tag="asize", var=s }
    end,

    -- Hashmaps / dictionaries
    ["hshval"] = function(s)
        return { tag="hshval", kvals=s } 
    end,
    ["kvpair"] = function(s)
        return { key=s[1], val=s[2] }
    end
}

--
return {
    node=function(t)
        return lut[t]
    end
}
