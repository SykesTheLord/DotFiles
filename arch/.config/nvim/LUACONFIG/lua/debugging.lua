-- lua/debug_setup.lua
local M = {}
local dap = require("dap")
local dapui = require("dapui")

--------------------------------------------------------------------------------
-- Global Debug Setup (Load once)
--------------------------------------------------------------------------------
function M.setup_global()
	-- Setup DAP UI (with default settings)
	dapui.setup()

	-- Automatically open DAP UI when debugging starts, and close it when finished.
	dap.listeners.after.event_initialized["dapui_config"] = function()
		dapui.open()
	end
	dap.listeners.before.event_terminated["dapui_config"] = function()
		dapui.close()
	end
	dap.listeners.before.event_exited["dapui_config"] = function()
		dapui.close()
	end

	-- Set up debugging key mappings
	M.setup_keymaps()

	-- Setup persistent breakpoints
	M.setup_persistent_breakpoints()
end

--------------------------------------------------------------------------------
-- Key Mappings for Debugging
--------------------------------------------------------------------------------
function M.setup_keymaps()
	local opts = { noremap = true, silent = true }
	vim.api.nvim_set_keymap("n", "<F5>", "<cmd>lua require'dap'.continue()<CR>", opts)
	vim.api.nvim_set_keymap("n", "<F10>", "<cmd>lua require'dap'.step_over()<CR>", opts)
	vim.api.nvim_set_keymap("n", "<F11>", "<cmd>lua require'dap'.step_into()<CR>", opts)
	vim.api.nvim_set_keymap("n", "<F12>", "<cmd>lua require'dap'.step_out()<CR>", opts)
	vim.api.nvim_set_keymap("n", "<leader>dr", "<cmd>lua require'dap'.repl.open()<CR>", opts)
	vim.api.nvim_set_keymap("n", "<leader>du", "<cmd>lua require'dapui'.toggle()<CR>", opts)
end

--------------------------------------------------------------------------------
-- Persistent Breakpoints Setup
--------------------------------------------------------------------------------
function M.setup_persistent_breakpoints()
	require("persistent-breakpoints").setup({
		load_breakpoints_event = { "BufReadPost" },
	})
	local opts = { noremap = true, silent = true }
	vim.api.nvim_set_keymap(
		"n",
		"<leader>db",
		"<cmd>lua require('persistent-breakpoints.api').toggle_breakpoint()<CR>",
		opts
	)
	vim.api.nvim_set_keymap(
		"n",
		"<leader>dc",
		"<cmd>lua require('persistent-breakpoints.api').set_conditional_breakpoint()<CR>",
		opts
	)
	vim.api.nvim_set_keymap(
		"n",
		"<leader>bc",
		"<cmd>lua require('persistent-breakpoints.api').clear_all_breakpoints()<CR>",
		opts
	)
	vim.api.nvim_set_keymap(
		"n",
		"<leader>lp",
		"<cmd>lua require('persistent-breakpoints.api').set_log_point()<CR>",
		opts
	)
end

--------------------------------------------------------------------------------
-- Language-Specific Debug Configurations
--------------------------------------------------------------------------------
-- Python Debugging (using debugpy)
function M.setup_python()
	dap.adapters.python = {
		type = "executable",
		command = "python",
		args = { "-m", "debugpy.adapter" },
	}
	dap.configurations.python = {
		{
			type = "python",
			request = "launch",
			name = "Launch Python file",
			program = "${file}",
			pythonPath = function()
				return "python"
			end,
		},
	}
end

-- C# Debugging (using netcoredbg)
function M.setup_cs()
	dap.adapters.coreclr = {
		type = "executable",
		command = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg",
		args = { "--interpreter=vscode" },
	}
	dap.configurations.cs = {
		{
			type = "coreclr",
			name = "Launch C# project",
			request = "launch",
			program = function()
				return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
			end,
		},
	}
end

-- Java Debugging (using java-debug-adapter)
function M.setup_java()
	dap.adapters.java = {
		type = "server",
		host = "127.0.0.1",
		port = 5005,
	}
	dap.configurations.java = {
		{
			type = "java",
			request = "attach",
			name = "Attach to Java process",
			hostName = "127.0.0.1",
			port = 5005,
		},
	}
end

-- C/C++ Debugging (using cpptools)
function M.setup_cpp()
	dap.adapters.cppdbg = {
		id = "cppdbg",
		type = "executable",
		command = "/home/jacob/.local/share/nvim/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
	}
	dap.configurations.cpp = {
		{
			name = "Launch file",
			type = "cppdbg",
			request = "launch",
			program = function()
				return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
			end,
			cwd = "${workspaceFolder}",
			stopAtEntry = true,
		},
		{
			name = "Attach to gdbserver :1234",
			type = "cppdbg",
			request = "launch",
			MIMode = "gdb",
			miDebuggerServerAddress = "localhost:1234",
			miDebuggerPath = "/usr/bin/gdb",
			cwd = "${workspaceFolder}",
			program = function()
				return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
			end,
		},
	}
	dap.configurations.c = dap.configurations.cpp
end

--------------------------------------------------------------------------------
-- Return the Module
--------------------------------------------------------------------------------
return M
