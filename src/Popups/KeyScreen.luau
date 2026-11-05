--[[
	Aetheris/Popups/KeyScreen.luau

	Combined loading + key-system card shown before the window builds when
	CreateWindow receives a KeySystem table. One card plays the loading steps
	(assets, sounds, key services, saved-key check) with a real progress bar,
	then crossfades into the key UI (input, Get Key, Discord + Information
	cards) when a key is actually required. Draggable like the main window,
	fades in/out, fully themed, sounds through KeySystemOpen/Close.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

--# selene: allow(undefined_variable)
-- Executor APIs (identifyexecutor, setclipboard, request, ...) are injected
-- by the host at runtime; probed with type() checks throughout.

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

-- First-paint images for the card and window chrome, warmed by the loading step.
local PRELOAD_IMAGES = {
	"rbxassetid://92458734285074",
	Icons["sparkles"],
	Icons["key"],
	Icons["link"],
	Icons["info"],
	Icons["x"],
	Icons["bell"],
	Icons["triangle-alert"],
	Icons["shield-alert"],
	Icons["minimize-2"],
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

-- UIStroke/UIShadow transparency is not covered by CanvasGroup.GroupTransparency,
-- so the open/close fade carries them separately.
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

-- Tween each decoration between its own resting transparency and hidden: the
-- fade value scales toward 1, never toward an opaque 0.
local function fadeTo(targets, value, duration)
	for _, target in ipairs(targets or {}) do
		local base = target[3]
		Tween.Play(target[1], TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			[target[2]] = base + (1 - base) * value,
		})
	end
end

-- Tween captured targets back to the transparency they were captured at.
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

----------------------------------------------------------------
-- Card build
----------------------------------------------------------------

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
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = card })
	local stroke = new("UIStroke", {
		Color = theme.StrokeColor or Color3.fromRGB(255, 255, 255),
		-- Pinned at 0.7; the open/close fade returns it to this base instead of zero.
		Transparency = 0.7,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = card,
	})
	local shadow = new("UIShadow", {
		Color = theme.MainframeShadowColor or Color3.new(0, 0, 0),
		Transparency = 0.5,
		BlurRadius = UDim.new(0, 28),
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
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = clip })
	self._aurora = Aurora.new(clip, { Theme = theme, Transparency = 0.35 })

	-- Drag frame mirrors the window: Instant follows the cursor, Smooth tweens.
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
				-- switch to top-left anchoring so offset positions track the cursor 1:1
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

	----------------------------------------------------------------
	-- Header
	----------------------------------------------------------------

	-- Hidden during the intro, then faded in with the loading body
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
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = theme.AccentColor or Color3.fromRGB(14, 45, 178),
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
		ZIndex = 4,
		Parent = brandTile,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = brandIcon })

	local title = new("TextLabel", {
		Name = UUID.Static("Title"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(62, 25),
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
		Position = UDim2.fromOffset(62, 45),
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
	local execChip = new("Frame", {
		Name = UUID.Static("ExecutorChip"),
		AnchorPoint = Vector2.new(1, 0.5),
		-- Inset past the close button so the chip never slides under it.
		Position = UDim2.new(1, -(CONTENT_PAD + 22), 0.5, -4),
		Size = UDim2.fromOffset(execWidth, 24),
		BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = (theme.InputBackgroundTransparency or 0.9) + 0.02,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = headerGroup,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = execChip })
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

	-- Direct child of the card, above the drag frame, so the click never starts a drag.
	-- The bare X was near-invisible over the header, so it sits on a small chip:
	-- muted at rest, brighter with the icon popping forward on hover.
	local closeButton = new("ImageButton", {
		Name = UUID.Static("CloseButton"),
		AnchorPoint = Vector2.new(1, 0.5),
		-- Centred on the header row so it lines up with the executor chip.
		Position = UDim2.new(1, -10, 0, HEADER_HEIGHT / 2 - 4),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = theme.PopupNeutralColor or Color3.fromRGB(46, 46, 46),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Image = Icons["x"] or "rbxassetid://110786993356448",
		ImageColor3 = theme.PopupTextColor or theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
		ImageTransparency = 0.15,
		ZIndex = 6,
		Parent = card,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = closeButton })
	closeButton.MouseEnter:Connect(function()
		Tween.Play(closeButton, "HoverIn", { BackgroundTransparency = 0.05, ImageTransparency = 0 })
	end)
	closeButton.MouseLeave:Connect(function()
		Tween.Play(closeButton, "HoverOut", { BackgroundTransparency = 0.35, ImageTransparency = 0.15 })
	end)
	closeButton.MouseButton1Click:Connect(function()
		self:_dismiss()
	end)
	self._closeButton = closeButton

	self._title = title
	self._subtitle = subtitle
	self._stroke = stroke
	self._shadow = shadow
end

----------------------------------------------------------------
-- Intro phase
----------------------------------------------------------------

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
			NumberSequenceKeypoint.new(0.3, 0),
			NumberSequenceKeypoint.new(0.45, 0.75),
			NumberSequenceKeypoint.new(1, 0.9),
		}),
		Rotation = 0,
		Parent = ringStroke,
	})

	local tile = new("Frame", {
		Name = UUID.Static("IntroTile"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(50, 50),
		BackgroundColor3 = theme.AccentColor or Color3.fromRGB(14, 45, 178),
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = ring,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = tile })
	new("ImageLabel", {
		Name = UUID.Static("IntroIcon"),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1,
		Image = Icons["sparkles"] or Icons["key"],
		ImageColor3 = Color3.new(1, 1, 1),
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
	self._introSpin = Tween.StartSpin(comet, { Rotation = 360 }, "SpinBurst")
	self._introFadeTargets = captureFade(body)
end

----------------------------------------------------------------
-- Loading phase
----------------------------------------------------------------

local function buildLoading(self)
	local theme = self._theme

	-- CanvasGroup so the phase crossfade can tween one GroupTransparency;
	-- starts hidden until the intro hands off
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

	local rows = {}
	local column = new("Frame", {
		Name = UUID.Static("Steps"),
		Position = UDim2.fromOffset(CONTENT_PAD, 8),
		Size = UDim2.new(1, -(CONTENT_PAD * 2), 0, 104),
		BackgroundTransparency = 1,
		Parent = body,
	})
	local layout = new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = column,
	})
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		column.Size = UDim2.new(1, -(CONTENT_PAD * 2), 0, layout.AbsoluteContentSize.Y)
	end)

	for index, step in ipairs(self._steps) do
		local row = new("Frame", {
			Name = UUID.Static("StepRow"),
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			LayoutOrder = index,
			Parent = column,
		})
		local dot = new("Frame", {
			Name = UUID.Static("Dot"),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(7, 7),
			BackgroundColor3 = theme.StrokeColor or Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			Parent = row,
		})
		new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		local label = new("TextLabel", {
			Name = UUID.Static("StepLabel"),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 20, 0.5, 0),
			Size = UDim2.new(1, -20, 1, 0),
			BackgroundTransparency = 1,
			FontFace = Constants.Font(Enum.FontWeight.Medium),
			Text = step.Label,
			TextSize = 12,
			TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		rows[index] = { Dot = dot, Label = label }
	end

	local barTrack = new("Frame", {
		Name = UUID.Static("BarTrack"),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, CONTENT_PAD, 1, -44),
		Size = UDim2.new(1, -(CONTENT_PAD * 2), 0, 6),
		BackgroundColor3 = theme.InputBackgroundColor or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = theme.InputBackgroundTransparency or 0.9,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barTrack })
	local fill = new("Frame", {
		Name = UUID.Static("BarFill"),
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = theme.AccentColor or Color3.fromRGB(14, 45, 178),
		BorderSizePixel = 0,
		Parent = barTrack,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	local fillGradient = new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.AccentColor or Color3.fromRGB(14, 45, 178)),
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
			NumberSequenceKeypoint.new(0.35, 0.85),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(0.65, 0.85),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Offset = Vector2.new(-0.5, 0),
		Parent = sheen,
	})

	local currentLabel = new("TextLabel", {
		Name = UUID.Static("CurrentStep"),
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, CONTENT_PAD, 1, -30),
		Size = UDim2.new(1, -(CONTENT_PAD * 2 + 50), 0, 14),
		BackgroundTransparency = 1,
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		Text = "",
		TextSize = 11,
		TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = body,
	})
	-- Odometer rolls the percent digits slot-machine style as loading advances.
	local percentHolder = new("Frame", {
		Name = UUID.Static("Percent"),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -CONTENT_PAD, 1, -30),
		Size = UDim2.fromOffset(46, 14),
		BackgroundTransparency = 1,
		Parent = body,
	})
	local percent = Odometer.new(percentHolder, {
		textSize = 11,
		height = 14,
		alignment = Enum.HorizontalAlignment.Right,
		textColor = theme.PrimaryTextColor,
	})
	percent:snap("0%")

	self._stepRows = rows
	self._barFill = fill
	self._barGradient = fillGradient
	self._sheenGradient = sheenGradient
	self._sheenSpin = Tween.StartSpin(sheenGradient, { Offset = Vector2.new(0.5, 0) }, "SpinBurst")
	self._currentLabel = currentLabel
	self._percent = percent
end

local function setStepState(self, index, state)
	local row = self._stepRows[index]
	if not row or not self._card then
		return
	end
	local theme = self._theme
	if state == "active" then
		row.Dot.BackgroundColor3 = theme.AccentColor or Color3.fromRGB(14, 45, 178)
		row.Dot.BackgroundTransparency = 0
		row.Label.TextColor3 = theme.PrimaryTextColor or Color3.new(1, 1, 1)
		row._pulse =
			Tween.Play(row.Dot, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
				BackgroundTransparency = 0.45,
			})
	elseif state == "done" then
		if row._pulse then
			Tween.Cancel(row._pulse)
			row._pulse = nil
		end
		row.Dot.BackgroundColor3 = SUCCESS_COLOR
		row.Dot.BackgroundTransparency = 0
		row.Label.TextColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
	elseif state == "failed" then
		if row._pulse then
			Tween.Cancel(row._pulse)
			row._pulse = nil
		end
		row.Dot.BackgroundColor3 = ERROR_COLOR
		row.Dot.BackgroundTransparency = 0
	end
end

local function setProgress(self, fraction, label)
	if not self._card then
		return
	end
	fraction = math.clamp(fraction, 0, 1)
	Tween.Play(self._barFill, "Smooth", { Size = UDim2.fromScale(fraction, 1) })
	self._percent:to(math.floor(fraction * 100 + 0.5) .. "%", true)
	if label then
		self._currentLabel.Text = label
	end
end

----------------------------------------------------------------
-- Key phase
----------------------------------------------------------------

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
			Description = "The key link isn't configured yet.",
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
		-- no clipboard outside executors: show the link instead so it's still usable
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
		FontFace = Constants.Font(Enum.FontWeight.Medium),
		PlaceholderText = "Enter your key",
		PlaceholderColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200),
		Text = "",
		TextSize = 13,
		TextColor3 = theme.PrimaryTextColor or Color3.new(1, 1, 1),
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = field })
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
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = continue })
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
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = getKey })
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

	----------------------------------------------------------------
	-- Discord + Information cards
	----------------------------------------------------------------

	local infoWidth = 168
	local discordWidth = CARD_WIDTH - (CONTENT_PAD * 2) - infoWidth - 10
	local cardsY = 134

	local discordCard = new("TextButton", {
		Name = UUID.Static("DiscordCard"),
		Position = UDim2.fromOffset(CONTENT_PAD, cardsY),
		Size = UDim2.fromOffset(discordWidth, 74),
		BackgroundColor3 = theme.ComponentBackgroundColor or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = theme.ComponentBackgroundTransparency or 0.94,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 7), Parent = discordCard })
	new("UIStroke", {
		Color = theme.StrokeColor or Color3.fromRGB(255, 255, 255),
		Transparency = theme.SectionStrokeTransparency or 0.9,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = discordCard,
	})
	buttonMotion(discordCard)

	local dcTile = new("Frame", {
		Name = UUID.Static("IconTile"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = theme.AccentColor or Color3.fromRGB(14, 45, 178),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = discordCard,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 7), Parent = dcTile })
	new("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(19, 19),
		BackgroundTransparency = 1,
		Image = Icons["link"] or Icons["external-link"],
		ImageColor3 = theme.AccentColor or Color3.fromRGB(108, 140, 255),
		ZIndex = 3,
		Parent = dcTile,
	})
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
		BackgroundColor3 = theme.ComponentBackgroundColor or Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = theme.ComponentBackgroundTransparency or 0.94,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		Parent = body,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 7), Parent = infoCard })
	new("UIStroke", {
		Color = theme.StrokeColor or Color3.fromRGB(255, 255, 255),
		Transparency = theme.SectionStrokeTransparency or 0.9,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = infoCard,
	})
	buttonMotion(infoCard)

	local infoTile = new("Frame", {
		Name = UUID.Static("IconTile"),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = theme.AccentColor or Color3.fromRGB(14, 45, 178),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = infoCard,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 7), Parent = infoTile })
	new("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(19, 19),
		BackgroundTransparency = 1,
		Image = Icons["info"] or Icons["badge-info"],
		ImageColor3 = theme.AccentColor or Color3.fromRGB(108, 140, 255),
		ZIndex = 3,
		Parent = infoTile,
	})
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
			infoTitle.Text = "Key history"
		else
			infoTitle.Text = "Information"
			infoSub.Text = "Tap to view"
		end
	end)
	self._infoTitle = infoTitle
	self._infoSub = infoSub

	----------------------------------------------------------------
	-- Notifications container (toasts stack above the card)
	----------------------------------------------------------------

	local notifHolder = new("Frame", {
		Name = UUID.Static("Notifications"),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.new(0, 260, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 999,
		Parent = self._gui,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = notifHolder,
	})
	local notifPadding = new("UIPadding", { Parent = notifHolder })
	notifPadding.PaddingBottom = UDim.new(0, 14)
	notifPadding.PaddingRight = UDim.new(0, 14)
	self._notifHolder = notifHolder

	self._keyFadeTargets = captureFade(body)
end

----------------------------------------------------------------
-- Success phase
----------------------------------------------------------------

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

----------------------------------------------------------------
-- Phase transitions
----------------------------------------------------------------

function KeyScreen:_fadeCard(target, duration)
	Tween.Play(self._card, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		GroupTransparency = target,
	})
	fadeTo(self._fadeTargets, target, duration)
end

-- CanvasGroup transparency skips UIStroke/UIShadow, so phases carry their own
-- captured fade targets and snap invisible before restoring on the way in.
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

function KeyScreen:_showKeyPhase()
	if not self._card then
		return
	end
	self._subtitle.Text = "Enter your key to continue"
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
	self._subtitle.Text = "Access granted"
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
		self._continue.Text = "Continue"
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
			-- red flash on the field so the failure reads even with notifications off
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

-- Close button: abort the gate so CreateWindow returns nil instead of building.
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
		-- clear refs first so the Destroying handler below doesn't fire
		-- resolve(false) over an already-resolved gate
		self._gui = nil
		self._card = nil
		self._closeButton = nil
		gui:Destroy()
	end
end

----------------------------------------------------------------
-- Loading runner
----------------------------------------------------------------

function KeyScreen:_runSteps()
	local totalWeight = 0
	for _, step in ipairs(self._steps) do
		totalWeight += step.Weight
	end

	local doneWeight = 0
	for index, step in ipairs(self._steps) do
		-- The close button can dismiss mid-run; stop touching the dead card.
		if not self._card then
			return
		end
		setStepState(self, index, "active")
		self._currentLabel.Text = step.Label .. "..."

		local stepStart = os.clock()
		local ok, err = pcall(step.Run, function(fraction, label)
			setProgress(self, (doneWeight + math.clamp(fraction, 0, 1) * step.Weight) / totalWeight, label)
		end)

		-- hold each step briefly so the bar reads as real work, not a flash
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
	setProgress(self, 1, "Ready")
end

----------------------------------------------------------------
-- Entry point
----------------------------------------------------------------

-- Runs the combined loading + key card. Resolves true when the caller may
-- build the window, false + reason when the gate was aborted.
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
			Label = "Loading assets",
			Weight = 2,
			Run = function(report)
				local list, seen = {}, {}
				for _, id in ipairs(PRELOAD_IMAGES) do
					if type(id) == "string" and not seen[id] then
						seen[id] = true
						table.insert(list, id)
					end
				end
				-- Theme wallpapers: warming them here keeps the Themes tab from hitching on first open.
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
			Label = "Loading sounds",
			Weight = 4,
			Run = function(report)
				Sound.Preload(function(loaded, total)
					report(total > 0 and loaded / total or 1)
				end)
			end,
		},
		{
			Label = "Starting key services",
			Weight = 2,
			Run = function(report)
				self._validator:Init(function(fraction)
					report(fraction)
				end)
			end,
		},
		{ Label = "Checking saved key", Weight = 3, Run = savedKeyStep },
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
		if self._closeButton then
			self._closeButton.ImageColor3 = theme.SecondaryTextColor or Color3.fromRGB(200, 200, 200)
		end
		self._card.BackgroundColor3 = theme.WindowColor or Color3.fromRGB(15, 15, 16)
		-- Card opacity is pinned at build; only the colour follows the theme.
		self._card.BackgroundTransparency = 0
		self._stroke.Color = theme.StrokeColor or Color3.new(1, 1, 1)
		self._barGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.AccentColor or Color3.fromRGB(14, 45, 178)),
			ColorSequenceKeypoint.new(1, theme.PrimaryColor or Color3.fromRGB(13, 44, 177)),
		})
		self._aurora:SetTheme(theme)
	end, self._card)

	local signal = Instance.new("BindableEvent")
	self._resolve = function(passed)
		signal:Fire(passed)
	end
	self._gui.Destroying:Connect(function()
		if self._card then
			-- the gui died under us (teardown/leave): abort the gate
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
				end
			end
		end)
	end

	task.wait(INTRO_HOLD)
	if not self._card then
		return signal.Event:Wait()
	end
	self._subtitle.Text = "Loading"
	self:_phaseOut(self._introBody, self._introFadeTargets)
	Tween.StopSpin(self._introComet)
	self._introSpin = nil
	Tween.Play(self._headerGroup, "Smooth", { GroupTransparency = 0 })
	self:_phaseIn(self._loadingBody)

	self:_runSteps()

	-- saved key already verified during loading: skip the key UI entirely
	if self._savedValid == true then
		self:_finish("All set")
		return signal.Event:Wait()
	end

	if not self._validator:HasAny() then
		-- KeySystem configured but nothing to validate against: loading only
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
