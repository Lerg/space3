local scene = storyboard.newScene()
local app = require('lib.app')

function scene:createScene(event)
    timer.performWithDelay(app.duration, function() storyboard.gotoScene('scenes.' .. app.promoRatePlayScene(true), {effect = 'fade', time = app.duration, params = event.params}) end)
end

function scene:didExitScene()
    storyboard.removeScene('scenes.restart')
end

scene:addEventListener('didExitScene')
scene:addEventListener('createScene')
return scene