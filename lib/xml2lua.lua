-- {"ver":"1.0.0","author":"manoelcampos and N4O"}

-- A quick wrapper for manoelcampos xml2lua
-- https://github.com/manoelcampos/xml2lua

local parser = Require("XMLLua/xml2lua")
local handler = Require("XMLLua/Handler/Tree")

--- Parse XML string to Lua table
--- @param xmlString string XML string
--- @param returnRoot boolean indicates if we should include the root element. (default to false, optional)
--- @param parseAttributes boolean indicates if tag attributes should be parsed or not. (default to true, optional)
return function(xmlString, returnRoot, parseAttributes)
    if returnRoot == nil then returnRoot = false end
    if parseAttributes == nil then parseAttributes = true end
    local parser = parser.parser(handler)
    parser:parse(xmlString, parseAttributes)

    return returnRoot and handler or handler.root
end
