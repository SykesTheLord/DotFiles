local M = {}

function M.setup()
	-- Clipboard integration for WSL/Wayland/X11
	if vim.fn.has("wsl") == 1 then
		-- WSL: Use win32yank.exe to access Windows clipboard
		vim.g.clipboard = {
			name = "win32yank-wsl",
			copy = {
				["+"] = "win32yank.exe -i --crlf",
				["*"] = "win32yank.exe -i --crlf",
			},
			paste = {
				["+"] = "win32yank.exe -o --lf",
				["*"] = "win32yank.exe -o --lf",
			},
			cache_enabled = 0,
		}
	elseif vim.env.XDG_SESSION_TYPE == "wayland" or vim.env.WAYLAND_DISPLAY then
		-- Wayland: use wl-copy/wl-paste
		vim.g.clipboard = {
			name = "wayland",
			copy = {
				["+"] = "wl-copy",
				["*"] = "wl-copy",
			},
			paste = {
				["+"] = "wl-paste",
				["*"] = "wl-paste",
			},
			cache_enabled = 0,
		}
	else
		-- X11: use xclip as fallback
		vim.g.clipboard = {
			name = "x11",
			copy = {
				["+"] = "xclip -selection clipboard",
				["*"] = "xclip -selection primary",
			},
			paste = {
				["+"] = "xclip -selection clipboard -o",
				["*"] = "xclip -selection primary -o",
			},
			cache_enabled = 0,
		}
	end

	-- Gitsigns setup (show git diff in sign column)
	require("gitsigns").setup({
		signs = {
			add = { text = "┃" },
			change = { text = "┃" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
			untracked = { text = "┆" },
		},
		signs_staged = {
			add = { text = "┃" },
			change = { text = "┃" },
		},
	})

	-- Telescope setup (with binary file preview filtering)
	local previewers = require("telescope.previewers")
	local Job = require("plenary.job")
	local new_maker = function(filepath, bufnr, opts)
		filepath = vim.fn.expand(filepath)
		Job:new({
			command = "file",
			args = { "--mime-type", "-b", filepath },
			on_exit = function(j)
				local mime_type = vim.split(j:result()[1], "/")[1]
				if mime_type == "text" then
					previewers.buffer_previewer_maker(filepath, bufnr, opts)
				else
					vim.schedule(function()
						vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "BINARY" })
					end)
				end
			end,
		}):sync()
	end

	require("telescope").setup({
		defaults = {
			buffer_previewer_maker = new_maker,
			preview = {
				-- Display images with `catimg` if the file is an image
				mime_hook = function(filepath, bufnr, opts)
					local function is_image(path)
						local ext = string.match(path:lower(), "%.([^%.]+)$")
						local image_exts = { png = true, jpg = true, jpeg = true }
						return ext and image_exts[ext]
					end
					if is_image(filepath) then
						local term = vim.api.nvim_open_term(bufnr, {})
						vim.fn.jobstart({ "catimg", filepath }, {
							on_stdout = function(_, data)
								for _, d in ipairs(data) do
									vim.api.nvim_chan_send(term, d .. "\r\n")
								end
							end,
							stdout_buffered = true,
							pty = true,
						})
					else
						previewers.buffer_previewer_maker(filepath, bufnr, opts)
					end
				end,
			},
		},
	})
	require("telescope").load_extension("csharpls_definition")
	-- Rainbow Delimiters (colored brackets) configuration
	local rainbow_delimiters = require("rainbow-delimiters")
	vim.g.rainbow_delimiters = {
		strategy = {
			[""] = rainbow_delimiters.strategy["global"],
			vim = rainbow_delimiters.strategy["local"],
		},
		query = {
			[""] = "rainbow-delimiters",
			lua = "rainbow-blocks",
		},
		highlight = {
			"RainbowDelimiterRed",
			"RainbowDelimiterYellow",
			"RainbowDelimiterBlue",
			"RainbowDelimiterOrange",
			"RainbowDelimiterGreen",
			"RainbowDelimiterViolet",
			"RainbowDelimiterCyan",
		},
	}

	-- NERDTree settings.
	vim.g.NERDTreeShowHidden = 1 -- Show hidden files.
	vim.g.NERDTreeIgnore = { "^node_modules$" } -- Ignore node_modules folders.
	vim.g.NERDTreeFileLines = 1 -- Show number of lines in file.

	-- Setup Vim-Devicons.
	-- Define custom extension symbols.
	vim.g.WebDevIconsUnicodeDecorateFileNodesExtensionSymbols = {
		cs = "",
		tf = "",
	}

	-- Define exact filename symbols.
	vim.g.WebDevIconsUnicodeDecorateFileNodesExactSymbols = {
		[".envrc"] = "󰒓",
		["azure-pipelines.yaml"] = "",
		["azure-pipelines.yml"] = "",
	}
end

return M
