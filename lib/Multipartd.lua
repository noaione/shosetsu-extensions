-- {"ver":"1.0.0","author":"N4O"}

-- A helper to create a multipart/form-data request

local Multipartd = {}
Multipartd.__index = Multipartd

--- Generate a random boundary for multipart form data.
--- @return string
local function generateBoundary()
	-- create custom boundary
	local boundary = ""
	for _ = 1, 30 do
		-- use number
		boundary = boundary .. string.char(math.random(48, 57))
	end
	return boundary
end


--- Create a multipart/form-data request.
--- @param data table
--- @return Multipartd
function Multipartd:new()
    local multipartd = {}
    setmetatable(multipartd, Multipartd)
    multipartd.boundary = "-----------------------------" .. generateBoundary()
    multipartd.formData = ""
    return multipartd
end

--- Add a field to the form data.
--- @param name string
--- @param value string
function Multipartd:add(name, value)
    self.formData = self.formData .. self.boundary .. "\r\n"
    self.formData = self.formData .. 'Content-Disposition: form-data; name="' .. name .. '"\r\n'
    self.formData = self.formData .. "\r\n"
    self.formData = self.formData .. value .. "\r\n"
end

--- Build the form data.
--- @return string
function Multipartd:build()
    return self.formData .. self.boundary .. "--\r\n"
end

function Multipartd:reset()
    self.boundary = "-----------------------------" .. generateBoundary()
    self.formData = ""
end

function Multipartd:getHeader()
    local boundarySub = self.boundary:sub(3)
    return "multipart/form-data; boundary=" .. boundarySub
end

return Multipartd
