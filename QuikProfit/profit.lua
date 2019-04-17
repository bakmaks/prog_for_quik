package.cpath=".\\?.dll;.\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\?.dll;C:\\Program Files (x86)\\Lua\\5.1\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\?.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\?51.dll;C:\\Program Files (x86)\\Lua\\5.1\\loadall.dll;C:\\Program Files (x86)\\Lua\\5.1\\clibs\\loadall.dll;C:\\Program Files\\Lua\\5.1\\?.dll;C:\\Program Files\\Lua\\5.1\\?51.dll;C:\\Program Files\\Lua\\5.1\\clibs\\?.dll;C:\\Program Files\\Lua\\5.1\\clibs\\?51.dll;C:\\Program Files\\Lua\\5.1\\loadall.dll;C:\\Program Files\\Lua\\5.1\\clibs\\loadall.dll"..package.cpath
package.path=package.path..";.\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\?.lua;C:\\Program Files (x86)\\Lua\\5.1\\?\\init.lua;C:\\Program Files (x86)\\Lua\\5.1\\lua\\?.luac;C:\\Program Files\\Lua\\5.1\\lua\\?.lua;C:\\Program Files\\Lua\\5.1\\lua\\?\\init.lua;C:\\Program Files\\Lua\\5.1\\?.lua;C:\\Program Files\\Lua\\5.1\\?\\init.lua;C:\\Program Files\\Lua\\5.1\\lua\\?.luac;"

package.path=package.path..getScriptPath()..'\\?.lua;'

-- require'QL'
-- require'elementToStr'

local serializer = require("Serializer")

local deals = {data = {total_profit = 0, number_of_all_deals = 0, work_date = 0}}	-- таблица сделок заполняется в функции openDeal()

local count = 0
local run = true
local d_color = QTABLE_DEFAULT_COLOR
local path_file = getScriptPath()..'\\'

local message = function (str) message(str, 1) end
-- local toLog = function(str) toLog(path_file..'log.txt', str) end

--~~~~~~~~~~~~~~~~~~ Функции обработчики событий Quik ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function OnInit()
	TableCalcProfit = AllocTable()
	AddColumn(TableCalcProfit, 1, "Name", true, QTABLE_CACHED_STRING_TYPE, 15)
	AddColumn(TableCalcProfit, 2, "Avg Price", true, QTABLE_DOUBLE_TYPE, 15)
	AddColumn(TableCalcProfit, 3, "Last_Price", true, QTABLE_DOUBLE_TYPE, 15)
	AddColumn(TableCalcProfit, 4, "QTY in Deal", true, QTABLE_INT_TYPE , 15)
	AddColumn(TableCalcProfit, 5, "Total Deals / QTY", true, QTABLE_INT_TYPE , 19)
	AddColumn(TableCalcProfit, 6, "Profit", true, QTABLE_STRING_TYPE , 10)
	AddColumn(TableCalcProfit, 7, "Total profit", true, QTABLE_DOUBLE_TYPE , 20)
	CreateWindow(TableCalcProfit)
	
	SetTableNotificationCallback(TableCalcProfit, tableManagement)		-- назначение функции обратного вызова
	
	SetWindowPos(TableCalcProfit, 100, 700, 600, 100)
	SetWindowCaption(TableCalcProfit, "Calculation Profit")
	InsertRow(TableCalcProfit, -1)
end

function OnParam(class, sec)
	local d_key = sec..' '..class
	if deals[d_key] ~= nil then
		deals[d_key].last_price = tonumber(getParamEx(class, sec, "LAST").param_value)
		if deals[d_key].deal.open then
			deals[d_key].profit = math_floor(difPriceCost(deals[d_key].deal.avg_price, deals[d_key].last_price, deals[d_key].deal) * 
									deals[d_key].deal.sum_contracts, 0.01)
		end
	end
	
end

function OnStop()
	run = false
	DestroyTable(TableCalcProfit)
	closeDeals()
	serializer.serializeTable(path_file.."dealsData.lua", deals)
	--toLog('################## Program Finished #############################')
end

function tableManagement(t_id, msg, par1, par2)
	if t_id == TableCalcProfit and  msg == QTABLE_CLOSE then
		OnStop()
		--toLog('################## Program Finished #############################')
    end
end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function math_floor(in_number, step)
-- приведение значения цены к соответствию с шагом цены для инструмента Quik
	return math.floor(in_number / step) * step
end

function getDateNumber(t)
-- Получает транзакцию
-- возвращает целое число вида DDMMYYYY
	return tonumber(string.format('%04d%02d%02d', t.datetime.year, t.datetime.month, t.datetime.day))
end

function getTransacDirect(transact)
-- получает транзакцию
-- возвращает направление сделки
	if bit.band(transact.flags, 4) > 0 then return 's'
	else return 'b'
	end
end

function extractParam(transact)
-- получает транзакцию из таблицы сделок
-- возвращает таблицу с нужными параметрами транзакции
	return {price=transact.price, qty=transact.qty, 
			flags=transact.flags, sec_code=transact.sec_code, 
			class_code=transact.class_code, ordernum = transact.ordernum, datetime = transact.datetime}
end

function openDeal(transact, first)
-- получает транзакцию и first -- флаг открытия первой сделки
-- если first true -- устанавливает начальные значения сделки
-- если nil -- увеличивает счётчики, устанавливвает значения из transact

	--toLog('set transaction #'..count..' qty = '..transact.qty..', price = '..transact.price..' '..getTransacDirect(transact))
	count = count + 1
	local op_d = first or false
	local d = {}
	if op_d then
		deals[transact.sec_code..' '..transact.class_code] = {}
		d = deals[transact.sec_code..' '..transact.class_code]
		d.deal = {transactions = {}}
		d.number_of_deals = 1	-- кол-во сделок по бумаге или фьючерсу
		d.total_profit = 0 -- общий доход по бумаге или фьючерсу
		d.total_qty = transact.qty	-- общее кол-во контрактов в сделках по бумаге или фъючерсу
	else
		d = deals[transact.sec_code..' '..transact.class_code]
		d.number_of_deals = d.number_of_deals + 1
		d.total_qty = d.total_qty + transact.qty
	end
	d.deal.open = true
	d.last_price = 0
	d.profit = 0
	d.deal.open_date = getDateNumber(transact)
	d.deal.transactions[#d.deal.transactions + 1] = transact
	d.deal.avg_price = transact.price
	d.deal.deal_direct = getTransacDirect(transact)
	d.deal.sum_contracts = transact.qty
	d.deal.sec_code = transact.sec_code
	d.deal.class_code = transact.class_code
	deals.data.number_of_all_deals = deals.data.number_of_all_deals + 1
end

function closeDeal(transact)
	--toLog('Deal closed')
	local d = deals[transact.sec_code..' '..transact.class_code]
	d.last_price = 0
	d.profit = 0
	d.deal = {transactions = {}}
	d.deal.open_date = getDateNumber(transact)
	d.deal.open = false
	d.deal.avg_price = 0
	d.deal.deal_direct = ''
	d.deal.sum_contracts = 0
end

function closeDeals()	
	deals.data.total_profit = 0
	deals.data.number_of_all_deals = 0
	deals.data.work_date = os.date('%Y%m%d')
	for key, value in pairs(deals) do
		if key ~= 'data' then
			if deals[key].deal.open then
				deals.data.number_of_all_deals = deals.data.number_of_all_deals + 1	--подсчёт открытых сделок по различным бумагам или фьючерсам
				deals[key].number_of_deals = 1
				deals[key].total_profit = 0
				deals[key].total_qty = deals[key].deal.sum_contracts
			else
				deals[key] = nil
			end
		end
	end
end

function avgPrice(transact)
	--расчитывает среднюю цену сделки и записывает её
	--в deals[transact.sec_code..' '..transact.class_code].deal.avg_price
	local d = deals[transact.sec_code..' '..transact.class_code]
	local sum_q, sum_p = 0, 0	
	for i = 1, #d.deal.transactions do
		sum_q = sum_q + d.deal.transactions[i].qty
		sum_p = sum_p +d.deal.transactions[i].qty * d.deal.transactions[i].price
	end
	if sum_q ~= 0 then 
		d.deal.avg_price = math_floor(sum_p / sum_q, 
		getParamEx(transact.class_code, transact.sec_code, "SEC_PRICE_STEP").param_value)
	else d.deal.avg_price = 0 end
	d.deal.sum_contracts = sum_q 
end

function addToDeal(transact)
-- добавляет транзакцию в сделку
	local d = deals[transact.sec_code..' '..transact.class_code]
	if transact.qty ~= 0 then 
		d.deal.transactions[#d.deal.transactions + 1] = extractParam(transact) 
		--toLog('add transaction #'..count..' qty = '..transact.qty..', price = '..transact.price..' '..getTransacDirect(transact))
		--d.total_qty = d.total_qty + transact.qty
		count = count + 1
	end	
	avgPrice(transact)
	--toLog('avg price of deal = '..d.deal.avg_price..' all qty in deal = '..d.deal.sum_contracts)
end

function difPriceCost(begin_price, end_price, deal)
-- beging_price начальная цена сделки, end_price конечная цена, deal - открытая сделка
-- возвращает стоимость разницы в цене
	local dif = 0
	if deal.deal_direct == 'b' then
		dif = end_price - begin_price
	else
		dif = begin_price - end_price
	end
	return dif / getParamEx(deal.class_code, 
							deal.sec_code, "SEC_PRICE_STEP").param_value *	
				getParamEx(deal.class_code, 
							deal.sec_code, "STEPPRICE").param_value
end

function calcDeal(transaction)
-- Принимает транзакцию -- transaction
-- Создаёт в таблице deals, если ещё не существует, ключ 'sec_code cass_code'
-- присваивает ему значение таблицу deal в которой заполняе поля.
	local in_transact = extractParam(transaction)
	
	if deals[in_transact.sec_code..' '..in_transact.class_code] == nil then
		--toLog('Deal is opening first time.')
		openDeal(in_transact, true)
	else
		local d = deals[in_transact.sec_code..' '..in_transact.class_code]	
		if d.deal.open == false then
			--toLog('Deal is opening')
			openDeal(in_transact)
		else
			if d.deal.deal_direct == getTransacDirect(in_transact) then	-- если транзакция совпадает с напр. сделки.
				--toLog('transation adding to deal')
				addToDeal(in_transact)
				d.total_qty = d.total_qty + in_transact.qty
			else
				--toLog('closing part of deal')
				--toLog('closing transaction #'..count..' qty = '..in_transact.qty..', price = '..in_transact.price..' '..getTransacDirect(in_transact))
				count = count + 1
				-- qty, price - разница в кол-ве контрактов и цене между последней транзакцией в сделке
				-- и транзакцией на закрытие сделки
				local dif = {qty = 0, price = 0}
				local last_deal_tr = {}	-- последняя транзакция в сделке
				-- флаг полного исполнения транзакции противоположной направлению сделки
				local transaction_perormed = false
				while not transaction_perormed do
					last_deal_tr = table.remove(d.deal.transactions) 	--вытаскивает последнюю транзакцию из  deal	
					dif.price_cost = difPriceCost(last_deal_tr.price, in_transact.price, d.deal) 
					dif.qty = last_deal_tr.qty - in_transact.qty
					local profit = 0
					if dif.qty >= 0 then
						profit = in_transact.qty * dif.price_cost
						--toLog('profit = '..profit..', dif.price = '..dif.price_cost..' dif.qty = '..dif.qty)						
						last_deal_tr.qty = dif.qty
						addToDeal(last_deal_tr)
						transaction_perormed = true
					else
						profit = last_deal_tr.qty * dif.price_cost
						in_transact.qty = -1 * dif.qty	-- неисполненый остаток контрактов во входящей транзакции
					end
					d.total_profit = math_floor(d.total_profit  + profit, 0.01)
					deals.data.total_profit = math_floor(deals.data.total_profit + profit, 0.01)
					--toLog('d.total_profit = '..d.total_profit..' deals.data.total_profit = '..deals.data.total_profit)
					if #d.deal.transactions == 0 then	-- если больше нет транзакций в сделке
						--toLog('Deal is closing')
						closeDeal(in_transact)
						--toLog('******************************************************************************************')
						if dif.qty < 0 then		-- если остались не закрытые контракты во входящей транзакции
							--toLog('Opening new revers deal')
							d = openDeal(in_transact)	-- открывается сделка в противоположном направлении
						end
						transaction_perormed = true
					end
				end
			end
		end		
	end	
end

function makeIndicator()
	local i = 0
	return function()
		local str = ' '
		for k = 0, i do
			str = str..str
		end
		i = (i + 1) % 10
		return str..'-'
	end
end

local indicator = makeIndicator()

function noDeals(d)
	-- получает d -- таблицу вида Deals
	-- возвращает true если нет ни одной сделки, если есть то false
	for key, _ in pairs(d) do
		if key ~= 'data' then return false end
	end
	return true
end

function viewResult(ch)
	local ch = ch or '0'
	local rows, col = GetTableSize(TableCalcProfit)
	local row = 1
	for item, value in pairs(deals) do
		if item ~= 'data' then
			SetCell(TableCalcProfit, row, 1, item)
			SetCell(TableCalcProfit, row, 2, tostring(value.deal.avg_price), value.deal.avg_price)
			SetCell(TableCalcProfit, row, 3, tostring(value.last_price), value.last_price)
			SetCell(TableCalcProfit, row, 4, tostring(value.deal.sum_contracts), value.deal.sum_contracts)
			SetCell(TableCalcProfit, row, 5, string.format('%d / %d   ',value.number_of_deals, value.total_qty))			
			if value.deal.open then				
				if value.deal.deal_direct == 'b' then
					SetColor(TableCalcProfit, row, 1, RGB(162, 252, 174), d_color, d_color, d_color)
				else
					SetColor(TableCalcProfit, row, 1, RGB(252, 210, 210), d_color, d_color, d_color)
				end												
				SetCell(TableCalcProfit, row, 6, tostring('   '..value.profit))
			else
				SetCell(TableCalcProfit, row, 6, ch)
				SetColor(TableCalcProfit, row, 1, d_color, d_color, d_color, d_color)
			end
			SetCell(TableCalcProfit, row, 7, tostring(value.total_profit), value.total_profit)
			row = row + 1
			if row > rows then
				InsertRow(TableCalcProfit, -1)
			end
		else
			SetCell(TableCalcProfit, rows, 1, 'Total')
			SetCell(TableCalcProfit, rows, 7, tostring(deals.data.total_profit), deals.data.total_profit)
		end
	end
end

function main()
	local file_old_deals = dofile(path_file.."oldDealsData.lua")
	local file_deals = dofile(path_file.."dealsData.lua")
	if file_deals.data.work_date == os.date('%Y%m%d') then 
		deals = file_old_deals
	else
		serializer.serializeTable(path_file.."oldDealsData.lua", file_deals)
		deals = file_deals
	end
	local old_numbers, number_of_items = 0, getNumberOf('trades')
	local start_item, n = 0, 0
	
	-- toLog('Price of pricestep  '..getParamEx("SPBFUT", "SRZ5", "STEPPRICE").param_value)
	-- toLog('pricestep  '..getParamEx("SPBFUT", "SRZ5", "SEC_PRICE_STEP").param_value)
	-- toLog('the number of digits after the decimal point  '..getParamEx("SPBFUT", "SRZ5", "SEC_SCALE").param_value)
	local tr = {}
	local now = os.date('*t')
	while run do
		for i = start_item, number_of_items - 1 do
			tr = getItem('trades', i )
			if now.day == tr.datetime.day then
				calcDeal(tr)
			end
			n = i			
		end
		if number_of_items > 0 then start_item = n + 1 end	--если хотябы одна итерация цикла прошла
		number_of_items = getNumberOf('trades')
		viewResult(indicator())
		sleep(100)
	end
end