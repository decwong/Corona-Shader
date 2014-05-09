-- [[ based on http://greweb.me/2012/05/illuminated-js-2d-lights-and-shadows-rendering-engine-for-html5-applications/
display.setStatusBar( display.HiddenStatusBar )

local swCaster = require "swcaster.engine"
local swLigth = require "swcaster.light"
local swShape = require "swcaster.shape"

local magnet = require "lib.magnet"
local looper = require "lib.looper"
local inspect = require "lib.inspect"

local memory = require("memory")

local loop = nil

local background = display.newImageRect("img/background2.png", magnet.screenWidth, magnet.screenHeight)
magnet:center(background)

swCaster:init(display.contentCenterX, display.contentCenterY, 800, 600)
swCaster:toFront()

local star = swShape.newPolygon({
				x = 50,
				y = 50,
				vectors = {  339, 316  ,  321, 295  ,  315, 274  ,  319, 250  ,  372, 271  ,  381, 303  },
				fill = { type = "image", filename = "img/concreteTexture.png"},
				})
				--[[,
				
				swShape.newPolygon({
				x = 50,
				y = 50,
				vectors = {-720, -193  ,  -629, -179  ,  -622, -133  ,  -682, -137  ,  -720, -144 },
				fill = { type = "image", filename = "img/concreteTexture.png"},
				}),
				
				swShape.newPolygon({
				x = 50,
				y = 50,
				vectors = {-535, -188  ,  -528, -146  ,  -622, -133  ,  -629, -179 },
				fill = { type = "image", filename = "img/concreteTexture.png"},
				}),
				
				swShape.newPolygon({
				x = 50,
				y = 50,
				vectors = {-468, -200  ,  -392, -184  ,  -458, -159  ,  -528, -146  ,  -535, -188 },
				fill = { type = "image", filename = "img/concreteTexture.png"},
				}),
				
				swShape.newPolygon({
				x = 50,
				y = 50,
				vectors = {-412, -225  ,  -344, -215  ,  -392, -184  ,  -468, -200 },
				fill = { type = "image", filename = "img/concreteTexture.png"},
				}),
				
				swShape.newPolygon({
				x = 50,
				y = 50,
				vectors = {-379, -255  ,  -319, -250  ,  -344, -215  ,  -412, -225 },
				fill = { type = "image", filename = "img/concreteTexture.png"},
				}),	
				
				swShape.newPolygon({
				x = 50,
				y = 50,
				vectors = {-319, -250  ,  -379, -255  ,  -372, -271 },
				fill = { type = "image", filename = "img/concreteTexture.png"},
				}),]]--
			
			
swCaster:addShape(star)

--[[
for i=1, #star do			
	swCaster:addShape(star[i])
	print("added", star[i])
end
]]--


local circle = swShape.newCircle({x=-50, y=0, radius = 15.000})
swCaster:addShape(circle)

--[[
local light1 = swLigth.new({ 
	x = -30,
	y = 30, 
	color = swLigth.colors.black,	
	radius = 10,
	distance = 150, 
	samples = 8,
})
swCaster:addLight(light1)
]]--

local light2 = swLigth.new({ 
	x = 0,	
	y = 0, 
	color = swLigth.colors.black, 
	radius = 50, 
	distance = 100, 
	samples = 1,
	})
swCaster:addLight(light2)


--[[
local star = swShape.newPolygon({
	x = 0,
	y = 0,
	vectors = {0,-110, 27,-35, 105,-35, 43,16, 65,90, 0,45, -65,90, -43,15, -105,-35, -27,-35},
	fill = { type = "image", filename = "img/concreteTexture.png"},
	})
swCaster:addShape(star)
]]--

local rectangle = swShape.newRectangle({
	x = -80,
	y = -80,
	width = 30,
	height = 20,
	fill = { type = "image", filename = "img/concreteTexture2.png"}
})
swCaster:addShape(rectangle)

local rectangle = swShape.newRectangle({
	x = 50,
	y = 50,
	width = 30,
	height = 20,
	fill = { type = "image", filename = "img/concreteTexture2.png"}
})
swCaster:addShape(rectangle)

local rotLight = 0


local onLoop = function(e, loop)
	--light1.position.x = 15 * math.cos(math.rad(rotLight)) 
	--light1.position.y = 15 * math.sin(math.rad(rotLight))

	light2.position.x = 15 * math.cos(math.rad(rotLight)) 
	light2.position.y = 15 * math.sin(math.rad(rotLight))

	rotLight = rotLight + loop.delta * 0.05
	swCaster:update()
end

loop = looper:newLoop(onLoop)
loop:resume()


local function runMem(event)
	memory.monitorMem()
end

Runtime:addEventListener("enterFrame", runMem)

