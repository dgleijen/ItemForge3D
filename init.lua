local REGISTERED_ITEMS = {}
local EQUIPED_ITEMS = {}
local ENTITIES = {}
local ENTITY_POOL = {}
local ITEM_ID_COUNTER = 0 
local EQUIP_CALLBACKS = {}
local UNEQUIP_CALLBACKS = {}


local IFORGE = {}
IFORGE.slots = { "shield", "helmet", "chest", "legs", "boots" }

function IFORGE.register_on_equip(func)
    table.insert(EQUIP_CALLBACKS, func)
end

function IFORGE.register_on_unequip(func)
    table.insert(UNEQUIP_CALLBACKS, func)
end





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

local function cleanup_entity_pool()
    local max_pool_size = 10
    if #ENTITY_POOL > max_pool_size then
        local excess = #ENTITY_POOL - max_pool_size
        for i = 1, excess do
            local ent = table.remove(ENTITY_POOL)
            if ent then
                ent:remove()
            end
        end
    end
end

local function return_entity_to_pool(entity)
    if entity then
        entity:set_properties({
            visual = "mesh",
            mesh = "itemforge3d_blank.glb",
            textures = {"blank.png"},
            visual_size = {x=1, y=1},
            pointable = false,
            physical = false,
            collide_with_objects = false,
        })
        
        entity:set_detach()
        entity:set_properties({visual_size = {x=0, y=0}})
        table.insert(ENTITY_POOL, entity)
        cleanup_entity_pool()
    end
end

function IFORGE.get_slot(player, slot)
    if not player or not player:is_player() then return nil end
    local pname = player:get_player_name()
    return EQUIPED_ITEMS[pname] and EQUIPED_ITEMS[pname][slot] or nil
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
        mesh = "itemforge3d_blank.glb",
        textures = {"blank.png"},
        visual_size = {x=1, y=1},
        pointable = false,
        physical = false,
        collide_with_objects = false,
    },
})

function IFORGE.unequip(player, slot)
    if not player or not player:is_player() then
        return false
    end

    local pname = player:get_player_name()

    if slot and EQUIPED_ITEMS[pname] and EQUIPED_ITEMS[pname][slot] then
        local def = EQUIPED_ITEMS[pname][slot]

        if ENTITIES[pname] and ENTITIES[pname][slot] then
            return_entity_to_pool(ENTITIES[pname][slot])
            ENTITIES[pname][slot] = nil
        end

        EQUIPED_ITEMS[pname][slot] = nil

        if def and def.stack then
            local inv = player:get_inventory()
            if inv then
                inv:add_item("main", def.stack)
            end
        end

        if def.def and def.def.on_unequip then
            def.def.on_unequip(player, def.stack)
        end

        for _, cb in ipairs(UNEQUIP_CALLBACKS) do
            cb(player, def.def, def.stack)
        end

        return true
    end

    if not slot and EQUIPED_ITEMS[pname] and EQUIPED_ITEMS[pname].generic then
        local list = EQUIPED_ITEMS[pname].generic
        local entry = table.remove(list)

        if entry and entry.entity then
            return_entity_to_pool(entry.entity)
        end

        if entry and entry.stack then
            local inv = player:get_inventory()
            if inv then
                inv:add_item("main", entry.stack)
            end
        end

        if entry and entry.def and entry.def.on_unequip then
            entry.def.on_unequip(player, entry.stack)
        end

        for _, cb in ipairs(UNEQUIP_CALLBACKS) do
            cb(player, entry.def, entry.stack)
        end

        return true
    end

    return false
end


function IFORGE.equip(player, itemstack)
    if not player or not player:is_player() then
        core.log("error", "[itemforge3d] Invalid player object in IFORGE.equip")
        return false
    end

    local pname = player:get_player_name()
    local itemname = itemstack:get_name()
    local def = REGISTERED_ITEMS[itemname]
    if not def then
        core.log("error", "[itemforge3d] Item not registered: " .. itemname)
        return false
    end

    ENTITIES[pname] = ENTITIES[pname] or {}
    EQUIPED_ITEMS[pname] = EQUIPED_ITEMS[pname] or {}

    local slot = def.slot

    if slot and IFORGE.get_slot(player, slot) then
        return false 
    end

    local ent = get_entity_from_pool()
    if not ent then return false end

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

    if slot then
        ENTITIES[pname][slot] = ent
        EQUIPED_ITEMS[pname][slot] = {
            def = def,
            stack = itemstack:peek_item()
        }
    else
        EQUIPED_ITEMS[pname].generic = EQUIPED_ITEMS[pname].generic or {}
        table.insert(EQUIPED_ITEMS[pname].generic, {
            def = def,
            stack = itemstack:peek_item(),
            entity = ent
        })
    end

    itemstack:take_item()
    if def.on_equip then
        def.on_equip(player, itemstack)
    end
    for _, cb in ipairs(EQUIP_CALLBACKS) do
        cb(player, def, itemstack)
    end
    return true
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

function IFORGE.get_stats(player)
    if not player or not player:is_player() then return {} end
    local player_stats = {}
    local equipped_items = IFORGE.get_equipped(player)

    for slot, item_def in pairs(equipped_items) do
        if item_def.def.stats then
            for _, stat in ipairs(item_def.def.stats) do
                local stat_name = stat.type
                local stat_value = stat.value or 0

                if stat_name == "durability" and item_def.stack then
                    -- calculate durability percentage from wear
                    local wear = item_def.stack:get_wear()
                    stat_value = math.max(0, 100 - (wear / 65535) * 100)
                end

                if not player_stats[stat_name] then
                    player_stats[stat_name] = 0
                end

                if stat.modifier == "multiply" then
                    player_stats[stat_name] = player_stats[stat_name] * stat_value
                elseif stat.modifier == "set" then
                    player_stats[stat_name] = stat_value
                else
                    player_stats[stat_name] = player_stats[stat_name] + stat_value
                end
            end
        end
    end

    return player_stats
end

minetest.register_chatcommand("equip", {
    params = "<itemname>",
    description = "Equip an item by name",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end

        local inv = player:get_inventory()
        local stack = inv:remove_item("main", param)
        if stack:is_empty() then
            return false, "You don't have " .. param
        end

        local ok = IFORGE.equip(player, stack)
        if ok then
            return true, "Equipped " .. param
        else
            inv:add_item("main", stack) 
            return false, "Could not equip " .. param
        end
    end
})

core.register_chatcommand("unequip", {
    params = "<slot>",
    description = "Unequip an item from a slot",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end

        local ok = IFORGE.unequip(player, param)
        if ok then
            return true, "Unequipped from slot " .. param
        else
            return false, "No item equipped in slot " .. param
        end
    end
})

itemforge3d = IFORGE

-- Add mod storage
local storage = core.get_mod_storage()

-- Helper function to serialize only slot-specific equipped items
local function serialize_slot_items(equipped_data)
    local serialized = {}
    
    -- Only save items in specific slots
    local slots = {"helmet", "chest", "legs", "boots", "shield"}
    for _, slot in ipairs(slots) do
        local item_data = equipped_data[slot]
        if item_data and type(item_data) == "table" and item_data.def then
            serialized[slot] = {
                item_name = item_data.def.name,
                stack = item_data.stack and item_data.stack:to_string() or nil
            }
        end
    end
    
    return serialized
end

-- Helper function to deserialize slot-specific items (without adding to inventory)
local function deserialize_slot_items(player, serialized_data)
    if not serialized_data then return end
    
    -- Restore items in each slot directly
    for slot, item_data in pairs(serialized_data) do
        if item_data.item_name then
            -- Create item stack and equip directly without taking from inventory
            local stack = ItemStack(item_data.stack) or ItemStack(item_data.item_name)
            local itemname = stack:get_name()
            local def = REGISTERED_ITEMS[itemname]
            
            if def and def.slot == slot then
                -- Manually equip without using IFORGE.equip (which takes from inventory)
                local pname = player:get_player_name()
                ENTITIES[pname] = ENTITIES[pname] or {}
                EQUIPED_ITEMS[pname] = EQUIPED_ITEMS[pname] or {}
                
                local ent = get_entity_from_pool()
                if ent and def.attach_model and def.attach_model.properties then
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
                EQUIPED_ITEMS[pname][slot] = {
                    def = def,
                    stack = stack:peek_item()
                }
                
                if def.on_equip then
                    def.on_equip(player, stack)
                end
                for _, cb in ipairs(EQUIP_CALLBACKS) do
                    cb(player, def, stack)
                end
            end
        end
    end
end

local function save_player_slot_items(player)
    local pname = player:get_player_name()
    if EQUIPED_ITEMS[pname] then
        local serialized = serialize_slot_items(EQUIPED_ITEMS[pname])
        storage:set_string("player_" .. pname .. "_slot_equipment", core.serialize(serialized))
        
    else
        storage:set_string("player_" .. pname .. "_slot_equipment", "")
    end
end

local function restore_player_slot_items(player)
    local pname = player:get_player_name()
    local saved_data = storage:get_string("player_" .. pname .. "_slot_equipment")
    if saved_data and saved_data ~= "" then
        local serialized = core.deserialize(saved_data)
        if serialized then
            deserialize_slot_items(player, serialized)
        end
        storage:set_string("player_" .. pname .. "_slot_equipment", "")
    end
end

core.register_on_leaveplayer(function(player, timed_out)
    save_player_slot_items(player)
end)


core.register_on_joinplayer(function(player)
    core.after(1, function()
        restore_player_slot_items(player)
    end)
end)

