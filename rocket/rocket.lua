
staged_rocket.rocket = {}

local rocket = staged_rocket.rocket

local modpath = minetest.get_modpath(minetest.get_current_modname())

rocket.fuel = {
  ['biofuel:phial_fuel'] = {
    amount=0.25
  },
  ['biofuel:bottle_fuel'] = {
    amount=1
  },
  ['biofuel:fuel_can'] = {
    amount=10
  },
}
rocket.oxidizer = {
  ['vacuum:air_bottle'] = {
    amount=100,
    drop="vessels:steel_bottle",
  },
}
rocket.air = {
  ['vacuum:air_bottle'] = {
    amount=100,
    drop="vessels:steel_bottle",
  },
}

dofile(modpath .. "/rocket/settings.lua")
dofile(modpath .. "/rocket/functions.lua")
dofile(modpath .. "/rocket/environment.lua")
dofile(modpath .. "/rocket/control.lua")
dofile(modpath .. "/rocket/fuel_management.lua")
dofile(modpath .. "/rocket/oxidizer_management.lua")
dofile(modpath .. "/rocket/air_management.lua")
dofile(modpath .. "/rocket/battery_management.lua")
dofile(modpath .. "/rocket/screen.lua")
dofile(modpath .. "/rocket/physics.lua")
dofile(modpath .. "/rocket/stage_1.lua")
dofile(modpath .. "/rocket/coupling_ring.lua")
dofile(modpath .. "/rocket/stage_orbital.lua")
dofile(modpath .. "/rocket/seat.lua")
dofile(modpath .. "/rocket/items.lua")

