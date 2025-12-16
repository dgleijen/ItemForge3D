local EXTRAS = {}   -- only ItemForge3D-specific metadata
local ENTITIES = {}
local IFORGE = {}

-- Simple deepcopy utility
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- helper: deep merge of two property tables
local function merge_properties(base, override)
    local props = deepcopy(base)
    if override then
        for k, v in pairs(override) do
            if type(v) == "table" and type(props[k]) == "table" then
                props[k] = merge_properties(props[k], v)
            else
                props[k] = deepcopy(v)
            end
        end
    end
    return props
end

-- Register items with Minetest, store only extras
function IFORGE.register(modname, item_name, def)
    local full_name = modname .. ":" .. item_name

    if EXTRAS[full_name] then
        minetest.log("warning", "[ItemForge3D] Duplicate registration attempt for " .. full_name)
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
        properties = deepcopy(def.properties),
        attach     = deepcopy(def.attach),
        on_attach  = def.on_attach,
        on_reload  = def.on_reload,
        wieldview  = def.wieldview,
    }

    return true
end

-- Accessor for extras
function IFORGE.get_extras(full_name)
    local extras = EXTRAS[full_name]
    return extras and deepcopy(extras) or nil
end

function IFORGE.update_extras(full_name, fields)
    local extras = EXTRAS[full_name]
    if not extras then return false end
    for k, v in pairs(fields) do
        if type(v) == "table" and type(extras[k]) == "table" then
            extras[k] = merge_properties(extras[k], v)
        else
            extras[k] = deepcopy(v)
        end
    end
    return true
end

function IFORGE.get_registered_item_names()
    local names = {}
    for name, _ in pairs(EXTRAS) do
        table.insert(names, name)
    end
    return table.copy(names)
end

function IFORGE.get_registered_items()
    local items = {}
    for name, extras in pairs(EXTRAS) do
        table.insert(items, { name = name, def = deepcopy(extras) })
    end
    return table.copy(items)
end

function IFORGE.get_registered_items_by_type(item_type)
    local items = {}
    for name, extras in pairs(EXTRAS) do
        local base = minetest.registered_items[name]
        if base and base.type == item_type then
            table.insert(items, { name = name, def = deepcopy(extras) })
        end
    end
    return table.copy(items)
end

function IFORGE.attach_entity(player, itemstack, opts)
    opts = opts or {}
    if not player or not itemstack or itemstack:is_empty() then return false end

    local item_name = itemstack:get_name()
    local extras = EXTRAS[item_name]
    if not extras then return false end

    local ent
    if extras.wieldview == "wielditem" then
        ent = core.add_entity(player:get_pos(), "itemforge3d:wield_entity_item")
    else
        ent = core.add_entity(player:get_pos(), "itemforge3d:wield_entity")
    end
    if not ent then return false end

    local current = ent:get_properties()
    local props = merge_properties(current, extras.properties)

    if extras.wieldview == "wielditem" then
        props.visual = "wielditem"
        props.wield_item = item_name
    end

    ent:set_properties(props)

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
    ENTITIES[name] = nil
    return true
end

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

function IFORGE.reapply_attachment(player, entry)
    local extras = EXTRAS[entry.item_name]
    if not extras then return false end

    local attach = extras.attach or {}
    entry.entity:set_attach(player,
        attach.bone or "",
        attach.pos or {x=0,y=0,z=0},
        attach.rot or {x=0,y=0,z=0},
        attach.force_visible or false
    )
    return true
end

function IFORGE.reload_attached_items(player, item_list)
    item_list = item_list or IFORGE.get_attached_entries(player)
    if not item_list or #item_list == 0 then return false end

    for _, entry in ipairs(item_list) do
        local extras = EXTRAS[entry.item_name]
        local entries = ENTITIES[player:get_player_name()] or {}

        local attached
        for _, e in ipairs(entries) do
            if e.id == entry.id then
                attached = e
                break
            end
        end

        if attached then
            IFORGE.reapply_attachment(player, attached)
            if extras and extras.on_reload then
                extras.on_reload(player, attached.entity, attached)
            end
        else
            IFORGE.attach_entity(player, entry.stack, { id = entry.id })
        end
    end
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

core.register_entity("itemforge3d:wield_entity_item", {
    initial_properties = {
        visual = "wielditem",
        wield_item = "",
        visual_size = {x=1, y=1},
        pointable = false,
        physical = false,
        collide_with_objects = false,
    },
})

itemforge3d = IFORGE