local dap = require("dap")
local dapui = require("dapui")

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

-- Configure adapter for Python using debugpy
dap.adapters.python = {
  type = 'executable',
  command = 'python',
  args = { '-m', 'debugpy.adapter' },
}
dap.configurations.python = {
  {
    type = 'python',
    request = 'launch',
    name = "Launch Python file",
    program = "${file}",
    pythonPath = function() return 'python' end,
  },
}

-- Configure adapter for C# using netcoredbg (assumes installation via Mason)
dap.adapters.coreclr = {
  type = 'executable',
  command = vim.fn.stdpath("data").."/mason/bin/netcoredbg",
  args = {"--interpreter=vscode"}
}
dap.configurations.cs = {
  {
    type = "coreclr",
    name = "Launch C# project",
    request = "launch",
    program = function()
      return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
    end,
  },
}

-- Configure adapter for Java using java-debug-adapter
dap.adapters.java = {
  type = 'server',
  host = '127.0.0.1',
  port = 5005,
}
dap.configurations.java = {
  {
    type = 'java',
    request = 'attach',
    name = "Attach to Java process",
    hostName = "127.0.0.1",
    port = 5005,
  },
}


dap.adapters.cppdbg = {
  id = 'cppdbg',
  type = 'executable',
  command = '/home/jacob/.local/share/nvim/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
}


dap.configurations.cpp = {
  {
    name = "Launch file",
    type = "cppdbg",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopAtEntry = true,
  },
  {
    name = 'Attach to gdbserver :1234',
    type = 'cppdbg',
    request = 'launch',
    MIMode = 'gdb',
    miDebuggerServerAddress = 'localhost:1234',
    miDebuggerPath = '/usr/bin/gdb',
    cwd = '${workspaceFolder}',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
  },
}

dap.configurations.c = dap.configurations.cpp



-- Optional key mappings for debugging
vim.api.nvim_set_keymap('n', '<F5>', "<cmd>lua require'dap'.continue()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F10>', "<cmd>lua require'dap'.step_over()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F11>', "<cmd>lua require'dap'.step_into()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F12>', "<cmd>lua require'dap'.step_out()<CR>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>db', "<cmd>lua require'dap'.toggle_breakpoint()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>dr', "<cmd>lua require'dap'.repl.open()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>du', "<cmd>lua require'dapui'.toggle()<CR>", { noremap = true, silent = true })


