require("torch")
require("gnuplot")

cmd = torch.CmdLine()
cmd:text()
cmd:text("Playing a demo")
cmd:text()
cmd:text("Options:")
cmd:option("--width", 4, "Size of game")
cmd:option("--sleep", 0, "Sleep before each action")
cmd:option("--display", false, "Display game")

cmd:option("--learning_rate", 0.1, "Learning rate")
cmd:option("--epsLearning", 0.5, "Epsilon pentru greedy")
cmd:option("--epsEvaluate", 0.1, "Epsilon pentru evalaure")
cmd:option("--discout", 0.9, "Gama")
cmd:option("--memorySize", 3, "Size of memory")


cmd:option("--episodesNo", 100000, "Number of training episodes")
cmd:option("--evalEvery", 200, "Eval the learning every n games")
cmd:option("-evalEpisodes", 100, "Number of episodes to use for evaluation")


cmd:option("--player", "random", "Who has to play?")

opt = cmd:parse(arg)

local MemoryGame = require("memory_game")
local player

if opt.player == "random" then
    Player = require("RandomPlayer")
elseif opt.player == "q_learning" then
    Player = require("QLearning")
end

local player = Player.create(opt)

local episodesNo = tonumber(opt.episodesNo)
local evalEvery = tonumber(opt.evalEvery)
local evalEpisodesNo = tonumber(opt.evalEpisodes)
local evalSessionsNo = torch.ceil(episodesNo / evalEvery)

trainingScores = torch.Tensor(episodesNo)
evalScores = torch.Tensor(evalSessionsNo)
statesNo = torch.Tensor(evalSessionsNo)

for s = 1, evalSessionsNo do
    for e = 1, evalEvery do
        local game = MemoryGame(opt)
        local state = game:serialize()
        local oldState = ""
        local actionsAvailable

        while not game:isOver() do
            oldState = state

            actionsAvailable = game:getAvailableActions()

            action = player:selectAction(state, actionsAvailable, true)

            state, reward = game:applyAction(action)
            player:feedback(oldState, action, reward, state)

            if opt.display then game:display(true); sys.sleep(tonumber(opt.sleep))
            end

        end

        print("Score:" .. game.score)

        trainingScores[(s - 1) * evalEvery + e] = game.score

    end

    local totalScore = 0
    if opt.player == "q_learning" then statesNo[s] = player.statesNo end

    for e = 1, evalEpisodesNo do
        local game = MemoryGame(opt)
        local state = game:serialize()
        local reward, actionsAvailable

        while not game:isOver() do
            if opt.display then game:display(false); sys.sleep(tonumber(opt.sleep))
            end
            actionsAvailable = game:getAvailableActions()
            action = player:selectAction(state, actionsAvailable, false)

            state, _ = game:applyAction(action)

            if opt.display then game:display(true); sys.sleep(tonumber(opt.sleep))
            end
        end
        
        print("EvalScore:" .. game.score)
        totalScore = totalScore + game.score
    end

    evalScores[s] = (totalScore / evalEpisodesNo)

    gnuplot.figure(1)
    gnuplot.plot(
        {'Train', torch.linspace(1, s * evalEvery, s * evalEvery), trainingScores[{{1, s * evalEvery}}], "-"},
        {'Eval', torch.linspace(evalEvery, s * evalEvery, s), evalScores[{{1, s}}], "~"})

    if opt.player == "q_learning" then
        gnuplot.figure(2)
        gnuplot.plot(
      {'Eval', statesNo[{{1, s}}], "~"}
      )
    end
end