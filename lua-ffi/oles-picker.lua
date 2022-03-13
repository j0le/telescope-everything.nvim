-- Tutorial https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md



local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local sorters = require "telescope.sorters"
local async = require "plenary.async"
local ffi = require "ffi"

local everything_constants = {
  EVERYTHING_OK = 0, -- no error detected
  EVERYTHING_ERROR_MEMORY = 1, -- out of memory.
  EVERYTHING_ERROR_IPC = 2, -- Everything search client is not running
  EVERYTHING_ERROR_REGISTERCLASSEX = 3, -- unable to register window class.
  EVERYTHING_ERROR_CREATEWINDOW = 4, -- unable to create listening window
  EVERYTHING_ERROR_CREATETHREAD = 5, -- unable to create listening thread
  EVERYTHING_ERROR_INVALIDINDEX = 6, -- invalid index
  EVERYTHING_ERROR_INVALIDCALL = 7, -- invalid call
  EVERYTHING_ERROR_INVALIDREQUEST = 8, -- invalid request data, request data first.
  EVERYTHING_ERROR_INVALIDPARAMETER = 9, -- bad parameter.

  EVERYTHING_SORT_NAME_ASCENDING = 1,
  EVERYTHING_SORT_NAME_DESCENDING = 2,
  EVERYTHING_SORT_PATH_ASCENDING = 3,
  EVERYTHING_SORT_PATH_DESCENDING = 4,
  EVERYTHING_SORT_SIZE_ASCENDING = 5,
  EVERYTHING_SORT_SIZE_DESCENDING = 6,
  EVERYTHING_SORT_EXTENSION_ASCENDING = 7,
  EVERYTHING_SORT_EXTENSION_DESCENDING = 8,
  EVERYTHING_SORT_TYPE_NAME_ASCENDING = 9,
  EVERYTHING_SORT_TYPE_NAME_DESCENDING = 10,
  EVERYTHING_SORT_DATE_CREATED_ASCENDING = 11,
  EVERYTHING_SORT_DATE_CREATED_DESCENDING = 12,
  EVERYTHING_SORT_DATE_MODIFIED_ASCENDING = 13,
  EVERYTHING_SORT_DATE_MODIFIED_DESCENDING = 14,
  EVERYTHING_SORT_ATTRIBUTES_ASCENDING = 15,
  EVERYTHING_SORT_ATTRIBUTES_DESCENDING = 16,
  EVERYTHING_SORT_FILE_LIST_FILENAME_ASCENDING = 17,
  EVERYTHING_SORT_FILE_LIST_FILENAME_DESCENDING = 18,
  EVERYTHING_SORT_RUN_COUNT_ASCENDING = 19,
  EVERYTHING_SORT_RUN_COUNT_DESCENDING = 20,
  EVERYTHING_SORT_DATE_RECENTLY_CHANGED_ASCENDING = 21,
  EVERYTHING_SORT_DATE_RECENTLY_CHANGED_DESCENDING = 22,
  EVERYTHING_SORT_DATE_ACCESSED_ASCENDING = 23,
  EVERYTHING_SORT_DATE_ACCESSED_DESCENDING = 24,
  EVERYTHING_SORT_DATE_RUN_ASCENDING = 25,
  EVERYTHING_SORT_DATE_RUN_DESCENDING = 26,

  EVERYTHING_REQUEST_FILE_NAME = 0x00000001,
  EVERYTHING_REQUEST_PATH = 0x00000002,
  EVERYTHING_REQUEST_FULL_PATH_AND_FILE_NAME = 0x00000004,
  EVERYTHING_REQUEST_EXTENSION = 0x00000008,
  EVERYTHING_REQUEST_SIZE = 0x00000010,
  EVERYTHING_REQUEST_DATE_CREATED = 0x00000020,
  EVERYTHING_REQUEST_DATE_MODIFIED = 0x00000040,
  EVERYTHING_REQUEST_DATE_ACCESSED = 0x00000080,
  EVERYTHING_REQUEST_ATTRIBUTES = 0x00000100,
  EVERYTHING_REQUEST_FILE_LIST_FILE_NAME = 0x00000200,
  EVERYTHING_REQUEST_RUN_COUNT = 0x00000400,
  EVERYTHING_REQUEST_DATE_RUN = 0x00000800,
  EVERYTHING_REQUEST_DATE_RECENTLY_CHANGED = 0x00001000,
  EVERYTHING_REQUEST_HIGHLIGHTED_FILE_NAME = 0x00002000,
  EVERYTHING_REQUEST_HIGHLIGHTED_PATH = 0x00004000,
  EVERYTHING_REQUEST_HIGHLIGHTED_FULL_PATH_AND_FILE_NAME = 0x00008000,
}

assert(ffi.os == "Windows", "OS is not Windows")

ffi.cdef([[ unsigned int GetACP(); ]]);
local active_system_ansi_codepage = ffi.C.GetACP()

if active_system_ansi_codepage == 65001 then
  print([[the active "ANSI" codepage is UTF-8 (65001)]])
else
  error([[the active "ANSI" codepage is not UTF-8 (65001), but ]], active_system_ansi_codepage)
  return
end

ffi.cdef([[
  typedef unsigned long    DWORD;
  typedef const char *     LPCSTR;

  // write search state
  void Everything_SetSearchA(LPCSTR lpString);
  void Everything_SetRequestFlags(DWORD dwRequestFlags); // Everything 1.4.1
  void Everything_SetSort(DWORD dwSort); // Everything 1.4.1

  // execute query
  bool Everything_QueryA(bool bWait);

  // read result state
  DWORD Everything_GetNumResults(void);
  LPCSTR Everything_GetResultFileNameA(DWORD dwIndex);
  LPCSTR Everything_GetResultPathA(DWORD dwIndex);

  // read search state
  DWORD Everything_GetLastError(void);
]])

local everything_dll = ffi.load([[.\Everything64.dll]])

-- >O===-----------------------------------------------------------------------===O< --


local max_results = 1000
local await_count =  300

local function get_everything_finder()
  local last_prompt = ''
  local function everything_finder_callable(_, prompt, process_result, process_complete)
    if last_prompt == promt then
      -- TODO: use cache
    end
    last_prompt = prompt
    local prompt_str = tostring(prompt)

    if prompt_str == '' then
      process_complete()
      return
    end

    everything_dll.Everything_SetSearchA(prompt_str)
    local request_flags = everything_constants.EVERYTHING_REQUEST_FILE_NAME + everything_constants.EVERYTHING_REQUEST_PATH; -- + EVERYTHING_REQUEST_SIZE;
    everything_dll.Everything_SetRequestFlags(request_flags);
    everything_dll.Everything_SetSort(everything_constants.EVERYTHING_SORT_PATH_DESCENDING);

    -- Query:
    -- TODO: might be improved by setting to false and doing more. 
    --       See documentation 
    --       https://www.voidtools.com/support/everything/sdk/everything_query/
    local success = everything_dll.Everything_QueryA(--[[bWait]] true);
    if not success then
      local last_error = everything_dll.Everything_GetLastError()
      local error_message = 'unknown error'

      if last_error == everything_constants.EVERYTHING_ERROR_CREATETHREAD then
        error_message = 'Failed to create the search query thread.'

      elseif last_error == everything_constants.EVERYTHING_ERROR_REGISTERCLASSEX then
        error_message = 'Failed to register the search query window class.'

      elseif last_error == everything_constants.EVERYTHING_ERROR_CREATEWINDOW then
        error_message = 'Failed to create the search query window.'

      elseif last_error == everything_constants.EVERYTHING_ERROR_IPC then
        error_message = 'IPC is not available. Make sure Everything is running.'

      elseif last_error == everything_constants.EVERYTHING_ERROR_MEMORY then
        error_message = 'Failed to allocate memory for the search query.'

      elseif last_error == everything_constants.EVERYTHING_ERROR_INVALIDCALL then
        error_message = 'Invalid call to Everything_SetReplyWindow before calling Everything_Query with bWait set to FALSE.'

      else
        error_message = 'unknown error'
      end

      process_result {
        value = error_message,
        display = 'Error: '..error_message,
        ordinal = error_message
      }
      process_complete()
      return
    end

    local i = 0
    while i < everything_dll.Everything_GetNumResults() and i < max_results do
      local filename = ffi.string(everything_dll.Everything_GetResultFileNameA(i));
      local path = ffi.string(everything_dll.Everything_GetResultPathA(i));

      local combined = path .. [[\]] .. filename

      if process_result {
          value = {
            filename = filename,
            path_without_filename = path,
          },
          display = filename .. '  -==-  ' .. path,
          ordinal = combined,
          path = combined,
        }
      then
        return
      end
      if (i % await_count) == 0 then
        async.util.scheduler()
      end
      i = i+1;
    end
    process_complete()
    return
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
everything_picker()


-- vim:tabstop=2:expandtab:
