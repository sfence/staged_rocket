
local rocket = staged_rocket.rocket

rocket.COLLISION_SPEED_DAMAGE = minetest.settings:get("staged_rocket_rocket_collision_speed_damage") or 100

rocket.STAGE_1_FUEL_CONSUMPTION = minetest.settings:get("staged_rocket_rocket_stage_1_fuel_consumption") or 1
rocket.STAGE_1_THRUST = minetest.settings:get("staged_rocket_rocket_stage_1_thrust") or 1


rocket.STAGE_ORBITAL_FUEL_CONSUMPTION = minetest.settings:get("staged_rocket_rocket_stage_orbital_fuel_consumption") or 1
rocket.STAGE_ORBITAL_THRUST = minetest.settings:get("staged_rocket_rocket_stage_orbital_thrust") or 1
rocket.STAGE_ORBITAL_AIR_CONSUMPTION = minetest.settings:get("staged_rocket_rocket_stage_orbital_air_consumption") or 1
rocket.STAGE_ORBITAL_BATTERY_CONSUMPTION = minetest.settings:get("staged_rocket_rocket_stage_orbital_battery_consumption") or 1
rocket.STAGE_ORBITAL_REAIR_ON_AIR = minetest.settings:get("staged_rocket_rocket_stage_orbital_reair_on_air") or 200
rocket.STAGE_ORBITAL_OPEN_AIR_LOST = minetest.settings:get("staged_rocket_rocket_stage_orbital_open_air_lost") or 25

