--[[
	Aetheris/Components/Label.luau

	Styled text label with an optional container, corner and stroke. With
	ShowStroke = false the stroke is marked caller-owned, so ThemeManager leaves
	it hidden across switches.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ThemeManager = require("../Themes/ThemeManager")
local Constants = require("../Constants")
local ComponentAPI = require("../Utils/ComponentAPI")
local Hyperlinks = require("../Utils/Hyperlinks")
local Locale = require("../Utils/Locale")
local UUID = require("../Utils/UUID")
local Label = {}
Label.__index = Label
local function getFontWeight(weight)
	if typeof(weight) == "EnumItem" then
		return weight
	end
	local weightMap = {
		Regular = Enum.FontWeight.Regular,
		Medium = Enum.FontWeight.Medium,
		SemiBold = Enum.FontWeight.SemiBold,
		Bold = Enum.FontWeight.Bold,
		Heavy = Enum.FontWeight.Heavy,
		ExtraBold = Enum.FontWeight.ExtraBold,
	}
	return weightMap[weight] or Enum.FontWeight.Regular
end
function Label.new(parent, Settings, theme, window)
	theme = ThemeManager.GetTheme(theme)
	Settings = Settings or {}
	local self = setmetatable({}, Label)
	self._theme = theme
	local text = Settings.Text or "Label"
	local hasLinks = Hyperlinks.hasLinks(text)
	local showContainer = (Settings.ShowContainer == nil) and true or Settings.ShowContainer
	local showStroke = ((Settings.ShowStroke == nil) and true or Settings.ShowStroke) and showContainer
	local fontWeight = getFontWeight(Settings.FontWeight or "Regular")
	local textSize = Settings.TextSize or 14
	local customTextTransparency = Settings.TextTransparency
	local paddingOverride = Settings.Padding
	local container = Instance.new("Frame")
	container.Name = UUID.Generate("Label")
	container.BorderSizePixel = 0
	container.BackgroundColor3 = (theme and theme.ComponentBackgroundColor)
	container.BackgroundTransparency = showContainer and ((theme and theme.ComponentBackgroundTransparency) or 0.985)
		or 1
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.Size = UDim2.fromScale(1, 0)
	container:SetAttribute(UUID.Static("IsComponentContainer"), true)
	container.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container
	local stroke = Instance.new("UIStroke")
	if showStroke then
		stroke.Transparency = (theme and theme.StrokeTransparency) or 0.95
	else
		stroke.Transparency = 1
		-- Mark the stroke caller-owned; ThemeManager then skips it.
		stroke:SetAttribute(UUID.Static("ThemeOverride_Transparency"), 1)
	end
	stroke.Color = (theme and theme.StrokeColor)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = container
	local padding = Instance.new("UIPadding")
	if paddingOverride then
		padding.PaddingTop = UDim.new(0, paddingOverride.Top or 0)
		padding.PaddingBottom = UDim.new(0, paddingOverride.Bottom or 0)
		padding.PaddingLeft = UDim.new(0, paddingOverride.Left or 0)
		padding.PaddingRight = UDim.new(0, paddingOverride.Right or 0)
	else
		padding.PaddingTop = UDim.new(0, 15)
		padding.PaddingBottom = UDim.new(0, 15)
		padding.PaddingLeft = UDim.new(0, 11)
		padding.PaddingRight = UDim.new(0, 11)
	end
	padding.Parent = container
	local label = Instance.new("TextLabel")
	label.Name = UUID.Static("ElementName")
	label.FontFace = Constants.Font(fontWeight)
	label.Text = text
	label.RichText = true
	label.TextColor3 = (theme and theme.PrimaryTextColor)
	label.TextSize = textSize
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.fromScale(0, 0.5)
	label.TextTransparency = customTextTransparency or ((theme and theme.PrimaryTextTransparency) or 0.45)
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Parent = container

	local renderer
	if hasLinks then
		-- Hide the plain label but keep it as the locale/search proxy.
		label.Visible = false
		label.Size = UDim2.fromOffset(0, 0)
		label.AutomaticSize = Enum.AutomaticSize.None
		Locale.set(label, "Text", Hyperlinks.plain(text))
		renderer = Hyperlinks.render(container, {
			Text = text,
			Position = UDim2.fromOffset(0, 0),
			Width = UDim2.fromScale(1, 0),
			TextSize = textSize,
			FontFace = Constants.Font(fontWeight),
			TextColor3 = theme and theme.PrimaryTextColor,
			LinkColor3 = theme and theme.AccentColor,
			TextTransparency = customTextTransparency or ((theme and theme.PrimaryTextTransparency) or 0.45),
			TextThemeKey = "PrimaryTextColor",
			LinkThemeKey = "AccentColor",
			TransparencyThemeKey = customTextTransparency == nil and "PrimaryTextTransparency" or nil,
			OnAction = function(action, target, linkLabel)
				if not window then
					return
				end
				if action == "copy" then
					window:CopyToClipboard(target or linkLabel, linkLabel)
				elseif action == "page" then
					window:NavigateTo(target or linkLabel)
				end
			end,
		})
	end

	self.Container = container
	self.Corner = corner
	self.Stroke = stroke
	self.Padding = padding
	self.Label = label
	self._showContainer = showContainer
	self._showStroke = showStroke
	self._fontWeight = fontWeight
	self._hasCustomTextTransparency = (customTextTransparency ~= nil)
	local bgTransBinding =
		ThemeManager.BindTransparency(container, "BackgroundTransparency", "ComponentBackgroundTransparency")
	ThemeManager.BindColor(container, "BackgroundColor3", "ComponentBackgroundColor")
	ThemeManager.BindColor(stroke, "Color", "StrokeColor")
	ThemeManager.BindColor(label, "TextColor3", "PrimaryTextColor")
	local textTransBinding = ThemeManager.BindTransparency(label, "TextTransparency", "PrimaryTextTransparency")
	local strokeTransBinding = ThemeManager.BindTransparency(stroke, "Transparency", "StrokeTransparency")
	-- Disable bindings whose condition fails and set the value directly.
	if not showContainer then
		bgTransBinding:SetEnabled(false)
		container:SetAttribute(UUID.Static("ThemeOverride_BackgroundTransparency"), 1)
		container.BackgroundTransparency = 1
	end
	if not showStroke then
		strokeTransBinding:SetEnabled(false)
		stroke:SetAttribute(UUID.Static("ThemeOverride_Transparency"), 1)
		stroke.Transparency = 1
	end
	if customTextTransparency ~= nil then
		textTransBinding:SetEnabled(false)
	end
	ComponentAPI.Apply(self, {
		Root = container,
		Label = label,
		Name = Settings.Text,
		OnName = hasLinks and function(_, newName)
			Locale.set(label, "Text", Hyperlinks.plain(newName))
			if renderer then
				renderer:SetText(newName)
			end
		end or nil,
		Methods = {
			SetTextTransparency = function(_, transparency)
				self._hasCustomTextTransparency = (transparency ~= nil)
				if transparency ~= nil then
					textTransBinding:SetEnabled(false)
					label.TextTransparency = transparency
				else
					textTransBinding:SetEnabled(true)
				end
				if renderer then
					renderer:SetTransparency(transparency)
				end
			end,
			SetFontWeight = function(_, weight)
				local newWeight = getFontWeight(weight)
				self._fontWeight = newWeight
				label.FontFace = Constants.Font(newWeight)
				if renderer then
					renderer:SetFont(Constants.Font(newWeight))
				end
			end,
			SetShowContainer = function(_, show)
				self._showContainer = show
				if show then
					container:SetAttribute(UUID.Static("ThemeOverride_BackgroundTransparency"), nil)
					bgTransBinding:SetEnabled(true)
				else
					bgTransBinding:SetEnabled(false)
					container:SetAttribute(UUID.Static("ThemeOverride_BackgroundTransparency"), 1)
					container.BackgroundTransparency = 1
				end
			end,
			SetShowStroke = function(_, show)
				self._showStroke = show
				if show then
					stroke:SetAttribute(UUID.Static("ThemeOverride_Transparency"), nil)
					strokeTransBinding:SetEnabled(true)
				else
					strokeTransBinding:SetEnabled(false)
					stroke:SetAttribute(UUID.Static("ThemeOverride_Transparency"), 1)
					stroke.Transparency = 1
				end
			end,
			Destroy = function(_self)
				-- Drop the bindings so nothing stays in the ThemeManager registry.
				ThemeManager.UnbindInstance(label)
				ThemeManager.UnbindInstance(container)
				ThemeManager.UnbindInstance(stroke)
				if container and container.Parent then
					container:Destroy()
				end
			end,
		},
	})
	return self
end
return Label
