--
-- constants
--
local LONGIT_DRAG_FACTOR = 0.13*0.13
local LATER_DRAG_FACTOR = 2.0

local modpath = minetest.get_modpath(minetest.get_current_modname())

if (minetest.features.object_step_has_moveresult~=true) then
  error("Please use minetest which supports moveresults (version 5.3.0 and higger).")
end

staged_rocket={}

staged_rocket.colors ={
  black='#2b2b2b',
  blue='#0063b0',
  brown='#8c5922',
  cyan='#07B6BC',
  dark_green='#567a42',
  dark_grey='#6d6d6d',
  green='#4ee34c',
  grey='#9f9f9f',
  magenta='#ff0098',
  orange='#ff8b0e',
  pink='#ff62c6',
  red='#dc1818',
  violet='#a437ff',
  white='#FFFFFF',
  yellow='#ffe400',
}
  
dofile(modpath .. "/rocket/rocket.lua")

--
-- helpers and co.
--

--painting
function staged_rocket.paint(self, colstr)
  if colstr then
    self.color = colstr
    local l_textures = self.initial_properties.textures
    for _, texture in ipairs(l_textures) do
      local indx = texture:find('nautilus_painting.png')
      if indx then
        l_textures[_] = "nautilus_painting.png^[multiply:".. colstr
      end
    end
    self.object:set_properties({textures=l_textures})
  end
end

if minetest.settings:get_bool("rocket_variants", true) then
  --dofile(modpath .. DIR_DELIM .. "rocket_variants.lua")
end

