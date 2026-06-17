QuantumLibDemo = SMODS.current_mod

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
        },
    }
end

QuantumLib.enable_stack_visibility()
QuantumLib.enable_stack_enhancement_calculate()
QuantumLib.enable_stack_lucky_mult()
QuantumLib.enable_stack_tooltip()
QuantumLib.enable_stack_badges()
QuantumLib.enable_stack_deck_view()
QuantumLib.enable_stack_persistence()
