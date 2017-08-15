JSON = require('json/json')
HC = require("HC")

--- Reads in Tiled data
local sti = require('Simple-Tiled-Implementation/sti')

--- A "Camera", in 2D drawing, is a set of transformations that can
--- be applied to or removed from a drawing context
local Camera = require('hump/camera')

--- Instantiable game objects
local Platform = require('Platform')
local HotMagma = require('HotMagma')
local Coin = require('Coin')
local Player = require('Player')
local Door = require('Door')
local Exit = require('Exit')

--- Constructor(String map = map filename)
function Game(map)

  -- Base table for the game
  local game = {}
  
  --- Event handlers for Box2D's collisions ---
  --   Mostly, these delegate collision responsibilities to other objects, 
  --   like `Player` and `Platform`
  
  --- A new collision has occurred.  "Maintained" collisions - pairs that were
  --    already in the table - do not trigger this.
  function beginContact(a, b, contact)
    local oa = a:getUserData()
    if not (oa == nil) and not (oa.addContact == nil) then
      oa:addContact(b, contact, false)
    end
    local ob = b:getUserData()
    if not (ob == nil) and not (ob.addContact == nil) then
      ob:addContact(a, contact, true)
    end
  end
  
  --- A collision has ended
  function endContact(a, b, contact)
    local oa = a:getUserData()
    if not (oa == nil) and not (oa.removeContact == nil) then
      oa:removeContact(b, contact, false)
    end
    local ob = b:getUserData()
    if not (ob == nil) and not (ob.removeContact == nil) then
      ob:removeContact(a, contact, true)
    end
  end
  
  --- Called before a collision occurs.  Use this when you need
  --- to modify the behavior of the collision
  function preSolve(a, b, contact)
    local oa = a:getUserData()
    if not (oa == nil) and not (oa.preSolve == nil) then
      oa:preSolve(b, contact, false)
    end
    local ob = b:getUserData()
    if not (ob == nil) and not (ob.preSolve == nil) then
      ob:preSolve(a, contact, true)
    end    
  end
  
  --- Called after a collision occurs.  This is called for every
  --- frame, not jsut the first frame of the collision.
  function postSolve(a, b, contact)
    local oa = a:getUserData()
    if not (oa == nil) and not (oa.postSolve == nil) then
      oa:postSolve(b, contact, false)
    end
    local ob = b:getUserData()
    if not (ob == nil) and not (ob.postSolve == nil) then
      ob:postSolve(a, contact, true)
    end        
  end
  
    --- Persistent data for the game (best clear time)
  game.persistent = {}
  if (love.filesystem.exists('persistent.json')) then
    game.persistent = JSON.decode(love.filesystem.read('persistent.json'))
  else 
    game.persistent.bestTime = 9999
  end

  --- Image resources
  game.sprites = {}
  game.sprites.coin_sheet = love.graphics.newImage('sprites/coin_sheet.png')
  game.sprites.player_jump = love.graphics.newImage('sprites/player_jump.png')
  game.sprites.player_stand = love.graphics.newImage('sprites/player_stand.png')
  
  function game:init()
      --- Our Box2d world
      game.world = love.physics.newWorld(0, 1000, false)
      --- Attach callbacks
      game.world:setCallbacks(beginContact, endContact, preSolve, postSolve)
      --- Player instance
      game.player = Player(game)
      --- Play time
      game.timer = 0
      -- Setup camera
      self.cam = Camera()
      -- Load the map
      self:loadMap(map)
      -- Set the background color
      love.graphics.setBackgroundColor(155, 214, 255)
      -- Look at the player's start position
      self.cam:lookAt(self.player.body:getX(), love.graphics.getHeight() / 2)
      -- Update the world once so that the player's state is OK.
      self:update(0.01667)
  end
  
  --- Called when Gamestate enters this state
  function game:enter()
    game:init()
  end


  --- loads a Tiled map lua file, and spawns objects appropriately for it
  function game:loadMap(map)
    self.platforms = {}
    self.coins = {}    
    self.map = sti(map)
    local doors = {}
    local playerSet = false
    for i, obj in pairs(game.map.layers.Objects.objects) do
      --- Rather than break it up by layers, I have one "Objects" layer, and switch behavior by the 
      --    `type` property
      if obj.type == 'Coin' then
        self:spawnCoin(obj.x, obj.y)
      elseif obj.type == 'Player' then
        if playerSet then
            print("Warning: Multiple player start positions in map: " .. map)
        else
            --print("Player found at " .. obj.x .. ", " .. obj.y)
            playerSet = true
            self.player.body:setX(obj.x + player.width / 2)
            self.player.body:setY(obj.y + player.height / 2)
        end
      elseif obj.type == 'Door' then
        if obj.name == nil then
          print("Warning: Unnamed door in map: " .. map)
        else
          if doors[obj.name] == nil then
            doors[obj.name] = {}
          end
          
          table.insert(doors[obj.name], obj)        
          --print("Adding door[" .. obj.name .. "]#" .. #doors[obj.name])
        end
      
          
      elseif obj.type == 'Exit' then
        self:spawnExit(obj)
      elseif obj.type == "HotMagma" then
        self:spawnHotMagma(obj)
      elseif obj.type == "CoinBox" then
        print("TODO: CoinBox")
      elseif obj.type == "BoomBox" then
        print("TODO: BoomBox")
      else
        -- Default object type is platform
        -- This covers the type "Cloud" as well, which is a platform you can jump through.
        self:spawnPlatform(obj)
      end
    end
    for n, t in pairs(doors) do
      if #t < 2 then
        print("Warning: Only one door named " .. n .. " in map " .. map)
      elseif #t > 2 then
        print("Warning: " .. #t .. " doors named " .. n .. " in map " .. map)
      else
        print("Creating door pair")
        self:spawnDoor(t[1], t[2])
      end
    end
  end

  --- Spawn a coin at a given position
  --- TODO: use an object pool
  function game:spawnCoin(x, y)
    table.insert(self.coins, Coin(self, x, y))  
  end
  
  --- Spawn a platform at a given position
  --- TODO: use an object pool
  function game:spawnPlatform(obj)
    local platform = Platform(self, obj)
    if not platform == nil then
      table.insert(self.platforms, platform)
    end
  end
  
  function game:spawnDoor(left, right)
    local portal = new Door(self, left, right)
    if not portal == nil then
      table.insert(self.doors, portal)
    end
  end
  function game:spawnExit(obj)
    print("Spawning exit")
    local xit = new Exit(self, obj)
    if not xit == nil then
      table.insert(self.doors, xit)
    end
  end
      
  
  function game:spawnHotMagma(obj)
    local magma = HotMagma(self, obj)
    if not magma == nil then
      table.insert(self.platforms, magma)
    end
  end
  
  --- Store persistent data to love.filesystem.
  function game:persist()
    love.filesystem.write('persistent.json', JSON.encode(self.persistent))
  end
  
  
  --- Reset the game state
  function game:reset(survived)
    if survived then
        if self.timer < self.persistent.bestTime then
          self.persistent.bestTime = math.floor(self.timer)
          game:persist()
        end
    end
    --- Re-init the game
    self.world:destroy()
    self:init()

    -- Pause the game
    self:pause()
  end
  
  function game:update(dt)
    -- Doors don't really need to update, just accept collision events
    
    --- Coins' update is just maintaining animation state.
    --    Might consider splitting off an `updateAnimation` 
    --    for platforms and background objects if I decide they 
    --    need animated too.
    for i, c in ipairs(self.coins) do
      c:update(dt)
    end
    --- Stuff that shouldn't happen if the game is paused.
    if not self.paused then
      -- Advance the timer
      self.timer = self.timer + dt
      -- Update the player's logic
      self.player:update(dt)
      -- Update the world's physics
      self.world:update(dt)
      -- Update the map (TODO: What's this do?)
      self.map:update(dt)
      
      --- Clean up the coin table
      for i, c in ipairs(self.coins) do
        if c.collected then
          table.remove(self.coins, i)
        end
      end
            
      --- Update the camera's position
      self.cam:lookAt(self.player.body:getX(), love.graphics.getHeight() / 2)
    end
  end

  function game:pause()
    -- Push the `menu` state, which will pause the `from` state (this)
    GS.push(menu)
  end

  function game:keypressed(key, scancode, isRepeat)
    --- forward the `keypressed` event to the player
    self.player:keypressed(key, scancode, isRepeat)
    --- handle `escape` as a Pause action
    if key == 'escape' then
      self:pause()
    end
  end

  function game:draw()
  
    -- Attach the camera for game field drawing
    self.cam:attach()
    
    --- Draw the map's foreground
    self.map:drawLayer(game.map.layers["Background"])
    --- Draw the player
    self.player:draw()
    --- Draw the coins
    for i, c in ipairs(game.coins) do
      c:draw()
    end
    -- Draw in the foreground
    self.map:drawLayer(game.map.layers["Foreground"])
    
    --- Detatch the camera for HUD drawing
    self.cam:detach()
    
    
    love.graphics.setFont(hudFont)
    love.graphics.printf("Coins: " .. self.player.coins, 10, 660, love.graphics:getWidth() - 20, "left")
    --- Show the record time when paused or reset
    if self.paused then
      love.graphics.printf("Best time: " .. math.floor(self.persistent.bestTime), 10, 660, love.graphics:getWidth() - 20, "right")
    else
      love.graphics.printf("Time: " .. math.floor(self.timer), 10, 660, love.graphics:getWidth() - 20, "right")
    end
  end
  
  -- return the instance
  return game
end


-- return the constructor
return Game