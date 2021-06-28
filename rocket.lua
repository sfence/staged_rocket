
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

dofile(modpath .. "/rocket_settings.lua")
dofile(modpath .. "/rocket_functions.lua")
dofile(modpath .. "/rocket_environment.lua")
dofile(modpath .. "/rocket_control.lua")
dofile(modpath .. "/rocket_fuel_management.lua")
dofile(modpath .. "/rocket_oxidizer_management.lua")
dofile(modpath .. "/rocket_air_management.lua")
dofile(modpath .. "/rocket_battery_management.lua")
dofile(modpath .. "/rocket_screen.lua")
dofile(modpath .. "/rocket_custom_physics.lua")
dofile(modpath .. "/rocket_stage_1.lua")
dofile(modpath .. "/rocket_coupling_ring.lua")
dofile(modpath .. "/rocket_stage_orbital.lua")
dofile(modpath .. "/rocket_items.lua")

