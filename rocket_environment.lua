
local rocket = staged_rocket.rocket

-- override this function for different worlds
function rocket.get_gravity_vector(pos)
  -- 1/(1+C^x)
  local y = 9.81 * (1/(1+1.01^(pos.y-1000)))
  return {x=0,y=-y,z=0}
end

function rocket.get_altitude(pos)
  return pos.y
end

