--[[
	Toggle  ·  Aetheris UI Library

	Boolean switch row with an optional confirmation. An IsOn attribute keeps
	the on/off look stable across theme switches.
]]

local ThemeManager = require("../Themes/ThemeManager")
local Tween = require("../Utils/Tween")
local ComponentRow = require("./ComponentRow")
local ComponentAPI = require("../Utils/ComponentAPI")
local PageAwareness = require("../Utils/PageAwareness")
local UUID = require("../Utils/UUID")
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
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. " [Toggle]",
		Theme = theme,
		Clickable = true,
		LabelWidth = 0.486,
	})

	local toggleInterractionHolder = Instance.new("Frame")
	toggleInterractionHolder.Name = UUID.Static("InterractionHolder")
	toggleInterractionHolder.BackgroundTransparency = 1
	toggleInterractionHolder.AnchorPoint = Vector2.new(1, 0.5)
	toggleInterractionHolder.Size = UDim2.new(0, 65, 1, 0)
	toggleInterractionHolder.Position = UDim2.fromScale(1, 0.5)
	toggleInterractionHolder.Parent = row

	----------------------------------------------------------------
	-- TRACK
	----------------------------------------------------------------
	local track = Instance.new("Frame")
	track.Name = UUID.Static("ToggleSlidingFrame")
	track.BorderSizePixel = 0
	track.BackgroundColor3 = theme.SecondaryColor
	track.BackgroundTransparency = 0.9
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Size = UDim2.fromOffset(34, 2)
	track.Position = UDim2.fromScale(0.5, 0.5)
	track.Parent = toggleInterractionHolder
	self.track = track
	----------------------------------------------------------------
	-- THUMB
	----------------------------------------------------------------
	local thumb = Instance.new("TextButton")
	thumb.Name = UUID.Static("Toggle")
	thumb.BorderSizePixel = 0
	thumb.BackgroundColor3 = (theme and theme.PrimaryColor)
	thumb.BackgroundTransparency = 1
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Size = UDim2.fromOffset(14, 14)
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
	sheen.Name = UUID.Static("BackImage")
	sheen.BorderSizePixel = 0
	sheen.BackgroundTransparency = 1
	sheen.Image = theme.Wallpaper or "rbxassetid://11094025229"
	sheen:SetAttribute("IsThemeSheen", true)
	sheen.ImageTransparency = 1
	sheen.AnchorPoint = Vector2.new(0.5, 0.5)
	sheen.Position = UDim2.fromScale(0.5, 0.5)
	sheen.Size = UDim2.fromScale(1, 1)
	sheen.Parent = thumb
	local sheenCorner = Instance.new("UICorner")
	sheenCorner.CornerRadius = UDim.new(1, 0)
	sheenCorner.Parent = sheen
	local sheenGradient = Instance.new("UIGradient")
	sheenGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.000, 1),
		NumberSequenceKeypoint.new(0.324, 0.80625),
		NumberSequenceKeypoint.new(0.600, 0.6875),
		NumberSequenceKeypoint.new(0.726, 0.55),
		NumberSequenceKeypoint.new(0.844, 0.36875),
		NumberSequenceKeypoint.new(1.000, 0),
	})
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
	-- DECLARATIVE THEME BINDINGS (no ApplyTheme body)
	----------------------------------------------------------------
	-- Label colour is pure theme; thumb/track/stroke are bindings whose key
	-- applyState swaps for ON (PrimaryColor) and OFF (SecondaryColor).
	local FAST = { duration = 0.2 }
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	local thumbColorBinding =
		ThemeManager.BindColor(thumb, "BackgroundColor3", state and "PrimaryColor" or "SecondaryColor", FAST)
	local trackColorBinding =
		ThemeManager.BindColor(track, "BackgroundColor3", state and "PrimaryColor" or "SecondaryColor", FAST)
	local strokeColorBinding =
		ThemeManager.BindColor(stroke, "Color", state and "PrimaryColor" or "SecondaryColor", FAST)
	----------------------------------------------------------------
	-- APPLY STATE
	----------------------------------------------------------------
	local function applyState(newState, animate, fireCallback)
		if state == newState and fireCallback then
			return
		end
		state = newState
		thumb:SetAttribute("IsOn", state)
		-- Swap which theme key drives the state-coloured parts; the bindings
		-- resolve + crossfade the new colour. No manual colour stamping.
		local onKey = state and "PrimaryColor" or "SecondaryColor"
		thumbColorBinding:SetKey(onKey)
		trackColorBinding:SetKey(onKey)
		strokeColorBinding:SetKey(onKey)
		local targetPos = state and onPos or offPos
		local targetBgTransparency = state and 0 or 1
		local targetStrokeTransparency = state and 0 or 0.7
		local targetTrackTransparency = state and 0 or 0.9
		local targetLabelTransparency = state and 0.1 or 0.45
		-- Keep PageFade's cached fade-base in sync with the CURRENT resting
		-- stroke transparency. applyState changes the stroke OUTSIDE ApplyTheme,
		-- so without this a page fade would restore a stale base (the
		-- "stroke stays invisible until hover" bug).
		stroke:SetAttribute("PageFadeBase", targetStrokeTransparency)
		if animate then
			Tween.Play(thumb, "Fast", {
				Position = targetPos,
				BackgroundTransparency = targetBgTransparency,
			})
			Tween.Play(stroke, "Fast", {
				Transparency = targetStrokeTransparency,
			})
			Tween.Play(label, "Fast", {
				TextTransparency = targetLabelTransparency,
			})
			Tween.Play(track, "Fast", {
				BackgroundTransparency = targetTrackTransparency,
			})
			Tween.Play(sheen, "Fast", {
				ImageTransparency = state and 0 or 1,
			})
		else
			thumb:SetAttribute("IsOn", state)
			thumb.Position = targetPos
			thumb.BackgroundTransparency = targetBgTransparency
			stroke.Transparency = targetStrokeTransparency
			label.TextTransparency = targetLabelTransparency
			track.BackgroundTransparency = targetTrackTransparency
			sheen.ImageTransparency = state and 0 or 1
		end
		-- The sheen is only VISIBLE while ON, so don't let it spin while OFF:
		-- pause it (angle preserved) and resume from where it left off next time
		-- the toggle turns on. Composes with the shared visibility gate.
		Tween.SetSpinWanted(sheenGradient, state)
		if fireCallback and Settings.Callback then
			Settings.Callback(state)
		end
	end
	----------------------------------------------------------------
	-- PAGE FOCUS DIM (visual-only; does NOT change `state`)
	----------------------------------------------------------------
	-- Off-page, the control collapses to a zeroed look (thumb parked at off,
	-- chrome faded) so returning to the page can tween it back to its real
	-- value via applyState(state). `state` is untouched, so GetState() and the
	-- saved setting are unaffected by the animation.
	local dimmed = false
	local function setDimmed(on)
		dimmed = on
		if on then
			Tween.Play(thumb, "Fast", { Position = offPos, BackgroundTransparency = 1 })
			Tween.Play(stroke, "Fast", { Transparency = 1 })
			Tween.Play(track, "Fast", { BackgroundTransparency = 1 })
			Tween.Play(sheen, "Fast", { ImageTransparency = 1 })
			-- Park the sheen spin while dimmed (composes with the ON/OFF gate).
			Tween.SetSpinWanted(sheenGradient, false)
		else
			-- Restore: recompute the real look from `state`, animating back.
			applyState(state, true, false)
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
				Title = confirm.Title or "Confirm Action",
				Description = confirm.Description or "Are you sure you want to change this setting?",
				TitleColor = confirm.TitleColor,
				ConfirmText = confirm.ConfirmText or "Yes",
				CancelText = confirm.CancelText or "No",
				----------------------------------------------------
				-- CONFIRMED
				----------------------------------------------------
				OnConfirm = function()
					confirmationPending = false
					-- Apply the state requested when the
					-- notification was originally opened.
					applyState(intendedState, true, true)
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
			applyState(intendedState, true, true)
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
	applyState(default, false, false)
	----------------------------------------------------------------
	-- PUBLIC API
	----------------------------------------------------------------
	self.UpdateState = function(_self, newState)
		if typeof(newState) ~= "boolean" then
			warn("[Toggle] UpdateState expected a boolean, got:", typeof(newState))
			return
		end
		-- Programmatic state changes bypass confirmation.
		-- Confirmation is only for user clicks.
		if newState ~= state then
			applyState(newState, true, true)
		end
	end
	self.GetState = function(_self)
		return state
	end
	self.SetVisibility = function(_self, visible)
		row.Visible = visible
	end
	self.UpdateName = function(_self, newName)
		label.Text = newName
	end
	-- Colours are bindings, but the state transparencies are set by applyState's
	-- own tweens; a theme switch cancels those tweens, so re-stamp the resting
	-- state after every theme apply to avoid a half-faded toggle.
	local unregisterTheme = ThemeManager.OnThemeApplied(function()
		applyState(state, false, false)
		-- A theme switch re-stamps the real look; if we're currently dimmed
		-- off-page, re-collapse so the switch doesn't pop it back to full.
		if dimmed then
			setDimmed(true)
		end
	end, row)

	-- Page awareness: collapse off-page, tween back to `state` on focus. Gated
	-- by the UI Settings "Page Animations" toggle; OnActive always restores.
	PageAwareness.Register(row, {
		Gate = "PageAnimations",
		OnInactive = function()
			setDimmed(true)
		end,
		OnActive = function()
			setDimmed(false)
		end,
	})

	self.Destroy = function(_self)
		if unregisterTheme then
			unregisterTheme()
			unregisterTheme = nil
		end
		-- Stop the sheen gradient spin before destroying.
		Tween.StopSpin(sheenGradient)
		-- Cancel any in-flight tweens on themed instances.
		Tween.CancelAll(thumb)
		Tween.CancelAll(track)
		Tween.CancelAll(stroke)
		Tween.CancelAll(label)
		Tween.CancelAll(sheen)
		-- Drop all ThemeManager bindings for every instance we registered.
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(thumb)
		ThemeManager.UnbindInstance(track)
		ThemeManager.UnbindInstance(stroke)
		-- Destroy the root instance (cascades to all children).
		if row and row.Parent then
			row:Destroy()
		end
	end
	ComponentAPI.Apply(self, { Root = row, Label = label, Name = name })
	return self
end
return Toggle
