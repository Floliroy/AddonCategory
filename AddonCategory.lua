AddonCategory = AddonCategory or {}
local AddonCategory = AddonCategory

AddonCategory.name = "AddonCategory"
AddonCategory.version = "1.5"
AddonCategory.listAddons = {}
AddonCategory.listLibraries = {}
AddonCategory.listNonAssigned = {}

local sV

local ADDON_DATA = 1
local SECTION_HEADER_DATA = 2

local IS_LIBRARY = true
local IS_ADDON = false

local AddOnManager = GetAddOnManager()
local votanAddonListPresent = false

local expandedAddons = {}

local g_uniqueNamesByCharacterName = {}
local function CreateAddOnFilter(characterName)
    local uniqueName = g_uniqueNamesByCharacterName[characterName]
    if not uniqueName then
        uniqueName = GetUniqueNameForCharacter(characterName)
        g_uniqueNamesByCharacterName[characterName] = uniqueName
    end
    return uniqueName
end

local function StripText(text)
    return text:gsub("|c%x%x%x%x%x%x", "")
end

local function resetList()
	AddonCategory.listAddons = {}
    AddonCategory.listLibraries = {}
    AddonCategory.listNonAssigned = {}
end

local function addAddonToList(index, name, isLibrary)
	if isLibrary ~= IS_LIBRARY then
		AddonCategory.listAddons[index] = name
	else
		AddonCategory.listLibraries[index] = name
	end
	
	if sV[name] == nil and isLibrary ~= IS_LIBRARY then
		table.insert(AddonCategory.listNonAssigned, name)
	end
end

local function populateList()
	resetList()

	for i = 1, AddOnManager:GetNumAddOns() do
		local name, _, _, _, _, _, _, isLibrary = AddOnManager:GetAddOnInfo(i)

        addAddonToList(i, name, isLibrary)
	end
end

local function BuildMasterList(self)
    self.addonTypes = self.addonTypes or {}
    self.addonTypes[IS_ADDON] = self.addonTypes[IS_ADDON] or {}
    for key, value in pairs(sV.listCategory) do
        self.addonTypes[value] = {}
    end

    resetList()

	for i = 1, #self.addonTypes[IS_ADDON] do
		local entryData = self.addonTypes[IS_ADDON][i]

		addAddonToList(entryData.index, entryData.addOnFileName, IS_ADDON)

		entryData.isCustomCategory = false
		if sV[entryData.addOnFileName] ~= nil then
			entryData.isCustomCategory = true
		end
        
        if entryData.isCustomCategory == true then
			self.addonTypes[IS_ADDON][i] = nil
            table.insert(self.addonTypes[sV[entryData.addOnFileName]], entryData)
        else
            table.insert(self.addonTypes[IS_ADDON], entryData)
        end
    end

	for i = 1, #self.addonTypes[IS_LIBRARY] do
		local entryData = self.addonTypes[IS_LIBRARY][i]
		addAddonToList(entryData.index, entryData.addOnFileName, IS_LIBRARY)
	end

	if votanAddonListPresent == true then
		--Reset to original sortCallback
		self.sortCallback = function(entry1, entry2)
			return ZO_TableOrderingFunction(entry1, entry2, self.currentSortKey, self.sortKeys, self.currentSortDirection)
		end
	end
end

--disable addon indent do by Votan's Addon List because this feature can't work when our addon is enabled
local function DisableVotanAddonListIndent(control)
	local indent = 0

	local enableButton = control:GetNamedChild("Enabled")
	enableButton:SetAnchor(TOPLEFT, nil, TOPLEFT, 7 + indent, 7)
	
	local name = control:GetNamedChild("Name")
	name:SetWidth(385 - indent)
end

-- Can't use SecurePostHook because need to be called on the callback function returned by GetRowSetupFunction()
local orgGetRowSetupFunction = ZO_AddOnManager.GetRowSetupFunction
function ZO_AddOnManager:GetRowSetupFunction()
	return function(...)
		local orgSetup = orgGetRowSetupFunction(self)
		orgSetup(...)
		
		if votanAddonListPresent == true then
			DisableVotanAddonListIndent(...)
		end
		
	end
end

local libraryText = nil
local _AddAddonTypeSection = ADD_ON_MANAGER.AddAddonTypeSection
local function AddAddonTypeSection(self, isLibrary, sectionTitleText)

    local customCategory = false

    for key, value in pairs(sV.listCategory) do
        if value == isLibrary then 
            customCategory = true
            break
        end
    end

    if customCategory == true or isLibrary == true then
        local addonEntries = self.addonTypes[isLibrary]
        table.sort(addonEntries, self.sortCallback)

        local scrollData = ZO_ScrollList_GetDataList(self.list)
        local titleText = isLibrary
        if isLibrary == true then
            titleText = sectionTitleText
            libraryText = sectionTitleText
        end
        scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(SECTION_HEADER_DATA, { isLibrary = isLibrary, text = titleText })
        for _, entryData in ipairs(addonEntries) do
            if sV.sectionsOpen[sectionTitleText] == nil or sV.sectionsOpen[sectionTitleText] == true then
                if entryData.expandable and expandedAddons[entryData.index] then
                    entryData.expanded = true

                    local useHeight, typeId = self:SetupTypeId(entryData.addOnDescription, entryData.addOnDependencyText)

                    entryData.height = useHeight
                    scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(typeId, entryData)
                else
                    entryData.height = ZO_ADDON_ROW_HEIGHT
                    scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(ADDON_DATA, entryData)
                end
            end
        end
    else
        _AddAddonTypeSection(self, isLibrary, sectionTitleText)
    end
end

local cptToolbar = 0
local sectionsHeader = {}
local sectionsEnable = {}
local _SetupSectionHeaderRow = ADD_ON_MANAGER.SetupSectionHeaderRow
local function SetupSectionHeaderRow(self, control, data)
    local customCategory = false

    for key, value in pairs(sV.listCategory) do
        if value == data.isLibrary then 
            customCategory = true
            break
        end
    end

    if customCategory == true or data.isLibrary == true then
        local previousText = control.textControl:GetText()
        control.textControl:SetText(data.text)
        control.checkboxControl:SetHidden(true)

        cptToolbar = cptToolbar + 1
        control.toolBar = CreateControlFromVirtual("$(parent)ToolBar" .. cptToolbar, control, "ZO_MenuBarTemplate")
        control.toolBar:ClearAnchors()
        control.toolBar:SetAnchor(BOTTOMRIGHT, control.textControl, BOTTOMRIGHT, 65, 4)
    
        ZO_MenuBar_OnInitialized(control.toolBar)
        local barData = {
            buttonPadding = -4,
            normalSize = 28,
            downSize = 28,
            animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
            buttonTemplate = "ZO_MenuBarTooltipButton"
        }
        ZO_MenuBar_SetData(control.toolBar, barData)
        ZO_MenuBar_SetClickSound(control.toolBar, "DEFAULT_CLICK")


        local function CreateButtonData(tooltipString, nb, icon, functionCallback)
            return {
                activeTabText = data.text,
                categoryName = data.text,
                CustomTooltipFunction = function(tooltip)
                    SetTooltipText(tooltip, tooltipString .. " all addons of " .. data.text)
                end,
                tooltip = "tooltip",
                alwaysShowTooltip = true,
                descriptor = nb,
                normal = "esoui/art/buttons/" .. icon .. "_up.dds",
                pressed = "esoui/art/buttons/" .. icon .. "_up.dds",
                highlight = "esoui/art/buttons/" .. icon .. "_over.dds",
                disabled = "esoui/art/buttons/" .. icon .. "_down.dds",
                callback = function(tabData)
                    functionCallback(tabData)

                    control.toolBar:SetHidden(true)
                    ADD_ON_MANAGER:RefreshData()
                    ZO_MenuBar_ClearSelection(control.toolBar)
                    PlaySound(SOUNDS.DEFAULT_CLICK)
                end
            }
        end

        local function callbackEnableDisable(tabData)
            if sectionsEnable[data.text] == nil then
                sectionsEnable[data.text] = false
            end
            local textTrueFalse = "false"
            if sectionsEnable[data.text] == true then
                textTrueFalse = "true"
            end
            if data.text == libraryText then 
                for key, value in pairs(AddonCategory.listLibraries) do
                    AddOnManager:SetAddOnEnabled(key, sectionsEnable[data.text])
                end
            else 
                for key, value in pairs(AddonCategory.listAddons) do
                    if sV[value] == data.text then
                        AddOnManager:SetAddOnEnabled(key, sectionsEnable[data.text])
                    end
                end
            end
            sectionsEnable[data.text] = not sectionsEnable[data.text]
            ADD_ON_MANAGER.isDirty = true
            --ADD_ON_MANAGER:RefreshMultiButton()
        end
        local function callbackShowHide(tabData)
            if sV.sectionsOpen[data.text] == nil then
                sV.sectionsOpen[data.text] = true
            end
            sV.sectionsOpen[data.text] = not sV.sectionsOpen[data.text]
        end
    
        local iconEnableDisable = "edit_cancel"
        local stringEnableDisable = "Disable"
        if sectionsEnable[data.text] == true then
            iconEnableDisable = "accept"
            stringEnableDisable = "Enable"
        end
        local iconShowHide = "large_rightarrow"
        local stringShowHide = "Hide"
        if sV.sectionsOpen[data.text] == false then
            iconShowHide = "large_downarrow"
            stringShowHide = "Show"
        end
        ZO_MenuBar_AddButton(control.toolBar, CreateButtonData(stringShowHide, 1, iconShowHide, callbackShowHide))
        ZO_MenuBar_AddButton(control.toolBar, CreateButtonData(stringEnableDisable, 2, iconEnableDisable, callbackEnableDisable))

        control.toolBar:SetHidden(false)
        local rowNb = control:GetName():gsub("ZO_AddOnsList2Row", "")
        if sectionsHeader[rowNb] ~= nil then
            sectionsHeader[rowNb]:SetHidden(true)
        end
        sectionsHeader[rowNb] = control.toolBar

        ZO_MenuBar_ClearSelection(control.toolBar)
    else
        if control.toolBar then
            control.toolBar:SetHidden(true)
        end
        _SetupSectionHeaderRow(self, control, data)
    end
end

local function SortScrollList(self)
    self:ResetDataTypes()
    local scrollData = ZO_ScrollList_GetDataList(self.list)        
    ZO_ClearNumericallyIndexedTable(scrollData)

    self:AddAddonTypeSection(IS_ADDON, GetString(SI_WINDOW_TITLE_ADDON_MANAGER))
    for i=1, #sV.listCategory do
        for key, value in pairs(AddonCategory.listAddons) do
            if sV[value] == sV.listCategory[i] then 
                self:AddAddonTypeSection(sV.listCategory[i], sV.listCategory[i])
                break
            end
        end
    end
    self:AddAddonTypeSection(IS_LIBRARY, GetString(SI_ADDON_MANAGER_SECTION_LIBRARIES))
end

local function OnExpandButtonClicked(self, row)
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    local data = ZO_ScrollList_GetData(row)

    if expandedAddons[data.index] then
        expandedAddons[data.index] = false

        data.expanded = false
        data.height = ZO_ADDON_ROW_HEIGHT
        scrollData[data.sortIndex] = ZO_ScrollList_CreateDataEntry(ADDON_DATA, data)
    else
        expandedAddons[data.index] = true

        local useHeight, typeId = self:SetupTypeId(data.addOnDescription, data.addOnDependencyText)

        data.expanded = true
        data.height = useHeight
        scrollData[data.sortIndex] = ZO_ScrollList_CreateDataEntry(typeId, data)
    end

    self:CommitScrollList()
end

SecurePostHook(ADD_ON_MANAGER, "BuildMasterList", BuildMasterList)
ADD_ON_MANAGER.AddAddonTypeSection = AddAddonTypeSection
ADD_ON_MANAGER.SetupSectionHeaderRow = SetupSectionHeaderRow
ADD_ON_MANAGER.SortScrollList = SortScrollList
ADD_ON_MANAGER.OnExpandButtonClicked = OnExpandButtonClicked

function AddonCategory.AssignAddonToCategory(addonName, categoryName)
    for _, name in pairs(AddonCategory.baseCategories) do
        if name == categoryName then
            if not sV then
                zo_callLater(function() 
                    if sV[addonName] == nil then
                        sV[addonName] = categoryName
                    end
                end, 3 * 1000)
            else
                if sV[addonName] == nil then
                    sV[addonName] = categoryName
                end
            end
        end
    end
end

----------
-- INIT --
----------
function AddonCategory:Initialize()
	--Saved Variables
	AddonCategory.savedVariables = ZO_SavedVars:NewAccountWide("AddonCategoryVariables", 1, nil, AddonCategory.defaultSV)
	sV = AddonCategory.savedVariables

	--Settings
	populateList()
	AddonCategory.CreateSettingsWindow()

	EVENT_MANAGER:UnregisterForEvent(AddonCategory.name, EVENT_ADD_ON_LOADED)
end

function AddonCategory.OnAddOnLoaded(event, addonName)
	if addonName == "LibVotansAddonList" then
		votanAddonListPresent = true
	end

	if addonName ~= AddonCategory.name then return end
    AddonCategory:Initialize()
end

EVENT_MANAGER:RegisterForEvent(AddonCategory.name, EVENT_ADD_ON_LOADED, AddonCategory.OnAddOnLoaded)