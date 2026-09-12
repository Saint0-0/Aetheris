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
local Keybind = {}
Keybind.__index = Keybind

-- Short display labels for long Enum.KeyCode names (cosmetic only -- the stored
-- value and callback still use the full KeyCode.Name).
local KEY_DISPLAY = {
	LeftControl = "LtCtrl", RightControl = "RtCtrl",
	LeftShift = "LtShift", RightShift = "RtShift",
	LeftAlt = "LtAlt", RightAlt = "RtAlt",
	-- digits show as the numeral
	Zero = "0", One = "1", Two = "2", Three = "3", Four = "4",
	Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
	-- punctuation shows as the actual character
	Backquote = "`", Equals = "=", Minus = "-",
	LeftBracket = "[", RightBracket = "]", BackSlash = "\\",
	Quote = "'", Comma = ",", Period = ".", Semicolon = ";",
}

-- Keys the user is allowed to bind: A-Z, 0-9, Control/Shift/Alt (both sides),
-- and ` = - [ ] \ ' , . ;
local ALLOWED = {}
for _, kc in ipairs({
	Enum.KeyCode.A, Enum.KeyCode.B, Enum.KeyCode.C, Enum.KeyCode.D, Enum.KeyCode.E,
	Enum.KeyCode.F, Enum.KeyCode.G, Enum.KeyCode.H, Enum.KeyCode.I, Enum.KeyCode.J,
	Enum.KeyCode.K, Enum.KeyCode.L, Enum.KeyCode.M, Enum.KeyCode.N, Enum.KeyCode.O,
	Enum.KeyCode.P, Enum.KeyCode.Q, Enum.KeyCode.R, Enum.KeyCode.S, Enum.KeyCode.T,
	Enum.KeyCode.U, Enum.KeyCode.V, Enum.KeyCode.W, Enum.KeyCode.X, Enum.KeyCode.Y,
	Enum.KeyCode.Z,
	Enum.KeyCode.Zero, Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
	Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven,
	Enum.KeyCode.Eight, Enum.KeyCode.Nine,
	Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl,
	Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift,
	Enum.KeyCode.LeftAlt, Enum.KeyCode.RightAlt,
	Enum.KeyCode.Backquote, Enum.KeyCode.Equals, Enum.KeyCode.Minus,
	Enum.KeyCode.LeftBracket, Enum.KeyCode.RightBracket, Enum.KeyCode.BackSlash,
	Enum.KeyCode.Quote, Enum.KeyCode.Comma, Enum.KeyCode.Period, Enum.KeyCode.Semicolon,
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
	local row = Instance.new("Frame")
	row.Name = name .. "Keybind"
	row.BorderSizePixel = 0
	row.BackgroundColor3 = Color3.fromRGB(31, 32, 34)
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 45)
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.new(0.5, 0, 0.5, 0)
	row.BorderColor3 = Color3.fromRGB(0, 0, 0)
	row.Parent = parent
	-- Label
	local label = Instance.new("TextLabel")
	label.Name = "ElementName"
	label.TextWrapped = true
	label.BorderSizePixel = 0
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTransparency = (theme and theme.PrimaryTextTransparency) or 0.45
	label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	label.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	label.TextColor3 = (theme and theme.PrimaryTextColor)
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Size = UDim2.new(0.48591, 0, 0.71359, 0)
	label.Position = UDim2.new(0, 0, 0.5, 0)
	label.BorderColor3 = Color3.fromRGB(0, 0, 0)
	label.Text = name
	label.Parent = row
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
	inputBox.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	inputBox.AnchorPoint = Vector2.new(1, 0.5)
	inputBox.ClearTextOnFocus = true
	inputBox.PlaceholderText = "[...]"
	inputBox.Size = UDim2.new(0, 45, 0, 29)
	inputBox.Position = UDim2.new(1, 0, 0.5, 0)
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
	local previousKey = currentKey  -- store the key before binding starts
	local isBinding = false
	local connection = nil
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
		-- Rebinding notification (optional): fired whenever the bind CHANGES.
		if Settings.OnRebind then
			Settings.OnRebind(currentKey)
		end
	end
	-- Gameplay dispatch: pressing the bound key calls Settings.Callback(key).
	-- The Keybind owns this listener, so a caller only has to supply Callback --
	-- no external registry or shared UserInputService listener required.
	--  * Callback = fired when the bound key is PRESSED during gameplay.
	--  * OnRebind = fired when the bind CHANGES (rebind in the box).
	local pressConnection = UserInputService.InputBegan:Connect(function(input, processed)
		-- Ignore while the box is capturing a new bind.
		if isBinding then return end
		-- Respect game-processed input (chat / a focused TextBox).
		if processed then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if currentKey ~= "" and input.KeyCode.Name == currentKey then
			if Settings.Callback then
				Settings.Callback(currentKey)
			end
		end
	end)
	-- Brighten stroke (hover/focus effect)
	local function setStrokeBright(bright)
		local liveTheme = ActiveTheme.theme or theme
		local targetTrans = bright and 0.3 or (liveTheme and liveTheme.StrokeTransparency or 0.95)
		local targetColor = liveTheme.StrokeColor
		Tween.Play(stroke, "Fast", { Transparency = targetTrans, Color = targetColor })
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
		inputBox.Text = ""  -- clear the box for new input
		-- Listen for key presses
		connection = UserInputService.InputBegan:Connect(function(input, processed)
			-- NOTE: deliberately NOT early-returning on `processed` here.
			-- Since this TextBox is focused and editable, normal keystrokes are
			-- consumed by the UI for text entry (processed == true). That's fine
			-- and expected for a keybind capture box -- we still want to see the
			-- key. setKey() below overwrites whatever the TextBox typed natively.
			if not isBinding then return end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local keyCode = input.KeyCode
				-- Only accept the allowed set (A-Z, 0-9, Ctrl/Shift/Alt, and the
				-- listed punctuation). Backspace clears the bind; anything else is
				-- ignored and we keep listening.
				if keyCode == Enum.KeyCode.Backspace then
					setKey("")  -- clear the key
					isBinding = false
					inputBox:ReleaseFocus()
					if connection then connection:Disconnect() end
					setStrokeBright(false)
				elseif ALLOWED[keyCode] then
					setKey(keyCode.Name)
					isBinding = false
					inputBox:ReleaseFocus()
					if connection then connection:Disconnect() end
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
			if connection then connection:Disconnect() end
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
		if pressConnection then pressConnection:Disconnect() end
		if connection then connection:Disconnect() end
	end
	row.Destroying:Connect(disconnectAll)
	self.Destroy = function()
		disconnectAll()
		if row.Parent then row:Destroy() end
	end
	-- Component-owned theming (see ThemeManager registry).
	function self:ApplyTheme(newTheme)
		theme = ThemeManager.GetTheme(newTheme)
		self._theme = theme
		label.TextColor3 = theme.PrimaryTextColor or label.TextColor3
		label.TextTransparency = theme.PrimaryTextTransparency or label.TextTransparency
		inputBox.TextColor3 = theme.SecondaryTextColor or inputBox.TextColor3
		inputBox.TextTransparency = theme.SecondaryTextTransparency or inputBox.TextTransparency
		inputBox.BackgroundColor3 = theme.InputBackgroundColor or inputBox.BackgroundColor3
		inputBox.BackgroundTransparency = theme.InputBackgroundTransparency or inputBox.BackgroundTransparency
		stroke.Color = theme.StrokeColor or stroke.Color
		stroke.Transparency = theme.StrokeTransparency or stroke.Transparency
	end
	ThemeManager.Register(row, self)
	return self
end
return Keybind