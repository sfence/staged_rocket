
local rocket = staged_rocket.rocket

local min = math.min
local abs = math.abs

function rocket.physics(self, dtime, curr_acc, curr_rot)
  local engine_stage = self.stage
  if self.data_stage_1 then
    engine_stage = self.data_stage_1
  end
  
  if engine_stage.engine_started then
    local acc = engine_stage.engine_power*engine_stage.engine_thrust
    local curr_dir = vector.rotate(vector.new(0,1,0), curr_rot)
  end
end
