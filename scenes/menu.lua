local _CX, _CY, _W, _H = '_CX', '_CY', '_W', '_H'
local app = require('lib.app')
app.setLocals()

local storyboard = require('storyboard')
local scene = storyboard.newScene()

function scene:createScene (event)
    local group = self.view
    local rect = display.newRect(group, 0, 0, _W, _H)
    rect.x, rect.y = _CX, _CY
    app.newText{g = group, x = _CX, y = _CY - 50, text = 'SPACE 3', size = 32}

    local newGameButton = app.newButton{g = group, x = _CX, y = _CY + 40,
        text = 'NEW GAME',
        fontSize = 16,
        onRelease = function()
            audio.playSFX('button')
            storyboard.gotoScene('scenes.play', {effect = 'slideLeft', time = app.duration})
        end}
    newGameButton:setFillColor(0.95, 1, 0.95)

    local sound_on, sound_off, music_on, music_off
    music_on = app.newButton{g = group, x = 16, y = _H - 16 - 32, w = 43, rp = 'BottomLeft',
        image = 'images/buttons/music_on.png',
        imageOver = 'images/buttons/music_on-over.png',
        onRelease = function()
            audio.stop()
            audio.playSFX('button')
            app.user.music_on = false
            app.music_on = false
            app.saveUser()
            music_on.isVisible = false
            music_off.isVisible = true
        end}
    music_off = app.newButton{g = group, x = music_on.x, y = music_on.y, w = 43, rp = 'BottomLeft',
        image = 'images/buttons/music_off.png',
        imageOver = 'images/buttons/music_off-over.png',
        onRelease = function()
            audio.playSFX('button')
            app.user.music_on = true
            app.music_on = true
            audio.crossFadeBackground('dreams', true)
            app.saveUser()
            music_on.isVisible = true
            music_off.isVisible = false
        end}

    sound_on = app.newButton{g = group, x = 16 + 22, y = _H - 16, w = 43, rp = 'BottomLeft',
        image = 'images/buttons/sound_on.png',
        imageOver = 'images/buttons/sound_on-over.png',
        onRelease = function()
            app.user.sound_on = false
            app.sound_on = false
            app.saveUser()
            sound_on.isVisible = false
            sound_off.isVisible = true
        end}
    sound_off = app.newButton{g = group, x = sound_on.x, y = sound_on.y, w = 43, rp = 'BottomLeft',
        image = 'images/buttons/sound_off.png',
        imageOver = 'images/buttons/sound_off-over.png',
        onRelease = function()
            app.user.sound_on = true
            app.sound_on = true
            app.saveUser()
            audio.playSFX('button')
            sound_on.isVisible = true
            sound_off.isVisible = false
        end}
    music_on.isVisible = false
    music_off.isVisible = false
    sound_on.isVisible = false
    sound_off.isVisible = false
    if app.user.music_on then
        music_on.isVisible = true
        audio.crossFadeBackground('dreams')
    else
        music_off.isVisible = true
    end
    if app.user.sound_on then
        sound_on.isVisible = true
    else
        sound_off.isVisible = true
    end
end

function scene:didExitScene()
    storyboard.removeScene('scenes.menu')
end

scene:addEventListener('didExitScene')
scene:addEventListener('createScene')
return scene

