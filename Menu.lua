-- Dead simple menu
function Menu()
  local menu = {}
  function menu:enter(from)
    self.parent = from
    self.parent.paused = true
  end
  function menu:update(dt)
    self.parent:update(dt)
  end
  function menu:draw() 
    self.parent:draw()
    love.graphics.setFont(menuFont)
    love.graphics.printf("Press any key to start!", 0, 50, love.graphics.getWidth(), "center")
  end
  function menu:keypressed(key)
    GS.pop()
    self.parent.paused = false
  end
  return menu
end
return Menu