--
local pt = require "pt"
return {
    stack = function(e)
        local s = { data = {e} }

        s.push = function(e)
            if e then
                s.data[#s.data + 1] = e
            end
        end

        s.pop = function()
            if #s.data > 0 then
                local e = s.data[#s.data]
                s.data[#s.data] = nil
                return e
            end
        end

        s.top = function()
            if #s.data > 0 then
                return s.data[#s.data]
            end
        end

        s.isempty = function()
            return #s.data == 0
        end

        s.tidx = function()
            return #s.data
        end

        s.print = function()
            local els = {}
            for i = 1, s.tidx() do
                if type(s.data[i]) == "table" then
                    table.insert(els, pt.pt(s.data[i]))
                else
                    table.insert(els, tostring(s.data[i]))
                end
            end

            local sstr = table.concat(els, ", ")
            print(sstr)
        end

        return s
    end
}

