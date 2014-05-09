--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Cocooned by Damaged Panda Games (http://signup.cocoonedgame.com/)
-- memory.lua
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Memory Check (http://coronalabs.com/blog/2011/08/15/corona-sdk-memory-leak-prevention-101/)
--------------------------------------------------------------------------------
-- Updated by: Derrick
--------------------------------------------------------------------------------
-- debug text object
local textObject = {
			display.newText("mem",  0, 10, native.systemFont, 12),
			display.newText("text", 0, 20, native.systemFont, 12),
			display.newText("fps", 0, 30, native.systemFont, 12),
			display.newText("star", 0, 40, native.systemFont, 12)
}

local prevTextMem = 0
local prevMemCount = 0
local monitorMem = function() collectgarbage("collect")
local memCount = collectgarbage("count")
local textMem = system.getInfo( "textureMemoryUsed" ) / 1000000
		
	if (prevMemCount ~= memCount) and (prevTextMem ~= textMem) then
		textObject[1].text = "Mem:" .. " " .. memCount
		textObject[2].text = "Text:" .. " " .. textMem
		textObject[3].text = "FPS:" .. " " .. display.fps
				
		prevMemCount = memCount
		prevTextMem = textMem
	end

	for i=1, #textObject do
		textObject[i].anchorX = 0
		textObject[i]:setFillColor(1,0,0)
		textObject[i]:toFront()
	end
end

local function pos(obj)
	if obj then
		textObject[4].text = "Pos:" .. " " .. obj.position.x .. ", " .. obj.position.y .. "."
	end
end

local memory = {
	textObject = textObject,
	monitorMem = monitorMem,
	pos = pos
}

return memory

--------------------------------------------------------------------------------
-- END MEMORY CHECKER
--------------------------------------------------------------------------------