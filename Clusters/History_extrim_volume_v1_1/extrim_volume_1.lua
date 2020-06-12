package.cpath=".\\?.dll;.\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\?.dll;C:\\Program Files (x86)\\Lua\\5.1\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\?.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\loadall.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\loadall.dll;C:\\Program Files\\Lua\\5.1\\?.dll;C:\\Program Files\\Lua\\5.1\\?51.dll;C:\\Program Files\\Lua\\5.1\\clibs\\?.dll;C:\\Program Files\\Lua\\5.1\\clibs\\?51.dll;C:\\Program Files\\Lua\\5.1\\loadall.dll;C:\\Program Files\\Lua\\5.1\\clibs\\loadall.dll"..package.cpath
package.path=package.path..";.\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.luac;C:\\Program Files\\Lua\\5.1\\lua\\?.lua;C:\\Program Files\\Lua\\5.1\\lua\\?\\init.lua;C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\?\\init.lua;C:\\Program Files\\Lua\\5.1\\lua\\?.luac;"

package.path=package.path..getScriptPath()..'\\?.lua;'


require 'history_ticker'

function split(str, ch)
	if str ~= nil then
		local words={}
		local regexp = "[^%"..ch.."]+"
		for w in string.gmatch(str, regexp) do words[#words+1]=w end
		return words
	else
		return ""
	end
end

function readFile(name)
    local f, error = io.open(name, 'r')
    local tbl = {}

    if not error then
	  tbl = split(f:read("*a"), '\n')
      f:close()
    else	    
		tbl = nil
    end
    return tbl
end

function getMsFromStringTime(time_string)
--Получает строку со временем в формате 'HH:MM:SS'
--Возвращает время сделки в ms в виде числа.
--
	local elements = split(time_string, ':')
	local ms_time = (elements[1] * 3600 + elements[2] * 60 + elements[3]) * 1000
	return ms_time
end

function getClusterTime(t)
--Получает время в ms виде числа
--Возвращает время в виде числа 'ЧЧММСС'
	local hour = math.floor(t / 3600000)
	local min = math.floor((t/1000/60) % 60)
	local sec = t / 1000 % 60
	return math.floor(hour *10000 + min * 100 + sec)
end

function getInitParameters(ticker)
	local result_tbl = {
			ticker_store = getTickerPattern(ticker),
			height_of_table = 0,		-- Начальная высота таблицы.
			cluster_labels = {},		-- Здесь хранятся идентификаторы меток.
			clusters = {},
			deal_table = {},			-- Таблица сделок {{time_ms, qty, price, operation, looked}}
			NOW_DATE = date(),
			sec_code = '',
			class_code = '',
			cl_date = 0,					-- число вида 'YYYYMMDD'
			file = {},					-- список  файлов	
			label = {					-- структура параметров метки
				IMAGE_PATH = nil,		--label_name
				ALIGNMENT = 'RIGHT',
				TRANSPARENCY = 0,
				TRANSPARENT_BACKGROUND = 1,
				FONT_FACE_NAME = "Arial",
				FONT_HEIGHT = 10
			}
		}
	return result_tbl
end

function clearParams(params)
-- очищает парамтры 'deal_table'
	params.deal_table = {}
end

function getEndTime(start_cluster_time, params)
	local end_t = start_cluster_time + params.ticker_store['CLUSTER_TIME'] * 1000
	return end_t
end

function setTradesTable(file_name, trade_date, params)
-- функция получает имя открываемого файла, дату сделок в файле и таблицу параметров
-- поле 'deal_table' содержит таблицы с полями данных сделкок,
-- поле 'flags'  содержит символ операции 'B', 'S',
-- поле 'looked' определяет просмотрена сделка или нет.
-- поле 'qty_table' ключ - это кол-во контрактов в сделке, а значение  это таблица с номерами
-- строк в таблице 'deal_table' в которых эти сделки находятся
	
    local tbl = readFile(file_name)
	local a = #params.file + 1
	params.file[a] = {}
    params.file[a].name = file_name

    if tbl == nil then		
        params.file[a].not_found = true
		return nil
    else
		local elements = split(tbl[2], ';')
		params.sec_code = elements[1]
		params.class_code = params.ticker_store['ClassCode']
		params.cl_date = tonumber(trade_date)
		local elements, n = {}, 0

        for k=2, #tbl do
            elements = split(tbl[k], ';')
			n = #params.deal_table + 1
			params.deal_table[n] = {}
            for i=3, #elements - 1 do
                if i==3 then
                    params.deal_table[n].time_ms = getMsFromStringTime(elements[i]) + tonumber(elements[7])
                elseif i == 4 then
                    params.deal_table[n].price = tonumber(elements[i])
                elseif i==5 then
                    params.deal_table[n].qty = tonumber(elements[i])
                elseif i==6 then
                    params.deal_table[n].operation = elements[i]
                end
            end
        end
    end
	return 1
end



function searchClusters(params)
	local qty = params.ticker_store['CONTRACTS_IN_TRADE']	--кол-во контр с которого начинает отсчёт кластера
	local min_qty = params.ticker_store['MIN_SIZE_TRADE']	--минимальное кол-во контрактов которое учитывается
	local end_t = 0
	local sum, price = 0, 0
	local max_qty, time_of_max = 0, 0
	local cl_position, start_pos = 0, 0
	local cl_date = params.cl_date
	local cl_mark = false
	params.clusters[cl_date] = {}
	for i = 1, #params.deal_table do
		if params.deal_table[i].qty >= qty and not cl_mark then
			cl_mark = true	
			sum = params.deal_table[i].qty
			end_t = getEndTime(params.deal_table[i].time_ms, params)
			start_pos = i
		elseif cl_mark and params.deal_table[i].qty >= min_qty then
			if params.deal_table[i].time_ms <= end_t then
				sum = sum + params.deal_table[i].qty
			else
				if sum >= params.ticker_store['MIN_SIZE_CLUSTER'] then
					cl_position = #params.clusters[cl_date] + 1
					params.clusters[cl_date][cl_position] = {}
					for k = start_pos, i - 1 do
						price = price + params.deal_table[k].qty * params.deal_table[k].price
						if params.deal_table[k].qty > max_qty then
							max_qty = params.deal_table[k].qty
							time_of_max = params.deal_table[k].time_ms
						end
					end
					params.clusters[cl_date][cl_position].cl_avg_price = price / sum
					params.clusters[cl_date][cl_position].cl_sum_qty = sum
					params.clusters[cl_date][cl_position].cl_time = getClusterTime(time_of_max)
					params.clusters[cl_date][cl_position].cl_max_qty = max_qty
				end
				price, max_qty  = 0, 0
				sum, cl_mark = 0, false
				if params.deal_table[i].qty >= qty and not cl_mark then
					cl_mark = true	
					sum = params.deal_table[i].qty
					end_t = getEndTime(params.deal_table[i].time_ms, params)
					start_pos = i
				end
			end
		end
	end
end

