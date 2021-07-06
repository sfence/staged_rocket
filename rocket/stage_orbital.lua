
local rocket = staged_rocket.rocket

--
-- support functions
--

local rocket_attached = {}

-- attach player
local function attach_player(self, player)
  --self.object:set_properties({glow = 10})
  local name = player:get_player_name()
  self.driver_name = name
  self.engine_running = true
  if (staged_rocket.have_air==false) then
    player:set_breath(10)
  end
  rocket_attached[name] = self.object

  -- temporary------
  self.hp = 50 -- why? cause I can desist from destroy
  ------------------

  -- attach the driver
  player:set_attach(self.seat, "", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})  
  player:set_eye_offset({x = 0, y = 0, z = 0})
  local props = player:get_properties()
  self.eye_height = props.eye_height
  props.eye_height = 0
  player:set_properties(props)
  player:set_look_vertical(-math.pi/2)
  player:set_look_horizontal(self.object:get_yaw())
  player_api.player_attached[name] = true
  -- make the driver sit
  minetest.after(0.2, function()
    player = minetest.get_player_by_name(name)
    if player then
      player_api.set_animation(player, "sit")
    end
  end)
  -- disable gravity
  self.object:set_acceleration(vector.new())
end
-- detach player
local function detach_player(self, player)
  -- detach the player
  local player_name = player:get_player_name()
  player:set_detach()
  rocket_attached[player_name] = nil
  player_api.player_attached[player_name] = nil
  local props = player:get_properties()
  props.eye_height = self.eye_height
  player:set_properties(props)
  player:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
  player_api.set_animation(player, "stand")
  self.driver_name = nil
  --self.object:set_acceleration(vector.multiply(staged_rocket.vector_up, -staged_rocket.gravity))
  -- move player
  local new_pos = vector.rotate(vector.new(0,1,-2), self.object:get_rotation())
  new_pos = vector.add(self.object:get_pos(), new_pos)
  minetest.after(0.1, function(player_name, pos)
    local player = minetest.get_player_by_name(player_name)
    if player then
      player:set_pos(pos)
    end
  end, player_name, new_pos)
end

-- open airlock
local function open_airlock(self, player)
  local pos = self.object:get_pos()
  local node = minetest.get_node_or_nil(pos)
  if node then
    local node_def = minetest.registered_nodes[node.name]
    if (node_def.liquidtype=="none") and (node_def.drowning==0) then
      if (self.stage.air < rocket.STAGE_ORBITAL_REAIR_ON_AIR) then
        self.stage.air = rocket.STAGE_ORBITAL_REAIR_ON_AIR
        minetest.chat_send_player(player:get_player_name(), "Rocket has been filled with fresh air.")
      end
    else
      self.stage.air = self.stage.air - rocket.STAGE_ORBITAL_OPEN_AIR_LOST
      if (self.stage.air<0) then
        self.stage.air = 0
      end
    end
  end
end

--
local function stage_destroy(self, player, overload)
  if self.pointer_fuel then
    self.pointer_fuel:remove()
  end
  if self.pointer_oxidizer then
    self.pointer_oxidizer:remove()
  end
  if self.pointer_air then
    self.pointer_air:remove()
  end
  if self.pointer_battery then
    self.pointer_battery:remove()
  end
  if player then
    detach_player(self, player)
  end
  self.seat:remove()
  
  if self.data_coupling_ring then
    local pos = self.object:get_pos()
    local rot = self.object:get_rotation()
    local vel = self.object:get_velocity()
    local acc = self.object:get_acceleration()
    local dir = vector.rotate(vector.new(0,1,0),rot)
    if self.data_stage_1 then
      rocket.set_detach(self.object_stage_1)
      self.object_coupling_ring:set_attach(self.object_stage_1, "", vector.new(0,31.5,0),vector.new(0,0,0))
      self.object_stage_1:set_pos(vector.add(pos,vector.multiply(dir, -6)))
      self.object_stage_1:set_rotation(rot)
      self.object_stage_1:set_velocity(vel)
      self.object_stage_1:set_acceleration(acc)
      local stage_1 = self.object_stage_1:get_luaentity()
      stage_1.data_coupling_ring = self.data_coupling_ring
      stage_1.object_coupling_ring = self.object_coupling_ring
      self.data_coupling_ring = nil
      self.object_coupling_ring = nil
      self.data_stage_1 = nil
      self.object_stage_1 = nil
    else
      rocket.set_detach(self.object_coupling_ring)
      self.object_coupling_ring:set_pos(vector.add(pos,vector.multiply(dir, -2.85)))
      self.object_coupling_ring:set_rotation(rot)
      self.object_coupling_ring:set_velocity(vel)
      self.object_coupling_ring:set_acceleration(acc)
      local ring = self.object_coupling_ring:get_luaentity()
      self.data_coupling_ring = nil
      self.object_coupling_ring = nil
    end
  end
  
  rocket.destroy(self, overload)
end

-- decouple stage 1
local function decouple_stage_1(self)
  local pos = self.object:get_pos()
  local rot = self.object:get_rotation()
  local vel = self.object:get_velocity()
  local dir = vector.rotate(vector.new(0,1,0), rot)
  local stage_1 = self.object_stage_1
  local data_stage_1 = stage_1:get_luaentity()
  self.data_stage_1 = nil
  self.object_stage_1 = nil
  stage_1:set_detach()
  data_stage_1.is_attached = false
  stage_1:set_pos(vector.add(pos, vector.multiply(dir, -6)))
  stage_1:set_rotation(rot)
  
  local stage_1_mass = rocket.get_mass(data_stage_1)
  local mass = rocket.get_mass(self)
  
  stage_1:set_velocity(vector.add(vel, vector.multiply(dir, -data_stage_1.stage.decouple_energy/stage_1_mass)))
  self.object:set_velocity(vector.add(vel, vector.multiply(dir, data_stage_1.stage.decouple_energy/mass)))
end

-- decouple coupling ring
local function decouple_coupling_ring(self)
  local pos = self.object:get_pos()
  local rot = self.object:get_rotation()
  local vel = self.object:get_velocity()
  local dir = vector.rotate(vector.new(0,1,0), rot)
  local ring = self.object_coupling_ring
  local data_ring = ring:get_luaentity()
  self.data_coupling_ring = nil
  self.object_coupling_ring = nil
  ring:set_detach()
  data_ring.is_attached = false
  ring:set_pos(vector.add(pos, vector.multiply(dir, -6)))
  ring:set_rotation(rot)
  
  local ring_mass = rocket.get_mass(data_ring)
  local mass = rocket.get_mass(self)
  
  ring:set_velocity(vector.add(vel, vector.multiply(dir, -data_ring.stage.decouple_energy/ring_mass)))
  self.object:set_velocity(vector.add(vel, vector.multiply(dir, data_ring.stage.decouple_energy/mass)))
end

-- norespawn in rocket when death
minetest.register_on_dieplayer(function(player, reason)
    local name = player:get_player_name()
    local object = rocket_attached[name]
    if object then
      local entity = object:get_luaentity()
      if entity and (entity.name=="staged_rocket:rocket_stage_orbital") then
        if (entity.driver_name == name) then
          player:set_detach()
          entity.driver_name = nil
          rocket_attached[player:get_player_name()] = nil
          player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
          player_api.player_attached[name] = nil
          player_api.set_animation(player, "stand")
        end
      end
    end
  end)


--
-- entity
--

minetest.register_entity("staged_rocket:rocket_stage_orbital", {
  initial_properties = {
    physical = true,
    collisionbox = {-1, -1, -1, 1, 1, 1},
    selectionbox = {-1, -1, -1, 1, 1, 1},
    --selectionbox = {-0.6,0.6,-0.6, 0.6,1,0.6},
    visual = "mesh",
    mesh = "staged_rocket_rocket_stage_orbital.b3d",
    --mesh = "staged_rocket_rocket_stage_orbital.obj",
    textures = {
      "staged_rocket_rocket_metal.png", --bottom cap
      "staged_rocket_rocket_white.png", --cabin painting
      "staged_rocket_rocket_black.png", --cabin painting 2
      "staged_rocket_rocket_grey.png", --cabin interior
      "staged_rocket_rocket_grey.png", --cabin interior cap
      "staged_rocket_rocket_black.png", --seat
      "staged_rocket_rocket_white.png", --door
      "staged_rocket_rocket_white.png", --wings pt1
      "staged_rocket_rocket_black.png", --wings pt2
      "staged_rocket_rocket_black.png", --exaust
      "staged_rocket_rocket_metal.png", --legs
      "staged_rocket_rocket_white.png", --main body
      "staged_rocket_rocket_red.png", --body strip
      "staged_rocket_rocket_black.png", -- nose
      "staged_rocket_rocket_black.png", --panel
      "staged_rocket_rocket_black.png", --panel front
      "staged_rocket_rocket_black.png", --screen
      "staged_rocket_rocket_panel.png", --panel
      "staged_rocket_rocket_black.png", --engines
      "staged_rocket_rocket_black.png", --windows and door frame
      "staged_rocket_rocket_glass.png" --glass
    },
  },
  decouple_stage_1 = decouple_stage_1,
  decouple_coupling_ring = decouple_coupling_ring,
  
  textures = {},
  driver_name = nil,
  sound_handle = nil,
  owner = "",
  static_save = true,
  infotext = "A rocket orbital stage",
  hp = 50,
  color = "#ffe400",
  timeout = 0;
  max_hp = 50,
  
  breath_time = 0,
  drown_time = 0,
  sound_time = 0,
  
  last_vel = vector.new(0,0,0),
  
  data_stage_1 = nil,
  object_stage_1 = nil,
  data_coupling_ring = nil,
  object_coupling_ring = nil,
  
  pointer_fuel = nil,
  pointer_oxidizer = nil,
  pointer_air = nil,
  pointer_battery = nil,
  
  stage = {
    mass = 15000,
    front_drag = 4,
    side_drag = 10,
    back_drag = 6,
    
    fuel = 500,
    consume_fuel = 1,
    require_oxidizer = 2.2,
    max_fuel = 500,
    density_fuel = 10,
    oxidizer = 1100,
    consume_oxidizer = 1,
    max_oxidizer = 1100,
    density_oxidizer = 10,
    air = rocket.STAGE_ORBITAL_REAIR_ON_AIR, -- air for crew
    max_air = 3600,
    density_air = 1,
    battery = 60,
    max_battery = 60,
    hull_integrity = nil,
    max_hull = nil,
    gear_limit = 600, -- max damage which gear is able to absorb
    drop_disassemble = {"staged_rocket:rocket_stage_orbital"},
    drop_destroy = {"default:steel_ingot"},
    
    engine_power = 300000, -- can be replaced by zero until engines will be installed
    engine_consume = 30, -- how much fuel engine consume
    engine_started = false, -- is engine started?
    engine_restart = 1, -- energy for engine start
    engine_thrust = 1, -- set engine thurst
    engine_thrust_step = 0.05, -- engine step for thrust change
    engine_thrust_min = 0.13, -- engine min settable thurst
    
    screen = true, -- screen is installed
    screen_sensors = true, -- sensors is installed
    screen_speedometer = true, -- speedometer
    screen_altimeter = true, -- altimeter
    screen_gyroscope = true, -- gyroscope for horizont in installed
    screen_radar = 100, -- object radar defined by range
    screen_lidar_sides = 50, -- lidar defined by range
    screen_lidar_top = 50, -- lidar defined by range
    screen_lidar_bottom = 50, -- lidar defined by range
  },

  get_staticdata = function(self) -- unloaded/unloads ... is now saved
    return minetest.serialize({
      owner = self.owner,
      hp = self.hp,
      color = self.color,
      last_vel = self.last_vel,
      driver_name = self.driver_name,
      data_stage_1 = self.data_stage_1,
      data_coupling_ring = self.data_coupling_ring,
      stage = self.stage,
    })
  end,

  on_activate = function(self, staticdata, dtime_s)
    if staticdata ~= "" and staticdata ~= nil then
      self.last_vel = self.object:get_velocity()
      
      local data = minetest.deserialize(staticdata) or {}
      self.owner = data.owner
      self.hp = data.hp
      self.color = data.color
      self.last_vel = data.last_vel
      self.driver_name = data.driver_name
      self.stage = data.stage
      local properties = self.object:get_properties()
      properties.infotext = data.owner .. " rocket orbital stage"
      self.object:set_properties(properties)
      if data.data_coupling_ring then
        rocket.restore_coupling_ring(self, data.data_coupling_ring, dtime_s)
      end
      if data.data_stage_1 then
        rocket.restore_stage_1(self, data.data_stage_1, dtime_s)
      end
      
    end

    --staged_rocket.paint(self, self.color)
    local pos = self.object:get_pos()

    -- fuel indicator
    -- oxidizer indicator
    if self.data_stage_1 then
      rocket.update_fuel_pointer(self, self.data_stage_1)
      rocket.update_oxidizer_pointer(self, self.data_stage_1)
    else
      rocket.update_fuel_pointer(self, self.stage)
      rocket.update_oxidizer_pointer(self, self.stage)
    end
    -- air indiator
    rocket.update_air_pointer(self, self.stage)
    -- battery indiator
    rocket.update_battery_pointer(self, self.stage)
    
    -- seat
    self.seat = minetest.add_entity(pos, "staged_rocket:rocket_seat")
    self.seat:set_attach(self.object, "", {x = 0, y = 14, z = 4}, {x = -90, y = 0, z = 0})

    self.object:set_armor_groups({immortal=1})
  end,

  on_step = function(self, dtime, moveresult)
    local player = nil
    -- check driver
    if self.driver_name then
      player = minetest.get_player_by_name(self.driver_name)
      if (player==nil) then
        -- waiting for driver to reconnect
        self.object:set_speed(vector.new(0,0,0))
        self.object:set_acceleration(vector.new(0,0,0))
        return
      end
    end
    
    local curr_pos = self.object:get_pos()
    local curr_vel = self.object:get_velocity()
    local curr_rot = self.object:get_rotation()
    --local curr_acc = self.object:get_acceleration()
    local curr_acc = rocket.get_gravity_vector(curr_pos)
    
    -- set attached
    local is_attached = false
    if player then
      local player_attach = player:get_attach()
      if player_attach then
        if player_attach == self.seat then
          is_attached = true
        else
          self.driver_name = nil
        end
      else
        -- probably by engine error player has been detached, so attach him
        attach_player(self, player)
      end
    end
    
    -- update collision box
    local curr_dir = vector.rotate({x=0,y=1,z=0},curr_rot)
    local angle = vector.angle(curr_dir, vector.add(curr_vel, vector.multiply(curr_acc, dtime)))
    local box = 0
    if (angle<(0.4*math.pi)) then
      box = 2.5
    elseif (angle>(0.6*math.pi)) then
      box = -2.20
      if self.data_stage_1 then
        box = -8.0
      end
    end
    if (self.box~=box) then
      print("box: "..box.." angle: "..angle)
      local move = vector.multiply(curr_dir, box)
      local props = self.object:get_properties()
      props.collisionbox = {-1+move.x,-1+move.y,-1+move.z,1+move.x,1+move.y,1+move.z}
      self.object:set_properties(props)
      self.box = box
    end
    -- check for collisions via raycast
    --[[
    local pos_top = vector.add(curr_pos, vector.multiply(curr_dir, 3))
    local pos_bottom = -3
    if self.data_stage_1 then
      pos_bottom = -9
    end
    pos_bottom = vector.add(curr_pos, vector.multiply(curr_dir, pos_bottom))
    local raycast = minetest.raycast(pos_top, pos_bottom, false, false)
    for box in raycast do
      curr_acc = {x=0,y=0,z=0}
      self.object:set_velocity({x=0,y=0,z=0})
      break
    end
    --]]
    
    local on_gear = false
    local no_rotate = moveresult.collides
    
    if moveresult.collides then
      --print(dump(moveresult))
      local gear_damage = 0
      local damage = 0
      for _, collision in pairs(moveresult.collisions) do
        local diff = vector.subtract(self.last_vel, collision.new_velocity)
        local collvec = nil
        if (collision.type=="node") then
          collvec = vector.subtract(collision.node_pos, curr_pos)
        else
          collvec = vector.subtract(collision.object:get_pos(), curr_pos)
        end
        local angle = vector.angle(curr_dir, collvec)
        if (angle>(0.6*math.pi)) then
          gear_damage = gear_damage + vector.length(diff)*rocket.COLLISION_SPEED_DAMAGE
          on_gear = true
        else
          damage = damage + vector.length(diff)*rocket.COLLISION_SPEED_DAMAGE
        end
      end
      if self.stage.hull_integrity then
        if (gear_damage>self.stage.gear_limit) then
          damage = damage  + gear_damage - self.stage.gear_limit
          self.gear_limit = 0
        end
        self.stage.hull_integrity = self.stage.hull_integrity - damage
        if (damage>0) then
          print("hull_integrity: "..self.stage.hull_integrity.." damage: "..damage.." gear: "..gear_damage)
        end
      end
    end
    
    rocket.update_screen(self, curr_rot, curr_dir, curr_vel, on_gear)
    
    if is_attached then
      local impact = 0
      --print(dump(moveresults))
      if impact > 1 then
        minetest.sound_play("staged_cocket_rocket_collision", {
          to_player = self.driver_name,
          --pos = curr_pos,
          --max_hear_distance = 5,
          gain = 1.0,
          fade = 0.0,
          pitch = 1.0,
        })
        if self.hull_integrity then
          self.hull_integrity = self.hull_integrity - impact
          if (self.hull_integrity <= 0) then
            --minetest.sound_play("rocket_hull_break", {
            minetest.sound_play("default_break_glass", {
              to_player = self.driver_name,
              --pos = curr_pos,
              --max_hear_distance = 5,
              gain = 2,
              fade = 0.0,
              pitch = 1.0,
            })
            stage_destroy(self, player, true)
            return
          end
        end
      end
      --control
      curr_rot, curr_acc = rocket.control(self, dtime, curr_pos, curr_vel, curr_rot, curr_acc)  
    else
      -- for some engine error the player can be detached from the submarine, so lets set him attached again
      local can_stop = true
      if self.owner and self.driver_name then
        -- attach the driver again
        if player then
          attach_player(self, player)
          can_stop = false
        end
      end

      if can_stop then
        --detach player
        if self.sound_handle ~= nil then
          minetest.sound_stop(self.sound_handle)
          self.sound_handle = nil
        end
      end
    end

    -- air consumption
    if is_attached then
      if (self.stage.air > 0) then
        self.stage.air = self.stage.air - dtime;
        
        self.breath_time = self.breath_time + dtime
        if (self.breath_time>=0.5) then
          local times = math.floor(self.breath_time/0.5)
          local breath = player:get_breath() + 1*times
          local max_breath = player:get_properties().breath_max
          if (breath<=max_breath) then
            player:set_breath(breath+1)
          end
          self.breath_time = self.breath_time - 0.5*times
        end
      else
        self.breath_time = self.breath_time + dtime
        self.drown_time = self.drown_time + dtime
        if (self.breath_time>=0.3) then
          local times = math.floor(self.breath_time/0.3)
          local pos = player:get_pos()
          pos.y = pos.y + 1
          local node = minetest.get_node_or_nil(pos)
          if node then
            node = minetest.registered_nodes[node.name]
          end
          local breath = player:get_breath()
          if (node==nil) or (node.drowning==0) then
            breath = breath - 1*times
            if (breath<=0) then
              breath = 0
              if (self.drown_time>=2) then
                self.drown_time = 0
                print(self.drown_time)
                local hp = player:get_hp()
                hp = hp - 1
                player:set_hp(hp, {type="drown"})
              end
            end
            player:set_breath(breath)
          end
          self.breath_time = self.breath_time - 0.3*times
        end
      end
    end
    
    if self.data_stage_1 then
      rocket.update_fuel_pointer(self, self.data_stage_1)
      rocket.update_oxidizer_pointer(self, self.data_stage_1)
    else
      rocket.update_fuel_pointer(self, self.stage)
      rocket.update_oxidizer_pointer(self, self.stage)
    end
    rocket.update_air_pointer(self, self.stage)
    rocket.update_battery_pointer(self, self.stage)
    
    curr_acc, curr_rot = rocket.physics(self, dtime, curr_acc, curr_rot)
    
    self.object:set_acceleration(curr_acc)
    self.object:set_rotation(curr_rot)
    --print(dump(curr_acc))
    --print(dump(curr_vel))
    
    self.last_vel = self.object:get_velocity()
  end,

  on_punch = function(self, puncher, ttime, toolcaps, dir, damage)
    if not puncher or not puncher:is_player() then
      return
    end
    local name = puncher:get_player_name()
    if self.owner and self.owner ~= name and self.owner ~= "" then return end
    if self.owner == nil then
      self.owner = name
    end
      
    if self.driver_name and self.driver_name ~= name then
      -- do not allow other players to remove the object while there is a driver
      return
    end
    
    local is_attached = false
    if puncher:get_attach() == self.object then
      is_attached = true
    end

    local itmstck=puncher:get_wielded_item()
    local item_name = ""
    if itmstck then item_name = itmstck:get_name() end

    if is_attached == true then
      --refuel
      staged_rocket.load_fuel(self, puncher:get_player_name())
      self.engine_running = true
      --reair
      if staged_rocket.have_air then
        staged_rocket.load_air(self, puncher:get_player_name())
      end
    end

    if is_attached == false then

      -- deal with painting or destroying
      if itmstck then
        local _,indx = item_name:find('dye:')
        if indx then

          --lets paint!!!!
          local color = item_name:sub(indx+1)
          local colstr = staged_rocket.colors[color]
          --minetest.chat_send_all(color ..' '.. dump(colstr))
          if colstr then
            staged_rocket.paint(self, colstr)
            itmstck:set_count(itmstck:get_count()-1)
            puncher:set_wielded_item(itmstck)
          end
          -- end painting

        else -- deal damage
          if not self.driver_name and toolcaps and toolcaps.damage_groups and
              toolcaps.damage_groups.fleshy then
            --mobkit.hurt(self,toolcaps.damage_groups.fleshy - 1)
            --mobkit.make_sound(self,'hit')
            self.hp = self.hp - 10
            minetest.sound_play("collision", {
              object = self.object,
              max_hear_distance = 5,
              gain = 1.0,
              fade = 0.0,
              pitch = 1.0,
            })
          end
        end
      end

      if self.hp <= 0 then
        stage_destroy(self, player, false)
      end

    end
    
  end,

  on_rightclick = function(self, clicker)
    if not clicker or not clicker:is_player() then
      return
    end

    local name = clicker:get_player_name()
    if self.owner and self.owner ~= name and self.owner ~= "" then return end
    if self.owner == "" then
      self.owner = name
    end

    if name == self.driver_name then
      self.engine_running = false
      
      detach_player(self, clicker)
      open_airlock(self, clicker)
      -- driver clicked the object => driver gets off the vehicle
      --self.object:set_properties({glow = 0})
      self.driver_name = nil
      -- sound and animation
      if self.sound_handle then
        minetest.sound_stop(self.sound_handle)
        self.sound_handle = nil
      end
      
      --self.engine:set_animation_frame_speed(0)

      
    elseif not self.driver_name then
      -- no driver => clicker is new driver
      attach_player(self, clicker)
      open_airlock(self, clicker)
    end
  end,
})

