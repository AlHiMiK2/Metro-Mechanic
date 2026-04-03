dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )

Currency = obj_decor_screw01
local products = {
    {uuid = obj_consumable_glowstick, price = 5, count = 4, chance = 14},
    {uuid = obj_decor_poster02, price = 5, count = 8, chance = 35},
    {uuid = obj_consumable_sunshake, price = 5, count = 5, chance = 100},
    {uuid = obj_consumable_carrotburger, price = 5, count = 5, chance = 100},
    {uuid = obj_consumable_water, price = 5, count = 5, chance = 100},
    {uuid = obj_consumable_milk, price = 5, count = 1, chance = 35},
    {uuid = blk_stripednet, price = 5, count = 6, chance = 7},
}

-- Предварительная подготовка данных (один раз)
local productList = {}
local totalChance = 0

for _, product in ipairs(products) do
    table.insert(productList, {
        uuid = product.uuid,
        price = product.price,
        count = product.count,
        chance = product.chance,
        chanceStart = totalChance + 1,
        chanceEnd = totalChance + product.chance
    })
    totalChance = totalChance + product.chance
end

function SelectProducts(count)
    if count <= 0 then return {} end

    local selected = {}

    for _ = 1, count do
        local randomValue = math.random(1, totalChance)

        local left, right = 1, #productList
        local selectedProduct = nil

        while left <= right do
            local mid = math.floor((left + right) / 2)
            local product = productList[mid]

            if randomValue < product.chanceStart then
                right = mid - 1
            elseif randomValue > product.chanceEnd then
                left = mid + 1
            else
                selectedProduct = product
                break
            end
        end

        if selectedProduct then
            table.insert(selected, {
                uuid = selectedProduct.uuid,
                price = selectedProduct.price,
                count = selectedProduct.count,
                chance = selectedProduct.chance
            })
        end
    end

    return selected
end