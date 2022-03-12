-- main.lua


local EVERYTHING_OK = 0 -- no error detected
local EVERYTHING_ERROR_MEMORY = 1 -- out of memory.
local EVERYTHING_ERROR_IPC = 2 -- Everything search client is not running
local EVERYTHING_ERROR_REGISTERCLASSEX = 3 -- unable to register window class.
local EVERYTHING_ERROR_CREATEWINDOW = 4 -- unable to create listening window
local EVERYTHING_ERROR_CREATETHREAD = 5 -- unable to create listening thread
local EVERYTHING_ERROR_INVALIDINDEX = 6 -- invalid index
local EVERYTHING_ERROR_INVALIDCALL = 7 -- invalid call
local EVERYTHING_ERROR_INVALIDREQUEST = 8 -- invalid request data, request data first.
local EVERYTHING_ERROR_INVALIDPARAMETER = 9 -- bad parameter.

local EVERYTHING_SORT_NAME_ASCENDING = 1
local EVERYTHING_SORT_NAME_DESCENDING = 2
local EVERYTHING_SORT_PATH_ASCENDING = 3
local EVERYTHING_SORT_PATH_DESCENDING = 4
local EVERYTHING_SORT_SIZE_ASCENDING = 5
local EVERYTHING_SORT_SIZE_DESCENDING = 6
local EVERYTHING_SORT_EXTENSION_ASCENDING = 7
local EVERYTHING_SORT_EXTENSION_DESCENDING = 8
local EVERYTHING_SORT_TYPE_NAME_ASCENDING = 9
local EVERYTHING_SORT_TYPE_NAME_DESCENDING = 10
local EVERYTHING_SORT_DATE_CREATED_ASCENDING = 11
local EVERYTHING_SORT_DATE_CREATED_DESCENDING = 12
local EVERYTHING_SORT_DATE_MODIFIED_ASCENDING = 13
local EVERYTHING_SORT_DATE_MODIFIED_DESCENDING = 14
local EVERYTHING_SORT_ATTRIBUTES_ASCENDING = 15
local EVERYTHING_SORT_ATTRIBUTES_DESCENDING = 16
local EVERYTHING_SORT_FILE_LIST_FILENAME_ASCENDING = 17
local EVERYTHING_SORT_FILE_LIST_FILENAME_DESCENDING = 18
local EVERYTHING_SORT_RUN_COUNT_ASCENDING = 19
local EVERYTHING_SORT_RUN_COUNT_DESCENDING = 20
local EVERYTHING_SORT_DATE_RECENTLY_CHANGED_ASCENDING = 21
local EVERYTHING_SORT_DATE_RECENTLY_CHANGED_DESCENDING = 22
local EVERYTHING_SORT_DATE_ACCESSED_ASCENDING = 23
local EVERYTHING_SORT_DATE_ACCESSED_DESCENDING = 24
local EVERYTHING_SORT_DATE_RUN_ASCENDING = 25
local EVERYTHING_SORT_DATE_RUN_DESCENDING = 26

local EVERYTHING_REQUEST_FILE_NAME = 0x00000001
local EVERYTHING_REQUEST_PATH = 0x00000002
local EVERYTHING_REQUEST_FULL_PATH_AND_FILE_NAME = 0x00000004
local EVERYTHING_REQUEST_EXTENSION = 0x00000008
local EVERYTHING_REQUEST_SIZE = 0x00000010
local EVERYTHING_REQUEST_DATE_CREATED = 0x00000020
local EVERYTHING_REQUEST_DATE_MODIFIED = 0x00000040
local EVERYTHING_REQUEST_DATE_ACCESSED = 0x00000080
local EVERYTHING_REQUEST_ATTRIBUTES = 0x00000100
local EVERYTHING_REQUEST_FILE_LIST_FILE_NAME = 0x00000200
local EVERYTHING_REQUEST_RUN_COUNT = 0x00000400
local EVERYTHING_REQUEST_DATE_RUN = 0x00000800
local EVERYTHING_REQUEST_DATE_RECENTLY_CHANGED = 0x00001000
local EVERYTHING_REQUEST_HIGHLIGHTED_FILE_NAME = 0x00002000
local EVERYTHING_REQUEST_HIGHLIGHTED_PATH = 0x00004000
local EVERYTHING_REQUEST_HIGHLIGHTED_FULL_PATH_AND_FILE_NAME = 0x00008000

local ffi = require('ffi')
if ffi.os == "Windows" then

	ffi.cdef([[
		typedef unsigned long    DWORD;
		typedef const char *     LPCSTR;
		typedef _Bool            BOOL;

		// write search state
		void Everything_SetSearchA(LPCSTR lpString);
		void Everything_SetRequestFlags(DWORD dwRequestFlags); // Everything 1.4.1
		void Everything_SetSort(DWORD dwSort); // Everything 1.4.1

		// execute query
		BOOL Everything_QueryA(BOOL bWait);

		// read result state
		DWORD Everything_GetNumResults(void);
		LPCSTR Everything_GetResultFileNameA(DWORD dwIndex);
		LPCSTR Everything_GetResultPathA(DWORD dwIndex);
	]])

	local everything_dll = ffi.load([[.\Everything64.dll]])

	everything_dll.Everything_SetSearchA('h\195\188ser') -- hüser
	local request_flags = EVERYTHING_REQUEST_FILE_NAME + EVERYTHING_REQUEST_PATH; -- + EVERYTHING_REQUEST_SIZE;
	print('request flags ', request_flags);
	everything_dll.Everything_SetRequestFlags(request_flags);
	everything_dll.Everything_SetSort(EVERYTHING_SORT_PATH_DESCENDING);

	print("execute query")
	everything_dll.Everything_QueryA(true);

	print("print results")
	do
		local i = 0
		local max_num_displayed = 10
		while i < everything_dll.Everything_GetNumResults() and i < max_num_displayed do
			local filename = ffi.string(everything_dll.Everything_GetResultFileNameA(i));
			local path = ffi.string(everything_dll.Everything_GetResultPathA(i));
			print(filename .. '  -==-  ' .. path);
			i = i+1;
		end
	end
end
-- lua local ffi = require'ffi'; ffi.cdef([[ unsigned int GetACP(); ]]); print(ffi.C.GetACP())
