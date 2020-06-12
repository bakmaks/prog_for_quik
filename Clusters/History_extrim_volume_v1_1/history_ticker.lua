package.cpath=".\\?.dll;.\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\?.dll;C:\\Program Files (x86)\\Lua\\5.1\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\?.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\loadall.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\loadall.dll;C:\\Program Files\\Lua\\5.1\\?.dll;C:\\Program Files\\Lua\\5.1\\?51.dll;C:\\Program Files\\Lua\\5.1\\clibs\\?.dll;C:\\Program Files\\Lua\\5.1\\clibs\\?51.dll;C:\\Program Files\\Lua\\5.1\\loadall.dll;C:\\Program Files\\Lua\\5.1\\clibs\\loadall.dll"..package.cpath
package.path=package.path..";.\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.luac;C:\\Program Files\\Lua\\5.1\\lua\\?.lua;C:\\Program Files\\Lua\\5.1\\lua\\?\\init.lua;C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\?\\init.lua;C:\\Program Files\\Lua\\5.1\\lua\\?.luac;"

package.path=package.path..getScriptPath()..'\\?.lua;'

require('LuaXml')

function getTickerPattern(ticker)
	local code = string.sub(ticker, 1, 2)
	local store = {}
	local tickers_table = xml.load(getScriptPath()..'\\'.."history_config.xml")
	local ticker_pattern = tickers_table:find(code)


	store['SecCode'] = code..tickers_table:find('ticker_suffix').value
	store['ClassCode'] = ticker_pattern.class
	store['PATH_FILE'] = tickers_table:find('file_path').value

	for key, value in ipairs(ticker_pattern) do
		if ticker_pattern[key]:tag() ~= 'graph_id' then
			store[ticker_pattern[key]:tag()] = tonumber(ticker_pattern[key].value)
		else
			store[ticker_pattern[key]:tag()] = ticker_pattern[key].value
		end
	end
	return store
end

--getTickerPattern('SRZ4')
