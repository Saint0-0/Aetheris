--[[
	Aetheris/Popups/KeyScreen.luau

	Combined loading and key-system card shown before the window builds when
	CreateWindow receives a KeySystem table. It plays the loading steps, then
	crossfades into the key UI when a key is required.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

--# selene: allow(undefined_variable)
-- Executor APIs are injected at runtime and probed with type() checks.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")

local Tween = require("../Utils/Tween")
local UUID = require("../Utils/UUID")
local Sound = require("../Utils/Sound")
local Aurora = require("../Utils/Aurora")
local Odometer = require("../Utils/Odometer")
local Security = require("../Utils/Security")
local ThemeManager = require("../Themes/ThemeManager")
local ThemeDefinitions = require("../Themes/ThemeDefinitions")
local KeyServices = require("../Core/KeyServices")
local SettingsStore = require("../Core/Settings/SettingsStore")
local Notification = require("./Notification")
local Constants = require("../Constants")
local Icons = require("../Assets/Icons")
local Locale = require("../Utils/Locale")

local KeyScreen = {}
KeyScreen.__index = KeyScreen

local CARD_WIDTH = 460
local LOADING_HEIGHT = 274
local KEY_HEIGHT = 300
local FADE_IN = 0.25
local FADE_OUT = 0.2
local INTRO_HOLD = 0.85
local SUCCESS_HOLD = 1.3
local HEADER_HEIGHT = 62
local CONTENT_PAD = 18
local HEADER_ROW_Y = HEADER_HEIGHT / 2 - 4
local HEADER_CHIP = 24
local HEADER_CLOSE = 28
local HEADER_CHIP_GAP = 8
local HEADER_INSET = 12

-- Close button hover, matching the changelog's icon timing.
local ICON_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ICON_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_ICON = Icons["circle-x"] or "rbxassetid://76821953846248"

-- Images warmed by the first loading step for first paint.
local PRELOAD_IMAGES = {
	"rbxassetid://92458734285074",
	Icons["sparkles"],
	Icons["key"],
	Icons["link"],
	Icons["info"],
	Icons["circle-x"],
	Icons["bell"],
	Icons["triangle-alert"],
	Icons["shield-alert"],
	Icons["minimize-2"],
	Icons["check"],
	Icons["x"],
	Icons["image"],
	Icons["volume-2"],
	Icons["shield-check"],
	Icons["key-round"],
	Icons["circle"],
}

local SUCCESS_COLOR = Color3.fromRGB(74, 200, 120)
local WARN_COLOR = Color3.fromRGB(249, 115, 22)
local ERROR_COLOR = Color3.fromRGB(226, 42, 42)

local function new(className, props)
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		if key == "Parent" then
			inst.Parent = value
		else
			inst[key] = value
		end
	end
	return inst
end

-- CanvasGroup transparency skips UIStroke and UIShadow, so capture them.
local function captureFade(root)
	local targets = {}
	local function scan(inst)
		if inst:IsA("UIStroke") or inst:IsA("UIShadow") then
			table.insert(targets, { inst, "Transparency", inst.Transparency })
		end
		for _, child in ipairs(inst:GetChildren()) do
			scan(child)
		end
	end
	scan(root)
	return targets
end

-- Scales each decoration toward 1 from its own rest, never toward opaque.
local function fadeTo(targets, value, duration)
	for _, target in ipairs(targets or {}) do
		local base = target[3]
		Tween.Play(target[1], TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			[target[2]] = base + (1 - base) * value,
		})
	end
end

local function fadeRestore(targets, duration)
	for _, target in ipairs(targets or {}) do
		Tween.Play(target[1], TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			[target[2]] = target[3],
		})
	end
end

local function getExecutorName()
	if type(identifyexecutor) == "function" then
		local ok, name = pcall(identifyexecutor)
		if ok and name ~= nil and tostring(name) ~= "" then
			return tostring(name)
		end
	end
	return "Unknown"
end

local function getExecutorStatus()
	local hasHttp = type(request) == "function"
		or type(http_request) == "function"
		or (type(syn) == "table" and type(syn.request) == "function")
		or (type(http) == "table" and type(http.request) == "function")
	local hasFile = type(writefile) == "function" and type(readfile) == "function"
	local hasClipboard = type(setclipboard) == "function"

	if hasHttp and hasFile and hasClipboard then
		return "Full", SUCCESS_COLOR
	elseif hasHttp or hasFile or hasClipboard then
		return "Limited", WARN_COLOR
	end
	return "Restricted", ERROR_COLOR
end

local function formatCount(value)
	if value == nil then
		return nil
	end
	if value >= 1000000 then
		return ("%.1fm"):format(value / 1000000)
	elseif value >= 1000 then
		return ("%.1fk"):format(value / 1000)
	end
	return tostring(value)
end

local function agoText(timestamp)
	if type(timestamp) ~= "number" then
		return "never"
	end
	local seconds = math.max(0, os.time() - timestamp)
	if seconds < 60 then
		return "just now"
	elseif seconds < 3600 then
		return math.floor(seconds / 60) .. "m ago"
	elseif seconds < 86400 then
		return math.floor(seconds / 3600) .. "h ago"
	end
	return math.floor(seconds / 86400) .. "d ago"
end

-- Card grammar: neutral fill under a 35-degree aurora wash.

local FALLBACK_NEUTRAL = Color3.fromRGB(34, 34, 38)
local AURORA_TINT = 0.14

local function isDark(color)
	return (color.R * 0.299 + color.G * 0.587 + color.B * 0.114) < 0.5
end

local function cardBase(theme)
	return (theme and theme.PopupNeutralColor) or (theme and theme.ComponentBackgroundColor) or FALLBACK_NEUTRAL
end

-- UIGradient.Color multiplies, so the keypoints are multipliers.
local function stampCardGradient(gradient, theme)
	local base = cardBase(theme)
	local bottom = if isDark(base) then 0.72 else 0.9
	local corner = Color3.new(1, 1, 1)
	if theme and theme.AccentColor then
		corner = corner:Lerp(theme.AccentColor, AURORA_TINT)
	end
	gradient.Rotation = 35
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, corner),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(bottom, bottom, bottom)),
	})
end

-- Tile fills derive from theme slots so they follow light/dark themes.
local function tileFill(tint, base)
	if isDark(base) then
		return base:Lerp(tint, 0.4):Lerp(Color3.new(0, 0, 0), 0.35)
	end
	return base:Lerp(tint, 0.3)
end

-- Pending rows sit a hair off the card fill so the tile still reads as one.
local function neutralTile(base)
	if isDark(base) then
		return base:Lerp(Color3.new(1, 1, 1), 0.1)
	end
	return base:Lerp(Color3.new(0, 0, 0), 0.06)
end

-- Accent text: hue kept, saturation capped, value forced on dark grounds.
local function accentText(color, onDark)
	if onDark then
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, math.min(s, 0.75), math.max(v, 0.92))
	end
	return color:Lerp(Color3.new(0, 0, 0), 0.3)
end

-- Registries let the theme switch restamp every card and tile.
local function rememberGradient(self, gradient)
	self._cardGradients = self._cardGradients or {}
	self._cardGradients[#self._cardGradients + 1] = gradient
end

local function rememberTile(self, tile, glyph)
	self._tiles = self._tiles or {}
	self._tiles[#self._tiles + 1] = { Tile = tile, Glyph = glyph }
end

local function restampTiles(self, theme)
	local base = cardBase(theme)
	local tint = (theme and theme.AccentColor) or Color3.fromRGB(96, 165, 250)
	for _, record in ipairs(self._tiles or {}) do
		record.Tile.BackgroundColor3 = tileFill(tint, base)
		record.Glyph.ImageColor3 = accentText(tint, isDark(base))
	end
end

local function buildCard(self)
	local theme = self._theme

	local gui = new("ScreenGui", {
		Name = UUID.Static("KeyScreen"),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		DisplayOrder = 50,
	})
	if self._opts.Parent ~= nil then
		gui.Parent = self._opts.Parent
	elseif self._secure then
		Security.Apply(gui, { Player = self._player })
	else
		local playerGui = self._player and self._player:FindFirstChild("PlayerGui")
		if not playerGui and self._player then
			playerGui = self._player:WaitForChild("PlayerGui", 5)
		end
		gui.Parent = playerGui or game:GetService("CoreGui")
	end
	self._gui = gui

	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
	local cardScale = math.clamp(((viewport and viewport.X or 1200) - 32) / CARD_WIDTH, 0.6, 1)

	local card = new("CanvasGroup", {
		Name = UUID.Static("Card"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(CARD_WIDTH, LOADING_HEIGHT),
		BackgroundColor3 = theme.WindowColor or Color3.fromRGB(15, 15, 16),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Parent = gui,
	})
	self._card = card

	new("UIScale", { Scale = cardScale, Parent = card })
	new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = card }) -- Shell radius.
	-- Top-down static multiplier so the fill never reads flat.
	new("UIGradient", {
		Name = UUID.Static("CardWash"),
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(0.9, 0.9, 0.9)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		}),
		Parent = card,
	})
	local stroke = new("UIStroke", {
		Color = theme.StrokeColor or Color3.fromRGB(255, 255, 255),
		-- Base at full paint; the open/close fade returns it here from hidden.
		Transparency = 0,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = card,
	})
	-- Rim ramp keeps the top edge painted so the card reads top-lit.
	new("UIGradient", {
		Name = UUID.Static("CardRim"),
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.84),
			NumberSequenceKeypoint.new(0.5, 0.92),
			NumberSequenceKeypoint.new(1, 0.78),
		}),
		Parent = stroke,
	})
	local shadow = new("UIShadow", {
		Color = theme.MainframeShadowColor or Color3.new(0, 0, 0),
		Transparency = 0.45,
		BlurRadius = UDim.new(0, 26),
		Offset = UDim2.fromOffset(0, 10),
		Parent = card,
	})
	shadow:SetAttribute(UUID.Static("PageFadeBase"), shadow.Transparency)

	local clip = new("Frame", {
		Name = UUID.Static("Clip"),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 0,
		Parent = card,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = clip })
	self._aurora = Aurora.new(clip, { Theme = theme, Transparency = 0.35 })

	-- Instant drag follows the cursor; Smooth tweens the card.
	local dragFrame = new("Frame", {
		Name = UUID.Static("DragArea"),
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = card,
	})
	do
		local dragging = false
		local dragStart, startPosition
		local inputEndedConn

		dragFrame.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = true
				dragStart = input.Position
				-- Top-left anchoring so offset positions track the cursor 1:1.
				local absolute = card.AbsolutePosition
				card.AnchorPoint = Vector2.new(0, 0)
				card.Position = UDim2.fromOffset(absolute.X, absolute.Y)
				startPosition = absolute

				if inputEndedConn then
					inputEndedConn:Disconnect()
				end
				inputEndedConn = UserInputService.InputEnded:Connect(function(ended)
					if
						ended.UserInputType == Enum.UserInputType.MouseButton1
						or ended.UserInputType == Enum.UserInputType.Touch
					then
						dragging = false
						inputEndedConn:Disconnect()
						inputEndedConn = nil
					end
				end)
			end
		end)

		self._dragConn = UserInputService.InputChanged:Connect(function(input)
			if
				dragging
				and (
					input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				)
			then
				local delta = input.Position - dragStart
				local target = UDim2.fromOffset(startPosition.X + delta.X, startPosition.Y + delta.Y)
				if self._dragStyle == "Smooth" then
					Tween.Play(card, "Fast", { Position = target })
				else
					card.Position = target
				end
			end
		end)
	end

	-- Hidden during the intro, faded in with the loading body.
	local headerGroup = new("CanvasGroup", {
		Name = UUID.Static("HeaderGroup"),
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		ZIndex = 4,
		Parent = card,
	})
	self._headerGroup = headerGroup

	local brandTile = new("Frame", {
		Name = UUID.Static("BrandTile"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(18, 35),
		-- Matches the window sidebar mark so the art keeps its proportions.
		Size = UDim2.fromOffset(40, 32),
		-- The mark sits bare on the shell, with no tile behind it.
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = headerGroup,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = brandTile })
	local brandIcon = new("ImageLabel", {
		Name = UUID.Static("BrandIcon"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://92458734285074",
		ImageColor3 = Color3.new(1, 1, 1),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 4,
		Parent = brandTile,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = brandIcon })

	local title = new("TextLabel", {
		Name = UUID.Static("Title"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(66, 25),
		Size = UDim2.new(1, -(CONTENT_PAD + 44 + 120), 0, 18),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.SemiBold),
		Text = self._opts.Title or "Aetheris",
		TextSize = 15,
		TextColor3 = theme.TitleTextColor or Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		Parent = headerGroup,
	})
	local subtitle = new("TextLabel", {
		Name = UUID.Static("Subtitle"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(66, 45),
		Size = UDim2.new(1, -(CONTENT_PAD + 44 + 120), 0, 12),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		Text = "Key System",
		TextSize = 10,
		TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		Parent = headerGroup,
	})

	local execName = getExecutorName()
	local execStatus, execColor = getExecutorStatus()
	local execWidth = math.clamp(#execName * 6.2 + 34, 70, 150)
	local chipTransparency = (theme.InputBackgroundTransparency or 0.9) + 0.02
	-- Chip and close share one pill, fill and hairline stroke.
	local execChip = new("Frame", {
		Name = UUID.Static("ExecutorChip"),
		AnchorPoint = Vector2.new(1, 0.5),
		-- Inset past the close button so the chip never slides under it.
		Position = UDim2.new(1, -(HEADER_INSET + HEADER_CLOSE + HEADER_CHIP_GAP), 0, HEADER_ROW_Y),
		Size = UDim2.fromOffset(execWidth, HEADER_CHIP),
		BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = chipTransparency,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = headerGroup,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = execChip })
	local chipStroke = new("UIStroke", {
		Color = theme.StrokeColor or Color3.new(1, 1, 1),
		Transparency = 0.9,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = execChip,
	})
	local statusDot = new("Frame", {
		Name = UUID.Static("StatusDot"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = execColor,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = execChip,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = statusDot })
	new("TextLabel", {
		Name = UUID.Static("ExecutorText"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 22, 0.5, 0),
		Size = UDim2.new(1, -28, 1, 0),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		Text = execName .. " · " .. execStatus,
		TextSize = 10,
		TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		Parent = execChip,
	})

	-- Above the drag frame, so a click never starts a drag. Same treatment as
	-- the changelog's close: a soft white circle with no stroke.
	local closeButton = new("ImageButton", {
		Name = UUID.Static("CloseButton"),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -HEADER_INSET, 0, HEADER_ROW_Y),
		Size = UDim2.fromOffset(HEADER_CLOSE, HEADER_CLOSE),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ZIndex = 6,
		Parent = card,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = closeButton })
	local closeIcon = new("ImageLabel", {
		Name = UUID.Static("CloseIcon"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = CLOSE_ICON,
		ImageColor3 = theme.PopupTextColor or Color3.fromRGB(255, 255, 255),
		ImageTransparency = 0.35,
		ZIndex = 6,
		Parent = closeButton,
	})
	closeButton.MouseEnter:Connect(function()
		Tween.Play(closeButton, ICON_IN, { BackgroundTransparency = 0.86 })
		Tween.Play(closeIcon, ICON_IN, { ImageTransparency = 0 })
	end)
	closeButton.MouseLeave:Connect(function()
		Tween.Play(closeButton, ICON_OUT, { BackgroundTransparency = 0.92 })
		Tween.Play(closeIcon, ICON_OUT, { ImageTransparency = 0.35 })
	end)
	closeButton.MouseButton1Click:Connect(function()
		self:_dismiss()
	end)
	self._closeButton = closeButton
	self._closeIcon = closeIcon
	self._execChip = execChip
	-- One restamp list so a live theme switch keeps the cluster in sync.
	self._headerStrokes = { chipStroke }

	self._title = title
	self._subtitle = subtitle
	self._stroke = stroke
	self._shadow = shadow
end

local function buildIntro(self)
	local theme = self._theme

	local body = new("CanvasGroup", {
		Name = UUID.Static("IntroBody"),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = self._card,
	})
	self._introBody = body

	local ringSize = 78
	local ring = new("Frame", {
		Name = UUID.Static("IntroRing"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(ringSize, ringSize),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
	local ringStroke = new("UIStroke", {
		Color = theme.StrokeColor or Color3.fromRGB(255, 255, 255),
		Transparency = 0.2,
		Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = ring,
	})
	local comet = new("UIGradient", {
		Color = ColorSequence.new(theme.AccentColor or Color3.fromRGB(14, 45, 178)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.14, 0.28),
			NumberSequenceKeypoint.new(0.32, 0.86),
			NumberSequenceKeypoint.new(1, 0.86),
		}),
		Rotation = 0,
		Parent = ringStroke,
	})

	-- Soft accent disc behind the mark so the ring reads as lit, not drawn.
	local halo = new("Frame", {
		Name = UUID.Static("IntroHalo"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(62, 62),
		BackgroundColor3 = theme.AccentColor or Color3.fromRGB(96, 165, 250),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = ring,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = halo })
	Tween.Play(halo, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.95,
	})

	local tile = new("Frame", {
		Name = UUID.Static("IntroTile"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(50, 50),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = ring,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = tile })
	new("ImageLabel", {
		Name = UUID.Static("IntroIcon"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1,
		Image = "rbxassetid://92458734285074",
		ImageColor3 = Color3.new(1, 1, 1),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 4,
		Parent = tile,
	})

	new("TextLabel", {
		Name = UUID.Static("IntroBrand"),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, ringSize / 2 + 18),
		Size = UDim2.new(1, -40, 0, 18),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.SemiBold),
		Text = self._opts.Title or "Aetheris",
		TextSize = 15,
		TextColor3 = theme.TitleTextColor or Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 4,
		Parent = body,
	})
	new("TextLabel", {
		Name = UUID.Static("IntroHint"),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, ringSize / 2 + 38),
		Size = UDim2.new(1, -40, 0, 13),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		Text = "Getting things ready",
		TextSize = 11,
		TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 4,
		Parent = body,
	})

	self._introComet = comet
	self._introHalo = halo
	self._introSpin = Tween.StartSpin(comet, { Rotation = 360 }, "SpinBurst")
	self._introFadeTargets = captureFade(body)
end

local function buildLoading(self)
	local theme = self._theme
	local base = cardBase(theme)
	local accent = theme.AccentColor or Color3.fromRGB(96, 165, 250)

	-- One GroupTransparency carries the phase crossfade; starts hidden.
	local body = new("CanvasGroup", {
		Name = UUID.Static("LoadingBody"),
		Position = UDim2.fromOffset(0, HEADER_HEIGHT),
		Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 3,
		Parent = self._card,
	})
	self._loadingBody = body

	-- Live status: current step icon, title, counter and percent chip.
	local statusRow = new("Frame", {
		Name = UUID.Static("StatusRow"),
		Position = UDim2.fromOffset(CONTENT_PAD, 10),
		Size = UDim2.new(1, -(CONTENT_PAD * 2), 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = body,
	})

	local statusTile = new("Frame", {
		Name = UUID.Static("StatusTile"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = tileFill(accent, base),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = statusRow,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = statusTile })
	local statusGlyph = new("ImageLabel", {
		Name = UUID.Static("StatusGlyph"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Image = Icons["sparkles"] or "rbxassetid://138635884129147",
		ImageColor3 = accentText(accent, isDark(base)),
		ZIndex = 3,
		Parent = statusTile,
	})
	local statusScale = new("UIScale", { Scale = 1, Parent = statusTile })

	local statusTitle = new("TextLabel", {
		Name = UUID.Static("StatusTitle"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 52, 0.5, -9),
		Size = UDim2.new(1, -(52 + 58), 0, 18),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.SemiBold),
		Text = Locale.resolve("Preparing"),
		TextSize = 14,
		TextColor3 = theme.PrimaryTextColor or Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = statusRow,
	})
	local statusSub = new("TextLabel", {
		Name = UUID.Static("StatusSub"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 52, 0.5, 9),
		Size = UDim2.new(1, -(52 + 58), 0, 14),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		Text = Locale.resolve("Getting things ready"),
		TextSize = 10,
		TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = statusRow,
	})

	local chipTransparency = math.min((theme.InputBackgroundTransparency or 0.9) + 0.03, 1)
	local percentChip = new("Frame", {
		Name = UUID.Static("PercentChip"),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(48, 22),
		BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = chipTransparency,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = statusRow,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = percentChip })
	local chipStroke = new("UIStroke", {
		Color = theme.StrokeColor or Color3.new(1, 1, 1),
		Transparency = 0.9,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = percentChip,
	})
	local percentHolder = new("Frame", {
		Name = UUID.Static("Percent"),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = percentChip,
	})
	local percent = Odometer.new(percentHolder, {
		textSize = 11,
		height = 14,
		alignment = Enum.HorizontalAlignment.Center,
		textColor = theme.PrimaryTextColor,
	})
	percent:snap("0%")

	-- Progress rail: accent fill plus one moving highlight wave.
	local barTrack = new("Frame", {
		Name = UUID.Static("BarTrack"),
		Position = UDim2.fromOffset(CONTENT_PAD, 58),
		Size = UDim2.new(1, -(CONTENT_PAD * 2), 0, 6),
		BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = math.min((theme.InputBackgroundTransparency or 0.9) + 0.03, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 3,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barTrack })
	local fill = new("Frame", {
		Name = UUID.Static("BarFill"),
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Parent = barTrack,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	local fillGradient = new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, accent),
			ColorSequenceKeypoint.new(1, theme.PrimaryColor or Color3.fromRGB(13, 44, 177)),
		}),
		Rotation = 25,
		Parent = fill,
	})
	local sheen = new("Frame", {
		Name = UUID.Static("BarSheen"),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = fill,
	})
	local sheenGradient = new("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 1),
			NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(0.7, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Offset = Vector2.new(-0.6, 0),
		Parent = sheen,
	})

	-- Step list: one tinted tile per task, filled as the run advances.
	local stepsCard = new("Frame", {
		Name = UUID.Static("Steps"),
		Position = UDim2.fromOffset(CONTENT_PAD, 72),
		Size = UDim2.new(1, -(CONTENT_PAD * 2), 0, 112),
		BackgroundColor3 = base,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = stepsCard })
	local stepsGradient = new("UIGradient", { Parent = stepsCard })
	stampCardGradient(stepsGradient, theme)
	rememberGradient(self, stepsGradient)
	ThemeManager.BindColor(stepsCard, "BackgroundColor3", "PopupNeutralColor")
	local stepsStroke = new("UIStroke", {
		Color = theme.StrokeColor or Color3.new(1, 1, 1),
		Transparency = 0.9,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = stepsCard,
	})
	local stepsPad = new("UIPadding", { Parent = stepsCard })
	stepsPad.PaddingTop = UDim.new(0, 6)
	stepsPad.PaddingBottom = UDim.new(0, 6)
	stepsPad.PaddingLeft = UDim.new(0, 8)
	stepsPad.PaddingRight = UDim.new(0, 10)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = stepsCard,
	})

	local rows = {}
	for index, step in ipairs(self._steps) do
		local row = new("Frame", {
			Name = UUID.Static("StepRow"),
			Size = UDim2.new(1, 0, 0, 25),
			BackgroundTransparency = 1,
			LayoutOrder = index,
			Parent = stepsCard,
		})
		local tile = new("Frame", {
			Name = UUID.Static("StepTile"),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = neutralTile(base),
			BorderSizePixel = 0,
			Parent = row,
		})
		new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tile })
		local glyph = new("ImageLabel", {
			Name = UUID.Static("StepGlyph"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(11, 11),
			BackgroundTransparency = 1,
			Image = Icons[step.Icon] or Icons["circle"],
			ImageColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
			ImageTransparency = 0.35,
			Parent = tile,
		})
		local scale = new("UIScale", { Scale = 1, Parent = tile })
		local label = new("TextLabel", {
			Name = UUID.Static("StepLabel"),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 28, 0.5, 0),
			Size = UDim2.new(1, -(28 + 66), 1, 0),
			BackgroundTransparency = 1,
			FontFace = Constants.Font(Enum.FontWeight.Medium),
			Text = step.Label,
			TextSize = 12,
			TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
			TextTransparency = 0.15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		local status = new("TextLabel", {
			Name = UUID.Static("StepStatus"),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -2, 0.5, 0),
			Size = UDim2.fromOffset(58, 14),
			BackgroundTransparency = 1,
			FontFace = Constants.Font(Enum.FontWeight.Medium),
			Text = Locale.resolve("Queued"),
			TextSize = 10,
			TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
			TextTransparency = 0.45,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		rows[index] = {
			Tile = tile,
			Glyph = glyph,
			Label = label,
			Status = status,
			Scale = scale,
			Icon = Icons[step.Icon] or Icons["circle"],
			State = "pending",
		}
	end

	new("TextLabel", {
		Name = UUID.Static("LoadingHint"),
		Position = UDim2.fromOffset(CONTENT_PAD, 192),
		Size = UDim2.new(1, -(CONTENT_PAD * 2), 0, 12),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		Text = Locale.resolve("This only takes a moment."),
		TextSize = 10,
		TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
		TextTransparency = 0.3,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = body,
	})

	self._stepRows = rows
	self._stepIndex = 1
	self._statusRow = statusRow
	self._statusTile = statusTile
	self._statusGlyph = statusGlyph
	self._statusScale = statusScale
	self._statusTitle = statusTitle
	self._statusSub = statusSub
	self._percentChip = percentChip
	self._percentChipStroke = chipStroke
	self._barTrack = barTrack
	self._barFill = fill
	self._barGradient = fillGradient
	self._sheenGradient = sheenGradient
	self._sheenSpin = Tween.StartSpin(sheenGradient, { Offset = Vector2.new(1, 0) }, "SpinBurst")
	self._stepsStroke = stepsStroke
	self._stepsCard = stepsCard
	self._percent = percent
end

-- Row states: pending, active, done or failed. Repaint is shared with theming.
local function paintStepRow(self, row, state, animate)
	if not row then
		return
	end
	local theme = self._theme
	local base = cardBase(theme)
	local accent = theme.AccentColor or Color3.fromRGB(96, 165, 250)
	local onDark = isDark(base)
	row.State = state
	if row.Pulse then
		Tween.Cancel(row.Pulse)
		row.Pulse = nil
	end
	row.Tile.BackgroundTransparency = 0
	row.Glyph.ImageTransparency = 0
	row.Label.TextTransparency = 0
	row.Status.TextTransparency = 0

	if state == "done" then
		row.Tile.BackgroundColor3 = tileFill(SUCCESS_COLOR, base)
		row.Glyph.Image = Icons["check"] or row.Icon
		row.Glyph.ImageColor3 = accentText(SUCCESS_COLOR, onDark)
		row.Label.TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
		row.Status.Text = Locale.resolve("Done")
		row.Status.TextColor3 = accentText(SUCCESS_COLOR, onDark)
	elseif state == "failed" then
		row.Tile.BackgroundColor3 = tileFill(ERROR_COLOR, base)
		row.Glyph.Image = Icons["x"] or row.Icon
		row.Glyph.ImageColor3 = accentText(ERROR_COLOR, onDark)
		row.Label.TextColor3 = theme.PrimaryTextColor or Color3.new(1, 1, 1)
		row.Status.Text = Locale.resolve("Failed")
		row.Status.TextColor3 = accentText(ERROR_COLOR, onDark)
	elseif state == "active" then
		row.Tile.BackgroundColor3 = tileFill(accent, base)
		row.Glyph.Image = row.Icon
		row.Glyph.ImageColor3 = accentText(accent, onDark)
		row.Label.TextColor3 = theme.PrimaryTextColor or Color3.new(1, 1, 1)
		row.Status.Text = Locale.resolve("Working")
		row.Status.TextColor3 = accentText(accent, onDark)
		row.Pulse =
			Tween.Play(row.Tile, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
				BackgroundTransparency = 0.3,
			})
	else
		row.Tile.BackgroundColor3 = neutralTile(base)
		row.Glyph.Image = row.Icon
		row.Glyph.ImageColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
		row.Glyph.ImageTransparency = 0.35
		row.Label.TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
		row.Label.TextTransparency = 0.15
		row.Status.Text = Locale.resolve("Queued")
		row.Status.TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
		row.Status.TextTransparency = 0.45
	end

	if animate ~= false and (state == "done" or state == "failed") then
		row.Scale.Scale = 0.86
		Tween.Play(row.Scale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
	end
end

local function setStepState(self, index, state)
	paintStepRow(self, self._stepRows[index], state, true)
end

local function setProgress(self, fraction, label)
	if not self._card then
		return
	end
	fraction = math.clamp(fraction, 0, 1)
	Tween.Play(self._barFill, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(fraction, 1),
	})
	self._percent:to(math.floor(fraction * 100 + 0.5) .. "%", true)
	if label and self._statusSub then
		self._statusSub.Text = string.format("Step %d of %d · %s", self._stepIndex or 1, #self._steps, label)
	end
end

local function buttonMotion(button)
	local scale = new("UIScale", { Parent = button, Scale = 1 })
	button.MouseEnter:Connect(function()
		Tween.Play(scale, "HoverIn", { Scale = 1.02 })
	end)
	button.MouseLeave:Connect(function()
		Tween.Play(scale, "HoverOut", { Scale = 1 })
	end)
	button.MouseButton1Down:Connect(function()
		Tween.Play(scale, "Fast", { Scale = 0.97 })
	end)
	button.MouseButton1Up:Connect(function()
		Tween.Play(scale, "HoverIn", { Scale = 1.02 })
	end)
	return scale
end

local function copyLink(self, url)
	if url == nil or url == "" then
		Notification.new(self._notifHolder, {
			Type = "Error",
			Title = "No link",
			Description = "The link isn't configured yet.",
			Duration = 4,
		}, self._theme):Show()
		return
	end
	if KeyServices.CopyToClipboard(url) then
		Notification.new(self._notifHolder, {
			Type = "Variable",
			Title = "Link copied",
			Description = "Open it in your browser to grab a key.",
			Duration = 4,
		}, self._theme):Show()
	else
		-- Without a clipboard, show the link so it stays usable.
		Notification.new(self._notifHolder, {
			Type = "Alert",
			Title = "Key link",
			Description = url,
			Duration = 7,
		}, self._theme):Show()
	end
end

local function buildKeyPhase(self)
	local theme = self._theme

	local body = new("CanvasGroup", {
		Name = UUID.Static("KeyBody"),
		Position = UDim2.fromOffset(0, HEADER_HEIGHT),
		Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 3,
		Parent = self._card,
	})
	self._keyBody = body

	local field = new("TextBox", {
		Name = UUID.Static("KeyInput"),
		Position = UDim2.fromOffset(CONTENT_PAD, 10),
		Size = UDim2.new(1, -(CONTENT_PAD * 2), 0, 40),
		BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = theme.InputBackgroundTransparency or 0.9,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		PlaceholderText = Locale.resolve("Enter your key"),
		PlaceholderColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
		Text = "",
		TextSize = 13,
		TextColor3 = theme.PrimaryTextColor or Color3.new(1, 1, 1),
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = field })
	local fieldStroke = new("UIStroke", {
		Color = theme.StrokeColor or Color3.fromRGB(80, 80, 80),
		Transparency = math.max(theme.StrokeTransparency or 0.95, 0.85),
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = field,
	})
	fieldStroke:SetAttribute(UUID.Static("PageFadeBase"), fieldStroke.Transparency)
	local fieldGlow = new("UIStroke", {
		Color = theme.AccentColor or Color3.fromRGB(108, 140, 255),
		Transparency = 1,
		Thickness = 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = field,
	})
	local PAD = 12
	local padding = new("UIPadding", { Parent = field })
	padding.PaddingLeft = UDim.new(0, PAD + 26)
	padding.PaddingRight = UDim.new(0, PAD)

	new("ImageLabel", {
		Name = UUID.Static("KeyIcon"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -25, 0.5, 0),
		Size = UDim2.fromOffset(15, 15),
		BackgroundTransparency = 1,
		Image = Icons["key"] or Icons["link"],
		ImageColor3 = theme.AccentColor or Color3.fromRGB(108, 140, 255),
		ZIndex = 3,
		Parent = field,
	})

	field.Focused:Connect(function()
		Tween.Play(fieldGlow, "Smooth", { Transparency = 0.6 })
		Tween.Play(fieldStroke, "Smooth", { Transparency = 1 })
	end)
	field.FocusLost:Connect(function(enterPressed)
		Tween.Play(fieldGlow, "Smooth", { Transparency = 1 })
		Tween.Play(fieldStroke, "Smooth", { Transparency = math.max(theme.StrokeTransparency or 0.95, 0.85) })
		if enterPressed then
			self:_submitKey()
		end
	end)
	self._field = field
	self._fieldGlow = fieldGlow

	new("TextLabel", {
		Name = UUID.Static("Microcopy"),
		Position = UDim2.fromOffset(CONTENT_PAD, 56),
		Size = UDim2.new(1, -(CONTENT_PAD * 2), 0, 13),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		Text = "Press enter to continue",
		TextSize = 10,
		TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = body,
	})

	local continue = new("TextButton", {
		Name = UUID.Static("Continue"),
		Position = UDim2.fromOffset(CONTENT_PAD, 78),
		Size = UDim2.fromOffset(248, 40),
		BackgroundColor3 = theme.AccentColor or Color3.fromRGB(14, 45, 178),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		FontFace = Constants.Font(Enum.FontWeight.SemiBold),
		Text = "Continue",
		TextSize = 13,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = continue })
	buttonMotion(continue)
	self._continue = continue
	continue.MouseButton1Click:Connect(function()
		self:_submitKey()
	end)

	local getKey = new("TextButton", {
		Name = UUID.Static("GetKey"),
		Position = UDim2.fromOffset(CONTENT_PAD + 258, 78),
		Size = UDim2.new(1, -(CONTENT_PAD * 2 + 258), 0, 40),
		BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = theme.InputBackgroundTransparency or 0.9,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		Text = "Get a key",
		TextSize = 12,
		TextColor3 = theme.PrimaryTextColor or Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = getKey })
	new("UIStroke", {
		Color = theme.StrokeColor or Color3.fromRGB(255, 255, 255),
		Transparency = math.max(theme.StrokeTransparency or 0.9, 0.85),
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = getKey,
	})
	new("ImageLabel", {
		Name = UUID.Static("LinkIcon"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Image = Icons["link"] or Icons["external-link"],
		ImageColor3 = theme.AccentColor or Color3.fromRGB(108, 140, 255),
		ZIndex = 3,
		Parent = getKey,
	})
	buttonMotion(getKey)
	getKey.MouseButton1Click:Connect(function()
		local url = self._validator:GetKeyLink()
		copyLink(self, url)
	end)

	local infoWidth = 168
	local discordWidth = CARD_WIDTH - (CONTENT_PAD * 2) - infoWidth - 10
	local cardsY = 134

	local discordCard = new("TextButton", {
		Name = UUID.Static("DiscordCard"),
		Position = UDim2.fromOffset(CONTENT_PAD, cardsY),
		Size = UDim2.fromOffset(discordWidth, 74),
		BackgroundColor3 = cardBase(theme),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = discordCard })
	local dcGradient = new("UIGradient", { Parent = discordCard })
	stampCardGradient(dcGradient, theme)
	rememberGradient(self, dcGradient)
	ThemeManager.BindColor(discordCard, "BackgroundColor3", "PopupNeutralColor")
	buttonMotion(discordCard)

	local dcTile = new("Frame", {
		Name = UUID.Static("IconTile"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = tileFill(theme.AccentColor or Color3.fromRGB(14, 45, 178), cardBase(theme)),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = discordCard,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = dcTile })
	local dcGlyph = new("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(19, 19),
		BackgroundTransparency = 1,
		Image = Icons["link"] or Icons["external-link"],
		ImageColor3 = accentText(theme.AccentColor or Color3.fromRGB(108, 140, 255), isDark(cardBase(theme))),
		ZIndex = 3,
		Parent = dcTile,
	})
	rememberTile(self, dcTile, dcGlyph)
	new("TextLabel", {
		Name = UUID.Static("CardTitle"),
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(62, 18),
		Size = UDim2.new(1, -70, 0, 15),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.SemiBold),
		Text = "Discord",
		TextSize = 13,
		TextColor3 = theme.PrimaryTextColor or Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = discordCard,
	})
	local dcSub = new("TextLabel", {
		Name = UUID.Static("CardSub"),
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(62, 40),
		Size = UDim2.new(1, -70, 0, 13),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		Text = "Tap to copy the invite",
		TextSize = 11,
		TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = discordCard,
	})
	discordCard.MouseButton1Click:Connect(function()
		copyLink(self, self._discordLink)
	end)
	self._dcSub = dcSub

	local infoCard = new("TextButton", {
		Name = UUID.Static("InfoCard"),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -CONTENT_PAD, 0, cardsY),
		Size = UDim2.fromOffset(infoWidth, 74),
		BackgroundColor3 = cardBase(theme),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = infoCard })
	local infoGradient = new("UIGradient", { Parent = infoCard })
	stampCardGradient(infoGradient, theme)
	rememberGradient(self, infoGradient)
	ThemeManager.BindColor(infoCard, "BackgroundColor3", "PopupNeutralColor")
	buttonMotion(infoCard)

	local infoTile = new("Frame", {
		Name = UUID.Static("IconTile"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = tileFill(theme.AccentColor or Color3.fromRGB(14, 45, 178), cardBase(theme)),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = infoCard,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = infoTile })
	local infoGlyph = new("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(19, 19),
		BackgroundTransparency = 1,
		Image = Icons["info"] or Icons["badge-info"],
		ImageColor3 = accentText(theme.AccentColor or Color3.fromRGB(108, 140, 255), isDark(cardBase(theme))),
		ZIndex = 3,
		Parent = infoTile,
	})
	rememberTile(self, infoTile, infoGlyph)
	local infoTitle = new("TextLabel", {
		Name = UUID.Static("CardTitle"),
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(62, 18),
		Size = UDim2.new(1, -70, 0, 15),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.SemiBold),
		Text = "Information",
		TextSize = 13,
		TextColor3 = theme.PrimaryTextColor or Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = infoCard,
	})
	local infoSub = new("TextLabel", {
		Name = UUID.Static("CardSub"),
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(62, 40),
		Size = UDim2.new(1, -70, 0, 13),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		Text = "Tap to view",
		TextSize = 11,
		TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = infoCard,
	})
	local statsExpanded = false
	infoCard.MouseButton1Click:Connect(function()
		statsExpanded = not statsExpanded
		if statsExpanded then
			local record = self._record or {}
			local last = record.Last and (record.Last .. " " .. agoText(record.LastAt)) or "no checks yet"
			infoSub.Text =
				string.format("%d valid · %d rejected · last: %s", record.Valid or 0, record.Rejected or 0, last)
			infoTitle.Text = Locale.resolve("Key history")
		else
			infoTitle.Text = Locale.resolve("Information")
			infoSub.Text = Locale.resolve("Tap to view")
		end
	end)
	self._infoTitle = infoTitle
	self._infoSub = infoSub

	-- Toasts stack bottom-centre, as in the window.

	local notifHolder = new("Frame", {
		Name = UUID.Static("Notifications"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Active = false, -- Transparent pass-through layer.
		ZIndex = 999,
		Parent = self._gui,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = notifHolder,
	})
	local notifPadding = new("UIPadding", { Parent = notifHolder })
	notifPadding.PaddingBottom = UDim.new(0, 14)
	self._notifHolder = notifHolder

	self._keyFadeTargets = captureFade(body)
end

local function buildSuccess(self)
	local theme = self._theme

	local body = new("CanvasGroup", {
		Name = UUID.Static("SuccessBody"),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 3,
		Parent = self._card,
	})
	self._successBody = body

	local ringSize = 76
	local ring = new("Frame", {
		Name = UUID.Static("SuccessRing"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(ringSize, ringSize),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
	new("UIStroke", {
		Color = SUCCESS_COLOR,
		Transparency = 0.35,
		Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = ring,
	})

	local check = new("Frame", {
		Name = UUID.Static("Check"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(44, 44),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = ring,
	})
	local barShort = new("Frame", {
		Name = UUID.Static("CheckShort"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(9, 22),
		Size = UDim2.fromOffset(0, 5),
		Rotation = 45,
		BackgroundColor3 = SUCCESS_COLOR,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = check,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barShort })
	local barLong = new("Frame", {
		Name = UUID.Static("CheckLong"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(19, 32),
		Size = UDim2.fromOffset(0, 5),
		Rotation = -45,
		BackgroundColor3 = SUCCESS_COLOR,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = check,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barLong })

	local label = new("TextLabel", {
		Name = UUID.Static("SuccessLabel"),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.42, ringSize / 2 + 16),
		Size = UDim2.new(1, -40, 0, 18),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.SemiBold),
		Text = "Key accepted",
		TextSize = 14,
		TextColor3 = theme.PrimaryTextColor or Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
		Parent = body,
	})

	self._successLabel = label
	self._checkBars = { barShort, barLong }
	self._successFadeTargets = captureFade(body)
end

local function drawCheck(self)
	local bars = self._checkBars
	if not bars then
		return
	end
	Tween.Play(bars[1], TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(13, 5),
	})
	task.delay(0.14, function()
		if bars[2].Parent then
			Tween.Play(bars[2], TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(24, 5),
			})
		end
	end)
end

function KeyScreen:_fadeCard(target, duration)
	Tween.Play(self._card, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		GroupTransparency = target,
	})
	fadeTo(self._fadeTargets, target, duration)
end

-- Each phase carries its own captured fade targets for strokes and shadows.
function KeyScreen:_phaseOut(body, targets, duration)
	if not body then
		return
	end
	duration = duration or 0.22
	Tween.Play(body, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		GroupTransparency = 1,
	})
	fadeTo(targets, 1, duration)
	local snapshot = body
	task.delay(duration + 0.04, function()
		if snapshot.Parent then
			snapshot.Visible = false
		end
	end)
end

function KeyScreen:_phaseIn(body, targets)
	if not body then
		return
	end
	body.Visible = true
	body.GroupTransparency = 1
	for _, target in ipairs(targets or {}) do
		target[1].Transparency = 1
	end
	Tween.Play(body, "Smooth", { GroupTransparency = 0 })
	fadeRestore(targets, 0.3)
end

-- Loading blocks fade in with a short rise, so the phase reads as one panel.
function KeyScreen:_enterLoading()
	local body = self._loadingBody
	if not body then
		return
	end
	body.Visible = true
	body.GroupTransparency = 1
	local blocks = {
		{ self._statusRow, 10 },
		{ self._barTrack, 58 },
		{ self._stepsCard, 72 },
	}
	for _, block in ipairs(blocks) do
		local frame = block[1]
		if frame then
			frame.Position = UDim2.fromOffset(CONTENT_PAD, block[2] + 8)
			Tween.Play(frame, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.fromOffset(CONTENT_PAD, block[2]),
			})
		end
	end
	Tween.Play(body, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		GroupTransparency = 0,
	})
end

function KeyScreen:_showKeyPhase()
	if not self._card then
		return
	end
	self._subtitle.Text = Locale.resolve("Enter your key to continue")
	Tween.Play(self._card, "Smooth", { Size = UDim2.fromOffset(CARD_WIDTH, KEY_HEIGHT) })
	self:_phaseOut(self._loadingBody)
	self:_phaseIn(self._keyBody, self._keyFadeTargets)
end

function KeyScreen:_showSuccess(message)
	if not self._card then
		return
	end
	if self._successLabel then
		self._successLabel.Text = message or "Key accepted"
	end
	self._subtitle.Text = Locale.resolve("Access granted")
	self:_phaseOut(self._keyBody, self._keyFadeTargets)
	self:_phaseOut(self._loadingBody)
	self:_phaseIn(self._successBody, self._successFadeTargets)
	drawCheck(self)
end

function KeyScreen:_submitKey()
	if self._checking or not self._card then
		return
	end
	local key = self._field.Text
	if key == nil or key:match("^%s*(.-)%s*$") == "" then
		Notification.new(self._notifHolder, {
			Type = "Alert",
			Title = "Empty key",
			Description = "Type your key first.",
			Duration = 3,
		}, self._theme):Show()
		return
	end

	self._checking = true
	self._continue.Text = "..."
	self._continue.TextTransparency = 0.4

	task.spawn(function()
		local valid, reason = self._validator:CheckKey(key)
		self._checking = nil
		self._continue.Text = Locale.resolve("Continue")
		self._continue.TextTransparency = 0
		if not self._card then
			return
		end

		if valid then
			self._record.Valid = (self._record.Valid or 0) + 1
			self._record.Last = "valid"
			self._record.LastAt = os.time()
			self._record.Key = key
			KeyServices.SaveRecord(self._record)
			self:_finish("Key accepted")
		else
			self._record.Rejected = (self._record.Rejected or 0) + 1
			self._record.Last = "rejected"
			self._record.LastAt = os.time()
			KeyServices.SaveRecord(self._record)
			Notification.new(self._notifHolder, {
				Type = "Error",
				Title = "Key rejected",
				Description = tostring(reason or "key is invalid."),
				Duration = 5,
			}, self._theme):Show()
			-- Field glows red so a failure reads even without notifications.
			Tween.Play(self._fieldGlow, "Fast", { Transparency = 0.15 })
			task.delay(0.5, function()
				if self._fieldGlow then
					Tween.Play(self._fieldGlow, "Smooth", { Transparency = 1 })
				end
			end)
		end
	end)
end

function KeyScreen:_finish(message)
	-- Access is granted, so the card can no longer be dismissed early.
	if self._closeButton then
		self._closeButton.Visible = false
	end
	self:_showSuccess(message)
	task.delay(SUCCESS_HOLD, function()
		if not self._gui then
			return
		end
		Sound.Play("KeySystemClose")
		self:_fadeCard(1, FADE_OUT)
		task.delay(FADE_OUT + 0.05, function()
			self:_destroy()
			if self._resolve then
				self._resolve(true)
			end
		end)
	end)
end

-- Aborts the gate so CreateWindow returns nil instead of building.
function KeyScreen:_dismiss()
	if self._closing or not self._card then
		return
	end
	self._closing = true
	Sound.Play("KeySystemClose")
	self:_fadeCard(1, FADE_OUT)
	task.delay(FADE_OUT + 0.05, function()
		self:_destroy()
		if self._resolve then
			self._resolve(false)
		end
	end)
end

function KeyScreen:_destroy()
	if self._introSpin then
		Tween.StopSpin(self._introComet)
		self._introSpin = nil
		self._introComet = nil
	end
	if self._sheenSpin then
		Tween.StopSpin(self._sheenGradient)
		self._sheenSpin = nil
		self._sheenGradient = nil
	end
	if self._dragConn then
		self._dragConn:Disconnect()
		self._dragConn = nil
	end
	if self._aurora then
		self._aurora:Destroy()
		self._aurora = nil
	end
	if self._themeUnbind then
		self._themeUnbind()
		self._themeUnbind = nil
	end
	if self._gui then
		local gui = self._gui
		-- Clear refs first so the Destroying handler cannot re-resolve.
		self._gui = nil
		self._card = nil
		self._closeButton = nil
		self._closeIcon = nil
		self._execChip = nil
		self._headerStrokes = nil
		gui:Destroy()
	end
end

-- Swaps the live status row to the step that is running now.
function KeyScreen:_setCurrentStep(index)
	self._stepIndex = index
	local step = self._steps[index]
	if not step or not self._statusTitle or not self._card then
		return
	end
	local theme = self._theme
	local base = cardBase(theme)
	local accent = theme.AccentColor or Color3.fromRGB(96, 165, 250)
	self._statusTitle.Text = step.Label
	self._statusSub.Text = string.format("Step %d of %d", index, #self._steps)
	self._statusGlyph.Image = Icons[step.Icon] or Icons["sparkles"]
	self._statusTile.BackgroundColor3 = tileFill(accent, base)
	self._statusGlyph.ImageColor3 = accentText(accent, isDark(base))
	-- Soft swap so a new step reads without a hard cut.
	self._statusTitle.TextTransparency = 0.7
	self._statusSub.TextTransparency = 0.7
	Tween.Play(self._statusTitle, "Fast", { TextTransparency = 0 })
	Tween.Play(self._statusSub, "Fast", { TextTransparency = 0 })
	if self._statusScale then
		self._statusScale.Scale = 0.9
		Tween.Play(
			self._statusScale,
			TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)
	end
end

function KeyScreen:_runSteps()
	local totalWeight = 0
	for _, step in ipairs(self._steps) do
		totalWeight += step.Weight
	end

	local doneWeight = 0
	for index, step in ipairs(self._steps) do
		-- The close button may dismiss mid-run, so stop touching the destroyed card.
		if not self._card then
			return
		end
		self:_setCurrentStep(index)
		setStepState(self, index, "active")

		local stepStart = os.clock()
		local ok, err = pcall(step.Run, function(fraction, label)
			setProgress(self, (doneWeight + math.clamp(fraction, 0, 1) * step.Weight) / totalWeight, label)
		end)

		-- Each step is held briefly so the bar reads as real work.
		local elapsed = os.clock() - stepStart
		if elapsed < 0.35 then
			task.wait(0.35 - elapsed)
		end

		setStepState(self, index, ok and "done" or "failed")
		if ok then
			doneWeight += step.Weight
			setProgress(self, doneWeight / totalWeight, step.Label)
		else
			warn("[Aetheris] loading step failed: " .. step.Label .. " - " .. tostring(err))
		end
	end
	setProgress(self, 1)
	if self._statusTitle then
		self._statusTitle.Text = Locale.resolve("Ready")
		self._statusSub.Text = Locale.resolve("Starting your interface")
	end
end

-- Resolves true when the window may build, false when the gate was aborted.
function KeyScreen.Run(keyConfig, opts)
	opts = opts or {}
	keyConfig = keyConfig or {}

	local self = setmetatable({}, KeyScreen)
	self._opts = opts
	self._player = Players.LocalPlayer
	self._secure = opts.SecureMode == true
	self._dragStyle = opts.DragStyle or "Instant"
	self._config = keyConfig
	self._record = KeyServices.LoadRecord() or {}
	self._checking = nil
	self._discordLink = nil

	UUID.SetSecureMode(self._secure)
	SettingsStore.Load()
	Sound.SetVolume(SettingsStore.Get("Volume"))
	local savedTheme = SettingsStore.Get("Theme")
	self._theme = ThemeManager.GetTheme(savedTheme ~= nil and savedTheme or opts.Theme)

	self._validator = KeyServices.Create(keyConfig)

	local discordConfig = keyConfig.Discord
	if type(discordConfig) == "string" then
		self._discordLink = discordConfig
	elseif type(discordConfig) == "table" then
		self._discordLink = discordConfig.Link
		self._discordGuildId = discordConfig.Id
	end

	local function savedKeyStep(report)
		if keyConfig.SaveKey ~= true or type(self._record.Key) ~= "string" or self._record.Key == "" then
			self._savedValid = nil
			report(1)
			return
		end
		local valid = self._validator:CheckKey(self._record.Key)
		self._savedValid = valid
		if not valid then
			self._record.Key = nil
			KeyServices.SaveRecord(self._record)
		end
		report(1)
	end

	self._steps = {
		{
			Label = Locale.resolve("Loading assets"),
			Icon = "image",
			Weight = 2,
			Run = function(report)
				local list, seen = {}, {}
				for _, id in ipairs(PRELOAD_IMAGES) do
					if type(id) == "string" and not seen[id] then
						seen[id] = true
						table.insert(list, id)
					end
				end
				-- Warming wallpapers here keeps the Themes tab from hitching.
				for _, def in pairs(ThemeDefinitions) do
					local wallpaper = def.Wallpaper
					if type(wallpaper) == "string" and not seen[wallpaper] then
						seen[wallpaper] = true
						table.insert(list, wallpaper)
					end
				end
				if #list == 0 then
					report(1)
					return
				end
				local loaded = 0
				ContentProvider:PreloadAsync(list, function()
					loaded += 1
					report(loaded / #list)
				end)
			end,
		},
		{
			Label = Locale.resolve("Loading sounds"),
			Icon = "volume-2",
			Weight = 4,
			Run = function(report)
				Sound.Preload(function(loaded, total)
					report(total > 0 and loaded / total or 1)
				end)
			end,
		},
		{
			Label = "Starting key services",
			Icon = "shield-check",
			Weight = 2,
			Run = function(report)
				self._validator:Init(function(fraction)
					report(fraction)
				end)
			end,
		},
		{ Label = "Checking saved key", Icon = "key-round", Weight = 3, Run = savedKeyStep },
	}

	buildCard(self)
	buildIntro(self)
	buildLoading(self)
	buildKeyPhase(self)
	buildSuccess(self)
	self._fadeTargets = captureFade(self._card)

	self._themeUnbind = ThemeManager.OnThemeApplied(function(theme)
		self._theme = theme
		self._title.TextColor3 = theme.TitleTextColor or Color3.new(1, 1, 1)
		self._subtitle.TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
		if self._closeIcon then
			self._closeIcon.ImageColor3 = theme.PopupTextColor or Color3.fromRGB(255, 255, 255)
		end
		-- Header cluster: the chip follows the theme; the close button is the
		-- fixed white circle shared by every popup.
		if self._execChip then
			self._execChip.BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255)
		end
		for _, headerStroke in ipairs(self._headerStrokes or {}) do
			headerStroke.Color = theme.StrokeColor or Color3.new(1, 1, 1)
		end
		self._card.BackgroundColor3 = theme.WindowColor or Color3.fromRGB(15, 15, 16)
		-- Card opacity is pinned at build; only the colour follows the theme.
		self._card.BackgroundTransparency = 0
		self._stroke.Color = theme.StrokeColor or Color3.new(1, 1, 1)
		self._barGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.AccentColor or Color3.fromRGB(14, 45, 178)),
			ColorSequenceKeypoint.new(1, theme.PrimaryColor or Color3.fromRGB(13, 44, 177)),
		})
		-- Washes and tile fills are derived, so they restamp here.
		for _, gradient in ipairs(self._cardGradients or {}) do
			stampCardGradient(gradient, theme)
		end
		restampTiles(self, theme)
		self._aurora:SetTheme(theme)
		-- Loading phase: status row, step tiles, rail and chip all derive.
		if self._statusTitle then
			self._statusTitle.TextColor3 = theme.PrimaryTextColor or Color3.new(1, 1, 1)
			self._statusSub.TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
		end
		if self._statusTile and self._statusGlyph then
			local base = cardBase(theme)
			local accent = theme.AccentColor or Color3.fromRGB(96, 165, 250)
			self._statusTile.BackgroundColor3 = tileFill(accent, base)
			self._statusGlyph.ImageColor3 = accentText(accent, isDark(base))
		end
		if self._percentChip then
			self._percentChip.BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255)
		end
		if self._percentChipStroke then
			self._percentChipStroke.Color = theme.StrokeColor or Color3.new(1, 1, 1)
		end
		if self._barTrack then
			self._barTrack.BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255)
		end
		if self._barFill then
			self._barFill.BackgroundColor3 = theme.AccentColor or Color3.fromRGB(96, 165, 250)
		end
		if self._stepsStroke then
			self._stepsStroke.Color = theme.StrokeColor or Color3.new(1, 1, 1)
		end
		for _, row in ipairs(self._stepRows or {}) do
			paintStepRow(self, row, row.State or "pending", false)
		end
		if self._introComet then
			self._introComet.Color = ColorSequence.new(theme.AccentColor or Color3.fromRGB(14, 45, 178))
		end
		if self._introHalo then
			self._introHalo.BackgroundColor3 = theme.AccentColor or Color3.fromRGB(96, 165, 250)
		end
	end, self._card)

	local signal = Instance.new("BindableEvent")
	self._resolve = function(passed)
		signal:Fire(passed)
	end
	self._gui.Destroying:Connect(function()
		if self._card then
			-- The gui was destroyed, so the gate is aborted.
			self._resolve(false)
		end
	end)

	Sound.Play("KeySystemOpen")
	self:_fadeCard(0, FADE_IN)

	if self._discordGuildId then
		task.spawn(function()
			local stats = KeyServices.FetchDiscordStats(self._discordGuildId)
			if stats and self._dcSub then
				local online = formatCount(stats.Online)
				local members = formatCount(stats.Members)
				if online and members then
					self._dcSub.Text = string.format("%s online · %s members", online, members)
				elseif online then
					self._dcSub.Text = string.format("%s online", online)
				end
			end
		end)
	end

	task.wait(INTRO_HOLD)
	if not self._card then
		return signal.Event:Wait()
	end
	self._subtitle.Text = Locale.resolve("Loading")
	self:_phaseOut(self._introBody, self._introFadeTargets)
	Tween.StopSpin(self._introComet)
	self._introSpin = nil
	Tween.Play(self._headerGroup, "Smooth", { GroupTransparency = 0 })
	self:_enterLoading()

	self:_runSteps()

	-- A saved key already verified, so skip the key UI.
	if self._savedValid == true then
		self:_finish("All set")
		return signal.Event:Wait()
	end

	if not self._validator:HasAny() then
		-- Nothing to validate against, so loading only.
		self:_finish("All set")
		return signal.Event:Wait()
	end

	self:_showKeyPhase()
	if self._savedValid == false and self._card then
		Notification.new(self._notifHolder, {
			Type = "Alert",
			Title = "Saved key expired",
			Description = "Your stored key is no longer valid.",
			Duration = 5,
		}, self._theme):Show()
	end

	local passed = signal.Event:Wait()
	signal:Destroy()
	self:_destroy()
	return passed, nil
end

return KeyScreen
