
local rocket = staged_rocket.rocket

local good_color = {r=0,g=255,b=0}
local bad_color = {r=255,g=0,b=0}

local function colortable_to_colorstring(colortable)
  return string.format("#%02X%02X%02X", colortable.r, colortable.g, colortable.b)
end

local function get_color(good)
  local bad = 1 - good
  local color = {r=0,g=0,b=0}
  for key,col in pairs(good_color) do
    col = math.floor(good*col + bad*bad_color[key])
    if (col<0) then
      col = 0
    end
    if (col>255) then
      col = 255
    end
    color[key] = col
  end
  --return minetest.colorspec_to_colorstring(color)
  return colortable_to_colorstring(color)
end

function rocket.update_screen(self)
  local stage = self.stage
  local screen = "stage_rocket_rocket_black.png" -- power off screen
  if (stage.battery>0) and stage.screen then
    screen = "staged_rocket_rocket_screen_bck.png"
    local sensors = nil
    local engine_stage = stage
    if self.data_stage_1 then
      engine_stage = self.data_stage_1
    end
    
    local curr_pos = self.object:get_pos()
    local curr_rot = self.object:get_rotation()
    local curr_dir = vector.rotate(vector.new(0,1,0), curr_rot)
    local curr_vel = self.object:get_velocity()
    
    if self.data_coupling_ring then
      local CP = 1
      if self.data_coupling_ring.hull_integrity then
        CP = self.data_coupling_ring.hull_integrity/self.data_coupling_ring.max_hull
      end
      screen = screen .. "^(staged_rocket_rocket_screen_CR.png^[multiply:"..get_color(CP)..")"
    end
    if self.data_stage_1 then
      local S1 = 1
      if engine_stage.hull_integrity then
        S1 = engine_stage.hull_integrity/engine_stage.max_hull
      end
      
      screen = screen .. "^(staged_rocket_rocket_screen_S1.png^[multiply:"..get_color(S1)..")"
      
      if engine_stage.screen_sensors then
        S1 = engine_stage.fuel/engine_stage.max_fuel
        screen = screen .. "^(staged_rocket_rocket_screen_S1_F.png^[multiply:"..get_color(S1)..")"
        S1 = engine_stage.oxidizer/engine_stage.max_oxidizer
        screen = screen .. "^(staged_rocket_rocket_screen_S1_O.png^[multiply:"..get_color(S1)..")"
      end
    end
    --if self.data_stage_orbital then
      local SO = 1
      if stage.hull_integrity then
        SO = stage.hull_integrity/stage.max_hull
      end
      
      screen = screen .. "^(staged_rocket_rocket_screen_SO.png^[multiply:"..get_color(SO)..")"
      
      if stage.screen_sensors then
        SO = stage.fuel/stage.max_fuel
        screen = screen .. "^(staged_rocket_rocket_screen_SO_F.png^[multiply:"..get_color(SO)..")"
        SO = stage.oxidizer/stage.max_oxidizer
        screen = screen .. "^(staged_rocket_rocket_screen_SO_O.png^[multiply:"..get_color(SO)..")"
        SO = stage.air/stage.max_air
        screen = screen .. "^(staged_rocket_rocket_screen_SO_A.png^[multiply:"..get_color(SO)..")"
        SO = stage.battery/stage.max_battery
        screen = screen .. "^(staged_rocket_rocket_screen_SO_B.png^[multiply:"..get_color(SO)..")"
        local color = "00FF00"
        if (stage.gear_limit==0) then
          color = "FF0000"
        end
        if (false) then -- touching ground
          color = "FFA600"
        end
        screen = screen .. "^(staged_rocket_rocket_screen_G.png^[multiply:#"..color..")"
      end
    --end
    
    if stage.screen_sensors then
      local color = "FF0000"
      if (engine_stage.engine_power>0) then
        color = "00FF00"
      end
      if (self.data_coupling_ring~=nil) and (self.data_stage_1==nil) then
        color = "FFA600"
      end
      screen = screen .. "^(staged_rocket_rocket_screen_E.png^[multiply:#"..color..")"
    end
    
    if stage.screen_speedometer then
      if (sensors==nil) then
        sensors = "^[combine:64x64"
      end
      -- 10, 14, 24
      local speedy = -vector.length(curr_vel)*math.cos(vector.angle(curr_dir, curr_vel))
      local gearlim = stage.gear_limit/rocket.COLLISION_SPEED_DAMAGE
      local drawy = 14 + math.floor(speedy/gearlim+0.5)
      if (drawy<10) then
        drawy = 10
      end
      if (drawy>24) then
        drawy = 24
      end
      sensors = sensors .. ":3,"..drawy.."=staged_rocket_rocket_screen_vertical_pointer.png"
    end
    if stage.screen_altimeter then
      if (sensors==nil) then
        sensors = "^[combine:64x64"
      end
      -- 10, 24
      local drawy = 24 - math.floor(rocket.get_altitude(curr_pos)/10+0.5)
      if (drawy<10) then
        drawy = 10
      end
      if (drawy>24) then
        drawy = 24
      end
      sensors = sensors .. ":7,"..drawy.."=staged_rocket_rocket_screen_vertical_pointer.png"
    end
    
    if stage.screen_gyroscope then
      if (sensors==nil) then
        sensors = "^[combine:64x64"
      end
      screen = screen .. "^(staged_rocket_rocket_screen_horizont.png)"
      
    end
    if stage.screen_radar then
      if (sensors==nil) then
        sensors = "^[combine:64x64"
      end
      screen = screen .. "^(staged_rocket_rocket_screen_radar.png)"
    end
    if (stage.screen_lidar_sides>0) then
      if (sensors==nil) then
        sensors = "^[combine:64x64"
      end
      screen = screen .. "^(staged_rocket_rocket_screen_lidar_sides.png)"
      
      -- front
      local curr_front = vector.rotate(vector.new(-1,0,0), curr_rot)
      local curr_right = vector.rotate(vector.new(0,0,1), curr_rot)
      
      local pos1 = vector.add(curr_pos, vector.multiply(curr_front, 1.5))
      local pos2 = vector.add(pos1, vector.multiply(curr_front, stage.screen_lidar_sides))
      local raycast = minetest.raycast(pos1, pos2, true, true)
      for ray in raycast do
        local distance = vector.distance(pos1, ray.intersection_point)
        local drawy = 23+math.floor(7*distance/engine_stage.screen_lidar_bottom)
        sensors = sensors .. ":24,"..drawy.."=staged_rocket_rocket_screen_lidar_found.png"
        break
      end
      -- back
      pos1 = vector.add(curr_pos, vector.multiply(curr_front, -1.5))
      pos2 = vector.add(pos1, vector.multiply(curr_front, -stage.screen_lidar_sides))
      raycast = minetest.raycast(pos1, pos2, true, true)
      for ray in raycast do
        local distance = vector.distance(pos1, ray.intersection_point)
        local drawy = 23-math.floor(7*distance/engine_stage.screen_lidar_bottom)
        sensors = sensors .. ":24,"..drawy.."=staged_rocket_rocket_screen_lidar_found.png"
        break
      end
      -- right
      local pos1 = vector.add(curr_pos, vector.multiply(curr_right, 1.5))
      local pos2 = vector.add(pos1, vector.multiply(curr_right, stage.screen_lidar_sides))
      local raycast = minetest.raycast(pos1, pos2, true, true)
      for ray in raycast do
        local distance = vector.distance(pos1, ray.intersection_point)
        local drawx = 24+math.floor(7*distance/engine_stage.screen_lidar_bottom)
        sensors = sensors .. ":"..drawx..",23=staged_rocket_rocket_screen_lidar_found.png"
        break
      end
      -- left
      local pos1 = vector.add(curr_pos, vector.multiply(curr_right, -1.5))
      local pos2 = vector.add(pos1, vector.multiply(curr_right, -stage.screen_lidar_sides))
      local raycast = minetest.raycast(pos1, pos2, true, true)
      for ray in raycast do
        local distance = vector.distance(pos1, ray.intersection_point)
        local drawx = 24-math.floor(7*distance/engine_stage.screen_lidar_bottom)
        sensors = sensors .. ":"..drawx..",23=staged_rocket_rocket_screen_lidar_found.png"
        break
      end
    end
    if (engine_stage.screen_lidar_bottom>0) or (stage.screen_lidar_top>0) then
      if (sensors==nil) then
        sensors = "^[combine:64x64"
      end
      screen = screen .. "^(staged_rocket_rocket_screen_lidar_vertical.png)"
      if (engine_stage.screen_lidar_bottom>0) then
        local lidar_offset = -2.25
        if self.data_stage_1 then
          lidar_offset = -8.5
        end
        local pos1 = vector.add(curr_pos, vector.multiply(curr_dir, lidar_offset))
        local pos2 = vector.add(pos1, vector.multiply(curr_dir, -stage.screen_lidar_bottom))
        local raycast = minetest.raycast(pos1,pos2, true, true)
        for ray in raycast do
          local distance = vector.distance(pos1, ray.intersection_point)
          local drawy = 25+math.floor(6*distance/engine_stage.screen_lidar_bottom)
          sensors = sensors .. ":14,"..drawy.."=staged_rocket_rocket_screen_lidar_found.png"
          break
        end
        
      end
      if (stage.screen_lidar_top>0) then
        local pos1 = vector.add(curr_pos, vector.multiply(curr_dir, 2.5))
        local pos2 = vector.add(pos1, vector.multiply(curr_dir, stage.screen_lidar_top))
        local raycast = minetest.raycast(pos1,pos2, true, true)
        for ray in raycast do
          local distance = vector.distance(pos1, ray.intersection_point)
          local drawy = 19-math.floor(6*distance/engine_stage.screen_lidar_bottom)
          sensors = sensors .. ":14,"..drawy.."=staged_rocket_rocket_screen_lidar_found.png"
          break;
        end
      end
    end
    
    if sensors then
      screen = "(" .. screen .. ")" .. sensors
    end
    --print(screen)
  end
  local props = self.object:get_properties()
  props.textures[17] = screen
  self.object:set_properties(props)
end 

