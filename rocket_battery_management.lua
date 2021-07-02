--
-- battery
--
local rocket = staged_rocket.rocket

rocket.GAUGE_BATTERY_POSITION = {x=3.5,y=22.15,z=0}

minetest.register_entity('staged_rocket:pointer_battery',{
  initial_properties = {
    physical = false,
    collide_with_objects=false,
    pointable=false,
    visual = "mesh",
    mesh = "staged_rocket_rocket_pointer.obj",
    textures = {"staged_rocket_rocket_white.png^[multiply:#FFD800"},
    static_save = false,
  },
})

function rocket.update_battery_pointer(self, stage)
    local indicator_angle = rocket.get_pointer_angle(stage.battery, stage.max_battery)
    if (self.pointer_battery==nil) or (self.pointer_battery:get_luaentity()==nil) then
      self.pointer_battery = minetest.add_entity(self.object:get_pos(),'staged_rocket:pointer_battery')
    end
    self.pointer_battery:set_attach(self.object,'',rocket.GAUGE_BATTERY_POSITION,{x=0,y=-indicator_angle+90,z=0})
end

function rocket.load_battery(self, player_name)
  local player = minetest.get_player_by_name(player_name)
  local inv = player:get_inventory()

  local itmstck=player:get_wielded_item()
  local item_name = ""
  if itmstck then item_name = itmstck:get_name() end

  --minetest.debug("battery: ", item_name)
  local battery = staged_rocket.contains(rocket.battery, item_name)
  if battery then
    local stack = ItemStack(item_name .. " 1")
    
    if self.battery < rocket.stage.max_battery then
      inv:remove_item("main", stack)
      self.battery = self.battery + battery.amount
      if self.battery > rocket.stage.max_battery then self.battery = rocket.stage.max_battery end
      
      if battery.drop then
        local leftover = inv:add_item("main", battery.drop)
        if leftover then
          minetest.item_drop(leftover, player, player:get_pos())
        end
      end

      local battery_indicator_angle = staged_rocket.get_pointer_angle(self.battery, rocket.stage.max_battery)
      self.pointer:set_attach(self.object,'',rocket.GAUGE_BATTERY_POSITION,{x=0,y=0,z=battery_indicator_angle})
    end
    
    return true
  end

  return false
end

