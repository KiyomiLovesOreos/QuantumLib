local function quantum_order_and_primary(card)
    if card.quantum and card.quantum.mode == "stack" then
        return QuantumLib.deep_copy(card.quantum.order), card.quantum.primary
    end
    return { card.config.center_key }, card.config.center_key
end

local original_set_ability = Card.set_ability
function Card:set_ability(center, initial, delay_sprites)
    if QuantumLibDemo.config.stack_on_enhance
        and not initial
        and center and center.set == "Enhanced"
        and self.config and self.config.center and self.config.center.set == "Enhanced"
    then
        local order, primary = quantum_order_and_primary(self)

        local already_has = false
        for _, key in ipairs(order) do
            if key == center.key then already_has = true end
        end

        if not already_has then
            table.insert(order, center.key)
            if center.key == "m_lucky" then primary = "m_lucky" end
            QuantumLib.make_quantum(self, { states = order, primary = primary, mode = "stack" })
            return
        end
    end

    return original_set_ability(self, center, initial, delay_sprites)
end
