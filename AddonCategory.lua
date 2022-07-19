AddonCategory = AddonCategory or {}
local AddonCategory = AddonCategory

AddonCategory.name = "AddonCategory"
AddonCategory.version = "0.1"

local sV

local ADDON_DATA = 1
local SECTION_HEADER_DATA = 2

local IS_LIBRARY = true
local IS_ADDON = false

local AddOnManager = GetAddOnManager()

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

local function BuildMasterList(self)
    self.addonTypes = {}
    self.addonTypes[IS_LIBRARY] = {}
    self.addonTypes[IS_ADDON] = {}
    for key, value in pairs(sV.listCategory) do
        self.addonTypes[value] = {}
    end

    if self.selectedCharacterEntry and not self.selectedCharacterEntry.allCharacters then
        self.isAllFilterSelected = false
        AddOnManager:SetAddOnFilter(CreateAddOnFilter(self.selectedCharacterEntry.name))
    else
        self.isAllFilterSelected = true
        AddOnManager:RemoveAddOnFilter()
    end

    AddonCategory.listAddons = {}
    for i = 1, AddOnManager:GetNumAddOns() do
        local name, title, author, description, enabled, state, isOutOfDate, isLibrary = AddOnManager:GetAddOnInfo(i)
        if isLibrary ~= IS_LIBRARY then
            table.insert(AddonCategory.listAddons, name)
        end

        local entryData = {
            index = i,
            addOnFileName = name,
            addOnName = title,
            strippedAddOnName = StripText(title),
            addOnDescription = description,
            addOnEnabled = enabled,
            addOnState = state,
            isOutOfDate = isOutOfDate,
            isLibrary = isLibrary,
            isCustomCategory = false,
        }
		
		if sV[name] ~= nil then
			entryData.isCustomCategory = true
		end

        if author ~= "" then
            local strippedAuthor = StripText(author)
            entryData.addOnAuthorByLine = zo_strformat(SI_ADD_ON_AUTHOR_LINE, author)
            entryData.strippedAddOnAuthorByLine = zo_strformat(SI_ADD_ON_AUTHOR_LINE, strippedAuthor)
        else
            entryData.addOnAuthorByLine = ""
            entryData.strippedAddOnAuthorByLine = ""
        end

        local dependencyText = ""
        for j = 1, AddOnManager:GetAddOnNumDependencies(i) do
            local dependencyName, dependencyExists, dependencyActive, dependencyMinVersion, dependencyVersion = AddOnManager:GetAddOnDependencyInfo(i, j)
            local dependencyTooLowVersion = dependencyVersion < dependencyMinVersion            
            
            local dependencyInfoLine = dependencyName
            if not self.isAllFilterSelected and (not dependencyActive or not dependencyExists or dependencyTooLowVersion) then
                entryData.hasDependencyError = true
                if not dependencyExists then
                    dependencyInfoLine = zo_strformat(SI_ADDON_MANAGER_DEPENDENCY_MISSING, dependencyName)
                elseif not dependencyActive then
                    dependencyInfoLine = zo_strformat(SI_ADDON_MANAGER_DEPENDENCY_DISABLED, dependencyName)
                elseif dependencyTooLowVersion then
                    dependencyInfoLine = zo_strformat(SI_ADDON_MANAGER_DEPENDENCY_TOO_LOW_VERSION, dependencyName)
                end
                dependencyInfoLine = ZO_ERROR_COLOR:Colorize(dependencyInfoLine)
            end
            dependencyText = string.format("%s\n    %s  %s", dependencyText, GetString(SI_BULLET), dependencyInfoLine)
        end
        entryData.addOnDependencyText = dependencyText

        entryData.expandable = (description ~= "") or (dependencyText ~= "")
        
        if entryData.isCustomCategory == true then
            table.insert(self.addonTypes[sV[name]], entryData)
        else
            table.insert(self.addonTypes[isLibrary], entryData)
        end
    end
end

local _AddAddonTypeSection = ADD_ON_MANAGER.AddAddonTypeSection
local function AddAddonTypeSection(self, isLibrary, sectionTitleText)

    local customCategory = false

    for key, value in pairs(sV.listCategory) do
        if value == isLibrary then 
            customCategory = true
            break
        end
    end

    if customCategory == true then
        local addonEntries = self.addonTypes[isLibrary]
        table.sort(addonEntries, self.sortCallback)

        local scrollData = ZO_ScrollList_GetDataList(self.list)
        scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(SECTION_HEADER_DATA, { isLibrary = isLibrary, text = isLibrary })
        for _, entryData in ipairs(addonEntries) do
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
    else
        _AddAddonTypeSection(self, isLibrary, sectionTitleText)
    end
end

local cptToolbar = 0
local sectionsHeader = {}
local _SetupSectionHeaderRow = ADD_ON_MANAGER.SetupSectionHeaderRow
local function SetupSectionHeaderRow(self, control, data)
    local customCategory = false

    for key, value in pairs(sV.listCategory) do
        if value == data.isLibrary then 
            customCategory = true
            break
        end
    end

    if customCategory == true then
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


        local function CreateButtonData(tooltipString, nb, normal, highlight, disabled, functionCallback)
            return {
                activeTabText = data.text,
                categoryName = data.text,
                CustomTooltipFunction = function(tooltip)
                    SetTooltipText(tooltip, tooltipString .. data.text)
                end,
                tooltip = "tooltip",
                alwaysShowTooltip = true,
                descriptor = nb,
                normal = normal,
                pressed = normal,
                highlight = highlight,
                disabled = disabled,
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
            d("Click Enable " .. data.text .. " (" .. data.sortIndex .. ")")
        end
        local function callbackShowHide(tabData)
            d("Click Show " .. data.text .. " (" .. data.sortIndex .. ")")
        end
    
        ZO_MenuBar_AddButton(control.toolBar, CreateButtonData("Show / hide all addons of ", 1, "esoui/art/buttons/rightarrow_up.dds", "esoui/art/buttons/rightarrow_over.dds", "esoui/art/buttons/rightarrow_down.dds", callbackShowHide))
        ZO_MenuBar_AddButton(control.toolBar, CreateButtonData("Enable / disable all addons of ", 2, "esoui/art/buttons/edit_cancel_up.dds", "esoui/art/buttons/edit_cancel_over.dds", "esoui/art/buttons/edit_cancel_down.dds", callbackEnableDisable))

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

function OnExpandButtonClicked(self, row)
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

ADD_ON_MANAGER.BuildMasterList = BuildMasterList
ADD_ON_MANAGER.AddAddonTypeSection = AddAddonTypeSection
ADD_ON_MANAGER.SetupSectionHeaderRow = SetupSectionHeaderRow
ADD_ON_MANAGER.SortScrollList = SortScrollList
ADD_ON_MANAGER.OnExpandButtonClicked = OnExpandButtonClicked

----------
-- INIT --
----------
function AddonCategory:Initialize()
	--Saved Variables
	AddonCategory.savedVariables = ZO_SavedVars:NewAccountWide("AddonCategoryVariables", 0, nil, {
        listCategory = {"User Interface", "Trials / Dungeons", "PvP", "Map"},
    })
	sV = AddonCategory.savedVariables

	--Settings
    ADD_ON_MANAGER.BuildMasterList(self)
	AddonCategory.CreateSettingsWindow()

	EVENT_MANAGER:UnregisterForEvent(AddonCategory.name, EVENT_ADD_ON_LOADED)
end

function AddonCategory.OnAddOnLoaded(event, addonName)
	if addonName ~= AddonCategory.name then return end
    AddonCategory:Initialize()
end

EVENT_MANAGER:RegisterForEvent(AddonCategory.name, EVENT_ADD_ON_LOADED, AddonCategory.OnAddOnLoaded)