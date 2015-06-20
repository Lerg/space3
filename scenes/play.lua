local _CX, _CY, _W, _H = '_CX', '_CY', '_W', '_H'
local app = require('lib.app')
app.setLocals()

local storyboard = require('storyboard')
local scene = storyboard.newScene()
local physics = require('physics')

local particleDesigner = require('lib.particle_designer')

physics.start()
physics.setGravity(0, 0)

scene.newShip = require('classes.ship').newShip
scene.newPiece = require('classes.piece').newPiece
    
function scene:createShaderBackground()
    local group = self.view
    local bg = display.newRect(group, _CX, _CY, _W, _H)
    bg.fill.effect = 'generator.custom.stars'
end

function scene:addBackgroundPlanet()
    local planet = app.newImage('images/planets/' .. math.random(1, 10) .. '.png',
        {g = self.backgroundGroup, x = math.random(0, _W), y = -64, w = 128, h = 128})
    local s = math.random(1, 4)
    planet.speed = s / 10
    planet:setFillColor(0.9 ^ s, 0.8 ^ s, 1)
    return planet
end

function scene:addBackgroundStar(params)
    local star = display.newRect(self.backgroundGroup, 0, 0, 2, 2)
    star.x, star.y = math.random(0, _W), -5
    if params and params.initial then
        star.y = math.random(0, _H)
    end
    local s = math.random(1, 40)
    star.speed = s / 10
    star:setFillColor(math.random(80, 100) / 100, math.random(60, 80) / 100, 1)
    star:toBack()
end

function scene.backgroundEnterFrame()
    local self = scene
    if self.nextPlanetTime < system.getTimer() then
        local planet = self:addBackgroundPlanet()
        self.nextPlanetTime = self.nextPlanetTime + math.random(10000, 20000) * 0.4 / planet.speed
    end
    
    if math.random() < 0.3 then
        self:addBackgroundStar()
    end
    
    for i = self.backgroundGroup.numChildren, 1, -1 do
        local obj = self.backgroundGroup[i]
        obj.y = obj.y + obj.speed
        
        if obj.y - obj.height > _H then
            obj:removeSelf()
        end
    end
end

function scene:createPixelartBackground()
    local group = self.view
    local bg = display.newRect(group, _CX, _CY, _W, _H)
    bg.fill = {
        type = 'gradient',
        color1 = {0, 0.1, 0.3},
        color2 = {0, 0, 0.0, 0.0},
        direction = 'down'
    }

    self.backgroundGroup = display.newGroup()
    group:insert(self.backgroundGroup)
    self.nextPlanetTime = system.getTimer() + math.random(500, 1000)
    app.eachFrame(self.backgroundEnterFrame)
    
    for i = 1, 100 do
        self:addBackgroundStar{initial = true}
    end
end

function scene:createScene(event)
    local group = self.view

    --self:createShaderBackground()
    self:createPixelartBackground()
    self.ship = self:newShip{g = group, x = _CX, y = _H - 64}

    local touchRect = display.newRect(_CX, _CY, _W, _H)
    touchRect.isVisible = false
    touchRect.isHitTestable = true
    local super = self
    function touchRect:touch(event)
        if event.phase == 'began' then
            super.ship:moveStart(event.x, event.y)
        elseif event.phase == 'moved' then
            super.ship:move(event.x, event.y)
        else
            super.ship:moveStop(event.x, event.y)
        end
        return true
    end
    touchRect:addEventListener('touch')
    group:insert(touchRect)

    self.pieces = {}
    self.nextPieceTime = system.getTimer() + 1000
    app.eachFrame(self.enterFrame)
    
    local vignette = app.newImage('images/shade.png', {g = group, x = _CX, y = _CY, w = 388, h = 640})
    vignette.alpha = 0.75
end

function scene.enterFrame()
    local self = scene
    local group = self.view

    if self.nextPieceTime < system.getTimer() then
        local piece = self:newPiece{g = group}
        self.nextPieceTime = self.nextPieceTime + math.random(1000, 2000)
    end
    
    for i = #self.pieces, 1, -1 do
        local obj = self.pieces[i]
        if obj.y - obj.height > _H then
            obj:removeSelf()
            table.remove(self.pieces, i)
        end
    end
    
    for i = 1, #self.pieces do
        local obj = self.pieces[i]
        if #obj.sameNeighbors >= 2 then
            obj.toRemove = true
            for j = 1, #obj.sameNeighbors do
                obj.sameNeighbors[j].toRemove = true
            end
        end
    end
    
    for i = #self.pieces, 1, -1 do
        local obj = self.pieces[i]
        if obj.toRemove then
            obj:explode()
            obj:removeSelf()
            table.remove(self.pieces, i)
        end
    end
end


function scene:backPressed()
    
end

function scene:didExitScene()
    storyboard.removeScene('scenes.play')
    app.eachFrameRemove(self.enterFrame)
    app.eachFrameRemove(self.backgroundEnterFrame)
end

scene:addEventListener('didExitScene')
scene:addEventListener('createScene')
return scene