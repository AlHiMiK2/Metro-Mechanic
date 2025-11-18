---@class FogEffect : ToolClass
FogEffect = class()

function FogEffect:client_onCreate()
    local effect = sm.effect.createEffect("ShapeRenderable", self.tool:getOwner().character)
    effect:setParameter("uuid", sm.uuid.new("1bb1955d-09ef-4e0c-b765-e3b5560ace0c"))
    effect:setScale(sm.vec3.new(20, 20, 20))
    effect:start()
    print(effect)
end