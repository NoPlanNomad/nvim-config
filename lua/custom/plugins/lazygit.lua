local wk = require("which-key")
return {
	"kdheepak/lazygit.nvim",
	-- optional for floating window border decoration
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		wk.add({
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "Open LazyGit" },
		})
	end,
}
