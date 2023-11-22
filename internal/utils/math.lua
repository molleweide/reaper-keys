local numbers = {}

numbers.getRandomIndexInRange = function(minIndex, maxIndex)
  -- Calculate the random floating-point number between 0 and 1
  local randomFloat = math.random()
  -- Calculate the random index within the specified range
  local rangeSize = maxIndex - minIndex + 1
  local randomIndex = math.floor(randomFloat * rangeSize) + minIndex
  return randomIndex
end

return numbers
