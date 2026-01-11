---@class FogEffect : ToolClass
FogEffect = class()

function FogEffect:client_onUpdate(dt)
    if self.effect == nil then
        self.effect = sm.effect.createEffect("ShapeRenderable")
        self.effect:setParameter("uuid", sm.uuid.new("1bb1955d-09ef-4e0c-b765-e3b5560ace0c"))
        self.effect:setScale(sm.vec3.new(400, 400, 400))
        self.effect:start()
    end

    self.effect:setPosition(self.tool:getOwner().character.worldPosition)
end