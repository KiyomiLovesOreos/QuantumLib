QuantumLibDemo = SMODS.current_mod
QuantumLibDemo.config = QuantumLibDemo.config or {}
if QuantumLibDemo.config.show_debug_jokers == nil then
    QuantumLibDemo.config.show_debug_jokers = true
end

local mod_path = QuantumLibDemo.path
assert(load(NFS.read(mod_path .. "src/j_enhancer.lua"), "=[QuantumLibDemo] src/j_enhancer.lua"))()
assert(load(NFS.read(mod_path .. "src/c_catalyst.lua"), "=[QuantumLibDemo] src/c_catalyst.lua"))()
assert(load(NFS.read(mod_path .. "src/stack_on_enhance.lua"), "=[QuantumLibDemo] src/stack_on_enhance.lua"))()
assert(load(NFS.read(mod_path .. "src/j_alloy_live.lua"),     "=[QuantumLibDemo] src/j_alloy_live.lua"))()
assert(load(NFS.read(mod_path .. "src/j_alloy_live_wild.lua"), "=[QuantumLibDemo] src/j_alloy_live_wild.lua"))()

QuantumLibDemo.config_tab = function()
    return {
        n = G.UIT.ROOT,
        config = { align = "cm", colour = G.C.CLEAR },
        nodes = {
            { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
                create_toggle({
                    label = "Enhancements stack instead of overwrite",
                    label_scale = 0.4,
                    w = 8,
                    ref_table = QuantumLibDemo.config,
                    ref_value = "stack_on_enhance",
                }),
            } },
            { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
                create_toggle({
                    label = "Show debug items",
                    label_scale = 0.4,
                    w = 8,
                    ref_table = QuantumLibDemo.config,
                    ref_value = "show_debug_jokers",
                }),
            } },
        },
    }
end

local _orig_collection_pool = SMODS.collection_pool
SMODS.collection_pool = function(_base_pool)
    local pool = _orig_collection_pool(_base_pool)
    if QuantumLibDemo.config.show_debug_jokers ~= false then return pool end
    local filtered = {}
    for _, v in ipairs(pool) do
        if v.mod ~= QuantumLibDemo then filtered[#filtered + 1] = v end
    end
    return filtered
end

QuantumLib.enable_stack_visibility()
QuantumLib.enable_stack_enhancement_calculate()
QuantumLib.enable_stack_lucky_mult()
QuantumLib.enable_stack_tooltip()
QuantumLib.enable_stack_badges()
QuantumLib.enable_stack_deck_view()
QuantumLib.enable_stack_persistence()
QuantumLib.enable_cycle_persistence()
QuantumLib.enable_superposition_persistence()
