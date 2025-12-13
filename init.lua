local REGISTERED_ITEMS = {}
local ENTITIES = {}
local ENTITY_POOL = {}
local IFORGE = {}

local function get_entity_from_pool()
    local ent = table.remove(ENTITY_POOL, 1) -- FIFO reuse
    if not ent then
        ent = core.add_entity({x=0,y=0,z=0}, "itemforge3d:wield_entity")
    end
    return ent
end

local function cleanup_entity_pool()
    local max_pool_size = IFORGE.max_pool_size or 10
    if #ENTITY_POOL > max_pool_size then
        local excess = #ENTITY_POOL - max_pool_size
        for i = 1, excess do
            local ent = table.remove(ENTITY_POOL)
            if ent then ent:remove() end
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
        entity:get_luaentity().item_meta = nil -- clear metadata
        table.insert(ENTITY_POOL, entity)
        cleanup_entity_pool()
    end
end

function IFORGE.register(modname, item_name, register_def)
    local full_name = modname .. ":" .. item_name

    if REGISTERED_ITEMS[full_name] then
        core.log("error", "[itemforge3d] Duplicate registration for " .. full_name)
        return false
    end

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

function IFORGE.attach_entity(player, item_name)
    local def = REGISTERED_ITEMS[item_name]
    if not def then return false end

    local ent = get_entity_from_pool()
    if not ent or not player then return false end

    ent:set_properties({
        mesh = def.mesh or "itemforge3d_blank.glb",
        textures = def.textures or {"blank.png"},
        visual_size = def.visual_size or {x=1,y=1},
    })

    local attach = def.attach or {}
    ent:set_attach(player,
        attach.bone or "",
        attach.pos or {x=0,y=0,z=0},
        attach.rot or {x=0,y=0,z=0}
    )

    ENTITIES[player:get_player_name()] = {entity = ent, item_name = item_name}

    if def.on_attach then def.on_attach(player, ent) end
    return true
end

function IFORGE.detach_entity(player)
    local name = player:get_player_name()
    local entry = ENTITIES[name]
    if entry and entry.entity then
        local ent = entry.entity
        ent:set_detach()
        return_entity_to_pool(ent)
        ENTITIES[name] = nil

        local def = REGISTERED_ITEMS[entry.item_name]
        if def and def.on_detach then
            def.on_detach(player, ent)
        end
        return true
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