SMODS.Joker {
    key = "enhancer",
    loc_txt = {
        name = "Quantum Test1",
        text = {
            "The first 3 cards in your deck",
            "become {C:attention}Bonus{} AND {C:attention}Mult{},",
            "{C:attention}Lucky{} AND {C:attention}Glass{},",
            "{C:attention}Steel{} AND {C:attention}Gold{}",
            "applied once, on pickup",
        },
    },
    config = {},
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    pos = { x = 0, y = 0 },
    atlas = "Joker",
    prefix_config = { atlas = false },
    in_pool = function(self)
        return QuantumLibDemo.config.show_debug_jokers ~= false
    end,
    add_to_deck = function(self, card, from_debuff)
        local bonus_mult_card = G.playing_cards[1]
        if bonus_mult_card then
            bonus_mult_card:set_ability(G.P_CENTERS.m_bonus)
            QuantumLib.make_quantum(bonus_mult_card, {
                states = { "m_bonus", "m_mult" },
                primary = "m_bonus",
                mode = "stack",
            })
            print(("[QuantumLibDemo] bonus+mult: bonus=%s mult=%s gen=%d cache_nil=%s")
                :format(tostring(bonus_mult_card.ability.bonus), tostring(bonus_mult_card.ability.mult),
                    bonus_mult_card.quantum._generation,
                    tostring(bonus_mult_card.quantum._tooltip_cache == nil)))
        end

        local lucky_glass_card = G.playing_cards[2]
        if lucky_glass_card then
            lucky_glass_card:set_ability(G.P_CENTERS.m_lucky)
            QuantumLib.make_quantum(lucky_glass_card, {
                states = { "m_lucky", "m_glass" },
                primary = "m_lucky",
                mode = "stack",
            })
            print(("[QuantumLibDemo] lucky+glass: effect=%s mult=%s p_dollars=%s x_mult=%s gen=%d cache_nil=%s")
                :format(tostring(lucky_glass_card.ability.effect), tostring(lucky_glass_card.ability.mult),
                    tostring(lucky_glass_card.ability.p_dollars), tostring(lucky_glass_card.ability.x_mult),
                    lucky_glass_card.quantum._generation,
                    tostring(lucky_glass_card.quantum._tooltip_cache == nil)))

            local enhancements = {}
            for key, _ in pairs(SMODS.get_enhancements(lucky_glass_card)) do
                enhancements[#enhancements + 1] = key
            end
            table.sort(enhancements)
            print(("[QuantumLibDemo] lucky+glass enhancements: %s"):format(table.concat(enhancements, ",")))
        end

        local steel_gold_card = G.playing_cards[3]
        if steel_gold_card then
            steel_gold_card:set_ability(G.P_CENTERS.m_steel)
            QuantumLib.make_quantum(steel_gold_card, {
                states = { "m_steel", "m_gold" },
                primary = "m_steel",
                mode = "stack",
            })
            print(("[QuantumLibDemo] steel+gold: h_x_mult=%s h_dollars=%s gen=%d cache_nil=%s")
                :format(tostring(steel_gold_card.ability.h_x_mult), tostring(steel_gold_card.ability.h_dollars),
                    steel_gold_card.quantum._generation,
                    tostring(steel_gold_card.quantum._tooltip_cache == nil)))
        end
    end,
}
