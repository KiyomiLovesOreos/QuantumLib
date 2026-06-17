SMODS.Consumable {
    key = "catalyst",
    set = "Tarot",
    loc_txt = {
        name = "BonusMultConsumable",
        text = {
            "Select 1 card,",
            "it gains {C:attention}Bonus{} and {C:attention}Mult{}",
        },
    },
    config = { max_highlighted = 1 },
    rarity = 1,
    cost = 1,
    unlocked = true,
    discovered = true,
    pos = { x = 0, y = 0 },
    atlas = "Tarot",
    prefix_config = { atlas = false },
    use = function(self, card, area, copier)
        local target = G.hand.highlighted[1]
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                card:juice_up(0.3, 0.5)
                target:flip()

                local pre_gen   = (target.quantum and target.quantum._generation) or 0
                local pre_cache = target.quantum and target.quantum._tooltip_cache ~= nil
                print(("[QuantumLibDemo] Catalyst pre-apply: gen=%d cache_set=%s")
                    :format(pre_gen, tostring(pre_cache)))

                target.quantum = nil
                target:set_ability(G.P_CENTERS.m_bonus)
                QuantumLib.make_quantum(target, {
                    states = { "m_bonus", "m_mult" },
                    primary = "m_bonus",
                    mode = "stack",
                })

                print(("[QuantumLibDemo] Catalyst post-apply: gen=%s cache_set=%s (expect false)")
                    :format(tostring(target.quantum._generation),
                        tostring(target.quantum._tooltip_cache ~= nil)))

                target:flip()
                target:juice_up(0.3, 0.3)
                play_sound('tarot2')
                return true
            end,
        }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.2,
            func = function()
                G.hand:unhighlight_all()
                return true
            end,
        }))
    end,
}
