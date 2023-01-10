local cjson = require("cjson.safe")
local ngx = require("ngx")
local ngx_re = require("ngx.re")
local http = require("resty.http")


local decode_args = ngx.decode_args
local exit = ngx.exit
local log = ngx.log
local say = ngx.say
local unescape_uri = ngx.unescape_uri

local req_get_headers = ngx.req.get_headers
local req_get_uri_args = ngx.req.get_uri_args
local req_read_body = ngx.req.read_body
local req_get_body_data = ngx.req.get_body_data


local DEBUG = false

local _M = {
    _VERSION = "0.0.1"
}

local function process(scheme, host, port)
    local ngx_query = req_get_uri_args()

    req_read_body()
    local ngx_body_data = req_get_body_data()
    local res = ngx_re.split(ngx_body_data, "\r\n")
    if not res then
        return exit(204)
    end

    local http_client = http.new()
    local flb_url = scheme .. "://" .. host .. ":" .. port
    for _, part in ipairs(res) do
        local body_opts = {}
        local e = decode_args(part)
        body_opts["name"] = e["en"]
        if e["en"] == "page_view" then
            body_opts["document_location"] = e["dl"]
            body_opts["document_title"] = e["dt"]
            body_opts["document_referrer"] = e["dr"]
        end
        body_opts["engagement_time"] = e["_et"]
        body_opts["protocol_version"] = ngx_query["v"]
        body_opts["tracking_id"] = ngx_query["tid"]
        body_opts["client_id"] = ngx_query["cid"]
        body_opts["screen_resolution"] = ngx_query["sr"]
        body_opts["user_language"] = ngx_query["ul"]
        body_opts["document_hostname"] = ngx_query["dh"]
        body_opts["user_agent_architecture"] = ngx_query["uaa"]
        body_opts["user_agent_bitness"] = ngx_query["uab"]
        body_opts["user_agent_full_version_list"] = unescape_uri(ngx_query["uafvl"])
        body_opts["user_agent_mobile"] = ngx_query["uamb"]
        body_opts["user_agent_platform"] = ngx_query["uap"]
        body_opts["user_agent_platform_version"] = ngx_query["uapv"]
        body_opts["user_agent_wow64"] = ngx_query["uaw"]

        local ngx_headers = req_get_headers()
        body_opts["ip"] = ngx_headers["X-REAL-IP"] or ngx_headers["X-FORWARDED-FOR"] or ngx.var.remote_addr

        local ok, flb_err = http_client:request_uri(flb_url, {
            method = "POST",
            body = cjson.encode(body_opts),
            headers = {
                ["Content-Type"] = "application/json",
            },
        })
        if not ok then
            log(ngx.ERR, flb_err)
        end
    end
--     ngx.say("ngx body", cjson.encode(ngx_body))

    return exit(204)
end

_M.process = process

return _M
