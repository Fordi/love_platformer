local anim8 = require('anim8/anim8')

function Coin(game, x, y)
  local coin = {}
  coin.sheet = game.sprites.coin_sheet
  coin.x = x
  coin.y = y 
  coin.grid = anim8.newGrid(41, 42, 123, 126)
  coin.animation = anim8.newAnimation(coin.grid('1-3', 1, '1-3', 2, '1-2', 3), 0.1)
  coin.collected = false
  function coin:update(dt) 
    self.animation:update(dt)
    -- inlined the distance function.
    local dist = math.sqrt((self.x - player.body:getX())^2 + (self.y - player.body:getY())^2)
    if not self.collected and dist < 50 then
      self.collected = true
      player:collect()
    end
  end
  function coin:draw()
    self.animation:draw(self.sheet, self.x, self.y, nil, nil, nil, 0, 0)
  end
  
  
  return coin
end
return Coin
