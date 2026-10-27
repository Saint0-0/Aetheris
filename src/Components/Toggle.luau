--[[
	Aetheris/Components/Toggle.luau

	Boolean switch row with an optional confirmation. An IsOn attribute keeps
	the on/off look stable across theme switches.

	License: Saint0-0 Source License - use in your own scripts, no editing or
	redistribution without permission. (c) 2026 Saint0-0.
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
	-- Seed the live-theme attributes so applyState reads current colours even
	-- before the first theme apply stamps them.
	thumb:SetAttribute(UUID.Static("ThemePrimary"), theme.PrimaryColor)
	thumb:SetAttribute(UUID.Static("ThemeSecondary"), theme.SecondaryColor)

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.Parent = thumb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = thumb

	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.7
	stroke.Thickness = 1.5
	stroke.Color = theme.PrimaryColor
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = thumb

	local sheen = Instance.new("ImageLabel")
	sheen.Name = UUID.Static("BackImage")
	sheen.BorderSizePixel = 0
	sheen.BackgroundTransparency = 1
	sheen.Image = theme.Wallpaper or "rbxassetid://11094025229"
	sheen:SetAttribute(UUID.Static("IsThemeSheen"), true)
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
	sheenGradient.Rotation = 0
	Tween.StartSpin(sheenGradient, { Rotation = 360 }, "SpinIdle")

	local state = default
	local offPos = UDim2.new(0, -6, 0.5, 0)
	local onPos = UDim2.new(0, 41, 0.5, 0)
	local confirmationPending = false

	-- Label colour is pure theme; thumb/track/stroke are bindings whose key
	-- applyState swaps between PrimaryColor (ON) and SecondaryColor (OFF).
	local FAST = { duration = 0.2 }
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	local thumbColorBinding =
		ThemeManager.BindColor(thumb, "BackgroundColor3", state and "PrimaryColor" or "SecondaryColor", FAST)
	local trackColorBinding =
		ThemeManager.BindColor(track, "BackgroundColor3", state and "PrimaryColor" or "SecondaryColor", FAST)
	local strokeColorBinding =
		ThemeManager.BindColor(stroke, "Color", state and "PrimaryColor" or "SecondaryColor", FAST)

	local function applyState(newState, animate, fireCallback)
		if state == newState and fireCallback then
			return
		end
		state = newState
		thumb:SetAttribute(UUID.Static("IsOn"), state)
		local onKey = state and "PrimaryColor" or "SecondaryColor"
		thumbColorBinding:SetKey(onKey)
		trackColorBinding:SetKey(onKey)
		strokeColorBinding:SetKey(onKey)
		local targetPos = state and onPos or offPos
		local targetBgTransparency = state and 0 or 1
		local targetStrokeTransparency = state and 0 or 0.7
		local targetTrackTransparency = state and 0 or 0.9
		local targetLabelTransparency = state and 0.1 or 0.45
		-- PageFade caches its fade-base from ApplyTheme, but applyState changes
		-- the stroke here, so keep the cached base in sync.
		stroke:SetAttribute(UUID.Static("PageFadeBase"), targetStrokeTransparency)
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
			thumb:SetAttribute(UUID.Static("IsOn"), state)
			thumb.Position = targetPos
			thumb.BackgroundTransparency = targetBgTransparency
			stroke.Transparency = targetStrokeTransparency
			label.TextTransparency = targetLabelTransparency
			track.BackgroundTransparency = targetTrackTransparency
			sheen.ImageTransparency = state and 0 or 1
		end
		-- The sheen is invisible while OFF, so pause the spin there; it resumes
		-- from the frozen angle the next time the toggle turns on.
		Tween.SetSpinWanted(sheenGradient, state)
		if fireCallback and Settings.Callback then
			Settings.Callback(state)
		end
	end

	-- Page-focus dim is visual only; `state` (GetState, the saved setting) is
	-- never touched, so the restore tween can return to the real value.
	local dimmed = false
	local function setDimmed(on, instant)
		dimmed = on
		if on then
			if instant then
				-- Snap at registration so the very first restore tween has real
				-- distance to cover.
				thumb.Position = offPos
				thumb.BackgroundTransparency = 1
				stroke.Transparency = 1
				track.BackgroundTransparency = 1
				sheen.ImageTransparency = 1
			else
				Tween.Play(thumb, "Fast", { Position = offPos, BackgroundTransparency = 1 })
				Tween.Play(stroke, "Fast", { Transparency = 1 })
				Tween.Play(track, "Fast", { BackgroundTransparency = 1 })
				Tween.Play(sheen, "Fast", { ImageTransparency = 1 })
			end
			Tween.SetSpinWanted(sheenGradient, false)
		else
			applyState(state, true, false)
		end
	end

	local function handleClick()
		-- One confirmation at a time; extra clicks while one is open are ignored.
		if confirmationPending then
			return
		end
		local intendedState = not state
		-- Confirmation only guards turning ON; OFF (or no confirm) applies
		-- immediately.
		if confirmEnabled and ShowNotification and intendedState then
			confirmationPending = true
			ShowNotification({
				Title = confirm.Title or "Confirm Action",
				Description = confirm.Description or "Are you sure you want to change this setting?",
				TitleColor = confirm.TitleColor,
				ConfirmText = confirm.ConfirmText or "Yes",
				CancelText = confirm.CancelText or "No",
				OnConfirm = function()
					confirmationPending = false
					-- Apply the state captured when the prompt opened rather than
					-- re-reading `state`.
					applyState(intendedState, true, true)
				end,
				OnCancel = function()
					-- Cancel only unlocks; it never applies the pending state.
					confirmationPending = false
				end,
			})
		else
			applyState(intendedState, true, true)
		end
	end

	row.MouseButton1Click:Connect(function()
		handleClick()
	end)
	thumb.MouseButton1Click:Connect(function()
		handleClick()
	end)

	-- Apply the default look without firing the callback during construction.
	applyState(default, false, false)

	self.UpdateState = function(_self, newState)
		if typeof(newState) ~= "boolean" then
			warn("[Toggle] UpdateState expected a boolean, got:", typeof(newState))
			return
		end
		-- Programmatic updates bypass confirmation; that is only for user clicks.
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
	-- A theme switch cancels applyState's transparencies tweens, so re-stamp
	-- the resting state to avoid a half-faded toggle.
	local unregisterTheme = ThemeManager.OnThemeApplied(function()
		applyState(state, false, false)
		-- Re-collapse too, so an off-page toggle doesn't pop back to full.
		if dimmed then
			setDimmed(true)
		end
	end, row)

	-- Collapse off-page and tween back to `state` on focus. "Page Animations"
	-- gates the tweens; OnActive always restores.
	PageAwareness.Register(row, {
		Gate = "PageAnimations",
		OnInactive = function(instant)
			setDimmed(true, instant)
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
		Tween.StopSpin(sheenGradient)
		Tween.CancelAll(thumb)
		Tween.CancelAll(track)
		Tween.CancelAll(stroke)
		Tween.CancelAll(label)
		Tween.CancelAll(sheen)
		ThemeManager.UnbindInstance(label)
		ThemeManager.UnbindInstance(thumb)
		ThemeManager.UnbindInstance(track)
		ThemeManager.UnbindInstance(stroke)
		if row and row.Parent then
			row:Destroy()
		end
	end
	ComponentAPI.Apply(self, { Root = row, Label = label, Name = name })
	return self
end
return Toggle
