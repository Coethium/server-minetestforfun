local time = tonumber(minetest.setting_get("remove_items"))
if not time then
	time = 600
end

unwalkable_nodes = {}

minetest.after(0, function()
	for itemname, node in pairs(minetest.registered_nodes) do
		if node.walkable == false then
			table.insert(unwalkable_nodes, 1, itemname)
		end
	end
end)

local get_flowing_dir = function(self)
	local pos = self.object:getpos()
	local param2 = minetest.get_node(pos).param2
	for i,d in ipairs({-1, 1, -1, 1}) do
		if i<3 then
			pos.x = pos.x+d
		else
			pos.z = pos.z+d
		end

		local name = minetest.get_node(pos).name
		local par2 = minetest.get_node(pos).param2
		if name == "default:water_flowing" and par2 < param2 then
			return pos
		end

		if i<3 then
			pos.x = pos.x-d
		else
			pos.z = pos.z-d
		end
	end
	return nil
end

minetest.register_entity(":__builtin:item", {
	initial_properties = {
		hp_max = 1,
		physical = true,
		collisionbox = {-0.175, -0.175, -0.175, 0.175, 0.175, 0.175},
		collide_with_objects = false,
		visual = "sprite",
		visual_size = {x=0.5, y=0.5},
		textures = {""},
		spritediv = {x=1, y=1},
		initial_sprite_basepos = {x=0, y=0},
		is_visible = false,
		timer = 0,
	},

	itemstring = "",
	physical_state = true,

	set_item = function(self, itemstring)
		self.itemstring = itemstring
		local stack = ItemStack(itemstring)
		local itemtable = stack:to_table()
		local itemname = nil
		if itemtable then
			itemname = stack:to_table().name
		end
		local item_texture = nil
		local item_type = ""
		if minetest.registered_items[itemname] then
			item_texture = minetest.registered_items[itemname].inventory_image
			item_type = minetest.registered_items[itemname].type
		end
		local prop = {
			is_visible = true,
			visual = "wielditem",
			textures = {(itemname or "unknown_item.png")},
			visual_size = {x=0.175, y=0.175},
			automatic_rotate = math.pi * 0.5,
		}
		self.object:set_properties(prop)
	end,

	get_staticdata = function(self)
		--return self.itemstring
		return minetest.serialize({
			itemstring = self.itemstring,
			always_collect = self.always_collect,
			timer = self.timer,
		})
	end,

	on_activate = function(self, staticdata, dtime_s)
		if string.sub(staticdata, 1, string.len("return")) == "return" then
			local data = minetest.deserialize(staticdata)
			if data and type(data) == "table" then
				self.itemstring = data.itemstring
				self.always_collect = data.always_collect
				self.timer = data.timer
				if not self.timer then
					self.timer = 0
				end
				self.timer = self.timer+dtime_s
			end
		else
			self.itemstring = staticdata
		end
		self.object:set_armor_groups({immortal=1})
		self.object:setvelocity({x=0, y=2, z=0})
		self.object:setacceleration({x=0, y=-10, z=0})
		self:set_item(self.itemstring)
	end,

	on_step = function(self, dtime)
		if not self.timer then
			self.timer = 0
		end
		self.timer = self.timer + dtime
		if self.itemstring == "" or (time ~= 0 and (self.timer > time)) then
			self.object:remove()
			return
		end

		local p = self.object:getpos()

		local name = minetest.get_node(p).name
		if not minetest.registered_nodes[name] then return end
		if minetest.registered_nodes[name].damage_per_second > 0 or name == "maptools:igniter" then
			minetest.sound_play("builtin_item_lava", {pos = p, gain = 0.5})
			self.object:remove()
			return
		end

		--[[ if name == "default:water_source" then
			self.object:setacceleration({x = 0, y = 4, z = 0})
		else
			self.object:setacceleration({x = 0, y = -10, z = 0})
		end
		--]]

		if minetest.registered_nodes[name].liquidtype == "flowing" then
			local vec = get_flowing_dir(self)
			if vec then
				local v = self.object:getvelocity()
				if v and vec.x-p.x > 0 then
					self.object:setacceleration({x = 0, y = 0, z = 0})
					self.object:setvelocity({x = 1, y = -0.22, z = 0})
				elseif v and vec.x-p.x < 0 then
					self.object:setacceleration({x = 0, y = 0, z = 0})
					self.object:setvelocity({x = -1, y = -0.22, z = 0})
				elseif v and vec.z-p.z > 0 then
					self.object:setacceleration({x = 0, y = 0, z = 0})
					self.object:setvelocity({x = 0, y = -0.22, z = 1})
				elseif v and vec.z-p.z < 0 then
					self.object:setacceleration({x = 0, y = 0, z = 0})
					self.object:setvelocity({x = 0, y = -0.22, z = -1})
				end

				self.object:setacceleration({x = 0, y = -10, z = 0})
				self.physical_state = true
				self.object:set_properties({
					physical = true
				})
				return
			end
		end

		p.y = p.y - 0.3
		local nn = minetest.get_node(p).name
		-- If node is not registered or node is walkably solid.
		if not minetest.registered_nodes[nn] or minetest.registered_nodes[nn].walkable then
			if self.physical_state then
				self.object:setvelocity({x=0,y=0,z=0})
				self.object:setacceleration({x=0, y=0, z=0})
				self.physical_state = false
				self.object:set_properties({
					physical = false
				})
			end
		else
			if not self.physical_state then
				self.object:setvelocity({x=0,y=0,z=0})
				self.object:setacceleration({x=0, y=-10, z=0})
				self.physical_state = true
				self.object:set_properties({
					physical = true
				})
			end
		end

		-- Eject if not walkable
		local upnode = minetest.get_node({x = p.x, y = math.ceil(p.y), z = p.z}).name
		if minetest.registered_nodes[upnode] and minetest.registered_nodes[upnode].walkable then
			local minp, maxp = {x=p.x-1, y=math.ceil(p.y), z=p.z-1}, {x=p.x+1, y=math.ceil(p.y)+1, z=p.z+1}
			local nodes = minetest.find_nodes_in_area(minp, maxp, unwalkable_nodes)
			if table.getn(nodes) > 0 then
				self.object:setpos(nodes[math.random(1,#nodes)])
			end
		end
	end,
	--[[ This causes a duplication glitch if a player walks upon an item and clicks on it at the same time.
	on_punch = function(self, hitter)
		if self.itemstring ~= "" then
			local left = hitter:get_inventory():add_item("main", self.itemstring)
			if not left:is_empty() then
				self.itemstring = left:to_string()
				return
			end
		end
		self.object:remove()
	end,
	--]]
})

if minetest.setting_get("log_mods") then
	minetest.log("action", "[builtin_item] loaded.")
end
