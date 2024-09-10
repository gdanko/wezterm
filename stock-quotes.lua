local wezterm = require "wezterm"
local util = require "util.util"

local stock_quotes = {}

function update_json(config)
    needs_update = false
    exists, err = util.file_exists(config["data_file"])
    if exists then
        json_data = util.json_parse(config["data_file"])
        if json_data ~= nil then
            if (util.get_timestamp() - json_data["timestamp"]) > (config["freshness_threshold"] * 3600) then
                needs_update = true
            end
        end
    else
        needs_update = true
    end

    if needs_update then
        local data = {
            timestamp = util.get_timestamp(),
            symbols = {},
        }
        local symbols_table = {"^DJI", "^IXIC", "^GSPC"}
        for _, symbol in ipairs(config["symbols"]) do
            table.insert(symbols_table, symbol)
        end
        local url = "https://query1.finance.yahoo.com/v7/finance/spark?symbols=" .. table.concat(symbols_table, ",")
        success, stdout, stderr = wezterm.run_child_process({"curl", url})
        if success then
            json_data = util.json_parse_string(stdout)
            if json_data ~= nil then
                if json_data["spark"] ~= nil and json_data["spark"]["result"] ~= nil and #json_data["spark"]["result"] > 0 then
                    for _, block in ipairs(json_data["spark"]["result"]) do
                        symbol = block["symbol"]
                        if data["symbols"][symbol] == nil then
                            meta = block["response"][1]["meta"]
                            data["symbols"][symbol] = {}
                            data["symbols"][symbol]["price"] = meta["regularMarketPrice"]
                            data["symbols"][symbol]["last"] = meta["previousClose"]
                            data["symbols"][symbol]["currency"] = meta["currency"]
                            data["symbols"][symbol]["symbol"] = meta["symbol"]
                        end
                    end
                end
                file = io.open(config["data_file"], "w")
                file:write(wezterm.json_encode(data))
                file:close()
            end
        end
    end
end

stock_quotes.update_json = update_json

return stock_quotes
