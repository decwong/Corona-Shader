-- EnterFrame events Helper
-- Author: Iván Juárez Núñez 2013
-- License: MIT 
-- Version: 1.0
--
--	Example:
-- 		scrollLoop = looper:newLoop( _callBack, { transitionIn = easing.inExpo, timeIn = 5000, 
--												  transitionOut = easing.outExpo, timeOut = 2000 } )
--			# _callBack: must be defined as function(e, loop)
--
--		scrollLoop:pause() -> Will pause the loop instance
--		looper:pauseAll() -> Will Pause all the loops created with the looper class
--	In the same way you can use resume() and resumeAll() methods to start/resume each or all the loops

local _M = {}

local tLoopers = {}
-- Cache
local tInsert = table.insert
local tRemove = table.remove
local MAX = math.max
local MIN = math.min

function _M:newLoop( callback, params )
	local loop = {}
	loop.callback = callback
	loop.startTime = 0
	loop.prevTime = 0
	loop.delta = 0
	loop.elapsedTime = 0
	loop.pauseTime = 0
	loop.speed = 1
	loop.speedTarget = 1
	loop.speedEasing = nil
	loop.speedTime = 0
	loop.speedTimeLeft = 0 
	loop.isPaused = false

	--easing properties
	local e = params or {}
	e.In = { fn = e.transitionIn or easing.linear, time = e.timeIn or 0 }
	e.Out = { fn = e.transitionOut or easing.linear, time = e.timeOut or 0 }
	e.prevTime = 0
	e.elapsedTime = 0
	e.currentTween = nil
	loop.easing = e

	loop._onFrame = function( e )
		--adjust speed with easing
		if (loop.speedTimeLeft > 0) then
			loop.speedTimeLeft = MAX(0, loop.speedTimeLeft - (e.time - loop.prevTime))
			loop.speed = loop.speedTarget + ((loop.speed - loop.speedTarget) * 
				loop.speedEasing(loop.speedTimeLeft / loop.speedTime, 1, 0, 1))
		end

		--calc delta
		loop.delta = (e.time - loop.prevTime) * loop.speed
		loop.prevTime = e.time
		
		if (loop.isPaused) then
			loop.pauseTime = loop.pauseTime + loop.delta
		else
			if loop.startTime == 0 then loop.startTime = e.time end
			loop.elapsedTime = e.time - loop.startTime

			if (loop.easing.currentTween ~= nil) then
				--calc current tween
				local tween = loop.easing.currentTween
				local tweenStep = tween.fn(loop.easing.elapsedTime, tween.time, 0, tween.time)
				tweenStep = loop.delta * MIN(tweenStep / tween.time, 1)
				--increment linear time and check if tween ended
				loop.easing.elapsedTime = loop.easing.elapsedTime + loop.delta
				if (loop.easing.elapsedTime > tween.time) then
					loop.easing.currentTween = nil
				end
				--override linear delta by tweened delta
				if (tween == loop.easing.Out) then
					loop.delta = loop.delta - tweenStep
				else
					loop.delta = tweenStep
				end
				loop.easing.prevTime = tweenStep
			end

			if ('function' == type(loop.callback)) then
				loop.callback(e, loop)
			end
		end
	end

	loop._setCurrentTween = function( easing, active)
		if (active == true and easing.time > 0) then
			loop.easing.currentTween = easing
			loop.easing.elapsedTime = 0
			loop.easing.prevTime = 0
		end
	end

	--bool to resume using easing
	function loop:resume( easeIn )
		--if already running the skip
		if not self.isPaused and self.startTime > 0 then
			return
		end

		self._setCurrentTween(self.easing.In, easeIn)
		if (self.isPaused) then
			self.isPaused = false
			--add compensation time
			self.startTime = self.startTime + self.pauseTime
		elseif (self.startTime == 0) then
			Runtime:addEventListener("enterFrame", self._onFrame)
		end
	end
	--bool to stop using easing
	function loop:pause( easeOut )
		if self.startTime == 0 then
			return false
		end

		self._setCurrentTween(self.easing.Out, easeOut)
		local pauseDelay = 0
		if (easeOut == true) then
			pauseDelay = self.easing.Out.time
		end
		local exePause = function() self.isPaused, self.pauseTime = true, 0 end

		if pauseDelay > 0 then
			timer.performWithDelay(pauseDelay, exePause, 1)
		else
			exePause()
		end
	end

	function loop:setSpeed( speed, transition, time)
		--clamp speed 
		speed = MAX(0.0001, speed or 1)
		--speed = MIN(10, speed or 1)
		self.speedTarget = speed
		self.speedEasing = transition or easing.linear
		self.speedTime = time or 500
		self.speedTimeLeft = time or 500
	end

	function loop:destroy()
		Runtime:removeEventListener(self._onFrame)
		loop._onFrame = nil
		self.callback = nil
		self = nil
		--print("loop destroyed!")
	end

	tInsert(tLoopers, loop)
	return loop
end

function _M:cleanUp()
	local i = 1
	while i <= #tLoopers do
		if (tLoopers[i] == nil) then
			tRemove( tLoopers, i )
		else
			i = i + 1
		end
	end
end

function _M:pauseAll()
	self:cleanUp()
	for i = 1, #tLoopers do
		tLoopers[i]:pause()
	end
end

function _M:resumeAll()
	self:cleanUp()
	for i = 1, #tLoopers do
		tLoopers[i]:resume()
	end
end

function _M:destroyAll()
	self:cleanUp()
	--the fuck is this shit?
	local i = 1
	while i <= #tLoopers do
		tLoopers[i]:destroy()
		tRemove( tLoopers, i )
	end
end

return _M