----- INIT ALL VARIABLES
XckMLAdvancedLUA = {frame = nil, 
	debugging = false, 
	countdownRange = 15, 
	countdownRunning = false,
	disenchant = nil,
	ConfirmNinja = nil,
	ConfirAttrib = nil,
	PDez = nil,
	bank = nil,
	qualityListSet = "Epic",
	RollorNeed = "Roll",
	poorguy = nil,
	aq_zg_items_guy = nil,
	dropdownData = {{}},
	dropdownGroupData = {},
	srData = {},
	deDropdownFrame = XckMLAdvancedMainSettings_SelectDE,
	bankDropdownFrame = XckMLAdvancedMainSettings_SelectBank,
	poorguyDropdownFrame = XckMLAdvancedMainSettings_SelectPoorGuy,
	aq_zg_items_guyDropdownFrame = XckMLAdvancedMainSettings_Selectaq_zg_items_Guy,
	qualityListDropdownFrame = XckMLAdvancedMainSettings_SelectQualityList,
	RollorNeedDropdownFrame = XckMLAdvancedMainSettings_SelectRollOrNeed,
	CountDownTimeFrame = XckMLAdvancedMainSettings_CountdownTime,
	SRInputFrame = XckMLAdvancedMainSettings_SRInput,
	currentItemSelected= 0,
	currentItemSelectedtexture = nil,
	LootPrioText = "Start Your Engines",
	bosslootname = nil, 
	looterfaction = nil,
	faketooltip = nil,
	dropannounced = nil,
	settings_set = false, -- I actually want this local not part of the settings, so that it always pops up once
	QualityList = {
		["Poor"] = 0,
		["Common"] = 1,
		["Uncommon"] = 2,
		["Rare"] = 3,
		["Epic"] = 4,
		["Legendary"] = 5,
	},
	LOCAL_RAID_CLASS_COLORS = {
		["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473" },
		["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79, colorStr = "ff9482c9" },
		["PRIEST"] = { r = 1.0, g = 1.0, b = 1.0, colorStr = "ffffffff" },
		["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
		["MAGE"] = { r = 0.41, g = 0.8, b = 0.94, colorStr = "ff69ccf0" },
		["ROGUE"] = { r = 1.0, g = 0.96, b = 0.41, colorStr = "fffff569" },
		["DRUID"] = { r = 1.0, g = 0.49, b = 0.04, colorStr = "ffff7d0a" },
		["SHAMAN"] = { r = 0.0, g = 0.44, b = 0.87, colorStr = "ff0070de" },
		["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" },
		["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23, colorStr = "ffc41f3b" },
		["MONK"] = { r = 0.0, g = 1.00, b = 0.59, colorStr = "ff00ff96" },
	},
}

XckMLAdvancedLUASettings = {
	ascending = false,
	enforcelow = true,
	enforcehigh = false,
	ignorefixed = true,
}
MasterLootTable = { lootCount = 0, loot = {} }
MasterLootRolls = { rollCount = 0, rolls = {} }

boss_quest = {}

local rollQualities = {
	{ tag = "SR", color = "ffff0000", condition = function(max) return max > 100 end },
	{ tag = "MS", color = "ffffff00", condition = function(max) return max == 100 end },
	{ tag = "OS", color = "ff00ff00", condition = function(max) return max == 99 end },
	{ tag = "XM", color = "ff00ffff", condition = function(max) return max < 99 end },
}

----- INIT DEBUG COMMAND INGAME
SLASH_XCKMLA1, SLASH_XCKMLA2, SLASH_XCKMLA3 = "/XckMLAdvanced", "/Xckmla", "/loot"

SlashCmdList["XCKMLA"] = function(msg)
	if(XckMLAdvancedMainSettings:IsShown() == nil) then
		XckMLAdvancedMainSettings:EnableMouse(true)
		XckMLAdvancedMainSettings:Show()
	else
		XckMLAdvancedMainSettings:EnableMouse(false)
		XckMLAdvancedMainSettings:Hide()
	end
end

----- DEFAULT_CHAT_FRAME FUNCTION
function XckMLAdvancedLUA:Print(str)
	DEFAULT_CHAT_FRAME:AddMessage(str)
end

------
------ HOOKS
------

----- HOOK RELOADUI TO KEEP SETTINGS
-- SR settings are intentionally not kept between logins to keep stale data from causing issues
-- but we should keep them between reloads
local orig_ReloadUI = ReloadUI
ReloadUI = function (a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
	if XckMLAdvancedLUA then XckMLAdvancedLUA.reloading = true end
	orig_ReloadUI(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
end
-----

----- HOOK LOOTFRAME TO SEE MORE AT ONCE
LOOTFRAME_NUMBUTTONS = 10

for i=5,LOOTFRAME_NUMBUTTONS do
  local f = CreateFrame("LootButton","LootButton"..i,LootFrame,"LootButtonTemplate")
  f:SetPoint("TOP","LootButton"..i-1,"BOTTOM",0,-4)
  f.id = i
	f:Hide()
end

for i=1,LOOTFRAME_NUMBUTTONS do
  local n = "LootButton"..i
  local button = getglobal(n)
end
-----

----- HOOK LOOTFRAME TO ADD RANDOM OPTION
function ML_GroupLootDropDown_Initialize()
	GroupLootDropDown_Initialize()
	if UIDROPDOWNMENU_MENU_LEVEL == 1 and (GetNumPartyMembers() + GetNumRaidMembers() > 0) then
		local eligible_players = {}
		local size_t = 0
		if GetNumRaidMembers() > 0 then
			local raid_info = {}
			for i=1,40 do
				local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
				if name then
					raid_info[name] = { GetRaidRosterInfo(i) }
				end
			end
			for i=1,40 do
				local name = GetMasterLootCandidate(i)
				if name and raid_info and raid_info[name] then
					if raid_info[name][8] and raid_info[name][7] == GetRealZoneText() then
						table.insert(eligible_players,i)
						size_t = size_t + 1
					end
				end
			end
		else
			for i=1,5 do
				local name = GetMasterLootCandidate(i)
				if name then
					table.insert(eligible_players,i)
					size_t = size_t + 1
				end
			end
		end

		if size_t > 0 then
			local choice = eligible_players[math.random(1,size_t)]

			local function award(name,ix)
				GiveMasterLoot(LootFrame.selectedSlot, name);
				SendChatMessage(GetLootSlotLink(LootFrame.selectedSlot).." randomly awarded to "..GetMasterLootCandidate(ix), XckMLAdvancedLUA:IsInRaidOrParty())
			end

			-- Random Option
			local info = {}
			info.hasArrow = false
			info.notCheckable = true
			info.text = "Random"
			info.textHeight = 12
			info.value = choice
			info.func = function ()
				if ( LootFrame.selectedQuality >= MASTER_LOOT_THREHOLD ) then
					local orig_ConfirmLootFunc = StaticPopupDialogs["CONFIRM_LOOT_DISTRIBUTION"].OnAccept
					StaticPopupDialogs["CONFIRM_LOOT_DISTRIBUTION"].OnHide = function ()
						-- restore original accept function
						StaticPopupDialogs["CONFIRM_LOOT_DISTRIBUTION"].OnAccept = orig_ConfirmLootFunc
					end
					StaticPopupDialogs["CONFIRM_LOOT_DISTRIBUTION"].OnAccept = function (data)
						award(choice,data)
					end
					local dialog = StaticPopup_Show("CONFIRM_LOOT_DISTRIBUTION", ITEM_QUALITY_COLORS[LootFrame.selectedQuality].hex..LootFrame.selectedItemName..FONT_COLOR_CODE_CLOSE, this:GetText());
					if ( dialog ) then
						dialog.data = this.value
					end
				else
					award(choice,this.value)
				end
				CloseDropDownMenus();
			end
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end

UIDropDownMenu_Initialize(GroupLootDropDown, ML_GroupLootDropDown_Initialize, "MENU"); -- add rand option
-----

------
------ CORE EVENT TRIGGER FUNCTION
------
-- OnLoad Event
function XckMLAdvancedLUA:OnLoad(frame)
	self.frame = frame

	self.frame:RegisterEvent("LOOT_OPENED")
	self.frame:RegisterEvent("LOOT_CLOSED")
	self.frame:RegisterEvent("CHAT_MSG_SYSTEM")
	self.frame:RegisterEvent("CHAT_MSG_PARTY")
	self.frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
	self.frame:RegisterEvent("CHAT_MSG_RAID")
	self.frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
	self.frame:RegisterEvent("LOOT_SLOT_CLEARED")
	self.frame:RegisterEvent("RAID_ROSTER_UPDATE")
	self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.frame:RegisterEvent("PLAYER_LOGOUT")
	
	self.frame:SetScript("OnEvent", function()
		self:OnEvent(self, event)
	end)
	
	self.frame:RegisterForDrag("LeftButton")
	self.frame:SetClampedToScreen(true)
	
	for index = 1, 8 do
		XckMLAdvancedLUA.dropdownData[index] = {};
	end
	
	self:UpdateDropdowns()
	
	UIDropDownMenu_Initialize(self.deDropdownFrame, XckMLAdvancedLUA.InitializeDropdown);
	UIDropDownMenu_Initialize(self.bankDropdownFrame, XckMLAdvancedLUA.InitializeDropdown);
	UIDropDownMenu_Initialize(self.poorguyDropdownFrame, XckMLAdvancedLUA.InitializeDropdown);
	UIDropDownMenu_Initialize(self.aq_zg_items_guyDropdownFrame, XckMLAdvancedLUA.InitializeDropdown);
	UIDropDownMenu_Initialize(self.qualityListDropdownFrame, XckMLAdvancedLUA.InitQualityListDropDown);
	UIDropDownMenu_Initialize(self.RollorNeedDropdownFrame, XckMLAdvancedLUA.InitRollOrNeedDropDown);
	UIDropDownMenu_SetText(UnitName("player"), self.deDropdownFrame)
	UIDropDownMenu_SetText(UnitName("player"), self.bankDropdownFrame)
	UIDropDownMenu_SetText(UnitName("player"), self.poorguyDropdownFrame)
	UIDropDownMenu_SetText(UnitName("player"), self.aq_zg_items_guyDropdownFrame)
	UIDropDownMenu_SetText(self.qualityListSet, self.qualityListDropdownFrame)
	UIDropDownMenu_SetText(self.RollorNeed, self.RollorNeedDropdownFrame)
	
	self:InitButtonLootAllItems()
	self:InitAllLootFrameFrame()

	LootFrame:SetMovable(1)
	LootFrame:SetScript("OnMouseUp", function () this:StopMovingOrSizing() end)
	LootFrame:SetScript("OnMouseDown", function () this:StartMoving() end)

	AutoMasterLooter = CreateFrame("Frame","AutoMasterLooter",UIParent)
	AutoMasterLooter:RegisterEvent("LOOT_OPENED")

	self:Print("Xckbucl MasterLoot Advanced |cff20b2aaFully Loaded |cff49C0C0/loot |rto edit settings")
end

-- OnEvent Event
function XckMLAdvancedLUA:OnEvent(self, event)
	if (event == "LOOT_OPENED") then

		-- over-ride people's position customization
		LootFrame:ClearAllPoints()
		LootFrame:SetPoint("CENTER", UIParent, "CENTER", 100, 0)

		self:FillLootTable()
		self:UpdateSelectionFrame()
		self:ToggleMLLootFrameButtons()
		if (MasterLootTable.lootCount > 0 and self:PlayerIsMasterLooter()) then
			XckMLAdvancedMain:SetHeight(LootFrame:GetHeight() - 18);
			XckMLAdvancedMain:Show()
		end
		XckMLAdvancedLUA:AutoLootTrash()
	elseif (event == "LOOT_CLOSED" and self:PlayerIsMasterLooter()) then
		if(SelectFrame) then
			if(SelectFrame:IsShown() == 1) then
				SelectFrame:Hide()
			end
		end
		XckMLAdvancedMain:Hide()
		XckMLAdvancedLUA.ConfirmNinja = nil
		XckMLAdvancedLUA.ConfirAttrib = nil
	elseif (event == "LOOT_SLOT_CLEARED" and self:PlayerIsMasterLooter()) then
		self:FillLootTable()
		self:UpdateSelectionFrame()
		if (MasterLootTable.lootCount > 0) then
			XckMLAdvancedMain:Show()
		else
			XckMLAdvancedMain:Hide()
		end
	elseif (event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_SYSTEM") then
		local message, sender= arg1, arg2;
		self:HandlePossibleRoll(message, sender)
	elseif (event == "RAID_ROSTER_UPDATE") then
		self:UpdateDropdowns()
	elseif (event == "PLAYER_ENTERING_WORLD") then
		MasterLootManagerSettings = MasterLootManagerSettings or {}
		if MasterLootManagerSettings.guildmembersdb then guildmembersdb = MasterLootManagerSettings.guildmembersdb end
		if MasterLootManagerSettings.PDez then
			XckMLAdvancedLUA.PDez = MasterLootManagerSettings.PDez
			UIDropDownMenu_SetText(XckMLAdvancedLUA.PDez, XckMLAdvancedLUA.deDropdownFrame)
		end
		if MasterLootManagerSettings.bank then
			XckMLAdvancedLUA.bank = MasterLootManagerSettings.bank
			UIDropDownMenu_SetText(XckMLAdvancedLUA.bank, XckMLAdvancedLUA.bankDropdownFrame)
		end
		if MasterLootManagerSettings.poorguy then
			XckMLAdvancedLUA.poorguy = MasterLootManagerSettings.poorguy
			UIDropDownMenu_SetText(XckMLAdvancedLUA.poorguy, XckMLAdvancedLUA.poorguyDropdownFrame)
		end
		if MasterLootManagerSettings.aq_zg_items_guy then
			XckMLAdvancedLUA.aq_zg_items_guy = MasterLootManagerSettings.aq_zg_items_guy
			UIDropDownMenu_SetText(XckMLAdvancedLUA.aq_zg_items_guy, XckMLAdvancedLUA.aq_zg_items_guyDropdownFrame)
		end
		if MasterLootManagerSettings.qualityListSet then
			XckMLAdvancedLUA.qualityListSet = MasterLootManagerSettings.qualityListSet
			UIDropDownMenu_SetText(XckMLAdvancedLUA.qualityListSet, XckMLAdvancedLUA.qualityListDropdownFrame)
		end
		if MasterLootManagerSettings.RollorNeed then
			XckMLAdvancedLUA.RollorNeed = MasterLootManagerSettings.RollorNeed
			UIDropDownMenu_SetText(XckMLAdvancedLUA.RollorNeed, XckMLAdvancedLUA.RollorNeedDropdownFrame)
		end
		if MasterLootManagerSettings.countdownStartTime then
			XckMLAdvancedLUA.countdownStartTime = MasterLootManagerSettings.countdownStartTime
			XckMLAdvancedLUA.CountDownTimeFrame:SetValue(XckMLAdvancedLUA.countdownStartTime)
		end
		if MasterLootManagerSettings.looterfaction then XckMLAdvancedLUA.looterfaction = MasterLootManagerSettings.looterfaction end
		if MasterLootManagerSettings.temp_sr then
			XckMLAdvancedLUA.srData = MasterLootManagerSettings.temp_sr
			MasterLootManagerSettings.temp_sr = nil
		end

		self:UpdateDropdowns()
	elseif (event == "PLAYER_LOGOUT") then
		if not XckMLAdvancedLUA.reloading then
			MasterLootManagerSettings.temp_sr = nil
		end
		XckMLAdvancedLUA.reloading = false
	end
end

-----
-----SETTINGS FRAME FUNCTION
-----

-- storing per item: attendee,class,specialization,comment
function XckMLAdvancedLUA:GetSRData(data)
	local parsedData = Util.parseCSVData(data)
	if not parsedData then return false end
	local indexedData = {}
	for _, row in ipairs(parsedData) do
			local item = row["item"]
			-- Initialize a new entry for this item if it doesn't already exist
			if not indexedData[item] then
					indexedData[item] = {}
			end
			-- Prepare the row data with only the specified columns
			local rowData = {
					attendee = row["attendee"],
					class = row["class"],
					specialization = row["specialization"],
					comment = row["comment"]
			}

			-- Add this row's data to the item's entry
			table.insert(indexedData[item], rowData)
			-- special-case gem bags, add all colors
			local _,_, gem_sack = string.find(item,"(%w+) Sack of Gems")
			if gem_sack then
				for _,color in ipairs({ "Blue", "Green", "Gray", "Yellow","Red" }) do
					if color ~= gem_sack then
						local sacstr = color .. " Sack of Gems"
						indexedData[sacstr] = indexedData[sacstr] or {}
						table.insert(indexedData[sacstr], rowData)
					end
				end
			end

	end
	return indexedData
end


------ Save Settings
function XckMLAdvancedLUA:SaveSettings()

	local roster_offline_option = GetGuildRosterShowOffline()
	SetGuildRosterShowOffline(true)
	guildmembersdb = {}
	G_Count = GetNumGuildMembers(numTotalMembers)
    for i = 1, G_Count do
		local name,rank,_,_,class,_,_,onote = GetGuildRosterInfo(i);
		table.insert(guildmembersdb, {name=name, rank=rank, class=class, onote=onote})
	end
	SetGuildRosterShowOffline(roster_offline_option)

	XckMLAdvancedLUA.PDez = UIDropDownMenu_GetText(XckMLAdvancedLUA.deDropdownFrame)
	XckMLAdvancedLUA.bank = UIDropDownMenu_GetText(XckMLAdvancedLUA.bankDropdownFrame)
	XckMLAdvancedLUA.poorguy = UIDropDownMenu_GetText(XckMLAdvancedLUA.poorguyDropdownFrame)
	XckMLAdvancedLUA.aq_zg_items_guy = UIDropDownMenu_GetText(XckMLAdvancedLUA.aq_zg_items_guyDropdownFrame)
	XckMLAdvancedLUA.qualityListSet = UIDropDownMenu_GetText(XckMLAdvancedLUA.qualityListDropdownFrame)
	XckMLAdvancedLUA.RollorNeed = UIDropDownMenu_GetText(XckMLAdvancedLUA.RollorNeedDropdownFrame)
	XckMLAdvancedLUA.countdownStartTime = XckMLAdvancedLUA.CountDownTimeFrame:GetValue()

	local englishFaction, localizedFaction = UnitFactionGroup("player")
	XckMLAdvancedLUA.looterfaction = englishFaction

	local sr_text = XckMLAdvancedLUA.SRInputFrame:GetText()
	if sr_text ~= "" then
	  XckMLAdvancedLUA.srData = XckMLAdvancedLUA:GetSRData(sr_text) or XckMLAdvancedLUA.srData
		XckMLAdvancedLUA.SRInputFrame:SetText("")
	end
	-- Reporting:
	DEFAULT_CHAT_FRAME:AddMessage(XCKMLA_WelcomeMessage)
	DEFAULT_CHAT_FRAME:AddMessage(XCKMLA_SavedSettingsSuccessSaved)
	DEFAULT_CHAT_FRAME:AddMessage("|cff20b2aa->|r |cffffd700"..XCKMLA_SavedSettingPlayerDE..self:GetHexClassColor(XckMLAdvancedLUA.PDez) .. XckMLAdvancedLUA.PDez.."|r|cffead454")
	DEFAULT_CHAT_FRAME:AddMessage("|cff20b2aa->|r |cffffd700"..XCKMLA_SavedSettingPlayerBank..self:GetHexClassColor(XckMLAdvancedLUA.bank) .. XckMLAdvancedLUA.bank.."|r|cffead454")
	DEFAULT_CHAT_FRAME:AddMessage("|cff20b2aa->|r |cffffd700"..XCKMLA_SavedSettingPlayerPoor..self:GetHexClassColor(XckMLAdvancedLUA.poorguy) .. XckMLAdvancedLUA.poorguy.."|r|cffead454")
	DEFAULT_CHAT_FRAME:AddMessage("|cff20b2aa->|r |cffffd700"..XCKMLA_SavedSettingPlayerRaidsItems.. self:GetHexClassColor(XckMLAdvancedLUA.aq_zg_items_guy) .. XckMLAdvancedLUA.aq_zg_items_guy.."|r|cffead454")
	DEFAULT_CHAT_FRAME:AddMessage("|cff20b2aa->|r |cffffd700"..XCKMLA_SavedSettingPlayerRollOrNeed.."  |cffead454|r|cffff8362" .. XckMLAdvancedLUA.RollorNeed .. "|r|cffead454")
	DEFAULT_CHAT_FRAME:AddMessage("|cff20b2aa->|r |cffffd700"..XCKMLA_SavedSettingPlayerMinQuality.."  |cffead454|r|cffff8362" .. XckMLAdvancedLUA.qualityListSet .. "|r|cffead454")
	DEFAULT_CHAT_FRAME:AddMessage("|cff20b2aa->|r |cffffd700"..XCKMLA_SavedSettingCountdownTimer.."  |cffead454|r|cffff8362" .. XckMLAdvancedLUA.countdownStartTime .. "|r|cffead454")
	DEFAULT_CHAT_FRAME:AddMessage("|cff20b2aa->|r |cffffd700".."Guild Members found: ".."  |cffead454|r|cffff8362"..G_Count.."|r|cffead454")
	DEFAULT_CHAT_FRAME:AddMessage("|cff20b2aa->|r |cffffd700".."MasterLooter Faction: ".."  |cffead454|r|cffff8362"..XckMLAdvancedLUA.looterfaction.."|r|cffead454")

	bossquest:fakeitems(XckMLAdvancedLUA.looterfaction)
	bossquest:faketooltip()

	if not Util.isTableEmpty(XckMLAdvancedLUA.srData) then
		local t = {}
		for item,_ in XckMLAdvancedLUA.srData do table.insert(t,item) end
		DEFAULT_CHAT_FRAME:AddMessage("|cff20b2aa->|r |cffffd700".."SRs loaded for: ".. table.concat(t,", ") .."|r|cffead454")
	end

	-- save to db too
	do
		MasterLootManagerSettings.guildmembersdb = guildmembersdb
		MasterLootManagerSettings.PDez = XckMLAdvancedLUA.PDez
		MasterLootManagerSettings.bank = XckMLAdvancedLUA.bank
		MasterLootManagerSettings.poorguy = XckMLAdvancedLUA.poorguy
		MasterLootManagerSettings.aq_zg_items_guy = XckMLAdvancedLUA.aq_zg_items_guy
		MasterLootManagerSettings.qualityListSet = XckMLAdvancedLUA.qualityListSet
		MasterLootManagerSettings.RollorNeed = XckMLAdvancedLUA.RollorNeed
		MasterLootManagerSettings.countdownStartTime = XckMLAdvancedLUA.countdownStartTime
		MasterLootManagerSettings.looterfaction = XckMLAdvancedLUA.looterfaction
		MasterLootManagerSettings.temp_sr = XckMLAdvancedLUA.srData
	end

	XckMLAdvancedLUA.settings_set = true

end

-----
-----MAIN FRAME EVENT FUNCTION
-----
function XckMLAdvancedLUA:SelectionButtonClicked(buttonFrame)
	XckMLAdvancedLUA.currentItemSelected = buttonFrame:GetID()
	self:UpdateCurrentItem()
	-- link = GetLootSlotLink(XckMLAdvancedLUA.currentItemSelected)
	-- if(link == "|cff9d9d9d|Hitem:1074:0:0:0|h[Hard Spider Leg Tip]|h|r") then
	-- 	XckMLAdvancedLUA.LootPrioText = "Hard Spider Leg Tip"
	-- elseif(link == "|cffffffff|Hitem:1081:0:0:0|h[Crisp Spider Meat]|h|r") then
	-- 	XckMLAdvancedLUA.LootPrioText = "Crisp Spider Meat"
	-- else
	-- 	XckMLAdvancedLUA.LootPrioText = "Select an Item"
	-- end
	if (selectionFrame:IsShown()) then
		selectionFrame:Hide()
		else
		selectionFrame:Show()
	end

end

--Select Player in Roll List
function XckMLAdvancedLUA:PlayerSelectionButtonClicked(buttonFrame)
	local buttonName = buttonFrame:GetName()
	local playerNameLabel = getglobal(buttonName .. "_PlayerName")
	MasterLootRolls.winningPlayer = playerNameLabel:GetText()
	MasterLootRolls:UpdateRollList()
	self:Print(XCKMLA_PotentialPlayerSelected.."|cffff8362["..playerNameLabel:GetText().."]")
end

--Switch Item From LootList
function XckMLAdvancedLUA:SelectItemClicked(buttonFrame)
	if(MasterLootTable.lootCount > 1) then
		if (SelectFrame:IsShown() == nil) then
			selectionFrame:SetPoint("TOP", buttonFrame, "BOTTOM")
			selectionFrame:Show()
			else
			selectionFrame:Hide()
		end
		else
		self:Print(XCKMLA_NoLootToSwitch)
	end
end

--Call Roll for Current Item
function XckMLAdvancedLUA:AnnounceItemForNeed(buttonFrame)
	local itemLink = MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected)
	-- link = GetLootSlotLink(XckMLAdvancedLUA.currentItemSelected)
	-- lootmsg = XckMLAdvancedLUA.LootPrioText
	-- if(link == "|cff9d9d9d|Hitem:1074:0:0:0|h[Hard Spider Leg Tip]|h|r") then
	-- 	XckMLAdvancedLUA.LootPrioText = "Hard Spider Leg Tip"
	-- elseif(link == "|cffffffff|Hitem:1081:0:0:0|h[Crisp Spider Meat]|h|r") then
	-- 	XckMLAdvancedLUA.LootPrioText = "Crisp Spider Meat"	
	-- end
	-- printable = gsub(link, "\124", "\124\124");
	-- print(printable)

	if(XckMLAdvancedLUA.RollorNeed == "Need") then
		self:Speak(itemLink..XCKMLA_CallAnnounce)
		elseif(XckMLAdvancedLUA.RollorNeed == "Roll") then
			if(XckMLAdvancedLUA.LootPrioText == "LC") then
				SendChatMessage("Need LC Input: "..itemLink,"OFFICER")
			else
		self:Speak(itemLink.." "..XckMLAdvancedLUA.LootPrioText)
		end
	end
	XckMLAdvancedLUA.dropannounced = "OpenToRoll"
end


-- if (LootPrioText["LootPrio"]) then
-- 	loothog_chat_rw(LootPrioText["LootPrio"])
-- end

--Announce All Drop
function XckMLAdvancedLUA:AnnounceLootClicked(buttonFrame)
	local itemCount = MasterLootTable:GetItemCount()
	if itemCount > 0 then
		local output = "Boss Loots: "
		for itemIndex = 1, itemCount do
			local itemLink = MasterLootTable:GetItemLink(itemIndex)
			local temp_output = output .. itemLink

			-- if only two remain, print them on their own line to avoid singular prints
			if itemIndex == itemCount - 1 then
				local last_item = MasterLootTable:GetItemLink(itemCount)
				temp_output = temp_output .. last_item

				if string.len(temp_output) > 255 then -- check if msg is too long
					self:Speak(output)
					output = itemLink .. last_item
				else
					output = temp_output
				end
				break
			elseif string.len(temp_output) > 255 then -- check if msg is too long
				self:Speak(output)
				output = itemLink -- too long, add to next round
			else
				output = temp_output
			end
		end
		self:Speak(output)
		Screenshot()
	else
		self:Print(XCKMLA_NoLootToAnnounce)
	end
end

--Start CountDown 10sc
function XckMLAdvancedLUA:CountdownClicked()
	if(XckMLAdvancedLUA.dropannounced ~= "OpenToRoll") then
		self:Print(XCKMLA_NoDropAnnouncedYet)
		return
	end

	if(self.countdownRunning) then
		self.countdownRunning = false
		local itemLink = MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected)
		SendChatMessage(itemLink .. " Rolling Cancelled", 'Raid')
	else
		self.countdownRunning = true
		self.countdownStartTime = GetTime()
		self.countdownLastDisplayed = self.countdownRange + 1
	end
end

--DE Current Item
function XckMLAdvancedLUA:AssignDEClicked(buttonFrame)
	if not XckMLAdvancedLUA.PDez then
		self:Print(XCKMLA_NoPlayerDE)
		return
	end

	local disenchanter = XckMLAdvancedLUA.PDez
	if (MasterLootRolls.rollCount == 0) then
		StaticPopupDialogs["Confirm_Attrib"].text = XCKMLA_YWillGiveItem..XCKMLA_FORDE..MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected).." -> |cFFF9c31c[|r|c"..self:GetHexClassColor(disenchanter)..disenchanter.."|cFFF9c31c], |r "..XCKMLA_PressForConfirmAttribDE
	else
		self:Print(XCKMLA_WARNINGPRINT)
		StaticPopupDialogs["Confirm_Attrib"].text = XCKMLA_WARNING..XCKMLA_WARNINGDE..MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected).." -> |cFFF9c31c[|r|c"..self:GetHexClassColor(disenchanter)..disenchanter.."|cFFF9c31c], |r "..XCKMLA_PressForConfirmAttribDE..XCKMLA_WARNING
	end

	for winningPlayerIndex = 1, 40 do
		if (GetMasterLootCandidate(winningPlayerIndex)) then
			if (GetMasterLootCandidate(winningPlayerIndex) == disenchanter) then
				for itemIndex = 1, GetNumLootItems() do
					local itemLink = GetLootSlotLink(itemIndex)
					if (itemLink == MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected)) then
						local texture, name, quantity, quality, locked = GetLootSlotInfo(itemIndex)
						if (quality < MasterLootTable:GetQualityArray(XckMLAdvancedLUA.qualityListSet)) then
							SendChatMessage(itemLink .. " was sent to " .. disenchanter .. " for DE", 'Raid')
							GiveMasterLoot(itemIndex, winningPlayerIndex)
							else
								StaticPopupDialogs["Confirm_Attrib"].OnAccept = function() 
									self:Speak(XCKMLA_DEAnnounceP1.. itemLink .. ", " .. disenchanter .. " was sent item for DE")
									GiveMasterLoot(itemIndex, winningPlayerIndex)
								end
							StaticPopup_Show("Confirm_Attrib")		
						end
						MasterLootRolls:ClearRollList()
						return
					end
				end
				self:Print(XCKMLA_CANNOTFINDITEM .. MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected))
			end
		end
	end
	self:Print(XCKMLA_CANNOTFINDPLAYER .. disenchanter)
end

--Bank Current Item
function XckMLAdvancedLUA:AssignBankClicked(buttonFrame)
	if not XckMLAdvancedLUA.bank then
		self:Print(XCKMLA_NoPlayerBANK)
		return
	end

	local banker = XckMLAdvancedLUA.bank
	if MasterLootRolls.rollCount == 0 then
		StaticPopupDialogs["Confirm_Attrib"].text = XCKMLA_YWillGiveItem..XCKMLA_FORBANK..MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected).." -> |cFFF9c31c[|r|c"..self:GetHexClassColor(banker)..banker.."|cFFF9c31c], |r"..XCKMLA_PressForConfirmAttribBank
	else
		self:Print(XCKMLA_WARNINGPRINT)
		StaticPopupDialogs["Confirm_Attrib"].text = XCKMLA_WARNING..XCKMLA_WARNINGBank..MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected).." -> |cFFF9c31c[|r|c"..self:GetHexClassColor(banker)..banker.."|cFFF9c31c], |r"..XCKMLA_PressForConfirmAttribBank..XCKMLA_WARNING
	end

	for winningPlayerIndex = 1, 40 do
		if (GetMasterLootCandidate(winningPlayerIndex)) then
			if (GetMasterLootCandidate(winningPlayerIndex) == banker) then
				for itemIndex = 1, GetNumLootItems() do
					local itemLink = GetLootSlotLink(itemIndex)
					if (itemLink == MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected)) then
						local texture, name, quantity, quality, locked = GetLootSlotInfo(itemIndex)
						if (quality < MasterLootTable:GetQualityArray(XckMLAdvancedLUA.qualityListSet)) then
							SendChatMessage(itemLink .." has been sent to " .. banker .." to deposit in the guild bank", 'Raid')
							GiveMasterLoot(itemIndex, winningPlayerIndex)
						else
							StaticPopupDialogs["Confirm_Attrib"].OnAccept = function()
								self:Speak(itemLink .." has been sent to " .. banker .." to deposit in the guild bank")
								GiveMasterLoot(itemIndex, winningPlayerIndex)
							end
							StaticPopup_Show("Confirm_Attrib")
						end
						MasterLootRolls:ClearRollList()
						return
					end
				end
				self:Print(XCKMLA_CANNOTFINDITEM .. MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected))
			end
		end
	end
	self:Print(XCKMLA_CANNOTFINDPLAYER .. banker)
end

--Give Loot to Win,er
function XckMLAdvancedLUA:AwardLootClicked(buttonFrame)
	if(MasterLootRolls.winningPlayer == nil) then
		XckMLAdvancedLUA:Print(XCKMLA_SelectPlayerBeforeAttrib)
	else
		-- self:Speak(MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected)..XCKMLA_PreAttribCountdown..MasterLootRolls.winningPlayer)
		-- self:CountdownClicked()
		StaticPopupDialogs["Confirm_Attrib"].text = XCKMLA_YWillGiveItem..MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected).." -> |cFFF9c31c[|r|c"..self:GetHexClassColor(MasterLootRolls.winningPlayer)..MasterLootRolls.winningPlayer.."|cFFF9c31c], |r"..XCKMLA_PressForConfirmAttrib
		StaticPopupDialogs["Confirm_Attrib"].OnAccept = function() GiveLootToWinner() end		
		StaticPopup_Show("Confirm_Attrib")
	end
end

--Give item to Winner
function GiveLootToWinner()
	if(MasterLootRolls.winningPlayer == nil) then
		XckMLAdvancedLUA:Print(XCKMLA_SelectPlayerBeforeAttrib)
		else
		for winningPlayerIndex = 1, 40 do
			if (GetMasterLootCandidate(winningPlayerIndex)) then
				if (GetMasterLootCandidate(winningPlayerIndex) == MasterLootRolls.winningPlayer) then
					for itemIndex = 1, GetNumLootItems() do
						local itemLink = GetLootSlotLink(itemIndex)
						if (itemLink == MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected)) then
							GiveMasterLoot(itemIndex, winningPlayerIndex)
							XckMLAdvancedLUA:Speak(MasterLootRolls.winningPlayer .. " received " .. itemLink)
							MasterLootRolls:ClearRollList()
							MasterLootRolls.winningPlayer = nil
							XckMLAdvancedLUA.ConfirAttrib = nil
							XckMLAdvancedLUA.dropannounced = nil
							return
						end
					end

					for fakeitemindex = 1, MasterLootTable:GetItemCount() do
					local fakeitemlink = MasterLootTable:GetItemLink(fakeitemindex)
					if (fakeitemlink == MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected)) then
							XckMLAdvancedLUA:Speak(MasterLootRolls.winningPlayer .. " won " .. fakeitemlink .. " Please stay to the end to loot your item as I can't send it to you..")
							SendChatMessage("You won ".. fakeitemlink .. " Please stay to the end to loot your item as I can't send it to you.", "WHISPER", nil, MasterLootRolls.winningPlayer)
							MasterLootRolls:ClearRollList()
							MasterLootRolls.winningPlayer = nil
							XckMLAdvancedLUA.ConfirAttrib = nil
							XckMLAdvancedLUA.dropannounced = nil
							return
						end
					end

					XckMLAdvancedLUA:Print(XCKMLA_CANNOTFINDITEM .. MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemIndex))
				end
			-- return
			end
		end
		XckMLAdvancedLUA:Print(XCKMLA_CANNOTFINDPLAYER .. MasterLootRolls.winningPlayer)
	end
end

---- Random Player Raid
function XckMLAdvancedLUA:RandomizePlayer()
	if(getn(MasterLootRolls.rolls) > 0) then
		StaticPopupDialogs["Confirm_Attrib"].text = XCKMLA_RaidorListRoll
		StaticPopupDialogs["Confirm_Attrib"].OnAccept = function() XckMLAdvancedLUA:RandomizePlayerInList() return end		
		StaticPopup_Show("Confirm_Attrib")
		else
		
		local PlayedIDRandomized = math.random(self:GetNbPlayersRaidParty())
		MasterLootRolls:AddRoll(UnitName(self:IsInRaidOrParty()..PlayedIDRandomized), PlayedIDRandomized)
		if(self:PlayerIsInAParty() and not self:PlayerIsInARaid()) then
			self:Print(XCKMLA_RandomizerRaidOnly)
			else
			self:Speak("[Xckbucl ML Advanced] Player Randomizer --> N°"..PlayedIDRandomized.." - "..UnitName(self:IsInRaidOrParty()..PlayedIDRandomized))
		end
	end
end

---- Random Player on Rolls/Need List
function XckMLAdvancedLUA:RandomizePlayerInList()
	
	local PlayedIDRandomized = math.random(getn(MasterLootRolls.rolls))
	if(self:PlayerIsInAParty() and not self:PlayerIsInARaid()) then
		self:Print(XCKMLA_RandomizerRaidOnly)
	else
		self:Speak("[Xckbucl ML Advanced] Player Randomizer In Player List --> N°"..PlayedIDRandomized.." - "..MasterLootRolls.rolls[PlayedIDRandomized].player)
	end
end
------
------ AutoLoot FUNCTION
------
-- Check if Current Item in Queue is a RaidItem
function XckMLAdvancedLUA:CheckIsRaidItem(ItemName)
	for i = 1, getn(Raids_Items) do
		if  (Raids_Items[i] == ItemName)  then
			return true
		end
	end
	return false
end

-- Check if item is not Bind on Pickup
-- function LootSlotIsSoulbound(arg)
-- 	AMLTooltip:ClearLines()
-- 	AMLTooltip:SetLootItem(arg)
-- 	local tooltipScan = getglobal("AMLTooltipTextLeft2")
-- 	if tooltipScan then
-- 		local BindingStatus = tooltipScan:GetText()
-- 		if BindingStatus == "Binds when equipped" or BindingStatus == "Binds when picked up" then
-- 			-- XckMLAdvancedLUA:Print("BOP or BOE")
-- 			return nil
-- 		end
-- 	end
-- 	-- XckMLAdvancedLUA:Print("loot")
-- 	return true
-- end

-- AutoLoot Corpse
function XckMLAdvancedLUA:AutoLootTrash()
	self:Print(match)
	local NbPlayers = self:GetNbPlayersRaidParty()
	for li = 1, GetNumLootItems() do 
		local texture, name, quantity, quality, locked = GetLootSlotInfo(li)
		if XckMLAdvancedMainSettingsAutoLootRaidsItem:GetChecked() and XckMLAdvancedLUA:CheckIsRaidItem(name) then
			for ci = 1, NbPlayers do 
				if (GetMasterLootCandidate(ci) == XckMLAdvancedLUA.aq_zg_items_guy) then 
					GiveMasterLoot(li, ci); 
				end
			end
			
			elseif XckMLAdvancedMainSettingsAutoLootTrash:GetChecked() and quality <= 1 and not XckMLAdvancedLUA.srData[name] and not loot_prio[name] and not LootedItemsTable[name] then
			
			-- elseif XckMLAdvancedMainSettingsAutoLootTrash:GetChecked() and LootSlotIsSoulbound(li) then
			-- local match = 0	
			-- 	for key,value in LootedItemsTable do
			-- 		if (key == name) then
			-- 			match = 1
			-- 		end
			-- 	end

			-- 	if (match ~= 1) then
			for ci = 1, NbPlayers do 
				if (GetMasterLootCandidate(ci) == XckMLAdvancedLUA.poorguy) then 
					GiveMasterLoot(li, ci); 
				end
			end		
		end
	end
end

------
------ MISC FUNCTION
------
-- Get Class Color RGB
function XckMLAdvancedLUA:GetClassColor(className)
	if (RAID_CLASS_COLORS[className] == nil) then
		self:Print("No such class: " .. className)
		return 0, 0, 0
	end
	return RAID_CLASS_COLORS[className].r, RAID_CLASS_COLORS[className].g, RAID_CLASS_COLORS[className].b
end

-- Get Class Color Hex Code
function XckMLAdvancedLUA:GetHexClassColor(PlayerName)
	if (PlayerName == nil) then
		self:Print("No such class: " .. PlayerName)
		return ""
	end
	local localizedClass, englishClass = UnitClass(XckMLAdvancedLUA:GetRaidIDByName(PlayerName));
	if not localizedClass then localizedClass,englishClass = "Warrior","WARRIOR" end
	return self.LOCAL_RAID_CLASS_COLORS[englishClass].colorStr
end

-- Get Player Raid ID
function XckMLAdvancedLUA:GetRaidIDByName(PlayerName)
	local targetID = 1;
	for i = 1, self:GetNbPlayersRaidParty() do
		if UnitName(self:IsInRaidOrParty()..i) == PlayerName then
			targetID = i;
			break;
		end
	end
	return self:IsInRaidOrParty()..targetID
end

-- Get PlayerNum in Party/RAID_CLASS_COLORS
function XckMLAdvancedLUA:GetNbPlayersRaidParty()
	local PlayerNumber = "raid"
	if(XckMLAdvancedLUA:PlayerIsInAParty() and XckMLAdvancedLUA:PlayerIsInARaid() == false) then
		PlayerNumber = GetNumPartyMembers()
	elseif(XckMLAdvancedLUA:PlayerIsInARaid()) then
		PlayerNumber = GetNumRaidMembers()
	else
		return 0
	end
	return PlayerNumber
end

-- Return Player is in Raid or Party
function XckMLAdvancedLUA:IsInRaidOrParty()
	local RaidorParty = "raid"
	if(XckMLAdvancedLUA:PlayerIsInAParty() and XckMLAdvancedLUA:PlayerIsInARaid() == false) then
		RaidorParty = "party"
	elseif(XckMLAdvancedLUA:PlayerIsInARaid()) then
		RaidorParty = "raid"
	end
	return RaidorParty
end

-- Roll is Lesser Than
function MasterLootRolls:LessThan(i1, v1, i2, v2)
	if (v1 > v2) then
		return false
	elseif (v1 == v2) then
		return i1 < i2
	end
	return true
end

-- Roll is Greater Than
function MasterLootRolls:GreaterThan(i1, v1, i2, v2)
	if (v1 < v2) then
		return false
	elseif (v1 == v2) then
		return i1 > i2
	end
	return true
end

---Display/Hide ML Lootframe Buttons
function XckMLAdvancedLUA:ToggleMLLootFrameButtons()
	if (self:PlayerIsMasterLooter()) then
		BSettings:Show()
		BAnnounceDrops:Show()
		NinjaAllItems:Show()
	else
		BSettings:Hide()
		BAnnounceDrops:Hide()
		NinjaAllItems:Hide()
	end
end

-- Check if Player is MasterLooter
function XckMLAdvancedLUA:PlayerIsMasterLooter()
	local lootMethod, masterLooterPartyID, masterLooterRaidID = GetLootMethod()
	if (lootMethod ~= "master") then
		return false
	end
	
	if (masterLooterPartyID ~= 0) then
		return false
	end
	
	return true
end

------
------ ROLLS/NEEDS TRIGGER FUNCTION
------
-- Check to Intercept a Possible Roll/need
function XckMLAdvancedLUA:HandlePossibleRoll(message, sender)
	local rollPattern = XCKMLA_rollPattern
	local player, roll, minRoll, maxRoll
	if (XckMLAdvancedLUA.dropannounced ~= nil) then
		if(XckMLAdvancedLUA.RollorNeed == "Need") then
			XckMLAdvancedLUASettings.ascending = true
			if string.find(message, "+1") and not string.find(message, "||") then
				player, roll, minRoll, maxRoll = sender,"1", "1", "100"
			elseif string.find(message, "+2")  and not string.find(message, "||") then
				player, roll, minRoll, maxRoll = sender,"2", "1", "100"
			elseif string.find(message, "+3") and not string.find(message, "||") then
				player, roll, minRoll, maxRoll = sender,"3", "1", "100"
			end
		elseif(XckMLAdvancedLUA.RollorNeed == "Roll") then
			XckMLAdvancedLUASettings.ascending = false
			if (string.find(message, rollPattern)) then
				_, _, player, roll, minRoll, maxRoll = string.find(message, rollPattern)
			end
		end
		if ((minRoll == "1" or not XckMLAdvancedLUASettings.enforcelow) and
				(maxRoll == "100" or not XckMLAdvancedLUASettings.enforcehigh) and
				(minRoll ~= maxRoll or not XckMLAdvancedLUASettings.ignorefixed)) then
			MasterLootRolls:AddRoll(player, tonumber(roll), tonumber(maxRoll))
		end
		if ((minRoll == "1") and
			(maxRoll == "99") and
			(minRoll ~= maxRoll)) then
			MasterLootRolls:AddRoll(player, tonumber(roll), tonumber(maxRoll))
		end
	end
end

-- Add Roll to Array Variable
function MasterLootRolls:AddRoll(player, roll, maxRoll)
	for rollIndex = 1, self.rollCount do
		if (self.rolls[rollIndex].player == player) then
			return
		end
	end
	self.rollCount = self.rollCount + 1
	self.rolls[self.rollCount] = {}
	self.rolls[self.rollCount].player = player
	self.rolls[self.rollCount].roll = roll
	self.rolls[self.rollCount].max = maxRoll or 100

	self:UpdateTopRoll()

	self:UpdateRollList()
end

-- Update Roll to Top if Greater(Re-Organizer)
function MasterLootRolls:UpdateTopRoll()
	local highestRoll
	if (not XckMLAdvancedLUASettings.ascending) then
		highestRoll = 0
	else
		highestRoll = 1000001
	end
	for rollIndex = 1, self.rollCount do
		if ((self.rolls[rollIndex].roll > highestRoll and not XckMLAdvancedLUASettings.ascending) or
			(self.rolls[rollIndex].roll < highestRoll and XckMLAdvancedLUASettings.ascending)) then
			highestRoll = self.rolls[rollIndex].roll
			--self.winningPlayer = self.rolls[rollIndex].player  // Can be missed the attrib if player roll or +1 at the last moment
			if(XckMLAdvancedLUA.RollorNeed == "Roll") then
					XckMLAdvancedLUA:Print(XCKMLA_CHighestRoll.."|cffffd700[|r|c"..XckMLAdvancedLUA:GetHexClassColor(self.rolls[rollIndex].player)..self.rolls[rollIndex].player.."|r|cffffd700]")
			end
		end
	end
end

-- Get Player Roll Amount
function MasterLootRolls:GetPlayerRoll(rollIndex)
	return self.rolls[rollIndex].roll, self.rolls[rollIndex].max
end

-- Get Name of Player Rolled
function MasterLootRolls:GetPlayerNameRoll(rollIndex)
	return self.rolls[rollIndex].player
end

-- Clear the Roll Data/List
function MasterLootRolls:ClearRollList()
	self.rollCount = 0
	self.rolls = {}
	self.winningPlayer = nil
	local needIndex = 1
	local rollFrame = getglobal("PlayerSelectionButton" .. needIndex)
	while (rollFrame ~= nil) do
		rollFrame:Hide()
		needIndex = needIndex + 1
		rollFrame = getglobal("PlayerSelectionButton" .. needIndex)
	end
end

-- Update Roll List & Displaying
function MasterLootRolls:UpdateRollList()
	local totalHeight = 0
	local scrollFrame = getglobal("XckMLAdvancedMain_ScrollFrame")	
	local scrollChild = getglobal("XckMLAdvancedMain_ScrollFrame_ScrollChildFrame")
	
	scrollChild:SetHeight(scrollFrame:GetHeight())
	scrollChild:SetWidth(scrollFrame:GetWidth())
	
	local tiedroll = 0
	local lastRollIndex = 0
	local lastRollValue, lastRollMax
	if (not XckMLAdvancedLUASettings.ascending) then
		lastRollValue = 1000001 --max /roll is 1,000,000
		lastRollMax = 1000001
	else
		lastRollValue = 0
		lastRollMax = 0
	end

	-- Loop through all rolls to build a sorted list
	for i = 1, self.rollCount do
		local highestRollIndex = 0
		local highestRollValue, highestRollMax
		if (not ascending) then
			highestRollValue = 0
			highestRollMax = 0
		else
			highestRollValue = 1000001
			highestRollMax = 1000001
		end

		-- Iterate over all player rolls
		for rollIndex = 1, self.rollCount do
			local rollValue, rollMax = self:GetPlayerRoll(rollIndex)
			-- Only consider rolls that are "below" the previous one.
			-- For descending order, we want candidates with a lower (or equal) rollMax,
			-- and if the same rollMax, a lower rollValue than the last shown.
			if not ascending then
				if (rollMax < lastRollMax) or (rollMax == lastRollMax and rollValue < lastRollValue) then
					-- Among those, choose the candidate with the highest values.
					if (rollMax > highestRollMax) or (rollMax == highestRollMax and rollValue > highestRollValue) then
						highestRollIndex = rollIndex
						highestRollValue = rollValue
						highestRollMax = rollMax
					end
				end
			else
				-- In ascending order, reverse the comparisons.
				if (rollMax > lastRollMax) or (rollMax == lastRollMax and rollValue > lastRollValue) then
					if (rollMax < highestRollMax) or (rollMax == highestRollMax and rollValue < highestRollValue) then
						highestRollIndex = rollIndex
						highestRollValue = rollValue
						highestRollMax = rollMax
					end
				end
			end
		end

		-- If the current candidate has the same roll and same rollMax as the previous one, mark as tied.
		if lastRollValue == highestRollValue and lastRollMax == highestRollMax then
			tiedroll = 1
			tiedPlayerIndex = lastRollIndex
		else
			tiedroll = 0
		end		

		lastRollIndex = highestRollIndex
		lastRollValue = highestRollValue
		lastRollMax = highestRollMax
		
		local buttonName = "PlayerSelectionButton" .. lastRollIndex
		local rollFrame = getglobal(buttonName) or CreateFrame("Button", buttonName, scrollChild, "PlayerSelectionButtonTemplate")
		rollFrame:Show()
		
		local playerName = self:GetPlayerNameRoll(lastRollIndex)
		local playerNameLabel = getglobal(buttonName .. "_PlayerName")
		local class, classFileName = UnitClass(XckMLAdvancedLUA:GetRaidIDByName(playerName))
		local r, g, b = XckMLAdvancedLUA:GetClassColor(classFileName)
		playerNameLabel:SetText(playerName)
		playerNameLabel:SetTextColor(r, g, b)
		
		local playerRankLabel = getglobal(buttonName .. "_PlayerRank")
		local playerSpecLabel = getglobal(buttonName .. "_PlayerSpec")
		
		grank = "Guest"
		gspec = ""

		for j = 1, G_Count do 
			if(guildmembersdb[j].name == playerName) then
				for key,value in specTable do
					if string.find(guildmembersdb[j].onote, key) then 
						gspec = value
					end
				end
				grank = guildmembersdb[j].rank
			end
		end

		if(grank == "Guest") then
			playerRankLabel:SetTextColor(0, 1, 0.59)
		else
			playerRankLabel:SetTextColor(1, 1, 1)
		end

		playerRankLabel:SetText(grank)
		playerSpecLabel:SetText(gspec)

		local starTexture = getglobal(buttonName .. "_StarTexture")
		if (playerName == self.winningPlayer) then
			starTexture:Show()
		else
			starTexture:Hide()
		end

		local rollTag
		for _, rule in ipairs(rollQualities) do
			if rule.condition(highestRollMax) then
				rollTag = rule
				break
			end
		end
		local playerRoll = lastRollValue
		local playerRollLabel = getglobal(buttonName .. "_PlayerRoll")
		if(XckMLAdvancedLUA.RollorNeed == "Need") then
			playerRollLabel:SetText("+"..playerRoll)
		elseif(XckMLAdvancedLUA.RollorNeed == "Roll") then
			if tiedroll == 1 then
				playerRollLabel:SetTextColor(0, 1, 0)
				-- buttonName = "PlayerSelectionButton" .. tiedPlayerIndex
				playerRollLabel:SetText("Tie: |c" .. rollTag.color .. playerRoll .. " (" .. rollTag.tag .. ")|r")
				-- playerRollLabel = getglobal(buttonName .. "_PlayerRoll")
				-- playerRollLabel:SetText("Tie: ".. playerRoll)
				-- playerRollLabel:SetTextColor(1, 0, 0)
			else
				playerRollLabel:SetTextColor(1, 1, 1)
				playerRollLabel:SetText("|c" .. rollTag.color .. playerRoll .. " (" .. rollTag.tag .. ")|r")
			end
		end
		
		rollFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -totalHeight)
		rollFrame:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
		totalHeight = totalHeight + rollFrame:GetHeight()
	end

	local slider = getglobal("XckMLAdvancedMain_ScrollFrame_Slider")
	local maxValue = totalHeight - scrollChild:GetHeight()
	if (maxValue < 0) then
		maxValue = 0
	end
	slider:SetMinMaxValues(0, maxValue)
	slider:SetValue(0)
end

------
------ LOOT FECTHING FUNCTION
------
-- Collecting Loots on Corpse
function XckMLAdvancedLUA:FillLootTable()
	local oldLootItem
	if (MasterLootTable.lootCount > 0) then
		oldLootItem = MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected)
	end
	MasterLootTable:Clear()

	local name, realm = UnitName("Target")
	
	local cnt = 1
	-- print("count".. cnt)
	for bossName, items in pairs(boss_quest) do
		if(bossName == name) then
			-- print(name)
			if type(items) == "table" then
				for lootcount = 1, getn(items) do
				fakelink = items[lootcount]
					if(XckMLAdvancedLUA.bosslootname ~= name) then
					DEFAULT_CHAT_FRAME:AddMessage("|cff4aa832".."Quest item ".. fakelink.. "|cff4aa832".." is on this loot Target! Adding to top of loot list for roll if missing. Winner will need to manually loot from boss.")
					end
				MasterLootTable:AddItem(fakelink,cnt)
				cnt = cnt + 1
				-- print("count".. cnt)
				end
			end
			XckMLAdvancedLUA.bosslootname = name
		end
	end

	if MasterLootTable:GetItemCount() >= 1 then
		for lootIndex = 1, GetNumLootItems() do
			if (LootSlotIsItem(lootIndex)) then
				local itemLink = GetLootSlotLink(lootIndex)
				local looti = lootIndex + 1
				MasterLootTable:AddItem(itemLink, looti)
			end
		end
	else 
		for lootIndex = 1, GetNumLootItems() do
			if (LootSlotIsItem(lootIndex)) then
				local itemLink = GetLootSlotLink(lootIndex)
				MasterLootTable:AddItem(itemLink, lootIndex)
			end
		end
	end

	XckMLAdvancedLUA.currentItemSelected = 1
	if (oldLootItem ~= nil) then
		for itemIndex = 1, MasterLootTable:GetItemCount() do
			if (oldLootItem == MasterLootTable:GetItemLink(itemIndex)) then
				XckMLAdvancedLUA.currentItemSelected = itemIndex
			end
		end
	end
	self:UpdateCurrentItem()
end

-- Updating Item Selected
function XckMLAdvancedLUA:UpdateSelectionFrame()
	self:CreateBasicSelectionFrame()
	local frameHeight = 5
	local county = MasterLootTable:GetItemCount()
	-- print(county)
	for itemIndex = 1, MasterLootTable:GetItemCount() do
		local buttonName = "SelectionButton" .. itemIndex
		local buttonFrame = getglobal(buttonName) or CreateFrame("Button", buttonName, selectionFrame, "SelectionButtonTemplate")
		buttonFrame:Show()
		buttonFrame:SetID(itemIndex)
		local itemLink = MasterLootTable:GetItemLink(itemIndex)
		-- print(itemLink)
		local buttonItemLink = getglobal(buttonName .. "_ItemLink")
		buttonItemLink:SetText(itemLink)

		local _, _, itemIdStr = string.find(itemLink, "item:(%d+)")
		local itemId = tonumber(itemIdStr)
		-- print(itemId)
		itemName, itemLink, itemQuality, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
		-- local itemTexture = MasterLootTable:GetItemTexture(itemIndex)
		-- print(itemTexture)
		local buttonItemTexture = getglobal(buttonName .. "_ItemTexture")
		buttonItemTexture:SetTexture(itemTexture)
		
		buttonFrame:SetPoint("TOPLEFT", selectionFrame, "TOPLEFT", 0, -frameHeight)
		frameHeight = frameHeight + 37
	end
	selectionFrame:SetHeight(frameHeight)
end

-- Get Amount of Items on Corpse
function MasterLootTable:GetItemCount()
	return self.lootCount
end

-- Create Frame for Switching Items Available
function XckMLAdvancedLUA:CreateBasicSelectionFrame()
	if (selectionFrame == nil) then
		selectionFrame = CreateFrame("Frame", "SelectFrame", nil, UIParent)
		selectionFrame:SetBackdrop( {
			bgFile = "Interface\\AddOns\\MasterLoot\\img\\UI-RaidFrame-GroupBg",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 10,
			edgeSize = 10,
			insets = {
				left = 3,
				right = 3,
				top = 3,
			bottom = 3 }})
			selectionFrame:SetAlpha(1)
			selectionFrame:SetBackdropColor(0, 0, 0, 1)
			
			selectionFrame.texture = selectionFrame:CreateTexture()
			selectionFrame.texture:SetTexture(0, 0, 0, 1)
			selectionFrame.texture:SetPoint("TOPLEFT", selectionFrame, "TOPLEFT", 3, -3)
			selectionFrame.texture:SetPoint("BOTTOMRIGHT", selectionFrame, "BOTTOMRIGHT", -3, 3)
			
			selectionFrame:SetWidth(200)
			selectionFrame:SetHeight(100)
			selectionFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			selectionFrame:Show()
			
	end
	local index = 1
	local buttonName = "SelectionButton" .. index
	local buttonHandle = getglobal(buttonName)
	while (buttonHandle ~= nil) do
		buttonHandle:Hide()
		index = index + 1
		buttonName = "SelectionButton" .. index
		buttonHandle = getglobal(buttonName)
	end
end

-- function XckMLAdvancedLUA:sr_prio()
-- 	sr_prio = {}
	

-- end


-- Update the Current Item Switched
function XckMLAdvancedLUA:UpdateCurrentItem()
	local lootPrioEditBox = getglobal("XckMLAdvancedMain_lootprio")
    -- lootPrioEditBox:SetText(XckMLAdvancedLUA.currentItemSelected)
	if (MasterLootTable:ItemExists(XckMLAdvancedLUA.currentItemSelected)) then
		local itemLink = MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected)
		local itemLinkLabel = getglobal("XckMLAdvancedMain_CurrentItemLink")
		itemLinkLabel:SetText(itemLink)
				
		-- for itemIndex = 1, GetNumLootItems() do
			-- local itemLink = GetLootSlotLink(itemIndex)
			-- print(itemLink)
			-- if (itemLink == MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected)) then
				-- print(itemLink)
				-- local texture, name, quantity, quality, locked = GetLootSlotInfo(itemLink)
				local _, _, itemIdStr = string.find(itemLink, "item:(%d+)")
				-- print(itemIdStr)
				local itemId = tonumber(itemIdStr)
				-- print(itemId) 
				local name = GetItemInfo(itemId)
				-- print(name)
				-- if(name == "Hard Spider Leg Tip") then
				-- 	XckMLAdvancedLUA.LootPrioText = "Prio1"
				-- elseif(name == "Crisp Spider Meat") then
				-- 	XckMLAdvancedLUA.LootPrioText = "Prio2"
				-- else
				-- 	XckMLAdvancedLUA.LootPrioText = name
				-- 	-- print(itemIndex)
				-- end
				if XckMLAdvancedLUA.srData[name] then
					local t = {}
					for _,entry in pairs(XckMLAdvancedLUA.srData[name]) do
						table.insert(t,entry.attendee)
					end
					XckMLAdvancedLUA.LootPrioText = "SR: " .. table.concat(t," / ")
				elseif(loot_prio[name]) then
					XckMLAdvancedLUA.LootPrioText = loot_prio[name]
				else
					XckMLAdvancedLUA.LootPrioText = name
				end

		-- 	end
		
		-- end

		-- print(itemLink)

		-- local texture, name, quantity, quality, locked = GetLootSlotInfo(1)
		-- print(name)
		lootPrioEditBox:SetText(XckMLAdvancedLUA.LootPrioText)
		-- print(XckMLAdvancedLUA.currentItemSelected)
		-- local itemTexture = MasterLootTable:GetItemTexture(XckMLAdvancedLUA.currentItemSelected)
		-- if XckMLAdvancedLUA.LootPrioText then
		XckMLAdvancedLUA.currentItemSelectedtexture = itemLink
		-- end
		-- local itemtest = MasterLootTable:GetItemTexture2(itemLink)
		-- print(itemtest)
		local _, _, itemIdStr = string.find(itemLink, "item:(%d+)")
		local itemId = tonumber(itemIdStr)
		-- print(itemId)
		itemName, itemLink, itemQuality, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
		local currentItemTexture = getglobal("XckMLAdvancedMain_CurrentItemTexture")
		currentItemTexture:SetNormalTexture(itemTexture)
		currentItemTexture:SetPushedTexture(itemTexture)
	end
	
end

-- Check if Item Exist
function MasterLootTable:ItemExists(index)
	return self.loot[index] ~= nil
end

-- Get Item Link
function MasterLootTable:GetItemLink(index)
	return self.loot[index].itemLink
end

-- Get item Texture
function MasterLootTable:GetItemTexture(index)
	return self.loot[index].itemTexture
end

-- Get item Texture
function MasterLootTable:GetItemTexture2(itemLink)
	local _, _, itemIdStr = string.find(itemLink, "item:(%d+)")
	local itemId = tonumber(itemIdStr)
	itemName, itemLink, itemQuality, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
	return itemTexture
end

-- Clear Loot Data Array
function MasterLootTable:Clear()
	self.lootCount = 0
	self.loot = {}
end

-- Get Quality of Item
function MasterLootTable:GetQualityArray(Quality)
	for k,v in pairs(XckMLAdvancedLUA.QualityList) do
		if(k == Quality) then
			return v;
		end
	end
end

-- Add Only Item Equal and Greater than Selected
function MasterLootTable:AddItem(itemLk, slot)
	--local name, item, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemLink)
	local texture, name, quantity, quality, locked = GetLootSlotInfo(slot)
	local lootThreshold = GetLootThreshold()
	-- if (quality  < MasterLootTable:GetQualityArray(XckMLAdvancedLUA.qualityListSet)) then
	-- 	return
	-- end
	self.lootCount = self.lootCount + 1
	self.loot[self.lootCount] = {}
	self.loot[self.lootCount].itemLink = itemLk
	self.loot[self.lootCount].itemTexture = texture
end

-- COUNTDOWN FUNCTION CORE
function XckMLAdvancedLUA:OnUpdate()
	if not self.countdownRunning then
		self.announcementTimes = nil
		return
	end

	local elapsed = GetTime() - self.countdownStartTime
	local currentTime = math.ceil(self.countdownRange - elapsed)
	if currentTime < 0 then
		currentTime = 0
	end

	local itemLink = MasterLootTable:GetItemLink(XckMLAdvancedLUA.currentItemSelected)

	-- Generate announcementTimes if they haven't been created yet.
	if not self.announcementTimes then
		self.announcementTimes = {}
		if self.countdownRange >= 30 then
			table.insert(self.announcementTimes, self.countdownRange)
			local half = math.ceil(self.countdownRange / 2)
			-- Avoid duplicate announcement if half equals 15 (e.g. for a 30‑second countdown)
			if half ~= 15 then
					table.insert(self.announcementTimes, half)
			end
			table.insert(self.announcementTimes, 15)
			table.insert(self.announcementTimes, 10)
			table.insert(self.announcementTimes, 5)
		elseif self.countdownRange >= 15 then
			table.insert(self.announcementTimes, self.countdownRange)
			table.insert(self.announcementTimes, 10)
			table.insert(self.announcementTimes, 5)
		elseif self.countdownRange > 5 then
			table.insert(self.announcementTimes, self.countdownRange)
			table.insert(self.announcementTimes, 5)
		end
	end

	-- Process any announcement times that have been reached.
	while self.announcementTimes and self.announcementTimes[1] and currentTime <= self.announcementTimes[1] do
		local t = table.remove(self.announcementTimes, 1)
		if t > 0 then
				SendChatMessage(itemLink .. " " .. t .. " seconds left to roll", 'Raid')
		end
	end

	if currentTime <= 0 then
		self.countdownRunning = false
		SendChatMessage(itemLink .. " Rolling is now Closed", 'Raid')
		self.announcementTimes = nil
	end
end

function XckMLAdvancedLUA:OnShow()
	if not XckMLAdvancedLUA.settings_set then
		XckMLAdvancedMainSettings:SetPoint("LEFT","LootFrame","RIGHT",-50,0)
		XckMLAdvancedMainSettings:Show();
		XckMLAdvancedMain:Hide()
	else
		XckMLAdvancedMainSettings:Hide();
	end
end

-----
----- SPEAKING RW/PARTY FUNCTION
-----
-- Call in Raid Warning or Speak in Party
function XckMLAdvancedLUA:Speak(str)
	local chatType = "SAY";
	
	if (self:PlayerIsInAParty() and self:PlayerIsInARaid() == false) then
		chatType = "PARTY";	
		elseif (self:PlayerIsInARaid()) then
		chatType = "RAID_WARNING";
	end
	
	SendChatMessage(str, chatType)
end

-- Check if Player is in Party
function XckMLAdvancedLUA:PlayerIsInAParty()
	return GetNumPartyMembers() ~= 0
end

-- Check if Player is in Raid
function XckMLAdvancedLUA:PlayerIsInARaid()
	return GetNumRaidMembers() ~= 0
end

-----
----- DROPDOWN FUNCTION
-----
-- UpdateDropDown Data Players
function XckMLAdvancedLUA:UpdateDropdowns()
	for index = 1, 8 do
		XckMLAdvancedLUA.dropdownData[index] = {}
		XckMLAdvancedLUA.dropdownGroupData[index] = false;
	end
	
	XckMLAdvancedLUA.dropdownGroupData = {}
	local numRaidMembers = XckMLAdvancedLUA:GetNbPlayersRaidParty();
	
	if(self:PlayerIsInARaid()) then
		for x = 1, numRaidMembers do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(x);
			XckMLAdvancedLUA.dropdownData[subgroup][name] = name;
			XckMLAdvancedLUA.dropdownGroupData[subgroup] = true;
		end
		elseif(self:PlayerIsInAParty() and self:PlayerIsInARaid() == false) then
		for x = 1, numRaidMembers do
			local name = UnitName(self:IsInRaidOrParty()..x)
			XckMLAdvancedLUA.dropdownData[1][name] = name;
			XckMLAdvancedLUA.dropdownGroupData[1] = true;
		end
		XckMLAdvancedLUA.dropdownData[1][UnitName("player")] = UnitName("player");
	end
end  

-- Init DropDown Quality List
function XckMLAdvancedLUA:InitQualityListDropDown()
	local arrayQListC = {"|cff9d9d9dPoor", "Common", "|cff1eff00Uncommon", "|cff0070ddRare", "|cffa335eeEpic", "|cffff8000Legendary"}
	local arrayQList = {"Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary"}
	if (UIDROPDOWNMENU_MENU_LEVEL == 1) then
		for key, value in pairs(arrayQList) do
			local info = {}
			info.hasArrow = false;
			info.notCheckable = false;
			info.text = arrayQListC[key];
			info.value = value;
			info.owner = UIDROPDOWNMENU_OPEN_MENU;
			info.func = XckMLAdvancedLUA.DropClicked;
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL );
		end
	end 
end

-- Init DropDown Loot Method
function XckMLAdvancedLUA:InitRollOrNeedDropDown()
	local RollNeedChoice = {
		["Roll"] = 0,
		["Need"] = 1,
	}
	if (UIDROPDOWNMENU_MENU_LEVEL == 1) then
		for key, value in pairs(RollNeedChoice) do
			local info = {}
			info.hasArrow = false;
			info.notCheckable = true;
			info.text = key;
			info.value = key;
			info.owner = UIDROPDOWNMENU_OPEN_MENU;
			info.func = XckMLAdvancedLUA.DropClicked;
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL );
		end
	end 
end

-- Init DropDown RaidGroups Players
function XckMLAdvancedLUA:InitializeDropdown()
	
	if (UIDROPDOWNMENU_MENU_LEVEL == 2) then
		local groupnumber = UIDROPDOWNMENU_MENU_VALUE;
		groupmembers = XckMLAdvancedLUA.dropdownData[groupnumber];
		for key, value in pairs(groupmembers) do
			local info = {}
			info.hasArrow = false;
			info.notCheckable = true;
			info.text = key;
			info.value = key;
			info.owner = UIDROPDOWNMENU_OPEN_MENU;
			info.func = XckMLAdvancedLUA.DropClicked;
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
		end
	end
	
	if (UIDROPDOWNMENU_MENU_LEVEL == 1) then
		for key, value in pairs(XckMLAdvancedLUA.dropdownData) do
			if (XckMLAdvancedLUA.dropdownGroupData[key] == true) then
				local info = {}
				info.hasArrow = true;
				info.notCheckable = true;
				info.text = "Group " .. key;
				info.value = key;
				info.owner = UIDROPDOWNMENU_OPEN_MENU;
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL );
			end
		end
	end    
end

-- Event DropDown Clicked
function XckMLAdvancedLUA:DropClicked()
	UIDropDownMenu_SetText(this.value, getglobal(this.owner))
end


-----
----- LOOTFRAME BUTTONS UI
-----
function XckMLAdvancedLUA:InitAllLootFrameFrame()
	
	local BSettings = CreateFrame('Button', "BSettings", LootFrame)
	BSettings:SetPoint('TOP', LootFrame, 'TOP', 25, -16)
	BSettings.tooltipText = "test"
	BSettings:SetWidth(20) 
	BSettings:SetHeight(20)
	local BSettingsNtex = BSettings:CreateTexture()
	BSettingsNtex:SetTexture("Interface\\AddOns\\MasterLoot\\img\\UI-Dialog-Icon-AlertOther")
	BSettingsNtex:SetAllPoints()	
	BSettings:SetNormalTexture(BSettingsNtex)
	local BSettingsHtex = BSettings:CreateTexture()
	BSettingsHtex:SetTexture("Interface\\AddOns\\MasterLoot\\img\\UI-Dialog-Icon-AlertOther")
	BSettingsHtex:SetAllPoints()
	BSettings:SetHighlightTexture(BSettingsHtex)
	BSettings:SetScript('OnClick', function()
		if(XckMLAdvancedMainSettings:IsShown() == nil) then
			XckMLAdvancedMainSettings:SetPoint("LEFT","LootFrame","RIGHT",-50,0)
			XckMLAdvancedMainSettings:Show();
		else
			XckMLAdvancedMainSettings:Hide();
		end
	end)
	BSettings:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(XCKMLA_Tooltip_Settings, 1, 1, 1)
		GameTooltip:Show()
	end)
	BSettings:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local BAnnounceDrops = CreateFrame('Button', "BAnnounceDrops", LootFrame)
	BAnnounceDrops:SetPoint('TOP', LootFrame, 'TOP', -40, -43)
	BAnnounceDrops:SetWidth(25) 
	BAnnounceDrops:SetHeight(25)
	local BAnnounceDropsNtex = BAnnounceDrops:CreateTexture()
	BAnnounceDropsNtex:SetTexture("Interface\\AddOns\\MasterLoot\\img\\INV_MISC_BEER_02")
	BAnnounceDropsNtex:SetAllPoints()
	BAnnounceDrops:SetNormalTexture(BAnnounceDropsNtex)
	local BAnnounceDropsHtex = BAnnounceDrops:CreateTexture()
	BAnnounceDropsHtex:SetTexture("Interface\\AddOns\\MasterLoot\\img\\INV_MISC_BEER_02")
	BAnnounceDropsHtex:SetAllPoints()
	BAnnounceDrops:SetHighlightTexture(BAnnounceDropsHtex)
	BAnnounceDrops:SetScript('OnClick', function()
		self:AnnounceLootClicked(getglobal(this:GetName()))
	end)
	BAnnounceDrops:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(XCKMLA_Tooltip_AnnounceDrops, 1, 1, 1)
		GameTooltip:Show()
	end)
	BAnnounceDrops:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

end

function XckMLAdvancedLUA:InitButtonLootAllItems()
	local na = CreateFrame('Button', "NinjaAllItems", LootFrame)
	na:SetPoint('TOP', LootFrame, 'TOP', 13, -43)
	na:SetWidth(75) 
	na:SetHeight(24)
	
	local ntex = na:CreateTexture()
	ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	ntex:SetAllPoints()	
	na:SetNormalTexture(ntex)
	
	local htex = na:CreateTexture()
	htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	htex:SetTexCoord(0, 0.625, 0, 0.6875)
	htex:SetAllPoints()
	na:SetHighlightTexture(htex)
	
	local ptex = na:CreateTexture()
	ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	ptex:SetTexCoord(0, 0.625, 0, 0.6875)
	ptex:SetAllPoints()
	na:SetPushedTexture(ptex)
	
	local fo = na:CreateFontString()
	fo:SetFont("Fonts/FRIZQT__.TTF",11)
	fo:SetPoint("CENTER", na, "CENTER", 0,0)
	fo:SetText("Loot")
	na:SetFontString(fo)
	
	na:SetScript('OnClick', function()
	local NbPlayers = XckMLAdvancedLUA:GetNbPlayersRaidParty()
		if (self:PlayerIsMasterLooter()) then			
			if(XckMLAdvancedLUA.ConfirmNinja == nil) then
				XckMLAdvancedLUA.ConfirmNinja = 1
				self:Print(XCKMLA_NinjaButtonMSGConfirm)
			elseif (XckMLAdvancedLUA.ConfirmNinja == 1) then
				for li = 1, GetNumLootItems() do 
					local texture, name, quantity, quality, locked = GetLootSlotInfo(li)
					
					if XckMLAdvancedLUA:CheckIsRaidItem(name) then
						for ci = 1, NbPlayers do 
							if (GetMasterLootCandidate(ci) == XckMLAdvancedLUA.aq_zg_items_guy) then 
								GiveMasterLoot(li, ci); 
							end
						end
					else
						if quality  <= 1 then
							for ci = 1, NbPlayers do 
								if (GetMasterLootCandidate(ci) == XckMLAdvancedLUA.poorguy) then 
									GiveMasterLoot(li, ci); 
								end
							end
						end
						for ci = 1, XckMLAdvancedLUA:GetNbPlayersRaidParty() do 
							if (GetMasterLootCandidate(ci) == UnitName("Player")) then 
								GiveMasterLoot(li, ci); 
							end
						end 
					end 
					XckMLAdvancedLUA.ConfirmNinja = nil
				end
			else
				self:Print(XCKMLA_PAreNotML)
			end
		end
	end)
end


-------
------- Guild info
-------
function GetGuildMembers()
	guildmembersdb = {}
	GCount = GetNumGuildMembers(numTotalMembers)
    for i = 1, GCount do
		local name,rank,_,_,class,_,_,onote = GetGuildRosterInfo(i);
		table.insert(guildmembersdb, {name=name, rank=rank, class=class, onote=onote})
	end
	print(GCount)
	print ("Guild Collected")
end

function RetrieveGuildMember()
	print(G_Count)
	-- print(GName..)
	for i = 1, G_Count do 
		-- if(guildmembersdb[i].name == GName) then
			if string.find(guildmembersdb[i].onote, "MS:B") then
				print(guildmembersdb[i].name.." "..guildmembersdb[i].rank.." ".."Boomkin")
			end
			if string.find(guildmembersdb[i].onote, "MS:F") then
				print(guildmembersdb[i].name.." "..guildmembersdb[i].rank.." ".."Frost")
			end
		-- end
	end
	-- return spec
end

-------
------- POP Confirm StaticPopup_Show("Confirm_Attrib")  MasterLootRolls:AddRoll("Xckbucl", "+1")
-------
StaticPopupDialogs["Confirm_Attrib"] = {
	text = XCKMLA_NothingTextPopup,
	button1 = XCKMLA_YESButton,
	button2 = XCKMLA_NOButton,
	OnAlt = function ()
		VideoOptionsFrame_SetCurrentToDefaults();
	end,
	OnCancel = function() end,
	showAlert = 1,
	OnAccept = function() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	hasItemFrame = true,
	preferredIndex = 3,
	OnShow = function()
		getglobal(this:GetName().."AlertIcon"):SetPoint("LEFT", 20, 0)
		getglobal(this:GetName().."AlertIcon"):SetTexture(MasterLootTable:GetItemTexture2(XckMLAdvancedLUA.currentItemSelectedtexture))
		getglobal(this:GetName().."AlertIcon"):SetWidth(40) getglobal(this:GetName().."AlertIcon"):SetHeight(40)
	end,
}
