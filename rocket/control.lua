
local rocket = staged_rocket.rocket

--global constants


rocket.last_time_command = 0
rocket.vector_up = vector.new(0, 1, 0)

function rocket.check_node_below(obj)
  local pos_below = obj:get_pos()
  pos_below.y = pos_below.y - 0.1
  local node_below = minetest.get_node(pos_below).name
  local nodedef = minetest.registered_nodes[node_below]
  local touching_ground = not nodedef or -- unknown nodes are solid
      nodedef.walkable or false
  local liquid_below = not touching_ground and nodedef.buildable_to
  return touching_ground, liquid_below
end

function rocket.control(self, dtime, curr_pos, curr_vel, curr_rot, curr_acc)
  local player = minetest.get_player_by_name(self.driver_name)
  
  local rot = curr_rot
  local acc = curr_acc
  
  -- player control
  if player then
    local engine_stage = self.stage
    if self.data_stage_1 then
      engine_stage = self.data_stage_1
    end
    local ctrl = player:get_player_control()
    if ctrl.up then
      local forward = vector.rotate({x=0,y=0,z=1},curr_rot)
      local right = vector.rotate({x=1,y=0,z=0},curr_rot)
      forward = vector.rotate_around_axis(forward, right, -1*dtime)
      local up = vector.cross(forward, right)
      rot = vector.dir_to_rotation(forward, up)
    elseif ctrl.down then
      local forward = vector.rotate({x=0,y=0,z=1},curr_rot)
      local right = vector.rotate({x=1,y=0,z=0},curr_rot)
      forward = vector.rotate_around_axis(forward, right, 1*dtime)
      local up = vector.cross(forward, right)
      rot = vector.dir_to_rotation(forward, up)
    end
    if ctrl.right and (not ctrl.aux1) then
      local forward = vector.rotate({x=0,y=0,z=1},curr_rot)
      local up = vector.rotate({x=0,y=1,z=0},curr_rot)
      forward = vector.rotate_around_axis(forward, up, 1*dtime)
      rot = vector.dir_to_rotation(forward, up)
    elseif ctrl.left and (not ctrl.aux1) then
      local forward = vector.rotate({x=0,y=0,z=1},curr_rot)
      local up = vector.rotate({x=0,y=1,z=0},curr_rot)
      forward = vector.rotate_around_axis(forward, up, -1*dtime)
      rot = vector.dir_to_rotation(forward, up)
    end
    if engine_stage.engine_started then
      if ctrl.sneak and ctrl.aux1 then
        -- stop engine
        engine_stage.engine_started = false
        if (engine_stage.engine_restart==0) then
          engine_stage.engine_power = 0
        end
      end
    else
      if ctrl.left and ctrl.aux1 then
        -- separate stage
        if self.data_stage_1 then
          self:decouple_stage_1(self)
        end
      end
      if ctrl.right and ctrl.aux1 then
        -- separate stage
        if (self.data_stage_1==nil) and self.data_coupling_ring then
          self:decouple_coupling_ring(self)
        end
      end
      if ctrl.jump and ctrl.aux1 then
        -- start engine
        if (engine_stage.engine_power > 0) and (self.stage.battery >= engine_stage.engine_restart) then
          self.stage.battery = self.stage.battery - engine_stage.engine_restart
          if (engine_stage.fuel>0) and (engine_stage.oxidizer>0) then
            engine_stage.engine_started = true
          end
        end
      end
    end
    if (not ctrl.aux1) then
      if ctrl.jump then
        -- increase engine thrust
        engine_stage.engine_thrust = engine_stage.engine_thrust + engine_stage.engine_thrust_step*dtime
        if (engine_stage.engine_thrust>1) then
          engine_stage.engine_thrust = 1
        end
      elseif ctrl.sneak then
        -- decrease engine thrust
        engine_stage.engine_thrust = engine_stage.engine_thrust - engine_stage.engine_thrust_step*dtime
        if (engine_stage.engine_thrust<engine_stage.engine_thrust_min) then
          engine_stage.engine_thrust = engine_stage.engine_thrust_min
        end
      end
    end
  end
  return rot, acc
end

