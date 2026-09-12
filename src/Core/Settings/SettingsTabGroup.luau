--[[
	SettingsTabGroup  ·  Aetheris UI Library

	Horizontal settings tab bar inside SettingsPages. Mirrors Core/TabGroup
	mechanics: spinning-gradient back images, a SelectionStatus indicator,
	active/inactive theme keys, and per-tab content scrollers with left/right
	columns for Section support.
]]

local Tween = require("../../Utils/Tween")
local Section = require("../Section")
local FallbackImage = require("../../Constants").FallbackImage
local ThemeManager = require("../../Themes/ThemeManager")
local VideoFade = require("../../Utils/VideoFade")

local SettingsTabGroup = {}
SettingsTabGroup.__index = SettingsTabGroup

local SettingsTabHandle = {}
SettingsTabHandle.__index = SettingsTabHandle

function SettingsTabHandle:Section(Settings)
	Settings = Settings or {}
	return Section.new(self.Page, Settings, self._theme)
end

function SettingsTabGroup.new(window, theme)
	theme = ThemeManager.GetTheme(theme)
	local self = setmetatable({}, SettingsTabGroup)
	self.Window = window
	self._theme = theme or {}
	self.Tabs = {}
	self.ActiveTab = nil
	self._fadeCaches = {}
	self._transitioning = false
	self._spinHandles = {}

	-- Horizontal tab bar at the top of SettingsPages
	self.Bar = Instance.new("Frame")
	self.Bar.Name = "SettingsTabBar"
	self.Bar.BorderSizePixel = 0
	self.Bar.BackgroundTransparency = 1
	self.Bar.Size = UDim2.new(1, 0, 0.07969, 0)
	self.Bar.Position = UDim2.new(0, 0, 0, 0)
	self.Bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	self.Bar.Parent = window.SettingsPages

	local BarLayout = Instance.new("UIListLayout")
	BarLayout.Padding = UDim.new(0, 12)
	BarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	BarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	BarLayout.FillDirection = Enum.FillDirection.Horizontal
	BarLayout.Parent = self.Bar

	local BarPadding = Instance.new("UIPadding")
	BarPadding.PaddingLeft = UDim.new(0, 7)
	BarPadding.Parent = self.Bar

	-- Content container below the tab bar
	self.Content = Instance.new("Frame")
	self.Content.Name = "SettingsContent"
	self.Content.BorderSizePixel = 0
	self.Content.BackgroundTransparency = 1
	self.Content.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Content.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.Content.Size = UDim2.new(0.983, 0, 1, 0)
	self.Content.BorderColor3 = Color3.fromRGB(0, 0, 0)
	self.Content.Parent = window.SettingsPages

	-- Register with ThemeManager (root = the tab bar) so this group's tab
	-- buttons, labels, icons, indicators and backdrops are themed without
	-- name-matching. The bar lives under window.Base.
	ThemeManager.Register(self.Bar, self)

	return self
end

-- Snapshot every element's base transparencies. This is only valid while
-- the page is in its NATURAL (un-faded) state, so it is captured fresh each
-- time the page is natural -- pages whose content is added after creation
-- (e.g. the Themes page) are then captured fully instead of as empty.
function SettingsTabGroup:_captureCache(tab)
	local cache = {}
	local function scan(instance)
		-- Video fade handle (UIGradient tagged by the Video component).
		if instance:IsA("UIGradient") and instance:GetAttribute("IsVideoFade") then
			table.insert(cache, {instance = instance, isVideo = true, base = VideoFade.get(instance)})
			return
		end
		local props = {}
		local function addProp(propName)
			local success, value = pcall(function() return instance[propName] end)
			if success and value ~= nil then
				table.insert(props, {propName, value})
			end
		end
		if instance:IsA("GuiObject") then
			addProp("BackgroundTransparency")
			addProp("TextTransparency")
			addProp("ImageTransparency")
		end
		if instance:IsA("UIStroke") or instance:IsA("UIShadow") then
			addProp("Transparency")
		end
		if #props > 0 then
			table.insert(cache, {instance = instance, props = props})
		end
		for _, child in ipairs(instance:GetChildren()) do
			scan(child)
		end
	end
	scan(tab.Page)
	return cache
end

-- Return a valid base cache for the tab. If the page is currently natural
-- (not faded), re-capture it so it stays fresh; otherwise reuse the stored
-- cache captured before the page was faded out.
function SettingsTabGroup:_getFadeCache(tab)
	if not tab._faded then
		tab._cache = self:_captureCache(tab)
	end
	return tab._cache or {}
end

-- Fade every element in a cache toward a target transparency.
--   targetTransparency == nil  -> fade back to each element's captured base
--   instant == true            -> set immediately (no tween)
function SettingsTabGroup:_fadeElements(cache, targetTransparency, callback, instant)
	if not cache or #cache == 0 then
		if callback then callback() end
		return
	end
	local total = 0
	local completed = 0
	local function onComplete()
		completed = completed + 1
		if completed >= total and callback then
			callback()
		end
	end
	for _, entry in ipairs(cache) do
		local instance = entry.instance
		if entry.isVideo then
			if instance.Parent then
				local target = targetTransparency
				if target == nil then target = entry.base end
				if instant then
					VideoFade.set(instance, target)
				else
					total = total + 1
					VideoFade.fade(instance, target, 0.2, "Out", onComplete)
				end
			end
		elseif instance.Parent then
			for _, propInfo in ipairs(entry.props) do
				local prop = propInfo[1]
				local base = propInfo[2]
				local target = targetTransparency
				if target == nil then
					target = base
				end
				if instant then
					instance[prop] = target
				elseif instance[prop] ~= target then
					total = total + 1
					local handle = Tween.Play(instance, "Fast", {[prop] = target})
					handle.Tween.Completed:Connect(onComplete)
				end
			end
		end
	end
	if total == 0 and callback then
		callback()
	end
end

-- Settings-tab backdrop spins route through the CENTRAL spin system
-- (Tween.StartSpin) so the global Tween.SetSpinsEnabled toggle controls them.
function SettingsTabGroup:_pauseSpin(gradient)
	Tween.StopSpin(gradient)
end

function SettingsTabGroup:_resumeSpin(gradient, reset)
	-- StartSpin handles the disabled case (registers + resets, no tween), so a
	-- later Tween.SetSpinsEnabled(true) restarts the active tab too.
	Tween.StartSpin(gradient, { Rotation = 360 }, "SpinIdle")
end

function SettingsTabGroup:Tab(Settings)
	Settings = Settings or {}
	local name = Settings.Name or "Settings"
	local isFirst = #self.Tabs == 0
	local theme = self._theme or {}

	-- Tab button
	local Button = Instance.new("TextButton")
	Button.Name = name .. "SettingsTab"
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.BackgroundColor3 = theme.InactiveTabButtonColor
	Button.BackgroundTransparency = theme.InactiveTabButtonTransparency
	Button.Size = UDim2.new(0.169, 0, 0.83, 0)
	Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Button.Text = ""
	Button.LayoutOrder = #self.Tabs + 1
	Button.Parent = self.Bar

	local ButtonCorner = Instance.new("UICorner")
	ButtonCorner.CornerRadius = UDim.new(0, 4)
	ButtonCorner.Parent = Button

	local TabName = Instance.new("TextLabel")
	TabName.Name = "TabName"
	TabName.BorderSizePixel = 0
	TabName.TextSize = 11
	TabName.TextXAlignment = Enum.TextXAlignment.Left
	TabName.TextTransparency = theme.InactiveTabTextTransparency
	TabName.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	TabName.TextColor3 = theme.InactiveTabTextColor
	TabName.BackgroundTransparency = 1
	TabName.AnchorPoint = Vector2.new(0.5, 0.5)
	TabName.Size = UDim2.new(0.73078, 0, 0.71359, 0)
	TabName.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabName.Text = name
	TabName.Position = UDim2.new(0.647, 0, 0.5, 0)
	TabName.Parent = Button

	local BackImage = Instance.new("ImageLabel")
	BackImage.Name = "BackImage"
	BackImage.BorderSizePixel = 0
	BackImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BackImage.ImageTransparency = 1
	BackImage.AnchorPoint = Vector2.new(0.5, 0.5)
	BackImage.Image = theme.Wallpaper or FallbackImage
	BackImage.Size = UDim2.new(1, 0, 1, 0)
	BackImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	BackImage.BackgroundTransparency = 1
	BackImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	BackImage.Parent = Button
	BackImage:SetAttribute("IsTabBackdrop", true)
	BackImage.Visible = theme.WallpaperEnabled

	local BackImageCorner = Instance.new("UICorner")
	BackImageCorner.CornerRadius = UDim.new(0, 4)
	BackImageCorner.Parent = BackImage

	local BackImageGradient = Instance.new("UIGradient")
	BackImageGradient.Rotation = 0
	BackImageGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.000, 0),
		NumberSequenceKeypoint.new(0.134, 0.3),
		NumberSequenceKeypoint.new(0.242, 0.53125),
		NumberSequenceKeypoint.new(0.371, 0.69375),
		NumberSequenceKeypoint.new(0.484, 0.80625),
		NumberSequenceKeypoint.new(0.590, 0.91875),
		NumberSequenceKeypoint.new(0.681, 0.975),
		NumberSequenceKeypoint.new(1.000, 1),
	})
	BackImageGradient.Parent = BackImage

	local TabImage = Instance.new("ImageLabel")
	TabImage.Name = "TabImage"
	TabImage.BorderSizePixel = 0
	TabImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabImage.ImageTransparency = theme.InactiveTabIconTransparency
	TabImage.AnchorPoint = Vector2.new(0, 0.5)
	TabImage.Image = Settings.Icon or "rbxassetid://8445470392"
	TabImage.ImageColor3 = theme.InactiveTabIconColor
	TabImage.Size = UDim2.new(0, 12, 0, 12)
	TabImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabImage.BackgroundTransparency = 1
	TabImage.Position = UDim2.new(0, 6, 0.5, 0)
	TabImage.Parent = Button

	local SelectionStatus = Instance.new("Frame")
	SelectionStatus.Name = "SelectionStatus"
	SelectionStatus.BorderSizePixel = 0
	SelectionStatus.BackgroundColor3 = theme.SecondaryColor
	SelectionStatus.BackgroundTransparency = 1
	SelectionStatus.AnchorPoint = Vector2.new(0.5, 0.5)
	SelectionStatus.Size = UDim2.new(0, 2, 0, 0)
	SelectionStatus.Position = UDim2.new(0, -5, 0.5, 0)
	SelectionStatus.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SelectionStatus.Parent = Button

	-- Simple page frame for this settings page (no automatic scroller)
	local Page = Instance.new("Frame")
	Page.Name = name
	Page.BorderSizePixel = 0
	Page.BackgroundTransparency = 1
	Page.Size = UDim2.new(1, 0, 1, 0)
	Page.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Page.Visible = false
	Page.Parent = self.Content

	local tab = setmetatable({
		Name = name,
		Button = Button,
		TabName = TabName,
		BackImage = BackImage,
		BackImageGradient = BackImageGradient,
		TabImage = TabImage,
		SelectionStatus = SelectionStatus,
		Page = Page,
		_theme = theme,
	}, SettingsTabHandle)

	Button.MouseButton1Click:Connect(function()
		self:SetActiveTab(tab)
	end)

	table.insert(self.Tabs, tab)

	if Settings.Active or isFirst then
		self:SetActiveTab(tab)
	end

	return tab
end

function SettingsTabGroup:_applyActiveVisuals(t)
	local theme = self._theme or {}
	Tween.Play(t.Button, "Fast", { BackgroundColor3 = theme.ActiveTabButtonColor, BackgroundTransparency = theme.ActiveTabButtonTransparency })
	Tween.Play(t.TabName, "Fast", { TextTransparency = theme.ActiveTabTextTransparency or 0.2, TextColor3 = theme.ActiveTabTextColor or Color3.fromRGB(255, 255, 255) })
	t.BackImage.Visible = theme.WallpaperEnabled
	Tween.Play(t.BackImage, "Fast", { ImageTransparency = 0 })
	Tween.Play(t.TabImage, "Fast", { ImageTransparency = theme.ActiveTabIconTransparency or 0.2, ImageColor3 = theme.ActiveTabIconColor or Color3.fromRGB(255, 255, 255) })
	Tween.Play(t.SelectionStatus, "OnOff", { BackgroundTransparency = 0, Size = UDim2.new(0, 2, 0.7, 0) })
	self:_resumeSpin(t.BackImageGradient)
end

function SettingsTabGroup:_applyInactiveVisuals(t)
	local theme = self._theme or {}
	Tween.Play(t.Button, "Fast", { BackgroundColor3 = theme.InactiveTabButtonColor, BackgroundTransparency = theme.InactiveTabButtonTransparency })
	Tween.Play(t.TabName, "Fast", { TextTransparency = theme.InactiveTabTextTransparency or 0.6, TextColor3 = theme.InactiveTabTextColor or Color3.fromRGB(200, 200, 200) })
	Tween.Play(t.BackImage, "Fast", { ImageTransparency = 1 })
	Tween.Play(t.TabImage, "Fast", { ImageTransparency = theme.InactiveTabIconTransparency or 0.6, ImageColor3 = theme.InactiveTabIconColor or Color3.fromRGB(200, 200, 200) })
	Tween.Play(t.SelectionStatus, "OnOff", { BackgroundTransparency = 1, Size = UDim2.new(0, 2, 0, 0) })
	self:_pauseSpin(t.BackImageGradient)
end

-- Update Window.PageTitle to "Settings | <page>" for the active page.
function SettingsTabGroup:RefreshTitle()
	local w = self.Window
	if not w or not w.PageTitle then return end
	local name = self.ActiveTab and self.ActiveTab.Name or "Settings"
	-- "Settings | " is Medium (weight 500); the page name stays Regular.
	w.PageTitle.Text = '<font weight="500">Settings | </font>' .. name
end

function SettingsTabGroup:SetActiveTab(tab)
	local previous = self.ActiveTab
	if previous == tab then
		return
	end
	self.ActiveTab = tab
	self:RefreshTitle()

	if previous == nil then
		-- First activation: capture bases while natural, reveal hidden, fade in.
		local cache = self:_getFadeCache(tab)
		tab._faded = true
		tab.Page.Visible = true
		self:_fadeElements(cache, 1, nil, true)
		self:_applyActiveVisuals(tab)
		self:_resumeSpin(tab.BackImageGradient, true)
		self:_fadeElements(cache, nil, function()
			tab._faded = false
		end, false)
		return
	end

	-- Tab-button visuals swap immediately so selection feels responsive.
	self:_applyInactiveVisuals(previous)
	self:_applyActiveVisuals(tab)

	-- Capture the incoming page's bases (it is natural), then hide it.
	local newCache = self:_getFadeCache(tab)
	self:_fadeElements(newCache, 1, nil, true)

	-- Fade the outgoing page fully out, THEN hide it and reveal/fade the new one.
	local prevCache = previous._cache or {}
	self:_fadeElements(prevCache, 1, function()
		previous.Page.Visible = false
		-- Previous is hidden/faded now: keep _faded true so its stored cache
		-- (captured while natural) is reused instead of re-snapshotting from
		-- this faded state.
		previous._faded = true
		tab.Page.Visible = true
		tab._faded = true
		self:_fadeElements(newCache, nil, function()
			tab._faded = false
		end, false)
	end, false)
end

-- Called by ThemeManager after a blanket CancelAll (theme switches cancel
-- every tween, including in-flight page fades). Restores the active page to
-- its natural state so nothing is left stuck transparent.
function SettingsTabGroup:RestoreActivePage()
	local tab = self.ActiveTab
	if not tab then return end
	for _, other in ipairs(self.Tabs) do
		if other ~= tab then
			other.Page.Visible = false
		end
	end
	local cache = self:_getFadeCache(tab)
	tab.Page.Visible = true
	self:_fadeElements(cache, nil, nil, true)
	tab._faded = false
	self:RefreshTitle()
end

function SettingsTabGroup:SetActiveTabByName(name)
	for _, tab in ipairs(self.Tabs) do
		if tab.Name == name then
			self:SetActiveTab(tab)
			return tab
		end
	end
	return nil
end

-- Component-owned theming. Called by ThemeManager via the component registry.
-- Applies the tab-bar colors directly (no animation) so the surrounding color
-- crossfade still produces the old -> new fade.
function SettingsTabGroup:ApplyTheme(newTheme)
	local theme = ThemeManager.GetTheme(newTheme)
	self._theme = theme
	for _, t in ipairs(self.Tabs) do
		t._theme = theme
		local isActive = (t == self.ActiveTab)
		if isActive then
			t.Button.BackgroundColor3 = theme.ActiveTabButtonColor or t.Button.BackgroundColor3
			if theme.ActiveTabButtonTransparency ~= nil then
				t.Button.BackgroundTransparency = theme.ActiveTabButtonTransparency
			end
			t.TabName.TextColor3 = theme.ActiveTabTextColor or t.TabName.TextColor3
			if theme.ActiveTabTextTransparency ~= nil then
				t.TabName.TextTransparency = theme.ActiveTabTextTransparency
			end
			t.TabImage.ImageColor3 = theme.ActiveTabIconColor or t.TabImage.ImageColor3
			if theme.ActiveTabIconTransparency ~= nil then
				t.TabImage.ImageTransparency = theme.ActiveTabIconTransparency
			end
		else
			t.Button.BackgroundColor3 = theme.InactiveTabButtonColor or t.Button.BackgroundColor3
			if theme.InactiveTabButtonTransparency ~= nil then
				t.Button.BackgroundTransparency = theme.InactiveTabButtonTransparency
			end
			t.TabName.TextColor3 = theme.InactiveTabTextColor or t.TabName.TextColor3
			if theme.InactiveTabTextTransparency ~= nil then
				t.TabName.TextTransparency = theme.InactiveTabTextTransparency
			end
			t.TabImage.ImageColor3 = theme.InactiveTabIconColor or t.TabImage.ImageColor3
			if theme.InactiveTabIconTransparency ~= nil then
				t.TabImage.ImageTransparency = theme.InactiveTabIconTransparency
			end
		end
		t.SelectionStatus.BackgroundColor3 = theme.SecondaryColor or t.SelectionStatus.BackgroundColor3
		t.BackImage.Image = theme.Wallpaper or FallbackImage
		t.BackImage.Visible = theme.WallpaperEnabled ~= false
	end
end

return SettingsTabGroup