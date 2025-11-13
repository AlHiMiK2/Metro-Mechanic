Broom = class()

Broom.maxParentCount	= 0
Broom.maxChildCount		= 1
Broom.connectionOutput	= 512

function Broom.server_onCreate(self)
	self.updateTimer = 0
	local cont = self.interactable:addContainer(0, 1, 1)
	cont:setFilters({ sm.uuid.new("910a7f2c-52b0-46eb-8873-ad13255539af")})
end

function Broom.client_onCreate(self)
end

function Broom.client_onRefresh(self)
end


function Broom.server_onFixedUpdate(self, dt)
	self.updateTimer = self.updateTimer + dt
    local Children = self.interactable:getChildren(512)
	self.cont = self.interactable:getContainer(0)
	if Children[1] ~= nil then
		if self.updateTimer > 0.25 and self.cont:getItem(0).quantity == 0 then
			self.updateTimer = 0
			local Start = self.shape.worldPosition
			local End = Start + self.shape:getAt() * -0.25
			succes, result = sm.physics.raycast(Start, End)
			if succes then
				if (result:getShape() ~= nil) and result:getShape().uuid == sm.uuid.new("f0caa8dc-889a-4aba-9cc1-0bf01826a15a") then
					sm.container.beginTransaction()
					sm.container.collect(self.cont, sm.uuid.new("910a7f2c-52b0-46eb-8873-ad13255539af"), 1)
					sm.container.endTransaction()
				end
			end
		end
	end
	if self.updateTimer > 0.25 and self.cont:getItem(0).quantity == 1 then
		self.updateTimer = 0
		local Start = self.shape.worldPosition
		local End = Start + self.shape:getAt() * -0.25
		succes, result = sm.physics.raycast(Start, End)
		if succes then
			if not ((result:getShape() ~= nil) and result:getShape().uuid == sm.uuid.new("f0caa8dc-889a-4aba-9cc1-0bf01826a15a")) then
				sm.container.beginTransaction()
				sm.container.spend(self.cont, sm.uuid.new("910a7f2c-52b0-46eb-8873-ad13255539af"), 1)
				sm.container.endTransaction()
			end
		else
			sm.container.beginTransaction()
			sm.container.spend(self.cont, sm.uuid.new("910a7f2c-52b0-46eb-8873-ad13255539af"), 1)
			sm.container.endTransaction()
		end
	end
end
--[[
function Broom.server_onCollision(self, other, _, selfPointVelocity, otherPointVelocity)
    if type(other) == "Shape" then
        print(other.uuid)
    end
end
]]