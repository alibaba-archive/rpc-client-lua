local sha1 = require("sha1")
local json = require("dkjson")

-- Encodes a character as a percent encoded string
local function char_to_pchar(c)
  return string.format("%%%02X", c:byte(1,1))
end

-- encodeURIComponent escapes all characters except the following: alphabetic, decimal digits, - _ . ! ~ * ' ( )
local function encodeURIComponent(str)
  return string.gsub(str, "[^%w%-_%.%!%~%*%'%(%)]", char_to_pchar)
end

local function getKeys(t)
  local keys = {}
  for key in pairs(t) do
    keys[#keys + 1] = key
  end
  return keys
end

local function encode(str)
  return encodeURIComponent(str)
end

local function normalize(params)
  local list = {}
  local keys = getKeys(params)
  table.sort(keys)
  for _, key in pairs(keys) do
    local value = params[key]
    list[#list + 1] = {encode(key), encode(value)}
  end
  return list
end

local function canonicalize(normalized)
  local fields = {}
  for _, item in pairs(normalized) do
    fields[#fields + 1] = item[1] .. "=" .. item[2]
  end
  return table.concat(fields, "&")
end

local RPCClient = {}

function RPCClient:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  return o
end

math.randomseed(os.time())

function RPCClient:__getNonce()
  return math.floor(math.random(1000000000000))
end

function RPCClient:__getAccessKeyId()
  return self.__accessKeyId
end

function RPCClient:__getEndpoint()
  return self.__endpoint_host
end

function RPCClient:__getAccessKeySecret()
  return self.__accessKeySecret
end

function RPCClient:__defaultNumber(a, b)
  return a or b
end

function RPCClient:__default(a, b)
  return a or b
end

function RPCClient:__query(query)
  local result = {}
  local keys = getKeys(query)
  table.sort(keys)
  for _, key in pairs(keys) do
    local value = query[key]
    if type(value) == "table" then
      for vi, vv in pairs(value) do
        result[key..vi] = vv
      end
    else
      result[key] = value
    end
  end

  return result
end

-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
-- encoding
local function base64encode(data)
  return ((data:gsub('.', function(x)
    local r, b = '', x:byte()
    for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
    return r;
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if (#x < 6) then return '' end
    local c=0
    for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
    return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
end

function RPCClient:__getSignature(request)
  local method = string.upper(request["method"] or 'GET')
  local normalized = normalize(request.query)
  local canonicalized = canonicalize(normalized)
  -- 2.1 get string to sign
  local stringToSign = method .. "&" .. encode("/") .. "&" .. encode(canonicalized)
  -- print(stringToSign)
  -- 2.2 get signature
  local key = self.__accessKeySecret .. '&'
  return base64encode(sha1.sha1_bin(key, stringToSign))
end

function RPCClient:__getTimestamp()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

function RPCClient:__json(response)
  return json.decode(response.body)
end

function RPCClient:__hasError(json)
  return json["Code"] and not self.codes[json["Code"]]
end

return RPCClient
