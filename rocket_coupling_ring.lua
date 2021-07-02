
local rocket = staged_rocket.rocket

--
-- entity
--

minetest.register_entity("staged_rocket:rocket_coupling_ring", {
  initial_properties = {
    physical = true,
    collisionbox = {-1, -0.3, -1, 1, 0.3, 1},
    selectionbox = {-1, -0.3, -1, 1, 0.3, 1},
    visual = "mesh",
    mesh = "staged_rocket_rocket_coupling_ring.b3d",
	  textures = {"staged_rocket_rocket_black.png"},
  },
  textures = {},
  sound_handle = nil,
  static_save = true,
  infotext = "A rocket coupling ring",
  lastvelocity = vector.new(),
  hp = 50,
  color = "#ffe400",
  timeout = 0,
  max_hp = 50,
  physics = staged_rocket.physics,
  
  is_attached = false,
  
  stage = {
    mass = 1000,
    front_drag = 0.1,
    side_drag = 1,
    back_drag = 0.1,
    
    drop_disassemble = {},
    drop_destroy = {},
    hull_integrity = nil,
    max_hull = nil,
  },
  
  get_staticdata = function(self)
    print("static ring: "..dump(self))
    return minetest.serialize({
      hp = self.hp,
      color = self.color,
      is_attached = self.is_attached,
      stage = self.stage,
    })
  end,

  on_activate = function(self, staticdata, dtime_s)
    if staticdata ~= "" and staticdata ~= nil then
      local data = minetest.deserialize(staticdata) or {}
      print("ring "..dump(data))
      if data.is_attached then
        print("remove attached ring "..dump(self.object:get_properties()))
        self.object:remove()
        return
      end
      self.hp = data.hp
      self.color = data.color
      self.stage = data.stage
    end

    staged_rocket.paint(self, self.color)
    local pos = self.object:get_pos()

    self.object:set_armor_groups({immortal=1})

    local children = self.object:get_attach()
    print(dump(children))
  end,

  on_step = function(self, dtime, moveresults)
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
        rocket.destroy(self, false)
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
    elseif (wield_name=="staged_rocket:rocket_stage_orbital") and self.have_coupling_ring then
      
      place_stage_orbital(self, wield)
      clicker:set_wielded_item(wield)
    end
  end,
})
