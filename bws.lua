local settings = {
  color = {
    new = _G.RGB(0, 255, 0),
	old = _G.RGB(255, 255, 0),
	out = _G.RGB(255, 0, 0)
  },
  days_back = 0,
  top = 8,
  period = 5 -- trading week
}

local str_split = function (str, sep)
    local fields = {}
	str:gsub("([^"..sep.."]*)"..sep, function(c)
	   table.sinsert(fields, c)
	end)
	return fields
end

local function get_secs_params (class_code, days_back)

  local days_back = days_back or 0

  local datasources = {}
  for _, sec_code in ipairs(str_split(_G.getClassSecurities(class_code), ",")) do
    local ds = _G.CreateDataSource(class_code, sec_code, _G.INTERVAL_D1)
    ds:SetEmptyCallback()
	datasources[sec_code] = ds
	_G.ParamRequest(class_code, sec_code, "LOTSIZE")
  end
  sleep(1000)
  
  local result = {}
  for sec_code, ds in pairs(datasources) do
    local lastCandleIndex = ds:Size() - days_back
	local _close = ds:C(lastCandleIndex)
	local lot_size = tonumber(_G.getParamEx2(class_code, sec_code, "LOTSIZE").param_value)
	
	local turnover = 0.0
	for i = lastCandleIndex, lastCandleIndex - 365, -1 do
	  turnover = turnover + ds:V(i) * lot_size * ds:C(i)
	end
	turnover = turnover / 365
	
	local close_week_back = ds:C(lastCandleIndex - days_back - 5)
	
    table.sinsert(result, {
      ticker = sec_code,
	  close = _close,
	  close_week_back = close_week_back,
	  close_difference = 100.0 * (_close - close_week_back) / close_week_back,
	  stop_loss = stop_loss,
	  turnover = turnover,
	  lot_size = lot_size
    })
	ds:Close()
	_G.CancelParamRequest(class_code, sec_code, "LOTSIZE")
  end
  
  return result
end

local function stringify_money (money)
  -- too lazy to think of a better solution
  if money < 1000 or money > 1000000000000 then
    return string.format("%.0f", money)
  elseif money <= 1000000 then
    return string.format("%dK", money / 1000)
  elseif money <= 1000000000 then
    return string.format("%0.2fM", money / 1000000)
  elseif money <= 1000000000000 then
    return string.format("%0.2fB", money / 1000000000)
  end
end

function main ()

  local classCode = "TQBR"

  local t_id = _G.AllocTable()
  _G.AddColumn(t_id, 0, "Ticker", true, QTABLE_STRING_TYPE, 10) -- ticker
  _G.AddColumn(t_id, 1, "Close", true, QTABLE_DOUBLE_TYPE, 30) -- close
  _G.AddColumn(t_id, 2, "Prev. week close", true, QTABLE_DOUBLE_TYPE, 30) -- close on prev. week
  _G.AddColumn(t_id, 3, "% diff", true, QTABLE_DOUBLE_TYPE, 20) -- % difference
  _G.AddColumn(t_id, 4, "Stop-Loss", true, QTABLE_DOUBLE_TYPE, 30) -- stop-loss
  _G.AddColumn(t_id, 5, "Turnover", true, QTABLE_DOUBLE_TYPE, 20) -- turnover
  _G.AddColumn(t_id, 6, "Lot size", true, QTABLE_INT_TYPE, 30) -- shares in a lot
  _G.CreateWindow(t_id)
  _G.SetWindowCaption(t_id, "BWS")
  
  local securities = get_secs_params(classCode, settings.days_back)
  table.sort(securities, function (a, b) return a.turnover > b.turnover end)
  local top_liquid_stocks = {}
  for k, v in pairs({unpack(securities, 1, 32)}) do
    table.sinsert(top_liquid_stocks, v)
  end
  table.sort(top_liquid_stocks, function (a, b) return a.close_difference > b.close_difference end)
  
  local secs_wb = get_secs_params(classCode, settings.days_back + settings.period)
  table.sort(secs_wb, function (a, b) return a.turnover > b.turnover end)
  local top_liquid_stocks_wb = {}
  for k, v in pairs({unpack(secs_wb, 1, 32)}) do
    table.sinsert(top_liquid_stocks_wb, v)
  end
  table.sort(top_liquid_stocks_wb, function (a, b) return a.close_difference > b.close_difference end)
  local top8_wb = {}
  for k, v in pairs({unpack(top_liquid_stocks_wb, 1, settings.top)}) do
    top8_wb[v.ticker] = true
  end
  
  local row_id
  for i, sec_info in ipairs(top_liquid_stocks) do
	row_id = InsertRow(t_id, -1)
	SetCell(t_id, row_id, 0, sec_info.ticker)
	SetCell(t_id, row_id, 1, tostring(sec_info.close), sec_info.close)
	SetCell(t_id, row_id, 2, tostring(sec_info.close_week_back), sec_info.close_week_back)
	SetCell(t_id, row_id, 3, string.format("%.2f", sec_info.close_difference), sec_info.close_difference)
	SetCell(t_id, row_id, 4, "0.0", 0.0)
	SetCell(t_id, row_id, 5, stringify_money(sec_info.turnover), sec_info.turnover)
	SetCell(t_id, row_id, 6, tostring(sec_info.lot_size), sec_info.lot_size)
	
	local color = _G.QTABLE_DEFAULT_COLOR
	if top8_wb[sec_info.ticker] then
	  if i > settings.top then
	    color = settings.color.out
	  else
	    color = settings.color.old
	  end
	elseif i <= settings.top then
	  color = settings.color.new
	end

	_G.SetColor(t_id, i, _G.QTABLE_NO_INDEX, color, _G.QTABLE_DEFAULT_COLOR, _G.QTABLE_DEFAULT_COLOR, _G.QTABLE_DEFAULT_COLOR)
  end
end