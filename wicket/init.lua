-- This minetest mod registers a user to a service that
-- is not minetest related.

-- minetest.register_on_newplayer(wicket_registrar.register)

local wicket_registrar = {}

wicket_registrar.register = function(player)
    local pw = tostring(math.random(1, 999999))
    local uname = player:get_player_name()
    local msg = "Your new password is " .. pw
    if validate(uname, pw, msg)
        minetest.chat_send_player(player:get_player_name(), msg)
end

wicket_registrar.validate = function()

end


