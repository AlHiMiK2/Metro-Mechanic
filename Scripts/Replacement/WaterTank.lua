dofile( "$SURVIVAL_DATA/Scripts/game/survival_items.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

WaterTank = class( nil )
WaterTank.poseWeightCount = 2
WaterTank.maxChildCount = 255

WaterTank.connectionOutput = sm.interactable.connectionType.water
WaterTank.colorNormal = sm.color.new( 0x84ff32ff )
WaterTank.colorHighlight = sm.color.new( 0xa7ff4fff )

local ContainerSize = 1

function WaterTank.server_onCreate( self )
	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container = self.shape:getInteractable():addContainer( 0, ContainerSize, self.data.stackSize )
	end
	if self.data.filterUid then
		local filters = { sm.uuid.new( self.data.filterUid ) }
		container:setFilters( filters )
	end
end

function WaterTank.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function WaterTank.client_onInteract( self, character, state )
	if state == true then
		local container = self.shape.interactable:getContainer( 0 )
		if container then
			local gui = nil --sm.gui.createWaterContainerGui( true )
			gui = sm.gui.createContainerGui( true )
			gui:setText( "UpperName", "#{CONTAINER_TITLE_GENERIC}" )
			
			gui:setContainer( "UpperGrid", container )
			gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
			gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
			gui:open()
		end
	end
end

function WaterTank.client_onUpdate( self, dt )

	local container = self.shape.interactable:getContainer( 0 )
	if container and self.data.stackSize then
		local quantities = sm.container.quantity( container )

		local quantity = 0
		for _,q in ipairs( quantities ) do
			quantity = quantity + q
		end

		local maxl = ContainerSize * self.data.stackSize
		local water_lvl = quantity / maxl --ContainerSize - math.ceil( quantity / self.data.stackSize )
		if water_lvl <= 0.216 then
			self.interactable:setPoseWeight(0, 1 - (water_lvl * 4.6))
			self.interactable:setPoseWeight(1, 0)
		else
			self.interactable:setPoseWeight(0, 0)
			self.interactable:setPoseWeight(1, (water_lvl - 0.216) * 1.276)
		end
	end
end