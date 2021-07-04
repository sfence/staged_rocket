--
-- air
--
local rocket = staged_rocket.rocket

rocket.GAUGE_AIR_POSITION = {x=3.5,y=22.15,z=0}

minetest.register_entity('staged_rocket:pointer_air',{
  initial_properties = {
    physical = false,
    collide_with_objects=false,
    pointable=false,
    visual = "mesh",
    mesh = "staged_rocket_rocket_pointer.obj",
    textures = {"staged_rocket_rocket_white.png^[multiply:#0000FF"},
    static_save = false,
  },
})

function rocket.update_air_pointer(self, stage)
    local indicator_angle = rocket.get_pointer_angle(stage.air, stage.max_air)
    if (self.pointer_air==nil) or (self.pointer_air:get_luaentity()==nil) then
      self.pointer_air = minetest.add_entity(self.object:get_pos(),'staged_rocket:pointer_air')
    end
    self.pointer_air:set_attach(self.object,'',rocket.GAUGE_AIR_POSITION,{x=0,y=-indicator_angle+90,z=0})
end

function rocket.load_air(self, player_name)
  local player = minetest.get_player_by_name(player_name)
  local inv = player:get_inventory()

  local itmstck=player:get_wielded_item()
  local item_name = ""
  if itmstck then item_name = itmstck:get_name() end

  --minetest.debug("air: ", item_name)
  local air = staged_rocket.contains(rocket.air, item_name)
  if air then
    local stack = ItemStack(item_name .. " 1")
    
    if self.air < rocket.stage.max_air then
      inv:remove_item("main", stack)
      self.air = self.air + air.amount
      if self.air > rocket.stage.max_air then self.air = rocket.stage.max_air end
      
      if air.drop then
        local leftover = inv:add_item("main", air.drop)
        if leftover then
          minetest.item_drop(leftover, player, player:get_pos())
        end
      end

      local air_indicator_angle = staged_rocket.get_pointer_angle(self.air, rocket.stage.max_air)
      self.pointer:set_attach(self.object,'',rocket.GAUGE_AIR_POSITION,{x=0,y=0,z=air_indicator_angle})
    end
    
    return true
  end

  return false
end

