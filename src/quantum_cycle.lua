QuantumLib._hooks = QuantumLib._hooks or {}

function QuantumLib.register_hooks(center_key, hooks)
    assert(type(center_key) == "string", "QuantumLib.register_hooks: center_key must be a string")
    assert(type(hooks) == "table", "QuantumLib.register_hooks: hooks must be a table")
    local entry = QuantumLib._hooks[center_key] or {}
    if hooks.on_enter then entry.on_enter = hooks.on_enter end
    if hooks.on_exit then entry.on_exit = hooks.on_exit end
    QuantumLib._hooks[center_key] = entry
end

function QuantumLib.set_state(card, state_key)
    assert(card.quantum, "QuantumLib.set_state: card has no quantum data (call make_quantum first)")

    local new_state = QuantumLib.get_state(card, state_key)
    if card.quantum.active == state_key then return end

    local old_state = QuantumLib.get_state(card, card.quantum.active)
    local old_hooks = QuantumLib._hooks[old_state.key]
    if old_hooks and old_hooks.on_exit then
        old_hooks.on_exit(card, old_state)
    end

    card.ability = new_state.ability
    card.config.center = new_state.center
    card.config.center_key = new_state.key
    card.quantum.active = state_key

    card:set_sprites(new_state.center)

    local new_hooks = QuantumLib._hooks[new_state.key]
    if new_hooks and new_hooks.on_enter then
        new_hooks.on_enter(card, new_state)
    end
end
