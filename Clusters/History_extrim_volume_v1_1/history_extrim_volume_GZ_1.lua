package.cpath=".\\?.dll;.\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\?.dll;C:\\Program Files (x86)\\Lua\\5.1\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\?.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\loadall.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\loadall.dll;C:\\Program Files\\Lua\\5.1\\?.dll;C:\\Program Files\\Lua\\5.1\\?51.dll;C:\\Program Files\\Lua\\5.1\\clibs\\?.dll;C:\\Program Files\\Lua\\5.1\\clibs\\?51.dll;C:\\Program Files\\Lua\\5.1\\loadall.dll;C:\\Program Files\\Lua\\5.1\\clibs\\loadall.dll"..package.cpath
package.path=package.path..";.\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.luac;C:\\Program Files\\Lua\\5.1\\lua\\?.lua;C:\\Program Files\\Lua\\5.1\\lua\\?\\init.lua;C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\?\\init.lua;C:\\Program Files\\Lua\\5.1\\lua\\?.luac;"

package.path=package.path..getScriptPath()..'\\?.lua;'


require 'date'
require 'extrim_volume_1'
require 'show_history_volume_1'

--Структура с параметрами кластера.
--Описана в файле config.xml

--##############################################
-- Ввести название инструмента.
local ticker = 'GZU7'	
--##############################################

local store = getInitParameters(ticker)
	
local is_run = true

function OnInit(path)
	LookedFiles = AllocTable()
	AddColumn(LookedFiles, 1, "Просмотренный файл", true, QTABLE_STRING_TYPE, 60)
	AddColumn(LookedFiles, 2, "Найден", true, QTABLE_STRING_TYPE, 10)
	
	CreateWindow(LookedFiles)
	SetWindowCaption(LookedFiles, "Список прросмотренных файлов.")
	InsertRow(LookedFiles, -1)
end

function OnStop(s)
	-- removeAllVolumeLabels(store.ticker_store['graph_id'], store.cluster_labels)
	-- DestroyTable(showTable)	    
	-- is_run = false
end

-- PATH_LOG_FILE = getScriptPath().."\\log"..store.ticker_store['SecCode']..".txt"

function main() 	
	
    local start_all_trade = 0      --Стартовая запись в таблице 'all_trades'
    local start_date = date(store.NOW_DATE):adddays(-store.ticker_store['DAYS_BEFORE'])    

    for i=1, store.ticker_store['DAYS_BEFORE'] do
        local y, m, d = start_date:getdate()
        local month = string.format('%02d', m )
        local date_f = string.format('%04d%02d%02d', y , m, d)        
        local f_name = store.ticker_store['PATH_FILE']..y..'\\'..month..'\\'..store.ticker_store['SecCode']..'_'..date_f..'.csv'
		
        if setTradesTable(f_name, date_f, store) then
			searchClusters(store)
			clearParams(store)
			addLableOnGr(store, date_f)
		end
		showListOfFiles(store, LookedFiles, i)
        start_date = start_date:adddays(1)
    end 
    message('Работа над '..store.ticker_store['SecCode']..' закончена!', 1) 

end