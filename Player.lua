--- Constructor(Game game)
function Player(game)
  player = {}
  
  player.game = game
  -- Box2d Body
  player.body = love.physics.newBody(game.world, 100, 100, "dynamic")
  -- Make it a heavy one
  player.body:setMass(20)
  -- Player's hitbox should not rotate
  player.body:setFixedRotation(true)
  
  -- By fiat; The images differ.
  player.width = 66
  player.height = 92
  
  -- Shape of player's hitbox
  player.shape = love.physics.newRectangleShape(player.width, player.height)
  -- Connection between center of mass and hitbox
  player.fixture = love.physics.newFixture(player.body, player.shape)
  -- Give the fixture a handle to the main object, so we can communicate when colliding
  player.fixture:setUserData(player)
  
  -- Standing sprite
  player.standing = game.sprites.player_stand
  -- Jumping sprite
  player.jumping = game.sprites.player_jump
  
  -- Force applied to player when asked to move
  player.speed = 200
  -- Maximum vel for player
  player.maxSpeed = 400
  -- Whether feet touching ground
  player.grounded = nil
  -- 1 = right, -1 = left
  player.direction = 1
  -- coins collected
  player.coins = 0
  -- Ground friction experienced by player
  player.friction = 0.6
  -- Impulse applied when `jump` pressed
  player.jumpPower = 4000

  -- Sprite to draw for the player; reassigned on update
  player.activeSprite = player.standing

  -- Draw the player's sprite.
  function player:draw() 
    local sprite = self.activeSprite
    love.graphics.draw(sprite, 
      self.body:getX(), self.body:getY(), -- x, y
      nil, -- angle
      player.direction, 1, -- scale x, y
      sprite:getWidth() / 2, sprite:getHeight() / 2 -- offset x, y
    )
  end
  
  function player:keypressed(key, scancode, isRepeat)
    -- Event-based input handling (state-based key handling done in `update`)
    if key == "up" and self.grounded then
      self.body:applyLinearImpulse(0, -self.jumpPower)
    end
  end

  -- A contact is going to change.
  function player:removeContact(other, contact, amOther)
    self:checkContacts()
  end
  function player:addContact(other, contact, amOther)
    self:checkContacts()
  end

  player.target = nil

  -- Check the list of contacts to see if the player is standing on something
  function player:checkContacts()
    local contacts = player.body:getContactList()
    
    for i, contact in ipairs(contacts) do
      -- The objects associated with this contact.
      -- One is the player; the other we assume (for now) is a platform
      local a, b = contact:getFixtures() 
      -- Get the contact normal (i.e., the vector travelling perpendicular to 
      -- the line of contact.  If player is 'a', this is correct).
      local x, y = contact:getNormal()
      -- If player is `a`, `other` should be `b`
      local other = b
      -- If player is b, we need to swap `other` and flip the normal
      if b == self.fixture then
        -- correct the normal and as
        x, y = -x, -y
        other = a
      end
    
    
      -- Reset the value of `grounded`; we'll check if it needs set later
      self.grounded = nil
      
      -- Calculate the contact angle in terms of PI/4 (90 deg per unit), or 
      -- half-radians.
      -- 
      -- I do this because it makes the unit circle real easy to understand:
      --  -1
      -- 2   0
      --   1 
      theta = math.atan2(y, x) * 2 / math.pi
      
      -- 0.5 .. 1.5 is a 90 degree ^ shape opened downward, 
      -- meaning "If I'm touching something that's below me"
      if (theta >= 0.5 and theta <= 1.5) then
        -- Store the surface's friction and the angle of contact
        self.grounded = { friction = other:getFriction(), angle = theta * math.pi / 2 }
        return
      end
      
    end
  end
  
  function player:kill()
    -- TODO: Add ded anim
    self.game:reset(false)
  end
  
  -- Collect a coin.  Called by the Coin object
  function player:collect()
    self.coins = self.coins + 1
  end
  
  function player:moveBy(x, y)
    self.target = { x = x, y = y }
  end
  
  -- Update the player's state
  function player:update(dt)
    -- If a teleport target's been set, go there
    if self.target ~= nil then
      self.body:setX(self.body:getX() + self.target.x)
      self.body:setY(self.body:getY() + self.target.y)
      self.target = nil
    end
  
    -- store the values of the player's control buttons
    local left, right = love.keyboard.isDown("left"), love.keyboard.isDown("right")
    
    -- If the user is actively trying to make the player move
    if left or right then
      -- overcome own friction
      local mul = 1 / self.friction
      
      -- store speed temporarily
      local speed = { x = -self.speed, y = 0 }
      
      if self.grounded then
        -- If grounded, need to overcome ground friction
        mul = self.grounded.friction / self.friction
        speed.x, speed.y = speed.x * mul, speed.y * mul
        
        -- Adjust direction of thrust to match contact angle
        -- TODO: normal points up from the ground; whether rotation is clock 
        -- or counter depends on intended movement direction
        local c = math.cos(self.grounded.angle + math.pi / 2)
        local s = math.sin(self.grounded.angle + math.pi / 2)
        local m = math.sqrt(speed.x^2 + speed.y^2)
        speed.x, speed.y = m * c, m * s
        
      end

      if left then
        -- If player's moving left, push left
        self.body:applyLinearImpulse(speed.x, speed.y)
        self.direction = -1
      elseif right then
        -- Otherwise, push right
        self.body:applyLinearImpulse(-speed.x, -speed.y)
        self.direction = 1
      end
    else
      -- No player input; apply game-like friction to X axis.
      local x, y = player.body:getLinearVelocity()
      self.body:applyLinearImpulse(-x * self.friction, 0)
    end
    
    -- Apply a speed limit
    local x, y = self.body:getLinearVelocity()
    if x > self.maxSpeed then
      x = self.maxSpeed
    end
    if x < -self.maxSpeed then
      x = -self.maxSpeed
    end
    self.body:setLinearVelocity(x, y)
    
    -- If touching the ground, swap to the `standing` sprite; else, use `jumping`
    if self.grounded then
      player.activeSprite = player.standing
    else
      player.activeSprite = player.jumping
    end    
  end
  
  -- Return the created instance
  return player;
end

-- Return the constructor.
return Player