local time = {}

function get_timestamp()
    return os.time()
end

function get_hms()
    time = os.date("*t")
    return time.hour, time.min, time.sec
end

time.get_hms = get_hms
time.get_timestamp = get_timestamp

return time