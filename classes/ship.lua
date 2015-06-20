local _CX, _CY, _W, _H = '_CX', '_CY', '_W', '_H'
local app = require('lib.app')
app.setLocals()

local physics = require('physics')
local particleDesigner = require('lib.particle_designer')

local _M = {}

function _M:newShip(params)
    local ship = display.newGroup()
    
    local sprite = display.newSprite(graphics.newImageSheet('images/ship.png',
        {width = 82,
        height = 76,
        numFrames = 3,
        sheetContentWidth = 82, sheetContentHeight = 228}),
        {name = 'normal',
        start = 1,
        count = 3})

    sprite:setSequence('normal')
    ship:insert(sprite)
    
    display.setDefault('minTextureFilter', 'nearest')
    local jet = particleDesigner.newEmitter('particle.json')
    display.setDefault('minTextureFilter', 'linear')
    ship:insert(jet)
    jet.x, jet.y = sprite.x, sprite.y + 40
    jet:scale(0.5, 0.5)
    jet:toBack()
    jet.gravityxOrig = jet.gravityx
    jet.gravityyOrig = jet.gravityy
    self.jet = jet

    physics.addBody(ship, 'dynamic', {density = 1, friction = 1, bouncy = 0, box = {halfWidth = 10, halfHeight = sprite.height / 2, x = 0, y = 0}})
    ship.isFixedRotation = true

    ship.isShip = true
    ship.speed = 0
    ship.maxSpeed = 100
    ship.acceleration = 2

    function ship:collision(event)
        local obj = event.other
        if event.phase == 'began' then
            local obj = event.other
            if obj.isPiece then
                if obj.y <= self.y - self.height / 2 then
                    app.nextFrame(function()
                        audio.playSFX('impact')
                        local joint = physics.newJoint('piston', self, obj, self.x, self.y, 0, 1)
                        joint.isLimitEnabled = true
                        joint:setLimits(0, 0)
                    end)
                end
            end
        end
    end
    ship:addEventListener('collision')

    function ship:moveStart(x, y)
        self.isMoving = true
        self.target = {x = x, y = y}
    end

    function ship:move(x, y)
        self.target.x = x
        self.target.y = y
    end

    function ship:moveStop(x, y)
        self.isMoving = false
        self:setLinearVelocity(0, 0)
        self.speed = 0
    end

    function ship:enterFrame()
        local self = ship
        if self.isMoving then
            local vx, vy = 0, 0
            
            self.dir = {x = self.target.x - self.x, y = self.target.y - self.y}
            local len = math.sqrt(self.dir.x ^ 2 + self.dir.y ^ 2)
            self.dir.x, self.dir.y = self.dir.x / len, self.dir.y / len
            
            local distance = math.sqrt((self.target.x - self.x) ^ 2 + (self.target.y - self.y) ^ 2)
            if distance > 2 then
                self.speed = math.min(self.speed + self.acceleration, self.maxSpeed) * math.max(distance, 20) / 22
            else
                self.speed = 0
            end
            self:setLinearVelocity(self.dir.x * self.speed, self.dir.y * self.speed)
        end
        
        local vx, vy = self:getLinearVelocity()
        if math.abs(vx / vy) > 0.5 then
            if vx < -0.1 then
                sprite:setFrame(2)
            elseif vx > 0.1 then
                sprite:setFrame(3)
            else
                sprite:setFrame(1)
            end
        else
            sprite:setFrame(1)
        end
        
        jet.gravityx, jet.gravityy = -vx * 10, jet.gravityyOrig - vy * 10
    end
    app.eachFrame(ship.enterFrame)

    function ship:finalize()
        app.eachFrameRemove(self.enterFrame)
    end
    ship:addEventListener('finalize')

    ship.x, ship.y = params.x, params.y
    params.g:insert(ship)
    return ship
end

return _M