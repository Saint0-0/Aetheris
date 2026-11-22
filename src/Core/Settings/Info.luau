--[[
	Aetheris/Core/Settings/Info.luau

	Default Info page: what the library is, where to find it and who made it.
	Links use the inline {label:action} syntax, so page links navigate and
	copy links write to the clipboard with a confirmation toast.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UIChangelog = require("../UIChangelog")
local UUID = require("../../Utils/UUID")

local Info = {}

local REPOSITORY = "https://github.com/Saint0-0/Aetheris"
local PROFILE = "https://github.com/Saint0-0"
local DISCORD = "https://dsc.gg/saintx"

function Info.Build(window, tab)
	local page = tab.Page

	page.Name = UUID.Static("Info")
	page.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	page.BackgroundTransparency = 1
	page.AnchorPoint = Vector2.new(0, 0)
	page.Size = UDim2.fromScale(1, 1)
	page.Position = UDim2.fromScale(0, 0)
	page.LayoutOrder = 1

	tab:Scroller()

	local about = tab:Section({ Name = "About" })
	about:Paragraph({
		Title = "Aetheris",
		Description = "Aetheris is a UI library for Roblox with a clean, modern look inspired by WinUI3, maclib, rayfield, and Fluent. "
			.. "Every component is built at runtime, and every theme repaints live.\n\n"
			.. "Visit {the GitHub repository:copy:"
			.. REPOSITORY
			.. "} or {copy the Discord invite:copy:"
			.. DISCORD
			.. "}. Created by {Saint0-0:copy:"
			.. PROFILE
			.. "}.",
	})

	about:Label({
		Text = "Jump to {UI Settings:UI Settings}, {Themes:Themes} or {Configs:Configs} from here.",
		ShowContainer = false,
		ShowStroke = false,
		TextSize = 12,
		Padding = { Top = 0, Bottom = 2, Left = 0, Right = 0 },
	})

	local links = tab:Section({ Name = "Links" })
	links:Button({
		Name = "Copy GitHub Link",
		Callback = function()
			window:CopyToClipboard(REPOSITORY, "GitHub repository")
		end,
	})
	links:Button({
		Name = "Copy Creator Profile",
		Callback = function()
			window:CopyToClipboard(PROFILE, "Creator profile")
		end,
	})
	links:Button({
		Name = "Copy Discord Invite",
		Callback = function()
			window:CopyToClipboard(DISCORD, "Discord invite")
		end,
	})
	links:Button({
		Name = "Aetheris Changelog",
		Callback = function()
			if window.AetherisChangelog then
				window.AetherisChangelog:Show()
			end
		end,
	})

	local version = tab:Section({ Name = "Version" })
	version:Label({
		Text = "Aetheris " .. (UIChangelog.Version or "development") .. " - MPL-2.0.",
		ShowContainer = false,
		ShowStroke = false,
		TextSize = 12,
		Padding = { Top = 0, Bottom = 2, Left = 0, Right = 0 },
	})
end

return Info
