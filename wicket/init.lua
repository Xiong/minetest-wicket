
minetest.register_on_newplayer(
    function(player)
        local pw = tostring(math.random(1, 999999))
        local uname = player:get_player_name()
        local msg = "Your new password is " .. pw
        if validate(uname, pw)
            minetest.chat_send_player(player:get_player_name(), msg)
    end)

function validate(uname, pw)
end
