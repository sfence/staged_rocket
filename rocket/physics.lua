
local rocket = staged_rocket.rocket

local min = math.min
local abs = math.abs

local get_mass = rocket.get_mass
local get_key_sum = rocket.get_key_sum

local stage_orbital_engines = {
  vector.new( 0   , 0 ,-0.5), -- 0, 5
  vector.new( 0.433, 0 , 0.25),-- 0.433, 2.5
  vector.new(-0.433, 0 , 0,25)
}
local stage_1_engines = {
  vector.new( 0.7 , 0, 0.0), -- 0, 7
  vector.new( 0.22, 0, 0.67),
  vector.new( -0.56, 0,0.41),
  vector.new( -0.56, 0,-0.41),
  vector.new( 0.22, 0,-0.67)
}
local function engine_particles(self, thrust, curr_pos, curr_rot, curr_dir, curr_vel)
  local offset = -3.2
  local engines = stage_orbital_engines
  if self.data_stage_1 then
    offset = -9
    engines = stage_1_engines
  end
  for _,engine in pairs(engines) do
    engine = vector.rotate(engine, curr_rot)
    local minmaxpos = vector.add(vector.add(curr_pos, vector.multiply(curr_dir, offset)), engine)
    local minvel = vector.add(vector.add(vector.multiply(engine,0.2), curr_vel), thrust)
    local maxvel = vector.add(vector.add(vector.multiply(engine,0.5), curr_vel), thrust)
    local minacc = vector.multiply(thrust, 1)
    local maxacc = vector.multiply(thrust, 5)
    
    minetest.add_particlespawner({
      amount = 1, --1,
      time = 1.0, --0.1,
      collisiondetection = true,
      minpos = minmaxpos,
      maxpos = minmaxpos,
      minvel = minvel,
      maxvel = maxvel,
      minacc = minacc,
      maxacc = maxacc,
      minexptime = 0.25, --1
      maxexptime = 0.75, --2.5,
      minsize = 10, --1,
      maxsize = 12, --4,
      texture = "staged_rocket_rocket_boom.png",
    })
    
    minmaxpos = vector.add(minmaxpos, vector.multiply(curr_dir, -0.5))
    
    minetest.add_particlespawner({
      amount = 3, --1,
      time = 0.2, --0.1,
      collisiondetection = true,
      collision_removal = true,
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
    
  end
end

function rocket.physics(self, dtime, curr_acc, curr_rot)
  local engine_stage = self.stage
  if self.data_stage_1 then
    engine_stage = self.data_stage_1
  end
  
  local mass = get_mass(self)
  
  local curr_pos = self.object:get_pos()
  
  local curr_vel = self.object:get_velocity()
  local curr_dir = vector.rotate(vector.new(0,1,0), curr_rot)
  
  local air_density = rocket.get_air_density(vector.add(curr_pos, vector.multiply(curr_vel, dtime)))
  
  local vel = vector.length(curr_vel)
  
  if (air_density>0) and (vel>0) then
    local angle = vector.angle(curr_dir, curr_vel)
    local front_sur = 0
    local side_sur = get_key_sum(self, "side_drag")
    if (angle<(0.5*math.pi)) then
      front_sur = self.stage.front_drag
    else
      front_sur = self.stage.back_drag
      if self.data_stage_1 then
        front_sur = self.data_stage_1.back_drag
      elseif self.data_coupling_ring then
        front_sur = front_sur + self.data_coupling_ring.back_drag
      end
    end
    print("side: "..side_sur..", front: "..front_sur..", angle: "..angle)
    local sin = math.sin(angle)
    local cos = math.cos(angle)
    local asin = math.abs(sin)
    local acos = math.abs(cos)
    local side_drag = rocket.DRAG_COEF*(acos*front_sur+asin*side_sur)*(sin*vel*vel)*air_density/mass
    local front_drag = rocket.DRAG_COEF*(asin*front_sur+acos*side_sur)*(cos*vel*vel)*air_density/mass
    print("side: "..side_drag..", front: "..front_drag)
    print("air density: "..air_density..", vel: "..vel)
    
    local side_vec = vector.subtract(curr_vel, vector.multiply(curr_dir, math.sin(angle)*vel))
    print("acc: "..dump(curr_acc))
    curr_acc = vector.add(curr_acc, vector.multiply(curr_dir, -front_drag))
    curr_acc = vector.add(curr_acc, vector.multiply(vector.normalize(side_vec), -side_drag))
    print("acc: "..dump(curr_acc))
    
    if (side_drag>0) then
      --local fix_angle = fix_angle*dtime*side_drag/mass
      --local normal = vector.cross(curr_dir, curr_vel)
      --vector.rotate_around_axis(curr_dir, normal, fix_angle)
    end
  end
  
  if engine_stage.engine_started then
    local acc = engine_stage.engine_power*engine_stage.engine_thrust/mass
    local consume = engine_stage.engine_consume*engine_stage.engine_thrust*dtime
    local fuel_need = consume*engine_stage.consume_fuel
    local oxidizer_need = fuel_need*engine_stage.require_oxidizer*engine_stage.consume_oxidizer
    print("mass: "..mass..", acc: "..acc..", fuel: "..fuel_need..", oxidizer: "..oxidizer_need)
    engine_stage.fuel = engine_stage.fuel - fuel_need
    engine_stage.oxidizer = engine_stage.oxidizer - oxidizer_need
    if (engine_stage.fuel<=0) or (engine_stage.oxidizer<=0) then
      engine_stage.engine_started = false
      if (engine_stage.engine_restart==0) then
        engine_stage.engine_power = 0
      end
    end
    
    local thrust = vector.multiply(curr_dir, acc)
    curr_acc = vector.add(curr_acc, thrust)
    thrust = vector.multiply(thrust, -1)
    
    engine_particles(self, thrust, curr_pos, curr_rot, curr_dir, curr_vel)
  end
  
  return curr_acc, curr_rot
end

