dofile("$CONTENT_DATA/Scripts/Game/Lootboxes/loot_table.lua")

Lootbox = class( nil )

function Lootbox.server_onCreate( self )
end

function Lootbox.client_onInteract( self, character, state )
	if character:isPlayer() then
		if state == true then
			self.network:sendToServer("sv_use", {character = character})
		end
	end
end

function Lootbox.sv_use(self, param)
	local player = param.character:getPlayer()
	
	local container = player:getInventory()
	if sm.container.beginTransaction() then

		for _, item in ipairs(loot_table[self.data.Lootbox_Type]) do
			local amount = math.random(item.min, item.max)
			if amount > 0 then
				sm.container.collect(container, item.uuid, amount)
			end
		end

		if sm.container.endTransaction() then
			sm.effect.playEffect( "Mechanic land", self.shape.worldPosition )
			sm.effect.playEffect( "Mechanic jump", self.shape.worldPosition )
			sm.effect.playEffect( "Drill - Debris", self.shape.worldPosition )
			self.shape:destroyShape(0)
		end
	end
	
	--self.shape:des
end