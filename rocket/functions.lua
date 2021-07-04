
local rocket = staged_rocket.rocket

-- restore rocket stages after server restart
function rocket.restore_stage_1(parent, data, dtime_s)
  local pos = parent.object:get_pos()
  local ring = minetest.add_entity(pos, "staged_rocket:rocket_stage_1")
  if ring then
    local ent = ring:get_luaentity()
    ring:set_yaw(parent.object:get_yaw())
    ring:set_attach(parent.object, "", {x=0,y=-60,z=0},{x=0,y=0,z=0})
    ent.is_attached = true
    ent.stage = data
    parent.data_stage_1 = data
    parent.object_stage_1 = ring
  end
end
function rocket.restore_coupling_ring(parent, data, dtime_s)
  local pos = parent.object:get_pos()
  local ring = minetest.add_entity(pos, "staged_rocket:rocket_coupling_ring")
  if ring then
    local ent = ring:get_luaentity()
    ring:set_yaw(parent.object:get_yaw())
    if (parent.name=="staged_rocket:rocket_stage_1") then
      ring:set_attach(parent.object, "", {x=0,y=31.5,z=0},{x=0,y=0,z=0})
    else
      ring:set_attach(parent.object, "", {x=0,y=-28.5,z=0},{x=0,y=0,z=0})
    end
    ent.is_attached = true
    ent.stage = data
    parent.data_coupling_ring = data
    parent.object_coupling_ring = ring
  end
end

-- on place functions
function rocket.on_place_stage1(itemstack, placer, pointed_thing)
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
        ent.surface_level = pointed_thing.under.y
        rocket.update_table(ent.stage, item_def._stage)
        local wear = (65535-itemstack:get_wear())/65535
        if item_def._stage.hull_integrity then
          ent.stage.hull_integrity = item_def._stage.hull_integrity*wear
        end
        ent.stage.drop_item = itemstack:to_string()
        boat:set_yaw(placer:get_look_horizontal())
        itemstack:take_item()

        local properties = ent.object:get_properties()
        properties.infotext = owner .. " rocket stage 1"
        if (ent.stage.engine_power==0) then
          properties.textures[19] = "staged_rocket_rocket_transparent.png"
        end
        ent.object:set_properties(properties)
      end
    end

    return itemstack
  end
end

-- droping
function rocket.drop_items(self, drop_list, curr_pos, explostion)
  local curr_pos = self.object:get_pos()
  local curr_vel = self.object:get_velocity()
  local curr_g = rocket.get_gravity_vector(curr_pos)
  for _, drop in pairs(drop_list) do
    local stack = ItemStack(drop)
    if minetest.registered_tools[stack:get_name()] then
      if self.stage.hull_integrity then
        local wear = math.floor(65535*(1-(self.stage.hull_integrity/self.stage.max_integrity)))
        stack:set_wear(wear)
      end
    end
    local item = minetest.add_item({x=curr_pos.x+math.random()-0.5,y=curr_pos.y,z=curr_pos.z+math.random()-0.5}, stack)
    if item then
      item:set_acceleration(curr_g)
      if (explosion==0) then
        item:set_velocity(curr_vel)
      else
        item:set_velocity({
          x=curr_vel.x+math.random(-explosion, explosion),
          y=curr_vel.y+math.random(-explosion, explosion),
          z=curr_vel.z+math.random(-explosion, explosion)})
      end
    end
  end
end

-- destroy the boat
function rocket.destroy(self, overload)
  if self.sound_handle then
    minetest.sound_stop(self.sound_handle)
    self.sound_handle = nil
  end

  if self.driver_name then
    local driver = minetest.get_player_by_name(self.driver_name)
    -- prevent error when submarine of unlogged driver is destroied by preasure
    if driver then
      driver:set_detach()
      driver:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
      -- player should stand again
      player_api.set_animation(driver, "stand")
    end
    player_api.player_attached[self.driver_name] = nil
    self.driver_name = nil
  end

  local pos = self.object:get_pos()

  self.object:remove()

  if overload then
    local stack = ItemStack(self.stage.item)
    local item_def = stack:get_definition()
    
    if item_def.overload_drop then
      for _,item in pairs(item_def.overload_drop) do
        minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},item)
      end
      return
    end
  end
  local stack = ItemStack(self.stage.item)
  local item_def = stack:get_definition()
  if self.hull_integrity then
    local boat_wear = math.floor(65535*(1-(self.hull_integrity/item_def.hull_integrity)))
    stack:set_wear(boat_wear)
  end
  minetest.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5}, stack)
end

-- help functions
function rocket.get_pointer_angle(value, maxvalue)
  local angle = value/maxvalue * 180
  angle = angle - 90
  angle = angle * -1
  return angle
end

function rocket.contains(table, val)
  for k,v in pairs(table) do
    if k == val then
      return v
    end
  end
  return false
end

function rocket.get_mass(self)
  local mass = self.stage.mass
  if self.stage.fuel and (self.stage.fuel>0) then
    mass = mass + self.stage.fuel * self.stage.density_fuel
  end
  if self.stage.oxidizer and (self.stage.oxidizer>0) then
    mass = mass + self.stage.oxidizer * self.stage.density_oxidizer
  end
  if self.stage.air and (self.stage.air>0) then
    mass = mass + self.stage.air * self.stage.density_air
  end
  if self.data_coupling_ring then
    mass = mass + self.data_coupling_ring.mass
  end
  if self.data_stage_1 then
    mass = mass + self.data_stage_1.mass
  end
  return mass
end

function rocket.get_key_sum(self, key)
  local sum = self.stage[key]
  if self.data_coupling_ring then
    sum = sum + self.data_coupling_ring[key]
  end
  if self.data_stage_1 then
    sum = sum + self.data_stage_1[key]
  end
  
  return sum
end

function rocket.update_table(table_to, table_add, manual)
  for key, value in pairs(table_add) do
    if (manual[key]=="add") then
      table_to[key] = table_to[key] + value
    elseif (manual[key]=="insert") then
      table.insert(table_to[key], value)
    elseif (manual[key]=="join") then
      for _,val in pairs(value) do
        table.insert(table_to[key], val)
      end
    else
      table_to[key] = value
    end
  end
end


