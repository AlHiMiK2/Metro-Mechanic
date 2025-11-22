dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_meleeattacks.lua" )

local Damage = 20

---@class DrillTool : ToolClass
---@field isLocal boolean
---@field animationsLoaded boolean
---@field fpAnimations table
---@field tpAnimations table
DrillTool = class()

local renderables = {
	"$CONTENT_DATA/Characters/Renderable/DrillTool/drilltool.rend"
}

local renderablesTp = {"$CONTENT_DATA/Characters/Renderable/DrillTool/Animations/drilltool_tp.rend"}
local renderablesFp = {"$CONTENT_DATA/Characters/Renderable/DrillTool/Animations/drilltool_fp.rend"}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

local Range = 2
local AttackRate = 0.1

function DrillTool:client_onCreate()
	self.isLocal = self.tool:isLocal()
	self:init()
end

function DrillTool:client_onRefresh()
	self:init()
end

function DrillTool:init()
	if self.animationsLoaded == nil then
		self.animationsLoaded = false
	end

	self.attackTimer = 0
	self.blendTime = 0.2
	self:loadAnimations()
end

function DrillTool:loadAnimations()
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			idle = {"drilltool_idle", { looping = true } },
			use = {"drilltool_use", { looping = true } }
		}
	)
	local movementAnimations = {
		idle = "drilltool_idle",
		runFwd = "drilltool_idle",
		runBwd = "drilltool_idle",
		sprint = "drilltool_idle",
		jump = "drilltool_idle",
		jumpUp = "drilltool_idle",
		jumpDown = "drilltool_idle",
		land = "drilltool_idle",
		landFwd = "drilltool_idle",
		landBwd = "drilltool_idle",
	}

	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

	setTpAnimation( self.tpAnimations, "idle", 5.0 )

	if self.isLocal then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "drilltool_idle", { nextAnimation = "idle" } },
				unequip = { "drilltool_idle" },
				idle = { "drilltool_idle",  { looping = true } },
			}
		)
		setFpAnimation( self.fpAnimations, "idle", 0.0 )
	end

	self.animationsLoaded = true
end

function DrillTool:client_onUpdate( dt )
	if self.attackTimer < AttackRate then
		self.attackTimer = self.attackTimer + dt
	end

	if not self.animationsLoaded then
		return
	end

	if self.tool:isLocal() then
		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end

	local crouchWeight = self.tool:isCrouching() and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight
	local totalWeight = 0.0

	for name, animation in pairs( self.tpAnimations.animations ) do
		animation.time = animation.time + dt

		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min( animation.weight + ( self.tpAnimations.blendSpeed * dt ), 1.0 )
			
			if animation.looping == true then
				if animation.time >= animation.info.duration then
					animation.time = animation.time - animation.info.duration
				end
			end
			if animation.time >= animation.info.duration - self.blendTime and not animation.looping then
				if ( name == "use" ) then
					setTpAnimation( self.tpAnimations, "idle", 10.0 )
				elseif name == "pickup" then
					setTpAnimation( self.tpAnimations, "idle", 0.001 )
				elseif animation.nextAnimation ~= "" then
					setTpAnimation( self.tpAnimations, animation.nextAnimation, 0.001 )
				end
				
			end
		else
			animation.weight = math.max( animation.weight - ( self.tpAnimations.blendSpeed * dt ), 0.0 )
		end

		totalWeight = totalWeight + animation.weight
	end

	totalWeight = totalWeight == 0 and 1.0 or totalWeight
	for name, animation in pairs( self.tpAnimations.animations ) do
		local weight = animation.weight / totalWeight
		if name == "idle" then
			self.tool:updateMovementAnimation( animation.time, weight )
		elseif animation.crouch then
			self.tool:updateAnimation( animation.info.name, animation.time, weight * normalWeight )
			self.tool:updateAnimation( animation.crouch.name, animation.time, weight * crouchWeight )
		else
			self.tool:updateAnimation( animation.info.name, animation.time, weight )
		end
	end
end

function DrillTool:client_onEquippedUpdate( primaryState, secondaryState )
	if primaryState == sm.tool.interactState.hold and self.attackTimer >= AttackRate then
		local raycastStart = sm.localPlayer.getRaycastStart()
		local direction = sm.localPlayer.getDirection()

		sm.melee.meleeAttack( sm.uuid.new("d153268c-67d4-4436-9693-c8449816a6d2"), Damage, raycastStart, direction * Range, self.tool:getOwner() )
		self.attackTimer = 0
	end

	return true, false
end

function DrillTool:client_onEquip( animate )
	if animate then
		sm.audio.play( "Sledgehammer - Equip", self.tool:getPosition() )
	end

	self.equipped = true

	for k,v in pairs( renderables ) do renderablesTp[#renderablesTp+1] = v end
	for k,v in pairs( renderables ) do renderablesFp[#renderablesFp+1] = v end

	self.tool:setTpRenderables( renderablesTp )

	self:init()

	setTpAnimation( self.tpAnimations, "idle", 0.0001 )

	if self.isLocal then
		self.tool:setFpRenderables( renderablesFp )
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end

	self.tool:setBlockSprint(true)
end

function DrillTool:client_onUnequip( animate )

	self.equipped = false
	if sm.exists( self.tool ) then
		if animate then
			sm.audio.play( "Sledgehammer - Unequip", self.tool:getPosition() )
		end
		setTpAnimation( self.tpAnimations, "unequip" )
		if self.isLocal and self.fpAnimations.currentAnimation ~= "unequip" then
			swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
		end
	end

	self.tool:setBlockSprint(false)
end
