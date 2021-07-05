
local rocket = staged_rocket.rocket

local update_manual = {
  mass = "add",
  side_surface = "add",
  front_surface = "add",
  drop_disassemble = "join",
  drop_destroy = "join",
}

minetest.register_tool("staged_rocket:rocket_stage_1", {
  description = "Rocket Stage 1",
  inventory_image = "staged_rocket_rocket_stage_1.png",
  
  _stage = {
    hull_integrity = 100,
    max_hull = 100,
    drop_disassemble = {"staged_rocket:rocket_stage_1"},
    drop_destroy = {"default:steel_ingot"},
  },

  on_place = function(itemstack, placer, pointed_thing)
    if (pointed_thing.type == "node") then
      local pointed_pos = pointed_thing.under
      local node_below = minetest.get_node(pointed_pos).name
      local nodedef = minetest.registered_nodes[node_below]
      if nodedef.liquidtype == "none" then
        pointed_pos.y = pointed_pos.y + 3.5
        local boat = minetest.add_entity(pointed_pos, "staged_rocket:rocket_stage_1")
        if boat and placer then
          local ent = boat:get_luaentity()
          local owner = placer:get_player_name()
          local item_def = itemstack:get_definition()
          ent.owner = owner
          rocket.update_table(ent.stage, item_def._stage, update_manual)
          local wear = (65535-itemstack:get_wear())/65535
          if item_def._stage.hull_integrity then
            ent.stage.hull_integrity = item_def._stage.hull_integrity*wear
          end
          boat:set_yaw(placer:get_look_horizontal())
          itemstack:take_item()

          local properties = ent.object:get_properties()
          properties.infotext = owner .. " rocket stage 1"
          ent.object:set_properties(properties)
        end
      end

      return itemstack
    end
  end,
})

minetest.register_tool("staged_rocket:rocket_coupling_ring", {
  description = "Rocket Coupling Ring",
  inventory_image = "staged_rocket_rocket_coupling_ring.png",
  
  _stage = {
    hull_integrity = 200,
    max_hull = 200,
    drop_disassemble = {"staged_rocket:rocket_coupling_ring"},
    drop_destroy = {"default:steel_ingot"},
  },

  on_place = function(itemstack, placer, pointed_thing)
    if (pointed_thing.type == "object") then
      print(dump(pointed_thing))
      return
    end
    if (pointed_thing.type == "node") then
      local pointed_pos = pointed_thing.under
      local node_below = minetest.get_node(pointed_pos).name
      local nodedef = minetest.registered_nodes[node_below]
      if nodedef.liquidtype == "none" then
        pointed_pos.y = pointed_pos.y + 3.5
        local boat = minetest.add_entity(pointed_pos, "staged_rocket:rocket_coupling_ring")
        if boat and placer then
          local ent = boat:get_luaentity()
          local owner = placer:get_player_name()
          local item_def = itemstack:get_definition()
          ent.owner = owner
          ent.surface_level = pointed_thing.under.y
          if staged_rocket.hull_deep_limit then
            ent.deep_limit = item_def.deep_limit
          end
          local wear = (65535-itemstack:get_wear())/65535
          if item_def.hull_integrity then
            ent.hull_integrity = item_def.hull_integrity*wear
          end
          boat:set_yaw(placer:get_look_horizontal())
          itemstack:take_item()

          local properties = ent.object:get_properties()
          properties.infotext = owner .. " rocket coupling ring"
          ent.object:set_properties(properties)
        end
      end

      return itemstack
    end
  end,
})

minetest.register_tool("staged_rocket:rocket_stage_orbital", {
  description = "Rocket orbital stage",
  inventory_image = "staged_rocket_rocket_stage_orbital.png",
  
  _stage = {
    hull_integrity = 100,
    max_hull = 100,
    drop_disassemble = {"staged_rocket:rocket_stage_orbital"},
    drop_destroy = {"default:steel_ingot"},
  },
  
  on_place = function(itemstack, placer, pointed_thing)
    if (pointed_thing.type == "node") then
      local pointed_pos = pointed_thing.under
      local node_below = minetest.get_node(pointed_pos).name
      local nodedef = minetest.registered_nodes[node_below]
      if nodedef.liquidtype == "none" then
        pointed_pos.y = pointed_pos.y + 3.67
        local boat = minetest.add_entity(pointed_pos, "staged_rocket:rocket_stage_orbital")
        if boat and placer then
          local ent = boat:get_luaentity()
          local owner = placer:get_player_name()
          local item_def = itemstack:get_definition()
          ent.owner = owner
          rocket.update_table(ent.stage, item_def._stage, update_manual)
          local wear = (65535-itemstack:get_wear())/65535
          if item_def.hull_integrity then
            ent.stage.hull_integrity = item_def.hull_integrity*wear
          end
          boat:set_yaw(placer:get_look_horizontal())
          itemstack:take_item()

          local properties = ent.object:get_properties()
          properties.infotext = owner .. " rocket orbital stage"
          ent.object:set_properties(properties)
        end
      end

      return itemstack
    elseif (pointed_thing.type == "object") then
      print(dump(pointed_thing))
    end
  end,
})

