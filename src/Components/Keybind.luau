--[[
	Keybind  ·  Aetheris UI Library

	Captures a single key and dispatches on press. The component owns its own
	input listener, so callers only supply the callbacks -- no external
	registry or shared listener is required.

	Callbacks:
		Callback(key)  - fires when the bound key is PRESSED in gameplay.
		OnRebind(key)  - fires when the bind CHANGES (including the initial set).

	Usage:
		local keybind = section:Keybind({
			Name = "My Keybind",
			Default = "G",                    -- optional initial key
			Callback = function(key) end,     -- on press
			OnRebind = function(key) end,     -- on change
		})
]]

local Tween = require("../Utils/Tween")
local UserInputService = game:GetService("UserInputService")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local KeybindDispatcher = require("../Utils/KeybindDispatcher")
local Constants = require("../Constants")
local ComponentRow = require("./ComponentRow")
local Keybind = {}
Keybind.__index = Keybind

-- Short display labels for long Enum.KeyCode names (cosmetic only -- the stored
-- value and callback still use the full KeyCode.Name).
local KEY_DISPLAY = {
	LeftControl = "LtCtrl",
	RightControl = "RtCtrl",
	LeftShift = "LtShift",
	RightShift = "RtShift",
	LeftAlt = "LtAlt",
	RightAlt = "RtAlt",
	-- digits show as the numeral
	Zero = "0",
	One = "1",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Seven = "7",
	Eight = "8",
	Nine = "9",
	-- punctuation shows as the actual character
	Backquote = "`",
	Equals = "=",
	Minus = "-",
	LeftBracket = "[",
	RightBracket = "]",
	BackSlash = "\\",
	Quote = "'",
	Comma = ",",
	Period = ".",
	Semicolon = ";",
}

-- Keys the user is allowed to bind: A-Z, 0-9, Control/Shift/Alt (both sides),
-- and ` = - [ ] \ ' , . ;
local ALLOWED = {}
for _, kc in ipairs({
	Enum.KeyCode.A,
	Enum.KeyCode.B,
	Enum.KeyCode.C,
	Enum.KeyCode.D,
	Enum.KeyCode.E,
	Enum.KeyCode.F,
	Enum.KeyCode.G,
	Enum.KeyCode.H,
	Enum.KeyCode.I,
	Enum.KeyCode.J,
	Enum.KeyCode.K,
	Enum.KeyCode.L,
	Enum.KeyCode.M,
	Enum.KeyCode.N,
	Enum.KeyCode.O,
	Enum.KeyCode.P,
	Enum.KeyCode.Q,
	Enum.KeyCode.R,
	Enum.KeyCode.S,
	Enum.KeyCode.T,
	Enum.KeyCode.U,
	Enum.KeyCode.V,
	Enum.KeyCode.W,
	Enum.KeyCode.X,
	Enum.KeyCode.Y,
	Enum.KeyCode.Z,
	Enum.KeyCode.Zero,
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.LeftControl,
	Enum.KeyCode.RightControl,
	Enum.KeyCode.LeftShift,
	Enum.KeyCode.RightShift,
	Enum.KeyCode.LeftAlt,
	Enum.KeyCode.RightAlt,
	Enum.KeyCode.Backquote,
	Enum.KeyCode.Equals,
	Enum.KeyCode.Minus,
	Enum.KeyCode.LeftBracket,
	Enum.KeyCode.RightBracket,
	Enum.KeyCode.BackSlash,
	Enum.KeyCode.Quote,
	Enum.KeyCode.Comma,
	Enum.KeyCode.Period,
	Enum.KeyCode.Semicolon,
}) do
	ALLOWED[kc] = true
end

function Keybind.new(parent, Settings, theme)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Keybind)
	self._theme = theme
	local name = Settings.Name or "Keybind"
	local default = Settings.Default or ""
	-- Row frame
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "Keybind",
		Theme = theme,
		LabelWidth = 0.48591,
	})
	-- Input box
	local inputBox = Instance.new("TextBox")
	inputBox.Name = "InputBox"
	inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	inputBox.BorderSizePixel = 0
	inputBox.TextWrapped = true
	inputBox.TextTransparency = (theme and theme.SecondaryTextTransparency) or 0.4
	inputBox.TextSize = 11
	inputBox.TextColor3 = (theme and theme.SecondaryTextColor)
	inputBox.BackgroundColor3 = theme.InputBackgroundColor
	inputBox.BackgroundTransparency = theme.InputBackgroundTransparency
	inputBox:SetAttribute("IsInputBackground", true)
	inputBox.FontFace = Constants.Font(Enum.FontWeight.Medium)
	inputBox.AnchorPoint = Vector2.new(1, 0.5)
	inputBox.ClearTextOnFocus = true
	inputBox.PlaceholderText = "[...]"
	inputBox.Size = UDim2.fromOffset(45, 29)
	inputBox.Position = UDim2.fromScale(1, 0.5)
	inputBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	inputBox.Text = ""
	inputBox.Parent = row
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = inputBox
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	stroke.Thickness = 0.7
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = inputBox
	-- State
	local currentKey = default or ""
	local previousKey = currentKey -- store the key before binding starts
	local isBinding = false
	local connection = nil
	local pressToken = nil -- KeybindDispatcher registration token (gameplay press)
	-- Forward declaration: setKey re-registers the dispatcher entry whenever
	-- the bind changes, so setKey needs to call a function defined below.
	local updatePressRegistration
	-- Helper to set the displayed key
	local function setKey(key)
		currentKey = key
		if key and key ~= "" then
			-- Display: single letters uppercase (M), long names shortened
			-- (LeftControl -> LtCtrl). The stored/callback value stays the full name.
			inputBox.Text = KEY_DISPLAY[key] or ((#key == 1) and string.upper(key) or key)
		else
			inputBox.Text = ""
		end
		-- Keep the dispatcher map in sync with the new bind.
		if updatePressRegistration then
			updatePressRegistration()
		end
		-- Rebinding notification (optional): fired whenever the bind CHANGES.
		if Settings.OnRebind then
			Settings.OnRebind(currentKey)
		end
	end
	-- Gameplay dispatch: pressing the bound key calls Settings.Callback(key).
	-- ONE shared KeybindDispatcher owns the single UserInputService.InputBegan
	-- listener for every Keybind row (map lookup by KeyCode.Name), instead of
	-- each row connecting its own listener that string-compares every key.
	--  * Callback = fired when the bound key is PRESSED during gameplay.
	--  * OnRebind = fired when the bind CHANGES (rebind in the box).
	updatePressRegistration = function()
		if pressToken then
			KeybindDispatcher.Unregister(pressToken)
			pressToken = nil
		end
		if currentKey and currentKey ~= "" then
			pressToken = KeybindDispatcher.Register(currentKey, function()
				-- Ignore while the box is capturing a new bind.
				if isBinding then
					return
				end
				if Settings.Callback then
					Settings.Callback(currentKey)
				end
			end)
		end
	end
	-- Brighten stroke (hover/focus effect)
	local function setStrokeBright(bright)
		local liveTheme = ActiveTheme.theme or theme
		local restTrans = liveTheme and liveTheme.StrokeTransparency or 0.95
		local targetTrans = bright and 0.3 or restTrans
		local targetColor = liveTheme.StrokeColor
		Tween.Play(stroke, "Fast", { Transparency = targetTrans, Color = targetColor })
		-- Keep PageFade's cached base at the RESTING transparency so a page fade
		-- never restores a transient hover/focus brighten.
		stroke:SetAttribute("PageFadeBase", restTrans)
	end
	-- Hover events on row and input box
	local function onHoverEnter()
		setStrokeBright(true)
	end
	local function onHoverLeave()
		if not inputBox:IsFocused() then
			setStrokeBright(false)
		end
	end
	row.MouseEnter:Connect(onHoverEnter)
	row.MouseLeave:Connect(onHoverLeave)
	inputBox.MouseEnter:Connect(onHoverEnter)
	inputBox.MouseLeave:Connect(onHoverLeave)
	-- Focus events
	inputBox.Focused:Connect(function()
		-- Store current key before binding
		previousKey = currentKey
		setStrokeBright(true)
		isBinding = true
		inputBox.Text = "" -- clear the box for new input
		-- Listen for key presses
		connection = UserInputService.InputBegan:Connect(function(input, _)
			-- NOTE: deliberately NOT early-returning on the second arg (processed) here.
			-- Since this TextBox is focused and editable, normal keystrokes are
			-- consumed by the UI for text entry (processed == true). That's fine
			-- and expected for a keybind capture box -- we still want to see the
			-- key. setKey() below overwrites whatever the TextBox typed natively.
			if not isBinding then
				return
			end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local keyCode = input.KeyCode
				-- Only accept the allowed set (A-Z, 0-9, Ctrl/Shift/Alt, and the
				-- listed punctuation). Backspace clears the bind; anything else is
				-- ignored and we keep listening.
				if keyCode == Enum.KeyCode.Backspace then
					setKey("") -- clear the key
					isBinding = false
					inputBox:ReleaseFocus()
					if connection then
						connection:Disconnect()
					end
					setStrokeBright(false)
				elseif ALLOWED[keyCode] then
					setKey(keyCode.Name)
					isBinding = false
					inputBox:ReleaseFocus()
					if connection then
						connection:Disconnect()
					end
					setStrokeBright(false)
				end
			end
		end)
	end)
	inputBox.FocusLost:Connect(function()
		-- If we are still in binding mode (no key was captured), revert to previousKey
		if isBinding then
			-- Clean up binding state
			isBinding = false
			if connection then
				connection:Disconnect()
			end
			-- Restore previous key
			currentKey = previousKey
			if currentKey and currentKey ~= "" then
				inputBox.Text = string.upper(currentKey)
			else
				inputBox.Text = ""
			end
		end
		-- Always dim the stroke on focus loss
		setStrokeBright(false)
	end)
	-- Set initial key
	setKey(default)
	-- Public API
	self.GetBind = function()
		return currentKey
	end
	self.SetBind = function(key)
		setKey(key)
	end
	self.SetVisibility = function(visible)
		row.Visible = visible
	end
	self.UpdateName = function(newName)
		label.Text = newName
	end
	-- Cleanup: when this row is removed (e.g. the whole window is destroyed),
	-- drop the input listeners so nothing fires on a dead UI.
	local function disconnectAll()
		if pressToken then
			KeybindDispatcher.Unregister(pressToken)
			pressToken = nil
		end
		if connection then
			connection:Disconnect()
		end
	end
	row.Destroying:Connect(disconnectAll)
	self.Destroy = function()
		disconnectAll()
		if row.Parent then
			row:Destroy()
		end
	end
	-- Declarative theming: every themed property is a BINDING.
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(inputBox, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(inputBox, "TextTransparency", "SecondaryTextTransparency")
	ThemeManager.BindColor(inputBox, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(inputBox, "BackgroundTransparency", "InputBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	return self
end
return Keybind
