QuantumLib._stack_rules_by_center = QuantumLib._stack_rules_by_center or {}
QuantumLib._stack_rule_specs = QuantumLib._stack_rule_specs or {}
QuantumLib._effective_rule_cache = QuantumLib._effective_rule_cache or {}
QuantumLib._pending_sweep_keys = QuantumLib._pending_sweep_keys or {}
QuantumLib._sweep_scheduled = QuantumLib._sweep_scheduled or false

local function _schedule_sweep(center_keys_set)
    for k in pairs(center_keys_set) do
        QuantumLib._pending_sweep_keys[k] = true
    end
    if QuantumLib._sweep_scheduled then return end
    QuantumLib._sweep_scheduled = true
    G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = function()
            QuantumLib._sweep_scheduled = false
            for _, card in ipairs(G.playing_cards or {}) do
                if card.config and card.config.center
                    and QuantumLib._pending_sweep_keys[card.config.center.key] then
                    QuantumLib._apply_live_rule(card, card.config.center)
                end
            end
            for k in pairs(QuantumLib._pending_sweep_keys) do
                QuantumLib._pending_sweep_keys[k] = nil
            end
            return true
        end
    }))
end

function QuantumLib._stack_rule_provider_key(owner)
    if owner.config and owner.config.center and owner.config.center.key then
        return owner.config.center.key
    end
    return owner.key
end

function QuantumLib._count_live_providers(provider_key, exclude_card)
    local count = 0
    for _, area in ipairs({ G.jokers, G.consumeables }) do
        if area and area.cards then
            for _, c in ipairs(area.cards) do
                if c ~= exclude_card and c.config and c.config.center
                    and c.config.center.key == provider_key then
                    count = count + 1
                end
            end
        end
    end
    return count
end

function QuantumLib._effective_rule(center_key)
    local cached = QuantumLib._effective_rule_cache[center_key]
    if cached ~= nil then return cached or nil end

    local entries = QuantumLib._stack_rules_by_center[center_key]
    if not entries or #entries == 0 then
        QuantumLib._effective_rule_cache[center_key] = false
        return nil
    end

    local seen = { [center_key] = true }
    local states = { center_key }
    for _, entry in ipairs(entries) do
        for _, extra in ipairs(entry.extra_states) do
            if not seen[extra] then
                seen[extra] = true
                states[#states + 1] = extra
            end
        end
    end

    if #states == 1 then
        QuantumLib._effective_rule_cache[center_key] = false
        return nil
    end
    local result = { states = states, primary = center_key }
    QuantumLib._effective_rule_cache[center_key] = result
    return result
end

function QuantumLib._apply_live_rule(card, center)
    if card.quantum and card.quantum._live_rule_center then
        card.quantum = nil
        card.ability.quantum_order = nil
        card.ability.quantum_primary = nil
        card.ability.quantum_live_rule_center = nil
    end

    local rule = QuantumLib._effective_rule(center.key)
    if rule then
        QuantumLib.make_quantum(card, {
            states = rule.states,
            primary = rule.primary,
            mode = "stack",
        })
        card.quantum._live_rule_center = center.key
        card.ability.quantum_live_rule_center = center.key
    end
end

function QuantumLib.enable_live_stacking()
    if QuantumLib._live_stacking_enabled then return end
    QuantumLib._live_stacking_enabled = true

    local original_set_ability = Card.set_ability
    function Card:set_ability(center, initial, delay_sprites)
        local ret = original_set_ability(self, center, initial, delay_sprites)
        if self.playing_card and QuantumLib._stack_rules_by_center[self.config.center.key] then
            QuantumLib._apply_live_rule(self, self.config.center)
        end
        return ret
    end
end

function QuantumLib.enable_stack_rule_cleanup()
    if QuantumLib._stack_rule_cleanup_enabled then return end
    QuantumLib._stack_rule_cleanup_enabled = true

    local original_remove_from_deck = Card.remove_from_deck
    function Card:remove_from_deck(deck_table, from_debuff)
        QuantumLib.unregister_stack_rule(self)
        return original_remove_from_deck(self, deck_table, from_debuff)
    end
end

function QuantumLib.register_stack_rule(owner, rules)
    assert(owner ~= nil, "QuantumLib.register_stack_rule: owner is required")

    local provider_key = QuantumLib._stack_rule_provider_key(owner)
    assert(provider_key, "QuantumLib.register_stack_rule: could not derive a provider_key from owner")

    if not QuantumLib._stack_rule_specs[provider_key] then
        QuantumLib._stack_rule_specs[provider_key] = rules

        for center_key, spec in pairs(rules) do
            QuantumLib._stack_rules_by_center[center_key] = QuantumLib._stack_rules_by_center[center_key] or {}
            local entries = QuantumLib._stack_rules_by_center[center_key]
            entries[#entries + 1] = { provider_key = provider_key, extra_states = spec.extra_states }
            QuantumLib._effective_rule_cache[center_key] = nil
        end
    end

    QuantumLib.enable_live_stacking()
    QuantumLib.enable_stack_rule_cleanup()

    _schedule_sweep(rules)
end

function QuantumLib.unregister_stack_rule(owner)
    if not next(QuantumLib._stack_rule_specs) then return end
    local provider_key = QuantumLib._stack_rule_provider_key(owner)
    if not provider_key then return end

    local rules = QuantumLib._stack_rule_specs[provider_key]
    if not rules then return end

    if QuantumLib._count_live_providers(provider_key, owner) > 0 then return end

    QuantumLib._stack_rule_specs[provider_key] = nil

    local affected = {}
    for center_key in pairs(rules) do
        local entries = QuantumLib._stack_rules_by_center[center_key]
        if entries then
            for i = #entries, 1, -1 do
                if entries[i].provider_key == provider_key then
                    table.remove(entries, i)
                end
            end
            if #entries == 0 then
                QuantumLib._stack_rules_by_center[center_key] = nil
            end
        end
        QuantumLib._effective_rule_cache[center_key] = nil
        affected[center_key] = true
    end

    _schedule_sweep(affected)
end
