local fs = require("@lune/fs")
local process = require("@lune/process")

local SrcEntry = "src/Init.luau"
local DistFile = "dist/Aetheris.luau"
local HeaderFile = "build/header.luau"
local Darklua = "tools/darklua.exe"
local DarkluaConfig = "build/darklua.json"

local function ensureDir(path)
	if not fs.isDir(path) then
		fs.writeDir(path)
	end
end

local function build()
	ensureDir("dist")

	local result = process.exec(Darklua, {
		"process",
		SrcEntry,
		DistFile,
		"--config",
		DarkluaConfig,
	})

	if not result.ok then
		print("darklua stdout:", result.stdout)
		print("darklua stderr:", result.stderr)
		error("darklua failed with exit code " .. tostring(result.code))
	end

	local header = fs.readFile(HeaderFile)
	local body = fs.readFile(DistFile)
	fs.writeFile(DistFile, header .. "\n" .. body)

	print("Built " .. DistFile)
end

build()
