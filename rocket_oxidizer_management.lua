--
-- oxidizer
--
local rocket = staged_rocket.rocket

rocket.GAUGE_OXIDIZER_POSITION = {x=-3.5,y=22.15,z=0}

minetest.register_entity('staged_rocket:pointer_oxidizer',{
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

function rocket.update_oxidizer_pointer(self, stage)
    local indicator_angle = rocket.get_pointer_angle(stage.oxidizer, stage.max_oxidizer)
    if (self.pointer_oxidizer==nil) or (self.pointer_oxidizer:get_luaentity()==nil) then
      self.pointer_oxidizer = minetest.add_entity(self.object:get_pos(),'staged_rocket:pointer_oxidizer')
    end
    self.pointer_oxidizer:set_attach(self.object,'',rocket.GAUGE_OXIDIZER_POSITION,{x=0,y=-indicator_angle+90,z=0})
end

function staged_rocket.load_oxidant(self, player_name)
  local player = minetest.get_player_by_name(player_name)
  local inv = player:get_inventory()

  local itmstck=player:get_wielded_item()
  local item_name = ""
  if itmstck then item_name = itmstck:get_name() end

  --minetest.debug("fuel: ", item_name)
  local fuel = staged_rocket.contains(staged_rocket.fuel, item_name)
  if fuel then
    local stack = ItemStack(item_name .. " 1")

    if (self.stage.oxidizer+oxidizer.amount) < staged_rocket.stage.max_oxidizer then
      inv:remove_item("main", stack)
      self.energy = self.energy + fuel.amount
      if self.energy > staged_rocket.stage.max_oxidizer then self.energy = staged_rocket.stage.max_oxidizer end
      
      if fuel.drop then
        local leftover = inv:add_item("main", fuel.drop)
        if leftover then
          minetest.item_drop(leftover, player, player:get_pos())
        end
      end

      local indicator_angle = staged_rocket.get_pointer_angle(self.energy, staged_rocket.stage.max_oxidizer)
      self.pointer:set_attach(self.object,'',staged_rocket.GAUGE_OXIDIZER_POSITION,{x=0,y=0,z=indicator_angle})
    end
    
    return true
  end

  return false
end

