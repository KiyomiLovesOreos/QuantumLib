SMODS.Joker {
    key = "alloy_live_wild",
    loc_txt = {
        name = "Quantum Test2",
        text = {
            "{C:attention}Steel{} cards also count as",
            "{C:attention}Wild{} cards, and vice versa",
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
    add_to_deck = function(self, card, from_debuff)
        QuantumLib.register_stack_rule(self, {
            m_steel = { extra_states = { "m_wild" } },
            m_wild  = { extra_states = { "m_steel" } },
        })
    end,
}
