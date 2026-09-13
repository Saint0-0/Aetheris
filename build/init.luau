local fs = require("@lune/fs")
local process = require("@lune/process")

local SrcEntry = "src/Init.luau"
local DistScript = "dist/Aetheris.luau"
local DistModel = "dist/Aetheris.rbxm"
local HeaderFile = "build/header.luau"
local Darklua = "tools/darklua.exe"
local DarkluaConfig = "build/darklua.json"
local Rojo = "tools/rojo.exe"
local ModelProject = "build/model.project.json"

local function ensureDir(path)
	if not fs.isDir(path) then
		fs.writeDir(path)
	end
end

local function run(label, cmd, args)
	local result = process.exec(cmd, args)
	if not result.ok then
		print(label .. " stdout: " .. tostring(result.stdout))
		print(label .. " stderr: " .. tostring(result.stderr))
		error(label .. " failed with exit code " .. tostring(result.code))
	end
end

local function build()
	ensureDir("dist")

	-- 1. Bundle + minify the source into a single loadstring script.
	run("darklua", Darklua, {
		"process",
		SrcEntry,
		DistScript,
		"--config",
		DarkluaConfig,
	})

	-- 2. Prepend the header banner.
	local header = fs.readFile(HeaderFile)
	local body = fs.readFile(DistScript)
	fs.writeFile(DistScript, header .. "\n" .. body)

	-- 3. Build the Roblox model (.rbxm) from the bundled script. The model is a
	--    Folder named Aetheris containing a single ModuleScript 'Init', so it can
	--    be dropped into ReplicatedStorage and required as Aetheris.Init.
	run("rojo", Rojo, {
		"build",
		ModelProject,
		"-o",
		DistModel,
	})

	print("Built " .. DistScript)
	print("Built " .. DistModel)
end

build()
