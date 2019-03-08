package.path = getScriptPath() .. '/?.lua;' .. package.path

local RankedWatchList = require('ranked_watch_list')

local settings = {
  color = {
    new = RGB(0, 255, 0),
    old = RGB(255, 255, 0),
    out = RGB(255, 0, 0)
  },
  daysBack = 0,
  top = 8,
  period = 5, -- trading week
}

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

-----

function main ()

  local tId = AllocTable()
  AddColumn(tId, 0, "Ticker", true, QTABLE_STRING_TYPE, 15) -- ticker
  AddColumn(tId, 1, "Close", true, QTABLE_DOUBLE_TYPE, 20) -- close
  AddColumn(tId, 2, "StopLoss", true, QTABLE_DOUBLE_TYPE, 20) -- recommended stop loss price
  AddColumn(tId, 3, "Prev. close", true, QTABLE_DOUBLE_TYPE, 20) -- close on prev. week
  AddColumn(tId, 4, "% diff", true, QTABLE_DOUBLE_TYPE, 15) -- % difference
  AddColumn(tId, 5, "Rank", true, QTABLE_INT_TYPE, 15) -- rank
  AddColumn(tId, 6, "Prev. Rank", true, QTABLE_INT_TYPE, 15) -- previous rank
  AddColumn(tId, 7, "Avg. daily vol", true, QTABLE_DOUBLE_TYPE, 20) -- avg. daily vol for 2 weeks
  
  CreateWindow(tId)
  
  local rankedWatchList = RankedWatchList:new(getWatchList(), settings)
  rankedWatchList:renderToTable(tId)
end
