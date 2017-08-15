local Menu = require("Menu")
local Game = require("Game")

-- Gamestate container and defined game states.
-- All global, because the states will need to invoke each
-- other through Gamestate.
GS = require("hump/gamestate")
menu = Menu()
game = Game("maps/gameMap.lua")

-- global fonts
menuFont = love.graphics.newFont(30)
hudFont = love.graphics.newFont(20)


function love.load()
  -- Initialize the game window
  love.window.setMode(900, 700)
  
  -- Initialize Gamestate
  GS.registerEvents()
  
  -- Switch to the game 
  GS.switch(game)
  
  -- Push the `menu` state on top.
  GS.push(menu)
end
