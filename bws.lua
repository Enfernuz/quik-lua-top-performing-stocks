package.path = _G.getScriptPath() .. '/?.lua;' .. package.path

local getPercentDiff = function (x0, x1)
  return 100.0 * (x1 - x0) / x0
end

local getWatchList = function ()

  return {
    TQBR = {
      "RASP",
      "HYDR",
      "GMKN",
      "LKOH",
      "MVID",
      "CHMF",
      "MFON",
      "NVTK",
      "ALRS",
      "NLMK",
      "RTKM",
      "SNGSP",
      "ROSN",
      "IRAO",
      "FEES",
      "PHOR",
      "RSTI",
      "MAGN",
      "SIBN",
      "TRNFP",
      "SBERP",
      "VTBR",
      "SNGS",
      "GAZP",
      "MGNT",
      "MTSS",
      "TATN",
      "MSNG",
      "SBER",
      "MOEX",
      "AFLT",
      "MTLR"
    }
  }
end

-- TODO: add history/depth
local buildRankedTable = function (watchList, period, daysBack)

  -- open datasources for the securities in the watch list
  local securityList = {}
  for classCode, secCodes in pairs(watchList) do
    for _, secCode in ipairs(secCodes) do
      local datasource = _G.CreateDataSource(classCode, secCode, _G.INTERVAL_D1)
      datasource:SetEmptyCallback()
      table.sinsert(securityList, {
        classCode = classCode,
        secCode = secCode,
        datasource = datasource
      })
    end
  end
  sleep(1000)

  -- build the table
  local daysBack = daysBack or 0
  local result = {}
  
  for _, security in ipairs(securityList) do
  
    local datasource = security.datasource
    local lastCandleIndex = datasource:Size()
    local close = datasource:C(lastCandleIndex)
    local periodAgoCandleIndex = lastCandleIndex - period - daysBack
    local closePeriodAgo = datasource:C(periodAgoCandleIndex)
    local closeTwoPeriodsAgo = datasource:C(periodAgoCandleIndex - period)
    datasource:Close()
	
    table.sinsert(result, {
      classCode = security.classCode,
      secCode = security.secCode,
      close = close,
      closePeriodAgo = closePeriodAgo,
      difference = getPercentDiff(closePeriodAgo, close),
      differencePeriodAgo = getPercentDiff(closeTwoPeriodsAgo, closePeriodAgo)
    })
  end
  
  table.ssort(result, function (a, b) return a.differencePeriodAgo > b.differencePeriodAgo end)
  for i, entry in ipairs(result) do
    entry.prevRank = i
  end
  
  table.ssort(result, function (a, b) return a.difference > b.difference end)
  
  return result
end

-----

local settings = {
  color = {
    new = _G.RGB(0, 255, 0),
    old = _G.RGB(255, 255, 0),
    out = _G.RGB(255, 0, 0)
  },
  daysBack = 0,
  top = 8,
  period = 5 -- trading week
}

function main ()

  local t_id = _G.AllocTable()
  _G.AddColumn(t_id, 0, "Ticker", true, QTABLE_STRING_TYPE, 10) -- ticker
  _G.AddColumn(t_id, 1, "Close", true, QTABLE_DOUBLE_TYPE, 30) -- close
  _G.AddColumn(t_id, 2, "Prev. week close", true, QTABLE_DOUBLE_TYPE, 30) -- close on prev. week
  _G.AddColumn(t_id, 3, "% diff", true, QTABLE_DOUBLE_TYPE, 20) -- % difference
  _G.AddColumn(t_id, 4, "Rank", true, QTABLE_INT_TYPE, 20) -- rank
  _G.AddColumn(t_id, 5, "Prev. Rank", true, QTABLE_INT_TYPE, 20) -- previous rank
  _G.CreateWindow(t_id)
  _G.SetWindowCaption(t_id, "BWS")
  
  local rankedTable = buildRankedTable(getWatchList(), settings.period, settings.daysBack)
  
  -- insert the rows
  for rank, security in ipairs(rankedTable) do

    local row_id = InsertRow(t_id, -1)
    SetCell(t_id, row_id, 0, security.secCode)
    SetCell(t_id, row_id, 1, tostring(security.close), security.close)
    SetCell(t_id, row_id, 2, tostring(security.closePeriodAgo), security.closePeriodAgo)
    SetCell(t_id, row_id, 3, string.format("%.2f", security.difference), security.difference)
    SetCell(t_id, row_id, 4, tostring(rank), rank)
    SetCell(t_id, row_id, 5, tostring(security.prevRank), security.prevRank)
  
    -- determine the row's color
    local color = nil
    if rank > settings.top then
      if security.prevRank <= settings.top then 
        color = settings.color.out
      end
    else
      if security.prevRank > settings.top then 
        color = settings.color.new
      else
        color = settings.color.old
      end    
    end
  
    if color then _G.SetColor(t_id, row_id, _G.QTABLE_NO_INDEX, color, _G.QTABLE_DEFAULT_COLOR, _G.QTABLE_DEFAULT_COLOR, _G.QTABLE_DEFAULT_COLOR) end
  end
end
