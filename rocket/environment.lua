
local rocket = staged_rocket.rocket

-- override this function for supports more worlds
function rocket.get_gravity_vector(pos)
  -- 1/(1+C^x)
  local y = 9.81 * (1/(1+1.01^(pos.y-1000)))
  return {x=0,y=-y,z=0}
end

-- default: only one world with see level at 0
function rocket.get_altitude(pos)
  return pos.y
end

-- default: preasure similar to Earth
function rocket.get_pressure(pos)
  -- ph = p0 * e^((-den0*h*g)/p0)
  -- ph - pressure in height y
  -- p0 - pressure in height 0
  -- den0 - density of air in height 0
  -- h - height
  -- g - gravity
  return 100000*math.exp(-1.4*pos.y*80*9.81/100000)
end

-- default: wind is disabled 
function rocket.get_wind(pos)
  return vector.new(0,0,0)
end 

