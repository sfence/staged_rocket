
local rocket = staged_rocket.rocket

--
-- entity
--

local function place_coupling_ring(self, itemstack)
  local pos = self.object:get_pos()
  local ring = minetest.add_entity(pos, "staged_rocket:rocket_coupling_ring")
  if ring then
    local ent = ring:get_luaentity()
    local item_def = itemstack:get_definition()
    local wear = (65535-itemstack:get_wear())/65535
    if (item_def.hull_integrity) then
      ent.hull_integrity = item_def.hull_integrity*wear
    end
    ent.stage.item = itemstack:to_string()
    ring:set_yaw(self.object:get_yaw())
    ring:set_attach(self.object, "", {x=0,y=31.5,z=0},{x=0,y=0,z=0})
    ent.is_attached = true
    self.data_coupling_ring = ent.stage
    self.object_coupling_ring = ring
    itemstack:take_item()
  end
end

local function place_stage_orbital(self, itemstack)
  local pos = self.object:get_pos()
  pos.y = pos.y + 6
  local orbital = minetest.add_entity(pos, "staged_rocket:rocket_stage_orbital")
  if orbital then
    local ent = orbital:get_luaentity()
    local item_def = itemstack:get_definition()
    local wear = (65535-itemstack:get_wear())/65535
    if (item_def.hull_integrity) then
      ent.hull_integrity = item_def.hull_integrity*wear
    end
    ent.stage.item = itemstack:to_string()
    orbital:set_yaw(self.object:get_yaw())
    self.object:set_attach(orbital, "", {x=0,y=-60,z=0},{x=0,y=0,z=0})
    self.object_coupling_ring:set_attach(orbital, "", {x=0,y=-28.5,z=0},{x=0,y=0,z=0})
    ent.data_coupling_ring = self.data_coupling_ring
    ent.object_coupling_ring = self.object_coupling_ring
    ent.data_stage_1 = self.stage
    ent.object_stage_1 = self.object
    self.is_attached = true
    self.data_coupling_ring = nil
    self.object_coupling_ring = nil
    itemstack:take_item()
  end
end

minetest.register_entity("staged_rocket:rocket_stage_1", {
  initial_properties = {
    physical = true,
    collisionbox = {-1, -1, -1, 1, 1, 1},
    selectionbox = {-1, -1, -1, 1, 1, 1},
    --selectionbox = {-0.6,0.6,-0.6, 0.6,1,0.6},
    visual = "mesh",
    mesh = "staged_rocket_rocket_stage_1.b3d",
	    textures = {"staged_rocket_rocket_white.png", --main body
                    "staged_rocket_rocket_black.png", --black or any color of checker painting
                    "staged_rocket_rocket_white.png", --white of checker painting
                    "staged_rocket_rocket_metal.png", --upper cap
                    "staged_rocket_rocket_white.png", --wings color
                    "staged_rocket_rocket_black.png", --wings secondary color
                    "staged_rocket_rocket_black.png", --engines
                    "staged_rocket_rocket_metal.png"}, --bottom cap
  },
  textures = {},
  sound_handle = nil,
  static_save = true,
  infotext = "A nice rocket stage 1",
  lastvelocity = vector.new(),
  hp = 50,
  color = "#ffe400",
  timeout = 0;
  max_hp = 50,
  physics = staged_rocket.physics,
  --water_drag = 0,
  breath_time = 0,
  drown_time = 0,
  
  is_attached = false,
  data_coupling_ring = nil,
  object_coupling_ring = nil,
  
  stage = {
    fuel = 10000, -- volume of fuel
    consume_fuel = 1, -- fuel quality (higger value, more fuel is required for get same thrust
    require_oxidant = 1, -- volume of oxidant required to burn 1 unit of fuel
    max_fuel = 10000, -- fuel capacity
    oxidizer = 30000, -- volume of oxidant
    consume_oxidant = 1, -- oxidant quality (higger value, more oxidant is required for get same thrust)
    max_oxidizer = 30000, -- oxidizer capacity
    hull_integrity = nil,
    item = "staged_rocket:rocket_stage_1",
    
    engine_power = 10, -- can be replaced by zero until engines will be installed
    engine_consume = 1, -- how much fuel engine consume
    engine_started = false, -- if engine is running
    engine_restart = 0, -- energy for engine start, 0 for one time startable engine
    thrust = 1, -- actual engine thrust
    step_thrust = 0.05, -- sensitivity of engine thurst change
    min_thrust = 0.8, -- lowest settable thrust of engin
    
    screen_sensors = true, -- sensors in installed
    screen_lidar_bottom = 50, -- lidar defined by range
  },

  get_staticdata = function(self)
    print("static stage 1")
    return minetest.serialize({
      hp = self.hp,
      color = self.color,
      is_attached = self.is_attached,
      data_coupling_ring = self.data_coupling_ring,
      stage = self.stage,
    })
  end,

  on_activate = function(self, staticdata, dtime_s)
    if staticdata ~= "" and staticdata ~= nil then
      local data = minetest.deserialize(staticdata) or {}
      if data.is_attached then
        self.object:remove()
        return
      end
      self.hp = data.hp
      self.color = data.color
      self.stage = data.stage
      if data.data_coupling_ring then
        rocket.restore_coupling_ring(self, data.data_coupling_ring, dtime_s)
      end
    end

    staged_rocket.paint(self, self.color)
    local pos = self.object:get_pos()

    self.object:set_armor_groups({immortal=1})
  end,

  on_step = function(self, dtime)
    
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
        staged_rocket.destroy(self, false)
      end

    end
    
  end,

  on_rightclick = function(self, clicker)
    if not clicker or not clicker:is_player() then
      return
    end
    
    local wield = clicker:get_wielded_item()
    local wield_name = wield:get_name()
    
    if (wield_name=="staged_rocket:rocket_coupling_ring") then
      place_coupling_ring(self, wield)
      clicker:set_wielded_item(wield)
    elseif (wield_name=="staged_rocket:rocket_stage_orbital") and self.data_coupling_ring then
      
      place_stage_orbital(self, wield)
      clicker:set_wielded_item(wield)
    end
  end,
})