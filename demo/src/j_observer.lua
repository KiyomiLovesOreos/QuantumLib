SMODS.Joker {
    key = "observer",
    loc_txt = {
        name = "Observer",
        text = {
            "+{C:mult}3 Mult{} per {C:attention}Bonus{}",
            "card and +{C:mult}3 Mult{} per",
            "{C:attention}Mult{} card in your deck",
            "(quantum-aware)",
        },
    },
    config = {},
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    pos = { x = 1, y = 0 },
    atlas = "Joker",
    prefix_config = { atlas = false },
    in_pool = function(self)
        return QuantumLibDemo.config.show_debug_jokers ~= false
    end,
    calculate = function(self, card, context)
        if context.before then
            local bonus_count = QuantumLib.get_enhancement_tally("m_bonus")
            local mult_count  = QuantumLib.get_enhancement_tally("m_mult")
            local total = (bonus_count + mult_count) * 3
            if total > 0 then
                print(("[QuantumLibDemo] Observer: bonus=%d mult=%d -> +%d Mult"):format(bonus_count, mult_count, total))
                return { mult = total, message = "+" .. total .. " Mult" }
            end
        end
    end,
}
