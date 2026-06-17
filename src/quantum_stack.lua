QuantumLib._effect_gates = QuantumLib._effect_gates or {}

function QuantumLib.register_effect_gate(center_key, fields)
    assert(type(center_key) == "string",
        "QuantumLib.register_effect_gate: center_key must be a string")
    assert(type(fields) == "table" and #fields > 0,
        "QuantumLib.register_effect_gate: fields must be a non-empty list of strings")
    for i, f in ipairs(fields) do
        assert(type(f) == "string",
            ("QuantumLib.register_effect_gate: fields[%d] must be a string, got %s"):format(i, type(f)))
    end
    if QuantumLib._effect_gates[center_key] then
        print(("[QuantumLib] register_effect_gate: overwriting existing effect gate for '%s'"):format(center_key))
    end
    local set = {}
    for _, f in ipairs(fields) do set[f] = true end
    QuantumLib._effect_gates[center_key] = { fields = set }
end

QuantumLib.register_effect_gate("m_lucky", { "mult", "p_dollars" })

QuantumLib.STACK_MERGE_RULES = {
    mult = "add",
    h_mult = "add",
    h_dollars = "add",
    p_dollars = "add",
    t_mult = "add",
    t_chips = "add",
    bonus = "add",

    x_mult = "multiply",
    h_x_mult = "multiply",
    x_chips = "multiply",

    extra = "merge_table",

    name = "primary",
    effect = "primary",
    set = "primary",
}

local _sums = {}
local _prods = {}
local _tbls = {}

function QuantumLib.recompute_stack(card)
    assert(card.quantum, "QuantumLib.recompute_stack: card has no quantum data (call make_quantum first)")
    assert(card.quantum.mode == "stack",
        "QuantumLib.recompute_stack: card.quantum.mode is not 'stack'")
    assert(card.ability, "QuantumLib.recompute_stack: card has no ability table (call card:set_ability first)")

    card.quantum.cached_enhancements = nil
    card.quantum._badge_names = nil
    card.quantum._generation = (card.quantum._generation or 0) + 1

    local primary = card.quantum.states[card.quantum.primary]
    local rules = QuantumLib.STACK_MERGE_RULES

    for k in pairs(_sums) do _sums[k] = nil end
    for k in pairs(_prods) do _prods[k] = nil end
    for k in pairs(_tbls) do _tbls[k] = nil end

    for _, state in pairs(card.quantum.states) do
        for field, value in pairs(state.ability) do
            local rule = rules[field] or "primary"
            if rule == "add" then
                _sums[field] = (_sums[field] or 0) + (value or 0)
            elseif rule == "multiply" then
                if value and value ~= 0 then
                    _prods[field] = (_prods[field] or 1) * value
                end
            elseif rule == "merge_table" and type(value) == "table" then
                if not _tbls[field] then _tbls[field] = {} end
                for k2, v2 in pairs(value) do _tbls[field][k2] = v2 end
            end
        end
    end

    for field, _ in pairs(primary.ability) do
        local rule = rules[field] or "primary"
        if rule == "add" then
            card.ability[field] = _sums[field] or 0
        elseif rule == "multiply" then
            card.ability[field] = _prods[field] or 1
        elseif rule == "merge_table" then
            card.ability[field] = _tbls[field] or primary.ability[field]
        else
            card.ability[field] = primary.ability[field]
        end
    end
    for field, v in pairs(_sums)  do if card.ability[field] == nil then card.ability[field] = v end end
    for field, v in pairs(_prods) do if card.ability[field] == nil then card.ability[field] = v end end
    for field, v in pairs(_tbls)  do if card.ability[field] == nil then card.ability[field] = v end end

    for gated_key, gate in pairs(QuantumLib._effect_gates) do
        local gated_state = card.quantum.states[gated_key]
        if gated_state then
            for field in pairs(gate.fields) do
                local guaranteed = (_sums[field] or 0) - (gated_state.ability[field] or 0)
                card.ability[field] = gated_state.ability[field]
                card.ability["stack_guaranteed_" .. field] = guaranteed
            end
        end
    end

    card.ability.Xmult = card.ability.x_mult
end

function QuantumLib.enable_stack_visibility()
    if QuantumLib._stack_visibility_enabled then return end
    QuantumLib._stack_visibility_enabled = true

    local original_get_enhancements = SMODS.get_enhancements
    SMODS.get_enhancements = function(card, ...)
        if card.quantum and card.quantum.mode == "stack" then
            if card.quantum.cached_enhancements then
                return card.quantum.cached_enhancements
            end
            local enhancements = {}
            for key, _ in pairs(card.quantum.states) do
                rawset(enhancements, key, true)
            end
            setmetatable(enhancements, {
                __newindex = function(_, k, _)
                    error(("QuantumLib: attempted to write key '%s' to the enhancements table returned by SMODS.get_enhancements — this table is read-only for quantum stack cards"):format(tostring(k)), 2)
                end,
            })
            card.quantum.cached_enhancements = enhancements
            return enhancements
        end
        return original_get_enhancements(card, ...)
    end
end

function QuantumLib.enable_stack_tooltip()
    if QuantumLib._stack_tooltip_enabled then return end
    QuantumLib._stack_tooltip_enabled = true

    local original_generate_UIBox_ability_table = Card.generate_UIBox_ability_table
    function Card:generate_UIBox_ability_table(vars_only)
        if self.quantum and self.quantum.mode == "stack" and not self.debuff then
            local gen  = self.quantum._generation
            local slot = vars_only and "v" or "f"
            local cache = self.quantum._tooltip_cache
            if cache and cache.gen == gen and cache[slot] then
                return cache[slot]
            end
        end

        local full_UI_table = original_generate_UIBox_ability_table(self, vars_only)
        if self.quantum and self.quantum.mode == "stack" and type(full_UI_table) == "table" then
            local order = self.quantum.order or {}

            if not self.debuff then
                for _, key in ipairs(order) do
                    if key ~= self.quantum.primary then
                        local saved_name = full_UI_table.name
                        full_UI_table.name = nil
                        local saved_bonus = self.ability.bonus
                        self.ability.bonus = 0

                        local saved_mult = self.ability.mult
                        if self.ability.stack_guaranteed_mult then
                            self.ability.mult = self.quantum.states[key].ability.mult
                        end

                        generate_card_ui(self.quantum.states[key].center, full_UI_table, nil, full_UI_table.card_type, nil, nil, nil, nil, self)

                        self.ability.mult = saved_mult
                        self.ability.bonus = saved_bonus
                        full_UI_table.name = saved_name
                    end
                end

                local gen  = self.quantum._generation
                local slot = vars_only and "v" or "f"
                local cache = self.quantum._tooltip_cache
                if not cache or cache.gen ~= gen then
                    cache = { gen = gen }
                    self.quantum._tooltip_cache = cache
                end
                cache[slot] = full_UI_table
            end

            local saved_ability = self.ability
            for _, key in ipairs(order) do
                local state = self.quantum.states[key]
                self.ability = state.ability
                generate_card_ui(state.center, full_UI_table, nil, full_UI_table.card_type, nil, nil, nil, nil, self)
                self.ability = saved_ability
            end
        end
        return full_UI_table
    end
end

function QuantumLib.enable_stack_badges()
    if QuantumLib._stack_badges_enabled then return end
    QuantumLib._stack_badges_enabled = true

    local original_card_h_popup = G.UIDEF.card_h_popup
    G.UIDEF.card_h_popup = function(card)
        local ui = original_card_h_popup(card)
        if card.quantum and card.quantum.mode == "stack" and type(ui) == "table" then
            local inner = ui.nodes[1].nodes[1].nodes[1]
            local badges_row = inner.nodes[3]
            if not badges_row then
                badges_row = { n = G.UIT.R, config = { align = "cm", padding = 0.03 }, nodes = {} }
                inner.nodes[3] = badges_row
            end

            for i = #badges_row.nodes, 1, -1 do
                table.remove(badges_row.nodes, i)
            end

            local names = card.quantum._badge_names
            if not names then
                names = {}
                for _, key in ipairs(card.quantum.order or {}) do
                    names[#names + 1] = localize{ type = 'name_text', key = key, set = 'Enhanced' }
                end
                card.quantum._badge_names = names
            end

            local primary_center = card.quantum.states[card.quantum.primary].center
            table.insert(badges_row.nodes, create_badge(
                names,
                get_type_colour(primary_center, card),
                SMODS.get_card_type_text_colour('Enhanced', primary_center, card),
                1.2
            ))
        end
        return ui
    end
end

function QuantumLib.enable_stack_deck_view()
    if QuantumLib._stack_deck_view_enabled then return end
    QuantumLib._stack_deck_view_enabled = true

    local original_copy_card = copy_card
    copy_card = function(other, ...)
        local new_card = original_copy_card(other, ...)
        if other.quantum and other.quantum.mode == "stack" and not new_card.quantum then
            QuantumLib.make_quantum(new_card, {
                states = other.quantum.order,
                primary = other.quantum.primary,
                mode = "stack",
            })
        end
        return new_card
    end
end

function QuantumLib.enable_stack_persistence()
    if QuantumLib._stack_persistence_enabled then return end
    QuantumLib._stack_persistence_enabled = true

    local original_load = Card.load
    function Card:load(...)
        local ret = original_load(self, ...)
        if not self.quantum and self.ability and self.ability.quantum_order then
            QuantumLib.make_quantum(self, {
                states = self.ability.quantum_order,
                primary = self.ability.quantum_primary,
                mode = "stack",
            })
            if self.ability.quantum_live_rule_center then
                self.quantum._live_rule_center = self.ability.quantum_live_rule_center
            end
        end
        return ret
    end
end

function QuantumLib.enable_stack_enhancement_calculate()
    if QuantumLib._stack_enhancement_calculate_enabled then return end
    QuantumLib._stack_enhancement_calculate_enabled = true

    local original_calculate_enhancement = Card.calculate_enhancement
    function Card:calculate_enhancement(context)
        if self.quantum and self.quantum.mode == "stack" then
            if self.ability.set ~= 'Enhanced' then return nil end
            for _, key in ipairs(self.quantum.order) do
                local state = self.quantum.states[key]
                local center = state.center
                if center.calculate and type(center.calculate) == 'function' then
                    local o = center:calculate(self, context)
                    if o then
                        if not o.card then o.card = self end
                        return o
                    end
                end
            end
            return nil
        end
        return original_calculate_enhancement(self, context)
    end
end

function QuantumLib.enable_stack_lucky_mult()
    if QuantumLib._stack_lucky_mult_enabled then return end
    QuantumLib._stack_lucky_mult_enabled = true

    local original_get_chip_mult = Card.get_chip_mult
    function Card:get_chip_mult()
        local ret = original_get_chip_mult(self)
        if self.quantum and self.quantum.mode == "stack" and self.ability.stack_guaranteed_mult then
            ret = ret + self.ability.stack_guaranteed_mult
        end
        return ret
    end
end
