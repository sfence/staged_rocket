
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
    if ctrl.right then
      local forward = vector.rotate({x=0,y=0,z=1},curr_rot)
      local up = vector.rotate({x=0,y=1,z=0},curr_rot)
      forward = vector.rotate_around_axis(forward, up, 1*dtime)
      rot = vector.dir_to_rotation(forward, up)
    elseif ctrl.left then
      local forward = vector.rotate({x=0,y=0,z=1},curr_rot)
      local up = vector.rotate({x=0,y=1,z=0},curr_rot)
      forward = vector.rotate_around_axis(forward, up, -1*dtime)
      rot = vector.dir_to_rotation(forward, up)
    end
    if ctrl.jump then
      local forward = vector.rotate({x=0,y=1,z=0},curr_rot)
      local engine = vector.multiply(forward, 11)
      acc = vector.add(acc, engine)
      local thrust = vector.multiply(forward, -1)
      local minmaxpos = vector.add(curr_pos, vector.multiply(forward, -8))
      local minvel = vector.add(vector.add({x=-0.2,y=0,z=-0.2}, curr_vel), thrust)
      local maxvel = vector.add(vector.add({x=0.3,y=0.3,z=0.3}, curr_vel), thrust)
      local minacc = vector.multiply(thrust, 1)
      local maxacc = vector.multiply(thrust, 5)
      minetest.add_particlespawner({
        amount = 3, --1,
        time = 0.2, --0.1,
        minpos = minmaxpos,
        maxpos = minmaxpos,
        minvel = minvel,
        maxvel = minvel,
        minacc = minacc,
        maxacc = maxacc,
        minexptime = 1,
        maxexptime = 2.5,
        minsize = 4, --1,
        maxsize = 10, --4,
        texture = "staged_rocket_rocket_smoke.png",
      })
      
      minetest.add_particlespawner({
        amount = 1, --1,
        time = 1.0, --0.1,
        minpos = minmaxpos,
        maxpos = minmaxpos,
        minvel = minvel,
        maxvel = maxvel,
        minacc = minacc,
        maxacc = maxacc,
        minexptime = 0.25, --1
        maxexptime = 0.75, --2.5,
        minsize = 14, --1,
        maxsize = 16, --4,
        texture = "staged_rocket_rocket_boom.png",
      })
    end
  end
  return rot, acc
end

