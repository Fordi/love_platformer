-- Constructor(Game game, TiledObject obj)
function Platform(game, obj)
  -- new instance
  local platform = {}
  
  -- `disabled` is flagged if contact with the player begins, the player is 
  --   approaching from below, and the Tiled type is ThroughPlatform
  --    thereby making a cloud-like platform.  When contact ends, `disabled` is 
  --    reset to false.
  platform.disabled = false
  
  -- List of vertices to pass to newFixture
  local vertices = {}
  
  -- Generate vertices from a possibly rotated rectangle
  if obj.shape == 'rectangle' then
    local r = math.rad(obj.rotation or 0)
    
    -- Precalculate the cosine and sine, so we don't need to re-do it eight times
    local cos = math.cos(r)
    local sin = math.sin(r)
    
    local offsetX, offsetY
    local minX, maxX, minY, maxY = 99999999, -99999999, 99999999, -99999999
    local ix, iy
    local vertices = {}
    -- Rotate the rectangle, find the bounding box, and add the points to `vertices`
    for _, v in ipairs({
        { x=obj.x             , y = obj.y             },
        { x=obj.x + obj.width, y = obj.y              },
        { x=obj.x            , y = obj.y + obj.height },
        { x=obj.x + obj.width, y = obj.y + obj.height }
      }) do
        
        ix, iy = cos * (v.x - obj.x) - sin * (v.y - obj.y),
                 sin * (v.x - obj.x) + cos * (v.y - obj.y)
        v.x, v.y = ix, iy
        minX = math.min(minX, ix)
        maxX = math.max(maxX, ix)
        minY = math.min(minY, iy)
        maxY = math.max(maxY, iy)
        table.insert(vertices, v.x)
        table.insert(vertices, v.y)
      end
      
      offsetX = (maxX - minX) / 2
      offsetY = (maxY - minY) / 2
    
    -- Create the shape
    platform.shape = love.physics.newPolygonShape(vertices)
  else
    -- TODO: At least implement Polygon and Polyline
    print("Unsupported shape: " .. platform.shape)
    return nil
  end
  
  -- Create the body
  platform.body = love.physics.newBody(game.world, obj.x, obj.y, "static")    
  
  -- Create the fixture
  platform.fixture = love.physics.newFixture(platform.body, platform.shape)
  -- Connect it to this Platform instance
  platform.fixture:setUserData(platform)
  
  -- Set the default fixture (TODO: property in Tiled)
  platform.fixture:setFriction(2)
  
  
  function platform:draw() 
      -- So's I can see it
      love.graphics.polygon('fill', vertices)
  end
  
  -- This, along with all the others, is called in Game's private preSolve
  function platform:preSolve(other, contact, amOther)
    -- If the platform is disabled (indicating the player is jumping up through it)
    --   disable this contact and exit the call
    if self.disabled then 
      contact:setEnabled(false)
      return
    end
    
    -- Player has contacted this platform for the first time
    -- Get the normal.  If platform is `a`, this is correct.
    local nx, ny = contact:getNormal()
    
    -- Get the relative velocity of the objects
    -- local mvx, mvy = self.body:getLinearVelocity()
    -- local ovx, ovy = other:getBody():getLinearVelocity()
    -- local vx, vy = ovx - mvx, ovy - mvy
    
    -- amOther indicates this was the 'b', and that things like the normal and 
    -- relative velocity should get flipped.
    if amOther then
        nx, ny = -nx, -ny
        --vx, vy = -vx, -vy
    end
    
    -- find the vel magnitude
    --local vmag = math.sqrt(vy*vy+vx*vx)
        
    if obj.type == 'Cloud' then
      -- Calculate the angle of contact
      local ntheta = math.atan2(ny, nx) * 2 / math.pi
      
      -- Rotate ntheta counter-clockwise by obj.rotation (which is in degree units)
      ntheta = (ntheta + 2 - (obj.rotation / 90)) % 4 - 2
      
      -- Same unit circle as in `Player`
      --  -1
      -- 2   0
      --   1
    
      -- Player is above, don't let 'em fall through!
      if (ntheta <= -0.5 and ntheta >= -1.5) then
        self.fixture:setFriction(2)
      end
      
      -- Player is below, coming up.  Phase out the platform and hold it 
      --  until the player stops contact
      if (ntheta >= 0.5 and ntheta <= 1.5) then
        contact:setEnabled(false)
        self.disabled = true
      end
      
      --     right edge                           left edge
      if (ntheta < 0.5 and ntheta > -0.5) or (ntheta > 1.5  or ntheta < -1.5) then
        -- platform presents no friction, but remains solid
        self.fixture:setFriction(0)
      end

    end
  end
  
  -- As said, when the player loses contact with this platform, the platform 
  -- will phase back in.
  function platform:removeContact()
    self.disabled = false
  end
  
  -- Return instance
  return platform
end

-- Return constructor
return Platform
