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

function IFORGE.attach_entity(player, item_name)
    local def = REGISTERED_ITEMS[item_name]
    if not def then return false end

    local ent = core.add_entity({x=0,y=0,z=0}, "itemforge3d:wield_entity")
    if not ent or not player then return false end

    if def.properties then
        ent:set_properties(def.properties)
    end

    local attach = def.attach or {}
    ent:set_attach(player,
        attach.bone or "",
        attach.pos or {x=0,y=0,z=0},
        attach.rot or {x=0,y=0,z=0}
    )

    local name = player:get_player_name()
    ENTITIES[name] = ENTITIES[name] or {}
    table.insert(ENTITIES[name], {entity = ent, item_name = item_name})

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
        mesh = "itemforge3d_blank.glb",
        textures = {"blank.png"},
        visual_size = {x=1, y=1},
        pointable = false,
        physical = false,
        collide_with_objects = false,
    },
})

itemforge3d = IFORGE