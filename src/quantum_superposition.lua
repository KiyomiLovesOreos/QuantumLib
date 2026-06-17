function QuantumLib.update_all(card, fn)
    assert(card.quantum, "QuantumLib.update_all: card has no quantum data (call make_quantum first)")
    assert(card.quantum.mode == "superposition",
        "QuantumLib.update_all: card.quantum.mode is not 'superposition'")
    assert(type(fn) == "function", "QuantumLib.update_all: fn must be a function")
    for _, state in pairs(card.quantum.states) do
        fn(card, state)
    end
end

function QuantumLib.collapse(card, context, selector_fn, score_fn)
    assert(card.quantum, "QuantumLib.collapse: card has no quantum data (call make_quantum first)")
    assert(card.quantum.mode == "superposition",
        "QuantumLib.collapse: card.quantum.mode is not 'superposition'")
    assert(type(selector_fn) == "function", "QuantumLib.collapse: selector_fn must be a function")
    assert(type(score_fn) == "function", "QuantumLib.collapse: score_fn must be a function")

    local chosen_key = selector_fn(card, card.quantum.states, context)
    assert(chosen_key and card.quantum.states[chosen_key],
        ("QuantumLib.collapse: selector_fn returned unknown state key '%s'"):format(tostring(chosen_key)))

    local chosen_state = card.quantum.states[chosen_key]
    local saved_ability = card.ability
    card.ability = chosen_state.ability
    local result = score_fn(card, chosen_state, context)
    card.ability = saved_ability
    return result
end
