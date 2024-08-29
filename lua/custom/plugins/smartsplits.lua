local wk = require("which-key")
return {
	"mrjones2014/smart-splits.nvim",
	{
		"iamcco/markdown-preview.nvim",
		build = "cd app && npm install",
		config = function()
			vim.g.mkdp_filetypes = {
				"markdown",
			}
			wk.add({
				{ "<C-h>", require("smart-splits").move_cursor_left(), desc = "move to left split" },
				{ "<C-j>", require("smart-splits").move_cursor_down(), desc = "move to below split" },
				{ "<C-k>", require("smart-splits").move_cursor_up(), desc = "move to above split" },
				{ "<C-l>", require("smart-splits").move_cursor_right(), dessc = "move to right split" },
				{ "<C-Up>", require("smart-splits").resize_up(), desc = "Resize split up" },
				{ "<C-Down>", require("smart-splits").resize_down(), desc = "Resize split down" },
				{ "<C-Left>", require("smart-splits").resize_left(), desc = "Resize split left" },
				{ "<C-Right>", require("smart-splits").resize_right(), desc = "Resize split right" },
			})
		end,
		ft = {
			"markdown",
		},
	},
}
