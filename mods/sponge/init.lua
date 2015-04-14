minetest.register_node("sponge:sponge", {
	description = "Sponge Dry",
	drawtype = "normal",
	tiles = {"sponge_sponge.png"},
	paramtype = 'light',
	walkable = true,
	pointable = true,
	diggable = true,
	buildable_to = false,
	stack_max = 99,
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=3,flammable=3},
	   	on_place = function(itemstack, placer, pointed_thing)
		local pn = placer:get_player_name()
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		if minetest.is_protected(pointed_thing.above, pn) then
			return itemstack
		end
			local change = false
			local on_water = false
			local pos = pointed_thing.above
		-- verifier si il est dans l'eau ou a cotée
		if string.find(minetest.get_node(pointed_thing.above).name, "water_source") 
		or  string.find(minetest.get_node(pointed_thing.above).name, "water_flowing") then
			on_water = true
		end
		for i=-1,1 do
			p = {x=pos.x+i, y=pos.y, z=pos.z}
			n = minetest.get_node(p)
			-- On verifie si il y a de l'eau
			if (n.name=="default:water_flowing") or (n.name == "default:water_source") then
				on_water = true
			end
		end
		for i=-1,1 do
			p = {x=pos.x, y=pos.y+i, z=pos.z}
			n = minetest.get_node(p)
			-- On verifie si il y a de l'eau
			if (n.name=="default:water_flowing") or (n.name == "default:water_source") then
				on_water = true
			end
		end
		for i=-1,1 do
			p = {x=pos.x, y=pos.y, z=pos.z+i}
			n = minetest.get_node(p)
			-- On verifie si il y a de l'eau
			if (n.name=="default:water_flowing") or (n.name == "default:water_source") then
				on_water = true
			end
		end
		
			if on_water == true then
				for i=-3,3 do
					for j=-3,3 do
						for k=-3,3 do
							p = {x=pos.x+i, y=pos.y+j, z=pos.z+k}
							n = minetest.get_node(p)
							-- On Supprime l'eau
							if (n.name=="default:water_flowing") or (n.name == "default:water_source")then
								minetest.add_node(p, {name="air"})
								change = true
							end
						end
					end
				end
			end
			p = {x=pos.x, y=pos.y, z=pos.z}
			n = minetest.get_node(p)
			if change == true then
				minetest.add_node(pointed_thing.above, {name = "sponge:sponge_wet"})	
			else
				minetest.add_node(pointed_thing.above, {name = "sponge:sponge"})	
			end
		return itemstack
		
	end
})

minetest.register_node("sponge:sponge_wet", {
	description = "Wet Sponge",
	drawtype = "normal",
	tiles = {"sponge_sponge_wet.png"},
	paramtype = 'light',
	walkable = true,
	pointable = true,
	diggable = true,
	buildable_to = false,
	stack_max = 99,
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=3},
})

--Cooking the sponge wet to be a sponge dry (Back to the future sponge !) :D
minetest.register_craft({
	type = "cooking", output = "sponge:sponge", recipe = "sponge:sponge_wet",
})

-- Juste une proposition d'autre craft (comme c'est jaune et que ça a des trou)
--minetest.register_craft({
--output = "sponge:sponge",
--recipe = {
--{"", "dye:yellow", ""},
--{"dye:yellow", "", "dye:yellow"},
--{"dye:yellow", "dye:yellow", "dye:yellow"},
--},
--})


minetest.register_craft({
output = "sponge:sponge",
recipe = {
{"", "dye:black", ""},
{"", "wool:white", ""},
{"", "farming:wheat", ""},
},
})
