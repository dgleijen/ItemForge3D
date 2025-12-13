# ItemForge3D API (Updated)

## How to Register Items

Use the function:

```lua
itemforge3d.register(modname, name, def)
```

- `modname`: The mod's namespace (e.g. `"mymod"`).  
- `name`: The item's unique name (e.g. `"sword"`).  
- `def`: A table with item definition and optional 3D model info.  

> The final registered item will be named as `modname:name`, for example: `"mymod:sword"`.

---

## Supported Item Types

You can register **three kinds of items**:

1. **Tools** → `type = "tool"`  
   - Pickaxes, swords, axes, shields, etc.  
   - Registered with `core.register_tool`.

2. **Nodes** → `type = "node"`  
   - Blocks you can place in the world.  
   - Registered with `core.register_node`.

3. **Craftitems** → `type = "craftitem"`  
   - Misc items (food, gems, scrolls, lanterns).  
   - Registered with `core.register_craftitem`.

---

## Definition Fields

Here’s what you can put inside `def`:

| Field             | Type    | Description |
|-------------------|---------|-------------|
| `type`            | string  | `"tool"`, `"node"`, or `"craftitem"` |
| `description`     | string  | Text shown in inventory |
| `inventory_image` | string  | Icon texture for inventory |
| `recipe`          | table   | Shaped craft recipe (shorthand) |
| `craft`           | table   | Full craft definition (shapeless, cooking, fuel, etc.) |
| `attach`    | table   | Defines the 3D model to attach when used |
| `on_attach`       | function| Called when entity is attached |
| `on_detach`       | function| Called when entity is detached |

---

## attach_model Fields

Inside `attach_model`, you can define:

| Field        | Type     | Description |
|--------------|----------|-------------|
| `properties` | table    | Entity properties (mesh, textures, size) |
| `attach`     | table    | Where/how to attach to player |
| `update`     | function | Optional per-frame logic (animations, effects) |

### Example `properties`
```lua
properties = {
    mesh = "sword.glb",
    textures = {"sword_texture.png"},
    visual_size = {x=1, y=1}
}
```

### Example `attach`
```lua
attach = {
    bone = "Arm_Right",
    position = {x=0, y=5, z=0},
    rotation = {x=0, y=90, z=0},
    forced_visible = false
}
```

### Example `update`
```lua
update = function(ent, player)
    if player:get_player_control().dig then
        ent:set_animation({x=0,y=20}, 15, 0) -- swing animation
    end
end
```

---

## Attach/Detach Lifecycle

The API manages **attach/detach** automatically:

- `itemforge3d.attach_entity(player, item_name)` → attaches the item’s 3D model to the player.  
- `itemforge3d.detach_entity(player)` → detaches the currently attached entity from the player.  
- Entities are pooled and recycled for performance.  
- Optional callbacks `on_attach` and `on_detach` are triggered when visuals are shown/hidden.

---

## Stats System

- Items can define arbitrary `stats` (armor, speed, jump, gravity, knockback, or custom).  
- Stats are stored in the item definition.  
- Aggregation helpers can be added later — current code does not auto‑apply stats.

---

## API Reference

| Function                          | Description |
|-----------------------------------|-------------|
| `itemforge3d.register(modname, name, def)` | Register a tool, node, or craftitem |
| `itemforge3d.attach_entity(player, item_name)` | Attach an item’s 3D model to a player |
| `itemforge3d.detach_entity(player)` | Detach the currently attached entity from a player |

---

## Full Examples

### 1. Tool with 3D Model
```lua
itemforge3d.register("mymod", "sword", {
    type = "tool",
    description = "Forged Sword",
    inventory_image = "sword.png",
    recipe = {
        {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
        {"", "default:stick", ""},
        {"", "default:stick", ""}
    },
    attach_model = {
        properties = {
            mesh = "sword.glb",
            textures = {"sword_texture.png"},
            visual_size = {x=1, y=1}
        },
        attach = {
            bone = "Arm_Right",
            position = {x=0, y=5, z=0},
            rotation = {x=0, y=90, z=0}
        }
    },
    on_attach = function(player, ent)
        core.chat_send_player(player:get_player_name(), "Sword attached!")
    end,
    on_detach = function(player, ent)
        core.chat_send_player(player:get_player_name(), "Sword detached!")
    end,
})
```

### 2. Craftitem with Dynamic Effect
```lua
itemforge3d.register("mymod", "lantern", {
    type = "craftitem",
    description = "Lantern",
    inventory_image = "lantern.png",
    recipe = {
        {"default:steel_ingot", "default:torch", "default:steel_ingot"},
        {"", "default:glass", ""}
    },
    attach_model = {
        properties = {
            mesh = "lantern.glb",
            textures = {"lantern_texture.png"},
            visual_size = {x=0.7, y=0.7}
        },
        attach = {
            bone = "Arm_Right",
            position = {x=0, y=6, z=0},
            rotation = {x=0, y=0, z=0}
        },
        update = function(ent, player)
            if player:get_player_control().sneak then
                core.add_particlespawner({
                    amount = 5,
                    time = 0.1,
                    minpos = player:get_pos(),
                    maxpos = player:get_pos(),
                    texture = "light_particle.png"
                })
            end
        end
    }
})
```

---

## Summary

- Use `itemforge3d.register(modname, name, def)` for **tools, nodes, or craftitems**.  
- Add `attach_model` to show a **3D mesh** when attached.  
- Use `update` for **animations, effects, or dynamic behavior**.  
- Recipes can be declared either with `recipe` (shaped shorthand) or `craft` (full passthrough).  
- Stats are arbitrary and stored in definitions, but not auto‑applied.  
- Entities are pooled for performance and recycled on detach.  
- Optional callbacks `on_attach` and `on_detach` let mods hook into lifecycle events.  
- Helper functions (`attach_entity`, `detach_entity`) make it easy to manage visuals programmatically.  
