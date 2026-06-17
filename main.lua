QuantumLib = SMODS.current_mod

local mod_path = QuantumLib.path
assert(load(NFS.read(mod_path .. "src/quantum_state.lua"),        "=[QuantumLib] src/quantum_state.lua"))()
assert(load(NFS.read(mod_path .. "src/quantum_cycle.lua"),         "=[QuantumLib] src/quantum_cycle.lua"))()
assert(load(NFS.read(mod_path .. "src/quantum_superposition.lua"), "=[QuantumLib] src/quantum_superposition.lua"))()
assert(load(NFS.read(mod_path .. "src/quantum_stack.lua"),         "=[QuantumLib] src/quantum_stack.lua"))()
assert(load(NFS.read(mod_path .. "src/quantum_rules.lua"),         "=[QuantumLib] src/quantum_rules.lua"))()
