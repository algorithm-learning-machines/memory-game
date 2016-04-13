local MemoryGame = require("memory_game")



cmd = torch.CmdLine()
cmd:text()
cmd:text("Playing a demo")
cmd:text()
cmd:text("Options:")
cmd:option("--width", 4, "Size of game")
cmd:option("--sleep", 0, "Sleep before each action")
cmd:option("--display", false, "Display game")


opt = cmd:parse(arg)

z = 0
for s = 1, 1000 do
    game = MemoryGame(opt)                                        -- initialize game

    while not game:isOver() do                -- util game reaches the final state,
       if opt.display then game:display(); sys.sleep(tonumber(opt.sleep)) end
       local actions = game:getAvailableActions()      -- get the available actions,
       local action_idx = math.random(#actions)               -- pick one at random,
       s, r = game:applyAction(actions[action_idx])       -- apply it and get reward
       if opt.display then game:display(true); sys.sleep(tonumber(opt.sleep)) end
    end

    z = z + game.score
end

print(z)

-- print(game.score)
