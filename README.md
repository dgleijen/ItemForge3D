# ItemForge3D

ItemForge3D provides a **safe, extensible API** for registering items and attaching wield entities to players. It supports lifecycle management, duplicate protection, and modder‑friendly callbacks.

---

## Register Items
```lua
itemforge3d.register(modname, name, def)
```
Registers a tool, node, or craftitem under the name `modname:name`.

### Definition Fields
- `type`: `"tool"`, `"node"`, or `"craftitem"`
- `description`: Inventory description
- `inventory_image`: Icon texture
- `craft`: Full craft definition (shapeless, cooking, fuel, etc.)
- `properties`: Entity properties (mesh, textures, size)
- `attach`: Attach position/rotation/bone
- `on_attach`: Callback when entity is attached
- `on_reload`: Callback when entity is reloaded after persistence

---

## Attach/Detach
- `itemforge3d.attach_entity(player, itemstack, opts)` → attach an item’s wield entity to a player  
  - `opts.id` → optional identifier for duplicate protection and slot management
- `itemforge3d.detach_entity(player, id)` → detach a specific item’s wield entity by identifier
- `itemforge3d.detach_all(player)` → detach all wield entities from a player

Multiple items can be attached per player, each tracked by `id`.

---

## Attachment Management
- `itemforge3d.get_entities(player)` → returns a **safe copy** of all attached entries `{entity, item_name, stack, id}`
- `itemforge3d.get_attached_items(player)` → returns a list of item names currently attached
- `itemforge3d.get_attached_entries(player)` → returns detailed entries `{item_name, id, stack}`
- `itemforge3d.reload_attached_items(player, item_list)` → re‑attaches items from a saved list

---

## API Reference

| Function | Description |
|----------|-------------|
| `itemforge3d.register(modname, name, def)` | Register a tool, node, or craftitem |
| `itemforge3d.attach_entity(player, itemstack, opts)` | Attach an item’s wield entity to a player |
| `itemforge3d.detach_entity(player, id)` | Detach a specific item’s wield entity by identifier |
| `itemforge3d.detach_all(player)` | Detach all wield entities from a player |
| `itemforge3d.get_entities(player)` | Get a safe copy of attached entities |
| `itemforge3d.get_attached_items(player)` | Get a list of attached item names |
| `itemforge3d.get_attached_entries(player)` | Get detailed attached entries (name, id, stack) |
| `itemforge3d.reload_attached_items(player, item_list)` | Reattach items from a saved list |

---

## Examples

### Tool with Custom Mesh
```lua
itemforge3d.register("mymod", "sword", {
    type = "tool",
    description = "Forged Sword",
    inventory_image = "sword.png",
    craft = {
        output = "mymod:sword",
        recipe = {
            {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
            {"", "default:stick", ""},
            {"", "default:stick", ""}
        }
    },
    properties = {
        mesh = "sword.glb",
        textures = {"sword_texture.png"},
        visual_size = {x=1, y=1}
    },
    attach = {
        bone = "Arm_Right",
        pos = {x=0, y=5, z=0},
        rot = {x=0, y=90, z=0}
    },
    on_attach = function(player, ent)
        core.chat_send_player(player:get_player_name(), "Sword attached!")
    end,
    on_reload = function(player, ent, entry)
        core.chat_send_player(player:get_player_name(), "Sword reloaded!")
    end,
})
```

### Craftitem With Default Image
```lua
itemforge3d.register("mymod", "pickaxe", {
    type = "tool",
    description = "Pickaxe",
    inventory_image = "pickaxe.png",
})
```

### Craftitem Without Any Wield Entity
```lua
itemforge3d.register("mymod", "potion", {
    type = "craftitem",
    description = "Healing Potion",
    inventory_image = "potion.png",
    craft = {
        output = "mymod:potion",
        recipe = {
            {"default:glass_bottle", "default:apple", "default:glass_bottle"},
        }
    },
})
```

### Saving and Reloading Attachments
```lua
-- Save current attachments
local saved = itemforge3d.get_attached_entries(player)

-- Detach everything
itemforge3d.detach_all(player)

-- Later, reload them
itemforge3d.reload_attached_items(player, saved)
```

---

## Summary
- Attach visuals with `itemforge3d.attach_entity`.  
- Detach visuals with `itemforge3d.detach_entity` or `detach_all`.  
- Multiple items can be attached per player, tracked by `id`.  
- Use `get_attached_items` or `get_attached_entries` plus `reload_attached_items` to snapshot and restore attachments.  
- Optional callbacks (`on_attach`, `on_reload`) let you hook into lifecycle events.  
- Use `craft` for registering recipes (shaped, shapeless, cooking, fuel, etc.).  
