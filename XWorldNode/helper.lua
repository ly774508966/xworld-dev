
helper = {}

local h2b = {
    ["0"] = 0,
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["A"] = 10,
    ["B"] = 11,
    ["C"] = 12,
    ["D"] = 13,
    ["E"] = 14,
    ["F"] = 15
}
function helper.hex2bin( hexstr )
    --local s = string.gsub(hexstr, "(.)(.)%s", function ( h, l )
    --     return string.char(h2b[h]*16+h2b[l])
    --end)

	--检查字符串长度
	if hexstr:len()%2 ~= 0 then
	    return nil,"str2hex invalid input lenth"
	end
	local index=1
	local ret=""
	for index=1,hexstr:len(),2 do
	    ret=ret..string.char(tonumber(hexstr:sub(index,index+1),16))
	end

    return ret
end

function helper.bin2hex(buf, len)
    local ret = ""
	local i = 1
	if buf == nil then
		return "nil"
	end
	for i = 1, len do
		ret = ret..string.format("%02x", buf:sub(i):byte())
	end
	
	return ret--string.gsub(s,"(.)",function (x) return string.format("%02X ",string.byte(x)) end)
end

--直接打印到屏幕
function printTable(t, n)
  if "table" ~= type(t) then
    return 0;
  end
  n = n or 0;
  local str_space = "";
  for i = 1, n do
    str_space = str_space.."  ";
  end
  print(str_space.."{");
  for k, v in pairs(t) do
    local str_k_v
    if(type(k)=="string")then
      str_k_v = str_space.."  "..tostring(k).." = ";
    else
      str_k_v = str_space.."  ["..tostring(k).."] = ";
    end
    if "table" == type(v) then
      print(str_k_v);
      printTable(v, n + 1);
    else
      if(type(v)=="string")then
        str_k_v = str_k_v.."\""..tostring(v).."\"";
      else
        str_k_v = str_k_v..tostring(v);
      end
      print(str_k_v);
    end
  end
  print(str_space.."}");
end