
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

  on_place = rocket.on_place_stage_1,
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
  
  on_place = rocket.on_place_stage_orbital,
})

