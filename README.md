# ItemForge3D

## Register Items
```lua
itemforge3d.register(modname, name, def)
```
Registers a tool, node, or craftitem under the name `modname:name`.

### Definition Fields
- `type`: `"tool"`, `"node"`, or `"craftitem"`
- `description`: Inventory description
- `inventory_image`: Icon texture
- `recipe`: Shaped craft recipe
- `craft`: Full craft definition (shapeless, cooking, fuel, etc.)
- `properties`: Entity properties (mesh, textures, size)
- `attach`: Attach position/rotation/bone
- `wield_mode`: `"image"` (default), `"model"`, or `"none"`  
  - `"image"` → attach a 2D inventory image entity to the player (default)  
  - `"model"` → attach a 3D mesh entity to the player  
  - `"none"` → no entity attached, item remains purely inventory‑based
- `on_attach`: Callback when entity is attached
- `on_detach`: Callback when entity is detached
- `on_reload`: Callback when entity is reloaded after persistence

---

## Attach/Detach
- `itemforge3d.attach_entity(player, itemstack, opts)` → attach an item’s wield entity to a player (image or model depending on `wield_mode`)
- `itemforge3d.detach_entity(player, item_name)` → detach a specific item’s wield entity from a player
- Multiple items can be attached per player

---

## Attachment Management
- `itemforge3d.get_attached_items(player)` → returns a list of item names currently attached to the player
- `itemforge3d.get_attached_entries(player)` → returns detailed entries `{item_name, id, stack}`
- `itemforge3d.reload_attached_items(player, item_list)` → re‑attaches items from a saved list
- `itemforge3d.is_model_wield(item_name)` → returns `true` if the item is registered with `wield_mode = "model"`

---

## API Reference

| Function | Description |
|----------|-------------|
| `itemforge3d.register(modname, name, def)` | Register a tool, node, or craftitem |
| `itemforge3d.attach_entity(player, itemstack, opts)` | Attach an item’s wield entity to a player |
| `itemforge3d.detach_entity(player, item_name)` | Detach a specific item’s wield entity from a player |
| `itemforge3d.get_attached_items(player)` | Get a list of attached item names for a player |
| `itemforge3d.get_attached_entries(player)` | Get detailed attached entries (name, id, stack) |
| `itemforge3d.reload_attached_items(player, item_list)` | Reattach items from a saved list |
| `itemforge3d.is_model_wield(item_name)` | Check if an item is set to use model wield |

---

## Examples

### Tool with 3D Model
```lua
itemforge3d.register("mymod", "sword", {
    type = "tool",
    description = "Forged Sword",
    inventory_image = "sword.png",
    wield_mode = "model", -- opt-in for 3D model
    recipe = {
        {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
        {"", "default:stick", ""},
        {"", "default:stick", ""}
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
    on_detach = function(player, ent)
        core.chat_send_player(player:get_player_name(), "Sword detached!")
    end,
    on_reload = function(player, ent, entry)
        core.chat_send_player(player:get_player_name(), "Sword reloaded!")
    end,
})
```

### Craftitem With Default Image Wield
```lua
itemforge3d.register("mymod", "pickaxe", {
    type = "tool",
    description = "Pickaxe",
    inventory_image = "pickaxe.png",
    -- wield_mode defaults to "image", so no need to specify
})
```

### Craftitem Without Any Wield Entity
```lua
itemforge3d.register("mymod", "potion", {
    type = "craftitem",
    description = "Healing Potion",
    inventory_image = "potion.png",
    wield_mode = "none", -- no entity attached
    recipe = {
        {"default:glass_bottle", "default:apple", "default:glass_bottle"},
    },
})
```

### Saving and Reloading Attachments
```lua
-- Save current attachments
local saved = itemforge3d.get_attached_entries(player)

-- Detach everything
while itemforge3d.detach_entity(player) do end

-- Later, reload them
itemforge3d.reload_attached_items(player, saved)
```

---

## Summary
- Items wield with their **inventory image by default** (`wield_mode = "image"`).  
- Opt‑in to 3D wielding with `wield_mode = "model"`.  
- Opt‑out completely with `wield_mode = "none"`.  
- Attach visuals with `itemforge3d.attach_entity`.  
- Detach visuals with `itemforge3d.detach_entity`.  
- Multiple items can be attached per player.  
- Use `get_attached_items` or `get_attached_entries` plus `reload_attached_items` to snapshot and restore attachments.  
- Optional callbacks (`on_attach`, `on_detach`, `on_reload`) let you hook into lifecycle events.  
- Use `is_model_wield(item_name)` to check if a given item is configured for 3D wield.  
