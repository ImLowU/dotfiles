local colors = require("colors.custom.enma-grey")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
	general = {
		gaps_in = 3,
		gaps_out = 12,

		border_size = 3,

		col = {
			active_border = colors.primary,
			inactive_border = colors.on_secondary,
		},

		-- Set to true to enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = true,

		-- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
		allow_tearing = false,

		layout = "dwindle",
	},
	decoration = {
		rounding = 10,
		rounding_power = 2,

		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = 0.73,

		shadow = {
			enabled = false,
			range = 12,
			render_power = 2,
			color = colors.background,
		},

		blur = {
			enabled = false,
			size = 1,
			passes = 1,
			vibrancy = 0.1696,
			special = true,
		},
	},

	animations = {
		enabled = true,
	},
})
