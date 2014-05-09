local Vec2 = require "lib.vectors"

local Inspect = require "lib.inspect"

--cache
local max 		= math.max
local min 		= math.min
local sqrt 		= math.sqrt
local abs 		= math.abs
local atan2 	= math.atan2
local acos 		= math.acos
local sin 		= math.sin
local cos 		= math.cos
local deg 		= math.deg
local rad 		= math.rad
local tRemove 	= table.remove
local tInsert 	= table.insert
--shapes
local Shape = {}

local prototype = {
	shadowGroup,
	tPaths = {},
}

function prototype:setShapeParent( parent )
	parent:insert(self._shape)
end

function prototype:setShadowParent( parent )
	self.shadowGroup = parent
end

--[[
function prototype:bounds()
	local topLeft = self.points[1]:copy()
	local bottomRight = topLeft:copy()
	for _, p in ipairs(self.points) do
		bottomRight.x = max(bottomRight.x, p.x)
		bottomRight.y = max(bottomRight.y, p.y)
		topLeft.x = min(topLeft.x, p.x)
		topLeft.y = min(topLeft.y, p.y)
	end
	return { topLeft = topLeft, bottomRight = bottomRight}
end
--]]
function prototype:contains( point )
	local oddNodes = false
	local x, y = point.x, point.y
	local j = #self.points
	local pC, pT = nil, nil
	for i = 1, #self.points do
		pC = self.points[i]
		pT = self.points[j]
		if ((pC.y < y and pT.y >= y or pT.y < y and
			 pC.y >= y) and (pC.x <= x or pT.x <= x)) then
			if (pC.x + (y - pC.y) / (pT.y - pC.y) * pT.x - pC.x) < x then
				oddNodes = not oddNodes
			end
		end
		j = i
	end
	return oddNodes
end

local distance = function(x1, y1, x2, y2)
	return sqrt( (x1 - x2 ) ^ 2 + (y1 - y2) ^ 2 )
end

local intersects = function(tVectors, pX, pY)
	local prevX, prevY, currPX, currPY
	local dist
	local intersects = false

	if #tVectors >= 4 then
		for i = 1, #tVectors, 2 do
			currPX = tVectors[i]
			currPY = tVectors[i + 1]
			if prevPX then
				dist = distance(currPX, currPY, prevPX, prevPY )
				if dist == distance(pX, pY, currPX, currPY) + distance(pX, pY, prevPX, prevPY) or 
					(pX == currPX and pY == currPY) or (pX == prevPX and pY == prevPY) then
					--print("intersects!")
					intersects = true
					break
				end
			end
			prevPX, prevPY = currPX, currPY
		end
	end
	return intersects
end

function prototype:newPath( tPath, origin )
	local vectorPath = {}
		
	local xLow, yLow = tPath[1].x, tPath[1].y
	local xHigh, yHigh = tPath[1].x, tPath[1].y
	
	for _, point in ipairs(tPath) do
		if not intersects(vectorPath, point.x, point.y) then
			vectorPath[#vectorPath + 1] = point.x
			vectorPath[#vectorPath + 1] = point.y
			xLow = min(point.x, xLow)
			xHigh = max(point.x, xHigh)
			yLow = min(point.y, yLow)
			yHigh = max(point.y, yHigh)
		end
	end

	local path = display.newPolygon(0, 0, vectorPath)
	
	path.x = (xHigh - xLow) * 0.5 + xLow
	path.y = (yHigh - yLow) * 0.5 + yLow

	if self.shadowGroup then
		self.shadowGroup:insert(path)
	end

	path.alpha = 0.1
	path.blendMode = "multiply"
	path.fill = { type = "image", filename = "img/squareGradient.png" }
	
	local angle = atan2(origin.y - path.y, origin.x - path.x)
	angle = deg( angle )
	path.fill.rotation = angle + 90
	self.tPaths[#self.tPaths + 1] = path
end


function prototype:clearPaths()
	local p = nil
	for i = #self.tPaths, 1, -1 do
		p = tRemove( self.tPaths, i )
		p:removeSelf()
		p = nil
	end
end

function prototype:forEachVisibleEdges(origin, bounds, func)
	local a = self.points[#self.points]
	for _, b in ipairs(self.points) do
		if a:inBound(bounds.topLeft, bounds.bottomRight) then	
			local originToA = a - origin
			local originToB = b - origin
			local aToB = b - a
			local normal = Vec2.new(aToB.y, -aToB.x)
			if (normal:dotproduct(originToA) < 0) then
				self.closestPoint = self.closestPoint or a
				func(a, b, originToA, originToB, aToB)
			end
		end
		a = b
	end
end

function prototype:cast(origin, bounds)
	self.closestPoint = nil
	local distance = ((bounds.bottomRight.x - bounds.topLeft.x) + (bounds.bottomRight.y - bounds.topLeft.y)) / 2
	self:forEachVisibleEdges(origin, bounds, function(a, b, originToA, originToB, aToB)
		local m
		local t = originToA:invert():dotproduct(aToB) / aToB:lenSqrt()
		
		if t < 0 then
			m = a
		elseif t > 1 then
			m = b
		else
			m = a + ( aToB * t )
		end
		local originToM = m - origin
		--normalize distance
		originToM = originToM:normalize() * distance
		originToA = originToA:normalize() * distance
		originToB = originToB:normalize() * distance
		--project points
		local oam = a + originToM
		local obm = b + originToM
		local ap = a + originToA
		local bp = b + originToB
		--print("PATH:", a, b, bp, obm, oam, ap)	
		self:newPath( {a, b, bp, obm, oam, ap}, origin )
	end)
end

--Rotation
function rotatePoint( point, angle, origin)
	local tV = point - origin
	local nV = Vec2.new()
	nV.x = tV.x * cos(angle) - tV.y * sin(angle)
	nV.y = tV.x * sin(angle) + tV.y * cos(angle)
	return nV + origin
end 


function prototype:rotate( angle )
	local angleRadians = math.rad( angle )
	local origin = Vec2.new(0, 0)
	self._vectors = {}

	for _, p in ipairs(self.points) do
		local v = rotatePoint(p, angleRadians, origin)
		self._vectors[#self._vectors + 1] = v.x
		self._vectors[#self._vectors + 1] = v.y
	end
	self._shape:rotate(angle)
	self:updatePoints()
	self:syncProperties()
end

function prototype:updatePoints() 
end

function prototype:syncProperties()
		self._shape.x 		= self.position.x
		self._shape.y 		= self.position.y	
		self._shape.fill 	= self.fill
end

function prototype:init( params )
	--set params if defined otherwise set default properties
	params 				= params or {}
	self.position 		= Vec2.new( params.x, params.y )
	self.fill 			= params.fill or {1, 1, 1}
end

-- RECTANGLE
function Shape.newRectangle( params )
	local self = {}
	setmetatable(self, {__index = prototype})

	self:init( params )
	self.width 			= params.width or 1
	self.height 		= params.height or 1
	self.topLeft 		= Vec2.new( self.position.x, self.position.y )
	self.bottomRight 	= Vec2.new( self.position.x + self.width, self.position.y + self.height )
	
	self._shape 		= display.newRect(0, 0, self.width, self.height)
	self._shape.anchorX = 0
	self._shape.anchorY = 0
	
	function self:updatePoints()
		self.points = {
			[1] = self.topLeft,
			[2] = Vec2.new(self.bottomRight.x, self.topLeft.y),
			[3] = self.bottomRight,
			[4] = Vec2.new(self.topLeft.x, self.bottomRight.y),
		}
	end
	
	self:updatePoints()
	self:syncProperties()
	return self
end

-- POLYGON
function Shape.newPolygon( params )
	local self = {}
	setmetatable(self, {__index = prototype})
		
	self:init( params )
	self._vectors		= params.vectors
	self._shape 		= display.newPolygon(0, 0, self._vectors)
	
	
	function self:updatePoints()
		self.points = {}
		local xLow, xHigh = self._vectors[1], self._vectors[1]
		local yLow, yHigh = self._vectors[1], self._vectors[1]

		for i = 1, #self._vectors, 2 do
			local x = self._vectors[i]
			local y = self._vectors[i + 1]
			self.points[#self.points + 1] = Vec2.new(x, y)
			xLow = min(x, xLow)
			xHigh = max(x, xHigh)
			yLow = min(y, yLow)
			yHigh = max(y, yHigh)
		end

		self.position.x = (xHigh - xLow) * 0.5 + xLow
		self.position.y = (yHigh - yLow) * 0.5 + yLow
	end

	self:updatePoints()
	self:syncProperties()
	return self
end

-- LINE ** TODO
function Shape.newLine( params )
	local self = {}
	setmetatable(self, {__index = prototype})
	
	self:init( params )
	
	self:syncProperties()
	return self
end

-- CIRCLE
function Shape.newCircle( params )
	local self = {}
	setmetatable(self, {__index = prototype})
	self:init( params )
	self.radius			= params.radius or 2
	self._shape 		= display.newCircle(0, 0, self.radius)
	
	function self:getTan2( radius, center )
		local solutions = {}

		local soln, len2radius, tt, nt, tt_cos, tt_sin, 
		nt_cos, nt_sin, dist0, dist1, dist2, dist3
		local epsilon = 1e-6
		local x0, y0 = center.x, center.y		
		local len2 = center:lenSqrt()
		
		len2radius = y0 * sqrt(len2 - radius * radius)
		tt = acos((-radius * x0 + len2radius) / len2)
		nt = acos((-radius * x0 - len2radius) / len2)
		tt_cos = radius * cos(tt)
		tt_sin = radius * sin(tt)
		nt_cos = radius * cos(nt)
		nt_sin = radius * sin(nt)

		soln = Vec2.new(x0 + nt_cos, y0 + nt_sin)
		tInsert(solutions, soln)
		dist0 = soln:lenSqrt()

		soln = Vec2.new(x0 + tt_cos, y0 - tt_sin)
		tInsert(solutions, soln)
		dist1 = soln:lenSqrt()
		
		if abs(dist0 - dist1) < epsilon then return solutions end

		soln = Vec2.new(x0 + nt_cos, y0 - nt_sin)
		tInsert(solutions, soln)
		dist2 = soln:lenSqrt()
		--print("dist2:",dist2)
		if abs(dist1 - dist2) < epsilon then return { soln, solutions[2] } end
		if abs(dist0 - dist2) < epsilon then return { solutions[1], soln } end

		soln = Vec2.new(x0 + tt_cos, y0 + tt_sin)
		tInsert(solutions, soln)
		dist3 = soln:lenSqrt()
		--print("dist3:",dist3)

		if abs(dist2 - dist3) < epsilon then return { solutions[3], soln } end
		if abs(dist1 - dist3) < epsilon then return { solutions[2], soln } end
		if abs(dist0 - dist3) < epsilon then return { solutions[1], soln } end

		return solutions
	end

	function self:contains( point )
		return point:distance2(self.position) < self.radius * self.radius
	end

	function self:cast( origin, bounds )
		--normalize to distance
		local distance = ((bounds.bottomRight.x - bounds.topLeft.x) + (bounds.bottomRight.y - bounds.topLeft.y)) / 2
		local dt = self.position:distance(origin) - (self.radius * 2) - distance / 2
		if dt < 0 then
			local m, originToM, originToA, originToB, a, b,	oam, obm, ap, bp, start, tangentLines
	
			m = self.position
			originToM = m - origin

			tangentLines = self:getTan2(self.radius, originToM)
			--print(tangentLines[1], tangentLines[2], tangentLines[3], tangentLines[4])
			originToA = tangentLines[1]
			originToB = tangentLines[2]
			a = originToA + origin
			b = originToB + origin
		
			originToM = originToM:normalize() * distance
			originToA = originToA:normalize() * distance
			originToB = originToB:normalize() * distance

			--project points
			oam = a + originToM
			obm = b + originToM
			ap 	= a + originToA
			bp 	= b + originToB

			--print("PATH VERTICES:", b, bp, obm, oam, ap, a)
			self:newPath( { b, bp, obm, oam, ap, a }, origin )
		end
	end
	self:syncProperties()
	return self
end

return Shape