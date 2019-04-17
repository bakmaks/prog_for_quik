package.cpath=".\\?.dll;.\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\?.dll;C:\\Program Files (x86)\\Lua\\5.1\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\?.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\loadall.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\loadall.dll;C:\\Program Files\\Lua\\5.1\\?.dll;C:\\Program Files\\Lua\\5.1\\?51.dll;C:\\Program Files\\Lua\\5.1\\clibs\\?.dll;C:\\Program Files\\Lua\\5.1\\clibs\\?51.dll;C:\\Program Files\\Lua\\5.1\\loadall.dll;C:\\Program Files\\Lua\\5.1\\clibs\\loadall.dll"..package.cpath
package.path=package.path..";.\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.luac;C:\\Program Files\\Lua\\5.1\\lua\\?.lua;C:\\Program Files\\Lua\\5.1\\lua\\?\\init.lua;C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\?\\init.lua;C:\\Program Files\\Lua\\5.1\\lua\\?.luac;"

package.path=package.path..getScriptPath()..'\\?.lua;'

require 'QL'
require 'nowClusterTools'
require 'nowClusterShow'

Cluster = {} -- хранилище всех свойств кластера и самого кластера
Label_params = {} --хранилище параметров меток

local run = true

local message = function (str) message(str, 1) end

--############################# Функции обратного вызова ########################################
function OnInit()
	Cluster = initClusterStore('SiM6') -- ВВЕСТИ НАЗВАНИЕ ФЬЮЧЕРСА !!!!!!
	Label_params = initLabelParams()
end

function OnStop(s)
	-- message('стоп!')
	removeAllClusterLabels(Cluster.ticker_items['graph_id'], Cluster.labels)
	run = false
	return 
end

--###############################################################################################

function main()
	local is_cluster = false 	-- нет кластера
	local start = 0				-- строка с которой продолжится перебор таблицы всех сделок
	local cl_average_pr = 0 	-- средняя цена кластера
	
	local t_time, t_date = '', ''		-- строковые значения даты и времени
	local suffix, hint = '', ''
	local l = 1
	while run do
		is_cluster, start = getCluster(start)
		if is_cluster then
			setLableColor(255, 245, 0)
			cl_average_pr = getClusterAveragePrice()
			t_time, t_date = getTimeDateString(getClusterDateTime())
			hint = 'Дата: '..t_date..'; Время: '..t_time..';\nЦена: '..math.floor(cl_average_pr)..
							'; Объём: '..Cluster.sum_contr..';\nМакс. сделка: '..maxTrade(Cluster.cluster)
			if Cluster.sum_contr < Cluster.ticker_items['MIDDLE_SIZE_TRADES'] then
				suffix = 's'			--'small_volume'
			elseif Cluster.sum_contr < Cluster.ticker_items['BIG_SIZE_TRADES'] then
				suffix = 'm'			--'middle_volume'
			elseif Cluster.sum_contr >= Cluster.ticker_items['BIG_SIZE_TRADES'] then
				suffix = 'O'			--'big_volume'
				local big = Cluster.ticker_items['BIG_SIZE_TRADES']
				if Cluster.sum_contr < big * 1.5 then
					setLableColor(255, 8, 8)
				elseif Cluster.sum_contr < big * 2  then
					setLableColor(205, 0, 116)
				elseif Cluster.sum_contr >= big * 2 then
					setLableColor(255, 137, 0)
				end
			end
			if Cluster.ticker_items['label_length'] <= 0 then 
				message('Задайте величину "label_length" > 0 в файле config.xml')
				OnStop()
			end
			Label_params.TEXT = suffix..getLine(math.floor((Cluster.sum_contr / (Cluster.ticker_items['label_length'] * 1000)) ^ 1.5))			
			Label_params.YVALUE = getClusterAveragePrice() + Cluster.ticker_items['price_shift']
			Label_params.DATE = getClusterDate(getClusterDateTime())
			Label_params.TIME = getClusterTime(getClusterDateTime())
			Label_params.HINT = hint 			
			table.insert(Cluster.labels, AddLabel(Cluster.ticker_items['graph_id'], Label_params))
		end
		--sleep(1000)
	end	
end