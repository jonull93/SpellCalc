---@class AddonEnv
local _addon = select(2, ...);
local _, playerClass = UnitClass("player");
if playerClass ~= "PRIEST" then
    return;
end

local WEAKENED_SOUL = GetSpellInfo(6788);
local SHADOW_WORD_PAIN = GetSpellInfo(48125);

---@type TalentDataRawEntry[]
_addon.talentDataRaw = {
    -----------------------------
    -- Discipline
    -----------------------------
    { -- Twin Disciplines
        tree = 1,
        tier = 1,
        column = 3,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_DAMAGE_HEALING,
                affectSpell = {-1713373184, 622610 + 32},
                perPoint = 1
            },
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_OVER_TIME,
                affectSpell = {35684416, 0, 64},
                perPoint = 1
            }
        }
    },
    { -- Meditation
        tree = 1,
        tier = 3,
        column = 1,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.FSR_SPIRIT_REGEN,
                values = {17, 33, 50}
            }
        }
    },
    { -- Improved Power Word: Shield
        tree = 1,
        tier = 3,
        column = 3,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_EFFECT,
                affectSpell = {1},
                perPoint = 5
            }
        }
    },
    { -- Focused Power
        tree = 1,
        tier = 6,
        column = 1,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SCHOOLMOD_PCT_DAMAGE,
                affectMask = _addon.CONST.SCHOOL_MASK.ALL_SPELL,
                perPoint = 2
            },
            {
                type = _addon.CONST.EFFECT_TYPE.PCT_HEALING,
                perPoint = 2
            }
        }
    },
    { -- Renewed Hope
        tree = 1,
        tier = 8,
        column = 1,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SCRIPT_SPELLMOD_CRIT_CHANCE,
                affectSpell = {2048 + 4096, 65536},
                scriptKey = "Renewed_Hope_Crit",
                perPoint = 2
            },
            {
                type = _addon.CONST.EFFECT_TYPE.SCRIPT_TARGET_UPDATE_ON_AURA,
                scriptKey = WEAKENED_SOUL,
                perPoint = 0
            }
        }
    },
    { -- Divine Aegis
        tree = 1,
        tier = 9,
        column = 1,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_EXTRA_ON_CRIT,
                affectSpell = {512 + 2048 + 4096 + 134217728, 4 + 65536 + 4194304, 4},
                perPoint = 10
            }
        }
    },
    { -- Borrowed Time
        tree = 1,
        tier = 10,
        column = 2,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_FLAT_SPELL_SCALE,
                affectSpell = {1},
                perPoint = 8
            }
        }
    },
    -----------------------------
    -- Holy
    -----------------------------
    { -- Improved Renew
        tree = 2,
        tier = 1,
        column = 2,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_OVER_TIME,
                affectSpell = {64},
                perPoint = 5
            }
        }
    },
    { -- Searing Light
        tree = 2,
        tier = 4,
        column = 3,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_DAMAGE_HEALING,
                affectSpell = {5243008, 32768},
                perPoint = 5
            },
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_OVER_TIME,
                affectSpell = {1048576},
                perPoint = 5
            }
        }
    },
    { -- Spiritual Healing
        tree = 2,
        tier = 6,
        column = 3,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_DAMAGE_HEALING,
                affectSpell = {419700288, 134283268, 4},
                perPoint = 2
            },
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_OVER_TIME,
                affectSpell = {419700288, 134283268, 4},
                perPoint = 2
            }
        }
    },
    { -- Spiritual Healing
        tree = 2,
        tier = 7,
        column = 3,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.PCT_HEALING,
                perPoint = 1
            },
        }
    },
    { -- Empowered Healing
        tree = 2,
        tier = 8,
        column = 2,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_FLAT_SPELL_SCALE,
                affectSpell = {4096},
                perPoint = 8
            },
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_FLAT_SPELL_SCALE,
                affectSpell = {2048, 4},
                perPoint = 4
            }
        }
    },
    { -- Empowered Renew
        tree = 2,
        tier = 9,
        column = 1,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_SPELL_SCALE,
                affectSpell = {64},
                perPoint = 5
            },
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_DOT_ON_HIT,
                affectSpell = {64},
                perPoint = 5
            }
        }
    },
    { -- Divine Providence
        tree = 2,
        tier = 10,
        column = 2,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_DAMAGE_HEALING,
                affectSpell = {402653696, 4, 4},
                perPoint = 2
            },
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_OVER_TIME,
                affectSpell = {0, 0, 4},
                perPoint = 2
            }
        }
    },
    -----------------------------
    -- Shadow
    -----------------------------
    { -- Darkness
        tree = 3,
        tier = 1,
        column = 3,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_DAMAGE_HEALING,
                affectSpell = {41951232, 524290},
                perPoint = 2
            },
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_OVER_TIME,
                affectSpell = {33587200, 1024, 64},
                perPoint = 2
            }
        }
    },
    { -- Improved Shadow Word: Pain
        tree = 3,
        tier = 2,
        column = 2,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_OVER_TIME,
                affectSpell = {32768},
                perPoint = 3
            }
        }
    },
    { -- Shadow Focus
        tree = 3,
        tier = 2,
        column = 3,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_FLAT_HIT_CHANCE,
                affectSpell = {109814020, 3933258, 8520},
                perPoint = 1
            }
        }
    },
    { -- Mind Melt
        tree = 3,
        tier = 6,
        column = 1,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_FLAT_CRIT_CHANCE,
                affectSpell = {8396800, 524288, 64},
                perPoint = 2
            },
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_FLAT_CRIT_CHANCE,
                affectSpell = {33587200, 1024},
                perPoint = 3
            }
        }
    },
    { -- Improved Devouring Plague
        tree = 3,
        tier = 6,
        column = 3,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_OVER_TIME,
                affectSpell = {33554432},
                perPoint = 5
            },
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_DOT_ON_HIT,
                affectSpell = {33554432},
                perPoint = 10
            }
        }
    },
    { -- Shadow Power
        tree = 3,
        tier = 7,
        column = 3,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_CRIT_MULT,
                affectSpell = {8396800, 2, 64},
                perPoint = 20
            }
        }
    },
    { -- Misery
        tree = 3,
        tier = 8,
        column = 3,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_SPELL_SCALE,
                affectSpell = {8396800, 524288, 64},
                perPoint = 5
            }
        }
    },
    { -- Twisted Faith
        tree = 3,
        tier = 10,
        column = 3,
        effects = {
            {
                type = _addon.CONST.EFFECT_TYPE.SCRIPT_SPELLMOD_DONE_PCT,
                affectSpell = {8388608 + 8192, 0, 64},
                scriptKey = "Twisted_Faith_SWP",
                perPoint = 2
            },
            {
                type = _addon.CONST.EFFECT_TYPE.SCRIPT_TARGET_UPDATE_ON_AURA_PERSONAL,
                scriptKey = SHADOW_WORD_PAIN,
                perPoint = 0
            }
        }
    },
};

--------------------------------------------------------------------------
-- Player auras
--------------------------------------------------------------------------

_addon.aurasPlayer[59891] = { -- Borrowed Time (trigger update for haste)
    {
        type = _addon.CONST.EFFECT_TYPE.TRIGGER_UPDATE,
        value = 0,
    }
}

_addon.aurasPlayer[33151] = { -- Surge of Light
    {
        type = _addon.CONST.EFFECT_TYPE.SPELLMOD_FLAT_CRIT_CHANCE,
        affectSpell = {128 + 2048},
        value = -100,
    }
}

_addon.aurasPlayer[15258] = { -- Shadow Weaving
    {
        type = _addon.CONST.EFFECT_TYPE.SCHOOLMOD_PCT_DAMAGE,
        affectMask = _addon.CONST.SCHOOL_MASK.SHADOW,
        value = 2,
        hasStacks = true
    }
}

-- Shadowform
_addon.aurasPlayer[15473] = {
    {
        type = _addon.CONST.EFFECT_TYPE.SCHOOLMOD_PCT_DAMAGE,
        affectMask = _addon.CONST.SCHOOL_MASK.SHADOW,
        value = 15,
    },
    {
        type = _addon.CONST.EFFECT_TYPE.SPELLMOD_ALLOW_PERIODIC_CRIT,
        affectSpell = {33587200, 1024},
        value = 1,
    },
    {
        type = _addon.CONST.EFFECT_TYPE.SPELLMOD_PCT_CRIT_MULT,
        affectSpell = {33587200, 1024},
        value = 100,
    },
    {
        type = _addon.CONST.EFFECT_TYPE.SPELLMOD_ALLOW_PERIODIC_HASTE,
        affectSpell = {33554432, 1024},
        value = 1,
    }
}

-- Inner Focus
_addon.aurasPlayer[14751] = {
    {type = _addon.CONST.EFFECT_TYPE.SPELLMOD_FLAT_CRIT_CHANCE,
    affectSpell = {-908837232, 13205558, 64},
    value = 25}
}

--------------------------------------------------------------------------
-- Target auras
--------------------------------------------------------------------------

_addon.aurasTarget[64844] = { -- Divine Hymn
    {
        type = _addon.CONST.EFFECT_TYPE.TARGET_HEALING_RECIEVED,
        value = 10
    }
};

_addon.aurasTarget[47930] = { -- Grace
    {
        type = _addon.CONST.EFFECT_TYPE.TARGET_HEALING_RECIEVED,
        value = 3,
        hasStacks = true
    }
};

--------------------------------------------------------------------------
-- Additional Glyphs (generated effects are in <class>_spell.lua)
--------------------------------------------------------------------------

--[[ _addon.classGlyphs[54743] = { -- Glyph of Regrowth
    {
        type = _addon.CONST.EFFECT_TYPE.SCRIPT_SPELLMOD_DONE_PCT,
        affectSpell = {64},
        value = 20,
        scriptKey = "Glyph_of_Regrowth",
    },
} ]]

--------------------------------------------------------------------------
-- Passives
--------------------------------------------------------------------------

---@type UnitAuraEffect[]
_addon.classPassives = {
    { -- Allow MF crit (MF was made a duration effect in this addon because I was lazy...)
        type = _addon.CONST.EFFECT_TYPE.SPELLMOD_ALLOW_PERIODIC_CRIT,
        affectSpell = {0, 0, 64},
        value = 1
    }
}

--------------------------------------------------------------------------
-- Scripts
--------------------------------------------------------------------------

_addon.scripting.RegisterScript("Renewed_Hope_Crit", function (val, cs, ce, spellId, si, scriptType, spellName)
    if _addon.Target.HasAuraName(WEAKENED_SOUL) then
        cs.critChance = cs.critChance + val;
    end
end);

_addon.scripting.RegisterScript("Twisted_Faith_SWP", function (val, cs, ce, spellId, si, scriptType, spellName)
    assert(ce, "Twisted_Faith_SWP called with ce nil!");
    if _addon.Target.HasAuraName(SHADOW_WORD_PAIN, true) then
        ce.modBonus = ce.modBonus * (1 + val/100);
    end
end);
