---@type string
local _addonName = select(1, ...);
---@class AddonEnv
local _addon = select(2, ...);

SLASH_SPELLCALC1 = "/sc";
SLASH_SPELLCALC2 = "/spellcalc";

SlashCmdList["SPELLCALC"] = function(arg)
    if arg == "debug" then
        SpellCalc_settings.debug = not SpellCalc_settings.debug;
        _addon.util.PrintWarn("Debug "..(SpellCalc_settings.debug and "active" or "disabled"));
        return;
    end

    if arg == "ub" then
        _addon:UpdatePlayerAuras(true);
        _addon:UpdatePlayerAuras();
        return;
    end

    if string.find(arg, "^tt") then
        local talentOverride = {};

        for tripel in string.gmatch(arg, "%d %d+ %d") do
            local tree, talent, rank = string.match(tripel, "(%d) (%d+) (%d)");

            if tree == nil or talent == nil or rank == nil then
                _addon.util.PrintWarn("tree, talent or rank nil for tripel: "..tripel);
                return;
            end

            local treen = tonumber(tree);
            local talentn = tonumber(talent);
            local rankn = tonumber(rank);

            local name, _, _, _, _, maxRank = GetTalentInfo(treen, talentn);

            if rankn > maxRank then
                _addon.util.PrintWarn("Rank " .. rankn .." invalid! Max rank = " .. maxRank);
                return;
            end

            table.insert(talentOverride, {
                tree = treen,
                talent = talentn,
                rank = rankn
            });

            print("Add talentoverride: "..name.. " "..rankn.."/"..maxRank);
        end

        if #talentOverride == 0 then
            _addon.util.PrintWarn("No talents specified!");
            return;
        end

        _addon:UpdateTalents(talentOverride);

        return;
    end

    if string.find(arg, "ps") then
        local spellId = string.match(arg, "(%d+)");
        if spellId == nil then
            _addon.util.PrintWarn("spellId is nil!");
            return;
        end

        local calcedSpell = _addon:GetCurrentSpellData(tonumber(spellId) or 0);
        if calcedSpell == nil then
            _addon.util.PrintWarn("No current data for spell with ID "..spellId);
            return;
        end

        print("=== Data for spell "..spellId.." ===============");
        _addon.util.PrintTable(calcedSpell);
        print("=========================================");

        return;
    end

    if string.find(arg, "cs") then
        local spellId = string.match(arg, "(%d+)");
        if spellId == nil then
            _addon.util.PrintWarn("spellId is nil!");
            return;
        end

        local calcedSpell = _addon:GetCalcedSpell(tonumber(spellId)--[[@as integer]]);
        if calcedSpell == nil then
            _addon.util.PrintWarn("No data for spell with ID "..spellId);
            return;
        end

        print("=== Data for spell "..spellId.." ===============");
        _addon.util.PrintTable(calcedSpell);
        print("=========================================");

        return;
    end

    if arg == "i" or arg == "info" then
		if SpellCalcStatScreen:IsShown() then
            SpellCalcStatScreen:Hide();
        else
            SpellCalcStatScreen:Show();
        end
		return;
    end

    if string.find(arg, "dii") then
        local iid, slotid = strmatch(arg, "(%d+) (%d+)");
        if iid and slotid then
            _addon.util.PrintWarn("Debug equip item "..iid.." into slot "..slotid.."!");
            _addon:DebugEquipItem(tonumber(iid)--[[@as integer]], tonumber(slotid)--[[@as integer]]);
        end
        return;
    end

    if string.find(arg, "dis") then
        local slotid, itemLink = strmatch(arg, "(%d+) (.+)");
        print(slotid, itemLink);
        if itemLink and slotid then
            local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?");
            _addon.util.PrintWarn("Debug equip item "..Id.." into slot "..slotid.."!");
            _addon:DebugEquipItem(tonumber(Id)--[[@as integer]], tonumber(slotid)--[[@as integer]]);
        end
        return;
    end

    if string.find(arg, "dab") then
        local spellId = strmatch(arg, "(%d+)");
        if spellId then
            _addon:DebugApplyBuff(tonumber(spellId) or 0);
        end
        return;
    end

    if string.find(arg, "dsbf") then
        local flags = strmatch(arg, "(%d+)");
        local remove = string.find(arg, "-");
        local flag = tonumber(flags)--[[@as integer]];
        if flag then
            if remove then
                _addon:RemoveAuraEffect("Debug Flag "..flag, {
                    type = _addon.CONST.EFFECT_TYPE.BOOLEAN_BITFLAG_SET,
                    value = flag,
                }, flag);
            else
                _addon:ApplyAuraEffect("Debug Flag "..flag, {
                    type = _addon.CONST.EFFECT_TYPE.BOOLEAN_BITFLAG_SET,
                    value = flag,
                }, flag);
            end
        end
        return;
    end

    if string.find(arg, "sval") then
        local key = string.sub(arg, 6);
        print(key);
        if key then
            print("Value for ", key, "is", _addon.ScriptEffects.GetValue(key));
        end
        return;
    end

    InterfaceOptionsFrame_OpenToCategory(_addonName);
    InterfaceOptionsFrame_OpenToCategory(_addonName);
end