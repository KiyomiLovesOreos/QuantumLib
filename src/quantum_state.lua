QuantumLib = QuantumLib or {}

local function deep_copy(t)
    if type(t) ~= 'table' then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deep_copy(v)
    end
    return copy
end
QuantumLib.deep_copy = deep_copy

function QuantumLib.build_card_ability(center)
    assert(type(center) == "table" and center.key,
        "QuantumLib.build_card_ability: center must be a SMODS center object with a .key field")
    local config = center.config or {}
    return {
        name = center.name,
        effect = center.effect,
        set = center.set,
        mult = config.mult or 0,
        h_mult = config.h_mult or 0,
        h_x_mult = config.h_x_mult or 0,
        h_dollars = config.h_dollars or 0,
        p_dollars = config.p_dollars or 0,
        t_mult = config.t_mult or 0,
        t_chips = config.t_chips or 0,
        x_mult = config.Xmult or config.x_mult or 1,
        Xmult = config.Xmult or config.x_mult or 1,
        x_chips = config.x_chips or 1,
        bonus = config.bonus or 0,
        extra = deep_copy(config.extra),
    }
end

function QuantumLib.make_quantum(card, opts)
    assert(card, "QuantumLib.make_quantum: card is required")
    assert(opts and opts.states and #opts.states > 0,
        "QuantumLib.make_quantum: opts.states must be a non-empty list of center keys")

    assert(not card.quantum,
        "QuantumLib.make_quantum: card already has quantum data — set card.quantum = nil before calling make_quantum again")

    local mode = opts.mode or "cycle"
    assert(mode == "cycle" or mode == "superposition" or mode == "stack",
        ("QuantumLib.make_quantum: mode must be 'cycle', 'superposition', or 'stack', got '%s'"):format(tostring(mode)))

    local states = {}
    for _, key in ipairs(opts.states) do
        local center = G.P_CENTERS[key]
        assert(center, ("QuantumLib.make_quantum: unknown center '%s'"):format(key))
        states[key] = {
            key = key,
            center = center,
            ability = (mode == "stack") and QuantumLib.build_card_ability(center) or deep_copy(center.config),
        }
    end

    if mode == "stack" then
        assert(opts.primary and states[opts.primary],
            "QuantumLib.make_quantum: stack mode requires opts.primary to be one of opts.states")
        assert(not states["m_lucky"] or opts.primary == "m_lucky",
            "QuantumLib.make_quantum: stack mode requires 'm_lucky' to be opts.primary if present")

        card.quantum = {
            mode = mode,
            states = states,
            primary = opts.primary,
            order = opts.states,
        }

        card.config.center = states[opts.primary].center
        card.config.center_key = opts.primary

        card.ability.quantum_order = deep_copy(opts.states)
        card.ability.quantum_primary = opts.primary

        QuantumLib.recompute_stack(card)

        return card.quantum
    end

    local initial = opts.initial or opts.states[1]
    assert(states[initial],
        ("QuantumLib.make_quantum: initial state '%s' is not in opts.states"):format(initial))

    card.quantum = {
        mode   = mode,
        states = states,
        active = initial,
        order  = opts.states,
    }

    return card.quantum
end

function QuantumLib.get_state(card, state_key)
    assert(card.quantum, "QuantumLib.get_state: card has no quantum data (call make_quantum first)")
    local state = card.quantum.states[state_key]
    assert(state, ("QuantumLib.get_state: card has no state '%s'"):format(state_key))
    return state
end

function QuantumLib.get_active_state(card)
    assert(card.quantum, "QuantumLib.get_active_state: card has no quantum data (call make_quantum first)")
    local key = card.quantum.active or card.quantum.primary
    return QuantumLib.get_state(card, key)
end

function QuantumLib.has_enhancement(card, key)
    assert(type(key) == "string",
        ("QuantumLib.has_enhancement: key must be a string, got %s"):format(type(key)))
    if not card.quantum then return false end
    if card.quantum.mode == "cycle" then
        return card.quantum.active == key
    end
    return card.quantum.states[key] ~= nil
end

function QuantumLib.add_state(card, key)
    assert(card.quantum, "QuantumLib.add_state: card has no quantum data (call make_quantum first)")
    assert(card.quantum.mode == "stack",
        ("QuantumLib.add_state: card is in '%s' mode — add_state only works for stack mode"):format(card.quantum.mode))
    assert(type(key) == "string",
        ("QuantumLib.add_state: key must be a string, got %s"):format(type(key)))
    assert(not card.quantum.states[key],
        ("QuantumLib.add_state: card already has state '%s'"):format(key))
    assert(key ~= "m_lucky",
        "QuantumLib.add_state: 'm_lucky' must be the primary state — to add Lucky Card, rebuild the stack with make_quantum using primary='m_lucky'")
    local center = G.P_CENTERS[key]
    assert(center, ("QuantumLib.add_state: unknown center '%s'"):format(key))

    card.quantum.states[key] = {
        key    = key,
        center = center,
        ability = QuantumLib.build_card_ability(center),
    }
    card.quantum.order[#card.quantum.order + 1] = key
    card.ability.quantum_order = deep_copy(card.quantum.order)
    QuantumLib.recompute_stack(card)
end

function QuantumLib.remove_state(card, key)
    assert(card.quantum, "QuantumLib.remove_state: card has no quantum data (call make_quantum first)")
    assert(card.quantum.mode == "stack",
        ("QuantumLib.remove_state: card is in '%s' mode — remove_state only works for stack mode"):format(card.quantum.mode))
    assert(type(key) == "string",
        ("QuantumLib.remove_state: key must be a string, got %s"):format(type(key)))
    assert(card.quantum.states[key],
        ("QuantumLib.remove_state: card has no state '%s'"):format(key))
    assert(key ~= card.quantum.primary,
        ("QuantumLib.remove_state: cannot remove the primary state '%s' — assign card.quantum.primary to another state first, or use make_quantum to rebuild the stack"):format(key))

    card.quantum.states[key] = nil
    local new_order = {}
    for _, k in ipairs(card.quantum.order) do
        if k ~= key then new_order[#new_order + 1] = k end
    end
    card.quantum.order = new_order
    card.ability.quantum_order = deep_copy(new_order)
    QuantumLib.recompute_stack(card)
end

function QuantumLib.stack_enhancement(card, key)
    assert(type(key) == "string",
        ("QuantumLib.stack_enhancement: key must be a string, got %s"):format(type(key)))
    local center = G.P_CENTERS[key]
    assert(center, ("QuantumLib.stack_enhancement: unknown center '%s'"):format(key))
    assert(center.set == "Enhanced",
        ("QuantumLib.stack_enhancement: '%s' is not an enhancement (set='%s') — stack_enhancement only works with Enhanced centers"):format(key, tostring(center.set)))

    if card.quantum and card.quantum.mode == "stack" then
        if card.quantum.states[key] then return false end

        if key == "m_lucky" then
            local new_order = { "m_lucky" }
            for _, k in ipairs(card.quantum.order) do
                new_order[#new_order + 1] = k
            end
            card.quantum = nil
            card.ability.quantum_order = nil
            card.ability.quantum_primary = nil
            card.ability.quantum_live_rule_center = nil
            QuantumLib.make_quantum(card, { states = new_order, primary = "m_lucky", mode = "stack" })
        else
            QuantumLib.add_state(card, key)
        end
        return true
    end

    assert(card.config and card.config.center and card.config.center.set == "Enhanced",
        "QuantumLib.stack_enhancement: card does not have an existing enhancement — apply an enhancement first, or use make_quantum directly")
    local current_key = card.config.center_key
    if current_key == key then return false end

    local primary, order
    if key == "m_lucky" then
        primary = "m_lucky"
        order   = { "m_lucky", current_key }
    else
        primary = current_key
        order   = { current_key, key }
    end
    QuantumLib.make_quantum(card, { states = order, primary = primary, mode = "stack" })
    return true
end
