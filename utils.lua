-- Represents a pair of integers as a string
function getString(fst, snd)
   return string.format("(%d,%d)", fst, snd)
end

-- Extracts the two numbers from the string reprepresentation
function getNumbers(action)
   x, y = unpack(string.split(string.sub(action, 2, #action-1), ","))
   return tonumber(x), tonumber(y)
end
