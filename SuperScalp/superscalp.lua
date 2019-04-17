
--SuperScalp.lua, ver 1.1, © hismatullin.h 17.11.2014
lastPos = 0
lastPrice = 0
local string_find=string.find
local string_sub=string.sub
local string_len=string.len
local SeaGreen=12713921         --      RGB(193, 255, 193)
local RosyBrown=12698111        --      RGB(255, 193, 193)

--настройки
function getInitParameter()
        account = '7600e6x'
        classCode = 'SPBFUT'
        secCode = 'SRZ5'
        workSize = 1
        OpenSlippage = 10
        Frequency = 50
end
-----------------------------

function event_callback_tblH(t_id, msg, par1, par2)
        if msg == QTABLE_LBUTTONDOWN then       -- нажата левая кнопка мыши
                lastPos = futures_position()
                local status = tonumber(getParamEx(classCode, secCode,"status").param_value)
                if status ~= 1 or par1 == 1 then -- если бумага не торгуется, заявку не подаем
                        Highlight(t_id, par1,par2, RosyBrown,QTABLE_DEFAULT_COLOR,500)          -- подсветка, RosyBrown
                        if status ~= 1 then
                                message('Ошибка: клиринг!',3)
                        end
                        return
                end
                Highlight(t_id, par1,par2, SeaGreen,QTABLE_DEFAULT_COLOR,500)           -- подсветка SeaGreen
                if par1 == 2 and par2 == 1 then
                        if lastPos < 0 then
                                Buy(classCode, secCode, -lastPos, 'CloseShort')
                        elseif  lastPos == 0 then
                                Buy(classCode, secCode, workSize, 'OpenLong')
                        else
                                message("Мы в лонгах, не покупаем!",1)
                        end
                elseif par1 == 2 and par2 == 2 then     -- продать, левая кнопка
                        if lastPos > 0 then
                                Sell(classCode, secCode, lastPos, 'CloseLong')
                        elseif  lastPos == 0 then
                                Sell(classCode, secCode, workSize, 'OpenShort')
                        else
                                message("Мы в шортах, не продаем!",1)
                        end
                elseif par1 == 2 and par2 == 3 then     -- закрыть позиции
                        if lastPos > 0 then
                                Sell(classCode, secCode, lastPos, 'CloseAll')
                        elseif  lastPos < 0 then
                                Buy(classCode, secCode, -lastPos, 'CloseAll')
                        else
                                message("Нет позиций для закрытия!",1)
                        end
                ------------------------------------------
                elseif par1 == 3 and par2 == 1 then     -- Купить лучше рынка
                        if lastPos < 0 then
                                BuyBid(classCode, secCode, -lastPos, 'CloseShort')
                        elseif  lastPos == 0 then
                                BuyBid(classCode, secCode, workSize, 'OpenLong')
                        else
                                message("Мы в лонгах, не покупаем!",1)
                        end
                elseif par1 == 3 and par2 == 2 then     -- продать, лучше рынка
                        if lastPos > 0 then
                                SellOffer(classCode, secCode, lastPos, 'CloseLong')
                        elseif  lastPos == 0 then
                                SellOffer(classCode, secCode, workSize, 'OpenShort')
                        else
                                message("Мы в шортах, не продаем!",1)
                        end
                elseif par1 == 3 and par2 == 3 then
                        message("Снять все заявки!",1)
                        KillOrders()
                end
        elseif msg == QTABLE_CLOSE then
                OnStop()
        end
end
-----------------------------

QTable ={}
QTable.__index = QTable
-- Создать и инициализировать экземпляр таблицы QTable
function QTable.new()
        local t_id = AllocTable()
        if t_id ~= nil then
                q_table = {}
                setmetatable(q_table, QTable)
                q_table.t_id=t_id
                q_table.caption = ""
                q_table.created = false
                q_table.curr_col=0
                -- таблица с описанием параметров столбцов
                q_table.columns={}
                return q_table
        else
                return nil
        end
end
tblH = QTable:new() -- для ручной торговли
-----------------------------

function get_trans_id()
        local s = tostring(os.clock())
        local x, g = string_find(s, "(%d+)")
        s = string_sub(s, g + 2)
        for i = 1, 3 - string_len(s) do
                s = "0" .. s
        end
        return os.date("%H%M%S") .. s
end
-----------------------------

function send_order(client, class, seccode, account, operation, quantity, price)
        local trans_id = 0
        trans_id = get_trans_id()
        local trans_params = {
                CLIENT_CODE = client,
                CLASSCODE = class,
                SECCODE = seccode,
                ACCOUNT = account,
                TYPE = new_type,
                TRANS_ID = trans_id,
                OPERATION = operation,
                QUANTITY = tostring(quantity),
                PRICE = tostring(price),
                ACTION = "NEW_ORDER"
                }
        local res = sendTransaction(trans_params)
        return res
end
-----------------------------

function Buy(classCode, secCode, size, action)
        local best_offer = getParamEx(classCode, secCode, "offer").param_value
        local buyPrice = best_offer + (OpenSlippage or 0)
        local res = send_order(action, classCode, secCode, account, "B", size, buyPrice)
        if string_len(res) ~= 0 then
                message('Ошибка: '..res..', '.. action..', '..secCode..', '.."B"..', '..size..', price='..buyPrice,3)
        end
end
-----------------------------

function Sell(classCode, secCode, size, action)
        local best_bid = getParamEx(classCode, secCode, "bid").param_value
        local sellPrice = best_bid - (OpenSlippage or 0)
        local res = send_order(action, classCode, secCode, account, "S", size, sellPrice)
        if string_len(res) ~= 0 then
                message('Ошибка: '..res..', '.. action..', '..secCode..', '.."S"..', '..size..', price='..sellPrice,3)
        end
end
-----------------------------

function BuyBid(classCode, secCode, size, action)
        local best_bid = getParamEx(classCode, secCode, "bid").param_value
        local buyPrice = best_bid - (OpenSlippage or 0)
        local res = send_order(action, classCode, secCode, account, "B", size, buyPrice)
        if string_len(res) ~= 0 then
                message('Ошибка: '..res..', '.. action..', '..secCode..', '.."B"..', '..size..', price='..buyPrice,3)
        end
end
-----------------------------

function SellOffer(classCode, secCode, size, action)
        local best_offer = getParamEx(classCode, secCode, "offer").param_value
        local sellPrice = best_offer + (OpenSlippage or 0)
        local res = send_order(action, classCode, secCode, account, "S", size, sellPrice)
        if string_len(res) ~= 0 then
                message('Ошибка: '..res..', '.. action..', '..secCode..', '.."S"..', '..size..', price='..sellPrice,3)
        end
end
-----------------------------

function KillOrders()
        local NumberOf = getNumberOf("orders")
        for i = 0, NumberOf - 1 do
                local ord = getItem("orders", i)
                local ord_status = get_order_status(ord.flags)
                if ord_status == "active" and (ord.sec_code == secCode) and ord.account == account  then
                        trans_id = get_trans_id()
                        local trans_params =
                                {
                                        ["CLASSCODE"] = classCode,
                                        ["TRANS_ID"] = trans_id,
                                        ["ACTION"] = "KILL_ORDER",
                                        ["ORDER_KEY"] = tostring(ord.order_num)
                                }
                        local res =  sendTransaction(trans_params)
                        if 0 < string_len(res) then
                                message('Ошибка: '..res,1)
                        end
                end
        end
end
-----------------------------

function get_order_status(flags)
        local status
        local band = bit.band
        local tobit = bit.tobit
        if band(tobit(flags), 1) ~= 0 and band(tobit(flags), 2) == 0 then
                status = "active"
        end
        return status
end
-----------------------------

function HandleBS()
        local t = tblH.t_id
        AddColumn(t, 1, 'Бумага', true,QTABLE_CACHED_STRING_TYPE,12)
        AddColumn(t, 2, 'ТЧП', true,QTABLE_STRING_TYPE,12)
        AddColumn(t, 3, 'Цена послед.', true,QTABLE_STRING_TYPE,17)
        CreateWindow(t)
        SetWindowCaption(t, "SuperScalp")       --SetWindowCaption(t, "Scalper:"..account)
        SetWindowPos(t, 0, 100, 250, 120)
        local li=InsertRow(t, -1)
        SetCell(t, li, 1, secCode)
        SetCell(t, li, 2, lastPos)
        SetCell(t, li, 3, '7503')       --Ожидание
        local li=InsertRow(t, -1)
        SetCell(t, li, 1, 'Купить')
        SetCell(t, li, 2, 'Продать')
        SetCell(t, li, 3, 'Закрыть')
        local li=InsertRow(t, -1)
        SetCell(t, li, 1, 'купить -')
        SetCell(t, li, 2, 'продать +')
        SetCell(t, li, 3, 'Снять все')
        SetTableNotificationCallback(t,event_callback_tblH)
end
-----------------------------

--прочитать ТТП и вытащить ТЧП.
function futures_position()
        local count=getNumberOf("futures_client_holding") --Позиции по клиентским счетам (фьючерсы)
        for i=0,count-1, 1 do
                local row=getItem("futures_client_holding",i)
                if row.trdaccid~=nil then
                        local seccode=row.sec_code              --Код фьючерсного контракта, "Инструмент"
                        local totn=row.totalnet                 --Текущие чистые позиции        "ТЧП"
                        if seccode == secCode then
                                return totn
                        end
                end
        end
        return 0
end
-----------------------------

-- function positionColor(tot)
        -- local q = QTABLE_DEFAULT_COLOR
        -- if tot>0 then
                -- SetColor(tblH.t_id,1,2, SeaGreen, q, q, q)      -- подсветка SeaGreen
        -- elseif tot < lastPrice then
                        -- Highlight(tblH.t_id, 1, 3, SeaGreen, QTABLE_DEFAULT_COLOR,1000)         -- подсветка мягкий, зеленый
                        -- lastPrice = lp  -- цена последней сделки
                        -- SetCell(tblH.t_id, 1, 3, tostring(lastPrice))
                -- elseif lp < lastPrice then
                        -- Highlight(tblH.t_id, 1, 3, RosyBrown, QTABLE_DEFAULT_COLOR,1000)                -- подсветка
                        -- lastPrice = lp
                        -- SetCell(tblH.t_id, 1, 3, tostring(lastPrice))
                -- end
        -- end
-- end
-----------------------------

-- 2.2.24 Функция вызывается терминалом QUIK при остановке скрипта из диалога управления.
function OnStop()
        message("SuperScalp остановлен",1)
        running = false
        DestroyTable(tblH.t_id)
end
-----------------------------

-- 2.2.25 OnInit
-- Функция вызывается терминалом QUIK перед вызовом функции main()
function OnInit(script_path)
        getInitParameter()
        running = true
        message("SuperScalp работает.",1)
        HandleBS()
        lastPos = futures_position()
        SetCell(tblH.t_id, 1, 2, tostring(lastPos))
        --positionColor(lastPos)
end
-----------------------------

-- 2.2.26 main
-- Функция, реализующая основной поток выполнения в скрипте.
function main()
        while running do
                sleep(Frequency)
        end
end
