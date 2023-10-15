-- Create a base class representing a shape
Shape = {}

function Shape:new()
    local object = {}
    setmetatable(object, self)
    self.__index = self
    return object
end

function Shape:area()
    return 0 -- Default implementation
end

-- Create subclasses for specific shapes
Circle = {}
setmetatable(Circle, { __index = Shape })

function Circle:new(radius)
    local object = Shape:new()
    setmetatable(object, self)
    self.__index = self
    object.radius = radius
    return object
end

function Circle:area()
    return math.pi * self.radius * self.radius -- Override area calculation
end

Rectangle = {}
setmetatable(Rectangle, { __index = Shape })

function Rectangle:new(width, height)
    local object = Shape:new()
    setmetatable(object, self)
    self.__index = self
    object.width = width
    object.height = height
    return object
end

function Rectangle:area()
    return self.width * self.height -- Override area calculation
end

-- Create instances of different shapes
local circle = Circle:new(5)
local rectangle = Rectangle:new(4, 6)

-- Function to calculate and display the area of a shape
function calculateAndDisplayArea(shape)
    print("Area:", shape:area())
end

-- Calculate and display areas of different shapes
calculateAndDisplayArea(circle)
calculateAndDisplayArea(rectangle)

