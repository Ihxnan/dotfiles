--- Open the hovered file with a user-specified program

local state = ya.sync(function()
	local h = cx.active.current.hovered
	return h and tostring(h.url) or nil
end)

local function entry(self)
	local url = state()
	if not url then
		return
	end

	local app = ya.input({
		title = "Open with:",
		value = "",
		pos = { "top-center", y = 2, w = 50, h = 3 },
		obscure = false,
		realtime = false,
	})

	if not app or #app == 0 then
		return
	end

	ya.emit("shell", { string.format('exec "%s" %s', app, ya.quote(url)), block = true })
end

return { entry = entry }
