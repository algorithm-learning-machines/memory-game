require("torch")
require("gnuplot")
require("utils")

local cmd = torch.CmdLine()
cmd:text()
cmd:text("Playing a demo")
cmd:text()
cmd:text("Options:")

--------------------------------------------------------------------------------
-- Game configuration
cmd:option("--game", "memory", "The game to play")
cmd:option("--width", 3, "Size of game")

--------------------------------------------------------------------------------
-- Game tracking
cmd:option("--sleep", 0, "Sleep before each action")
cmd:option("--display", false, "Display game")
cmd:option("--plotStates", false, "Plot evolution of states no")
cmd:option("--plotScores", false, "Plot evolution of scores no")
cmd:option("--printScores", false, "Print the scores")

--------------------------------------------------------------------------------
-- Learning constraints
cmd:option("--memorySize", 0, "Size of memory")
cmd:option("--network", "convnet", "Type of network to use")

--------------------------------------------------------------------------------
-- Learning hiper-parameters
cmd:option("--learningRate", 0.1, "Learning rate")
cmd:option("--epsLearning", 0.05, "Epsilon pentru greedy")
cmd:option("--epsEvaluate", 0.1, "Epsilon pentru evalaure")
cmd:option("--discout", 0.9, "Gama")

--------------------------------------------------------------------------------
-- Training and evalutaion
cmd:option("--episodesNo", 10000, "Number of training episodes")
cmd:option("--evalEvery", 200, "Eval the learning every n games")
cmd:option("--evalEpisodes", 50, "Number of episodes to use for evaluation")

--------------------------------------------------------------------------------
-- Player to test
cmd:option("--player", "rand", "Who has to play? (Q/rand/batman/DeepQ)")

cmd:option("--file", "dates.out", "Where to load the dates")
--------------------------------------------------------------------------------
-- Parse command line arguments
local opt = cmd:parse(arg)


f = io.open(opt.file, "r")
if f ~= nil then
   dates = torch.load(opt.file)
   dates["idx"] = dates["idx"] + 1
else
   dates = {}
   dates["idx"] = 1
end
local idxFile = dates["idx"]
-- print (dates)

--------------------------------------------------------------------------------
-- Instantiate game
local MemoryGame
if opt.game == "memory" then
   MemoryGame = require("memory_game")
else
   error("Not implemented yet!")
end

--------------------------------------------------------------------------------
-- Instantiate player

local Player
if opt.player == "rand" then
   Player = require("RandomPlayer")
   opt.plotStates = false
elseif opt.player == "Q" then
   Player = require("QPlayer")
elseif opt.player == "batman" then
   Player = require("Batman")
elseif opt.player == "DeepQ" then
   Player = require("DeepQPlayer")
end

-- opt.actionsNo = 5

local player = Player(opt)

--------------------------------------------------------------------------------
-- Train and evaluate

local episodesNo = tonumber(opt.episodesNo)
local evalEvery = tonumber(opt.evalEvery)
local evalEpisodesNo = tonumber(opt.evalEpisodes)
local evalSessionsNo = torch.ceil(episodesNo / evalEvery)

local trainingScores = torch.Tensor(episodesNo)
local evalScores = torch.Tensor(evalSessionsNo)
local statesNo = torch.Tensor(evalSessionsNo)

sum = 0

for s = 1, evalSessionsNo do
   -----------------------------------------------------------------------------
   -- Train
   for e = 1, evalEvery do
      local game = MemoryGame(opt)
      local state = game:serialize()
      local oldState, actionsAvailable, action, reward

      while not game:isOver() do
         if opt.display then game:display(false); sleep(opt.sleep) end

         oldState = state
         actionsAvailable = game:getAvailableActions()
         action = player:selectAction(oldState, actionsAvailable, true)
         state, reward = game:applyAction(action)
         player:feedback(oldState, action, reward, state)

         if opt.display then game:display(true); sleep(opt.sleep) end
      end

      if opt.printScores then print("[T]Score:" .. game.score) end

      trainingScores[(s - 1) * evalEvery + e] = game.score

   end

   -----------------------------------------------------------------------------
   -- Evaluate

   local totalScore = 0
   statesNo[s] = player:getStatesNo()

   for _ = 1, evalEpisodesNo do
      local game = MemoryGame(opt)
      local state = game:serialize()
      local actionsAvailable, action

      while not game:isOver() do
         if opt.display then game:display(true); sleep(opt.sleep) end

         actionsAvailable = game:getAvailableActions()
         action = player:selectAction(state, actionsAvailable, true) -- X
         state, _ = game:applyAction(action)

         if opt.display then game:display(true); sleep(opt.sleep) end
      end

      if opt.printScores then print("[E]Score:" .. game.score) end

      totalScore = totalScore + game.score
   end

   evalScores[s] = (totalScore / evalEpisodesNo)

   sum = sum + evalScores[s]

   -----------------------------------------------------------------------------
   -- Plot scores
   if opt.plotScores then
      gnuplot.figure(1, {['noraise'] = true})
      local idx = s * evalEvery                                 -- current index
      gnuplot.plot(
         {'Train', torch.linspace(1, idx, idx), trainingScores[{{1,idx}}], "-"},
         {'Eval', torch.linspace(evalEvery, idx, s), evalScores[{{1,s}}], "~"}
      )
   end

   -----------------------------------------------------------------------------
   -- Plot # of states
   if opt.plotStates then
      gnuplot.figure(2, {['noraise'] = true})
      gnuplot.plot({'Eval', statesNo[{{1,s}}], "~"})
   end

   -- gnuplot.raw("set term X11 1 noraise")
   -- gnuplot.raw("set term X11 2 noraise")
end

print(sum)
local memorySize = opt.memorySize or 0
local tScores = idxFile .. "_" .. opt.player .. "_" .. episodesNo .. "_"
-- local tScores = "_" .. opt.player .. "_" .. episodesNo .. "_" evalEvery
tScores = tScores .. evalEvery .. "_" .. evalEpisodesNo .. "_" .. memorySize
local eScores = tScores
tScores = tScores .. "_trainingScores"
eScores = eScores .. "_evalScores"

dates[tScores] = {trainingScores, sum}
dates[eScores] = {evalScores, sum}

torch.save("dates.out", dates)
