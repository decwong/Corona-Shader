-- Magnet, Position Helper for Corona SDK G2.0
--
-- Author: Iván Juárez Núñez 2013
-- License: MIT 
-- Version: 2.0

-- THIS VERSION IS REALLY BUGGY. Positioning inside snapshots wont work because the parent
-- attribute do not exists in childs inside them. I could validate this by comparing the
-- object.parent to nil but I havent test all possible cases and I ignore if this could
-- happen with other display objects.

local magnet = {}

local width 	= display.actualContentWidth
local height 	= display.actualContentHeight
local originX 	= display.screenOriginX
local originY 	= display.screenOriginY

local abs = math.abs

--swap if landscape mode
if string.sub(system.orientation, 1, 9) == "landscape" then
	width, height = height, width	
end
-- exposed attr
magnet.screenWidth 	= width
magnet.screenHeight = height

--this is a hackysh solution: top stage is both currentStage and current view. There are inconsistencies on positioning an object
--inside currentView group, (0, 0) will set an object on topLeft corner while inside a group, container or snapshot
--will be on the center.
function isTopStage( obj )
	return obj.parent and (obj.parent == display.getCurrentStage() or obj.parent == display.getCurrentStage()[3])
end

-- POSITIONING
function magnet:top(obj, marginY)
	if obj.parent and not isTopStage(obj) then
		obj.y = - obj.parent.height * 0.5
	else
		obj.y = originY
	end
	obj.y = obj.y + (marginY or 0) + obj.anchorY * obj.height
end

function magnet:right(obj, marginX)
	if obj.parent and not isTopStage(obj) then
		obj.x = obj.parent.width * 0.5
	else
		obj.x = width - abs(originX)
	end
	obj.x = obj.x + (marginX or 0) - obj.anchorX * obj.width
end

function magnet:bottom(obj, marginY)
	if obj.parent and not isTopStage(obj) then
		obj.y = obj.parent.height * 0.5
	else
		obj.y = height - abs(originY)
	end
	obj.y = obj.y + (marginY or 0) - obj.anchorY * obj.height
end

function magnet:left(obj, marginX)
	if obj.parent and not isTopStage(obj) then
		obj.x = - obj.parent.width * 0.5
	else
		obj.x = originX
	end
	obj.x = obj.x + (marginX or 0) + obj.anchorX * obj.width
end

function magnet:center(obj, marginX, marginY)
	if not obj.parent then
		obj.x = 0
		obj.y = 0
	else
		obj.x = display.contentCenterX
		obj.y = display.contentCenterY
	end
	obj.x = obj.x + (marginX or 0)
	obj.y = obj.y + (marginY or 0)
end

-- RESIZE
function magnet:snapToParent(obj, top, right, bottom, left)
	top, right, bottom, left = top or 0, right or 0, bottom or 0, left or 0
	if obj.parent then
		obj.width = obj.parent.width - left - right
		obj.height = obj.parent.height - top - bottom
	else
		obj.width = width - left - right
		obj.height = height - top - bottom
	end
	self:topLeft(obj, left, top)
end

-- PERCENT POSITIONING
function magnet:getPercentX( percent )
	return width * (percent * 0.01)
end

function magnet:getPercentY( percent )
	return height * (percent * 0.01)
end

-- CORNER ACCESSORIES
function magnet:topLeft(obj, marginX, marginY)
	self:left(obj, marginX)
	self:top(obj, marginY)
end

function magnet:topRight(obj, marginX, marginY)
	self:right(obj, marginX)
	self:top(obj, marginY)
end

function magnet:bottomLeft(obj, marginX, marginY)
	self:left(obj, marginX)
	self:bottom(obj, marginY)
end

function magnet:bottomRight(obj, marginX, marginY)
	self:right(obj, marginX)
	self:bottom(obj, marginY)
end

-- CENTER ACCESORIES
function magnet:centerTop(obj, marginX, marginY)
	self:center(obj, marginX)
	self:top(obj, marginY)
end

function magnet:centerRight(obj, marginX, marginY)
	self:center(obj, 0, marginY)
	self:right(obj, marginX)
end

function magnet:centerBottom(obj, marginX, marginY)
	self:center(obj, marginX)
	self:bottom(obj, marginY)
end

function magnet:centerLeft(obj, marginX, marginY)
	self:center(obj, 0, marginY)
	self:left(obj, marginX)
end

return magnet