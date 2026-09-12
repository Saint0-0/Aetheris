--[[
	Toggle  ·  Aetheris UI Library

	Boolean switch row. Optionally gates the change behind a confirmation
	notification. Carries an IsOn attribute so ThemeManager can restore the
	on/off look correctly on a theme switch (rather than inferring from
	transparency). Thumb sheen spins only while ON.

	Usage:
		local toggle = section:Toggle({
			Name = "Enable Feature",
			Default = false,
			Confirm = { Enabled = true },
			Callback = function(state) end,
		}, ShowNotification)
]]

local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local Tween = require("../Utils/Tween")
local Toggle = {}
Toggle.__index = Toggle
function Toggle.new(parent, Settings, ShowNotification, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Toggle)
	self._theme = theme
	self._themeResolved = theme
	local name = Settings.Name or "Toggle"
	local default = Settings.Default or false
	local confirm = Settings.Confirm or {}
	local confirmEnabled = confirm.Enabled or false
	----------------------------------------------------------------
	-- MAIN ROW
	----------------------------------------------------------------
	local row = Instance.new("TextButton")
	row.Name = name .. " [Toggle]"
	row.BorderSizePixel = 0
	row.BackgroundColor3 = Color3.fromRGB(31, 32, 34)
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 45)
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.new(0.5, 0, 0.5, 0)
	row.Text = ""
	row.TextTransparency = 1
	row.AutoButtonColor = false
	row.Parent = parent
	----------------------------------------------------------------
	-- LABEL
	----------------------------------------------------------------
	local label = Instance.new("TextLabel")
	label.Name = "ElementName"
	label.FontFace = Font.new(
		"rbxassetid://12187365364",
		Enum.FontWeight.Regular,
		Enum.FontStyle.Normal
	)
	label.Text = name
	label.TextColor3 = (theme and theme.PrimaryTextColor)
	label.TextSize = 14
	label.TextTransparency = (theme and theme.PrimaryTextTransparency) or 0.45
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.486, 0, 0.714, 0)
	label.Position = UDim2.new(0, 0, 0.5, 0)
	label.Parent = row
	
	local toggleInterractionHolder = Instance.new("Frame")
	toggleInterractionHolder.Name = "InterractionHolder"	
	toggleInterractionHolder.BackgroundTransparency = 1
	toggleInterractionHolder.AnchorPoint = Vector2.new(1, 0.5)
	toggleInterractionHolder.Size = UDim2.new(0, 65, 1, 0)
	toggleInterractionHolder.Position = UDim2.new(1, 0, 0.5, 0)
	toggleInterractionHolder.Parent = row
	
	----------------------------------------------------------------
	-- TRACK
	----------------------------------------------------------------
	local track = Instance.new("Frame")
	track.Name = "ToggleSlidingFrame"
	track.BorderSizePixel = 0
	track.BackgroundColor3 = theme.SecondaryColor
	track.BackgroundTransparency = 0.9
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Size = UDim2.new(0, 34, 0, 2)
	track.Position = UDim2.new(0.5, 0, 0.5, 0)
	track.Parent = toggleInterractionHolder
	self.track = track
	----------------------------------------------------------------
	-- THUMB
	----------------------------------------------------------------
	local thumb = Instance.new("TextButton")
	thumb.Name = "Toggle"
	thumb.BorderSizePixel = 0
	thumb.BackgroundColor3 = (theme and theme.PrimaryColor)
	thumb.BackgroundTransparency = 1
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Size = UDim2.new(0, 14, 0, 14)
	thumb.Position = UDim2.new(0, -6, 0.5, 0)
	thumb.Text = ""
	thumb.TextTransparency = 1
	thumb.AutoButtonColor = false
	thumb.Parent = track
	-- Seed the live-theme color attributes so applyState reads current colors
	-- even before the first ApplyTheme stamps them.
	thumb:SetAttribute("ThemePrimary", theme.PrimaryColor)
	thumb:SetAttribute("ThemeSecondary", theme.SecondaryColor)
	----------------------------------------------------------------
	-- SIZE CONSTRAINT
	----------------------------------------------------------------
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.Parent = thumb
	----------------------------------------------------------------
	-- CORNER
	----------------------------------------------------------------
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = thumb
	----------------------------------------------------------------
	-- STROKE
	----------------------------------------------------------------
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.7
	stroke.Thickness = 1.5
	stroke.Color = theme.PrimaryColor
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = thumb
	----------------------------------------------------------------
	-- SHEEN (spinning gradient on the thumb, visible only when ON)
	----------------------------------------------------------------
	local sheen = Instance.new("ImageLabel")
	sheen.Name = "BackImage"
	sheen.BorderSizePixel = 0
	sheen.BackgroundTransparency = 1
	sheen.Image = theme.Wallpaper or "rbxassetid://11094025229"
	sheen:SetAttribute("IsThemeSheen", true)
	sheen.ImageTransparency = 1
	sheen.AnchorPoint = Vector2.new(0.5, 0.5)
	sheen.Position = UDim2.new(0.5, 0, 0.5, 0)
	sheen.Size = UDim2.new(1, 0, 1, 0)
	sheen.Parent = thumb
	local sheenCorner = Instance.new("UICorner")
	sheenCorner.CornerRadius = UDim.new(1, 0)
	sheenCorner.Parent = sheen
	local sheenGradient = Instance.new("UIGradient")
	sheenGradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0.000, 1),
		NumberSequenceKeypoint.new(0.324, 0.80625),
		NumberSequenceKeypoint.new(0.600, 0.6875),
		NumberSequenceKeypoint.new(0.726, 0.55),
		NumberSequenceKeypoint.new(0.844, 0.36875),
		NumberSequenceKeypoint.new(1.000, 0),
	}
	sheenGradient.Parent = sheen
	-- Perpetual spin, like the original ToggleMechanics; visibility is driven
	-- by ImageTransparency in applyState.
	sheenGradient.Rotation = 0
	Tween.StartSpin(sheenGradient, { Rotation = 360 }, "SpinIdle")
	----------------------------------------------------------------
	-- STATE
	----------------------------------------------------------------
	local state = default
	local offPos = UDim2.new(0, -6, 0.5, 0)
	local onPos = UDim2.new(0, 41, 0.5, 0)
	-- True while a confirmation notification is open.
	local confirmationPending = false
	----------------------------------------------------------------
	-- APPLY STATE
	----------------------------------------------------------------
	local function applyState(newState, animate, fireCallback)
		if state == newState and fireCallback then
			return
		end
		state = newState
		thumb:SetAttribute("IsOn", state)
		-- Always read the LIVE theme so a theme switch doesn't leave this
		-- toggle recomputing colors from a stale construction-time table.
		-- Prefer the colors ThemeManager stamped on this thumb during the last
		-- ApplyTheme (reliable across module-instance boundaries). Fall back
		-- to the live shared theme, then the construction-time theme.
		local livePrimary = thumb:GetAttribute("ThemePrimary")
			or (ActiveTheme.theme and ActiveTheme.theme.PrimaryColor)
			or theme.PrimaryColor
		local liveSecondary = thumb:GetAttribute("ThemeSecondary")
			or (ActiveTheme.theme and ActiveTheme.theme.SecondaryColor)
			or theme.SecondaryColor
		local targetPos = state and onPos or offPos
		local targetBgTransparency =
			state and 0 or 1
		local targetStrokeTransparency =
			state and 0 or 0.7
		local targetStrokeColor = state and livePrimary or liveSecondary
		local targetTrackColor = state and livePrimary or liveSecondary
		local targetTrackTransparency =
			state and 0 or 0.9
		local targetLabelTransparency =
			state and 0.1 or 0.45
		if animate then
			Tween.Play(thumb, "Fast", {
				Position = targetPos,
				BackgroundColor3 = livePrimary,
				BackgroundTransparency = targetBgTransparency
			})
			Tween.Play(stroke, "Fast", {
				Transparency = targetStrokeTransparency,
				Color = targetStrokeColor
			})
			Tween.Play(label, "Fast", {
				TextTransparency = targetLabelTransparency
			})
			Tween.Play(track, "Fast", {
				BackgroundColor3 = targetTrackColor,
				BackgroundTransparency = targetTrackTransparency
			})
			Tween.Play(sheen, "Fast", {
				ImageTransparency = state and 0 or 1
			})
		else
			thumb:SetAttribute("IsOn", state)
			thumb.Position = targetPos
			thumb.BackgroundColor3 = livePrimary
			thumb.BackgroundTransparency = targetBgTransparency
			stroke.Transparency = targetStrokeTransparency
			stroke.Color = targetStrokeColor
			label.TextTransparency = targetLabelTransparency
			track.BackgroundColor3 = targetTrackColor
			track.BackgroundTransparency = targetTrackTransparency
			sheen.ImageTransparency = state and 0 or 1
		end
		if fireCallback and Settings.Callback then
			Settings.Callback(state)
		end
	end
	----------------------------------------------------------------
	-- HANDLE CLICK
	----------------------------------------------------------------
	local function handleClick()
		-- Don't allow another notification while one
		-- confirmation is already waiting for a response.
		if confirmationPending then
			return
		end
		local intendedState = not state
		------------------------------------------------------------
		-- CONFIRMATION MODE (only when turning ON)
		------------------------------------------------------------
		if confirmEnabled and ShowNotification and intendedState then
			confirmationPending = true
			ShowNotification({
				Title =
					confirm.Title
					or "Confirm Action",
				Description =
					confirm.Description
					or "Are you sure you want to change this setting?",
				TitleColor =
					confirm.TitleColor,
				ConfirmText =
					confirm.ConfirmText
					or "Yes",
				CancelText =
					confirm.CancelText
					or "No",
				----------------------------------------------------
				-- CONFIRMED
				----------------------------------------------------
				OnConfirm = function()
					confirmationPending = false
					-- Apply the state requested when the
					-- notification was originally opened.
					applyState(
						intendedState,
						true,
						true
					)
				end,
				----------------------------------------------------
				-- CANCELLED
				----------------------------------------------------
				OnCancel = function()
					-- IMPORTANT:
					-- The toggle does NOT change state.
					-- We simply unlock it so it can be
					-- clicked again.
					confirmationPending = false
				end,
			})
			------------------------------------------------------------
			-- NORMAL MODE (turning OFF, or no confirmation)
			------------------------------------------------------------
		else
			applyState(
				intendedState,
				true,
				true
			)
		end
	end
	----------------------------------------------------------------
	-- SINGLE CLICK HANDLER
	----------------------------------------------------------------
	row.MouseButton1Click:Connect(function()
		handleClick()
	end)
	thumb.MouseButton1Click:Connect(function()
		handleClick()
	end)
	----------------------------------------------------------------
	-- INITIAL STATE
	----------------------------------------------------------------
	-- Apply the visual default state.
	-- Do NOT fire the user's callback during construction.
	applyState(
		default,
		false,
		false
	)
	----------------------------------------------------------------
	-- PUBLIC API
	----------------------------------------------------------------
	function self:UpdateState(newState)
		if typeof(newState) ~= "boolean" then
			warn(
				"[Toggle] UpdateState expected a boolean, got:",
				typeof(newState)
			)
			return
		end
		-- Programmatic state changes bypass confirmation.
		-- Confirmation is only for user clicks.
		if newState ~= state then
			applyState(
				newState,
				true,
				true
			)
		end
	end
	function self:GetState()
		return state
	end
	function self:SetVisibility(visible)
		row.Visible = visible
	end
	function self:UpdateName(newName)
		label.Text = newName
	end
	-- Component-owned theming. Re-stamps the live colors and re-applies the
	-- current on/off state (no animation, no callback). ThemeManager calls this
	-- via the component registry on a theme switch.
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		self._themeResolved = theme
		thumb:SetAttribute("ThemePrimary", theme.PrimaryColor)
		thumb:SetAttribute("ThemeSecondary", theme.SecondaryColor)
		label.TextColor3 = theme.PrimaryTextColor or label.TextColor3
		sheen.Image = theme.Wallpaper or "rbxassetid://11094025229"
		sheen.Visible = not (theme.WallpaperEnabled == false)
		applyState(state, false, false)
	end
	ThemeManager.Register(row, self)
	return self
end
return Toggle