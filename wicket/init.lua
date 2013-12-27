
-- this function registers the main idea of this mod
-- which is to do something when a player registers to register
-- the player to another service that this server has decided to
-- depend upon
--
-- what this does as of current is take a user, run it thru a couple
-- of mods to this mod that will register it to services that those
-- mods support
--
-- first we generate a 6 character password (to be padded)
-- then take the players name and validate it and if valid tell the
-- user he is no validated to xyz service
minetest.register_on_newplayer(
    function(player)
        local pw = tostring(math.random(1, 999999))
        local uname = player:get_player_name()
        local msg = "Your new password is " .. pw
        if validate(uname, pw, msg)
            minetest.chat_send_player(player:get_player_name(), msg)
    end)

function validate(uname, pw, msg)

end
