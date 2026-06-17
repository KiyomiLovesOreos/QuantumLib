-- tests/error_checks.lua
-- Validates every input-validation assert added in the error-message pass.
-- Output goes to the Lovely log. Run by adding one load line to demo/main.lua.

local _pass, _fail = 0, 0

-- Expects fn to throw an error. PASS = error raised, FAIL = no error.
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        print(("[QuantumLib:test] FAIL (no error raised): %s"):format(name))
        _fail = _fail + 1
    else
        print(("[QuantumLib:test] PASS: %s"):format(name))
        print(("[QuantumLib:test]   msg: %s"):format(tostring(err)))
    end
    _pass = _pass + (ok and 0 or 1)
end

-- Expects fn to succeed without error.
local function test_ok(name, fn)
    local ok, err = pcall(fn)
    if ok then
        print(("[QuantumLib:test] PASS: %s"):format(name))
        _pass = _pass + 1
    else
        print(("[QuantumLib:test] FAIL (unexpected error): %s"):format(name))
        print(("[QuantumLib:test]   msg: %s"):format(tostring(err)))
        _fail = _fail + 1
    end
end

-- Expects fn to succeed AND emit a print containing expected_str.
local function test_warns(name, fn, expected_str)
    local warned = false
    local orig_print = print
    print = function(s, ...)
        if type(s) == "string" and s:find(expected_str, 1, true) then warned = true end
        orig_print(s, ...)
    end
    local ok, err = pcall(fn)
    print = orig_print
    if not ok then
        orig_print(("[QuantumLib:test] FAIL (unexpected error): %s"):format(name))
        orig_print(("[QuantumLib:test]   msg: %s"):format(tostring(err)))
        _fail = _fail + 1
    elseif not warned then
        orig_print(("[QuantumLib:test] FAIL (warning not seen): %s"):format(name))
        orig_print(("[QuantumLib:test]   expected: %s"):format(expected_str))
        _fail = _fail + 1
    else
        orig_print(("[QuantumLib:test] PASS: %s"):format(name))
        _pass = _pass + 1
    end
end

-- Injects two minimal test centers into G.P_CENTERS for tests that need
-- make_quantum to resolve centers, then removes them afterward.
local function with_fake_centers(fn)
    G = G or {}
    G.P_CENTERS = G.P_CENTERS or {}
    G.P_CENTERS["__ql_test_a"] = { key = "__ql_test_a", config = {}, name = "TestA", effect = "TestA", set = "Enhanced" }
    G.P_CENTERS["__ql_test_b"] = { key = "__ql_test_b", config = {}, name = "TestB", effect = "TestB", set = "Enhanced" }
    local ok, err = pcall(fn)
    G.P_CENTERS["__ql_test_a"] = nil
    G.P_CENTERS["__ql_test_b"] = nil
    if not ok then error(err, 2) end
end

print("[QuantumLib:test] ====== error_checks start ======")

-- ── build_card_ability ──────────────────────────────────────────────────────

test("build_card_ability / nil center",
    function() QuantumLib.build_card_ability(nil) end)

test("build_card_ability / string passed instead of table",
    function() QuantumLib.build_card_ability("m_steel") end)

test("build_card_ability / table missing .key",
    function() QuantumLib.build_card_ability({ config = {} }) end)

test_ok("build_card_ability / valid center table", function()
    QuantumLib.build_card_ability({ key = "__ql_ok", config = {}, name = "T", effect = "T", set = "Enhanced" })
end)

-- ── make_quantum ────────────────────────────────────────────────────────────

test("make_quantum / nil card",
    function() QuantumLib.make_quantum(nil, { states = { "__ql_test_a" } }) end)

test("make_quantum / nil opts.states",
    function() QuantumLib.make_quantum({}, {}) end)

test("make_quantum / empty opts.states",
    function() QuantumLib.make_quantum({}, { states = {} }) end)

-- mode check fires before G.P_CENTERS loop so no fake centers needed here
test("make_quantum / bad mode string", function()
    QuantumLib.make_quantum({ config = {}, ability = {} }, { states = { "x" }, mode = "flux" })
end)

test("make_quantum / unknown center key", function()
    with_fake_centers(function()
        QuantumLib.make_quantum({ config = { center = {} }, ability = {} }, { states = { "__ql_no_such" } })
    end)
end)

test("make_quantum / already has quantum data", function()
    with_fake_centers(function()
        local card = { config = { center = {} }, ability = {} }
        QuantumLib.make_quantum(card, { states = { "__ql_test_a", "__ql_test_b" }, mode = "cycle" })
        QuantumLib.make_quantum(card, { states = { "__ql_test_a", "__ql_test_b" }, mode = "cycle" })
    end)
end)

test("make_quantum / stack mode missing primary", function()
    with_fake_centers(function()
        QuantumLib.make_quantum({ config = { center = {} }, ability = {} }, {
            states = { "__ql_test_a", "__ql_test_b" }, mode = "stack",
        })
    end)
end)

test("make_quantum / stack mode primary not in states", function()
    with_fake_centers(function()
        QuantumLib.make_quantum({ config = { center = {} }, ability = {} }, {
            states = { "__ql_test_a", "__ql_test_b" }, mode = "stack", primary = "__ql_test_c",
        })
    end)
end)

-- ── register_hooks ──────────────────────────────────────────────────────────

test("register_hooks / non-string center_key",
    function() QuantumLib.register_hooks(123, { on_enter = function() end }) end)

test("register_hooks / non-table hooks",
    function() QuantumLib.register_hooks("j_test", "not a table") end)

test("register_hooks / on_enter not a function",
    function() QuantumLib.register_hooks("j_test", { on_enter = "bad" }) end)

test("register_hooks / on_exit not a function",
    function() QuantumLib.register_hooks("j_test", { on_exit = 42 }) end)

test("register_hooks / empty hooks table",
    function() QuantumLib.register_hooks("j_test", {}) end)

test_ok("register_hooks / valid on_enter only",
    function() QuantumLib.register_hooks("__ql_test_hook", { on_enter = function() end }) end)

test_ok("register_hooks / valid on_exit only",
    function() QuantumLib.register_hooks("__ql_test_hook", { on_exit = function() end }) end)

-- ── set_state ───────────────────────────────────────────────────────────────

test("set_state / card has no quantum",
    function() QuantumLib.set_state({}, "some_key") end)

test("set_state / stack mode card",
    function() QuantumLib.set_state({ quantum = { mode = "stack", states = {}, primary = "x" } }, "x") end)

test("set_state / superposition mode card",
    function() QuantumLib.set_state({ quantum = { mode = "superposition", states = {}, active = "x" } }, "x") end)

test("set_state / non-string state_key", function()
    with_fake_centers(function()
        local card = { config = { center = {} }, ability = {} }
        QuantumLib.make_quantum(card, { states = { "__ql_test_a", "__ql_test_b" }, mode = "cycle" })
        QuantumLib.set_state(card, 42)
    end)
end)

-- ── register_effect_gate ────────────────────────────────────────────────────

test("register_effect_gate / non-string center_key",
    function() QuantumLib.register_effect_gate(42, { "mult" }) end)

test("register_effect_gate / non-table fields",
    function() QuantumLib.register_effect_gate("__ql_gate_test", "mult") end)

test("register_effect_gate / empty fields list",
    function() QuantumLib.register_effect_gate("__ql_gate_test", {}) end)

test("register_effect_gate / field entry not a string",
    function() QuantumLib.register_effect_gate("__ql_gate_test", { "mult", 99 }) end)

test_warns(
    "register_effect_gate / overwrite prints warning",
    function() QuantumLib.register_effect_gate("m_lucky", { "mult", "p_dollars" }) end,
    "[QuantumLib] register_effect_gate: overwriting existing effect gate for 'm_lucky'"
)

test_ok("register_effect_gate / valid new gate", function()
    QuantumLib.register_effect_gate("__ql_gate_new", { "bonus" })
    QuantumLib._effect_gates["__ql_gate_new"] = nil
end)

-- ── register_stack_rule ─────────────────────────────────────────────────────

test("register_stack_rule / nil owner",
    function() QuantumLib.register_stack_rule(nil, { m_steel = { extra_states = { "m_gold" } } }) end)

test("register_stack_rule / nil rules",
    function() QuantumLib.register_stack_rule({ key = "__ql_owner" }, nil) end)

test("register_stack_rule / empty rules table",
    function() QuantumLib.register_stack_rule({ key = "__ql_owner" }, {}) end)

test("register_stack_rule / non-string center_key in rules", function()
    QuantumLib.register_stack_rule({ key = "__ql_owner" }, { [99] = { extra_states = { "m_gold" } } })
end)

test("register_stack_rule / spec missing extra_states",
    function() QuantumLib.register_stack_rule({ key = "__ql_owner" }, { m_steel = {} }) end)

test("register_stack_rule / extra_states not a table",
    function() QuantumLib.register_stack_rule({ key = "__ql_owner" }, { m_steel = { extra_states = "m_gold" } }) end)

test("register_stack_rule / extra_states item not a string", function()
    QuantumLib.register_stack_rule({ key = "__ql_owner" }, { m_steel = { extra_states = { 99 } } })
end)

test("register_stack_rule / owner with no derivable key",
    function() QuantumLib.register_stack_rule({}, { m_steel = { extra_states = { "m_gold" } } }) end)

-- ── has_enhancement ─────────────────────────────────────────────────────────

test("has_enhancement / non-string key",
    function() QuantumLib.has_enhancement({}, 42) end)

test_ok("has_enhancement / non-quantum card returns false", function()
    local result = QuantumLib.has_enhancement({ ability = {} }, "m_steel")
    assert(result == false, "expected false, got " .. tostring(result))
end)

test_ok("has_enhancement / stack: present states return true", function()
    with_fake_centers(function()
        local card = { config = { center = {} }, ability = {} }
        QuantumLib.make_quantum(card, { states = { "__ql_test_a", "__ql_test_b" }, mode = "stack", primary = "__ql_test_a" })
        assert(QuantumLib.has_enhancement(card, "__ql_test_a") == true, "primary should return true")
        assert(QuantumLib.has_enhancement(card, "__ql_test_b") == true, "secondary should return true")
    end)
end)

test_ok("has_enhancement / stack: absent key returns false", function()
    with_fake_centers(function()
        local card = { config = { center = {} }, ability = {} }
        QuantumLib.make_quantum(card, { states = { "__ql_test_a", "__ql_test_b" }, mode = "stack", primary = "__ql_test_a" })
        assert(QuantumLib.has_enhancement(card, "m_steel") == false, "unregistered key should return false")
    end)
end)

test_ok("has_enhancement / cycle: active state returns true", function()
    with_fake_centers(function()
        local card = { config = { center = {} }, ability = {} }
        QuantumLib.make_quantum(card, { states = { "__ql_test_a", "__ql_test_b" }, mode = "cycle", initial = "__ql_test_a" })
        assert(QuantumLib.has_enhancement(card, "__ql_test_a") == true, "active state should return true")
    end)
end)

test_ok("has_enhancement / cycle: inactive state returns false", function()
    with_fake_centers(function()
        local card = { config = { center = {} }, ability = {} }
        QuantumLib.make_quantum(card, { states = { "__ql_test_a", "__ql_test_b" }, mode = "cycle", initial = "__ql_test_a" })
        assert(QuantumLib.has_enhancement(card, "__ql_test_b") == false, "inactive cycle state should return false")
    end)
end)

test_ok("has_enhancement / superposition: all states return true", function()
    with_fake_centers(function()
        local card = { config = { center = {} }, ability = {} }
        QuantumLib.make_quantum(card, { states = { "__ql_test_a", "__ql_test_b" }, mode = "superposition" })
        assert(QuantumLib.has_enhancement(card, "__ql_test_a") == true)
        assert(QuantumLib.has_enhancement(card, "__ql_test_b") == true)
    end)
end)

-- ── Summary ─────────────────────────────────────────────────────────────────

print(("[QuantumLib:test] ====== Done: %d passed, %d failed ======"):format(_pass, _fail))
