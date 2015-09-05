-----------------------------------------------------------------------------------------------
local title	= "Death Messages"
local version = "0.1.2"
local mname	= "death_messages"
-----------------------------------------------------------------------------------------------
dofile(minetest.get_modpath("death_messages").."/settings.txt")
-----------------------------------------------------------------------------------------------

-- A table of quips for death messages

local messages = {}

-- Another one to avoid double death messages
local whacked = {}

-- Fill this table with sounds
local sounds   = {
	[1] = "death_messages_player_1",
	[2] = "death_messages_player_2",
}

-- Lava death messages
messages.lava = {
	"%s thought lava was cool. / %s pensait que la lave etait cool.",
	"%s felt an urgent need to touch lava. / %s s'est sentit oblige de toucher la lave.",
	"%s fell in lava. / %s  est tombe dans la lave.",
	"%s died in lava. / %s  est mort(e) dans de la lave.",
	"%s didn't know lava was very hot. / %s ne savait pas que la lave etait vraiment chaude.",
	"%s destroyed Sauron's ring. / %s a detruit l'anneau de Sauron."
}

-- Drowning death messages
messages.water = {
	"%s lacked oxygen. / %s a manque d'air.",
	"%s tried to impersonate an anchor. / %s a essaye d'usurper l'identite d'une ancre.",
	"%s forgot they were not a fish. / %s a oublie qu'il n'etait pas un poisson.",
	"%s forgot they needed to breath underwater. / %s a oublier qu'il lui fallait respirer sous l'eau.",
	"%s isn't good at swimming. / %s n'est pas bon en natation.",
	"%s looked for the secret of the Unicorn. / %s a cherche le secret de la licorne.",
	"%s forgot their scaphander. / %s a oublie son scaphandre."
}

-- Burning death messages
messages.fire = {
	"%s was a bit too hot. / %s a eut un peu trop chaud.",
	"%s was too close to the fire. / %s a ete trop pres du feu.",
	"%s just got roasted. / %s vient de se faire rotir.",
	"%s got burnt. / %s a ete carbonise.",
	"%s thought they were the human torch. / %s s'est prit pour la torche.",
	"%s started a fire. / %s a allume le feu."
}

-- Acid death messages
messages.acid = {
	"%s has now parts of them missing. / %s a desormais des parties en moins.",
	"%s discovered that acid is fun. / %s a decouvert que l'acide c'est fun.",
	"%s put their head where it melted. / %s a mis sa tete la ou elle a fondu.",
	"%s dicovered that their body in acid, it's like sugar in water. / %s a decouvert que son corps dans l'acide, c'est comme du sucre dans de l'eau.",
	"%s thought they were swimming in apple juice. / %s a cru qu'il se baignait dans du jus de pomme.",
	"%s gave their body to make an infusion / %s a donne son corps pour faire une infusion.",
	"%s drowned in the wrong liquid. / %s a bu la mauvaise tasse.",
	"%s tried to test their body's solubility in acid. / %s a voulu tester la solubilite de son corps dans l'acide."
}

-- Quicksands death messages
messages.sand = {
	"%s leanrt that sand is less fluid than water. / %s a appris que le sable etait moins fluide que l'eau.",
	"%s joined the mummies. / %s a rejoint les momies.",
	"%s got themselves buried. / %s s'est fait(e) ensevelir.",
	"%s chose to become a fossil. / %s a choisi la voie de la fossilisation."
}

-- Other death messages
messages.other = {
	"%s did something fatal to them. / %s a fait quelque chose qui lui a ete fatale.",
	"%s is dead. / %s est mort(e).",
	"%s left this world. / %s n'est plus de ce monde.",
	"%s reached miner's heaven. / %s a rejoint le paradis des mineurs.",
	"%s lost their life. / %s a perdu la vie.",
	"%s saw the light. / %s a vu la lumière."
}

-- Whacking death messages
messages.whacking = {
	"%s got whacked by %s / %s s'est pris une raclee de la part de %s",
	"%s's grave was dug by %s / La tombe de %s a ete creusee par %s",
	-- Need to fill
}


local function broadcast_death(msg)
	minetest.chat_send_all(msg)
	if irc then
		irc:say(msg)
	end
end

local function sound_play_all(dead)
	for _, p in ipairs(minetest.get_connected_players()) do
		local player_name = p:get_player_name()
		if player_name and player_name ~= dead then
			minetest.sound_play("death_messages_people_1",{to_player=player_name, gain=soundset.get_gain(player_name,"other")})
		end
	end
end

minetest.register_on_punchplayer(function(player, hitter, time,
	tool_caps, dir, damage)
	if player:get_hp() - damage <= 0 and hitter:is_player() and not whacked[player:get_player_name()] then
		death_message = string.format(messages.whacking[math.random(1,#messages.whacking)], player:get_player_name(), hitter:get_player_name(), player:get_player_name(), hitter:get_player_name())
		broadcast_death(death_message)
		whacked[player:get_player_name()] = true
	end
end)


minetest.register_on_leaveplayer(function(player)
	whacked[player:get_player_name()] = nil
end)

minetest.register_on_respawnplayer(function(player)
	whacked[player:get_player_name()] = nil
end)

if RANDOM_MESSAGES == true then
	minetest.register_on_dieplayer(function(player)
		local player_name = player:get_player_name()
		local node = minetest.registered_nodes[minetest.get_node(player:getpos()).name]
		if minetest.is_singleplayer() then
			player_name = "You"
		end

		local death_message = ""

		if not whacked[player_name] then

			-- Death by lava
			if node.groups.lava ~= nil then
				death_message = messages.lava[math.random(1,#messages.lava)]
			-- Death by acid
			elseif node.groups.acid ~= nil then
				death_message = messages.acid[math.random(1,#messages.acid)]
			-- Death by drowning
			elseif player:get_breath() == 0 and node.groups.water then
				death_message = messages.water[math.random(1,#messages.water)]
			-- Death by fire
			elseif node.name == "fire:basic_flame" then
				death_message = messages.fire[math.random(1,#messages.fire)]
			-- Death in quicksand
			elseif player:get_breath() == 0 and node.name == "default:sand_source" or node.name == "default:sand_flowing" then
				death_message = messages.sand[math.random(1,#messages.sand)]
			-- Death by something else
			else
				death_message = messages.other[math.random(1,#messages.other)]
			end

			-- Actually tell something
			death_message = string.format(death_message, player_name, player_name)
			broadcast_death(death_message)
		end
		minetest.sound_play(sounds[math.random(1,#sounds)],{to_player=player:get_player_name(),gain=soundset.get_gain(player:get_player_name(),"other")})
		sound_play_all(player:get_player_name())
	end)

else
	-- Should we keep that part?
	minetest.register_on_dieplayer(function(player)
		local player_name = player:get_player_name()
		local node = minetest.registered_nodes[minetest.get_node(player:getpos()).name]
		if minetest.is_singleplayer() then
			player_name = "You"
		end
		if not whacked[player_name] then
			-- Death by lava
			if node.groups.lava ~= nil then
				minetest.chat_send_all(player_name .. " melted into a ball of fire")
			-- Death by drowning
			elseif player:get_breath() == 0 then
				minetest.chat_send_all(player_name .. " ran out of air.")
			-- Death by fire
			elseif node.name == "fire:basic_flame" then
				minetest.chat_send_all(player_name .. " burned to a crisp.")
			-- Death by something else
			else
				minetest.chat_send_all(player_name .. " died.")
			end
		end
		minetest.sound_play(sounds[math.random(1,#sounds)],{to_player=player:get_player_name(),gain=soundset.get_gain(player:get_player_name(),"other")})
		sound_play_all(player:get_player_name())
	end)
end

-----------------------------------------------------------------------------------------------
minetest.log("action", "[Mod] "..title.." ["..version.."] ["..mname.."] Loaded...")
-----------------------------------------------------------------------------------------------
