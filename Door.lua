function Door(game, left, right)
    local door = {}
    print("New door from " .. left.x .. ", " .. left.y .. " to " .. right.x .. ", " ..right.y)
    door.leftShape = love.physics.newRectangleShape(left.width, left.height)
    door.leftBody = love.physics.newBody(game.world, left.x, left.y, "static")
    door.leftFixture = love.physics.newFixture(door.leftBody, door.leftShape)
    door.leftFixture:setUserData(door)
    
    door.rightShape = love.physics.newRectangleShape(right.width, right.height)
    door.rightBody = love.physics.newBody(game.world, right.x, right.y, "static")
    door.rightFixture = love.physics.newFixture(door.rightBody, door.rightShape)
    door.rightFixture:setUserData(door)
    
    -- Disable this door pair until the player's cleared it
    door.disabled = 0
    
    function door:preSolve(other, contact)
        contact:setEnabled(false)
    end
    
    function door:addContact(other, contact)
        print("beginContact")
        if door.disabled > 0 then
            print("Door is disabled")
            return
        end
        door.disabled = 2
        local a, b = contact:getFixtures()
        local thisSide = door.rightFixture
        local otherSide = door.leftFixture
                
        if b == door.leftFixture then
          print("reverse")
          otherSide = door.rightFixture
          thisSide = door.leftFixture
        end
        
        local ox = otherSide:getBody():getX() - thisSide:getBody():getX()
        local oy = otherSide:getBody():getY() - thisSide:getBody():getY()
        print("Moving target fixture by " .. ox .. ", " .. oy)
        local object = other:getUserData()
        if object ~= nil and object.moveBy ~= nil then
            object:moveBy(ox, oy)
        end
    end
    
    function door:removeContact()
        door.disabled  = door.disabled - 1
        if door.disabled < 0 then
            door.disabled = 0
        end
    end
    
    return door
end
return Door