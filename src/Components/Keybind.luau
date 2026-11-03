--[[
	Aetheris/Components/Keybind.luau

	Captures one key into a focused box and dispatches press/rebind callbacks
	through the shared KeybindDispatcher, so every row listens with one
	keystroke lookup instead of its own InputBegan handler.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Tween = require("../Utils/Tween")
local UserInputService = game:GetService("UserInputService")
local ThemeManager = require("../Themes/ThemeManager")
local ActiveTheme = require("../Themes/ActiveTheme")
local KeybindDispatcher = require("../Utils/KeybindDispatcher")
local Constants = require("../Constants")
local ComponentRow = require("./ComponentRow")
local ComponentAPI = require("../Utils/ComponentAPI")
local UUID = require("../Utils/UUID")
local Keybind = {}
Keybind.__index = Keybind

-- display labels for long KeyCode names; stored values stay the full name
local KEY_DISPLAY = {
	LeftControl = "LtCtrl",
	RightControl = "RtCtrl",
	LeftShift = "LtShift",
	RightShift = "RtShift",
	LeftAlt = "LtAlt",
	RightAlt = "RtAlt",
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

-- what the user may bind: A-Z, 0-9, Control/Shift/Alt, and ` = - [ ] \ ' , . ;
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
	local row, label = ComponentRow.new(parent, {
		Name = name,
		RowName = name .. "Keybind",
		Theme = theme,
		LabelWidth = 0.48591,
	})
	local inputBox = Instance.new("TextBox")
	inputBox.Name = UUID.Static("InputBox")
	inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	inputBox.BorderSizePixel = 0
	inputBox.TextWrapped = true
	inputBox.TextTransparency = (theme and theme.SecondaryTextTransparency) or 0.4
	inputBox.TextSize = 11
	inputBox.TextColor3 = (theme and theme.SecondaryTextColor)
	inputBox.BackgroundColor3 = theme.InputBackgroundColor
	inputBox.BackgroundTransparency = theme.InputBackgroundTransparency
	inputBox:SetAttribute(UUID.Static("IsInputBackground"), true)
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
	local previousKey = currentKey -- key before binding started, restored on cancel
	local isBinding = false
	local connection = nil
	local pressToken = nil -- KeybindDispatcher registration token (gameplay press)
	-- forward-declared: setKey re-registers the dispatcher entry whenever the
	-- bind changes, so it needs a function defined below
	local updatePressRegistration
	local function setKey(key)
		currentKey = key
		if key and key ~= "" then
			-- display shortens long names (LeftControl -> LtCtrl) and uppercases
			-- single letters; the stored/callback value stays the full name
			inputBox.Text = KEY_DISPLAY[key] or ((#key == 1) and string.upper(key) or key)
		else
			inputBox.Text = ""
		end
		if updatePressRegistration then
			updatePressRegistration()
		end
		if Settings.OnRebind then
			Settings.OnRebind(currentKey)
		end
	end
	-- Callback = bound key pressed during gameplay; OnRebind = the bind changed.
	-- One shared dispatcher owns the single InputBegan listener for every row.
	updatePressRegistration = function()
		if pressToken then
			KeybindDispatcher.Unregister(pressToken)
			pressToken = nil
		end
		if currentKey and currentKey ~= "" then
			pressToken = KeybindDispatcher.Register(currentKey, function()
				-- ignore while the box is capturing a new bind
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
		-- keep PageFade's base at the resting alpha so it never restores a brighten
		stroke:SetAttribute(UUID.Static("PageFadeBase"), restTrans)
	end
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
	inputBox.Focused:Connect(function()
		previousKey = currentKey
		setStrokeBright(true)
		isBinding = true
		inputBox.Text = "" -- clear the box for new input
		connection = UserInputService.InputBegan:Connect(function(input, _)
			-- no early return on `processed` here: while this box is focused,
			-- keystrokes are consumed as text entry, but a bind capture still
			-- needs to see them (setKey overwrites whatever the box typed)
			if not isBinding then
				return
			end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local keyCode = input.KeyCode
				-- Backspace clears the bind; outside the allowed set is ignored
				-- and we keep listening
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
		-- still in binding mode means no key was captured: revert
		if isBinding then
			isBinding = false
			if connection then
				connection:Disconnect()
			end
			currentKey = previousKey
			if currentKey and currentKey ~= "" then
				inputBox.Text = string.upper(currentKey)
			else
				inputBox.Text = ""
			end
		end
		setStrokeBright(false)
	end)
	setKey(default)

	-- drop the input listeners so nothing fires on a dead UI
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
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	ThemeManager.BindColor(inputBox, "TextColor3", "SecondaryTextColor")
	ThemeManager.BindTransparency(inputBox, "TextTransparency", "SecondaryTextTransparency")
	ThemeManager.BindColor(inputBox, "BackgroundColor3", "InputBackgroundColor")
	ThemeManager.BindTransparency(inputBox, "BackgroundTransparency", "InputBackgroundTransparency")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	ComponentAPI.Apply(self, {
		Root = row,
		Label = label,
		Name = name,
		Methods = {
			GetBind = function()
				return currentKey
			end,
			SetBind = function(_, key)
				setKey(key)
			end,
			Destroy = function()
				disconnectAll()
				if row.Parent then
					row:Destroy()
				end
			end,
		},
	})
	return self
end
return Keybind
