require("torch")

local class = require("class")

local RandomPlayer = class("RandomPlayer")

function RandomPlayer:__init()
   do end
end

function RandomPlayer:selectAction(_, actionsAvailable)
    return actionsAvailable[torch.random(#actionsAvailable)]
end

function RandomPlayer:feedback()
   do end
end

function RandomPlayer:getStatesNo()
   return 0
end

return RandomPlayer
