-- vending machine script with owner-only access, coin payment and owner display (with persistent owner saving by name)

-- Dependencies
dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua")

-- Class definition
vend = class()
vend.poseWeightCount = 1

-- Constants
local ContainerSize = 18
local DropDelay = 10
local CoinUUID = sm.uuid.new("4a1b886b-913e-4aad-b5b6-6e41b0db23a6")

local SlotOffsets = {
	-- 18 offsets (3x3 grid front/back)
	-- back row
	sm.vec3.new(0.20, 0.33, 0.1), sm.vec3.new(-0.075, 0.33, 0.1), sm.vec3.new(-0.3425, 0.33, 0.1),
	sm.vec3.new(0.20, 0.05, 0.1), sm.vec3.new(-0.075, 0.05, 0.1), sm.vec3.new(-0.3425, 0.05, 0.1),
	sm.vec3.new(0.20, -0.23, 0.1), sm.vec3.new(-0.075, -0.23, 0.1), sm.vec3.new(-0.3425, -0.23, 0.1),
	-- front row
	sm.vec3.new(0.20, 0.33, 0.35), sm.vec3.new(-0.075, 0.33, 0.35), sm.vec3.new(-0.3425, 0.33, 0.35),
	sm.vec3.new(0.20, 0.05, 0.35), sm.vec3.new(-0.075, 0.05, 0.35), sm.vec3.new(-0.3425, 0.05, 0.35),
	sm.vec3.new(0.20, -0.23, 0.35), sm.vec3.new(-0.075, -0.23, 0.35), sm.vec3.new(-0.3425, -0.23, 0.35)
}

function vend.sv_init(self)
	self.sv = {
		downDelay = 0,
		canDrop = true,
		ownerName = nil
	}
	self:sv_loadData()
end

function vend.sv_loadData(self)
	local data = self.storage:load()
	if data and type(data.ownerName) == "string" then
		self.sv.ownerName = data.ownerName
	end
end

function vend.sv_saveData(self)
	self.storage:save({ ownerName = self.sv.ownerName })
end

function vend.server_onCreate(self)
	self:sv_init()
	local container = self.shape:getInteractable():getContainer(0)
	if not container then
		container = self.shape:getInteractable():addContainer(0, ContainerSize, 1)
	end

	local filters = {}
	if self.data.filterUid then
		table.insert(filters, sm.uuid.new(self.data.filterUid))
	end

	local extra = {
		"631b46aa-5a7d-4fe9-9294-ec431058d6c7",
		"f0f57ae4-e8f4-4d3b-af28-e0a8c752a0aa",
		"9393f6af-a473-4833-b34e-b6482c70aa09",
		"1ad2874b-0f5c-4f9f-bafc-dd60ffe9a532",
		"f4f4c787-2fb7-4c05-b6fd-f088400c3b1d",
		"211a771b-6aa5-40c7-bf65-d743946656fe"
	}
	for _, idStr in ipairs(extra) do
		local uuid = sm.uuid.new(idStr)
		local ok, res = pcall(sm.item.getShapeSize, uuid)
		if ok and res then
			table.insert(filters, uuid)
		end
	end
	if #filters > 0 then container:setFilters(filters) end
end

function vend.server_onFixedUpdate(self, dt)
	if not self.sv.canDrop then
		self.sv.downDelay = self.sv.downDelay + 1
		if self.sv.downDelay >= DropDelay then
			self.sv.downDelay = 0
			self.sv.canDrop = true
		end
	end
end

function vend.sv_tryDrop(self, _, player)
	if not self.sv.canDrop or not player then return end
	local inventory = player:getInventory()
	if not inventory or not sm.container.canSpend(inventory, CoinUUID, 1) then
		self.network:sendToClient(player, "cl_alertNoCoin")
		return
	end
	self:sv_Drop(inventory)
end

function vend.sv_Drop(self, inventory)
	self.sv.canDrop = false
	local container = self.shape.interactable:getContainer(0)
	for slot = 0, ContainerSize - 1 do
		local item = container:getItem(slot)
		if item and item.quantity > 0 and item.uuid ~= CoinUUID then
			sm.container.beginTransaction()
			sm.container.spend(container, item.uuid, 1, true)
			sm.container.spend(inventory, CoinUUID, 1)

			-- передача монеты владельцу
			for _, p in ipairs(sm.player.getAllPlayers()) do
				if p.name == self.sv.ownerName then
					local ownerInv = p:getInventory()
					if ownerInv then
						sm.container.collect(ownerInv, CoinUUID, 1, true)
					end
					break
				end
			end

			local ok = sm.container.endTransaction()
			if ok then
				local pos = self.shape.worldPosition + (self.shape.up + sm.vec3.new(0, 0, -0.85))
				local success, size = pcall(sm.item.getShapeSize, item.uuid)
				if success and size then
					local s = sm.shape.createPart(item.uuid, pos, nil, true, false)
					if s and s.body then sm.physics.applyImpulse(s, self.shape.up * 10, true) end
				end
				self.network:sendToClients("cl_onDropAnim")
			end
			break
		end
	end
end


function vend.cl_onDropAnim(self)
	self.cl.poseValue = 1.0
	self.cl.poseVelocity = -4.0
end

function vend.cl_alertNoCoin(self)
	sm.gui.displayAlertText("Need coin(bearing) to buy")
end

function vend.client_onCreate(self)
	self.effects = {}
	self.displayedUuids = {}
	self.cl = {
		poseValue = 0.0,
		poseVelocity = 0.0,
		ownerName = nil,
		ownerRequestSent = false
	}
end

function vend.client_onUpdate(self, dt)
	if not self.cl.ownerName and not self.cl.ownerRequestSent then
		self.network:sendToServer("sv_requestOwnerId")
		self.cl.ownerRequestSent = true
	end

	local container = self.shape.interactable:getContainer(0)
	if not container then return end
	for i = 1, ContainerSize do
		local item = container:getItem(i - 1)
		if item and item.quantity > 0 then
			if not self.effects[i] or self.displayedUuids[i] ~= item.uuid then
				if self.effects[i] then self.effects[i]:stop() end
				local e = sm.effect.createEffect("ShapeRenderable", self.interactable)
				e:setParameter("uuid", item.uuid)
				local b = sm.item.getShapeSize(item.uuid)
				local s = sm.construction.constants.subdivideRatio / (math.max(b.x, b.y, b.z) or 1)
				e:setScale(sm.vec3.new(s, s, s))
				e:setOffsetPosition(SlotOffsets[i] or sm.vec3.zero())
				if self.data.filterUid and tostring(item.uuid) == tostring(self.data.filterUid) then
					-- default rotation
				else
					e:setOffsetRotation(sm.quat.new(0, 0.7071068, 0, 0.7071068))
				end
				e:start()
				self.effects[i] = e
				self.displayedUuids[i] = item.uuid
			end
		else
			if self.effects[i] then self.effects[i]:stop() end
			self.effects[i] = nil
			self.displayedUuids[i] = nil
		end
	end

	local k, d = 250, 2.5
	local f = -k * self.cl.poseValue - d * self.cl.poseVelocity
	self.cl.poseVelocity = self.cl.poseVelocity + f * dt
	self.cl.poseValue = self.cl.poseValue + self.cl.poseVelocity * dt
	if math.abs(self.cl.poseValue) < 0.001 and math.abs(self.cl.poseVelocity) < 0.001 then
		self.cl.poseValue = 0.0
		self.cl.poseVelocity = 0.0
	end
	self.interactable:setPoseWeight(0, self.cl.poseValue)
end

function vend.cl_setOwnerId(self, name)
	self.cl.ownerName = name
end

function vend.client_onTinker(self, character, state)
	if not state then return end
	local player = sm.localPlayer.getPlayer()
	if not player then return end

	if not self.cl.ownerName then
		self.network:sendToServer("sv_setOwner", player)
	elseif self.cl.ownerName == player.name then
		local c = self.shape.interactable:getContainer(0)
		if c then
			local gui = sm.gui.createContainerGui(true)
			gui:setText("UpperName", "Machine Storage")
			gui:setContainer("UpperGrid", c)
			gui:setText("LowerName", "Supply Storage")
			gui:setContainer("LowerGrid", sm.localPlayer.getInventory())
			gui:open()
		end
	else
		sm.gui.displayAlertText("Access denied. Only owner can open.")
	end
end

function vend.client_canTinker(self)
	local player = sm.localPlayer.getPlayer()
	if not player then return false end

	if not self.cl.ownerName then
		sm.gui.setInteractionText(sm.gui.getKeyBinding("Tinker", true), "Set Owner", sm.gui.getKeyBinding("Tinker", true))
		return true
	elseif self.cl.ownerName == player.name then
		sm.gui.setInteractionText(sm.gui.getKeyBinding("Tinker", true), "Storage", sm.gui.getKeyBinding("Tinker", true))
		return true
	else
		sm.gui.setInteractionText("Access to storage denied")
		return false
	end
end

function vend.client_onInteract(self)
	self.network:sendToServer("sv_tryDrop")
end

function vend.sv_requestOwnerId(self, _, player)
	if player then
		self.network:sendToClient(player, "cl_setOwnerId", self.sv.ownerName)
	end
end

function vend.sv_setOwner(self, player)
	if player then
		self.sv.ownerName = player.name
		self:sv_saveData()
		self.network:sendToClients("cl_setOwnerId", player.name)
	end
end
