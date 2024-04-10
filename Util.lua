Util = {}

function Util.parseCSVLine(line)
  local result, field, inQuotes = {}, "", false
  local lineLength = string.len(line)
  local i = 1

  while i <= lineLength do
      local char = string.sub(line, i, i)
      local nextChar = string.sub(line, i + 1, i + 1)

      if char == '"' then
          if inQuotes and nextChar ~= '"' then
              inQuotes = false
          elseif not inQuotes then
              inQuotes = true
          else
              field = field .. char
              i = i + 1
          end
          i = i + 1
      elseif char == ',' and not inQuotes then
          table.insert(result, field)
          field = ""
          i = i + 1
      else
          field = field .. char
          i = i + 1
      end
  end

  table.insert(result, field)
  return result
end

function Util.parseCSVData(csvData)
  local result = {}
  local header = true
  local columns = {}
  if not csvData then return false end
  
  -- Split the CSV data into lines
  for line in string.gmatch(csvData, '([^\r\n]+)') do
      if header then
          -- Parse the first line to get column headers, lowercase
          columns = Util.parseCSVLine(line)
          for i,v in ipairs(columns) do
            columns[i] = string.lower(v)
          end
          header = false
      else
          -- Parse subsequent lines and store them in a table
          local values = Util.parseCSVLine(line)
          local row = {}
          for i, value in ipairs(values) do
              -- Associate each value with its corresponding column name
              row[columns[i]] = value
          end
          table.insert(result, row)
      end
  end

  return result
end

function Util.isTableEmpty(t)
  for _ in pairs(t) do
      return false -- Found an element, the table is not empty
  end
  return true -- No elements found, table is empty
end
