RubyStuffSocial = LibStub("AceAddon-3.0"):NewAddon("RubyStuffSocial", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

BINDING_HEADER_RubyStuffSocial = "RubyStuff Social"
BINDING_NAME_RubyStuff_SocialManager_Toggle = "Toggle RubyStuff Social List"

local NAME_DATABASE = {}

function RubyStuffSocial:OnInitialize()
	self:Print("Loading...")
	RubyStuffSocial:RegisterEvent("GUILD_ROSTER_UPDATE", "UpdateGuild")
	RubyStuffSocial:RegisterEvent("FRIENDLIST_UPDATE", "UpdateFriendList")
	self:SetupFrame()
end

function RubyStuffSocial:GetPlayerNote(player)
  if CustomPlayerNotes[player] then
    return CustomPlayerNotes[player]
  end
  if NAME_DATABASE[player] then
    return NAME_DATABASE[player]['guild_note']
  end
  return nil
end

function RubyStuffSocial:Make(name)
	return {
		['name']=name,
		['guild_note']='',
		['class']='',
		['level']='',
		['online']=-1,
		['rank']='',
		['offlineString']='Offline',
		['location']=''
	}
end

function RubyStuffSocial:PrepopulateDatabase()
	if not CustomPlayerNotes then
		CustomPlayerNotes = {}
	end
	for k, v in pairs(CustomPlayerNotes) do
	    self:EnsurePlayerExists(k)
	end
end

function RubyStuffSocial:EnsurePlayerExists(player, note)
  if not NAME_DATABASE[player] then
	  NAME_DATABASE[player] = self:Make(player)
  end
end

function RubyStuffSocial:SetCustomPlayerNote(player, note)
	self:EnsurePlayerExists(player)
	if note == "" then
	   note = nil
	end
	CustomPlayerNotes[player] = note
end

function RubyStuffSocial:UpdateNameEntry(Name, Level, Class, Zone, Online, AvailableValue, Status, Note, Rank, offlineString)
  self:EnsurePlayerExists(Name)
  if Note then
    NAME_DATABASE[Name]['guild_note'] = Note
  end
  if Level > 0 then
	  NAME_DATABASE[Name]['class'] = Class
	  NAME_DATABASE[Name]['level'] = Level
	  NAME_DATABASE[Name]['location'] = Zone
  end
  if Rank then
	  NAME_DATABASE[Name]['rank'] = Rank
  end
  if offlineString then
	  NAME_DATABASE[Name]['offlineString'] = offlineString
  end
  -- dumb blizzard
  if Online then
    if Status == "<Away>" then
		NAME_DATABASE[Name]['online'] = 1
	else
		if Status == "<Busy>" then
			NAME_DATABASE[Name]['online'] = 2
		else
			NAME_DATABASE[Name]['online'] = AvailableValue
		end
	end	
  else
	NAME_DATABASE[Name]['online'] = 0
  end
end

function RubyStuffSocial:UpdateFriendList()
    for i = 1, GetNumFriends() do
        Name, Level, Class, Zone, Connected, Status = GetFriendInfo(i)  -- name, level, class, area, connected, status
		self:UpdateNameEntry(Name, Level, Class, Zone, Connected, 3, Status, '', nil, nil)
    end
end

function RubyStuffSocial:UpdateGuild()
  if IsInGuild() then
    -- hardcode things
	RubyStuffSocial:PrepopulateDatabase()
	--self:Print("Updating Guild")
    GuildRoster()
    local Name, Rank, Note, _
    for i = 1, GetNumGuildMembers(true) do
	  --self:Print(GetGuildRosterInfo(i))
      Name, Rank, RankIndex, Level, Class, Zone, Note, OfficerNote, Online, Status, ClassFileName = GetGuildRosterInfo(i)
	  yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)
	  offlineString = ""
	  if yearsOffline and yearsOffline > 0 then
		offlineString = offlineString .. yearsOffline .. "y "
	  end
	  if monthsOffline and monthsOffline > 0 then
		offlineString = offlineString .. monthsOffline .. "m "
	  end
	  if daysOffline and daysOffline > 0 then
		offlineString = offlineString .. daysOffline .. "d "
	  end
	  if hoursOffline and hoursOffline > 0 then
		offlineString = offlineString .. hoursOffline .. "h "
	  end
	  if offlineString == "" then
	    offlineString = "< 1 hr"
	  end
	  self:UpdateNameEntry(Name, Level, Class, Zone, Online, 4, Status, Note, Rank, offlineString)
    end
  end
end

Prat:AddModuleToLoad(function()
	local PRAT_MODULE = Prat:RequestModuleName("RubyStuffSocial")

	if PRAT_MODULE == nil then 
		return 
	end

	local module = Prat:NewModule(PRAT_MODULE, "AceEvent-3.0")

	function module:OnModuleEnable()
		RubyStuffSocial:Print("Successfully loaded. WOOP <3")
		-- register events
		Prat.RegisterChatEvent(self, "Prat_PreAddMessage")
		Prat.RegisterMessageItem('RUBYSTUFF', 'Pp')
	end

	function module:OnModuleDisable()
		--RubyStuffSocial:Print("OnModuleDisable")
	end
	
	function module:Prat_PreAddMessage(e, message, frame, event)
		databasedName = RubyStuffSocial:GetPlayerNote(message.PLAYERLINK)
		if databasedName and (not (databasedName == message.PLAYERLINK or databasedName == "")) then
		  message.RUBYSTUFF = Prat.CLR:Colorize('ffefa3', string.format(' (%s)', databasedName))
		end
	end
end) -- Prat:AddModuleToLoad

local managerFrame = CreateFrame("Frame", "RubyStuffSocialManager_Frame", UIParent)

function RubyStuffSocial:SetupFrame()
	RubyStuffSocial:Print("Setting up frame")
	managerFrame:Hide()
	tinsert(UISpecialFrames, "RubyStuffSocialManager_Frame")
	-- Base frame
	managerFrame:SetPoint("TOPLEFT",UIParent,"CENTER",-440,200)
	managerFrame:SetPoint("BOTTOMRIGHT",UIParent,"CENTER",440,-200)
	managerFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 32, edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }});
	managerFrame:EnableMouse(1)
	managerFrame:RegisterForDrag("LeftButton", "RightButton")
	managerFrame:SetScript("OnShow", RubyStuffSocialManager_OnFrameShow)
	managerFrame:SetScript("OnHide", RubyStuffSocialManager_OnFrameHide)
	-- Title
	managerFrame.title = managerFrame:CreateFontString(nil, "ARTWORK", "GameTooltipText")
	managerFrame.title:SetPoint("TOPLEFT", 8, -10)
	managerFrame.title:SetText("Social List")
	-- Line
	managerFrame.line = managerFrame:CreateTexture()
	managerFrame.line:SetTexture(.8, .8, .8, .8)
	managerFrame.line:SetPoint("TOPLEFT",4,-30)
	managerFrame.line:SetSize(872, 1)
	-- Exit button
	local exitButton = CreateFrame("Button", "RubyStuffSocialManager_ExitButton", managerFrame, "UIPanelButtonTemplate")
	exitButton:SetSize(40, 24) -- width, height
	exitButton:SetText("X")
	exitButton:SetPoint("TOPRIGHT", managerFrame, "TOPRIGHT", -4, -4)
	exitButton:SetScript("OnClick", function() managerFrame:Hide() end)
	-- Scroll frame
	managerFrame.scrollFrame = CreateFrame("ScrollFrame", "RubyStuffSocialManager_ScrollFrame", managerFrame, "UIPanelScrollFrameTemplate")
	managerFrame.scrollChild = CreateFrame("Frame")
	-- Create scroll bar elements
	local scrollbarName = managerFrame.scrollFrame:GetName()
	managerFrame.scrollbar = _G[scrollbarName.."ScrollBar"];
	managerFrame.scrollbar:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
		})
	managerFrame.scrollupbutton = _G[scrollbarName.."ScrollBarScrollUpButton"];
	managerFrame.scrolldownbutton = _G[scrollbarName.."ScrollBarScrollDownButton"];
	managerFrame.scrollupbutton:ClearAllPoints();
	managerFrame.scrollupbutton:SetPoint("TOPRIGHT", managerFrame.scrollFrame, "TOPRIGHT", 0, 0);
	managerFrame.scrolldownbutton:ClearAllPoints();
	managerFrame.scrolldownbutton:SetPoint("BOTTOMRIGHT", managerFrame.scrollFrame, "BOTTOMRIGHT", 0, 0);
	managerFrame.scrollbar:ClearAllPoints();
	managerFrame.scrollbar:SetPoint("TOP", managerFrame.scrollupbutton, "BOTTOM", 0, 0);
	managerFrame.scrollbar:SetPoint("BOTTOM", managerFrame.scrolldownbutton, "TOP", 0, 2);
	managerFrame.scrollFrame:SetScrollChild(managerFrame.scrollChild);
--	managerFrame.scrollFrame:SetAllPoints(managerFrame);
	managerFrame.scrollFrame:ClearAllPoints()
	managerFrame.scrollFrame:SetPoint("TOPLEFT", managerFrame, "TOPLEFT", 4, -34);
	managerFrame.scrollFrame:SetPoint("BOTTOMRIGHT", managerFrame, "BOTTOMRIGHT", -4, 34);
	-- Line2
	managerFrame.line2 = managerFrame:CreateTexture()
	managerFrame.line2:SetTexture(.8, .8, .8, .8)
	managerFrame.line2:SetPoint("BOTTOMLEFT",4,30)
	managerFrame.line2:SetSize(872, 1)
	-- Some buttons
	managerFrame.removeNoteButton = CreateFrame("Button", "RubyStuffSocialManager_RemoveNoteButton", managerFrame, "UIPanelButtonTemplate")
	managerFrame.removeNoteButton:SetText("Remove note")
	managerFrame.removeNoteButton:SetPoint("BOTTOMRIGHT", managerFrame, "BOTTOMRIGHT", -4, 5)
	managerFrame.removeNoteButton:SetSize(120, 24) -- width, height
	managerFrame.removeNoteButton:SetScript("OnClick", function() RubyStuffSocial:OnRemoveNoteButtonClick() end)
	managerFrame.removeNoteButton:Disable()
	managerFrame.changeNoteButton = CreateFrame("Button", "RubyStuffSocialManager_EditNoteButton", managerFrame, "UIPanelButtonTemplate")
	managerFrame.changeNoteButton:SetText("Edit note")
	managerFrame.changeNoteButton:SetPoint("BOTTOMRIGHT", managerFrame, "BOTTOMRIGHT", -128, 5)
	managerFrame.changeNoteButton:SetSize(80, 24) -- width, height
	managerFrame.changeNoteButton:SetScript("OnClick", function() RubyStuffSocial:OnEditNoteButtonClick() end)
	managerFrame.changeNoteButton:Disable()
	managerFrame:SetFrameStrata(HIGH)
end

local selectedName = nil
local nameBeingEdited = nil

function RubyStuffSocial:OnRemoveNoteButtonClick()
    if selectedName then
	  self:SetCustomPlayerNote(selectedName, nil)
	end
	self:SelectElement(selectedName)
	self:UpdateFrame()
end

function RubyStuffSocial:OnEditNoteButtonClick()
	nameBeingEdited = selectedName
	StaticPopupDialogs["RUBYSTUFF_EDIT_PLAYER_CUSTOM_NOTE"].text = "Enter a new custom note for " .. nameBeingEdited
	StaticPopup_Show("RUBYSTUFF_EDIT_PLAYER_CUSTOM_NOTE")
end

function RubyStuffSocial:UpdateNoteFromEditBox(note)
    if nameBeingEdited then
	  self:SetCustomPlayerNote(nameBeingEdited, note)
	end
	self:SelectElement(selectedName)
	self:UpdateFrame()
end

function RubyStuffSocial:Toggle()
	--RubyStuffSocial:Print("Toggling")
	if managerFrame:IsShown() then
		managerFrame:Hide()
	else
		managerFrame:Show()
	end
end

function RubyStuffSocialManager_OnFrameShow()
	--RubyStuffSocial:Print("Showing frame")
	RubyStuffSocial:SelectElement(nil)
	PlaySound("igCharacterInfoOpen")
	RubyStuffSocial:UpdateFrame()
end

function RubyStuffSocialManager_OnFrameHide()
	--RubyStuffSocial:Print("Hiding frame")
	PlaySound("igCharacterInfoClose")
end

local FRAMES = {}

local function SortTable(a, b)
	if a[2]['online'] == b[2]['online'] then
		a_note = RubyStuffSocial:GetPlayerNote(a[2]['name'])
		if not a_note then
			a_note = ""
		end
		b_note = RubyStuffSocial:GetPlayerNote(b[2]['name'])
		if not b_note then
			b_note = ""
		end
		if a_note == b_note then
			return a[1] < b[1]
		else
			if a_note == "" or b_note == "" then
				return b_note == ""
			else
				return a_note < b_note
			end
		end
	else
		return a[2]['online'] > b[2]['online']
	end
end


function RubyStuffSocial:SelectElement(name)
	selectedName = name
	if selectedName then
		if CustomPlayerNotes[selectedName] then
			managerFrame.removeNoteButton:Enable()
		else
			managerFrame.removeNoteButton:Disable()
		end
		managerFrame.changeNoteButton:Enable()
	else
		managerFrame.removeNoteButton:Disable()
		managerFrame.changeNoteButton:Disable()
	end
	self:UpdateFrame()
end

local RAID_CLASS_COLORS = {
	["Druid"] = { r = 1, g = 0.49, b = 0.04, },
	["Hunter"] = { r = 0.67, g = 0.83, b = 0.45 },
	["Mage"] = { r = 0.41, g = 0.8, b = 0.41 },
	["Paladin"] = { r = 0.96, g = 0.55, b = 0.73 },
	["Priest"] = { r = 1, g = 1, b = 1 },
	["Rogue"] = { r = 1, g = 0.96, b = 0.41 },
	["Shaman"] = { r = 0.14, g = 0.35, b = 1 },
	["Warlock"] = { r = 0.58, g = 0.51, b = 0.79 },
	["Warrior"] = { r = 0.78, g = 0.61, b = 0.43 },
	["Unknown"] = { r = 1, g = 1, b = 1 },
	[""] = { r = 1, g = 1, b = 1 },
}

function RubyStuffSocial:UpdateFrame()
	--self:Print("Updating frame")
	RubyStuffSocial:UpdateGuild()
	RubyStuffSocial:UpdateFriendList()
	-- Sort the table
	local sortedTable = {}
	for playerName, nickname in pairs(NAME_DATABASE) do
		table.insert(sortedTable, {playerName, nickname})
	end
	table.sort(sortedTable, function(a, b) return SortTable(a,b) end)
	
	local foundSelectedName = not selectedName
	local pName, pRealm = UnitName("player")
	local zone = GetZoneText()
	local line_height = 15
	-- Hide all the existing frames	
	for k, v in pairs(FRAMES) do 
		v:Hide()
	end
	-- Add element for each thing
	local elements = 0
	local i = -4
	for q=1,#sortedTable do
		k = sortedTable[q][1]
		v = sortedTable[q][2]
		if not FRAMES[k] then
			FRAMES[k] = CreateFrame("Button", nil, managerFrame.scrollChild)
			FRAMES[k].playerName = k
			FRAMES[k]:SetSize(840, line_height)
			FRAMES[k].background = FRAMES[k]:CreateTexture()
			FRAMES[k].background:SetAllPoints(FRAMES[k]);
			FRAMES[k].text_NAME = FRAMES[k]:CreateFontString(nil, "ARTWORK", "GameTooltipText")
			FRAMES[k].text_NAME:SetPoint("TOPLEFT", 2, -1)
			FRAMES[k].text_ONLINE = FRAMES[k]:CreateFontString(nil, "ARTWORK", "GameTooltipText")
			FRAMES[k].text_ONLINE:SetPoint("TOPLEFT", 100, -1)
			FRAMES[k].text_RANK = FRAMES[k]:CreateFontString(nil, "ARTWORK", "GameTooltipText")
			FRAMES[k].text_RANK:SetPoint("TOPLEFT", 210, -1)
			FRAMES[k].text_NOTE = FRAMES[k]:CreateFontString(nil, "ARTWORK", "GameTooltipText")
			FRAMES[k].text_NOTE:SetPoint("TOPLEFT", 270, -1)
			FRAMES[k].text_LEVEL = FRAMES[k]:CreateFontString(nil, "ARTWORK", "GameTooltipText")
			FRAMES[k].text_LEVEL:SetPoint("TOPLEFT", 506, -1)
			FRAMES[k].text_CLASS = FRAMES[k]:CreateFontString(nil, "ARTWORK", "GameTooltipText")
			FRAMES[k].text_CLASS:SetPoint("TOPLEFT", 550, -1)
			FRAMES[k].text_ZONE = FRAMES[k]:CreateFontString(nil, "ARTWORK", "GameTooltipText")
			FRAMES[k].text_ZONE:SetPoint("TOPLEFT", 650, -1)
			FRAMES[k]:EnableMouse(1)
			FRAMES[k].highlightTexture = FRAMES[k]:CreateTexture(nil)
			FRAMES[k].highlightTexture:SetAllPoints(true)
			FRAMES[k].highlightTexture:SetTexture(0.5, 0.5, 0.5, 0.5)
			FRAMES[k].highlightTexture:Hide()
			FRAMES[k]:SetScript("OnClick", function(self) RubyStuffSocial:SelectElement(self.playerName) end)
			FRAMES[k]:SetScript("OnEnter", function(self) self.highlightTexture:Show() end)
			FRAMES[k]:SetScript("OnLeave", function(self) self.highlightTexture:Hide() end)
		end
		if selectedName and k == selectedName then
			FRAMES[k].background:SetTexture(.56, .44, .07, 1)
			foundSelectedName = true
		else
			FRAMES[k].background:SetTexture(.5, .5, .5, 0)
		end
		if k == pName then
			FRAMES[k].text_NAME:SetTextColor(0.8, 0.8, 0, FRAMES[k].text_NAME:GetAlpha())
		else
			FRAMES[k].text_NAME:SetTextColor(1, 1, 1, FRAMES[k].text_NAME:GetAlpha())
		end
		FRAMES[k].text_NAME:SetText(k)
		if v['online'] > 0 then
			if v['online'] == 4 then
				FRAMES[k].text_ONLINE:SetText('Online')
				FRAMES[k].text_ONLINE:SetTextColor(0,1,1,1)
			end
			if v['online'] == 3 then
				FRAMES[k].text_ONLINE:SetText('Available')
				FRAMES[k].text_ONLINE:SetTextColor(0,1,0,1)
			end
			if v['online'] == 2 then
				FRAMES[k].text_ONLINE:SetText('Busy')
				FRAMES[k].text_ONLINE:SetTextColor(1,0,0,1)
			end
			if v['online'] == 1 then
				FRAMES[k].text_ONLINE:SetText('Away')
				FRAMES[k].text_ONLINE:SetTextColor(1,1,0,1)
			end
			FRAMES[k].text_NAME:SetAlpha(1)
			FRAMES[k].text_ONLINE:SetAlpha(1)
			FRAMES[k].text_NOTE:SetAlpha(1)
			FRAMES[k].text_LEVEL:SetAlpha(1)
			FRAMES[k].text_CLASS:SetAlpha(1)
			FRAMES[k].text_ZONE:SetAlpha(1)
			FRAMES[k].text_RANK:SetAlpha(1)
		else
			if v['online'] == 0 then
				FRAMES[k].text_ONLINE:SetText(v['offlineString'])
			else
				FRAMES[k].text_ONLINE:SetText('?')
			end
			FRAMES[k].text_ONLINE:SetTextColor(1,1,1,1)
			FRAMES[k].text_NAME:SetAlpha(0.3)
			FRAMES[k].text_ONLINE:SetAlpha(0.3)
			FRAMES[k].text_NOTE:SetAlpha(0.3)
			FRAMES[k].text_LEVEL:SetAlpha(0.3)
			FRAMES[k].text_CLASS:SetAlpha(0.3)
			FRAMES[k].text_ZONE:SetAlpha(0.3)
			FRAMES[k].text_RANK:SetAlpha(0.3)
		end
		if CustomPlayerNotes[k] then
			FRAMES[k].text_NOTE:SetText(CustomPlayerNotes[k])
			FRAMES[k].text_NOTE:SetTextColor(1,1,1,FRAMES[k].text_NOTE:GetAlpha())
		else
			FRAMES[k].text_NOTE:SetText(v['guild_note'])
			FRAMES[k].text_NOTE:SetTextColor(0.7,0.55,0.4,FRAMES[k].text_NOTE:GetAlpha())
		end
		FRAMES[k].text_LEVEL:SetText(v['level'])
		FRAMES[k].text_CLASS:SetText(v['class'])
		local cc = RAID_CLASS_COLORS[v['class']]
		FRAMES[k].text_CLASS:SetTextColor(cc.r, cc.g, cc.b, FRAMES[k].text_CLASS:GetAlpha())
		FRAMES[k].text_ZONE:SetText(v['location'])
		if zone == v['location'] then
			FRAMES[k].text_ZONE:SetTextColor(0, 1, 0, FRAMES[k].text_ZONE:GetAlpha())
		else
			FRAMES[k].text_ZONE:SetTextColor(1, 1, 1, FRAMES[k].text_ZONE:GetAlpha())
		end
		FRAMES[k].text_RANK:SetText(v['rank'])
		FRAMES[k]:SetPoint("TOPLEFT", 4, i)
		FRAMES[k]:Show()
		i = i - line_height
		elements = elements + 1
	end
	managerFrame.scrollChild:SetSize(managerFrame.scrollFrame:GetWidth(), 8 + (elements * line_height ));
	if not foundSelectedName then
		self:SelectElement(nil)
	end
end

StaticPopupDialogs["RUBYSTUFF_EDIT_PLAYER_CUSTOM_NOTE"] = {
	text = "Enter a new custom note",
	button1 = TEXT(ACCEPT),
	button2 = TEXT(CANCEL),
	OnAccept = function(dialog) RubyStuffSocial:UpdateNoteFromEditBox(dialog.editBox:GetText()) end,
	OnCancel = function() end,
	EditBoxOnEnterPressed = function()
		local text = getglobal(this:GetParent():GetName().."EditBox"):GetText();
		this:GetParent():Hide();
		RubyStuffSocial:UpdateNoteFromEditBox(text)
	end,
	EditBoxOnEscapePressed = function()
		this:GetParent():Hide();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	hasEditBox = 1,
	exclusive = 1
}
