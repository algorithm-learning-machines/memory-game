require("torch")

local RandomPlayer = {}
RandomPlayer.__index = RandomPlayer

function RandomPlayer.create()     
    self = {}
    setmetatable(self, RandomPlayer)
    return self
end

function RandomPlayer:selectAction(actionsAvailable)
    return actionsAvailable[torch.random(#actionsAvailable)]
end


function RandomPlayer:feedback()
   do end
end

return RandomPlayer