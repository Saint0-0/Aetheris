--[[
	Aetheris/Components/Viewport.luau

	Player card: a ViewportFrame rendering a live character clone beside
	customisable info rows and a slim health bar.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local ComponentAPI = require("../Utils/ComponentAPI")
local PageAwareness = require("../Utils/PageAwareness")
local Constants = require("../Constants")
local UUID = require("../Utils/UUID")

-- Framing crop: focus offset and distance as fractions of model height.
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

local STATIC_YAW = math.rad(-20) -- Slight 3/4 angle when not rotating.
local ORBIT_SPEED = 0.35 -- Radians per second; one revolution takes about 18s.

-- Health ramp from red to yellow to green; deliberately not theme-bound.
local HEALTH_LOW = Color3.fromRGB(226, 70, 70)
local HEALTH_MID = Color3.fromRGB(245, 195, 75)
local HEALTH_HIGH = Color3.fromRGB(85, 220, 110)
local function healthColour(ratio)
	ratio = math.clamp(ratio, 0, 1)
	if ratio < 0.5 then
		return HEALTH_LOW:Lerp(HEALTH_MID, ratio * 2)
	end
	return HEALTH_MID:Lerp(HEALTH_HIGH, (ratio - 0.5) * 2)
end

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
	-- The orbit early-returns off screen, which is cheaper than reconnecting.
	self._pageActive = true
	local height = Settings.Height or 160
	local framing = FRAMING[Settings.Framing] and Settings.Framing or "Full"
	local rotating = Settings.Rotate ~= false
	-- Info opts into the info column; HealthBar = false drops the side bar.
	local showInfo = type(Settings.Info) == "table"
	local healthBar = Settings.HealthBar ~= false
	-- Gap to the side bar, plus the bar width when present.
	local viewportRight = if healthBar then 7 else 3
	local infoRows = {}
	if showInfo then
		local specs = if #Settings.Info > 0 then Settings.Info else INFO_ROWS
		for _, entry in ipairs(specs) do
			table.insert(infoRows, {
				caption = entry.Caption or entry.caption or "",
				key = entry.Key or entry.key,
				text = entry.Text or entry.text,
				suffix = entry.Suffix or entry.suffix,
			})
		end
	end

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

	-- Holder owns the viewport and bar pair and is scale-positioned.
	local holder = Instance.new("Frame")
	holder.Name = UUID.Static("ViewportHolder")
	holder.BorderSizePixel = 0
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = if showInfo then Vector2.new(0, 0.5) else Vector2.new(0.5, 0.5)
	holder.Position = if showInfo then UDim2.new(0, 8, 0.5, 0) else UDim2.fromScale(0.5, 0.5)
	holder.Size = if showInfo then UDim2.fromScale(0.55, 0.9) else UDim2.fromScale(0.94, 0.9)
	holder.Parent = frame
	if showInfo then
		-- 150px cap plus margin, applied to the holder.
		local holderConstraint = Instance.new("UISizeConstraint")
		holderConstraint.MaxSize = Vector2.new(150 + viewportRight, math.huge)
		holderConstraint.Parent = holder
	end

	-- Input-well tint; the right margin leaves room for the health bar.
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = UUID.Static("PlayerViewport")
	viewport.BorderSizePixel = 0
	viewport.BackgroundColor3 = (theme and theme.InputBackgroundColor) or Color3.fromRGB(28, 33, 44)
	viewport.BackgroundTransparency = (theme and theme.InputBackgroundTransparency) or 0
	viewport.AnchorPoint = Vector2.new(0, 0)
	viewport.Position = UDim2.fromScale(0, 0)
	viewport.Size = UDim2.new(1, -viewportRight, 1, 0)
	viewport.Ambient = Color3.fromRGB(126, 126, 134)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1.2, -0.8).Unit
	viewport.Parent = holder
	newCorner(viewport, 4)

	-- Slim bar at the right edge, filled from the bottom by humanoid health.
	local healthTrack, healthStroke, healthFill
	if healthBar then
		healthTrack = Instance.new("Frame")
		healthTrack.Name = UUID.Static("HealthTrack")
		healthTrack.BorderSizePixel = 0
		healthTrack.AnchorPoint = Vector2.new(0, 0.5)
		healthTrack.Position = UDim2.new(1, -4, 0.5, 0)
		healthTrack.Size = UDim2.new(0, 4, 1, -5)
		healthTrack.BackgroundColor3 = (theme and theme.InputBackgroundColor) or Color3.fromRGB(28, 33, 44)
		healthTrack.BackgroundTransparency = (theme and theme.InputBackgroundTransparency) or 0
		healthTrack.Parent = holder
		newCorner(healthTrack, 2)
		healthStroke = Instance.new("UIStroke")
		healthStroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
		healthStroke.Color = (theme and theme.StrokeColor)
		healthStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		healthStroke.Parent = healthTrack

		healthFill = Instance.new("Frame")
		healthFill.Name = UUID.Static("HealthFill")
		healthFill.BorderSizePixel = 0
		healthFill.AnchorPoint = Vector2.new(0, 1)
		healthFill.Position = UDim2.fromScale(0, 1)
		healthFill.Size = UDim2.fromScale(1, 1)
		healthFill.BackgroundColor3 = healthColour(1)
		healthFill.Parent = healthTrack
		newCorner(healthFill, 2)
	end

	local camera = Instance.new("Camera")
	camera.FieldOfView = 60
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	-- Caption over value rows; skipped without an Info table.
	local valueLabels = {}
	if showInfo then
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

		for index, spec in ipairs(infoRows) do
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
			-- Static rows carry text; key rows fill in on bind.
			value.Text = if spec.text ~= nil then tostring(spec.text) .. (spec.suffix or "") else ""
			value.Parent = row
			valueLabels[index] = value
		end
	end

	local yaw = STATIC_YAW
	local boxCF, boxSize -- bounding box; nil until a clone exists
	local clone
	local renderConn, charAddedConn, healthConn
	local bindToken = 0

	local function applyCamera()
		if not boxSize then
			return
		end
		local mode = FRAMING[framing]
		local focus = boxCF.Position + Vector3.new(0, boxSize.Y * mode.focus, 0)
		local distance = boxSize.Y * mode.distance + 0.4
		local rotation = CFrame.Angles(0, yaw, 0)
		-- Characters face -Z, so yaw 0 frames the front with slight elevation.
		local camPos = focus + rotation:VectorToWorldSpace(Vector3.new(0, boxSize.Y * 0.05, -distance))
		camera.CFrame = CFrame.lookAt(camPos, focus)
	end

	-- Reads the source humanoid, which stays live unlike the stripped clone.
	local function bindHealth(character)
		if not healthFill then
			return
		end
		if healthConn then
			healthConn:Disconnect()
			healthConn = nil
		end
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		local function update()
			local max = humanoid.MaxHealth
			local ratio = if max > 0 then math.clamp(humanoid.Health / max, 0, 1) else 0
			healthFill.Size = UDim2.fromScale(1, ratio)
			Tween.Play(healthFill, "Fast", { BackgroundColor3 = healthColour(ratio) })
		end
		update()
		healthConn = humanoid.HealthChanged:Connect(update)
	end

	local function attach(character)
		if clone then
			clone:Destroy()
			clone = nil
		end
		boxCF, boxSize = nil, nil

		-- Strip anything that could execute or float inside the viewport.
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
		-- Frame off the bounding box so R6, R15 and scaled avatars crop evenly.
		local root = clone:FindFirstChild("HumanoidRootPart")
		if root then
			root.Anchored = true
			root.CFrame = CFrame.new()
		end
		clone.Parent = worldModel
		boxCF, boxSize = clone:GetBoundingBox()
		bindHealth(character)
		applyCamera()
	end

	local function bindPlayer(player)
		bindToken += 1
		local token = bindToken
		if charAddedConn then
			charAddedConn:Disconnect()
			charAddedConn = nil
		end
		for index, spec in ipairs(infoRows) do
			-- Static text rows never change; key rows read the player live.
			local label = valueLabels[index]
			if label and spec.key then
				local raw
				if player then
					local ok, value = pcall(function()
						return player[spec.key]
					end)
					if ok then
						raw = value
					end
				end
				label.Text = (raw ~= nil and tostring(raw) or "") .. (spec.suffix or "")
			end
		end
		if not player then
			bindHealth(nil)
			if clone then
				clone:Destroy()
				clone = nil
			end
			boxCF, boxSize = nil, nil
			return
		end
		-- A respawn or swap may queue this attach late.
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

	-- One RenderStepped connection; static views keep yaw fixed.
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

	-- Pause the orbit off page to skip per-frame camera maths.
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

	ThemeManager.BindColor(frame, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindTransparency(frame, "BackgroundTransparency", "ComponentBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	ThemeManager.BindColor(viewport, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(viewport, "BackgroundTransparency", "InputBackgroundTransparency")
	if healthBar then
		ThemeManager.BindColor(healthTrack, "BackgroundColor3", "InputBackgroundColor")
		ThemeManager.BindTransparency(healthTrack, "BackgroundTransparency", "InputBackgroundTransparency")
		-- The health fill follows humanoid health, never the theme.
		ThemeManager.BindColor(healthStroke, "Color", "StrokeColor")
		ThemeManager.BindTransparency(healthStroke, "Transparency", "StrokeTransparency")
	end
	for _, value in ipairs(valueLabels) do
		ThemeManager.BindColor(value, "TextColor3", "PrimaryTextColor")
		ThemeManager.BindTransparency(value, "TextTransparency", "PrimaryTextTransparency")
	end

	ComponentAPI.Apply(self, {
		Root = frame,
		Name = Settings.Name,
		Methods = {
			SetPlayer = function(_, player)
				bindPlayer(player or Players.LocalPlayer)
			end,
			SetRotate = function(_, enabled)
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
			end,
			SetFraming = function(_, mode)
				if FRAMING[mode] then
					framing = mode
					applyCamera()
				end
			end,
			Destroy = function(_self)
				-- Disconnect orbit, respawn and health connections explicitly.
				if renderConn then
					renderConn:Disconnect()
					renderConn = nil
				end
				if charAddedConn then
					charAddedConn:Disconnect()
					charAddedConn = nil
				end
				if healthConn then
					healthConn:Disconnect()
					healthConn = nil
				end
				if frame and frame.Parent then
					frame:Destroy()
				end
			end,
		},
	})
	bindPlayer(Settings.Player or Players.LocalPlayer)
	return self
end

return Viewport
