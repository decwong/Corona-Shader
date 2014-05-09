local Vec2 = require "lib.vectors"

local engine = display.newGroup()

local tLights
local tShapes
local snapshotGround
local snapshotMask

function engine:updateLightShapes()
	for _, light in ipairs(tLights) do
		light:addShapes( tShapes )
	end
end

function engine:addLight( object )
	tLights[#tLights + 1] = object
	object:setMaskParent( snapshotMask.group)
	object:setLightParent( tLights.group )
	self:updateLightShapes()
end

function engine:addShape( object )
	tShapes[#tShapes + 1] = object
	object:setShapeParent( tShapes.shapesGroup )
	object:setShadowParent( tShapes.shadowsGroup )
	self:updateLightShapes()
end

--local updateMask = false
function engine:update()
	for _, shape in ipairs(tShapes) do
		shape:clearPaths()
	end

	for _, light in ipairs(tLights) do
		light:update()
	end
	snapshotGround:invalidate()

	--if updateMask then
		snapshotMask:invalidate()
	--end
	--updateMask = not updateMask
end

function engine:init(x, y, width, height)
	width = width or display.contentWidth
	height = height or display.contentHeight
	
	snapshotGround 	= display.newSnapshot(engine, width, height)
	snapshotMask 	= display.newSnapshot(engine, width, height)
	local r = display.newRect(snapshotMask.group, 0, 0, width, height)
	r:setFillColor(0, 1)

	tLights = { group = display.newGroup() }
	tShapes = { shapesGroup = display.newGroup(), shadowsGroup = display.newGroup()	}	

	snapshotGround.group:insert(tShapes.shadowsGroup)
	snapshotGround.group:insert(tLights.group)
	snapshotGround.group:insert(tShapes.shapesGroup)

	engine.x = x or 0
	engine.y = y or 0
end

return engine
