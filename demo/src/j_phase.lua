SMODS.Joker {
    key = "phase",
    loc_txt = {
        name = "Phase Joker",
        text = {
            "On pickup: cards 1 & 2 cycle",
            "between {C:attention}Bonus{}/{C:attention}Mult{}",
            "and {C:attention}Steel{}/{C:attention}Glass{}.",
            "Each advances when it scores",
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
        QuantumLib.register_hooks("m_bonus", {
            on_enter = function(c) c:juice_up(0.3, 0.2) end,
        })
        QuantumLib.register_hooks("m_steel", {
            on_enter = function(c) c:juice_up(0.3, 0.2) end,
        })

        local c1 = G.playing_cards[1]
        if c1 and not c1.quantum then
            c1:set_ability(G.P_CENTERS.m_bonus)
            QuantumLib.make_quantum(c1, {
                states  = { "m_bonus", "m_mult" },
                initial = "m_bonus",
                mode    = "cycle",
            })
            c1.ability = c1.quantum.states["m_bonus"].ability
            print(("[QuantumLibDemo] Phase: card1 Bonus+Mult cycle, active=%s"):format(c1.quantum.active))
        end

        local c2 = G.playing_cards[2]
        if c2 and not c2.quantum then
            c2:set_ability(G.P_CENTERS.m_steel)
            QuantumLib.make_quantum(c2, {
                states  = { "m_steel", "m_glass" },
                initial = "m_steel",
                mode    = "cycle",
            })
            c2.ability = c2.quantum.states["m_steel"].ability
            print(("[QuantumLibDemo] Phase: card2 Steel+Glass cycle, active=%s"):format(c2.quantum.active))
        end
    end,
    calculate = function(self, card, context)
        if context.individual and context.other_card then
            local target = context.other_card
            if target.quantum and target.quantum.mode == "cycle" then
                local order = target.quantum.order
                local current = target.quantum.active
                for i, key in ipairs(order) do
                    if key == current then
                        local next_key = order[(i % #order) + 1]
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.15,
                            func = function()
                                QuantumLib.set_state(target, next_key)
                                return true
                            end,
                        }))
                        print(("[QuantumLibDemo] Phase: queued advance %s -> %s"):format(current, next_key))
                        break
                    end
                end
            end
        end
    end,
}
