-- AffixData.lua
-- Pure data: tier definitions and per-affix configuration.
-- All logic and UI live in UI/Affixes.lua.
--
-- To edit a tactic: find the affix ID below and change its tactic field.
-- Use \n for line breaks. Find affix IDs in-game: /dump C_MythicPlus.GetCurrentAffixes()

BossHelper.AffixData = {}

------------------------------------------------------------------------
-- Tier bands – the five key-level columns shown in the UI.
-- tierDesc is the static explanatory text shown at the top of each column.
------------------------------------------------------------------------
BossHelper.AffixData.Tiers = {
    {
        label       = "+2 to +4",
        minLevel    = 2,
        maxLevel    = 4,
        colorBg     = { 0.05, 0.18, 0.05, 0.95 },   -- grøn
        colorBorder = { 0.30, 0.85, 0.30, 0.90 },
        tierDesc    = "nil",
    },
    {
        label       = "+5 to +6",
        minLevel    = 5,
        maxLevel    = 6,
        colorBg     = { 0.14, 0.14, 0.04, 0.95 },   -- gul-grøn
        colorBorder = { 0.75, 0.80, 0.20, 0.90 },
        tierDesc    = "nil",
    },
    {
        label       = "+7 to +9",
        minLevel    = 7,
        maxLevel    = 9,
        colorBg     = { 0.18, 0.10, 0.02, 0.95 },   -- orange
        colorBorder = { 0.95, 0.60, 0.15, 0.90 },
        tierDesc    = "nil",
    },
    {
        label       = "+10 to +11",
        minLevel    = 10,
        maxLevel    = 11,
        colorBg     = { 0.22, 0.05, 0.03, 0.95 },   -- rød-orange
        colorBorder = { 0.95, 0.35, 0.15, 0.90 },
        tierDesc    = "nil",
    },
    {
        label       = "+12 and up",
        minLevel    = 12,
        maxLevel    = 999,
        colorBg     = { 0.25, 0.03, 0.03, 0.95 },   -- dyb rød
        colorBorder = { 1.00, 0.15, 0.15, 0.90 },
        tierDesc    = "nil",
    },
}

------------------------------------------------------------------------
-- Affix definitions – one entry per affix ID.
--
-- range  = { minLevel, maxLevel } for this affix.
--          Tyrannical (9) / Fortified (10) have NO range here –
--          their active tier is resolved at runtime in Affixes.lua.
-- tactic = tooltip text on hover. Use \n for line breaks.
------------------------------------------------------------------------
BossHelper.AffixData.Affixes = {
    -- +2 to +4 ------------------------------------------------------------
    [165] = {
        range  = { 2, 4 },
        tactic = "Some enemies are marked and take extra damage. Player deaths do not reduce timer. Focus marked targets and play safe while learning dungeon.",
    },
    -- +5 to +11 – Xal'atath's Bargains (1 aktiv pr. uge) ----------------
    [148] = {
        range  = { 5, 11 },
        tactic = "Stop orbs with interrupts/CC/knockbacks/purges. Missed casts give enemies +20% Haste & movement speed per orb, stopped casts give party +2% Haste & movement speed per orb (up to +20% for 30 sec).",
    },
    [158] = {
        range  = { 5, 11 },
        tactic = "Swap and kill Void Emissary fast. Stop Dark Prayer casts. If it lives, enemies gain stacking damage reduction. On kill: party gets +20% Versatility and +30% cooldown speed for 30 sec.",
    },
    [162] = {
        range  = { 5, 11 },
        tactic = "Drag your orb into allies before 15 sec. If it explodes, enemies gain +10% damage done and -20% damage taken (stacks). If collected, party gains +4% Mastery and +2% Leech for 30 sec (stacks).",
    },
    [160] = {
        range  = { 5, 11 },
        tactic = "Dispel or heal absorbs within 15 sec. If it expires: enemies gain +10% damage done and -20% damage taken (stacks). If removed: party gains +4% Crit and +2% max health for 30 sec (stacks).",
    },
    -- +7 and up – range resolved from API rotation (see Affixes.lua) -----
    [9] = {
        tactic = "Bosses have +25% health and deal up to +15% damage. Save cooldowns for bosses and play single-target focused.",
    },
    [10] = {
        tactic = "Trash mobs have +20% health and deal up to +20% damage. Focus AoE, CC and safe pulls.",
    },
    -- +12+ ----------------------------------------------------------------
    [147] = {
        range  = { 12, 999 },
        tactic = "Dungeon timer increases by +90 sec. Each death removes -15 sec.\nPlay clean and avoid dying. Use defensives for heavy damage instead of relying on healer saves. Focus on survival first, speed second.",
    },
}
