package.cpath=".\\?.dll;.\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\?.dll;C:\\Program Files (x86)\\Lua\\5.1\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\?.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\loadall.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\loadall.dll;C:\\Program Files\\Lua\\5.1\\?.dll;C:\\Program Files\\Lua\\5.1\\?51.dll;C:\\Program Files\\Lua\\5.1\\clibs\\?.dll;C:\\Program Files\\Lua\\5.1\\clibs\\?51.dll;C:\\Program Files\\Lua\\5.1\\loadall.dll;C:\\Program Files\\Lua\\5.1\\clibs\\loadall.dll"..package.cpath
package.path=package.path..";.\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.luac;C:\\Program Files\\Lua\\5.1\\lua\\?.lua;C:\\Program Files\\Lua\\5.1\\lua\\?\\init.lua;C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\?\\init.lua;C:\\Program Files\\Lua\\5.1\\lua\\?.luac;"

package.path=package.path..getScriptPath()..'\\?.lua;'

require 'QL'
require 'ticker'



message = function (str) message(str, 1) end

function initClusterStore(ticker)
	local Store = {
		cluster = {},				-- таблица кластера
		labels = {},				-- таблица меток с графика
		table_name = 'all_trades',	-- название таблицы всех сделок в Quik
		start_time = 0,				-- начало кластера
		end_time = 0,				-- конец кластера
		sum_contr = 0,				-- сумма контрактов в кластере
		sum_cl_prices = 0,			-- сумма цен всех сделок в кластере
		average_cl_price = 0,		-- средняя цена кластера
		flag = false,				-- получен кластер или нет
		sign_cluster = false,		-- признак кластера
		ticker_items = getTickerPattern(ticker)	-- получает данные из файла config.xml
		}
		return Store
end

function getLine(lenth)
    local line = ''
    for i=1, lenth do line = line..'~~' end
    return line
end

function getClusterTime(t_date)
-- Получает таблицу "datetime" из таблицы сделки
-- возвращает число вида "hhmmss"
--
	return tonumber(string.format('%02d%02d%02d', t_date.hour, t_date.min, t_date.sec))
end

function getClusterDate(t_date)
-- Получает таблицу "datetime" из таблицы сделки
-- возвращает число вида "YYYYMMDD"
--
	return tonumber(string.format('%04d%02d%02d', t_date.year, t_date.month, t_date.day))
end

function getMilSec(trade_datetime)
--ѕолучает таблицу "datetime" из таблицы сделки
--¬озвращает врем¤ сделки в ms.
--
	local ms_time = (trade_datetime.hour * 3600 + trade_datetime.min * 60 + trade_datetime.sec) * 1000
                     + trade_datetime.ms
	return ms_time
end

function getStartEndTime(start_cl_time)
-- ¬озвращает врем¤ начала и окончани¤ кластера
	local start_t = start_cl_time
	local end_t = start_t + Cluster.ticker_items['CLUSTER_TIME'] * 1000
	return start_t, end_t
end

function isCluster(cl, cl_sum_qty)
-- возвращает true если выполняются все условия для кластера.
--
    if #cl > 0 and cl_sum_qty >= Cluster.ticker_items['MIN_SIZE_CLUSTER'] then
	    return true
    end
    return false
end

function getCluster(start)
-- start - номер строки в таблице всех сделок "AllTrade" в Quik которй начинаетс¤ отсчЄт.
-- возвращает true если кластер найден и false если нет, a так же значение start.
-- функци¤ ищет кластеры в табли всех сделок "AllTrade".
	local start = start
    local trade ={}
	local current_trade_time = 0
	
	local function addTradeToCluster()
		Cluster.cluster[#Cluster.cluster + 1] = trade --table.insert(Cluster.cluster, trade)
		Cluster.sum_contr = Cluster.sum_contr + trade.qty
		Cluster.sum_cl_prices = Cluster.sum_cl_prices + trade.price * trade.qty
		Cluster.average_cl_price = Cluster.sum_cl_prices / Cluster.sum_contr
	end
	
	local n = getNumberOf(Cluster.table_name)
	
	if n == 0 then
		return false, start
	else
		for i = start, n-1 do
			trade = getItem(Cluster.table_name, i)
			if trade.sec_code == Cluster.ticker_items['SecCode'] and trade.class_code == Cluster.ticker_items['ClassCode'] then
				
				current_trade_time = getMilSec(trade.datetime)
				
				if trade.qty >= Cluster.ticker_items['CONTRACTS_IN_TRADE'] and not Cluster.sign_cluster then					
					Cluster.sign_cluster = true
					Cluster.cluster = {}
					Cluster.sum_contr, Cluster.sum_cl_prices, Cluster.average_cl_price = 0, 0, 0
					Cluster.start_time, Cluster.end_time = getStartEndTime(current_trade_time)
					addTradeToCluster()
				elseif current_trade_time >= Cluster.start_time and current_trade_time < Cluster.end_time and Cluster.sign_cluster then
					addTradeToCluster()
				elseif current_trade_time > Cluster.end_time and Cluster.sign_cluster then
					Cluster.sign_cluster = false
					if Cluster.sum_contr >= Cluster.ticker_items['MIN_SIZE_CLUSTER'] then
						return true, i
					else
						return false, i
					end
				end
			end
		end
	end
	return false, n
end

function getClusterAveragePrice()
	return Cluster.average_cl_price		--cluster_price
end

function getClusterDateTime()
	return Cluster.cluster[#Cluster.cluster].datetime
end

function maxTrade(t_set)
-- Получает таюлицу вида 'cluster'.
-- Возвращает максимальное кол-во контрактов в одной сделке.
--
	local t_max= 0
	for _, trade in ipairs(t_set) do
		if trade.qty >= t_max then
			t_max = trade.qty
		end
	end
	return t_max
end

function getTimeDateString(t_date)
-- Получает таблицу "datetime" из таблицы сделки
-- Возвращает 2 строки вида hh:mm:ss и DD.MM.YYYY
--
	return string.format('%02d:%02d:%02d', t_date.hour, t_date.min, t_date.sec), string.format('%02d.%02d.%04d',  t_date.day, t_date.month, t_date.year)
end
