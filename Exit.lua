function Exit(game, obj)
    local xit = {}
    print("Exit exists at " .. obj.x .. ", " .. obj.y)
    xit.shape = love.physics.newRectangleShape(obj.width, obj.height)
    xit.body = love.physics.newBody(game.world, obj.x, obj.y, "static")
    xit.fixture = love.physics.newFixture(xit.body, xit.shape)
    xit.fixture:setUserData(xit)
    xit.game = game;
        
    function xit:addContact(other, contact)
        print("You win!")
        self.game:reset(true)
    end
    
    return xit
end
return Exit