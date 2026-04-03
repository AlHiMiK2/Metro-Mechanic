dofile("$CONTENT_DATA/Scripts/Game/ProductList.lua")
dofile( "$SURVIVAL_DATA/Scripts/game/survival_projectiles.lua" )

---@class VendingMachine : ShapeClass
VendingMachine = class()
--product
--uuid, price, count, chance

function VendingMachine:server_onCreate()
    self:sv_init()
end

function VendingMachine:sv_init()
    self.sv = self.storage:load() or {
        products = SelectProducts(6)
    }
    self.network:setClientData(self.sv)
end

function VendingMachine:sv_createProduct(data)
    local product = self.sv.products[data.productId]
    local money = sm.container.totalQuantity(data.container, Currency)

    if money >= product.price * product.count then
        local params = { lootUid = product.uuid, lootQuantity = product.count, epic = false }
        local vel = sm.vec3.new(0, 0.25, 0.5) * (4+math.random()*2)
	    local projectileUuid = params.epic and projectile_epicloot or projectile_loot
        sm.projectile.shapeCustomProjectileAttack( params, projectileUuid, 0, sm.vec3.new( 0, 0, 0 ), vel, self.shape, 0 )
        sm.container.beginTransaction()
        sm.container.spend(data.container, Currency, product.price * product.count, false)
        sm.container.endTransaction()
        product.selled = true
        self.network:setClientData(self.sv)
        self.storage:save(self.sv)
    end
end

function VendingMachine:client_onCreate()
    self:cl_init()
end

function VendingMachine:cl_init()
    self.cl = {}
    local gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/VendingMachine.layout")
    self.gui = gui
    for i = 1, 6, 1 do
        self.gui:setButtonCallback("Buy".. i, "cl_onBuyButtonPressed")
    end
end

function VendingMachine:cl_onBuyButtonPressed(buttonName)
    local container = sm.localPlayer.getPlayer():getInventory()
    local productId = tonumber(buttonName:sub(-1))
    self.network:sendToServer("sv_createProduct", {container = container, productId = productId})
end

function VendingMachine:client_onInteract(character, state)
    if state == true then
        self.gui:open()
        self:cl_updateGUI()
    end
end

function VendingMachine:cl_updateGUI()
    local player = sm.localPlayer.getPlayer()
    local inventory = player:getInventory()
    local money = sm.container.totalQuantity(inventory, Currency)
    for i = 1, 6, 1 do
        local state = money >= self.cl.products[i].price * self.cl.products[i].count and not self.cl.products[i].selled
        self.gui:setVisible("Buy".. i, state)
    end
end

function VendingMachine:client_onClientDataUpdate(data, channel)
    for k, v in pairs(data) do
        self.cl[k] = v
    end

    self:cl_updateProducts()
end

function VendingMachine:cl_updateProducts()
    for i = 1, 6, 1 do
        local product = self.cl.products[i]
        self.gui:setIconImage("Logo".. i, product.uuid)
        self.gui:setText("Count".. i, "X".. product.count)
        if product.selled == true then
            self.gui:setText("Price".. i, "Selled")
        else
            self.gui:setText("Price".. i, tostring(product.price * product.count))
        end
    end

    self:cl_updateGUI()
end