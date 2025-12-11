dofile("$CONTENT_DATA/Scripts/Game/Lootboxes/loot_table.lua")

Lootbox = class( nil )

function Lootbox.server_onCreate( self )
	self.destroyed = false
end

function Lootbox.client_onInteract( self, character, state )
	if self.data.Open_Action == "Use" and self.data.Open_Type == "Both" then
		if character:isPlayer() then
			if state == true then
				self.network:sendToServer("sv_use", {character = character})
			end
		end
	end
end

function Lootbox.sv_use(self, param)
	self.destroyed = true
	local player = param.character:getPlayer()
	
	local container = player:getInventory()
	if sm.container.beginTransaction() then

		for _, item in ipairs(loot_table[self.data.Lootbox_Type]) do
			if item.uuid ~= nil then
				local amount = math.random(item.min, item.max)
				if amount > 0 then
					sm.container.collect(container, item.uuid, amount)
				end
			end
		end

		if sm.container.endTransaction() then
			for _, effect in ipairs(loot_table[self.data.Lootbox_Type].effects) do
				sm.effect.playEffect( effect, self.shape.worldPosition)
			end

			self.shape:destroyShape(0)
		end
		self.destroyed = false
	end
end


function Lootbox.sv_hit(self, param)
	if not self.destroyed and sm.exists( self.shape ) then
		self.destroyed = true

		local lootList = {}
		for _, item in ipairs(loot_table[self.data.Lootbox_Type]) do
			if item.uuid ~= nil then
				local amount = math.random(item.min, item.max)
				if amount > 0 then
					lootList[i] = { uuid = item.uuid, quantity = amount }
				end
			end
		end

		SpawnLoot( self.shape, lootList, self.shape.worldPosition + sm.vec3.new( 0, 0, 1.0 ) )
		
		for _, effect in ipairs(loot_table[self.data.Lootbox_Type].effects) do
			sm.effect.playEffect( effect, self.shape.worldPosition)
		end
		
		self.shape:destroyShape(0)
	end
end





function WheatPlant.server_onProjectile( self, hitPos, hitTime, hitVelocity, _, attacker, damage, userData, hitNormal, projectileUuid )
	if self.data.Open_Action == "Hit" and self.data.Open_Type == "Both" then
		self:sv_hit()
	end
end

function WheatPlant.server_onMelee( self, hitPos, attacker, damage, power, hitDirection )
	if self.data.Open_Action == "Hit" and self.data.Open_Type == "Both" then
		self:sv_hit()
	end
end

function WheatPlant.server_onExplosion( self, center, destructionLevel )
	if self.data.Open_Action == "Hit" and self.data.Open_Type == "Both" then
		self:sv_hit()
	end
end


--ingame

function SpawnLoot( origin, lootList, worldPosition, ringAngle )

	if worldPosition == nil then
		if type( origin ) == "Shape" then
			worldPosition = origin.worldPosition
		elseif type( origin ) == "Player" or type( origin ) == "Unit" then
			local character = origin:getCharacter()
			if character then
				worldPosition = character.worldPosition
			end
		elseif type( origin ) == "Harvestable" then
			worldPosition = origin.worldPosition
		end
	end

	ringAngle = ringAngle or math.pi / 18

	if worldPosition then
		for i = 1, #lootList do
			local dir
			local up
			if type( origin ) == "Shape" then
				dir = sm.vec3.new( 1.0, 0.0, 0.0 )
				up = sm.vec3.new( 0, 1, 0 )
			else
				dir = sm.vec3.new( 0.0, 1.0, 0.0 )
				up = sm.vec3.new( 0, 0, 1 )
			end

			local firstCircle = 6
			local secondCircle = 13
			local thirdCircle = 26

			if i < 6 then
				local divisions = ( firstCircle - ( firstCircle - math.min( #lootList, firstCircle - 1 ) ) )
				dir = dir:rotate( i * 2 * math.pi / divisions, up )
				local right = dir:cross( up )
				dir = dir:rotate( math.pi / 2 - ringAngle, right )
			elseif i < 13 then
				local divisions = ( secondCircle - ( secondCircle - math.min( #lootList - firstCircle + 1, secondCircle - firstCircle ) ) )
				dir = dir:rotate( i * 2 * math.pi / divisions, up )
				local right = dir:cross( up )
				dir = dir:rotate( math.pi / 2 - 2 * ringAngle, right )
			elseif i < 26 then
				local dvisions = ( thirdCircle - ( thirdCircle - math.min( #lootList - secondCircle + 1, thirdCircle - secondCircle ) ) )
				dir = dir:rotate( i * 2 * math.pi / dvisions, up )
				local right = dir:cross( up )
				dir = dir:rotate( math.pi / 2 - 4 * ringAngle, right )
			else
				-- Out of predetermined room, place randomly
				dir = dir:rotate( math.random() * 2 * math.pi, up )
				local right = dir:cross( up )
				dir = dir:rotate( math.pi / 2 - ringAngle - math.random() * ( 3 * ringAngle ), right )
			end

			local loot = lootList[i]
			local params = { lootUid = loot.uuid, lootQuantity = loot.quantity or 1, epic = loot.epic }
			local vel = dir * (4+math.random()*2)
			local projectileUuid = loot.epic and projectile_epicloot or projectile_loot
			if type( origin ) == "Shape" then
				sm.projectile.shapeCustomProjectileAttack( params, projectileUuid, 0, sm.vec3.new( 0, 0, 0 ), vel, origin, 0 )
			elseif type( origin ) == "Player" or type( origin ) == "Unit" then
				sm.projectile.customProjectileAttack( params, projectileUuid, 0, worldPosition, vel, origin, worldPosition, worldPosition, 0 )
			elseif type( origin ) == "Harvestable" then
				sm.projectile.harvestableCustomProjectileAttack( params, projectileUuid, 0, worldPosition, vel, origin, 0 )
			end
		end
	end
end
