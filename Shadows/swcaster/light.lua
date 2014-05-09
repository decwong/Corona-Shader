--Light
local Vec2 = require "lib.vectors"

local Inspect = require "lib.inspect"
--cache
local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin

local GOLDEN_ANGLE = math.pi * (3 - sqrt(5))
local _2PI = 2 * math.pi

local Light = {}

Light.colors = {
	white 	= {	1, 		1, 		1     },
	yellow 	= {	1, 		0.8, 	0 	  },
	red 	= { 1,		0,		0	  },
	black 	= { 0,		0, 		0	  },
}

function Light.new( params )
	local self = {}
	--set params if defined otherwise set default properties
	params = params or {}

	self.position 	= Vec2.new(params.x, params.y)
	self.radius 	= params.radius or 2
	self.angle		= params.angle or 0
	self.samples 	= params.samples or 1
	self.distance 	= params.distance or 100
	self.diffuse 	= params.diffuse or 0.8
	self.intensity	= params.intensity or 0.5
	self.roughness	= params.roughness or 0
	self.color 		= params.color or Light.colors.white
	self._light		= nil
	self._mask		= nil
	self._shapes	= {}
	self._shapesDic = {}

	function self:center()
		return Vec2.new(self.distance, self.distance)
	end

	function self:getBounds()
		local orientationCenter = Vec2.new(cos(self.angle), -sin(self.angle)) * (self.distance * self.roughness)
		return {
			topLeft = Vec2.new(self.position.x + orientationCenter.x - self.distance, self.position.y + orientationCenter.y - self.distance),
			bottomRight = Vec2.new(self.position.x + orientationCenter.x + self.distance, self.position.y + orientationCenter.y + self.distance),
		}
	end

	function self:cast()
		local nSamples = self.samples
		local bounds = self:getBounds()
		local shapes = self._shapes
		self:forEachSample(function(position)
			local sampleInShape = false
			for _, shape in ipairs(shapes) do
				if shape:contains( position ) then
					--print("light is touching shape")
					return false
				end
			end
			for _, shape in ipairs(shapes) do
				shape:cast(position, bounds)
			end
		end)

	end

	function self:forEachSample( func )
		for sample = 0, self.samples - 1 do
			local a = sample * GOLDEN_ANGLE
			local r = sqrt(sample / self.samples) * self.radius
			local delta = Vec2.new(cos(a) * r, sin(a) * r)
			func(self.position + delta)		
		end
	end
	
	function self:addShapes( tShapes )
		for _, shape in ipairs(tShapes) do
			if self._shapesDic[shape] == nil then
				--print("shape added:", shape)
				self._shapes[#self._shapes + 1] = shape
				self._shapesDic[shape] = shape
			end
		end
	end

	--[[
	function _createRadialGradient( tColor, size)
		local gradient = display.newCircle(0, 0, size)
		gradient.fill.effect = "generator.radialGradient"	
		local fx = gradient.fill.effect
		fx.center_and_radiuses =  { 0.5, 0.5, 0, 0.5 } 
		fx.color1 = { tColor.c1[1], tColor.c1[2], tColor.c1[3], 0.9 }
		fx.color2 = { 0, 0, 0, 0 }
		gradient.alpha = 0.8
		return gradient
	end
	--]]
	function _createLight()
		local g = display.newGroup()
		g.reflection = display.newImageRect(g, "img/lightMask.png", 256, 256)
		g.reflection.fill.effect = "composite.difference"
		return g
	end

	function _createMask()
		local m = display.newImageRect("img/lightSpot.png", 256, 256)
		m.blendMode = "dstOut"
		return m
	end

	function self:recalculateLight()
		self._light = self._light or _createLight()
		
		local light = self._light
		local color = self.color

		light.reflection.width = self.distance * 2
		light.reflection.height = self.distance * 2
		light.reflection:setFillColor(color[1], color[2], color[3])
		light.reflection.alpha = 1

		light.alpha = 0.5
	end

	function self:recalculateMask()
		self._mask = self._mask or _createMask()
		local mask = self._mask
		--mask.alpha = 0.5
		mask.width = self.distance * 30
		mask.height = self.distance * 30
	end

	function self:setMaskParent( parent )
		parent:insert( self._mask )
	end

	function self:setLightParent( parent )
		parent:insert( self._light )
	end

	function self:update()
		--self:recalculateLight()
		--self:recalculateMask()
		self._light.x 	= self.position.x
		self._light.y 	= self.position.y
		self._mask.x 	= self.position.x
		self._mask.y 	= self.position.y
		self:cast()
	end

	self:recalculateLight()
	self:recalculateMask()
	return self
end


return Light