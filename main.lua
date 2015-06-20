display.setStatusBar(display.HiddenStatusBar)

-- Various utility functions
local app = require('lib.app')
require('lib.utils')

if app.isAndroid then
    native.setProperty('androidSystemUiVisibility', 'immersiveSticky')
end

audio = require('audio')
local physics = require('physics')

local storyboard = require('storyboard')

graphics.defineEffect(require('shaders.stars1'))
--graphics.defineEffect(require('shaders.stars2'))

app.name = 'Space 3'
app.font = native.systemFont
app.fontbold = native.systemFontBold

if app.isAndroid then
    Runtime:addEventListener('key', function (event)
        if event.keyName == 'back' and event.phase == 'down' then
            local scene = storyboard.getScene(storyboard.getCurrentSceneName())
            if scene and type(scene.backPressed) == 'function' then
                scene:backPressed()
                return true
            end
        end
    end)
end
if app.isSimulator then
    Runtime:addEventListener('key', function(event)
        if event.phase == 'down' then
            if event.keyName == 's' then
                local scene = storyboard.getScene(storyboard.getCurrentSceneName())
                if scene and scene.view then
                    display.save(scene.view, display.pixelHeight .. 'x' .. display.pixelWidth .. '_' .. math.floor(system.getTimer()) .. '.png')
                end
            elseif event.keyName == 'g' then
                collectgarbage('collect')
            elseif event.keyName == 'm' then
                local memoryUsed = collectgarbage('count')
                local textureMemoryUsed = system.getInfo('textureMemoryUsed') / 1048576
                print('System Memory:', string.format('%.00f', memoryUsed) .. ' kB')
                print('Texture Memory:', string.format('%.03f', textureMemoryUsed) .. ' MB')
            elseif event.keyName == 'd' then
                local modes = { 'normal', 'hybrid', 'debug' }
                if not physics.drawMode then physics.drawMode = 1 end
                physics.drawMode = physics.drawMode % 3 + 1
                physics.setDrawMode(modes[physics.drawMode])
                print('Physics draw mode: ' .. modes[physics.drawMode])
            else
                local scene = storyboard.getScene(storyboard.getCurrentSceneName())
                if scene and scene.keyPressed then
                    scene:keyPressed(event.keyName)
                end
            end
        end
    end)
end

--display.setDefault('magTextureFilter', 'nearest')
--display.setDefault('minTextureFilter', 'nearest')

app.initUser({score = 0, music_on = true, sound_on = true, promo = {}})

local function main()
    math.randomseed(os.time())
    app.sound_on = app.user.sound_on
    app.music_on = app.user.music_on
    storyboard.gotoScene('scenes.menu')
end
main()
