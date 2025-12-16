# ItemForge3D

## Register Items
```lua
itemforge3d.register(modname, name, def)
```
Registers a tool, node, or craftitem under the name `modname:name`.

### Definition Fields
- **Standard fields** (`type`, `description`, `inventory_image`, etc.) → handled by Minetest’s own registry (`minetest.registered_items`).
- **ItemForge3D extras**:
  - `properties`: Entity properties (mesh, textures, size)
  - `attach`: Attach position/rotation/bone
  - `on_attach`: Callback when entity is attached
  - `on_reload`: Callback when entity is reloaded after persistence
  - `wieldview`: `"mesh"` or `"wielditem"` visual mode
- **Crafting**:
  - `craft`: Full craft definition (shapeless, cooking, fuel, etc.)

> ⚠️ Duplicate protection: If you try to register the same item twice, ItemForge3D logs a warning and ignores the second attempt.

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
- `itemforge3d.reload_attached_items(player, item_list)` → re‑attaches items from a saved list (calls `on_reload` if defined)
- `itemforge3d.get_extras(item_name)` → returns the ItemForge3D‑specific metadata for a registered item

---

## API Reference

| Function | Description |
|----------|-------------|
| `itemforge3d.register(modname, name, def)` | Register a tool, node, or craftitem with extras |
| `itemforge3d.attach_entity(player, itemstack, opts)` | Attach an item’s wield entity to a player |
| `itemforge3d.detach_entity(player, id)` | Detach a specific item’s wield entity by identifier |
| `itemforge3d.detach_all(player)` | Detach all wield entities from a player |
| `itemforge3d.get_entities(player)` | Get a safe copy of attached entities |
| `itemforge3d.get_attached_items(player)` | Get a list of attached item names |
| `itemforge3d.get_attached_entries(player)` | Get detailed attached entries (name, id, stack) |
| `itemforge3d.reload_attached_items(player, item_list)` | Reattach items from a saved list |
| `itemforge3d.get_extras(item_name)` | Get ItemForge3D‑specific metadata for an item |

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
    wieldview = "mesh",
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
        minetest.chat_send_player(player:get_player_name(), "Sword attached!")
    end,
    on_reload = function(player, ent, entry)
        minetest.chat_send_player(player:get_player_name(), "Sword reloaded!")
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

### Wielditem Visual Example
```lua
itemforge3d.register("mymod", "apple", {
    type = "craftitem",
    description = "Shiny Apple",
    inventory_image = "apple.png",
    wieldview = "wielditem",
    attach = {
        bone = "Arm_Right",
        pos = {x=0, y=4, z=0},
        rot = {x=0, y=0, z=0},
    },
    on_attach = function(player, ent)
        minetest.chat_send_player(player:get_player_name(), "Apple attached with wielditem view!")
    end,
})
```

### Saving and Reloading Attachments
```lua
local saved = itemforge3d.get_attached_entries(player)
itemforge3d.detach_all(player)
itemforge3d.reload_attached_items(player, saved)
```

---

## Summary
- **Base item info** (type, description, inventory image, etc.) comes from Minetest’s built‑in registry.  
- **ItemForge3D stores only extras**: `properties`, `attach`, `on_attach`, `on_reload`, `wieldview`.  
- Attach visuals with `itemforge3d.attach_entity`.  
- Detach visuals with `itemforge3d.detach_entity` or `detach_all`.  
- Multiple items can be attached per player, tracked by `id`.  
- Use `get_attached_items` or `get_attached_entries` plus `reload_attached_items` to snapshot and restore attachments.  
- Use `get_extras(item_name)` to inspect ItemForge3D‑specific metadata.  
- Duplicate protection prevents silent overrides; conflicts can be inspected with helper utilities.  

---
