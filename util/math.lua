local math = {}

function divide(a, b)
    local quotient = math.floor(a / b)
    local remainder = a % b
    return quotient, remainder
end

math.divide = divide

return math
