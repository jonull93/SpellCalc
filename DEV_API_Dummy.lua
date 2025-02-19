---@diagnostic disable: lowercase-global
SlashCmdList = {}
UIParent = CreateFrame("");
WorldFrame = CreateFrame("");

local function SetScript(self, eventName, func) end

GameTooltip = {
    SetOwner = function(self, frame, anchor) end,
    SetText = function(self, text, a, r, g, b, wrap) end,
    AddLine = function(self, text, red, green, blue) end,
    AddDoubleLine = function(self, textL, textR, rL, gL, bL, rR, gR, bR) end,
    SetScript = SetScript,
}

AceGUIWidgetLSMlists = {font={}};

bit = {
    band = function(arg1, arg2) return 0 end,
}

LE_ITEM_CLASS_WEAPON = 2;

--- mhBase, mhMod, ohBase, ohMod
function UnitAttackBothHands(unit)
    return 1, 1, 1, 1;
end

-- base, mod
function UnitRangedAttack(unit)
    return 1, 1;
end

---Get the itemLink for the specified item.
---@param unit string
---@param slotId number
---@return string itemLink
function GetInventoryItemLink(unit, slotId) end

---Get Rank or whatever of spell.
---@param spellId number
---@return string subtext
function GetSpellSubtext(spellId) end


---Unit damage returns information about your current damage stats.
---@param unit string
---@return number lowDmg
---@return number hiDmg
---@return number offlowDmg
---@return number offhiDmg
---@return number posBuff
---@return number negBuff
---@return number percentmod
function UnitDamage(unit) end

---Returns the unit's ranged damage and speed. 
---@param unit string
---@return number speed
---@return number lowDmg
---@return number hiDmg
---@return number posBuff
---@return number negBuff
---@return number percentmod
function UnitRangedDamage(unit) end

--- as percent
function GetCritChance()
    return 2.5;
end

--- as percent
function GetRangedCritChance()
    return 2.5;
end

--- classLoc, class
function UnitClass(unit)
    return "Localized", "ENGLISH";
end

function GetAddOnMetadata(addonName, metaKey)
    return "value";
end

--- UNIX timestamp
function time()
    return 123;
end

-- ms since start
function debugprofilestop()
    return 123;
end

--- Splits a string using a delimiter (optionally: into a specified number of pieces)
---@param delimiter string
---@param subject string
---@param pieces number|nil
function strsplit(delimiter, subject, pieces)
    return "","","","","","","","","","";
end


---@param self WoWFrame
---@param point string
---@param relativeFrame WoWFrame
---@param relativePoint string
---@param ofsx number
---@param ofsy number
---@overload fun(self:WoWFrame, point:string, relativeFrame:WoWFrame, relativePoint:string): boolean
---@overload fun(self:WoWFrame, point:string, ofsx:number, ofsy:number): boolean
local function SetPointDummy(self, point, relativeFrame, relativePoint, ofsx, ofsy) end

---@class WoWFrame
---@field GetParent fun(self:WoWFrame):WoWFrame|nil
---@field SetWidth fun(self:WoWFrame, w:number):nil
---@field SetHeight fun(self:WoWFrame, h:number):nil
---@field GetWidth fun(self:WoWFrame):number
---@field GetHeight fun(self:WoWFrame):number
---@field SetClampedToScreen fun(self:WoWFrame, enable:boolean):nil
---@field SetMovable fun(self:WoWFrame, enable:boolean):nil
---@field EnableMouse fun(self:WoWFrame, enable:boolean):nil
---@field RegisterForDrag fun(self:WoWFrame, button:string):nil
---@field SetScript fun(self:WoWFrame, handler:string, callback:nil|fun(frame:WoWFrame, ...)):nil
---@field Show fun(self:WoWFrame):nil
---@field Hide fun(self:WoWFrame):nil
---@field SetBackdrop fun(self:WoWFrame, def:table):nil
---@field SetBackdropColor fun(self:WoWFrame, red:number, green:number, blue:number, alpha:number):nil
---@field UnregisterEvent fun(self:WoWFrame, event:string):nil
---@field RegisterEvent fun(self:WoWFrame, event:string):nil
---@field StartMoving any
---@field StopMovingOrSizing any
---@field SetClipsChildren fun(self:WoWFrame, enable:boolean):nil
---@field ScrollBar WoWFrame
---@field SetSize fun(self:WoWFrame, w:number, h:number):nil
---@field SetScrollChild fun(self:WoWFrame, child:WoWFrame):nil
---@field ClearAllPoints fun(self:WoWFrame):nil
---@field CreateFontString fun(self:WoWFrame, name:string|nil, layer:any, inherits: any):FontString
local WoWFrameDummy = {
    SetPoint = SetPointDummy
}

---@class WoWGameTooltip : WoWFrame
---@field SetOwner fun(self:WoWFrame, owner:WoWFrame, anchor:string):nil
---@field AddFontStrings fun(self:WoWFrame, ...:FontString):nil
---@field ClearLines fun(self:WoWFrame):nil
---@field NumLines fun(self:WoWFrame):integer
---@field SetHyperlink fun(self:WoWFrame, hl:string):nil

---@class FontString : WoWFrame
---@field SetText fun(self:WoWFrame, t:string):nil
---@field GetText fun(self:WoWFrame):string
---@field SetJustifyH fun(self:WoWFrame, j:string):nil
---@field SetWordWrap fun(self:WoWFrame, w:boolean):nil
---@field GetStringHeight fun(self:WoWFrame):number
---@field SetTextColor fun(self:WoWFrame, r:number, g:number, b:number):nil
---@field SetFont fun(self:WoWFrame, path:string, height:number, flags:string|nil);
local FontStringDummy = {

}

---Creates a Frame object. 
---@param frameType string Type of the frame; e.g. "Frame" or "Button".
---@param frameName string|nil
---@param parentFrame WoWFrame|nil
---@param inheritsFrame string|nil
---@return WoWFrame
function CreateFrame(frameType, frameName, parentFrame, inheritsFrame) end

--- name, rank, icon, castTime, minRange, maxRange 
function GetSpellInfo(spellId_spellName_spellLink)
    return "name", "rank", "icon", 1, 1, 1;
end

function UIDropDownMenu_SetWidth(dropDown, width) end
function UIDropDownMenu_Initialize(dropDown, initFunc) end
function UIDropDownMenu_CreateInfo()
    return {
        arg1 = "",
        arg2 = "",
        checked = false,
        func = function() end,
        text = "",
    }
end
function UIDropDownMenu_SetText(self, text) end
--- See UIDropDownMenu_CreateInfo
function UIDropDownMenu_AddButton(buttonInfo) end

function hooksecurefunc(table, key, func) end

--- actionType, actionId
function GetActionInfo(slot)
    return "type", 123
end

function GetMacroSpell(actionId)
    return 123;
end

function  UnitName(unit)
    return "name";
end

function UnitLevel(unit)
    return 1;
end

function UnitIsPlayer(unit)
    return true;
end

function GetSpellBonusDamage(schoolNum)
    return 123;
end

function GetSpellBonusHealing()
    return 123;
end

--- as percent
function GetSpellCritChance(schoolNum)
    return 123;
end

---Get attack power.
---@param unit string
---@return number base The unit's base attack power
---@return number posBuff The total effect of positive buffs to attack power.
---@return number negBuff The total effect of negative buffs to the attack power (a negative number)
function UnitAttackPower(unit) end

---Get ranged attack power.
---@param unit string
---@return number base The unit's base ranged attack power (seems to give a positive number even if no ranged weapon equipped)
---@return number posBuff The total effect of positive buffs to ranged attack power.
---@return number negBuff The total effect of negative buffs to the ranged attack power (a negative number)
function UnitRangedAttackPower(unit) end

---Get melee haste.
---@return number haste in percent.
function GetHaste() end

---Get ranged haste.
---@return number haste in percent.
function GetRangedHaste() end

---Get blovk value.
---@return number
function GetShieldBlock() end

---Gets the player's current mana regeneration rates (in mana per 1 seconds). 
---@return number base @Full regen while outside the fsr
---@return number casting @Regen from mp5 and uninterrupted spirit/int regen
function GetManaRegen() end

function UnitPowerMax(unit, powerType)
    return 123;
end

--- mainhand, offhand
function UnitAttackSpeed(unit)
    return 1.5, 1.2;
end

--- Returns information about an item. 
---@param itemID_itemString_itemName_itemLink string|number @ItemLink, Name or ID
---@return string itemName
---@return string itemLink
---@return integer itemQuality
---@return number itemLevel
---@return number itemMinLevel
---@return string itemType
---@return string itemSubType
---@return number itemStackCount
---@return string itemEquipLoc
---@return number itemTexture
---@return number sellPrice
---@return integer classID
---@return integer subclassID
---@return integer bindType
---@return integer expacID
---@return integer setID
---@return boolean isCraftingReagent
function GetItemInfo(itemID_itemString_itemName_itemLink) end

function GetInventoryItemID(unit, slot)
    return 123;
end

function GetInventoryItemDurability(slot)
    return 123;
end

---Returns information about a specified talent in a specified tab. 
---@param tree any
---@param talent any
---@return string name
---@return string icon
---@return integer tier
---@return integer column
---@return integer currentRank
---@return integer maxRank
function GetTalentInfo(tree, talent) end

---Returns the buffs/debuffs for the unit.
---@param unit string
---@param index number
---@param filter string|nil What auras to iterate (HELPFUL, HARMFUL), defaults to HELPFUL.
---@return string name The localized name of the aura, otherwise nil if there is no aura for the index.
---@return integer icon FileID - The icon texture.
---@return integer count The amount of stacks, otherwise 0.
---@return string|nil dispelType The locale-independent magic type of the aura: Curse, Disease, Magic, Poison, otherwise nil.
---@return number duration The full duration of the aura in seconds.
---@return number expirationTime Time the aura expires compared to GetTime(), e.g. to get the remaining duration: expirationtime - GetTime()
---@return string source The unit that applied the aura.
---@return boolean isStealable If the aura may be stolen.
---@return boolean nameplateShowPersonal If the aura should be shown on the player/pet/vehicle nameplate.
---@return integer spellId The spell ID for e.g. GetSpellInfo()
---@return boolean canApplyAura If the player can apply the aura.
---@return boolean isBossDebuff If the aura was cast by a boss.
---@return boolean castByPlayer If the aura was applied by a player.
---@return boolean nameplateShowAll If the aura should be shown on nameplates.
---@return number timeMod The scaling factor used for displaying time left.
function UnitAura(unit, index, filter) end

--- name, _, count, _, _, _, _, _, _, spellId
function UnitBuff(unit, i)
    return "name", "_", 1, "_", "_", "_", "_", "_", "_", 123;
end

--- Wipe table
function wipe(table) end

function GetLocale()
    return "enUS";
end

--- localized, english
function UnitRace(unit)
    return "localized", "English";
end

---Returns info about one of the unit's stats (strength, agility, stamina, intellect, spirit). 
---@param unit string
---@param statID number
---@return number base @The unit's base stat.
---@return number stat @The unit's current stat.
---@return number posBuff @Any positive buffs applied to the stat.
---@return number negBuff @Any negative buffs applied to the stat.
function UnitStat(unit, statID) end

---@class SpellPowerEntry
local SpellPowerEntry = {
    hasRequiredAura = true,
    ---@type PowerType
    type = 1,
    name = "name",
    cost = 1,
    minCost = 0,
    requiredAuraID = 0,
    costPercent = 0,
    costPerSec = 0
}

---@return table<number,SpellPowerEntry>
function GetSpellPowerCost(spellName_spellID) end

function GetShapeshiftForm()
    return 0;
end

function GetRealmName()
    return "";
end

---@param libName string
---@return table
function LibStub(libName) end

Bartender4 = {}

Bartender4DB = {
    namespaces = {},
    profileKeys = {},
}

DominosDB = {
    profileKeys = {},
    profiles = {},
}

ElvUISpellBookTooltip = {};

ElvDB = {
    profileKeys = {},
    profiles = {},
}

--- initpos is optional. Returns the matched substring(s) found within string. Multiple return values can occur.
function strmatch(string, pattern, initpos)
    return "", "", "", "";
end

--- icon, active, castable, spellId
function GetShapeshiftFormInfo(index)
    return "", true, true, 1;
end

function GetHitModifier()
    return 1;
end

function GetSpellHitModifier()
    return 1;
end

CR_WEAPON_SKILL = 1;
CR_DEFENSE_SKILL = 2;
CR_DODGE = 3;
CR_PARRY = 4;
CR_BLOCK = 5;
CR_HIT_MELEE = 6;
CR_HIT_RANGED = 7;
CR_HIT_SPELL = 8;
CR_CRIT_MELEE = 9;
CR_CRIT_RANGED = 10;
CR_CRIT_SPELL = 11;
CR_MULTISTRIKE = 12;
CR_READINESS = 13;
CR_SPEED = 14;
COMBAT_RATING_RESILIENCE_CRIT_TAKEN = 15;
COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN = 16;
CR_LIFESTEAL = 17;
CR_HASTE_MELEE = 18;
CR_HASTE_RANGED = 19;
CR_HASTE_SPELL = 20;
CR_AVOIDANCE = 21;
CR_WEAPON_SKILL_OFFHAND = 22;
CR_WEAPON_SKILL_RANGED = 23;
CR_EXPERTISE = 24;
CR_ARMOR_PENETRATION = 25;
CR_MASTERY = 26;
CR_PVP_POWER = 27;
CR_VERSATILITY_DAMAGE_DONE = 29;
CR_VERSATILITY_DAMAGE_TAKEN = 31;

---Returns the bonus, in percent (or other converted units, such as skill points), of a specific combat rating for the player.
---@param combatRatingId number
---@return number bonusPct
function GetCombatRatingBonus(combatRatingId)
end

--- Returns the current power of the specified unit.
---@param unitId string
---@param powerType number @Type of resource (mana/rage/energy/etc) to query
---@param unmodified boolean|nil @Return the higher precision internal value (for graphical use only)
---@return number
function UnitPower(unitId, powerType, unmodified)
    return 1;
end

--- Returns the GUID of the specified unit.
---@param unitId string
---@return string
function UnitGUID(unitId)
    return "Creature-0-1133-870-141-71953-0000432FBD";
end

--- Returns the creature type of the specified unit.
---@param unitId string
---@return string
function UnitCreatureType(unitId)
    return "Beast";
end

function InterfaceOptionsFrame_OpenToCategory(panelName) end
function InterfaceOptions_AddCategory(frame) end
InterfaceOptionsFrameAddOns = {};
function OptionsListButtonToggle_OnClick() end
function ChatConfigFrame_PlayCheckboxSound() end
function EditBox_ClearFocus() end
function GameTooltip_Hide() end

function GetWeaponEnchantInfo()
    return true, 1, 1, 1, true, 1, 1, 1;
end

---Returns information on a glyph socket. 
---@param socketID number glyph [Glyph SocketID|socket index]] (1 to GetNumGlyphSockets() )
---@param talentGroup number|nil (dual) specialization index (1 to GetNumTalentGroups(...)).
---@return boolean enabled
---@return integer type
---@return integer spellId
---@return string icon
function GetGlyphSocketInfo(socketID, talentGroup) end

---@return number
function GetNumGlyphSockets() end

C_Timer = {
    ---@param delay number Delay in seconds.
    ---@param callback fun():nil
    After = function(delay, callback) end
}

---@return number expertise
---@return number offhandExpertise
function GetExpertise() end

---Returns the percentage of target's armory your physical attacks ignore due to armor penetration. 
---@return number armorPenPct
function GetArmorPenetration() end

---Retrieves the number of combo points gained by a player. 
---@param unit "player"|"vehicle"
---@param target "target"
---@return integer
function GetComboPoints(unit, target) end

---Are 2 units the same?
---@param unit1 string
---@param unit2 string
---@return boolean
function UnitIsUnit(unit1, unit2) end

---Retrieves information about a specific SpellBook item 
---@param entryName string
---@return string skillType The type of the spell (known values: "SPELL", "PETACTION", "FUTURESPELL", "FLYOUT")
---@return integer contextualID For SPELL and FUTURESPELL this is the spellID. For PetAction is it an integer value that is troublesome to use outside of two functions related solely to the PetBarUI. For Flyout, it is the FlyoutID.
function GetSpellBookItemInfo(entryName) end

---@param delim string
---@param str string
---@return string[]
function strsplittable(delim, str) end

---@type string
WOW_PROJECT_ID = ""
WOW_PROJECT_CLASSIC = "CLASSIC";
WOW_PROJECT_WRATH_CLASSIC = "WRATH";

---@param spellID integer
---@param isPetSpell boolean|nil if true, will check if the currently active pet knows the spell; if false or omitted, will check if the player knows the spell
---@return boolean
function IsSpellKnown(spellID, isPetSpell) end

---@param spellID integer
---@return integer|nil
function FindBaseSpellByID(spellID) end

---@param spellID integer
---@return integer|nil
function FindSpellOverrideByID(spellID) end

---@param spellID integer
---@return boolean
function IsPlayerSpell(spellID) end
