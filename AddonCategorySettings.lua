AddonCategory = AddonCategory or {}
local AddonCategory = AddonCategory

local LAM2 = LibAddonMenu2

local function getArrayCategoriesLength(sV)
    local array = {}
    for i=1, #sV.listCategory do
        table.insert(array, i)
    end
    return array
end

local function UpdateAllChoices()
    Categories_dropdown:UpdateChoices()
    CategoriesName_dropdown:UpdateChoices()
    CategoriesOrder_dropdown:UpdateChoices()
end

function AddonCategory.CreateSettingsWindow()
	local panelData = {
		type = "panel",
		name = "AddonCategory",
		displayName = "AddonCategory",
		author = "Floliroy",
		version = AddonCategory.version,
		slashCommand = "/addoncategory",
		registerForRefresh = true,
		registerForDefaults = false,
	}
	
	local cntrlOptionsPanel = LAM2:RegisterAddonPanel("AddonCategory_Settings", panelData)
	local sV = AddonCategory.savedVariables

    local addon, category, newCategory, categoryName, newCategoryName, categoryOrder, newOrder

    table.sort(AddonCategory.listAddons, function (a, b) return a < b end)
	
	local optionsData = {
		{
			type = "header",
			name = "Link Addon to Category",
		},
        {
            type = "editbox",
            name = "Create New Category",
            tooltip = "Enter here the new category's name you want.",
            getFunc = function() return nil end,
            setFunc = function(newValue) 
                if newValue ~= nil and newValue ~= "" then
                    newCategory = newValue
                end
            end,
        },
        {
            type = "button",
            name = "Add Category",
            tooltip = "Add a new category with the name you typed above.",
            func = function()
                if newCategory ~= nil and newCategory ~= "" then
                    table.insert(sV.listCategory, newCategory)
                    UpdateAllChoices()
                end
            end,
        },
        {
            type = "button",
            name = "Delete Category",
            tooltip = "Delete the selected category below.",
            func = function()
                if category ~= nil then
                    for i, v in ipairs(sV.listCategory) do
                        if v == category then
                            table.remove(sV.listCategory, i)
                            break
                        end
                    end
                    UpdateAllChoices()
                end
            end,
        },
        {
            type = "dropdown",
			name = "List Addons",
			tooltip = "List of all of your non librairies addons.",
			choices = AddonCategory.listAddons,
			default = AddonCategory.listAddons[1],
			getFunc = function() return addon end,
			setFunc = function(selected)
				for index, name in ipairs(AddonCategory.listAddons) do
					if name == selected then
						addon = name
					end
				end
			end,
            scrollable = true,
			width = "half",
        },
        {
            type = "dropdown",
			name = "List Categories",
			tooltip = "List of the categories of addons you have.",
			choices = sV.listCategory,
			default = sV.listCategory[1],
			getFunc = function() return category end,
			setFunc = function(selected)
				for index, name in ipairs(sV.listCategory) do
					if name == selected then
						category = name
					end
				end
			end,
            scrollable = true,
			width = "half",
            reference = "Categories_dropdown",
        },
        {
            type = "button",
            name = "Link Between",
            tooltip = "Link the selected addon with the selected category.",
            func = function()
                if addon ~= nil and category ~= nil then
                    sV[addon] = category
                end
            end,
        },
        {
            type = "divider",
        },
		{
			type = "header",
			name = "Edit Categories",
		},
        {
            type = "dropdown",
			name = "Choose Category",
			tooltip = "Choose a Category to edit it name.",
			choices = sV.listCategory,
			default = sV.listCategory[1],
			getFunc = function() return categoryName end,
			setFunc = function(selected)
				for index, name in ipairs(sV.listCategory) do
					if name == selected then
						categoryName = name
					end
				end
			end,
            scrollable = true,
			width = "half",
            reference = "CategoriesName_dropdown",
        },
        {
            type = "editbox",
            name = "Category New Name",
            tooltip = "Enter here the new category's name you want.",
            getFunc = function() return nil end,
            setFunc = function(newValue) 
                if newValue ~= nil and newValue ~= "" then
                    newCategoryName = newValue
                end
            end,
			width = "half",
        },
        {
            type = "button",
            name = "Change Name",
            tooltip = "Change the name of the selected category to the new one.",
            func = function()
                if categoryName ~= nil and newCategoryName ~= nil then
                    for key, value in pairs(sV.listCategory) do
                        if value == categoryName then 
                            sV.listCategory[key] = newCategoryName
                            break
                        end
                    end
                    for key, value in pairs(AddonCategory.listAddons) do
                        if sV[value] == categoryName then 
                            sV[value] = newCategoryName
                        end
                    end
                    UpdateAllChoices()
                end
            end,
        },
        {
            type = "dropdown",
			name = "Choose Category",
			tooltip = "Choose a Category to change it order.",
			choices = sV.listCategory,
			default = sV.listCategory[1],
			getFunc = function() return categoryOrder end,
			setFunc = function(selected)
				for index, name in ipairs(sV.listCategory) do
					if name == selected then
						categoryOrder = name
					end
				end
			end,
            scrollable = true,
			width = "half",
            reference = "CategoriesOrder_dropdown",
        },
        {
            type = "dropdown",
			name = "New Order",
			tooltip = "Choose a Category to change it order.",
			choices = getArrayCategoriesLength(sV),
			default = getArrayCategoriesLength(sV)[1],
			getFunc = function() return newOrder end,
			setFunc = function(selected)
				for index, name in ipairs(getArrayCategoriesLength(sV)) do
					if name == selected then
						newOrder = name
					end
				end
			end,
            scrollable = true,
			width = "half",
            reference = "NewOrder_dropdown",
        },
        {
            type = "button",
            name = "Change Order",
            tooltip = "Change the order of the selected category to the new one.",
            func = function()
                if categoryOrder ~= nil and newOrder ~= nil then
                    local oldOrder, oldCategory
                    for key, value in pairs(sV.listCategory) do
                        if value == categoryOrder then 
                            oldOrder = key
                        end
                        if key == newOrder then
                            oldCategory = value
                        end
                    end
                    for key, value in pairs(sV.listCategory) do
                        if key == oldOrder then
                            sV.listCategory[key] = oldCategory
                        end
                        if key == newOrder then
                            sV.listCategory[key] = categoryOrder
                        end
                    end
                    UpdateAllChoices()
                end
            end,
        },
	}
	
	LAM2:RegisterOptionControls("AddonCategory_Settings", optionsData)
end