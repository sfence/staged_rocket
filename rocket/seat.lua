
local orcket = staged_rocket.rocket

minetest.register_entity("staged_rocket:rocket_seat",{
  initial_properties = {
    physical = false,
    collide_with_objects=false,
    pointable=false,
    visual = "mesh",
    mesh = "staged_rocket_rocket_dummy.obj",
    textures = {"staged_rocket_rocket_transparent.png"},
    static_save = false,
  },
})

