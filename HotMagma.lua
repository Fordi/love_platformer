Platform = require("Platform")
-- Constructor(Game game, TiledObject obj)
function HotMagma(game, obj)
  -- new instance
  local magma = Platform(game, obj)
  
  --eliminate baseline platform solve logic; magma doesn't fade out, it just kills.
  function magma:preSolve(other, contact, amOther) end
  function magma:removeContact() end
  
  function magma:addContact(other)
    local otherObj = other:getUserData()
    if otherObj.kill ~= nil then
      otherObj:kill(self)
    end
  end
  
  -- As said, when the player loses contact with this platform, the platform 
  -- will phase back in.
  
  
  -- Return instance
  return magma
end

-- Return constructor
return HotMagma
