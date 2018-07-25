local socket = ngx.socket.tcp
local cjson = require('cjson')
local defer = require('util.defer')
local assert = assert

local _M = {}

local function send_data(jsonData)
  local s = assert(socket())
  assert(s:connect('unix:/tmp/prometheus-nginx.socket'))
  assert(s:send(jsonData))
  assert(s:close())
end

function _M.encode_nginx_stats()
  return cjson.encode({
    host = ngx.var.host or "-",

    method = ngx.var.request_method or "-",
    path = ngx.var.location_path or "-",

    status = ngx.var.status or "-",

    requestLength = tonumber(ngx.var.request_length) or -1,
    requestTime = tonumber(ngx.var.request_time) or -1,

    responseLength = tonumber(ngx.var.bytes_sent) or -1,

    endpoint = ngx.var.upstream_addr or "-",

    upstreamLatency = tonumber(ngx.var.upstream_connect_time) or -1,
    upstreamResponseTime = tonumber(ngx.var.upstream_response_time) or -1,
    upstreamResponseLength = tonumber(ngx.var.upstream_response_length) or -1,
    upstreamStatus = ngx.var.upstream_status or "-",

    namespace = ngx.var.namespace or "-",
    ingress = ngx.var.ingress_name or "-",
    service = ngx.var.service_name or "-",
  })
end

function _M.call()
  local ok, err = defer.to_timer_phase(send_data, _M.encode_nginx_stats())
  if not ok then
    ngx.log(ngx.ERR, "failed to defer send_data to timer phase: ", err)
    return
  end
end

return _M
