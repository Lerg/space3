local particleDesigner = {}

local json = require('json')

particleDesigner.loadParams = function(filename, baseDir)
	local path = system.pathForFile(filename, baseDir)
	local f = io.open(path, 'r')
	local data = f:read('*a')
	f:close()
	return json.decode(data)
end

particleDesigner.newEmitter = function(filename, baseDir)
	return display.newEmitter(particleDesigner.loadParams(filename, baseDir))
end

return particleDesigner
