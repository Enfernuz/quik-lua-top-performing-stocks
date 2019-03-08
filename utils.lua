local utils = {}

function utils.getPercentDiff (x0, x1)
  return 100.0 * (x1 - x0) / x0
end

function utils.formatDate (dt)
  return os.date("%d.%m.%Y", os.time{year = dt.year, month = dt.month, day = dt.day})
end

function utils.formatDateTime (dateTime)
  return os.date("%d.%m.%Y %H:%M:%S", dateTime and os.time{year = dateTime.year, month = dateTime.month, day = dateTime.day, hour = dateTime.hour, min = dateTime.min, sec = dateTime.sec} or os.time())
end

function utils.calculateStopLossPrice (args)
  return args.close - (2 * args.avgDailyVol * args.close / 100.0)
end

function utils.getSecurityParams (classCode, secCode)

  local dbName = "SEC_SCALE"
  local result = {}
  
  if ParamRequest(classCode, secCode, dbName) then
  result.scale = tonumber(getParamEx2(classCode, secCode, dbName).param_value)
  else
    error(string.format("Не удалось выполнить запрос на получение параметров: ParamRequest(class_code=%s, sec_code=%s, db_name=%s)", classCode, secCode, dbName))
  end
    
  if not CancelParamRequest(classCode, secCode, dbName) then
    error(string.format("Не удалось выполнить запрос на отмену получения параметров: CancelParamRequest(class_code=%s, sec_code=%s, db_name=%s)", classCode, secCode, dbName))
  end
  
  return result
end

return utils
