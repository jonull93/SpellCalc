import { SpellData, SpellEffect, SpellMisc, SpellLevel, Spell, SpellCategory, SpellCooldown, SpellPower, SpellEquippedItems, SpellAuraOptions } from "./SpellData";
import * as fs from "fs";
import { isSeal, SealType } from "./paladinCrap";
import { ItemSetCreator } from "./ItemSetCreator";
import { ClassSpellLists } from "./ClassSpellLists";
import { ClassSpellSets } from "./ClassSpellSets";
import { ItemEffectsCreator } from "./ItemEffectsCreator";
import { getHandledClassGlyphs } from "./glyphs";
import { createMechanicLists } from "./mechanicList";
import { cfg } from "./config";
import { TalentsCreator } from "./modules/TalentCreator";
import { AuraHandlers } from "./ItemAuraHandlers";
import { isPlayerClass } from "./helper";
import { SpellLevelScaling } from "./modules/SpellLevelScaling";
import { applyHotfixes } from "./modules/hotFix";
import { PlayerAuras } from "./modules/PlayerAuras";
import { TargetAuras } from "./modules/TargetAuras";

const DO_CLASSES: PlayerClass[] = [
    PlayerClass.DRUID,
    PlayerClass.PRIEST,
    PlayerClass.WARLOCK,
    PlayerClass.MAGE,
    PlayerClass.PALADIN,
    PlayerClass.SHAMAN,
    //PlayerClass.HUNTER,
    //PlayerClass.WARRIOR,
    //PlayerClass.ROGUE,
];

const SCHOOL_MASK_TO_ENUM = {
    [SCHOOL_MASK.NONE]: 0,
    [SCHOOL_MASK.PHYSICAL]: 1,
    [SCHOOL_MASK.HOLY]: 2,
    [SCHOOL_MASK.FIRE]: 3,
    [SCHOOL_MASK.NATURE]: 4,
    [SCHOOL_MASK.FROST]: 5,
    [SCHOOL_MASK.SHADOW]: 6,
    [SCHOOL_MASK.ARCANE]: 7,
    [SCHOOL_MASK.FROST + SCHOOL_MASK.FIRE]: 5 // TODO: Hackfix for FFB, just set as frost, most likely won't do what it should do
}

const USEFUL_SPELL_MECHANICS: {[sm: number]: boolean} = {
    [SpellMechanic.BLEED]: true,
    [SpellMechanic.INFECTED]: true
}

const spellData = new SpellData();
applyHotfixes(spellData);
const classSpellLists = new ClassSpellLists(spellData, DO_CLASSES);
const classSpellSets = new ClassSpellSets(spellData);
const auraHandlers = new AuraHandlers(spellData, classSpellLists, classSpellSets);
const talentCreator = new TalentsCreator(spellData, auraHandlers, classSpellSets);
const spellLevelScaling = new SpellLevelScaling(spellData);
const playerAuras = new PlayerAuras(spellData, auraHandlers);
const targetAuras = new TargetAuras(spellData);

const SpellClassSet = {
    MAGE: 3,
    WARRIOR: 4,
    WARLOCK: 5,
    PRIEST: 6,
    DRUID: 7,
    ROGUE: 8,
    HUNTER: 9,
    PALADIN: 10,
    SHAMAN: 11,
}

/**
 * Should class be handled?
 * @param pclass 
 * @returns 
 */
function shouldDoClass(pclass: string)
{
    return isPlayerClass(pclass) && DO_CLASSES.indexOf(pclass) !== -1;
}

function getCorectBase(effect: SpellEffect)
{
    if (effect.EffectDieSides == 0) return effect.EffectBasePoints;
    return effect.EffectBasePoints + 1;
}

function fillBaseAndRange(ei: EffectInfo, effect: SpellEffect)
{
    if (effect.EffectDieSides == 0)
    {
        ei.valueBase = effect.EffectBasePoints;
        ei.valueRange = 0;
        return;
    }
    ei.valueBase = effect.EffectBasePoints + 1;
    ei.valueRange = effect.EffectDieSides - 1;
}

function handleDummyAura(effect: SpellEffect, ei: EffectInfo, ri: RankInfo) {
    const sealType = isSeal(effect.SpellID);
    if (sealType !== false)
    {
        if (sealType == SealType.SOR) {
            fillBaseAndRange(ei, effect);
            return;
        }

        if (sealType == SealType.SoCor || sealType == SealType.SoV) {
            ei.weaponCoef = 0.33;
            return;
        }
    }

    const spellName = spellData.getSpellName(effect.SpellID).Name_lang;

    // Prayer of Mending
    if (spellName == "Prayer of Mending")
    {
        ri.charges = 5;
        fillBaseAndRange(ei, effect);
        ei.coef = effect.EffectBonusCoefficient;
        ri.forceHeal = true;
        ri.defenseType = DEFENSE_TYPE.MAGIC;
        return;
    }

    // Earth Shield
    if (spellName == "Earth Shield")
    {
        ri.charges = 6;
        fillBaseAndRange(ei, effect);
        ei.coef = 0.538;
        ri.forceHeal = true;
        return;
    }

    // Sacred Shield
    if (spellName == "Sacred Shield")
    {
        ei.effectType = EFFECT_TYPE.SPELL_EFFECT_TRIGGER_SPELL;
        ei.auraType = 0;
        ei.valueBase = 0;
        ei.valueRange = 0;
        ei.triggeredSpell = effect.EffectTriggerSpell;
        return;
    }

    throw new Error("Dummy aura effect not supported!");
}

function handleDummyEffect(rankInfo: RankInfo, effect: SpellEffect, effectNum: number, spellName: string) 
{
    // Starfall
    if (spellName == "Starfall")
    {
        if (effectNum > 0) throw new Error("Starfall dummy effect not 0!");

        // Coefs are same for all ranks
        rankInfo.effects[effectNum] = {
            effectType: EFFECT_TYPE.SPELL_EFFECT_APPLY_AURA,
            auraType: AURA_TYPE.SPELL_AURA_DUMMY,
            coef: 0.3, // Star hit
            coefAP: 0,
            valueBase: 0,
            valueRange: 0,
            valuePerLevel: 0,
            forceScaleWithHeal: false,
            period: 0,
            weaponCoef: 0,
            mechanic: 0,
            perResource: 0,
            triggeredSpell: 0,
        };
        const triggeredDummy = spellData.getSpellEffects(effect.EffectTriggerSpell);
        const startTrigger = spellData.getSpellEffects(getCorectBase(triggeredDummy[0]));
        if (startTrigger.length == 0) throw new Error("Failed to get spell effects for Starfall trigger!");
        for (const teff2 of startTrigger)
        {
            if (teff2.EffectIndex == 0)
            {
                // The main hit of a star
                fillBaseAndRange(rankInfo.effects[effectNum], teff2);
            }
            else if (teff2.EffectIndex == 1)
            {
                // Put star AoE base damage in valuePerLevel
                const aoeTrigger = spellData.getSpellEffects(teff2.EffectTriggerSpell);
                if (aoeTrigger.length == 0) throw new Error("Failed to get spell effects for Starfall AoE trigger!");
                rankInfo.effects[1] = {
                    effectType: EFFECT_TYPE.SPELL_EFFECT_APPLY_AURA,
                    auraType: AURA_TYPE.SPELL_AURA_DUMMY,
                    coef: 0.127, // AoE effect
                    coefAP: 0,
                    valueBase: aoeTrigger[0].EffectBasePoints + 1,
                    valueRange: 0,
                    valuePerLevel: 0,
                    forceScaleWithHeal: false,
                    period: 0,
                    weaponCoef: 0,
                    mechanic: 0,
                    perResource: 0,
                    triggeredSpell: 0,
                };
            }
        }
        return;
    }

    // Conflagrate
    if (spellName == "Conflagrate")
    {
        rankInfo.effects = [{
            effectType: EFFECT_TYPE.SPELL_EFFECT_APPLY_AURA,
            auraType: AURA_TYPE.SPELL_AURA_DUMMY,
            coef: 0,
            coefAP: 0,
            valueBase: 0,
            valueRange: 0,
            valuePerLevel: 0,
            forceScaleWithHeal: false,
            period: 0,
            weaponCoef: 0,
            mechanic: 0,
            perResource: 0,
            triggeredSpell: 0,
        }];
        return;
    }

    if (cfg.expansion == "CLASSIC")
    {
        if (spellName == "Judgement of Righteousness") return;
    }

    throw new Error("Dummy effect not handled!");
}

/**
 * SPELL_EFFECT_APPLY_AURA and SPELL_EFFECT_PERSISTENT_AREA_AURA
 */
function applyAuraAreaAura(rankInfo: RankInfo, effect: SpellEffect, effectNum: number, spellName: string) {
    const saopts = spellData.getSpellAuraOptions(effect.SpellID);
    
    rankInfo.effects[effectNum] = {
        effectType: effect.Effect,
        auraType: effect.EffectAura,
        coef: effect.EffectBonusCoefficient,
        coefAP: effect.BonusCoefficientFromAP,
        valueBase: 0,
        valueRange: 0,
        valuePerLevel: effect.EffectRealPointsPerLevel,
        forceScaleWithHeal: false,
        period: 0,
        weaponCoef: 0,
        mechanic: effect.EffectMechanic,
        perResource: effect.EffectPointsPerResource,
        triggeredSpell: 0,
    };
    fillBaseAndRange(rankInfo.effects[effectNum], effect);

    if (saopts && saopts.CumulativeAura > 1) rankInfo.effects[effectNum].auraStacks = saopts.CumulativeAura;

    switch (effect.EffectAura) {
        case AURA_TYPE.SPELL_AURA_PERIODIC_HEAL:
            rankInfo.effects[effectNum].period = effect.EffectAuraPeriod / 1000;
            break;
        case AURA_TYPE.SPELL_AURA_PERIODIC_DAMAGE:
        case AURA_TYPE.SPELL_AURA_PERIODIC_LEECH:
            rankInfo.effects[effectNum].period = effect.EffectAuraPeriod / 1000;
            break;
        case AURA_TYPE.SPELL_AURA_SCHOOL_ABSORB:
        case AURA_TYPE.SPELL_AURA_MANA_SHIELD:
            if (spellName == "Power Word: Shield") rankInfo.effects[effectNum].forceScaleWithHeal = true;
            break;
        case AURA_TYPE.SPELL_AURA_DAMAGE_SHIELD:
            break;
        case AURA_TYPE.SPELL_AURA_PROC_TRIGGER_SPELL: 
            {
                rankInfo.effects[effectNum].triggeredSpell = effect.EffectTriggerSpell;
            } break;
        case AURA_TYPE.SPELL_AURA_PERIODIC_TRIGGER_SPELL:
        case AURA_TYPE.SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE:
            {
                rankInfo.effects[effectNum].triggeredSpell = effect.EffectTriggerSpell;
                rankInfo.effects[effectNum].period = effect.EffectAuraPeriod / 1000;
            } break;
        case AURA_TYPE.SPELL_AURA_DUMMY:
            handleDummyAura(effect, rankInfo.effects[effectNum], rankInfo);
            break;
        case AURA_TYPE.SPELL_AURA_PROC_TRIGGER_DAMAGE:
        case AURA_TYPE.SPELL_AURA_PERIODIC_ENERGIZE:
        case AURA_TYPE.MOD_POWER_REGEN_PERCENT:
        case AURA_TYPE.SPELL_AURA_OBS_MOD_MANA:
            break;
        default:
            if (effect.EffectMechanic != 0) {
                const misc = spellData.getSpellMisc(effect.SpellID);
                if (rankInfo.school != 1
                    && (misc["Attributes_6"] & SPELL_ATTR6.SPELL_ATTR_NO_BINARY_OR_MAYBE_NOT_IDK_WHAT_THIS_DOES) === 0) {
                    rankInfo.isBinary = true;
                }
                rankInfo.effects.splice(effectNum);
            } else {
                throw new Error("Aura type not supported! " + effect.EffectAura);
            }
    }
}

/**
 * SPELL_EFFECT_SCHOOL_DAMAGE and SPELL_EFFECT_HEALTH_LEECH
 */
function directDmg(rankInfo: RankInfo, effect: SpellEffect, effectNum: number) {
    rankInfo.effects[effectNum] = {
        effectType: effect.Effect,
        coef: effect.EffectBonusCoefficient,
        coefAP: effect.BonusCoefficientFromAP,
        valueBase: 0,
        valueRange: 0,
        valuePerLevel: effect.EffectRealPointsPerLevel,
        forceScaleWithHeal: false,
        period: 0,
        weaponCoef: 0,
        mechanic: effect.EffectMechanic,
        perResource: effect.EffectPointsPerResource,
        triggeredSpell: 0,
    };
    fillBaseAndRange(rankInfo.effects[effectNum], effect);

    if (effect.EffectChainTargets > 1 && effect.EffectChainAmplitude < 1)
    {
        rankInfo.effects[effectNum].chainInfo = {
            chains: effect.EffectChainTargets,
            mult: effect.EffectChainAmplitude
        };
    }
}

function summonTotemSlot(rankInfo: RankInfo, effect: SpellEffect, effectNum: number, spellName: string) {
    const totemSpell = spellData.getTotemSpell(effect.SpellID);
    if (!totemSpell) throw new Error("Totem spell not found!");
    const totemEffects = spellData.getSpellEffects(totemSpell);
    const totemSpellCat = spellData.getSpellCategory(totemSpell);
    const totemSpellLevel = spellData.getSpellLevel(totemSpell);

    if (!totemSpellCat) throw new Error("Totem spell category not found!");

    rankInfo.maxLevel = totemSpellLevel.MaxLevel;

    switch(spellName) {
        case "Searing Totem":
            throw new Error("Searing Totem should be handled in spell fixes!");
        case "Magma Totem":
            throw new Error("Magma Totem should be handled in spell fixes!");
        case "Healing Stream Totem":
            applyAuraAreaAura(rankInfo, totemEffects[0], effectNum, spellName);
            break;
        case "Fire Nova Totem":
            directDmg(rankInfo, totemEffects[0], effectNum);
            break;
        default:
            throw new Error("Totem with defined spells is not implemented!");
    }
}

/**
 * Functions to fill effect info
 */
const effectInfoHandler: {[index: number]: (rankInfo: RankInfo, effect: SpellEffect, effectNum: number, spellName: string) => void} = {
    [EFFECT_TYPE.SPELL_EFFECT_HEAL]: (rankInfo, effect, effectNum) => {
        rankInfo.effects[effectNum] = {
            effectType: effect.Effect,
            coef: effect.EffectBonusCoefficient,
            coefAP: effect.BonusCoefficientFromAP,
            valueBase: 0,
            valueRange: 0,
            valuePerLevel: effect.EffectRealPointsPerLevel,
            forceScaleWithHeal: false,
            period: 0,
            weaponCoef: 0,
            mechanic: effect.EffectMechanic,
            perResource: effect.EffectPointsPerResource,
            triggeredSpell: 0,
        };
        fillBaseAndRange(rankInfo.effects[effectNum], effect);

        if (effect.EffectChainTargets > 1 && effect.EffectChainAmplitude < 1)
        {
            rankInfo.effects[effectNum].chainInfo = {
                chains: effect.EffectChainTargets,
                mult: effect.EffectChainAmplitude
            };
        }
    },

    [EFFECT_TYPE.SPELL_EFFECT_APPLY_AURA]: applyAuraAreaAura,
    [EFFECT_TYPE.SPELL_EFFECT_HEALTH_FUNNEL]: applyAuraAreaAura,
    [EFFECT_TYPE.SPELL_EFFECT_PERSISTENT_AREA_AURA]: applyAuraAreaAura,
    [EFFECT_TYPE.SPELL_EFFECT_APPLY_AREA_AURA_PARTY]: applyAuraAreaAura,

    [EFFECT_TYPE.SPELL_EFFECT_SCHOOL_DAMAGE]: directDmg,
    [EFFECT_TYPE.SPELL_EFFECT_HEALTH_LEECH]: directDmg,

    [EFFECT_TYPE.SPELL_EFFECT_SUMMON_TOTEM_SLOT_CLASSIC]: summonTotemSlot,

    [EFFECT_TYPE.SPELL_EFFECT_WEAPON_DAMAGE]: (rankInfo, effect, effectNum, _spellName) => {
        rankInfo.effects[effectNum] = {
            effectType: effect.Effect,
            coef: effect.EffectBonusCoefficient,
            coefAP: effect.BonusCoefficientFromAP,
            valueBase: 0,
            valueRange: 0,
            valuePerLevel: effect.EffectRealPointsPerLevel,
            forceScaleWithHeal: false,
            period: 0,
            weaponCoef: 1,
            mechanic: effect.EffectMechanic,
            perResource: effect.EffectPointsPerResource,
            triggeredSpell: 0,
        };
        fillBaseAndRange(rankInfo.effects[effectNum], effect);
    },

    [EFFECT_TYPE.SPELL_EFFECT_NORMALIZED_WEAPON_DMG]: (rankInfo, effect, effectNum, _spellName) => {
        rankInfo.effects[effectNum] = {
            effectType: effect.Effect,
            coef: effect.EffectBonusCoefficient,
            coefAP: effect.BonusCoefficientFromAP,
            valueBase: 0,
            valueRange: 0,
            valuePerLevel: effect.EffectRealPointsPerLevel,
            forceScaleWithHeal: false,
            period: 0,
            weaponCoef: 1,
            mechanic: effect.EffectMechanic,
            perResource: effect.EffectPointsPerResource,
            triggeredSpell: 0,
        };
        fillBaseAndRange(rankInfo.effects[effectNum], effect);
    },

    [EFFECT_TYPE.SPELL_EFFECT_WEAPON_PERCENT_DAMAGE]: (rankInfo, effect, effectNum, spellName) => {
        const weaponCoef = getCorectBase(effect) / 100;

        if (effectNum > 0) {
            if (rankInfo.effects[0].effectType != EFFECT_TYPE.SPELL_EFFECT_WEAPON_DAMAGE
                && rankInfo.effects[0].effectType != EFFECT_TYPE.SPELL_EFFECT_NORMALIZED_WEAPON_DMG) {
                throw new Error("E1/2 is SPELL_EFFECT_WEAPON_PERCENT_DAMAGE but E0 isn't SPELL_EFFECT_WEAPON_DAMAGE!");
            }
            rankInfo.effects[0].weaponCoef = weaponCoef;
            return;
        }

        rankInfo.effects[effectNum] = {
            effectType: effect.Effect,
            coefAP: effect.BonusCoefficientFromAP,
            coef: effect.EffectBonusCoefficient,
            valueBase: 0,
            valueRange: 0,
            valuePerLevel: effect.EffectRealPointsPerLevel,
            forceScaleWithHeal: false,
            period: 0,
            weaponCoef: weaponCoef,
            mechanic: effect.EffectMechanic,
            perResource: effect.EffectPointsPerResource,
            triggeredSpell: 0,
        };

        // SoC "fix"
        if (spellName == "Seal of Command") {
            rankInfo.effects[effectNum].effectType = EFFECT_TYPE.SPELL_EFFECT_APPLY_AURA;
            rankInfo.effects[effectNum].auraType = AURA_TYPE.SPELL_AURA_DUMMY;
        }
    },

    [EFFECT_TYPE.SPELL_EFFECT_ATTACK]: (rankInfo, effect, effectNum, _spellName) => {
        rankInfo.effects[effectNum] = {
            effectType: effect.Effect,
            coef: 0,
            coefAP: 0,
            valueBase: 0,
            valueRange: 0,
            valuePerLevel: 0,
            forceScaleWithHeal: false,
            period: 0,
            weaponCoef: 0,
            mechanic: effect.EffectMechanic,
            perResource: effect.EffectPointsPerResource,
            triggeredSpell: 0,
        };
    },

    [EFFECT_TYPE.SPELL_EFFECT_TRIGGER_SPELL]: (rankInfo, effect, effectNum, _spellName) => {
        rankInfo.effects[effectNum] = {
            effectType: effect.Effect,
            coef: 0,
            coefAP: 0,
            valueBase: 0,
            valueRange: 0,
            valuePerLevel: 0,
            forceScaleWithHeal: false,
            period: 0,
            weaponCoef: 0,
            mechanic: effect.EffectMechanic,
            perResource: effect.EffectPointsPerResource,
            triggeredSpell: effect.EffectTriggerSpell,
        };
    },

    [EFFECT_TYPE.SPELL_EFFECT_DUMMY]: handleDummyEffect,

    [EFFECT_TYPE.SPELL_EFFECT_ENERGIZE_PCT]: (rankInfo, effect, effectNum, _spellName) => {
        rankInfo.effects[effectNum] = {
            effectType: effect.Effect,
            coefAP: effect.BonusCoefficientFromAP,
            coef: effect.EffectBonusCoefficient,
            valueBase: 0,
            valueRange: 0,
            valuePerLevel: effect.EffectRealPointsPerLevel,
            forceScaleWithHeal: false,
            period: 0,
            weaponCoef: 0,
            mechanic: effect.EffectMechanic,
            perResource: effect.EffectPointsPerResource,
            triggeredSpell: 0,
        };
        fillBaseAndRange(rankInfo.effects[effectNum], effect);
    },
}

/**
 * Build spell info data for class
 * @param pclass 
 */
function buildSpellInfo(pclass: string) {
    console.log("Building spell data for class " + pclass);
    const list = classSpellLists.getListForClass(pclass);
    let classInfo: ClassInfo = {
        rankInfo: {},
    };

    let effects: SpellEffect[];
    let spellMisc: SpellMisc;
    let spellName: string;
    let spellLevel: SpellLevel;
    let spellspell: Spell;
    let spellcat: SpellCategory | undefined;
    let spellcd: SpellCooldown;
    let spellCosts: SpellPower[];
    let spellEquippedItems: SpellEquippedItems | undefined;
    let spellAuraOptions: SpellAuraOptions | undefined;

    for (const [spellId, spellEffects] of list) {
        effects = spellEffects;
        spellMisc = spellData.getSpellMisc(spellId);
        spellName = spellData.getSpellName(spellId).Name_lang;
        spellLevel = spellData.getSpellLevel(spellId);
        spellspell = spellData.getSpell(spellId);
        spellcat = spellData.getSpellCategory(spellId);
        spellcd = spellData.getSpellCooldown(spellId);
        spellCosts = spellData.getSpellPowerCosts(spellId);
        spellEquippedItems = spellData.getSpellEquipeedItems(spellId);
        spellAuraOptions = spellData.getSpellAuraOptions(spellId);

        if (!spellcat) throw new Error("Sspell category not found!");

        // Skip physical spells except auto attack and SOtC for now
        //if (spellMisc.SchoolMask == 1 && spellName != "Attack" && !isSeal(spellMisc.SpellID) && spellId != 35395 && spellId != 53385) continue;

        // Create rank info if needed
        if (!classInfo.rankInfo[spellId]) {
            let dur = (spellMisc.DurationIndex) ? spellData.getSpellDuration(spellMisc.DurationIndex).Duration / 1000 : 0;
            if (dur < 1 ) dur = 0;
            classInfo.rankInfo[spellId] = {
                school: SCHOOL_MASK_TO_ENUM[spellMisc.SchoolMask],
                isChannel: ((spellMisc["Attributes_1"] & SPELL_ATTR1.SPELL_ATTR_EX_CHANNELED_ANY) > 0),
                isBinary: false,
                gcd: spellcd.StartRecoveryTime / 1000,
                defenseType: spellcat.DefenseType,
                cantDogeParryBlock: ((spellMisc["Attributes_0"] & SPELL_ATTR0.SPELL_ATTR_IMPOSSIBLE_DODGE_PARRY_BLOCK) > 0),
                equippedWeaponMask: (spellEquippedItems && spellEquippedItems.EquippedItemClass === ItemClass.ITEM_CLASS_WEAPON) ? spellEquippedItems.EquippedItemSubclass : 0,
                noCrit: (spellMisc["Attributes_2"] & SPELL_ATTR2.SPELL_ATTR_EX2_CANT_CRIT) === SPELL_ATTR2.SPELL_ATTR_EX2_CANT_CRIT,
                forceHeal: false,
                charges: (spellAuraOptions && spellAuraOptions.ProcCharges > 0) ? spellAuraOptions.ProcCharges : 0,
                spellnamecomment: spellName + ( (spellspell.NameSubtext_lang.length) ? `(${spellspell.NameSubtext_lang})` : "" ),
                spellLevel: spellLevel.SpellLevel,
                maxLevel: spellLevel.MaxLevel,
                duration: dur,
                baseCost: 0,
                baseCostPct: 0,
                usePeriodicHaste: (spellMisc["Attributes_5"] & SPELL_ATTR5.SPELL_ATTR_SPELL_HASTE_AFFECTS_PERIODIC) === SPELL_ATTR5.SPELL_ATTR_SPELL_HASTE_AFFECTS_PERIODIC,
                onNextAttack: (spellMisc["Attributes_0"] & SPELL_ATTR0.SPELL_ATTR_ON_NEXT_SWING_NO_DAMAGE) > 0,
                isOffhandAttack: (spellMisc["Attributes_3"] & SPELL_ATTR3.SPELL_ATTR_EX3_REQUIRES_OFFHAND_WEAPON) > 0,
                useScalingFormula: spellLevelScaling.getVariableKeyForSpell(spellId),
                effects: []
            };

            if (spellCosts.length === 1) {
                if (spellCosts[0].PowerType == PowerType.MANA || spellCosts[0].PowerType == PowerType.RAGE || spellCosts[0].PowerType == PowerType.ENERGY) {
                    classInfo.rankInfo[spellId].baseCost = spellCosts[0].ManaCost;
                    classInfo.rankInfo[spellId].baseCostPct = spellCosts[0].PowerCostPct;
                }
            } else if (spellCosts.length > 1) {
                for (let cinfo of spellCosts) {
                    if (cinfo.PowerType == PowerType.MANA || cinfo.PowerType == PowerType.RAGE || cinfo.PowerType == PowerType.ENERGY) {
                        classInfo.rankInfo[spellId].baseCost = cinfo.ManaCost;
                        classInfo.rankInfo[spellId].baseCostPct = cinfo.PowerCostPct;
                        break;
                    }
                }
            }
        }

        // Handle effects
        for (let i = 0; i < effects.length; i++) {
            effectInfoHandler[effects[i].Effect](classInfo.rankInfo[effects[i].SpellID], effects[i], i, spellName);

            // Make sure maxlevel is defined for spells with level scaling
            if (classInfo.rankInfo[spellId].effects[i] 
                && classInfo.rankInfo[spellId].effects[i].valuePerLevel != 0 
                && classInfo.rankInfo[spellId].maxLevel == 0) console.error("Effect has perlevel scaling but maxlevel of the spell is 0! " + spellId);
        }

        // Fix empty 2nd effect slot due to stupid SPELL_EFFECT_WEAPON_PERCENT_DAMAGE implementation...
        if (classInfo.rankInfo[spellId].effects.length == 3 && !classInfo.rankInfo[spellId].effects[1])
        {
            classInfo.rankInfo[spellId].effects.splice(1, 1);
        }
    }

    for (const spellId in classInfo.rankInfo)
    {
        for (const effect of classInfo.rankInfo[spellId].effects)
        {
            if (effect.effectType === EFFECT_TYPE.SPELL_EFFECT_WEAPON_DAMAGE
                && effect.weaponCoef === 0) throw new Error("Effect is SPELL_EFFECT_WEAPON_DAMAGE but no weapon coef is defined! " + spellId)
        }
    }

    return classInfo;
}

/**
 * Create lua file with data for class
 * @param pclass 
 */
function createLua(pclass: string) {
    console.log("Creating Lua for " + pclass);
    let str = `-- GENERATED

---@class AddonEnv
local _addon = select(2, ...);
local _, playerClass = UnitClass("player");
if playerClass ~= "${pclass.toUpperCase()}" then
    return;
end

`;
    let classInfo = buildSpellInfo(pclass);

    str += "---@type SpellInfoTable\n_addon.spellInfo = {\n";
    for (let sid in classInfo.rankInfo) {
        let ri = classInfo.rankInfo[sid];
        str += `\t[${sid}] = { -- ${ri.spellnamecomment}\n`;
        str += `\t\tspellLevel = ${ri.spellLevel},\n`;
        str += `\t\tmaxLevel = ${ri.maxLevel},\n`;
        if (ri.duration) str += `\t\tduration = ${ri.duration},\n`;
        if (ri.baseCost > 0) str += `\t\tbaseCost = ${ri.baseCost},\n`;
        if (ri.baseCostPct > 0) str += `\t\tbaseCostPct = ${ri.baseCostPct},\n`;
        str += `\t\tschool = ${ri.school},\n`;
        if (ri.isChannel) str += `\t\tisChannel = true,\n`;
        if (ri.isBinary) str += `\t\tisBinary = true,\n`;
        if (ri.gcd != 1.5) str += `\t\tGCD = ${ri.gcd},\n`;
        str += `\t\tdefType = ${ri.defenseType},\n`;
        if (ri.cantDogeParryBlock) str += `\t\tcantDogeParryBlock = true,\n`;
        if (ri.equippedWeaponMask != 0) str += `\t\tequippedWeaponMask = ${ri.equippedWeaponMask},\n`;
        if (ri.noCrit) str += `\t\tnoCrit = ${ri.noCrit},\n`;
        if (ri.forceHeal) str += `\t\tforceHeal = ${ri.forceHeal},\n`;
        if (ri.charges != 0) str += `\t\tcharges = ${ri.charges},\n`;
        if (ri.usePeriodicHaste) str += `\t\tusePeriodicHaste = true,\n`;
        if (ri.onNextAttack) str += `\t\tonNextSwing = true,\n`;
        if (ri.isOffhandAttack) str += `\t\tisOffhandAttack = true,\n`;
        if (ri.useScalingFormula) str += `\t\tuseScalingFormula = "${ri.useScalingFormula}",\n`;

        str += `\t\teffects = {\n`;

        for (let i = 0; i < ri.effects.length; i++) {
            let eff = ri.effects[i];
            str += `\t\t\t[${i + 1}] = {\n`;
            str += `\t\t\t\teffectType = ${eff.effectType},\n`;
            if (eff.auraType) str += `\t\t\t\tauraType = ${eff.auraType},\n`;
            if (eff.forceScaleWithHeal) str += `\t\t\t\tforceScaleWithHeal = true,\n`;
            if (eff.period > 0) str += `\t\t\t\ttickPeriod = ${eff.period},\n`;
            if (eff.weaponCoef) str += `\t\t\t\tweaponCoef = ${eff.weaponCoef},\n`;
            str += `\t\t\t\tvalueBase = ${eff.valueBase},\n`;
            str += `\t\t\t\tvalueRange = ${eff.valueRange},\n`;
            if (eff.valuePerLevel) str += `\t\t\t\tvaluePerLevel = ${eff.valuePerLevel},\n`;
            if (eff.perResource) str += `\t\t\t\tperResouce = ${eff.perResource},\n`;
            if (eff.triggeredSpell) str += `\t\t\t\ttriggeredSpell = ${eff.triggeredSpell},\n`;
            str += `\t\t\t\tcoef = ${eff.coef},\n`;
            str += `\t\t\t\tcoefAP = ${eff.coefAP},\n`;
            if (eff.chainInfo) 
            {
                str += `\t\t\t\tchains = ${eff.chainInfo.chains},\n`;
                str += `\t\t\t\tchainMult = ${eff.chainInfo.mult},\n`;
            }
            if (eff.auraStacks) str += `\t\t\t\tauraStacks = ${eff.auraStacks},\n`;
            if (USEFUL_SPELL_MECHANICS[eff.mechanic]) str += `\t\t\t\tmechanic = ${eff.mechanic},\n`;
            //if (eff.triggeredSpell) str += `\t\t\t\ttriggeredSpell = ${eff.triggeredSpell},\n`;
            str += `\t\t\t},\n`;
        }

        str += `\t\t}\n`;
        str += `\t},\n`;
    }
    str += "};\n\n";

    if (pclass == "paladin") {
        let spellName: string;
        let spellspell: Spell;
        for (const [sealId, remapId] of classSpellLists.getJudgementRemap()) {
            spellName = spellData.getSpellName(sealId).Name_lang;
            spellspell = spellData.getSpell(sealId);
            const name = spellName + ( (spellspell.NameSubtext_lang.length) ? `(${spellspell.NameSubtext_lang})` : "" );
            str += `_addon.aurasPlayer[${sealId}] = { -- ${name}\n`;
            str += "\t{\n";
            str += "\t\ttype = _addon.CONST.EFFECT_TYPE.JUDGEMENT_SPELL,\n";
            str += `\t\tvalue = ${remapId}\n`;
            str += "\t}\n";
            str += "};\n\n";
        }
    }

    // @ts-ignore
    const classSetNum: number = SpellClassSet[pclass.toUpperCase()];
    const classSpellSet = classSpellSets.getClassSets(classSetNum);

    str += "---@type SpellClassSet\n_addon.spellClassSet = {\n";
    for (let i = 0; i < 4; i++) {
        let sset = classSpellSet[i];
        str += `\t[${i + 1}] = {\n`;
        
        for (let bit in sset) {
            let setEntry = sset[bit];
            // Lua 1 << 31 is 2147483648 and not -2147483648
            str += `\t\t[${Math.abs(parseInt(bit))}] = {\n`;
            
            for (let spellId in setEntry) {
                const spellIdNum = parseInt(spellId);
                const spellName = spellData.getSpellName(spellIdNum).Name_lang;
                const spellspell = spellData.getSpell(spellIdNum);
                str += `\t\t\t${spellId}, -- ${spellName + ( (spellspell.NameSubtext_lang.length) ? `(${spellspell.NameSubtext_lang})` : "" )}\n`;
            }
            
            str += `\t\t},\n`;
        }

        str += `\t},\n`;
    }
    str += "};\n\n";

    if (cfg.expansion == "WOTLK")
    {
        str += getHandledClassGlyphs(spellData, classSetNum, classSpellLists, classSpellSets);
    }

    str = str.replace(/\t/gm, "    ");

    fs.writeFileSync(cfg.outputDir + "classes/" + pclass + "_spell.lua", str);
}

/**
 * Create lua files for item effect and set data
 */
async function createItemLua() {
    const isc = new ItemSetCreator(spellData, classSpellLists, classSpellSets);
    const setLua = await isc.getItemSetLua();
    fs.writeFileSync(cfg.outputDir + "itemSetData.lua", setLua.GENERAL);
    for (const classname in setLua)
    {
        if (classname == "GENERAL" || !shouldDoClass(classname)) continue;
        fs.writeFileSync(cfg.outputDir + "classes/" + classname + "_itemSetData.lua", setLua[classname as keyof typeof setLua]);
    }

    const iec = new ItemEffectsCreator(spellData, classSpellLists, classSpellSets);
    const itemLua = await iec.getItemEffectLua();
    fs.writeFileSync(cfg.outputDir + "itemEffects.lua", itemLua.GENERAL);
    for (const classname in itemLua)
    {
        if (classname == "GENERAL" || !shouldDoClass(classname)) continue;
        fs.writeFileSync(cfg.outputDir + "classes/" + classname + "_itemEffects.lua", itemLua[classname as keyof typeof itemLua]);
    }
}

for (let i = 0; i < DO_CLASSES.length; i++) {
    createLua(DO_CLASSES[i]);

    const ctlua = talentCreator.buildTalentLua(DO_CLASSES[i]);
    fs.writeFileSync(cfg.outputDir + "classes/" + DO_CLASSES[i] + "_talents.lua", ctlua);
}

const levelScalingLua = spellLevelScaling.getVariablesLua();
fs.writeFileSync(cfg.outputDir + "levelScaling.lua", levelScalingLua);

createMechanicLists([SpellMechanic.BLEED], spellData);
createItemLua();

fs.writeFileSync(cfg.outputDir + "auras.lua", playerAuras.getAuraLua());
fs.writeFileSync(cfg.outputDir + "aurasTarget.lua", targetAuras.getAuraLua());
