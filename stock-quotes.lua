local wezterm = require "wezterm"
local util = require "util.util"
local stock_quotes = {}

local indexes = {"^DJI", "^IXIC", "^GSPC"}
local arrow_down = wezterm.nerdfonts.cod_arrow_small_down
local arrow_up = wezterm.nerdfonts.cod_arrow_small_up

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

function get_stock_quotes(config)
    stock_quote_data = {}
    market_data = util.json_parse(config["status_bar"]["stock_quotes"]["data_file"])
    if market_data ~= nil then
        for symbol, data in pairs(market_data["symbols"]) do
            if not util.has_value(indexes, symbol) then
                if util.has_value(config["status_bar"]["stock_quotes"]["symbols"], symbol) then
                    if data["price"] ~= nil and data["last"] ~= nil then
                        local price = data["price"]
                        local last = data["last"]
                        if price > last then
                            updown_arrow = arrow_up
                            updown_amount = string.format("%.2f", price - last)
                            pct_change = string.format("%.2f", ((price - last) / last) * 100)
                        else
                            updown_arrow = arrow_down
                            updown_amount = string.format("%.2f", last - price)
                            pct_change = string.format("%.2f", ((last - price) / last) * 100)
                        end
                        stock_quote = wezterm.nerdfonts.cod_graph_line .. " " .. symbol .. " $" .. price .. " " .. updown_arrow .. "$" .. updown_amount .. " (" .. pct_change .. "%)"
                        table.insert(stock_quote_data, util.pad_string(2, 2, stock_quote))
                    end
                end
            end
        end
        if #stock_quote_data > 0 then
            return stock_quote_data
        end
    end
    return nil
end

function get_stock_indexes(config)
    index_data = {}
    market_data = util.json_parse(config["status_bar"]["stock_quotes"]["data_file"])
    if market_data ~= nil then
        for symbol, data in pairs(market_data["symbols"]) do
            if util.has_value(indexes, symbol) then
                if data["price"] ~= nil and data["last"] ~= nil then
                    local price = data["price"]
                    local last = data["last"]
                    if price > last then
                        updown_arrow = arrow_up
                        updown_amount = string.format("%.2f", price - last)
                        pct_change = string.format("%.2f", ((price - last) / last) * 100)
                    else
                        updown_arrow = arrow_down
                        updown_amount = string.format("%.2f", last - price)
                        pct_change = string.format("%.2f", ((last - price) / last) * 100)
                    end
                    if symbol == "^DJI" then
                        if config["status_bar"]["stock_quotes"]["indexes"]["show_djia"] then
                            table.insert(index_data, "DOW " .. updown_arrow .. " " .. pct_change .. "%")
                        end
                    elseif symbol == "^IXIC" then
                        if config["status_bar"]["stock_quotes"]["indexes"]["show_nasdaq"] then
                            table.insert(index_data, "Nasdaq " .. updown_arrow .. " " .. pct_change .. "%")
                        end
                    elseif symbol == "^GSPC" then
                        if config["status_bar"]["stock_quotes"]["indexes"]["show_sp500"] then
                            table.insert(index_data, "S&P 500 " .. updown_arrow .. " " .. pct_change .. "%")
                        end
                    end
                end
            end
        end
        if #index_data > 0 then
            return wezterm.nerdfonts.cod_graph_line .. " " .. table.concat(index_data, "; ")
        end
    end
    return nil
end

stock_quotes.get_stock_indexes = get_stock_indexes
stock_quotes.get_stock_quotes = get_stock_quotes
stock_quotes.update_json = update_json

return stock_quotes
