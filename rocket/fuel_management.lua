--
-- fuel
--
local rocket = staged_rocket.rocket

rocket.GAUGE_FUEL_POSITION = {x=-3.5,y=22.15,z=0}

minetest.register_entity('staged_rocket:pointer_fuel',{
  initial_properties = {
    physical = false,
    collide_with_objects=false,
    pointable=false,
    visual = "mesh",
    mesh = "staged_rocket_rocket_pointer.obj",
    textures = {"staged_rocket_rocket_white.png"},
    static_save = false,
  },
})

function rocket.update_fuel_pointer(self, stage)
    local indicator_angle = rocket.get_pointer_angle(stage.fuel, stage.max_fuel)
    if (self.pointer_fuel==nil) or (self.pointer_fuel:get_luaentity()==nil) then
      self.pointer_fuel = minetest.add_entity(self.object:get_pos(),'staged_rocket:pointer_fuel')
    end
    self.pointer_fuel:set_attach(self.object,'',rocket.GAUGE_FUEL_POSITION,{x=0,y=indicator_angle-90,z=0})
end

function staged_rocket.load_fuel(self, player_name)
  local player = minetest.get_player_by_name(player_name)
  local inv = player:get_inventory()

  local itmstck=player:get_wielded_item()
  local item_name = ""
  if itmstck then item_name = itmstck:get_name() end

  --minetest.debug("fuel: ", item_name)
  local fuel = staged_rocket.contains(staged_rocket.fuel, item_name)
  if fuel then
    local stack = ItemStack(item_name .. " 1")

    if self.energy < staged_rocket.MAX_FUEL then
      inv:remove_item("main", stack)
      self.energy = self.energy + fuel.amount
      if self.energy > staged_rocket.MAX_FUEL then self.energy = staged_rocket.MAX_FUEL end
      
      if fuel.drop then
        local leftover = inv:add_item("main", fuel.drop)
        if leftover then
          minetest.item_drop(leftover, player, player:get_pos())
        end
      end

      local energy_indicator_angle = staged_rocket.get_pointer_angle(self.energy, staged_rocket.MAX_FUEL)
      self.pointer:set_attach(self.object,'',staged_rocket.GAUGE_FUEL_POSITION,{x=0,y=0,z=energy_indicator_angle})
    end
    
    return true
  end

  return false
end

