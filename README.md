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
- `on_attach`: Callback when entity is attached
- `on_detach`: Callback when entity is detached

---

## Attach/Detach
- `itemforge3d.attach_entity(player, item_name)` → attach a 3D model to a player  
- `itemforge3d.detach_entity(player, item_name)` → detach a specific item’s 3D model from a player  
- Multiple items can be attached per player  

---

## Attachment Management
- `itemforge3d.get_attached_items(player)` → returns a list of item names currently attached to the player  
- `itemforge3d.reload_attached_items(player, item_list)` → re‑attaches items from a saved list  

---

## API Reference

| Function | Description |
|----------|-------------|
| `itemforge3d.register(modname, name, def)` | Register a tool, node, or craftitem |
| `itemforge3d.attach_entity(player, item_name)` | Attach an item’s 3D model to a player |
| `itemforge3d.detach_entity(player, item_name)` | Detach a specific item’s 3D model from a player |
| `itemforge3d.get_attached_items(player)` | Get a list of attached item names for a player |
| `itemforge3d.reload_attached_items(player, item_list)` | Reattach items from a saved list |

---

## Examples

### Tool with 3D Model
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
})
```

### Craftitem with Simple Effect
```lua
itemforge3d.register("mymod", "lantern", {
    type = "craftitem",
    description = "Lantern",
    inventory_image = "lantern.png",
    recipe = {
        {"default:steel_ingot", "default:torch", "default:steel_ingot"},
        {"", "default:glass", ""}
    },
    properties = {
        mesh = "lantern.glb",
        textures = {"lantern_texture.png"},
        visual_size = {x=0.7, y=0.7}
    },
    attach = {
        bone = "Arm_Right",
        pos = {x=0, y=6, z=0},
        rot = {x=0, y=0, z=0}
    },
    on_attach = function(player, ent)
        core.chat_send_player(player:get_player_name(), "Lantern attached!")
    end,
    on_detach = function(player, ent)
        core.chat_send_player(player:get_player_name(), "Lantern detached!")
    end,
})
```

### Saving and Reloading Attachments
```lua
-- Save current attachments
local saved = itemforge3d.get_attached_items(player)

-- Detach everything
while itemforge3d.detach_entity(player) do end

-- Later, reload them
itemforge3d.reload_attached_items(player, saved)
```

---

## Summary
- Register items with `itemforge3d.register`.  
- Attach visuals with `itemforge3d.attach_entity`.  
- Detach visuals with `itemforge3d.detach_entity`.  
- Multiple items can be attached per player.  
- Use `get_attached_items` and `reload_attached_items` to snapshot and restore attachments.  
- Optional callbacks let you hook into attach/detach events.  
