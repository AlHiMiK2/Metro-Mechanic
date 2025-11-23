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

local renderablesTp = {"$CONTENT_DATA/Characters/Renderable/DrillTool/Animations/drilltool_tp.rend", "$CONTENT_DATA/Characters/Renderable/DrillTool/drilltool.rend"}
local renderablesFp = {"$CONTENT_DATA/Characters/Renderable/DrillTool/Animations/drilltool_fp.rend", "$CONTENT_DATA/Characters/Renderable/DrillTool/drilltool.rend"}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

local Range = 2.5
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
	self.useFlag = false
	self.prevUseFlag = false
	self.dispersion = 0.0
	self.jointWeight = 0.0
	self.spineWeight = 0.0
	self.aimBlendSpeed = 3.0
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
	self.velocity = 0
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
		runFwd = "drilltool_run",
		runBwd = "drilltool_run2",
	}

	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

	setTpAnimation( self.tpAnimations, "idle", self.blendTime )

	if self.isLocal then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "drilltool_equip", { nextAnimation = "idle" } },
				unequip = { "drilltool_unequip" },
				idle = { "drilltool_idle",  { looping = true } },
				use = {"drilltool_use", { looping = true } }
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

	self.dispersion = math.max( 0.0, self.dispersion - dt * 4.0 )
	self.tool:setDispersionFraction( self.dispersion )

	if self.useFlag then
		self.velocity = math.min(self.velocity + dt * 1.125, 1.0)
	else
		self.velocity = math.max(self.velocity - dt * 0.75, 0.0)
	end

	if sm.exists(self.drillEffect) then
		self.drillEffect:setParameter( "velocity", self.velocity)
	end

	if not self.animationsLoaded then
		return
	end

	if self.useFlag ~= self.prevUseFlag then
		if self.useFlag then
			setTpAnimation( self.tpAnimations, "use", self.blendTime )

			if self.isLocal then
				setFpAnimation( self.fpAnimations, "use", self.blendTime )
			end
		else
			setTpAnimation( self.tpAnimations, "idle", self.blendTime )

			if self.isLocal then
				setFpAnimation( self.fpAnimations, "idle", self.blendTime )
			end
		end

		self.prevUseFlag = self.useFlag
	end

	updateTpAnimations( self.tpAnimations, self.equipped, dt )

	if self.isLocal then
		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end

	self:cl_aimUpdate(dt)
end

function DrillTool:cl_aimUpdate(dt)
	local playerDir = self.tool:getSmoothDirection()
	local angle = math.asin( playerDir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 )
	local crouchWeight = self.tool:isCrouching() and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight
	local isSprinting =  self.tool:isSprinting()
	local relativeMoveDirection = self.tool:getRelativeMoveDirection()
	if ( self.tpAnimations.currentAnimation == "use") then
		self.jointWeight = math.min( self.jointWeight + ( 10.0 * dt ), 1.0 )
	else
		self.jointWeight = math.max( self.jointWeight - ( 6.0 * dt ), 0.0 )
	end

	if ( not isSprinting ) then
		self.spineWeight = math.min( self.spineWeight + ( 10.0 * dt ), 1.0 )
	else
		self.spineWeight = math.max( self.spineWeight - ( 10.0 * dt ), 0.0 )
	end

	local totalOffsetZ = lerp( -22.0, -26.0, crouchWeight )
	local totalOffsetY = lerp( 6.0, 12.0, crouchWeight )
	local crouchTotalOffsetX = clamp( ( angle * 60.0 ) -15.0, -60.0, 40.0 )
	local normalTotalOffsetX = clamp( ( angle * 50.0 ), -45.0, 50.0 )
	local totalOffsetX = lerp( normalTotalOffsetX, crouchTotalOffsetX , crouchWeight )

	local finalJointWeight = ( self.jointWeight )

	self.tool:updateJoint( "jnt_hips", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), 0.35 * finalJointWeight * ( normalWeight ) )

	local crouchSpineWeight = ( 0.35 / 3 ) * crouchWeight

	self.tool:updateJoint( "jnt_spine1", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.10 + crouchSpineWeight )  * finalJointWeight )
	self.tool:updateJoint( "jnt_spine2", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.10 + crouchSpineWeight ) * finalJointWeight )
	self.tool:updateJoint( "jnt_spine3", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.45 + crouchSpineWeight ) * finalJointWeight )
	self.tool:updateJoint( "jnt_head", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), 0.3 * finalJointWeight )

	-- Camera update
	local bobbing = 1
	if self.useFlag then
		local blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 60 )
		self.aimWeight = sm.util.lerp( self.aimWeight, 1.0, blend )
		bobbing = 0.12
	else
		local blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 60 )
		self.aimWeight = sm.util.lerp( self.aimWeight, 0.0, blend )
		bobbing = 1
	end

	self.tool:updateCamera( 2.8, 30.0, sm.vec3.new( 0.65, 0.0, 0.05 ), self.aimWeight )
	self.tool:updateFpCamera( 30.0, sm.vec3.new( 0.0, 0.0, 0.0 ), self.aimWeight, bobbing )
end

function DrillTool:client_onEquippedUpdate( primaryState, secondaryState )
	self.useFlag = primaryState == sm.tool.interactState.hold

	if self.useFlag and self.attackTimer >= AttackRate and self.velocity > 0.9 then
		local raycastStart = sm.localPlayer.getRaycastStart()
		local direction = sm.localPlayer.getDirection()

		sm.melee.meleeAttack( sm.uuid.new("d153268c-67d4-4436-9693-c8449816a6d2"), Damage, raycastStart, direction * Range, self.tool:getOwner() )
		self.dispersion = 0.8
		self.tool:setDispersionFraction(self.dispersion)
		self.attackTimer = 0
	end

	return true, false
end

function DrillTool:client_onEquip( animate )
	if animate then
		sm.audio.play( "Sledgehammer - Equip", self.tool:getPosition() )
	end

	self.velocity = 0
	self.drillEffect = sm.effect.createEffect( "Drill - StoneDrill", self.tool:getOwner().character )
	self.drillEffect:setParameter( "impact", 1 )
	self.drillEffect:setParameter( "velocity", self.velocity )
	self.drillEffect:start()

	self.equipped = true

	self.tool:setTpRenderables( renderablesTp )
	self.tool:setTpColor(sm.color.new("815406FF"))

	if self.isLocal then
		self.tool:setFpRenderables( renderablesFp )
		self.tool:setFpColor(sm.color.new("815406FF"))
	end

	self:loadAnimations()

	if self.isLocal then
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
		setFpAnimationProgress( self.fpAnimations, "equip", 0.1 )
	end

	self.tool:setBlockSprint(true)
end

function DrillTool:client_onUnequip( animate )
	self.equipped = false
	self.useFlag = false
	self.drillEffect:destroy()
	self.velocity = 0

	if sm.exists( self.tool ) then
		if animate then
			sm.audio.play( "Sledgehammer - Unequip", self.tool:getPosition() )
		end

		setTpAnimation( self.tpAnimations, "idle" )

		if self.isLocal and self.fpAnimations.currentAnimation ~= "unequip" then
			swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
		end
	end

	self.tool:setBlockSprint(false)
end
