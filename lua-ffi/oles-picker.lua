-- Tutorial https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md



local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local function display_fn(tbl)
  return tbl.value[1] .. ' display: '..tostring(display_fn == tbl.display)
end

-- our picker function: colors
local colors = function(opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "colors",
    finder = finders.new_table {
      results = {
        { "red",   "#ff0000" },
        { "green", "#00ff00" },
        { "blue",  "#0000ff" },
      },
      entry_maker = function(entry)
        return {
          value = entry,
          display = display_fn,
          ordinal = entry[1],
        }
      end
    },
    sorter = conf.generic_sorter(ots),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        print(vim.inspect(selection))
        vim.api.nvim_put({ selection[1] }, "", false, true)
      end)
      return true
    end,i
  }):find()
end

-- to execute the function
colors(require("telescope.themes").get_dropdown{})


-- vim:tabstop=2:expandtab:
