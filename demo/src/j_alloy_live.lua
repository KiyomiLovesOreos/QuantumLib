SMODS.Joker {
    key = "alloy_live",
    loc_txt = {
        name = "Quantum Test3",
        text = {
            "{C:attention}Steel{} cards also count as",
            "{C:attention}Gold{} cards, and vice versa",
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
        QuantumLib.register_stack_rule(self, {
            m_steel = { extra_states = { "m_gold" } },
            m_gold  = { extra_states = { "m_steel" } },
        })
    end,
}
