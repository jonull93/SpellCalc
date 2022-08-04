---@class AddonEnv
local _addon = select(2, ...);

local SPELL_EFFECT_FLAGS = _addon.SPELL_EFFECT_FLAGS;
local NewCalcedSpell = _addon.NewCalcedSpell;
local SCHOOL = _addon.SCHOOL;
local DEF_TYPE = _addon.DEF_TYPE;
local SPELL_EFFECT_TYPES = _addon.SPELL_EFFECT_TYPES;
local EFFECT_TYPE = _addon.EFFECT_TYPE;
local AURA_TYPES = _addon.SPELL_AURA_TYPES;
---@type table<number, CalcedSpell>
local calcedSpells = {};
local currentState = 1;
local stats = _addon.stats;
local meleeCalc = _addon.MeleeCalc:New();
local magicCalc = _addon.MagicCalc:New();
local costHandler = _addon.CostHandler;
local scriptEffects = _addon.ScriptEffects;

-- If a seal is currently active this will be the spell that should be used for Judgement.
---@type integer|nil
_addon.judgementSpell = nil;

-- Not to self: This annotation doesn't really work for this purpose anyways, see function call for parameters...
---@type table<number, EffectHandler>
local effectHandler = {};
_addon.effectHandler = effectHandler;

--- Is effect type a heal effect
---@param effectType number
---@param auraType number|nil
local function IsHealEffect(effectType, auraType)
    if (effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_APPLY_AURA and auraType == AURA_TYPES.SPELL_AURA_PERIODIC_HEAL)
    or (effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_APPLY_AREA_AURA_PARTY and auraType == AURA_TYPES.SPELL_AURA_PERIODIC_HEAL)
    or effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_HEAL then
        return true;
    end
    return false;
end

--- Is effect type an absorb effect
---@param effectType number
---@param auraType number|nil
local function IsAbsorbEffect(effectType, auraType)
    if effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_APPLY_AURA then
        if auraType == AURA_TYPES.SPELL_AURA_MANA_SHIELD
        or auraType == AURA_TYPES.SPELL_AURA_SCHOOL_ABSORB then
            return true;
        end
    end
    return false;
end

--- Is effect type a duration effect
---@param effectType number
---@param auraType number|nil
local function IsDurationEffect(effectType, auraType)
    if effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_APPLY_AURA
    or effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_APPLY_AREA_AURA_PARTY
    or effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_PERSISTENT_AREA_AURA then
        if auraType == AURA_TYPES.SPELL_AURA_PERIODIC_DAMAGE 
        or auraType == AURA_TYPES.SPELL_AURA_PERIODIC_HEAL 
        or auraType == AURA_TYPES.SPELL_AURA_PERIODIC_LEECH 
        or auraType == AURA_TYPES.SPELL_AURA_PERIODIC_TRIGGER_SPELL then
            return true;
        end
    end
    return false;
end

--- Is effect type a damage shield effect (actual dmg shields and stuff like shadowguard)
---@param effectType number
---@param auraType number|nil
local function IsDmgShieldEffect(effectType, auraType)
    if effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_APPLY_AURA
    or effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_APPLY_AREA_AURA_PARTY then
        if auraType == AURA_TYPES.SPELL_AURA_DAMAGE_SHIELD
        or auraType == AURA_TYPES.SPELL_AURA_PROC_TRIGGER_DAMAGE then
            return true;
        end
    end
    return false;
end

--- Generate effect modifiers (baseMod, bonusMod)
---@param school number
---@param isDmg boolean
---@param isHeal boolean
---@param spellId number
---@param calcedSpell CalcedSpell
---@param isDuration boolean
---@param ri SpellRankInfo
---@param effNum number
local function SetBaseModifiers(school, isDmg, isHeal, spellId, calcedSpell, isDuration, ri, effNum)
    local bonusMod = 1;
    local baseMod = 1;

    if isDmg then
        if stats.spellModPctEffect[spellId] ~= nil then
            baseMod = baseMod * (100 + stats.spellModPctEffect[spellId].val) / 100;
            calcedSpell:AddToBuffList(stats.spellModPctEffect[spellId].buffs);
        end

        if not isDuration then
            if stats.spellModPctDamageHealing[spellId] ~= nil then
                bonusMod = bonusMod * (100 + stats.spellModPctDamageHealing[spellId].val) / 100;
                calcedSpell:AddToBuffList(stats.spellModPctDamageHealing[spellId].buffs);
            end
        else
            if stats.spellModPctDoTHoT[spellId] ~= nil then
                bonusMod = bonusMod * (100 + stats.spellModPctDoTHoT[spellId].val) / 100;
                calcedSpell:AddToBuffList(stats.spellModPctDoTHoT[spellId].buffs);
            end
        end

        bonusMod = bonusMod * (100 + stats.schoolModPctDamage[school].val) / 100;
        calcedSpell:AddToBuffList(stats.schoolModPctDamage[school].buffs);

        if stats.versusModPctDamage[_addon.Target.creatureType] then
            bonusMod = bonusMod * (100 + stats.versusModPctDamage[_addon.Target.creatureType].val) / 100;
            calcedSpell:AddToBuffList(stats.versusModPctDamage[_addon.Target.creatureType].buffs);
        end

        if stats.targetSchoolModDamageTaken[school].val ~= 0 then
            bonusMod = bonusMod * (100 + stats.targetSchoolModDamageTaken[school].val) / 100;
            calcedSpell:AddToBuffList(stats.targetSchoolModDamageTaken[school].buffs);
        end

        if ri.mechanic and stats.targetMechanicModDmgTakenPct[ri.mechanic].val ~= 0 then
            local t = stats.targetMechanicModDmgTakenPct[ri.mechanic];
            bonusMod = bonusMod * (1 + t.val / 100);
            calcedSpell:AddToBuffList(t.buffs);
        end
    else
        -- TODO: Improved PW:S increase bonus as well, Aplify Curse doesn't, any other uses of this for scaling spells to check?
        if stats.spellModPctEffect[spellId] ~= nil then
            bonusMod = bonusMod * (100 + stats.spellModPctEffect[spellId].val) / 100;
            calcedSpell:AddToBuffList(stats.spellModPctEffect[spellId].buffs);
        end

        if isHeal then
            if not isDuration then
                if stats.spellModPctDamageHealing[spellId] ~= nil then
                    bonusMod = bonusMod * (100 + stats.spellModPctDamageHealing[spellId].val) / 100;
                    calcedSpell:AddToBuffList(stats.spellModPctDamageHealing[spellId].buffs);
                end
            else
                if stats.spellModPctDoTHoT[spellId] ~= nil then
                    bonusMod = bonusMod * (100 + stats.spellModPctDoTHoT[spellId].val) / 100;
                    calcedSpell:AddToBuffList(stats.spellModPctDoTHoT[spellId].buffs);
                end
            end

            bonusMod = bonusMod * (100 + stats.modhealingDone.val) / 100;
            calcedSpell:AddToBuffList(stats.modhealingDone.buffs);

            if stats.targetHealingRecieved.val ~= 0 then
                bonusMod = bonusMod * (1 + stats.targetHealingRecieved.val / 100);
                calcedSpell:AddToBuffList(stats.targetHealingRecieved.buffs);
            end
        end
    end

    local ce = calcedSpell[effNum];
    ce.modBase = baseMod;
    ce.modBonus = bonusMod;
    scriptEffects.DoSpell(EFFECT_TYPE.SCRIPT_SPELLMOD_DONE_PCT, calcedSpell, ce, spellId, ri);
    ce.modBase = ce.modBase * ce.modBonus;

    _addon:PrintDebug("Basemod: "..ce.modBase..", Bonusmod: "..ce.modBonus);
end

--- Get effective mana pool
function _addon:GetEffectiveManaPool()
    local mana = SpellCalc_settings.useCurrentPowerLevel and stats.manaCurrent or stats.manaMax;

    if SpellCalc_settings.calcEffManaRune then
        mana = mana + 1200;
    end

    if SpellCalc_settings.calcEffManaPotionTypeNew ~= "NONE" then
        local potVal = 0;
        if SpellCalc_settings.calcEffManaPotionTypeNew == "MAJOR" then
            potVal = 1800;
        elseif SpellCalc_settings.calcEffManaPotionTypeNew == "GREATER" then
            potVal = 800;
        elseif SpellCalc_settings.calcEffManaPotionTypeNew == "SUPERIOR" then
            potVal = 1200;
        elseif SpellCalc_settings.calcEffManaPotionTypeNew == "SUPER" then
            potVal = 2400;
        end
        mana = mana + potVal;
    end

    if SpellCalc_settings.calcEffManaInnervate then
        -- Regen in 5sec rule is already accounted for in effective mana cost, we can't add it again here!
        mana = mana + stats.manaRegBase * 100 - stats.manaRegCasting * 20;
    end

    return mana;
end

--- Calculate spell values with current stats
---@param spellId number
---@param calcedSpell CalcedSpell|nil
---@param parentSpellData CalcedSpell|nil
---@param parentEffCastTime number|nil
---@return CalcedSpell
local function CalcSpell(spellId, calcedSpell, parentSpellData, parentEffCastTime)
    local spellName, _, _, castTime = GetSpellInfo(spellId);
    _addon:PrintDebug("Calculating spell " .. spellId .. " " .. spellName);
    local effCastTime = parentEffCastTime or 0;
    local spellRankInfo = _addon.spellRankInfo[spellId];
    local GCD = spellRankInfo.GCD or 1.5;
    local costs;
    local spellCost = 0;
    local costType;

    if spellId == _addon.judgementSpell then
        costs = GetSpellPowerCost(_addon.JUDGEMENT_ID);
    else
        costs = GetSpellPowerCost(spellId);
    end

    -- TODO: This will need a change for spells with multiple costs, e.g. combo spells!
    if costs and #costs > 0 then
        ---@type SpellPowerEntry
        local entry = costs[1];
        spellCost = entry.cost;
        costType = entry.type;
    end

    --------------------------
    -- Calculation objects

    if calcedSpell == nil then
        local effectFlags = {};

        for i = 1, 2, 1 do
            if spellRankInfo.effects[i] == nil then
                effectFlags[i] = nil;
            else
                ---@type SpellRankEffectData
                local red = spellRankInfo.effects[i];
                effectFlags[i] = 0;

                if IsHealEffect(red.effectType, red.auraType) or spellRankInfo.forceHeal then
                    effectFlags[i] = effectFlags[i] + SPELL_EFFECT_FLAGS.HEAL;
                end

                if IsDmgShieldEffect(red.effectType, red.auraType) then
                    effectFlags[i] = effectFlags[i] + SPELL_EFFECT_FLAGS.DMG_SHIELD;
                end

                if IsDurationEffect(red.effectType, red.auraType) then
                    effectFlags[i] = effectFlags[i] + SPELL_EFFECT_FLAGS.DURATION;
                end

                if IsAbsorbEffect(red.effectType, red.auraType) then
                    effectFlags[i] = effectFlags[i] + SPELL_EFFECT_FLAGS.ABSORB;
                end

                if spellRankInfo.isChannel then
                    effectFlags[i] = effectFlags[i] + SPELL_EFFECT_FLAGS.CHANNEL;
                end

                if red.auraType and red.auraType == AURA_TYPES.SPELL_AURA_PERIODIC_TRIGGER_SPELL then
                    effectFlags[i] = effectFlags[i] + SPELL_EFFECT_FLAGS.TRIGGER_SPELL_AURA;
                end

                if red.effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_ATTACK then
                    effectFlags[i] = effectFlags[i] + SPELL_EFFECT_FLAGS.AUTO_ATTACK;
                end

                if red.auraType and red.auraType == AURA_TYPES.SPELL_AURA_DUMMY then
                    effectFlags[i] = effectFlags[i] + SPELL_EFFECT_FLAGS.DUMMY_AURA;
                end

                if red.auraStacks and red.auraStacks > 1 then
                    effectFlags[i] = effectFlags[i] + SPELL_EFFECT_FLAGS.STACKABLE_AURA;
                end

                if red.effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_ENERGIZE_PCT
                or red.auraType and (
                    red.auraType == AURA_TYPES.SPELL_AURA_OBS_MOD_MANA
                    or red.auraType == AURA_TYPES.SPELL_AURA_PERIODIC_ENERGIZE
                ) then
                    effectFlags[i] = effectFlags[i] + SPELL_EFFECT_FLAGS.MANA_RESTORE;
                end

                if red.effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_TRIGGER_SPELL
                or (red.effectType == SPELL_EFFECT_TYPES.SPELL_EFFECT_APPLY_AURA and red.auraType == AURA_TYPES.SPELL_AURA_PROC_TRIGGER_SPELL) then
                    effectFlags[i] = effectFlags[i] + SPELL_EFFECT_FLAGS.TRIGGERED_SPELL;
                end
            end
        end

        _addon:PrintDebug("Has " .. #spellRankInfo.effects .. " effects with flags (" .. effectFlags[1] .. ", " .. tostring(effectFlags[2]) .. ")");
        calcedSpell = NewCalcedSpell(effectFlags, spellRankInfo.effects);
        calcedSpell.school = spellRankInfo.school;
    end

    calcedSpell:ResetBuffList();

    if spellRankInfo.school == SCHOOL.PHYSICAL or spellRankInfo.defType ~= DEF_TYPE.MAGIC then
        meleeCalc:Init(
            calcedSpell,
            false,
            bit.band(calcedSpell[1].effectFlags, SPELL_EFFECT_FLAGS.AUTO_ATTACK) > 0,
            spellRankInfo.defType == DEF_TYPE.RANGED,
            spellRankInfo.cantDogeParryBlock
        );
    end

    if spellRankInfo.school ~= SCHOOL.PHYSICAL or spellRankInfo.defType == DEF_TYPE.MAGIC then
        magicCalc:Init(calcedSpell, spellRankInfo, spellId);
    end

    local hasteMult;
    do
        local _, _, _, cast2000msBase = GetSpellInfo(31);
        hasteMult = cast2000msBase / 2000;
    end

    ----------------------------------------------------------------------------------------------------------------------
    -- Duration

    if spellRankInfo.duration then
        local baseDuration = spellRankInfo.duration;

        if stats.spellModFlatDuration[spellId] ~= nil then
            baseDuration = baseDuration + stats.spellModFlatDuration[spellId].val;
            calcedSpell:AddToBuffList(stats.spellModFlatDuration[spellId].buffs);
        end

        calcedSpell.durationNoHaste = baseDuration;
        calcedSpell.duration = baseDuration;

        if spellRankInfo.usePeriodicHaste
        or stats.spellModAllowDotHaste[spellId] and stats.spellModAllowDotHaste[spellId].val > 0 then
            calcedSpell.duration = calcedSpell.duration * hasteMult;
        end
    end

    ----------------------------------------------------------------------------------------------------------------------
    -- Cast time and GCD

    if parentEffCastTime == nil then
        if stats.spellModGCDms[spellId] ~= nil then
            GCD = GCD + stats.spellModGCDms[spellId].val / 1000;
            calcedSpell:AddToBuffList(stats.spellModGCDms[spellId].buffs);
        end

        GCD = GCD * hasteMult;

        if spellRankInfo.isChannel then
            castTime = calcedSpell.duration;
        else
            castTime = castTime / 1000;
        end
        effCastTime = math.max(GCD, castTime);
    end

    ----------------------------------------------------------------------------------------------------------------------
    -- Crit

    if spellRankInfo.defType ~= DEF_TYPE.MAGIC then
        calcedSpell.critMult = 2;
        calcedSpell.critChance = meleeCalc:GetCrit();
    else
        calcedSpell.critMult = 1.5;
        calcedSpell.critChance = magicCalc:GetSchoolCritChance();
    end

    if calcedSpell.critChance > 0 and stats.spellModFlatCritChance[spellId] ~= nil then
        calcedSpell.critChance = calcedSpell.critChance + stats.spellModFlatCritChance[spellId].val;
        calcedSpell:AddToBuffList(stats.spellModFlatCritChance[spellId].buffs);
    end

    scriptEffects.DoSpell(EFFECT_TYPE.SCRIPT_SPELLMOD_CRIT_CHANCE, calcedSpell, nil, spellId, spellRankInfo);

    if calcedSpell.critChance > 100 then
        calcedSpell.critChance = 100;
    end

    if stats.schoolCritBaseMult[spellRankInfo.school].val > 0 and bit.band(calcedSpell[1].effectFlags, SPELL_EFFECT_FLAGS.HEAL + SPELL_EFFECT_FLAGS.ABSORB) == 0 then
        calcedSpell.critMult = calcedSpell.critMult * (1 + stats.schoolCritBaseMult[spellRankInfo.school].val/100);
        calcedSpell:AddToBuffList(stats.schoolCritBaseMult[spellRankInfo.school].buffs);
    end

    local cmbonus = calcedSpell.critMult - 1;

    if stats.schoolModPctCritMult[spellRankInfo.school].val > 0 then
        calcedSpell.critMult = calcedSpell.critMult + cmbonus * stats.schoolModPctCritMult[spellRankInfo.school].val/100;
        calcedSpell:AddToBuffList(stats.schoolModPctCritMult[spellRankInfo.school].buffs);
    end

    if stats.spellModPctCritMult[spellId] ~= nil then
        calcedSpell.critMult = calcedSpell.critMult + cmbonus * stats.spellModPctCritMult[spellId].val/100;
        calcedSpell:AddToBuffList(stats.spellModPctCritMult[spellId].buffs);
    end

    -- TODO: ?????
    if stats.versusModPctCritDamage[_addon.Target.creatureType] then
        calcedSpell.critMult = calcedSpell.critMult + stats.versusModPctCritDamage[_addon.Target.creatureType].val / 100;
        calcedSpell:AddToBuffList(stats.versusModPctCritDamage[_addon.Target.creatureType].buffs);
    end

    if bit.band(calcedSpell[1].effectFlags, SPELL_EFFECT_FLAGS.HEAL) > 0 and stats.modCriticalHealing.val ~= 0 then
        calcedSpell.critMult = calcedSpell.critMult + stats.modCriticalHealing.val / 100;
        calcedSpell:AddToBuffList(stats.modCriticalHealing.buffs);
    end

    if spellRankInfo.noCrit then
        calcedSpell.critChance = 0;
    end

    ----------------------------------------------------------------------------------------------------------------------
    -- Mitigation

    if spellRankInfo.school == SCHOOL.PHYSICAL then
        local mitigtation, armor = meleeCalc:GetArmorDR();
        calcedSpell.avgResist = mitigtation;
        calcedSpell.resistance = armor;
    else
        local avgResist, baseRes, pen, levelRes = magicCalc:GetAvgResist();
        calcedSpell.avgResist = avgResist;
        calcedSpell.resistance = baseRes;
        calcedSpell.resistancePen = pen;
        calcedSpell.resistanceFromLevel = levelRes;
    end

    if bit.band(calcedSpell[1].effectFlags, SPELL_EFFECT_FLAGS.HEAL) == 0 then
        if spellRankInfo.defType == DEF_TYPE.MAGIC then
            local full, base, bonus, binaryLoss = magicCalc:GetHitChances(calcedSpell.avgResist);
            calcedSpell.hitChance = full;
            calcedSpell.hitChanceBase = base;
            calcedSpell.hitChanceBonus = bonus;
            if binaryLoss then
                calcedSpell.hitChanceBinaryLoss = binaryLoss;
            end
        elseif spellRankInfo.defType == DEF_TYPE.MELEE then
            local hit, dodge, parry, glancing, block, hitBonus, glancingDmg = meleeCalc:GetMDPGB();
            calcedSpell.hitChance = math.min(100, hit + hitBonus);
            calcedSpell.hitChanceBase = hit;
            calcedSpell.hitChanceBonus = hitBonus;

            calcedSpell.meleeMitigation = {
                dodge = dodge,
                parry = parry,
                block = block,
                glancing = 0,
                glancingDmg = 0,
            };

            if glancing and glancing > 0 then
                calcedSpell.meleeMitigation.glancing = glancing;
                calcedSpell.meleeMitigation.glancingDmg = glancingDmg;
            end
        elseif spellRankInfo.defType == DEF_TYPE.RANGED then
            local hit, _, _, _, block, hitBonus = meleeCalc:GetMDPGB();
            calcedSpell.hitChance = math.min(100, hit + hitBonus);
            calcedSpell.hitChanceBase = hit;
            calcedSpell.hitChanceBonus = hitBonus;

            calcedSpell.meleeMitigation = {
                dodge = 0,
                parry = 0,
                block = block,
                glancing = 0,
                glancingDmg = 0,
            };
        else
            calcedSpell.hitChance = 100;
            calcedSpell.hitChanceBase = 100;
        end
    end

    ----------------------------------------------------------------------------------------------------------------------
    -- Offhand part, just hacky auto attack for now

    if bit.band(calcedSpell[1].effectFlags, SPELL_EFFECT_FLAGS.AUTO_ATTACK) > 0
    and _addon:IsDualWieldEquipped() then

        if calcedSpell[1].offhandAttack == nil then
            calcedSpell[1].offhandAttack = {
                critChance = 0,
                hitChance = -1,
                hitChanceBase = -1,
                hitChanceBonus = 0,
                meleeMitigation = nil,

                min = 0,
                max = 0,
                avg = 0,
                minCrit = 0,
                maxCrit = 0,
                avgCrit = 0,
                avgCombined = 0,
                avgAfterMitigation = 0,
                perSec = 0,
            };
        end

        local ohd = calcedSpell[1].offhandAttack;
        assert(ohd, spellName + " is dual wield but offhand table is missing!");

        meleeCalc:Init(calcedSpell, true, bit.band(calcedSpell[1].effectFlags, SPELL_EFFECT_FLAGS.AUTO_ATTACK) > 0, false, false);
        local hit, dodge, parry, glancing, block, hitBonus, glancingDmg = meleeCalc:GetMDPGB();

        ohd.hitChance = math.min(100, hit + hitBonus);
        ohd.hitChanceBase = hit;
        ohd.hitChanceBonus = hitBonus;

        ohd.meleeMitigation = {
            dodge = dodge,
            parry = parry,
            block = block,
            glancing = 0,
            glancingDmg = 0,
        };

        if glancing and glancing > 0 then
            ohd.meleeMitigation.glancing = glancing;
            ohd.meleeMitigation.glancingDmg = glancingDmg;
        end

        ohd.critChance = meleeCalc:GetCrit();
    end

    --------------------------
    -- Cast time mods

    if parentEffCastTime == nil then
        if stats.spellModMageNWR[spellId] ~= nil and stats.spellModMageNWR[spellId].val ~= 0 and castTime > 0 then
            -- E.g. with a 10% chance every 10th cast will proc, causing the next to be 1.5s (GCD).
            -- NWR has a 10sec ICD, therefore 1 instant + floor(8.5/castTime) casts can't proc it after a proc.
            -- So in reality you have 10 normal casts, 1 GCD and floor(8.5/castTime) additional normal casts.
            -- The effective cast time is then (10*castTime + 1.5 + floor(8.5/castTime)*castTime)/(10 + floor(8.5/castTime) + 1)
            local castsInICD = math.floor(8.5/effCastTime);
            effCastTime = (GCD + (10 + castsInICD) * effCastTime) / (11 + castsInICD);
            effCastTime = math.max(effCastTime, GCD);
            calcedSpell:AddToBuffList(stats.spellModMageNWR[spellId].buffs);
        end
    end

    ----------------------------------------------------------------------------------------------------------------------
    -- Cost

    if parentSpellData == nil then
        calcedSpell.baseCost = spellCost;
        calcedSpell.effectiveCost = spellCost;

        if costType == 0 then -- mana
            costHandler.Mana(calcedSpell, spellRankInfo, effCastTime, spellName, spellId);
        elseif costType == 1 then -- rage
            -- TODO: rage (on next melee, proc on crit etc.)
        elseif costType == 3 then -- energy
            -- TODO: energy??
        end

        -- Prevent div by 0 in case the spell has simply no cost at all
        if calcedSpell.effectiveCost == 0 then
            calcedSpell.effectiveCost = -1;
        end
    else
        calcedSpell.baseCost = parentSpellData.baseCost;
        calcedSpell.effectiveCost = parentSpellData.effectiveCost;
    end

    --------------------------
    -- Flat mods

    local flatMod = 0;
    if stats.spellModFlatValue[spellId] ~= nil then
        flatMod = stats.spellModFlatValue[spellId].val;
        calcedSpell:AddToBuffList(stats.spellModFlatValue[spellId].buffs);
    end

    local extraSp = 0;
    if stats.spellModFlatSpellpower[spellId] ~= nil then
        extraSp = stats.spellModFlatSpellpower[spellId].val;
        calcedSpell:AddToBuffList(stats.spellModFlatSpellpower[spellId].buffs);
    end

    if stats.versusModFlatSpellpower[_addon.Target.creatureType] then
        extraSp = extraSp + stats.versusModFlatSpellpower[_addon.Target.creatureType].val;
        calcedSpell:AddToBuffList(stats.versusModFlatSpellpower[_addon.Target.creatureType].buffs);
    end

    --------------------------
    -- Handle add triggered spell effect

    do
        local triggerFromSpell = spellId;
        if spellId == _addon.judgementSpell then
            triggerFromSpell = _addon.JUDGEMENT_ID;
        end

        if stats.spellModAddTriggerSpell[triggerFromSpell] ~= nil then
            local triggeredSpellId = stats.spellModAddTriggerSpell[triggerFromSpell].val;
            if triggeredSpellId > 0 then
                _addon:PrintDebug("Add triggered spell "..triggeredSpellId.." on spell "..spellId);
                local triggeredId = _addon:GetHandledSpellID(triggeredSpellId);
                if not triggeredId then
                    _addon:PrintError("Spell "..spellId.." has added trigger effect "..triggeredSpellId.." but that spell isn't handled!");
                else
                    calcedSpell:SetTriggeredSpell(triggeredId, 2);
                end
            elseif calcedSpell[2] and calcedSpell[2].effectFlags == SPELL_EFFECT_FLAGS.TRIGGERED_SPELL then
                _addon:PrintDebug("Remove triggered effect from spell "..spellId);
                calcedSpell:UnsetTriggeredSpell(2);
            end
        end
    end

    --------------------------
    -- Effects

    for i = 1, #calcedSpell, 1 do
        _addon:PrintDebug("Calculating effect " .. i);
        ---@type CalcedEffect
        local calcedEffect = calcedSpell[i];
        ---@type SpellRankEffectData
        local effectData = spellRankInfo.effects[i];

        --------------------------
        -- Charges

        if parentSpellData and parentSpellData.charges then
            calcedSpell.charges = parentSpellData.charges;
        elseif spellRankInfo.charges then
            calcedSpell.charges = spellRankInfo.charges;
            if stats.spellModCharges[spellId] then
                calcedSpell.charges = calcedSpell.charges + stats.spellModCharges[spellId].val;
                calcedSpell:AddToBuffList(stats.spellModCharges[spellId].buffs);
            end
        end

        --------------------------
        -- Ticks

        if effectData.tickPeriod then
            calcedEffect.ticks = math.floor(calcedSpell.durationNoHaste / effectData.tickPeriod);
            calcedEffect.tickPeriod = calcedSpell.duration / calcedEffect.ticks;
        end

        -- Trigger spell spell effect, update triggered spell data
        if bit.band(calcedEffect.effectFlags, SPELL_EFFECT_FLAGS.TRIGGERED_SPELL + SPELL_EFFECT_FLAGS.TRIGGER_SPELL_AURA) > 0 then
            _addon:PrintDebug("Has trigger spell effect, updating triggered spell!");
            calcedEffect.spellData = CalcSpell(calcedEffect.triggeredSpell, calcedEffect.spellData, calcedSpell, effCastTime);
            if bit.band(calcedEffect.effectFlags, SPELL_EFFECT_FLAGS.TRIGGER_SPELL_AURA) > 0 then
                local effectData = spellRankInfo.effects[i];
                effectHandler[effectData.effectType](effectData.auraType, calcedSpell, i, spellRankInfo, effCastTime, 0, spellName, spellId, GCD);
            end
        else
            --------------------------
            -- Effect specific modifier

            local isHeal = bit.band(calcedSpell[1].effectFlags, SPELL_EFFECT_FLAGS.HEAL) > 0;
            local isDuration = bit.band(calcedEffect.effectFlags, SPELL_EFFECT_FLAGS.DURATION) > 0;
            local isNotHealLike = not isHeal and bit.band(calcedSpell[1].effectFlags, SPELL_EFFECT_FLAGS.ABSORB) == 0;
            SetBaseModifiers(spellRankInfo.school, isNotHealLike, isHeal, spellId, calcedSpell, isDuration, spellRankInfo, i);

            --TODO: Remove this
            -- Lets find a case and check if this is still needed.
            if calcedEffect.modBase ~= calcedEffect.modBonus then
                _addon:PrintError("Effect mod is not bonus mod! "..spellName);
                print(calcedEffect.modBase, calcedEffect.modBonus);
            end

            --------------------------
            -- Effect bonus power scaling

            -- Spell power
            calcedEffect.spellPower = (isHeal or effectData.forceScaleWithHeal) and stats.spellHealing or stats.spellPower[spellRankInfo.school];
            calcedEffect.spellPower = calcedEffect.spellPower + extraSp;

            if effectData.coef > 0 then
                local coef = effectData.coef;

                if stats.spellModFlatSpellScale[spellId] then
                    coef = coef + stats.spellModFlatSpellScale[spellId].val / 100;
                    calcedSpell:AddToBuffList(stats.spellModFlatSpellScale[spellId].buffs);
                end

                if stats.spellModPctSpellScale[spellId] then
                    coef = coef * (100 + stats.spellModPctSpellScale[spellId].val) / 100;
                    calcedSpell:AddToBuffList(stats.spellModPctSpellScale[spellId].buffs);
                end

                if spellRankInfo.maxLevel > 0 and bit.band(calcedEffect.effectFlags, SPELL_EFFECT_FLAGS.DUMMY_AURA) == 0 then
                    local downrank = (spellRankInfo.maxLevel + 6) / UnitLevel("player");
                    if downrank < 1 then
                        coef = coef * downrank;
                    end
                end

                calcedEffect.effectiveSpCoef = coef * calcedEffect.modBonus;
                calcedEffect.effectivePower = calcedEffect.spellPower * calcedEffect.effectiveSpCoef;

                -- TODO: LB idol only uses base coef, if ever used for something else this probably needs to change
                if i == 1 and stats.spellModEff1FlatSpellpower[spellId] then
                    calcedEffect.spellPower = calcedEffect.spellPower + stats.spellModEff1FlatSpellpower[spellId].val;
                    calcedEffect.effectivePower = calcedEffect.effectivePower + stats.spellModEff1FlatSpellpower[spellId].val * effectData.coef;
                    calcedSpell:AddToBuffList(stats.spellModEff1FlatSpellpower[spellId].buffs);
                end
            end

            -- Attack power
            if spellRankInfo.defType == DEF_TYPE.RANGED then
                calcedEffect.attackPower = stats.attackPowerRanged;
            else
                calcedEffect.attackPower = stats.attackPower;
            end

            if effectData.coefAP > 0 then
                calcedEffect.effectiveApCoef = effectData.coefAP * calcedEffect.modBonus;
                calcedEffect.effectivePower = calcedEffect.effectivePower + calcedEffect.attackPower * calcedEffect.effectiveApCoef;
            end

            calcedEffect.flatMod = flatMod;

            --------------------------
            -- Effect values

            -- Pre process script hook
            scriptEffects.DoSpell(EFFECT_TYPE.SCRIPT_SPELLMOD_EFFECT_PRE, calcedSpell, calcedEffect, spellId, spellRankInfo);

            assert(effectHandler[effectData.effectType] ~= nil, "No effect handler for effect #"..i..":"..effectData.effectType.." on spell ("..spellId..") "..spellName);

            effectHandler[effectData.effectType](effectData.auraType, calcedSpell, i, spellRankInfo, effCastTime, calcedEffect.modBase, spellName, spellId, GCD);

            --------------------------
            -- Aura stacking (Only Lifebloom, incompatible with dmg spells!)

            if bit.band(calcedEffect.effectFlags, SPELL_EFFECT_FLAGS.STACKABLE_AURA) > 0 then
                local stackCount = effectData.auraStacks;
                local stackData = calcedEffect.auraStack;
                assert(stackCount and stackData, "stackCount or stackData mising for aura stack handler!");
                stackData.stacks = stackCount;
                stackData.ticks = calcedEffect.ticks - 1;
                stackData.min = calcedEffect.min * stackCount;
                stackData.max = calcedEffect.max * stackCount;
                stackData.avg = calcedEffect.avg * stackCount;
                stackData.avgCombined = stackData.avg;
                stackData.avgAfterMitigation = stackData.ticks * stackData.avgCombined;
                stackData.perSec = stackData.avgAfterMitigation / effCastTime;
                stackData.perSecDurOrCD = calcedEffect.perSecDurOrCD * stackCount;
                stackData.perResource = stackData.avgAfterMitigation / calcedSpell.effectiveCost;
                stackData.doneToOom = calcedSpell.castingData.castsToOom * stackData.avgAfterMitigation;
            end
        end
    end

    --------------------------
    -- Combined direct + HoT/DoT data

    if calcedSpell.combined ~= nil then
        ---@type CombinedData
        local cd = calcedSpell.combined;
        ---@type CalcedEffect
        local eff1 = calcedSpell[1];
        ---@type CalcedEffect
        local eff2 = calcedSpell[2];
        ---@type SpellRankEffectData
        local effectData2 = spellRankInfo.effects[2];
        local totalEff2 = eff2.ticks * eff2.avg;

        cd.fullDuration.hitAvg = eff1.avg + totalEff2;
        cd.fullDuration.critAvg = eff1.avgCrit + totalEff2;
        cd.fullDuration.perResource = eff1.perResource + eff2.perResource;
        cd.fullDuration.perSecond = eff1.perSec + eff2.perSec;
        cd.fullDuration.doneToOom = eff1.doneToOom + eff2.doneToOom;

        local ticksPerCast = math.floor(castTime / effectData2.tickPeriod);
        cd.spam.ticksUsed = ticksPerCast;

        if ticksPerCast > 0 then
            local tickDonePerCast = ticksPerCast * eff2.avg;
            cd.spam.hitAvg = tickDonePerCast + eff1.avg;
            cd.spam.critAvg = tickDonePerCast + eff1.avgCrit;
            cd.spam.perSecond = eff1.perSec + tickDonePerCast / castTime;
            cd.spam.perResource = eff1.perResource + (eff2.perResource * (ticksPerCast / eff2.ticks));
            local hitCastsToOom = calcedSpell.castingData.castsToOom;
            if calcedSpell.hitChance > 0 then
                hitCastsToOom = hitCastsToOom * calcedSpell.hitChance / 100;
            end
            local ticksPerCastToOom = hitCastsToOom * ticksPerCast;
            cd.spam.doneToOom = eff1.doneToOom + ticksPerCastToOom * eff2.avg;
        end
    end

    calcedSpell.updated = currentState;

    -- _addon:PrintDebug("== Updated spell (".. spellId .. ") " .. spellName .. " ==");
    -- _addon:PrintDebug(calcedSpell);
    -- _addon:PrintDebug("===========================================");

    return calcedSpell;
end

do
    local updateStaggerFrame = CreateFrame("Frame");
    local timerDiff = 0;
    local waitForUpdate = false;

    -- Only update every 1/3 sec instead of possibly after every single change
    local function UpdateUpdate(self, diff)
        timerDiff = timerDiff + diff;
        if timerDiff > 0.333 then
            currentState = currentState + 1;
            _addon:PrintDebug("Increment state! " .. currentState);
            updateStaggerFrame:SetScript("OnUpdate", nil);
            timerDiff = 0;
            waitForUpdate = false;
        end
    end

    --- Trigger full update
    function _addon:TriggerUpdate()
        if waitForUpdate then
            return;
        end
        self:PrintDebug("Update triggered!");
        updateStaggerFrame:SetScript("OnUpdate", UpdateUpdate);
    end
end

--- Return the handled spell ID (if different) or nil if spell is not handled by the addon
---@param spellID integer
---@return integer|nil
function _addon:GetHandledSpellID(spellID)
    if self.JUDGEMENT_IDS[spellID] then
        if not self.judgementSpell then
            return;
        end
        spellID = self.judgementSpell;
    end

    if self.spellRankInfo[spellID] == nil then
        return;
    end

    return spellID;
end

--- Get calculated spell if it is handled by the addon, updates or creates spell data if needed
---@param spellID integer
---@return CalcedSpell|nil
function _addon:GetCalcedSpell(spellID)
    local handledSpellId = self:GetHandledSpellID(spellID);

    if not handledSpellId then
        return;
    end

    if calcedSpells[handledSpellId] == nil or calcedSpells[handledSpellId].updated < currentState then
        calcedSpells[handledSpellId] = CalcSpell(handledSpellId, calcedSpells[handledSpellId]);
    end

    return calcedSpells[handledSpellId];
end

--- Return current calculated spell data if there is any
---@param spellID number
---@return CalcedSpell|nil
function _addon:GetCurrentSpellData(spellID)
    return calcedSpells[spellID];
end

--- Get the current incrementing internal update state
function _addon:GetCurrentState()
    return currentState;
end