SMODS.Joker {
    key = "qubit",
    loc_txt = {
        name = "Qubit Joker",
        text = {
            "Card 3 is in {C:attention}superposition{}",
            "of {C:attention}Mult{} and {C:attention}Bonus{}.",
            "{C:chips}+5 Chips{}/{C:mult}+1 Mult{} each hand.",
            "Collapses to the stronger when scored",
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
        local c3 = G.playing_cards[3]
        if c3 and not c3.quantum then
            c3:set_ability(G.P_CENTERS.m_mult)
            QuantumLib.make_quantum(c3, {
                states  = { "m_mult", "m_bonus" },
                initial = "m_mult",
                mode    = "superposition",
            })
            print(("[QuantumLibDemo] Qubit: card3 Mult+Bonus superposition"))
        end
    end,
    calculate = function(self, card, context)
        if context.before then
            for _, c in ipairs(G.playing_cards or {}) do
                if c.quantum and c.quantum.mode == "superposition" then
                    QuantumLib.update_all(c, function(_, state)
                        -- identify by ability field: m_mult has .mult, m_bonus has .bonus
                        if state.ability.mult then
                            state.ability.mult = state.ability.mult + 1
                        elseif state.ability.bonus then
                            state.ability.bonus = state.ability.bonus + 5
                        end
                    end)
                    print(("[QuantumLibDemo] Qubit: accumulated on superposition card"))
                end
            end
            return
        end

        if context.individual and context.other_card then
            local target = context.other_card
            if target.quantum and target.quantum.mode == "superposition" then
                return QuantumLib.collapse(target, context,
                    function(_, states, _)
                        local m_state = states["m_mult"]
                        local b_state = states["m_bonus"]
                        local mult_val = (m_state and m_state.ability.mult or 0) * 4
                        local bonus_val = b_state and b_state.ability.bonus or 0
                        local chosen = mult_val >= bonus_val and "m_mult" or "m_bonus"
                        print(("[QuantumLibDemo] Qubit: collapse -> %s (mult_val=%d bonus_val=%d)"):format(chosen, mult_val, bonus_val))
                        return chosen
                    end,
                    function(_, state, _)
                        if state.ability.mult then
                            local m = state.ability.mult
                            return { mult = m, message = "Collapse! +" .. m .. " Mult" }
                        else
                            local b = state.ability.bonus or 0
                            return { chips = b, message = "Collapse! +" .. b .. " Chips" }
                        end
                    end
                )
            end
        end
    end,
}
