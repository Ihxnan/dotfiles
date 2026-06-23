return {
	"MisakiForacy/musicode.nvim",
	build = "cd daemon && cargo build --release",
	config = function()
		require("musicode").setup({
			enabled = true,
			mode = "flow",
			sound = { backend = "rpc" },
			music = {
				library = "~/Music/mp3/TUYU",
				autostart = true,
				order = "shuffle",
				volume = 50,
				background_volume = 20,
			},
		})
	end,
}
