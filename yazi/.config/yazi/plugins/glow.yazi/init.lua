local M = {}

function M:peek()
	local child = Command("glow")
		:args({
			"--width", tostring(self.area.w),
			tostring(self.file.url),
		})
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if not child then
		return
	end

	local limit = self.area.h
	local i, lines = 0, ""
	repeat
		local next, event = child:read_line()
		if event == 1 then
			break
		end
		lines = lines .. next
		i = i + 1
	until i >= limit

	child:kill()
	ya.preview_widgets(self, { ui.Text(lines):area(self.area) })
end

function M:seek(units)
	local h = cx.active.current.hovered
	if h and h.url == self.file.url then
		local step = ya.clamp(units, -1, 1)
		ya.manager_emit("peek", {
			math.max(0, cx.active.preview.skip + step),
			only_if = self.file.url,
			upper_bound = true,
		})
	end
end

return M
