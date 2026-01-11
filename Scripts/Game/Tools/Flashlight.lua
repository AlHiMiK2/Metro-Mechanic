dofile( "$GAME_DATA/Scripts/game/AnimationUtil.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )

Flashlight = class()

local renderables =   {"$CONTENT_DATA/Tools/Mesh/flashlight.rend" }
local renderablesTp = {"$CONTENT_DATA/Tools/Mesh/ThrowAnim/char_male_tp_glowstick.rend", "$SURVIVAL_DATA/Character/Char_Glowstick/char_glowstick_tp_animlist.rend"}
local renderablesFp = {"$CONTENT_DATA/Tools/Mesh/ThrowAnim/char_male_fp_glowstick.rend", "$SURVIVAL_DATA/Character/Char_Glowstick/char_glowstick_fp_animlist.rend"}

local currentRenderablesTp = {}
local currentRenderablesFp = {}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Flashlight.cl_loadAnimations( self )
	
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			idle = { "glowstick_idle" },
			use = { "glowstick_use", { nextAnimation = "idle" } },
			sprint = { "glowstick_sprint" },
			pickup = { "glowstick_pickup", { nextAnimation = "idle" } },
			putdown = { "glowstick_putdown" }
		
		}
	)
	local movementAnimations = {
	
		idle = "glowstick_idle",
		
		runFwd = "glowstick_run_fwd",
		runBwd = "glowstick_run_bwd",
		sprint = "glowstick_sprint",
		
		jump = "glowstick_jump_start",
		jumpUp = "glowstick_jump_up",
		jumpDown = "glowstick_jump_down",
		
		land = "glowstick_jump_land",
		landFwd = "glowstick_jump_land_fwd",
		landBwd = "glowstick_jump_land_bwd",

		crouchIdle = "glowstick_crouch_idle",
		crouchFwd = "glowstick_crouch_fwd",
		crouchBwd = "glowstick_crouch_bwd"
	}

	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

	if self.tool:isLocal() then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				idle = { "glowstick_idle", { looping = true } },
				use = { "glowstick_use", { nextAnimation = "idle" } },
				equip = { "glowstick_pickup", { nextAnimation = "idle" } },
				unequip = { "glowstick_putdown" }
			}
		)
	end
	setTpAnimation( self.tpAnimations, "idle", 5.0 )
	self.blendTime = 0.2
	
end


function Flashlight.client_onCreate(self)
    self:client_onRefresh()
end

function Flashlight.client_onRefresh(self)
	--[[ Default Settings
			"color": "eeeeee",
			"range": 10.0,
			"coneFade": 0.5,
			"coneAngle": 45.0,
			"intensity": 1.0,
			"maxIntensity": 1.0,
			"ambient": true,
			"additive": false,
			"ambientPosScale": 0.25,
			"ambientIntensityScale": 0.2,
			"ambientMaxIntensity": 0.0,
			"ambientRangeScale": 1.0,
			"falloffMode": 0,
			"falloffFactor": 1.0,
			"shadowMode": 1
	]]--

	self.settings = {
		color = "C3784C",
		range = 30.0,
		coneFade = 0.5,
		coneAngle = 45.0,
		intensity = 1.0,
		maxIntensity = 1.0,
		ambient = true,
		additive = false,
		ambientPosScale = 0.25,
		ambientIntensityScale = 0.2,
		ambientMaxIntensity = 0.0,
		ambientRangeScale = 1.0,
		falloffMode = 0,
		falloffFactor = 1.0,
		shadowMode = 1
	}


	self:cl_loadAnimations()
	
	self.Effect = sm.effect.createEffect("EnvironmentSpotLight_Static_Small", self.tool:getOwner().character, "jnt_right_weapon")

	
	self.Effect:setOffsetPosition(sm.vec3.new(0, 0, 0.2))
	self.Effect:setOffsetRotation(sm.quat.fromEuler(sm.vec3.new(0, 180, 0)))

	if self.data.color ~= nil then
		self.settings.color = self.data.color
	end
	if self.data.range ~= nil then
		self.settings.range = self.data.range
	end
	if self.data.coneFade ~= nil then
		self.settings.coneFade = self.data.coneFade
	end
	if self.data.coneAngle ~= nil then
		self.settings.coneAngle = self.data.coneAngle
	end
	if self.data.intensity ~= nil then
		self.settings.intensity = self.data.intensity
	end
	if self.data.maxIntensity ~= nil then
		self.settings.maxIntensity = self.data.maxIntensity
	end
	if self.data.ambient ~= nil then
		self.settings.ambient = self.data.ambient
	end
	if self.data.additive ~= nil then
		self.settings.additive = self.data.additive
	end
	if self.data.ambientPosScale ~= nil then
		self.settings.ambientPosScale = self.data.ambientPosScale
	end
	if self.data.ambientIntensityScale ~= nil then
		self.settings.ambientIntensityScale = self.data.ambientIntensityScale
	end
	if self.data.ambientRangeScale ~= nil then
		self.settings.ambientRangeScale = self.data.ambientRangeScale
	end
	if self.data.falloffMode ~= nil then
		self.settings.falloffMode = self.data.falloffMode
	end
	if self.data.falloffFactor ~= nil then
		self.settings.falloffFactor = self.data.falloffFactor
	end
	if self.data.shadowMode ~= nil then
		self.settings.shadowMode = self.data.shadowMode
	end

	
    self.Effect:setParameter("color", sm.color.new(self.settings.color))
    self.Effect:setParameter("range", self.settings.range)
    self.Effect:setParameter("coneFade", self.settings.coneFade)
    self.Effect:setParameter("coneAngle", self.settings.coneAngle)
    self.Effect:setParameter("intensity", self.settings.intensity)
    self.Effect:setParameter("ambient", self.settings.ambient)
    self.Effect:setParameter("additive", self.settings.additive)
    self.Effect:setParameter("ambientPosScale", self.settings.ambientPosScale)
    self.Effect:setParameter("ambientIntensityScale", self.settings.ambientIntensityScale)
    self.Effect:setParameter("ambientRangeScale", self.settings.ambientRangeScale)
    self.Effect:setParameter("falloffMode", self.settings.falloffMode)
    self.Effect:setParameter("falloffFactor", self.settings.falloffFactor)
    self.Effect:setParameter("shadowMode", self.settings.shadowMode)

	self.wantToggle = false
	self.isActive = false
end

function Flashlight.client_onUpdate( self, dt )
	-- First person animation	
	local isSprinting =  self.tool:isSprinting() 
	local isCrouching =  self.tool:isCrouching() 
	
	
	if self.tool:isLocal() then
		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end

	
	
	if not self.equipped then
		if self.wantEquipped then
			self.wantEquipped = false
			self.equipped = true
		end
		return
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

function Flashlight.client_onFixedUpdate( self, dt )
	if self.wantToggle and not self.isActive then
		self.Effect:start()
		self.isActive = true
		self.wantToggle = false
	elseif self.wantToggle and self.isActive then
		self.Effect:stop()
		self.isActive = false
		self.wantToggle = false
	end
end

function Flashlight.client_onEquippedUpdate(self, primaryState, secondaryState)
    if primaryState == 1 then
		self.wantToggle = true
		return false, true
    end
    return true, true
end

function Flashlight.client_onReload(self)
    return true
end

function Flashlight.client_onEquip( self )
	
	self.wantEquipped = true
	

	currentRenderablesTp = {}
	currentRenderablesFp = {}
	
	for k,v in pairs( renderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	
	self.tool:setTpRenderables( currentRenderablesTp )
	if self.tool:isLocal() then
		self.tool:setFpRenderables( currentRenderablesFp )
	end
	
	self:cl_loadAnimations()
	
	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )
	if self.tool:isLocal() then
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end

end

function Flashlight.client_onUnequip( self )
	self.wantToggle = false
	self.isActive = false
	self.Effect:stop()
	self.wantEquipped = false
	self.equipped = false
	self.pendingThrowFlag = false
	if sm.exists( self.tool ) then
		setTpAnimation( self.tpAnimations, "putdown" )
		if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" then
			swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
		end
	end
end
