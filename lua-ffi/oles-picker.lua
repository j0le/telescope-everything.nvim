-- Tutorial https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md



local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local sorters = require "telescope.sorters"

local function display_fn(tbl)
  return tbl.value[1] .. ' display: '..tostring(display_fn == tbl.display)
end

local function get_everything_finder()
  local last_prompt = ''
  local function everything_finder_callable(_, prompt, process_result, process_complete)
    if last_prompt == promt then
      -- TODO: use cache
    end
    last_prompt = prompt
    local prompt_str = tostring(prompt)

    process_result {
      value = prompt_str,
      display = prompt_str..' moin',
      ordinal = prompt_str
    }
    process_complete()
  end

  local everything_finder = setmetatable(
    { close = function() end },
    { __call = everything_finder_callable, }
  )
  return everything_finder;
end

-- our picker function: colors
local everything_picker = function(opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "Everything Search",
    finder = get_everything_finder(),
    --sorter = conf.generic_sorter(ots),
    sorter = sorters.highlighter_only(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        print(vim.inspect(selection))
        vim.api.nvim_put({ selection.value }, "", false, true)
      end)
      return true
    end,i
  }):find()
end

-- to execute the function
everything_picker(require("telescope.themes").get_dropdown{})


-- vim:tabstop=2:expandtab:
