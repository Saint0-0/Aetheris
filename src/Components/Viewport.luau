--[[
	Aetheris/Components/Viewport.luau

	Player card: a ViewportFrame rendering a live character clone (slow orbit or
	static 3/4 view) beside four info rows. Framing picks the camera crop;
	SetPlayer swaps the subject in place.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ThemeManager = require("../Themes/ThemeManager")
local ComponentAPI = require("../Utils/ComponentAPI")
local PageAwareness = require("../Utils/PageAwareness")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

-- camera crop per framing: focus offset above the bounding-box centre and
-- distance, both as fractions of the model's height
local FRAMING = {
	Full = { focus = 0.0, distance = 1.25 },
	UpperBody = { focus = 0.18, distance = 0.55 },
	Torso = { focus = 0.05, distance = 0.75 },
	Head = { focus = 0.36, distance = 0.28 },
}

local INFO_ROWS = {
	{ caption = "USERNAME", key = "Name" },
	{ caption = "DISPLAY NAME", key = "DisplayName" },
	{ caption = "USER ID", key = "UserId" },
	{ caption = "ACCOUNT AGE", key = "AccountAge", suffix = " days" },
}

local STATIC_YAW = math.rad(-20) -- slight 3/4 angle when not rotating.
local ORBIT_SPEED = 0.35 -- radians per second (~20°/s: a calm ~18s revolution).

local function newCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local Viewport = {}
Viewport.__index = Viewport

function Viewport.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Viewport)
	self._theme = theme
	-- the orbit RenderStepped early-returns while off screen (cheaper than connect/disconnect)
	self._pageActive = true
	local height = Settings.Height or 160
	local framing = FRAMING[Settings.Framing] and Settings.Framing or "Full"
	local rotating = Settings.Rotate ~= false

	local frame = Instance.new("Frame")
	frame.Name = UUID.Static("Viewport")
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = (theme and theme.ComponentBackgroundColor)
	frame.BackgroundTransparency = (theme and theme.ComponentBackgroundTransparency) or 0.985
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame:SetAttribute(UUID.Static("IsComponentContainer"), true)
	frame.Parent = parent
	newCorner(frame, 6)
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame

	-- input-well tint keeps it recessed and themed like a Keybind/TextInput
	-- field; `side` is recomputed by relayout so the info labels never clip
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = UUID.Static("PlayerViewport")
	viewport.BorderSizePixel = 0
	viewport.BackgroundColor3 = (theme and theme.InputBackgroundColor) or Color3.fromRGB(28, 33, 44)
	viewport.BackgroundTransparency = (theme and theme.InputBackgroundTransparency) or 0
	viewport.AnchorPoint = Vector2.new(0, 0.5)
	viewport.Position = UDim2.new(0, 8, 0.5, 0)
	viewport.Size = UDim2.fromScale(0.55, 0.9)
	viewport.Ambient = Color3.fromRGB(126, 126, 134)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1.2, -0.8).Unit
	viewport.Parent = frame
	newCorner(viewport, 4)

	local viewportConstraint = Instance.new("UISizeConstraint")
	viewportConstraint.MaxSize = Vector2.new(150, math.huge)
	viewportConstraint.Parent = viewport

	local camera = Instance.new("Camera")
	camera.FieldOfView = 60
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	-- caption over value, four rows
	local infoColumn = Instance.new("Frame")
	infoColumn.Name = UUID.Static("InfoColumn")
	infoColumn.BorderSizePixel = 0
	infoColumn.BackgroundTransparency = 1
	infoColumn.AnchorPoint = Vector2.new(1, 0.5)
	infoColumn.Position = UDim2.new(1, -8, 0.5, 0)
	infoColumn.Size = UDim2.new(0, 100, 0.9, 0)
	infoColumn.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = infoColumn

	local valueLabels = {}
	for index, spec in ipairs(INFO_ROWS) do
		local row = Instance.new("Frame")
		row.Name = UUID.Static("InfoRow")
		row.BorderSizePixel = 0
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 32)
		row.LayoutOrder = index
		row.Parent = infoColumn
		local caption = Instance.new("TextLabel")
		caption.Name = UUID.Static("Caption")
		caption.BackgroundTransparency = 1
		caption.BorderSizePixel = 0
		caption.AnchorPoint = Vector2.new(0, 0)
		caption.Position = UDim2.fromOffset(0, 0)
		caption.Size = UDim2.new(1, 0, 0, 12)
		caption.FontFace = Constants.Font(Enum.FontWeight.Bold)
		caption.TextSize = 10
		caption.TextXAlignment = Enum.TextXAlignment.Right
		caption.Text = spec.caption
		ThemeManager.BindColor(caption, "TextColor3", "TertiaryColor")
		caption.Parent = row

		local value = Instance.new("TextLabel")
		value.Name = UUID.Static("Value")
		value.BackgroundTransparency = 1
		value.BorderSizePixel = 0
		value.AnchorPoint = Vector2.new(0, 0)
		value.Position = UDim2.fromOffset(0, 13)
		value.Size = UDim2.new(1, 0, 0, 17)
		value.FontFace = Constants.Font(Enum.FontWeight.Medium)
		value.TextSize = 13
		value.TextXAlignment = Enum.TextXAlignment.Right
		value.TextTruncate = Enum.TextTruncate.AtEnd
		value.Text = ""
		value.Parent = row
		valueLabels[index] = value
	end

	local yaw = STATIC_YAW
	local boxCF, boxSize -- bounding box; nil until a clone exists
	local clone
	local renderConn, charAddedConn
	local bindToken = 0

	local function applyCamera()
		if not boxSize then
			return
		end
		local mode = FRAMING[framing]
		local focus = boxCF.Position + Vector3.new(0, boxSize.Y * mode.focus, 0)
		local distance = boxSize.Y * mode.distance + 0.4
		local rotation = CFrame.Angles(0, yaw, 0)
		-- characters face -Z, so yaw 0 puts the camera on the -Z side showing
		-- the front; elevation adds a touch of top-down perspective
		local camPos = focus + rotation:VectorToWorldSpace(Vector3.new(0, boxSize.Y * 0.05, -distance))
		camera.CFrame = CFrame.lookAt(camPos, focus)
	end

	local function attach(character)
		if clone then
			clone:Destroy()
			clone = nil
		end
		boxCF, boxSize = nil, nil

		-- strip anything that could execute or float away inside the viewport
		local previousArchivable = character.Archivable
		character.Archivable = true
		local ok, result = pcall(function()
			return character:Clone()
		end)
		character.Archivable = previousArchivable
		if not ok or not result then
			return
		end
		clone = result
		for _, descendant in ipairs(clone:GetDescendants()) do
			if descendant:IsA("BaseScript") or descendant:IsA("ModuleScript") or descendant:IsA("BillboardGui") then
				descendant:Destroy()
			end
		end
		-- hold the model upright and frame off the bounding box, so R6/R15 and
		-- scaled avatars all crop correctly
		local root = clone:FindFirstChild("HumanoidRootPart")
		if root then
			root.Anchored = true
			root.CFrame = CFrame.new()
		end
		clone.Parent = worldModel
		boxCF, boxSize = clone:GetBoundingBox()
		applyCamera()
	end

	local function bindPlayer(player)
		bindToken += 1
		local token = bindToken
		if charAddedConn then
			charAddedConn:Disconnect()
			charAddedConn = nil
		end
		for index, spec in ipairs(INFO_ROWS) do
			local raw = player and player[spec.key]
			valueLabels[index].Text = (raw ~= nil and tostring(raw) or "") .. (spec.suffix or "")
		end
		if not player then
			if clone then
				clone:Destroy()
				clone = nil
			end
			boxCF, boxSize = nil, nil
			return
		end
		-- a respawn or player swap may have queued this attach late
		local function attachIfCurrent(character)
			if token == bindToken and frame.Parent then
				attach(character)
			end
		end
		if player.Character then
			attachIfCurrent(player.Character)
		end
		charAddedConn = player.CharacterAdded:Connect(function(character)
			task.defer(attachIfCurrent, character)
		end)
	end

	-- one RenderStepped connection; static views keep yaw fixed
	if rotating then
		renderConn = RunService.RenderStepped:Connect(function(deltaTime)
			if not self._pageActive then
				return
			end
			if not frame.Visible then
				return
			end
			yaw += deltaTime * ORBIT_SPEED
			applyCamera()
		end)
	end

	self.SetPlayer = function(_, player)
		bindPlayer(player or Players.LocalPlayer)
	end
	self.SetRotate = function(_, enabled)
		rotating = enabled == true
		if rotating and not renderConn then
			renderConn = RunService.RenderStepped:Connect(function(deltaTime)
				if not self._pageActive then
					return
				end
				if not frame.Visible then
					return
				end
				yaw += deltaTime * ORBIT_SPEED
				applyCamera()
			end)
		elseif not rotating and renderConn then
			renderConn:Disconnect()
			renderConn = nil
		end
	end
	self.SetFraming = function(_, mode)
		if FRAMING[mode] then
			framing = mode
			applyCamera()
		end
	end
	-- pause the orbit while the page is off screen (always on, no Gate: it
	-- saves per-frame camera math on a hidden view)
	PageAwareness.Register(frame, {
		OnInactive = function()
			self._pageActive = false
		end,
		OnActive = function()
			self._pageActive = true
		end,
	})
	if not PageAwareness.IsActive(frame) then
		self._pageActive = false
	end
	-- the orbit and respawn connections outlive the instance tree unless
	-- disconnected here
	self.Destroy = function(_self)
		if renderConn then
			renderConn:Disconnect()
			renderConn = nil
		end
		if charAddedConn then
			charAddedConn:Disconnect()
			charAddedConn = nil
		end
		if frame and frame.Parent then
			frame:Destroy()
		end
	end

	ThemeManager.BindColor(frame, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(frame, "BackgroundTransparency", "ComponentBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	ThemeManager.BindColor(viewport, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(viewport, "BackgroundTransparency", "InputBackgroundTransparency")
	for _, value in ipairs(valueLabels) do
		ThemeManager.BindColor(value, "TextColor3", "PrimaryTextColor")
		ThemeManager.BindTransparency(value, "TextTransparency", "PrimaryTextTransparency")
	end

	ComponentAPI.Apply(self, { Root = frame, Name = Settings.Name })
	bindPlayer(Settings.Player or Players.LocalPlayer)
	return self
end

return Viewport
