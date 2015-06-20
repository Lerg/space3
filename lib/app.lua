local _M = {}

_M.deviceID = system.getInfo('deviceID')
_M.store = system.getInfo('targetAppStore')

local json = require('json')

if system.getInfo('environment') ~= 'simulator' then
    io.output():setvbuf('no')
else
    _M.isSimulator = true
end
local platform = system.getInfo('platformName')
if platform == 'Android' then
    _M.isAndroid = true
elseif platform == 'iPhone OS' then
    _M.isiOS = true
end

if _M.isSimulator then
    -- Prevent global missuse
    local mt = getmetatable(_G)
    if mt == nil then
      mt = {}
      setmetatable(_G, mt)
    end

    mt.__declared = {}

    mt.__newindex = function (t, n, v)
      if not mt.__declared[n] then
        local w = debug.getinfo(2, 'S').what
        if w ~= 'main' and w ~= 'C' then
          error('assign to undeclared variable \'' .. n .. '\'', 2)
        end
        mt.__declared[n] = true
      end
      rawset(t, n, v)
    end

    mt.__index = function (t, n)
      if not mt.__declared[n] and debug.getinfo(2, 'S').what ~= 'C' then
        error('variable \'' .. n .. '\' is not declared', 2)
      end
      return rawget(t, n)
    end
end

local locals = {
    _W = display.contentWidth,
    _H = display.contentHeight,
    _CX = display.contentWidth * 0.5,
    _CY = display.contentHeight * 0.5,
    mFloor = math.floor,
    tInsert = table.insert,
    mCeil = math.ceil,
    mFloor = math.floor,
    mAbs = math.abs,
    mAtan2 = math.atan2,
    mSin = math.sin,
    mCos = math.cos,
    mPi = math.pi,
    mSqrt = math.sqrt,
    mRandom = math.random,
    tInsert = table.insert,
    tRemove = table.remove,
    tForeach = table.foreach,
    tShuffle = table.shuffle,
    sSub = string.sub,
    sLower = string.lower}

function _M.setLocals()
    local i = 1
    repeat
        local k, v = debug.getlocal(2, i)
        if k and v and locals[v] then
            debug.setlocal(2, i, locals[v])
        end
        i = i + 1
    until not k
end

local colors = {}
colors['white'] = {1, 1, 1}
colors['grey'] = {0.6, 0.6, 0.6}
colors['black'] = {0, 0, 0}
colors['red'] = {1, 0, 0}
colors['green'] = {0, 1, 0}
colors['blue'] = {0, 0, 1}
colors['yellow'] = {1, 1, 0}
colors['cyan'] = {0, 1, 1}
colors['magenta'] = {1, 0, 1}

colors['orange'] = {1, 0.75, 0}
colors['dark_green'] = {0, 0.5, 0}
colors['dark_grey'] = {0.25, 0.25, 0.25}
colors['res_green'] = {0, 0.3, 0}
colors['res_red'] = {0.7, 0, 0}

local ext = (_M.isAndroid or _M.isSimulator) and '.ogg' or '.m4a'

local sounds = {
    impact = 'sounds/impact.wav',
    explosion = 'sounds/explosion.wav',
    tick = 'sounds/tick.wav',
    button = 'sounds/button.wav',
    button_back = 'sounds/button_back.wav',
    dreams = 'sounds/music/dreams.mp3'
}

_M.duration = 200

local referencePoints = {
    TopLeft      = {0, 0},
    TopRight     = {1, 0},
    TopCenter    = {0.5, 0},
    BottomLeft   = {0, 1},
    BottomRight  = {1, 1},
    BottomCenter = {0.5, 1},
    CenterLeft   = {0, 0.5},
    CenterRight  = {1, 0.5},
    Center       = {0.5, 0.5}
}
function _M.setRP(object, rp)
    local anchor = referencePoints[rp]
    if anchor then
        object.anchorX, object.anchorY = anchor[1], anchor[2]
    else
        error('No such reference point: ' .. tostring(rp), 2)
    end
end

function _M.setFillColor(object, color)
    local rgb = colors[color]
    if rgb then
        object:setFillColor(unpack(rgb))
    else
        error('No such color: ' .. tostring(color), 2)
    end
end

function _M.setStrokeColor(object, color)
    local rgb = colors[color]
    if rgb then
        object:setStrokeColor(unpack(rgb))
    else
        error('No such color: ' .. tostring(color), 2)
    end
end

function _M.loadSprite(filename)
    local sheetInfo  = require(filename)
    local sheet = graphics.newImageSheet(filename:gsub('%.', '/') .. '.png',  sheetInfo:getSheet())
    return sheetInfo, sheet
end

local function extractExtension(filename)
    local ext = ''
    for i = filename:len(), 1, -1 do
        local c = filename:sub(i, i)
        if c == '.' then
            return ext
        else
            ext = c .. ext
        end
    end
    return ''
end

function _M.getImageSize(filename, dir)
    if not filename or not dir then return end


    --[[local img = display.newImage(filename, dir, -1000, -1000, true)
    local w, h = img.width, img.height
    img:removeSelf()
    return w, h
    --]]


    local ext = string.lower(extractExtension(filename))
    if ext ~= 'png' and ext ~= 'jpg' then
        error('Image is not supported for size extraction: ' .. filename, 2)
    end
    local fh = io.open(system.pathForFile(filename, dir), 'rb')
    if ext == 'png' then
        fh:seek('cur', 12)
        if fh:read(4) == 'IHDR' then
            fh:seek('cur', 2)
            local a, b = fh:read(2):byte(1, 2)
            local w = a * 256 + b
            fh:seek('cur', 2)
            a, b = fh:read(2):byte(1, 2)
            local h = a * 256 + b
            io.close(fh)
            return w, h
        else
            error('Not a PNG file: ' .. filename, 2)
        end
    elseif ext == 'jpg' then
        local MARKER = 0xFF         -- Section marker.
        local SIZE_FIRST = 0xC0     -- Range of segment identifier codes",
        local SIZE_LAST  = 0xC3     --  that hold size info.
        fh:seek('cur', 2)
        while true do
            local length = 4
            local segheader = fh:read(length)
            if not segheader or fh:len() ~= length then
                error('End of file before JPEG size found: ' .. filename, 2)
            end
            -- Extract the segment header.
            local marker, code = segheader:byte(1, 2)
            local a, b = segheader:byte(3, 4)
            length = a * 256 + b

            -- Verify that it's a valid segment.
            if marker ~= MARKER then
                error('JPEG marker not found: ' .. filename, 2)
            elseif code >= SIZE_FIRST and code <= SIZE_LAST then
                -- Segments that contain size info
                length = 5
                local sizeinfo = fh:read(length)
                io.close(fh)
                if not sizeinfo or sizeinfo:len() ~= length then
                    error('JPEG file\'s size info incomplete: ' .. filename, 2)
                end
                local a, b = sizeinfo:byte(4, 5)
                local w = a * 256 + b
                a, b = sizeinfo:byte(2, 3)
                local h = a * 256 + b
                return w, h
            else
                fh:seek('cur', length - 2)
            end
        end
    end
    --]]
end

function _M.newImage(source, params)
    params = params or {}
    local image
    if type(source) == 'string' then
        local dir = params.dir or system.ResourceDirectory
        local w, h = params.w, params.h
        if not w or not h then
            w, h = _M.getImageSize(source, dir)
        end
        image = display.newImageRect(source, dir, w, h)
    elseif type(source) == 'table' then
        local sheet, index, sheetInfo = source[1], source[2], source[3]
        if type(index) == 'string' then
            index = sheetInfo.frameIndex[index]
            if not index then
                error('newImage: index for "' .. source[2] .. '" not found.', 2)
            end
        end
        local w, h = params.w, params.h
        if not w or not h then
            local frame = sheetInfo.sheet.frames[index]
            if not frame then
                error('newImage: frame ' .. (index and index or 'nil') .. ' not found.', 2)
            end
            w, h = frame.width, frame.height
        end
        image = display.newImageRect(sheet, index, w, h)
    end
    if not image then return end
    if params.rp then
        _M.setRP(image, params.rp)
    end
    image.x = params.x or 0
    image.y = params.y or 0
    if params.g then
        params.g:insert(image)
    end
    return image
end

function _M.newText(params)
    params = params or {}
    local text
    if params.align then
        text = display.newText{text = params.text or '',
            x = params.x or 0, y = params.y or 0,
            width = params.w, height = params.h or (params.w and 0),
            font = params.font or _M.font,
            fontSize = params.size or 16,
            align = params.align or 'center'}
    elseif params.w then
        text = display.newEmbossedText(params.text or '', 0, 0, params.w, params.h or 0, params.font or _M.font, params.size or 16)
    elseif params.flat then
        text = display.newText(params.text or '', 0, 0, params.font or _M.font, params.size or 16)
    else
        text = display.newEmbossedText(params.text or '', 0, 0, params.font or _M.font, params.size or 16)
    end
    if params.rp then
        _M.setRP(text, params.rp)
    end
    text.x = params.x or 0
    text.y = params.y or 0
    if params.g then
        params.g:insert(text)
    end
    params.color = params.color or 'grey'
    if params.color then
        _M.setFillColor(text, params.color)
    end
    return text
end

local fonts = {}
fonts.numbers = {
    ['-'] = 16,
    ['0'] = 23,
    ['1'] = 12,
    ['2'] = 21,
    ['3'] = 22,
    ['4'] = 22,
    ['5'] = 22,
    ['6'] = 23,
    ['7'] = 21,
    ['8'] = 21,
    ['9'] = 22}
fonts.score = {
    ['-'] = 18,
    ['0'] = 22,
    ['1'] = 16,
    ['2'] = 20,
    ['3'] = 20,
    ['4'] = 22,
    ['5'] = 20,
    ['6'] = 18,
    ['7'] = 20,
    ['8'] = 18,
    ['9'] = 18,
    width = 22,
    gap = 1}
function _M.newBitmapText(params)
    local scaleFactor = params.size / 32
    local text = display.newGroup()
    text.anchorChildren = true
    local fontname = params.font or 'numbers'
    local font = fonts[fontname]
    local gap = font.gap or 0
    function text:setText(str)
        for i = self.numChildren, 1, -1 do
            display.remove(self[i])
        end
        str = tostring(str)
        local x = 0
        for i = 1, str:len() do
            local d = str:sub(i, i)
            local di = _M.newImage('images/' .. fontname .. '/' .. d .. '.png', {g = self, w = font.width or font[d], h = 32, x = x, y = 0, rp = 'CenterLeft'})
            di:scale(scaleFactor, scaleFactor)
            x = x + scaleFactor * font[d] + gap
        end
    end
    text:setText(params.text)
    if params.rp then
        _M.setRP(text, params.rp)
    end
    text.x = params.x or 0
    text.y = params.y or 0
    if params.g then
        params.g:insert(text)
    end
    if params.color then
        _M.setFillColor(text, params.color)
    end
    return text
end

function _M.newButton(params)
    local w = params.w or 128
    local h = params.h or 48
    local button = display.newGroup()
    button.back = _M.newImage(params.imageOver or 'images/button-over.png', {g = button, x = 0, y = 0, w = w, h = h})
    button.front = _M.newImage(params.image or 'images/button.png', {g = button, x = 0, y = 0, w = w, h = h})
    button.back.isVisible = false
    button.isEnabled = true

    local labelColor = params.fontColor or {default = 'black', over = 'white'}
    if params.text then
        local font = params.font or _M.font
        local size = params.fontSize or 24
        button.label = _M.newText{g = button, text = params.text, x = 0, y = 0, size = size, font = font, color = labelColor.default or colors.white}
    end
    if params.icon then
        _M.newImage(params.icon, {g = button, w = params.icon_w or 200, h = params.icon_h or 60})
    end

    if params.onRelease and type(params.onRelease) == 'function' then
        button._onRelease = params.onRelease
        button._view = {onRelease = button._onRelease}
    end

    function button:touch(event)
        if not self.isEnabled then return true end
        local onRelease = self._onRelease
        local phase = event.phase
        if phase == 'began' then
            self.back.isVisible = true
            self.front.isVisible = false
            if self.label then
                _M.setFillColor(self.label, labelColor.over)
            end
            display.getCurrentStage():setFocus(self, event.id)
            self.isFocus = true
        elseif self.isFocus then
            local bounds = self.contentBounds
            local x, y = event.x,event.y
            local isWithinBounds = bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
            if phase == 'moved' then
                if isWithinBounds then
                    self.back.isVisible = true
                    self.front.isVisible = false
                    if self.label then
                        _M.setFillColor(self.label, labelColor.over)
                    end
                else
                    self.back.isVisible = false
                    self.front.isVisible = true
                    if self.label then
                        _M.setFillColor(self.label, labelColor.default)
                    end
                end
            else
                self.back.isVisible = false
                self.front.isVisible = true
                if self.label then
                    _M.setFillColor(self.label, labelColor.default)
                end
                if isWithinBounds then
                    if onRelease then
                        onRelease(event)
                    end
                end
                -- Allow touch events to be sent normally to the objects they "hit"
                display.getCurrentStage():setFocus(self, nil)
                self.isFocus = false
            end
        end
        return true
    end
    button:addEventListener('touch', button)
    function button:setFillColor(r, g, b)
        self.back:setFillColor(r, g, b)
        self.front:setFillColor(r, g, b)
    end
    function button:setLabel(txt)
        self.label:setText(txt)
    end
    function button:setEnabled(state)
        self.isEnabled = state
    end

    button.x, button.y = params.x or 0, params.y or 0
    if params.rp then
        button.anchorChildren = true
        _M.setRP(button, params.rp)
    end
    params.g:insert(button)
    button:setFillColor(0.98, 0.98, 1)
    return button
end

function _M.buildBackground(height)
    local group = display.newGroup()
    local w, h = 125, 125
    local W, H = math.floor(display.viewableContentWidth / w), math.floor(height / h)
    local img
    for y = 0, H + 1 do
        for x = 0, W + 1 do
            img = display.newImageRect(group, 'images/back.jpg', w, h)
            img:setReferencePoint(display.TopLeftReferencePoint)
            img.x, img.y = x * w, y * h
        end
    end
    return group
end

function _M.transition(object, params)
    params = params or {}
    params.delay = params.delay or 0
    object.xScale = 0.01
    object.yScale = 0.01
    local transParams = {time = 800, xScale = 1, yScale = 1, transition = easing.outElastic}
    if params.delay > 0 then
        object.isVisible = false
        transParams.onStart = function (obj) obj.isVisible = true end
        transParams.delay = params.delay * 30
    end
    transition.to(object, transParams)
    transition.from(object, {time = 400, alpha = 0})
end

function _M.alert(txt)
    if type(txt) == 'string' then
        native.showAlert(_M.name, txt, {'OK'}, function() end)
    end
end

function _M.returnTrue(obj)
    if obj then
        local function rt() return true end
        obj:addEventListener('touch', rt)
        obj:addEventListener('tap', rt)
        obj.isHitTestable = true
    else
        return true
    end
end

local audioChannel, otherAudioChannel, currentMusicPath = 1, 2
function audio.crossFadeBackground(path, force)
    if not _M.music_on then return end
    path = sounds[path]
    if currentMusicPath == path and audio.getVolume{channel = audioChannel} > 0.1 and not force then return false end
    audio.fadeOut{channel = audioChannel, time = 1000}
    audioChannel, otherAudioChannel = otherAudioChannel, audioChannel
    audio.setVolume(0.5, {channel = audioChannel})
    audio.play(audio.loadStream(path), {channel = audioChannel, loops = -1, fadein = 1000})
    currentMusicPath = path
end
audio.reserveChannels(2)

local loadedSounds = {}
local function loadSound(snd)
    if not loadedSounds[snd] then
        loadedSounds[snd] = audio.loadSound(sounds[snd])
    end
    return loadedSounds[snd]
end
function audio.playSFX(snd, params)
    if not _M.sound_on then return end
    local channel = (type(snd) == 'string') and audio.play(loadSound(snd), params) or audio.play(snd, params)
    audio.setVolume(1, {channel = channel})
    return channel
end

function _M.initUser(t)
    _M.user = json.decode(_M.readFile('user.txt'))
    if not _M.user then
        _M.user = t
        _M.saveUser()
    end
end

function _M.saveUser()
    _M.saveFile('user.txt', json.encode(_M.user))
end

function _M.nextFrame(f)
    timer.performWithDelay(1, f)
end
function _M.enterFrame()
    for i = 1, #_M.enterFrameFunctions do
        _M.enterFrameFunctions[i]()
    end
end
function _M.eachFrame(f)
    if not _M.enterFrameFunctions then
        _M.enterFrameFunctions = {}
        Runtime:addEventListener('enterFrame', _M.enterFrame)
    end
    table.insert(_M.enterFrameFunctions, f)
    return f
end
function _M.eachFrameRemove(f)
    if not f or not _M.enterFrameFunctions then return end
    local ind = table.indexOf(_M.enterFrameFunctions, f)
    if ind then
        table.remove(_M.enterFrameFunctions, ind)
        if #_M.enterFrameFunctions == 0 then
            Runtime:removeEventListener('enterFrame', _M.enterFrame)
            _M.enterFrameFunctions = nil
        end
    end
end
function _M.eachFrameRemoveAll()
    Runtime:removeEventListener('enterFrame', _M.enterFrame)
    _M.enterFrameFunctions = nil
end

-- Fixed in 2015.2544
-- Fix problem that finalize event is not called for children objects when group is removed
--[[local function finalize(event)
    local g = event.target
    for i = 1, g.numChildren do
        if g[i]._tableListeners and g[i]._tableListeners.finalize then
            for j = 1, #g[i]._tableListeners.finalize do
                g[i]._tableListeners.finalize[j]:dispatchEvent{name = 'finalize', target = g[i]}
            end
        end
        if g[i]._functionListeners and g[i]._functionListeners.finalize then
            for j = 1, #g[i]._functionListeners.finalize do
                g[i]._functionListeners.finalize[j]({name = 'finalize', target = g[i]})
            end
        end
        if g[i].numChildren then
            finalize{target = g[i]}
        end
    end
end
local newGroup = display.newGroup
function display.newGroup()
    local g = newGroup()
    g:addEventListener('finalize', finalize)
    return g
end]]

function _M.loadRemoteCachedImage(params)
    local group, url, x, y, w = params.g, params.url, params.x, params.y, params.w or 50
    local h = params.h or params.w
    local filename
    local fileExists = true
    if url ~= '' then
        filename = crypto.digest(crypto.md5, url) .. '.jpg'
        local path = system.pathForFile(filename, system.DocumentsDirectory)
        fileExists = io.open(path, 'r')
        if fileExists then
            io.close(fileExists)
            fileExists = true
        else
            fileExists = false
        end
    end

    local function listener(event)
        if params.cancel.cancel then return end
        if event and event.isError then
            print('Network error: image download failed', url)
        elseif group then
            local image
            if url ~= '' then
                image = display.newImageRect(filename, system.CachesDirectory, w, h)
                _M.setRP(image, params.rp or 'Center')
                image.x, image.y = x, y
            else

            end
            group:insert(image)
        end
    end

    if fileExists then
        listener()
    else
        network.download(url, 'GET', listener, filename, system.CachesDirectory)
    end
end

function _M.promoRatePlayScene(save)
    local nextScene = 'play'
    if _M.user.score >= _M.adsScore then
        if not _M.user.rated and not _M.user.promo.laser then
            local scenes = {'promo', 'rate'}
            if math.random(1, 3) == 1 then
                nextScene = scenes[math.random(1, 2)]
            end
        elseif not _M.user.rated then
            if math.random(1, 3) == 1 then
                nextScene = 'rate'
            end
        elseif not _M.user.promo.laser and _M.store ~= 'amazon' then
            if math.random(1, 3) == 1 then
                nextScene = 'promo'
            end
        end
    end
    if not _M.user.tutorial then
        nextScene = 'tutorial'
    end
    --return nextScene
    return 'play'
end

function _M.newBanner(g)
    local banner = _M.newImage('images/banner.png', {g = g, w = locals._W, h = _M.bannerH, x = 0, y = locals._H, rp = 'BottomLeft'})
    return banner
end

return _M
