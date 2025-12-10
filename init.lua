itemforge3d = {
    defs = {},      
    equipped = {},     
    entities = {},   
    cached_stats = {}, 
    slots = { "shield", "helmet", "chest", "legs", "boots" },

    on_equip = nil, 
    on_unequip = nil,   
}

local function is_valid_slot(slot)
    for _, s in ipairs(itemforge3d.slots) do
        if s == slot then return true end
        return false
    end
end

function itemforge3d.register(modname, name, def)
    local full_name = modname .. ":" .. name

    if itemforge3d.defs[full_name] then
        core.log("warning", "[itemforge3d] Duplicate registration for " .. full_name)
    end

    if def.slot and not is_valid_slot(def.slot) then
        core.log("warning", "[itemforge3d] Unknown slot '" .. def.slot .. "' for " .. full_name)
    end

    if def.type == "tool" then
        core.register_tool(full_name, def)
    elseif def.type == "node" then
        core.register_node(full_name, def)
    elseif def.type == "craftitem" then
        core.register_craftitem(full_name, def)
    else
        core.log("warning", "[itemforge3d] Unknown type for " .. full_name)
    end

    if def.craft then
        core.register_craft(def.craft)
    elseif def.recipe then
        core.register_craft({
            output = full_name,
            recipe = def.recipe
        })
    end

    itemforge3d.defs[full_name] = def
end

core.register_entity("itemforge3d:wield_entity", {
    initial_properties = {
        visual = "mesh",
        mesh = "blank.glb",
        textures = {},
        visual_size = {x=1, y=1},
        pointable = false,
        physical = false,
        collide_with_objects = false,
    },
})

local function attach_model(player, def)
    local pname = player:get_player_name()
    local ent = core.add_entity({x=0,y=0,z=0}, "itemforge3d:wield_entity")
    if not ent then return end

    if def.attach_model and def.attach_model.properties then
        ent:set_properties(def.attach_model.properties)
    else
        ent:set_properties({
            mesh = "blank.glb",
            textures = {def.inventory_image or "blank.png"},
            visual_size = {x=0, y=0}
        })
    end

    local a = def.attach_model and def.attach_model.attach or {}
    ent:set_attach(player,
        a.bone or "Arm_Right",
        a.position or {x=0,y=5,z=0},
        a.rotation or {x=0,y=90,z=0},
        a.forced_visible or false
    )

    local slot = def.slot or "weapon"
    itemforge3d.entities[pname] = itemforge3d.entities[pname] or {}
    itemforge3d.entities[pname][slot] = ent

    itemforge3d.equipped[pname] = itemforge3d.equipped[pname] or {}
    itemforge3d.equipped[pname][slot] = def

    itemforge3d.refresh_stats(player)

    if itemforge3d.on_equip then
        itemforge3d.on_equip(player, def, slot)
    end
end

function itemforge3d.equip(player, itemname)
    local pname = player:get_player_name()
    local def = itemforge3d.defs[itemname]
    if not def or not def.slot then return end

    if itemforge3d.entities[pname] and itemforge3d.entities[pname][def.slot] then
        local old_def = itemforge3d.equipped[pname][def.slot]
        itemforge3d.entities[pname][def.slot]:remove()
        itemforge3d.entities[pname][def.slot] = nil
        itemforge3d.equipped[pname][def.slot] = nil

        if itemforge3d.on_unequip and old_def then
            itemforge3d.on_unequip(player, old_def, def.slot)
        end
    end

    attach_model(player, def)
end

core.register_on_leaveplayer(function(player)
    local pname = player:get_player_name()
    if itemforge3d.entities[pname] then
        for slot, ent in pairs(itemforge3d.entities[pname]) do
            ent:remove()
            if itemforge3d.on_unequip and itemforge3d.equipped[pname] and itemforge3d.equipped[pname][slot] then
                itemforge3d.on_unequip(player, itemforge3d.equipped[pname][slot], slot)
            end
        end
        itemforge3d.entities[pname] = nil
    end
    itemforge3d.equipped[pname] = nil
    itemforge3d.cached_stats[pname] = nil
end)

core.register_on_dieplayer(function(player)
    local pname = player:get_player_name()
    if itemforge3d.entities[pname] then
        for slot, ent in pairs(itemforge3d.entities[pname]) do
            ent:remove()
            if itemforge3d.on_unequip and itemforge3d.equipped[pname] and itemforge3d.equipped[pname][slot] then
                itemforge3d.on_unequip(player, itemforge3d.equipped[pname][slot], slot)
            end
        end
        itemforge3d.entities[pname] = nil
    end
    itemforge3d.equipped[pname] = nil
    itemforge3d.cached_stats[pname] = nil
end)

function itemforge3d.refresh_stats(player)
    local pname = player:get_player_name()
    local stats = {}
    if itemforge3d.equipped[pname] then
        for slot, def in pairs(itemforge3d.equipped[pname]) do
            if def.stats then
                for k,v in pairs(def.stats) do
                    stats[k] = (stats[k] or 0) + v
                end
            end
        end
    end
    itemforge3d.cached_stats[pname] = stats
end

function itemforge3d.get_stats(player)
    local pname = player:get_player_name()
    return itemforge3d.cached_stats[pname] or {}
end

local last_wielded = {}
local timer = 0
local interval = 0.5

core.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < interval then return end
    timer = 0

    for _, player in ipairs(core.get_connected_players()) do
        local pname = player:get_player_name()
        local wielded = player:get_wielded_item():get_name()

        if wielded ~= "" and wielded ~= last_wielded[pname] then
            last_wielded[pname] = wielded
            local def = itemforge3d.defs[wielded]
            if def and def.auto_wield then
                itemforge3d.equip(player, wielded)
            end
        end
    end
end)

core.register_on_leaveplayer(function(player)
    local pname = player:get_player_name()
    last_wielded[pname] = nil
end)

function itemforge3d.is_equipped(player, slot)
    local pname = player:get_player_name()
    return itemforge3d.equipped[pname] and itemforge3d.equipped[pname][slot] ~= nil
end

function itemforge3d.get_equipped_item(player, slot)
    local pname = player:get_player_name()
    if itemforge3d.equipped[pname] then
        return itemforge3d.equipped[pname][slot]
    end
    return nil
end

function itemforge3d.unequip(player, slot)
    local pname = player:get_player_name()
    if itemforge3d.entities[pname] and itemforge3d.entities[pname][slot] then
        local old_def = itemforge3d.equipped[pname][slot]
        itemforge3d.entities[pname][slot]:remove()
        itemforge3d.entities[pname][slot] = nil
        itemforge3d.equipped[pname][slot] = nil

        if itemforge3d.on_unequip and old_def then
            itemforge3d.on_unequip(player, old_def, slot)
        end

        itemforge3d.refresh_stats(player)
    end
end