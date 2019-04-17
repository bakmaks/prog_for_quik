-- Дата: 22.01.2014
-- Автор: CyberTrader

sClassCode = "SPBFUT"
sSecCode = "RIU5"
nSizeStakan = 22

bIsRun = false
t_Stakan, t_NumTrades, t_AllTrade = os.clock(), os.clock(), os.clock()
nTime_Param, nTime_AllTrade = 0, 0
bSelfUpdating = false


function main()
  local x, y, width_Stakan, hight_Stakan = 0, 65, 157, 615

  ID_Stakan = AllocTable()
  AddColumn(ID_Stakan, 1, "Цена", true, QTABLE_DOUBLE_TYPE, 9)
  AddColumn(ID_Stakan, 2, "Объём", true, QTABLE_INT_TYPE, 8)
  AddColumn(ID_Stakan, 3, "В сделках", true, QTABLE_INT_TYPE, 6)
  CreateWindow(ID_Stakan)
  SetTableNotificationCallback(ID_Stakan, f_cb)
  SetWindowPos(ID_Stakan, x, y, width_Stakan, hight_Stakan)
  SetWindowCaption(ID_Stakan, sSecCode)

  nNumRows = nSizeStakan + nSizeStakan
  for i=1, nNumRows+1 do InsertRow(ID_Stakan, -1) end
  SetCell(ID_Stakan, nNumRows+1, 1, "C", 0)
  SetColor(ID_Stakan, nNumRows+1, 1, RGB(255, 201, 14), QTABLE_DEFAULT_COLOR, RGB(255, 201, 14), QTABLE_DEFAULT_COLOR)
  SetCell(ID_Stakan, nNumRows+1, 2, "A", 0)
  SetColor(ID_Stakan, nNumRows+1, 2, RGB(245, 246, 247), QTABLE_DEFAULT_COLOR, RGB(245, 246, 247), QTABLE_DEFAULT_COLOR)

  ID_Stat = AllocTable()
  AddColumn(ID_Stat, 1, "Параметр", true, QTABLE_CACHED_STRING_TYPE, 16)
  AddColumn(ID_Stat, 2, "Значение", true, QTABLE_INT_TYPE, 10)
  AddColumn(ID_Stat, 3, "Тайминг", true, QTABLE_DOUBLE_TYPE, 10)
  AddColumn(ID_Stat, 4, "Время", true, QTABLE_CACHED_STRING_TYPE, 10)
  AddColumn(ID_Stat, 5, "Изменений", true, QTABLE_INT_TYPE, 11)
  CreateWindow(ID_Stat)
  SetTableNotificationCallback(ID_Stat, f_cb)
  local dx, hight_Stat = 0, 105
  SetWindowPos(ID_Stat, x+width_Stakan+dx, y, 340, hight_Stat)
  SetWindowCaption(ID_Stat, sSecCode.." Статистика")
  InsertRow(ID_Stat, -1)
  SetCell(ID_Stat, 1, 1, "Стакан")
  InsertRow(ID_Stat, 2)
  SetCell(ID_Stat, 2, 1, "Кол-во сделок")
  InsertRow(ID_Stat, 3)
  SetCell(ID_Stat, 3, 1, "Цена послед.")
  InsertRow(ID_Stat, 4)
  SetCell(ID_Stat, 4, 1, "Все сделки")
  --InsertRow(ID_Stat, 5)
  --SetCell(ID_Stat, 5, 1, "Кол-во сделок")
  --local n = getNumberOf("all_trades")
  --SetCell(ID_Stat, 5, 2, _formatNumber(n), n)

  nScale = tonumber(getParamEx(sClassCode, sSecCode, 'SEC_SCALE').param_value)
  nPriceStep = tonumber(getParamEx(sClassCode, sSecCode, 'SEC_PRICE_STEP').param_value)
  tPrice, tQuantity, tOperation, tQuantity_AllTrade, tOperation_AllTrade = {}, {}, {}, {}, {}
  nOfferMax, n_Stakan, n_Param, n_AllTrade = 0, 0, 0, 0
  _fRefreshStakan(sClassCode, sSecCode)

  nNumTradesLast = 0
  _fGetParam(sClassCode, sSecCode)

  bIsRun = true
  while bIsRun do
    sleep(100)
  end
end


function OnStop()
  bIsRun = false
end


function OnClose()
  bIsRun = false
end


function _fRefreshStakan(sClassCode, sSecCode)
  local tStakan = getQuoteLevel2(sClassCode, sSecCode)
  if tStakan then
    local nOffer_Count, nBid_Count = tonumber(tStakan.offer_count), tonumber(tStakan.bid_count)
    if nOffer_Count > 0 or nBid_Count > 0 then
      local nOffer, nBid = tonumber(tStakan.offer[1].price), tonumber(tStakan.bid[nBid_Count].price)
      if not next(tPrice) or bSelfUpdating then _fMakeStakan(nOffer, nBid) end
      local tQuantity_New, tOperation_New = {}, {}
      for i = 1, nOffer_Count do
        local nNum = _fGetNumberRow(tonumber(tStakan.offer[i].price))
        if nNum < 1 then break end
        tQuantity_New[nNum] = tonumber(tStakan.offer[i].quantity)
        tOperation_New[nNum] = "Sell"
      end
      for i = nBid_Count, 1, -1 do
        local nNum = _fGetNumberRow(tonumber(tStakan.bid[i].price))
        if nNum > nNumRows then break end
        tQuantity_New[nNum] = tonumber(tStakan.bid[i].quantity)
        tOperation_New[nNum] = "Buy"
      end
      for nNum = 1, nNumRows do
        local nQuantity = tQuantity_New[nNum]
        if nQuantity then
          if nQuantity ~= tQuantity[nNum] then SetCell(ID_Stakan, nNum, 2, _formatNumber(nQuantity), nQuantity) end
          local sOperation = tOperation_New[nNum]
          if sOperation ~= tOperation[nNum] then
            if sOperation == "Buy" then
              SetColor(ID_Stakan, nNum, QTABLE_NO_INDEX, RGB(198, 255, 198), QTABLE_DEFAULT_COLOR, RGB(198, 255, 198), QTABLE_DEFAULT_COLOR)
            elseif sOperation == "Sell" then
              SetColor(ID_Stakan, nNum, QTABLE_NO_INDEX, RGB(255, 198, 198), QTABLE_DEFAULT_COLOR, RGB(255, 198, 198), QTABLE_DEFAULT_COLOR)
            end
          end
          if sOperation == tOperation_AllTrade[nNum] then SetCell(ID_Stakan, nNum, 3, "") end
        else
          if tQuantity[nNum] then
            SetCell(ID_Stakan, nNum, 2, "")
            SetColor(ID_Stakan, nNum, QTABLE_NO_INDEX, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
          end
        end
      end
      tQuantity, tOperation = tQuantity_New, tOperation_New
    end
  end
end


function _fMakeStakan(nOffer, nBid)
  local nCenter = math.ceil((nOffer + nBid) / 2 / nPriceStep) * nPriceStep
  local n = (nOfferMax - nCenter) / nPriceStep - nSizeStakan
  if n < -2 or n > -1 then
    local nOfferMax_Prew = nOfferMax
    nOfferMax = nCenter + (nSizeStakan - 1) * nPriceStep
    --nBidMin = nCenter - nSizeStakan * nPriceStep
    local dNum = math.floor((nOfferMax - nOfferMax_Prew) / nPriceStep + 0.5)
    if next(tQuantity_AllTrade) and dNum ~= 0 then
      local tTable = {}
      for nNum, nQuantity in pairs(tQuantity_AllTrade) do tTable[nNum+dNum] = nQuantity end
      tQuantity_AllTrade, tTable = tTable, {}
      for nNum, sOperation in pairs(tOperation_AllTrade) do tTable[nNum+dNum] = sOperation end
      tOperation_AllTrade = tTable
    end
    for i = 1, nNumRows do
      local nPrice = nCenter + (nSizeStakan - i) * nPriceStep
      SetCell(ID_Stakan, i, 1, _formatNumber2(nPrice, nScale), nPrice)
      tPrice[i] = nPrice
      if next(tQuantity_AllTrade) and dNum ~= 0 then
        nQuantity = tQuantity_AllTrade[i]
        if nQuantity then
          SetCell(ID_Stakan, i, 3, _formatNumber(nQuantity), nQuantity)
        else
          SetCell(ID_Stakan, i, 3, "")
        end
      end
    end
  end
end


function OnQuote(class_code, sec_code)
  if bIsRun and class_code == sClassCode and sec_code == sSecCode then
    local t2_Stakan = os.clock()
    local dt_Stakan = t2_Stakan - t_Stakan
    SetCell(ID_Stat, 1, 3, _formatNumber2(dt_Stakan, 3), dt_Stakan)
    SetCell(ID_Stat, 1, 4, _toSec(t2_Stakan))
    _fRefreshStakan(sClassCode, sSecCode)
    n_Stakan = n_Stakan + 1
    SetCell(ID_Stat, 1, 5, _formatNumber(n_Stakan), n_Stakan)
    t_Stakan = t2_Stakan
  end
end


function _fGetParam(sClassCode, sSecCode)
  local nNumTrades = tonumber(getParamEx(sClassCode, sSecCode, 'NUMTRADES').param_value)
  if nNumTrades ~= nNumTradesLast then
    local t2_NumTrades = os.clock()
    local dt_NumTrades = t2_NumTrades - t_NumTrades
    SetCell(ID_Stat, 2, 2, _formatNumber(nNumTrades), nNumTrades)
    SetCell(ID_Stat, 2, 3, _formatNumber2(dt_NumTrades, 3), dt_NumTrades)
    local sTime_Param = _toSec(t2_NumTrades)
    SetCell(ID_Stat, 3, 4, sTime_Param)
    nTime_Param = tonumber(sTime_Param)
    if nTime_Param > nTime_AllTrade then
      SetColor(ID_Stat, 3, 4, -1, RGB(255, 0, 0), -1, RGB(255, 0, 0))
      SetColor(ID_Stat, 4, 4, -1, -1, -1, -1)
    elseif nTime_Param < nTime_AllTrade then
      SetColor(ID_Stat, 3, 4, -1, -1, -1, -1)
      SetColor(ID_Stat, 4, 4, -1, RGB(255, 0, 0), -1, RGB(255, 0, 0))
    else
      SetColor(ID_Stat, 3, 4, -1, -1, -1, -1)
      SetColor(ID_Stat, 4, 4, -1, -1, -1, -1)
    end
    n_Param = n_Param + 1
    SetCell(ID_Stat, 2, 5, _formatNumber(n_Param), n_Param)
    nNumTradesLast = nNumTrades
    t_NumTrades = t2_NumTrades
  end
  local nLast = tonumber(getParamEx(sClassCode, sSecCode, 'LAST').param_value)
  SetCell(ID_Stat, 3, 2, _formatNumber(nLast), nLast)
end


function OnParam(class_code, sec_code)
  if bIsRun and class_code == sClassCode and sec_code == sSecCode then
    _fGetParam(class_code, sec_code)
  end
end


function OnAllTrade(alltrade)
  if bIsRun and alltrade.class_code == sClassCode and alltrade.sec_code == sSecCode then
    local t2_AllTrade = os.clock()
    local dt_AllTrade, sTime_AllTrade = t2_AllTrade-t_AllTrade, _toSec(t2_AllTrade)
    SetCell(ID_Stat, 4, 3, _formatNumber2(dt_AllTrade, 3), dt_AllTrade)
    SetCell(ID_Stat, 4, 4, sTime_AllTrade)
    local nPrice, flags = alltrade.price, alltrade.flags
    SetCell(ID_Stat, 4, 2, _formatNumber(nPrice), nPrice)
    if flags then
      local nQuantity = alltrade.qty
      local nNum = _fGetNumberRow(nPrice)
      if _bitset(flags, 1) then
        Highlight(ID_Stakan, nNum, QTABLE_NO_INDEX, RGB(128, 255, 128), QTABLE_DEFAULT_COLOR, 120)
        if tOperation_AllTrade[nNum] ~= "Sell" then nQuantity = (tQuantity_AllTrade[nNum] or 0) + nQuantity end
        tOperation_AllTrade[nNum] = "Buy"
      else
        Highlight(ID_Stakan, nNum, QTABLE_NO_INDEX, RGB(255, 128, 128), QTABLE_DEFAULT_COLOR, 120)
        if tOperation_AllTrade[nNum] ~= "Buy" then nQuantity = (tQuantity_AllTrade[nNum] or 0) + nQuantity end
        tOperation_AllTrade[nNum] = "Sell"
      end
      tQuantity_AllTrade[nNum] = nQuantity
      if nNum >= 1 and nNum <= nNumRows then SetCell(ID_Stakan, nNum, 3, _formatNumber(nQuantity), nQuantity) end
    end
    nTime_AllTrade = tonumber(sTime_AllTrade)
    if nTime_Param > nTime_AllTrade then
      SetColor(ID_Stat, 3, 4, -1, RGB(255, 0, 0), -1, RGB(255, 0, 0))
      SetColor(ID_Stat, 4, 4, -1, -1, -1, -1)
    elseif nTime_Param < nTime_AllTrade then
      SetColor(ID_Stat, 3, 4, -1, -1, -1, -1)
      SetColor(ID_Stat, 4, 4, -1, RGB(255, 0, 0), -1, RGB(255, 0, 0))
    else
      SetColor(ID_Stat, 3, 4, -1, -1, -1, -1)
      SetColor(ID_Stat, 4, 4, -1, -1, -1, -1)
    end
    n_AllTrade = n_AllTrade + 1
    SetCell(ID_Stat, 4, 5, _formatNumber(n_AllTrade), n_AllTrade)
    --local n = getNumberOf("all_trades")
    --local n = alltrade.trade_num
    --SetCell(ID_Stat, 5, 2, _formatNumber(n), n)
    t_AllTrade = t2_AllTrade
  end
end


function _fGetNumberRow(nPrice)
  return math.floor((nOfferMax-nPrice)/nPriceStep+0.5)+1
end


function f_cb(t_id, msg, par1, par2)
  if msg == QTABLE_CLOSE then
    if t_id == ID_Stakan then
      DestroyTable(ID_Stat)
      bIsRun = false
    elseif t_id == ID_Stat then
      DestroyTable(ID_Stakan)
      bIsRun = false
    end
  elseif t_id == ID_Stakan then
    if par1 == nNumRows+1 then
      if par2 == 1 then
        if msg == QTABLE_LBUTTONDOWN then
          SetColor(ID_Stakan, nNumRows+1, 1, RGB(255, 255, 0), QTABLE_DEFAULT_COLOR, RGB(255, 255, 0), QTABLE_DEFAULT_COLOR)
          tPrice = {}
          _fRefreshStakan(sClassCode, sSecCode)
        elseif msg == QTABLE_LBUTTONUP then
          SetColor(ID_Stakan, nNumRows+1, 1, RGB(255, 201, 14), QTABLE_DEFAULT_COLOR, RGB(255, 201, 14), QTABLE_DEFAULT_COLOR)
        end
      elseif par2 == 2 and msg == QTABLE_LBUTTONDOWN then
        if bSelfUpdating then
          bSelfUpdating = false
          tPrice = {}
          SetColor(ID_Stakan, nNumRows+1, 2, RGB(245, 246, 247), QTABLE_DEFAULT_COLOR, RGB(245, 246, 247), QTABLE_DEFAULT_COLOR)
        else
          bSelfUpdating = true
          tPrice = {}
          SetColor(ID_Stakan, nNumRows+1, 2, RGB(0, 179, 255), QTABLE_DEFAULT_COLOR, RGB(0, 179, 255), QTABLE_DEFAULT_COLOR)
          _fRefreshStakan(sClassCode, sSecCode)
        end
      end
    end
  end
end


function _formatNumber(amount)
  -- разделяет строку с входящим числом разделенным на разряды (100000 --> 100 000)
  local formatted, k = amount
  while k~=0 do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1 %2")
  end
  return formatted
end


function _formatNumber2(amount, scale)
  -- разделяет строку с входящим числом разделенным на разряды (1000000 --> 1 000 000)
  -- так же заполняется определенное кол-во знаков после запятой
  -- если кол-во знаков после запятой не указывается, то берется 2 знака
  local formatted, k = string.format("%."..(scale or 2).."f",amount or 0)
  while k~=0 do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1 %2")
  end
  return formatted
end


function _toSec(time)
  if time ~= 0 then
    local n = string.find(time, '%.') or string.len(time)
    return string.sub(time, n-2, n+4)
  else
    return time
  end
end


function _bitset(flags, index)
  local n = 1
    n = bit.lshift(1, index)
  if bit.band(flags, n) == 0 then
    return false
  else
    return true
  end
end
