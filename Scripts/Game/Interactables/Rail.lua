Rail = class()

function Rail.server_onCreate(self)
end

function Rail.client_onCreate(self)
end

function Rail.client_onRefresh(self)
end

function Rail.server_onFixedUpdate(self, dt)
end

function Rail.server_onCollision(self, other, position, selfPointVelocity, otherPointVelocity)
    if type(other) == "Character" then
		other:setTumbling( true )
        sm.event.sendToPlayer(other:getPlayer(), "sv_takeDamage", 1)--{damage = 15, source = "Melee"})
        sm.effect.playEffect("Part - Electricity", position, otherPointVelocity)
    end
end