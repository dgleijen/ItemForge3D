local REGISTERED_ITEMS = {}
local EQUIPED_ITEMS = {}
local ENTITIES = {}
local ENTITY_POOL = {}
local ITEM_ID_COUNTER = 0 

local IFORGE = {}
IFORGE.slots = { "shield", "helmet", "chest", "legs", "boots" }

local function is_valid_slot(slot)
    for _, s in ipairs(IFORGE.slots) do
        if s == slot then return true end
    end
    return false
end

local function get_entity_from_pool()
    local ent = table.remove(ENTITY_POOL)
    if not ent then
        ent = core.add_entity({x=0,y=0,z=0}, "itemforge3d:wield_entity")
    end
    return ent
end

local function return_entity_to_pool(entity)
    if entity then
        entity:set_properties({
            visual = "mesh",
            mesh = "blank.glb",
            textures = {"blank.png"},
            visual_size = {x=1, y=1},
            pointable = false,
            physical = false,
            collide_with_objects = false,
        })
        
        entity:set_detach()
        entity:set_properties({visual_size = {x=0, y=0}})
        
        table.insert(ENTITY_POOL, entity)
    end
end

function IFORGE.register(modname, item_name, register_def)
    local full_name = modname .. ":" .. item_name

    if REGISTERED_ITEMS[full_name] then
        core.log("error", "[itemforge3d] Duplicate registration for " .. full_name)
        return false
    end

    if register_def.slot and not is_valid_slot(register_def.slot) then
        core.log("warning", "[itemforge3d] Unknown slot '" .. register_def.slot .. "' for " .. full_name)
    end

    ITEM_ID_COUNTER = ITEM_ID_COUNTER + 1
    register_def.id = ITEM_ID_COUNTER
    register_def.name = full_name

    if register_def.type == "tool" then
        core.register_tool(full_name, register_def)
    elseif register_def.type == "node" then
        core.register_node(full_name, register_def)
    elseif register_def.type == "craftitem" then
        core.register_craftitem(full_name, register_def)
    else
        core.log("warning", "[itemforge3d] Unknown type '" .. tostring(register_def.type) .. "' for " .. full_name)
        return false
    end

    if register_def.craft then
        core.register_craft(register_def.craft)
    elseif register_def.recipe then
        core.register_craft({
            output = full_name,
            recipe = register_def.recipe
        })
    end

    REGISTERED_ITEMS[full_name] = register_def
    return true
end

core.register_entity("itemforge3d:wield_entity", {
    initial_properties = {
        visual = "mesh",
        mesh = "blank.glb",
        textures = {"blank.png"},
        visual_size = {x=1, y=1},
        pointable = false,
        physical = false,
        collide_with_objects = false,
    },
})

function IFORGE.equip(player, def)
    if not player or not player:is_player() then
        core.log("error", "[itemforge3d] Invalid player object in IFORGE.equip")
        return false
    end

    local pname = player:get_player_name()
    local slot = def.slot or "generic"

    ENTITIES[pname] = ENTITIES[pname] or {}
    EQUIPED_ITEMS[pname] = EQUIPED_ITEMS[pname] or {}

    if ENTITIES[pname][slot] then
        IFORGE.unequip(player, slot)
    end

    local ent = get_entity_from_pool()
    if not ent then
        core.log("error", "[itemforge3d] Failed to get entity from pool for " .. pname)
        return false
    end

    if def.attach_model and def.attach_model.properties then
        ent:set_properties(def.attach_model.properties)
    end

    local a = def.attach_model and def.attach_model.attach or {}
    ent:set_attach(player,
        a.bone or "Arm_Right",
        a.position or {x=0,y=0,z=0},
        a.rotation or {x=0,y=0,z=0},
        a.forced_visible or false
    )

    ENTITIES[pname][slot] = ent
    EQUIPED_ITEMS[pname][slot] = def

    if def.on_equip then
        def.on_equip(player, ent, slot, def)
    end

    return true
end

function IFORGE.unequip(player, slot)
    if not player or not player:is_player() then
        core.log("error", "[itemforge3d] Invalid player object in IFORGE.unequip")
        return
    end

    local pname = player:get_player_name()
    
    local def = EQUIPED_ITEMS[pname] and EQUIPED_ITEMS[pname][slot]

    if ENTITIES[pname] and ENTITIES[pname][slot] then
        return_entity_to_pool(ENTITIES[pname][slot])
        ENTITIES[pname][slot] = nil
    end

    if EQUIPED_ITEMS[pname] then
        EQUIPED_ITEMS[pname][slot] = nil
    end

    if def and def.on_unequip then
        def.on_unequip(player, slot, def)
    end
end

local function cleanup_entity_pool()
    local max_pool_size = 10
    while #ENTITY_POOL > max_pool_size do
        local ent = table.remove(ENTITY_POOL)
        if ent then
            ent:remove()
        end
    end
end

local last_cleanup = 0
core.register_globalstep(function(dtime)
    last_cleanup = last_cleanup + dtime
    if last_cleanup > 300 then
        cleanup_entity_pool()
        last_cleanup = 0
    end
end

function IFORGE.get_equipped(player)
    if not player or not player:is_player() then return {} end
    local pname = player:get_player_name()
    return EQUIPED_ITEMS[pname] or {}
end

function IFORGE.list_equipped(player)
    if not player or not player:is_player() then return {} end
    local pname = player:get_player_name()
    local equipped = EQUIPED_ITEMS[pname] or {}
    local list = {}
    for slot, def in pairs(equipped) do
        table.insert(list, {slot = slot, item = def})
    end
    return list
end

function IFORGE.get_slot(player, slot)
    if not player or not player:is_player() then return nil end
    local pname = player:get_player_name()
    return EQUIPED_ITEMS[pname] and EQUIPED_ITEMS[pname][slot] or nil
end

function IFORGE.get_stats(player)
    if not player or not player:is_player() then return {} end
    local player_stats = {}

    local equipped_items = IFORGE.get_equipped(player)
    
    for stat_name in pairs(player_stats) do
        player_stats[stat_name] = 0
    end
    
    for slot, item_def in pairs(equipped_items) do
        if item_def.stats then
            for _, stat in ipairs(item_def.stats) do
                local stat_name = stat.type
                local stat_value = stat.value or 0
                if not player_stats[stat_name] then
                    player_stats[stat_name] = 0
                end
                if stat.modifier == "multiply" then
                    player_stats[stat_name] = player_stats[stat_name] * stat_value
                else
                    player_stats[stat_name] = player_stats[stat_name] + stat_value
                end
            end
        end
    end
    
    return player_stats
end

itemforge3d = ITEMFORGE
