local _CX, _CY, _W, _H = '_CX', '_CY', '_W', '_H'
local app = require('lib.app')
app.setLocals()

local physics = require('physics')
local particleDesigner = require('lib.particle_designer')

local _M = {}

function _M:newPiece(params)
    local piece = display.newSprite(graphics.newImageSheet('images/match3.png',
        {width = 64,
        height = 64,
        numFrames = 6,
        border = 1,
        sheetContentWidth = 398, sheetContentHeight = 68}),
        {name = 'normal',
        start = 1,
        count = 6})
    
    local ind = math.random(1, 6)
    piece.ind = ind
    local r, g, b = app.HSVtoRGB((ind - 1) * 50, 1, 1)
    piece:setFillColor(r, g, b)
    piece:setFrame(ind)
    
    piece.width = piece.width * 0.5
    piece.height = piece.height * 0.5
    
    piece.sameNeighbors = {}

    physics.addBody(piece, 'dynamic', {friction = 1, density = 10, bounce = 0, box = {halfWidth = piece.width * 0.4, halfHeight = piece.height * 0.4, x = 0, y = 0}})
    piece.isFixedRotation = true
    piece.isPiece = true
    piece:setLinearVelocity(0, 100)
    
    function piece:collision(event)
        local obj = event.other
        if event.phase == 'began' then
            local obj = event.other
            if obj.isPiece then
                if obj.y < self.y then
                    app.nextFrame(function()
                        if not self.toRemove and not obj.toRemove then
                            audio.playSFX('tick')
                            local joint = physics.newJoint('piston', self, obj, self.x, self.y, 0, 1)
                            joint.isLimitEnabled = true
                            joint:setLimits(0, 0)
                        end
                    end)
                    if obj.ind == self.ind then
                        table.insert(self.sameNeighbors, obj)
                        table.insert(obj.sameNeighbors, self)
                    end
                end
            end
        end
    end
    piece:addEventListener('collision')
    
    function piece:explode()
        audio.playSFX('explosion')
        display.setDefault('minTextureFilter', 'nearest')
        local explosion = particleDesigner.newEmitter('explosion.json')
        display.setDefault('minTextureFilter', 'linear')
        self.parent:insert(explosion)
        explosion.x, explosion.y = self.x, self.y
        timer.performWithDelay(100, function()
            explosion:removeSelf()
        end)
    end

    piece.x, piece.y = math.random(32, _W - 32), -32
    params.g:insert(piece)
    table.insert(self.pieces, piece)
    return piece
end

return _M