local REGISTERED_ITEMS = {}
local ENTITIES = {}
local IFORGE = {}

function IFORGE.register(modname, item_name, register_def)
    local full_name = modname .. ":" .. item_name

    if REGISTERED_ITEMS[full_name] then
        return false
    end

    if register_def.type == "tool" then
        core.register_tool(full_name, register_def)
    elseif register_def.type == "node" then
        core.register_node(full_name, register_def)
    elseif register_def.type == "craftitem" then
        core.register_craftitem(full_name, register_def)
    else
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

function IFORGE.attach_entity(player, itemstack, opts)
    opts = opts or {}
    if not player or not itemstack or itemstack:is_empty() then return false end

    local item_name = itemstack:get_name()
    local def = REGISTERED_ITEMS[item_name]
    if not def then return false end

    local ent = core.add_entity({x=0,y=0,z=0}, "itemforge3d:wield_entity")
    if not ent then return false end

    if def.properties then
        ent:set_properties(def.properties)
    end
    
    local attach = def.attach or {}
    ent:set_attach(player,
        attach.bone or "",
        attach.pos or {x=0,y=0,z=0},
        attach.rot or {x=0,y=0,z=0},
        attach.force_visible or false
    )

    local name = player:get_player_name()
    ENTITIES[name] = ENTITIES[name] or {}
    table.insert(ENTITIES[name], {
        entity    = ent,
        item_name = item_name,
        stack     = ItemStack(itemstack), -- full copy of stack with metadata
        id        = opts.id,              -- optional slot/identifier
    })

    if def.on_attach then def.on_attach(player, ent) end
    return true
end

function IFORGE.detach_entity(player, item_name)
    local name = player:get_player_name()
    local entries = ENTITIES[name]
    if not entries then return false end

    for i, entry in ipairs(entries) do
        if not item_name or entry.item_name == item_name then
            local ent = entry.entity
            ent:set_detach()
            ent:remove()

            local def = REGISTERED_ITEMS[entry.item_name]
            if def and def.on_detach then
                def.on_detach(player, ent)
            end

            table.remove(entries, i)
            if #entries == 0 then
                ENTITIES[name] = nil
            end
            return true
        end
    end
    return false
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

function IFORGE.get_attached_items(player)
    local name = player:get_player_name()
    local entries = ENTITIES[name]
    if not entries then return {} end

    local list = {}
    for _, entry in ipairs(entries) do
        table.insert(list, entry.item_name)
    end
    return list
end

function IFORGE.get_attached_entries(player)
    local name = player:get_player_name()
    local entries = ENTITIES[name]
    if not entries then return {} end

    local out = {}
    for i, entry in ipairs(entries) do
        out[i] = {
            item_name = entry.item_name,
            id        = entry.id,
            stack     = ItemStack(entry.stack), -- copy to avoid mutation
        }
    end
    return out
end

function IFORGE.reload_attached_items(player, item_list)
    if not item_list then return false end
    for _, entry in ipairs(item_list) do
        IFORGE.attach_entity(player, entry.stack, { id = entry.id })
        local def = REGISTERED_ITEMS[entry.item_name]
        if def and def.on_reload then
            local name = player:get_player_name()
            local entries = ENTITIES[name]
            local last = entries and entries[#entries]
            if last then def.on_reload(player, last.entity, last) end
        end
    end
    return true
end

itemforge3d = IFORGE