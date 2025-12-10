## How to Register Items

Use the function:

```lua
itemforge3d.register(modname, name, def)
```

- `modname`: The mod's namespace (e.g. `"mymod"`).  
- `name`: The item’s unique name (e.g. `"sword"`).  
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
| `slot`            | string  | Equipment slot (`helmet`, `chest`, `legs`, `boots`, `shield`, or custom) |
| `attach_model`    | table   | Defines the 3D model to attach when equipped |
| `stats`           | table   | Arbitrary stats (armor, speed, jump, gravity, knockback, or custom) |

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

## Equipment Lifecycle

The API manages **equip/unequip** automatically:

- `itemforge3d.equip(player, itemname)` → equips an item into its slot.  
- If a slot is already occupied, the old item is unequipped first.  
- Entities are attached to player bones for visuals.  
- On player **death** or **leave**, all equipment is removed.  

### Callbacks
- `itemforge3d.on_equip(player, def, slot)` → called when an item is equipped.  
- `itemforge3d.on_unequip(player, def, slot)` → called when an item is unequipped.  

---

## Stats System

- Stats from all equipped items are **aggregated** automatically.  
- Use `itemforge3d.refresh_stats(player)` to recalculate.  
- Use `itemforge3d.get_stats(player)` to retrieve cached stats.  

> Stats are **not applied automatically** to gameplay — mods must use them (e.g. adjust physics, damage, etc.).

---

## API ARMOR

| Function                        | Description |
|---------------------------------|-------------|
| `itemforge3d.equip(player, itemname)` | Equip an item by name |
| `itemforge3d.get_stats(player)` | Get aggregated stats for a player |
| `itemforge3d.refresh_stats(player)` | Force refresh of cached stats |
| `itemforge3d.is_equipped(player, slot)` | Check if a slot is filled |
| `itemforge3d.get_equipped_item(player, slot)` | Get the item definition in a slot |
| `itemforge3d.unequip(player, slot)` | Unequip an item from a slot |


## Full Examples

### 1. Tool with 3D Model (shaped recipe shorthand)
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
    stats = { damage = 5 },
    auto_wield = true
})
```

---

### 2. Node with 3D Model (full craft passthrough)
```lua
itemforge3d.register("mymod", "magic_block", {
    type = "node",
    description = "Magic Block",
    inventory_image = "magic_block.png",
    craft = {
        output = "mymod:magic_block",
        recipe = {
            {"default:mese_crystal", "default:mese_crystal", "default:mese_crystal"},
            {"default:mese_crystal", "default:diamond", "default:mese_crystal"},
            {"default:mese_crystal", "default:mese_crystal", "default:mese_crystal"}
        }
    },
    attach_model = {
        properties = {
            mesh = "block.glb",
            textures = {"magic_block_texture.png"},
            visual_size = {x=0.5, y=0.5}
        },
        attach = {
            bone = "Arm_Right",
            position = {x=0, y=4, z=0},
            rotation = {x=0, y=0, z=0}
        }
    }
})
```

---

### 3. Craftitem with Dynamic Effect
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
    },
    auto_wield = true
})
```

---

### 4. Helmet with Armor Stat
```lua
itemforge3d.register("mymod", "iron_helmet", {
    type = "craftitem",
    description = "Iron Helmet",
    inventory_image = "iron_helmet.png",
    slot = "helmet",
    stats = { armor = 2 },
    attach_model = {
        properties = { mesh = "helmet.glb", textures = {"iron_helmet.png"} },
        attach = { bone = "Head", position = {x=0,y=0,z=0} }
    }
})
```
---

### 5. Boots with Speed Bonus
```lua
itemforge3d.register("mymod", "swift_boots", {
    type = "craftitem",
    description = "Swift Boots",
    inventory_image = "swift_boots.png",
    slot = "boots",
    stats = { speed = 0.3 },
    attach_model = {
        properties = { mesh = "boots.glb", textures = {"swift_boots.png"} },
        attach = { bone = "Legs", position = {x=0,y=0,z=0} }
    },
    auto_wield = true
})
```

---

### 6. Shield with Knockback Resistance
```lua
itemforge3d.register("mymod", "sturdy_shield", {
    type = "tool",
    description = "Sturdy Shield",
    inventory_image = "shield.png",
    slot = "shield",
    stats = { knockback = -0.5 },
    attach_model = {
        properties = { mesh = "shield.glb", textures = {"shield.png"} },
        attach = { bone = "Arm_Left", position = {x=0,y=5,z=0}, rotation = {x=0,y=0,z=0} }
    },
    auto_wield = true
})
```

---

### 7. Chestplate with Defense Bonus
```lua
itemforge3d.register("mymod", "iron_chestplate", {
    type = "craftitem",
    description = "Iron Chestplate",
    inventory_image = "iron_chestplate.png",
    slot = "chest",
    stats = { armor = 4 },
    attach_model = {
        properties = { mesh = "chestplate.glb", textures = {"iron_chestplate.png"} },
        attach = { bone = "Chest", position = {x=0,y=0,z=0} }
    }
})
```

---

### 8. Legs with Jump Boost
```lua
itemforge3d.register("mymod", "spring_leggings", {
    type = "craftitem",
    description = "Spring Leggings",
    inventory_image = "spring_leggings.png",
    slot = "legs",
    stats = { jump = 0.5 },
    attach_model = {
        properties = { mesh = "leggings.glb", textures = {"spring_leggings.png"} },
        attach = { bone = "Legs", position = {x=0,y=0,z=0} }
    },
    auto_wield = true
})
```

---

## Summary

- Use `itemforge3d.register(modname, name, def)` for **tools, nodes, or craftitems**.  
- Add `slot` to place items in equipment slots (`helmet`, `boots`, `shield`, `chest`, `legs`, etc.).  
- Add `attach_model` to show a **3D mesh** when equipped.  
- Use `update` for **animations, effects, or dynamic behavior**.  
- Recipes can be declared either with `recipe` (shaped shorthand) or `craft` (full passthrough).  
- Stats are arbitrary and aggregated by the API, but not applied automatically.  
- Equipment is cleaned up on **death** or **leaveplayer**.  
- Duplicate registrations log a warning.  
- The registered item will be named `modname:name`.  
- Optional callbacks `on_equip` and `on_unequip` let mods hook into lifecycle events.  
- Helper functions (`equip`, `get_stats`, `refresh_stats`, `is_equipped`, `get_equipped_item`, `unequip`) make it easy to manage equipment programmatically.  
- Items can opt‑in to **auto‑attach on wield** by setting `auto_wield = true`, but this is now handled externally (e.g. via a formspec mod).  


