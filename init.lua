local EXTRAS = {}   -- only ItemForge3D-specific metadata
local ENTITIES = {}
local IFORGE = {}

-- Register items with Minetest, store only extras
function IFORGE.register(modname, item_name, def)
    local full_name = modname .. ":" .. item_name

    if EXTRAS[full_name] then
        return false
    end

    if def.type == "tool" then
        core.register_tool(full_name, def)
    elseif def.type == "node" then
        core.register_node(full_name, def)
    elseif def.type == "craftitem" then
        core.register_craftitem(full_name, def)
    else
        return false
    end

    if def.craft then
        core.register_craft(def.craft)
    end

    -- store only ItemForge3D-specific fields
    EXTRAS[full_name] = {
        properties = def.properties,
        attach     = def.attach,
        on_attach  = def.on_attach,
        on_reload  = def.on_reload,
    }

    return true
end

-- Accessor for extras
function IFORGE.get_extras(full_name)
    return EXTRAS[full_name] and table.copy(EXTRAS[full_name]) or nil
end

-- Accessor for all registered item names with extras
function IFORGE.get_registered_item_names()
    local names = {}
    for name, _ in pairs(EXTRAS) do
        table.insert(names, name)
    end
    return table.copy(names)
end

-- Accessor for all extras
function IFORGE.get_registered_items()
    local items = {}
    for name, extras in pairs(EXTRAS) do
        table.insert(items, { name = name, def = table.copy(extras) })
    end
    return table.copy(items)
end

-- Filter extras by type (using Minetest’s registry for type info)
function IFORGE.get_registered_items_by_type(item_type)
    local items = {}
    for name, extras in pairs(EXTRAS) do
        local base = minetest.registered_items[name]
        if base and base.type == item_type then
            table.insert(items, { name = name, def = table.copy(extras) })
        end
    end
    return table.copy(items)
end

-- Attach entity
function IFORGE.attach_entity(player, itemstack, opts)
    opts = opts or {}
    if not player or not itemstack or itemstack:is_empty() then return false end

    local item_name = itemstack:get_name()
    local extras = EXTRAS[item_name]
    if not extras then return false end

    local ent = core.add_entity(player:get_pos(), "itemforge3d:wield_entity")
    if not ent then return false end

    if extras.properties then
        ent:set_properties(extras.properties)
    end

    local attach = extras.attach or {}
    ent:set_attach(player,
        attach.bone or "",
        attach.pos or {x=0,y=0,z=0},
        attach.rot or {x=0,y=0,z=0},
        attach.force_visible or false
    )

    local name = player:get_player_name()
    ENTITIES[name] = ENTITIES[name] or {}

    if opts.id then
        for i, e in ipairs(ENTITIES[name]) do
            if e.id == opts.id then
                e.entity:remove()
                table.remove(ENTITIES[name], i)
                break
            end
        end
    end

    table.insert(ENTITIES[name], {
        entity    = ent,
        item_name = item_name,
        stack     = ItemStack(itemstack),
        id        = opts.id,
    })

    if extras.on_attach then extras.on_attach(player, ent) end
    return true
end

-- Detach helpers
function IFORGE.detach_entity(player, id)
    local name = player:get_player_name()
    local list = ENTITIES[name]
    if not list then return false end

    for i, e in ipairs(list) do
        if e.id == id then
            e.entity:remove()
            table.remove(list, i)
            return true
        end
    end
    return false
end

function IFORGE.detach_all(player)
    local name = player:get_player_name()
    local list = ENTITIES[name]
    if not list then return false end

    for _, e in ipairs(list) do
        e.entity:remove()
    end
    ENTITIES[name] = {}
    return true
end

-- Safe entity inspection
function IFORGE.get_entities(player)
    local list = ENTITIES[player:get_player_name()] or {}
    local copy = {}
    for i, e in ipairs(list) do
        copy[i] = {
            entity    = e.entity,
            item_name = e.item_name,
            stack     = ItemStack(e.stack),
            id        = e.id,
        }
    end
    return copy
end

function IFORGE.get_attached_items(player)
    local entries = IFORGE.get_entities(player)
    local list = {}
    for _, entry in ipairs(entries) do
        table.insert(list, entry.item_name)
    end
    return list
end

function IFORGE.get_attached_entries(player)
    local entries = IFORGE.get_entities(player)
    local out = {}
    for i, entry in ipairs(entries) do
        out[i] = {
            item_name = entry.item_name,
            id        = entry.id,
            stack     = ItemStack(entry.stack),
        }
    end
    return out
end

function IFORGE.reload_attached_items(player, item_list)
    item_list = item_list or IFORGE.get_attached_entries(player)
    if not item_list or #item_list == 0 then return false end

    for _, entry in ipairs(item_list) do
        IFORGE.attach_entity(player, entry.stack, { id = entry.id })

        local extras = EXTRAS[entry.item_name]
        if extras and extras.on_reload then
            local entries = ENTITIES[player:get_player_name()]
            local attached = entries[#entries]
            if attached then extras.on_reload(player, attached.entity, attached) end
        end
    end
    return true
end

-- Base wield entity
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

itemforge3d = IFORGE