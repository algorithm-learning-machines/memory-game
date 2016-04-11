require("torch")
require("gnuplot")

MemoryGame = require("memory_game")


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
cmd:option("--epsEvaluate", 0.01, "Epsilon pentru evalaure")
cmd:option("--discout", 0.9, "Gama")
cmd:option("--memory", 3, "Lastest moves")

opt = cmd:parse(arg)

local epsLearning = opt.epsLearning or 0.5
local epsEvaluate = opt.epsEvaluate or 0.01
local discout = opt.discout or 0.9

function selectAction(Q, state, actions, isTraining)
   if (not isTraining and math.random() >= epsEvaluate) or (math.random() >= epsLearning ) then
      return bestAction(Q, state, actions)
   else
      return actions[torch.random(#actions)]
   end
end


function bestAction(Q, state, actions)
   local Qs = Q[state] or {}
   local bestAction
   local bestQ

   for a, q in pairs(Qs) do
      if not bestQ or q > bestQ then
         bestQ = q
         bestAction = a
      end
   end

   if bestAction then
      return bestAction, bestQ
   else
      return actions[torch.random(#actions)], 0
   end

end

function getBestQ(Q, state)
   bestQ = 0

   for a, q in pairs(Q[state] or {}) do
      if q > bestQ then
         bestQ = q
      end
   end

   return bestQ
end


local trainEpisodesNo = tonumber(opt.episodes) or 1000
local sessionsNo = tonumber(opt.sessionsNo) or 10
local evalEpisodesNo = tonumber(opt.evalEpisodesNo) or 200
trainingScores = torch.Tensor(trainEpisodesNo * sessionsNo)
evalScores = torch.Tensor(sessionsNo)
statesNo = torch.Tensor(sessionsNo)

local Q = {}
local N = 0

local comp = require 'pl.comprehension' . new()
-- local latestMoves = {1:nil, 2:nil, 3:nil}

for s = 1, sessionsNo do
   for e = 1, trainEpisodesNo do
      local game = MemoryGame(opt)
      local oldState = "", actions, action
      local state = game:serialize()

      while not game:isOver() do
         oldStates = (oldState .. state)
         oldState = state
         -- if opt.display then game:display(); sys.sleep(tonumber(opt.sleep)) end

         actionsAvailable = game:getAvailableActions()
         action = selectAction(Q, oldStates, actionsAvailable, true)

         state, reward = game:applyAction(action)

         newOldStates = (oldState .. state)
         q = getBestQ(Q, newOldStates)

         if not Q[oldStates] then
            Q[oldStates] = {}
            N = N + 1
         end

         -- Q[oldState][action] = Q[oldState][action] or 0
         -- Q[oldState][action] = Q[oldState][action] + opt.learning_rate * 
         --                (reward + opt.discout * q - Q[oldState][action])
         Q[oldStates][action] = Q[oldStates][action] or 0
         Q[oldStates][action] = Q[oldStates][action] + opt.learning_rate * 
                        (reward + opt.discout * q - Q[oldStates][action])
         -- if opt.display then game:display(true); sys.sleep(tonumber(opt.sleep))
         -- end
      end

      print("Score:" .. game.score)

      trainingScores[(s - 1) * trainEpisodesNo + e] = game.score
   end

   local totalScore = 0
   statesNo[s] = N

   for e = 1, evalEpisodesNo do
      local game = MemoryGame(opt)
      local state = game:serialize()

      while not game:isOver() do
         if opt.display then game:display(); sys.sleep(tonumber(opt.sleep)) end
         actionsAvailable = game:getAvailableActions()

         action, _ = selectAction(Q, state, actionsAvailable, false)
         state, reward = game:applyAction(action)
         if opt.display then game:display(true); sys.sleep(tonumber(opt.sleep)) end
      end

      print("EvalScore:" .. game.score .. " " .. e)
      totalScore = totalScore + game.score
   end -- for e

   print("Finished eval session")
   evalScores[s] = (totalScore / evalEpisodesNo)

   gnuplot.figure(1)
   gnuplot.plot(
      {'Train', torch.linspace(1, s * trainEpisodesNo, s * trainEpisodesNo), trainingScores[{{1, s * trainEpisodesNo}}], "-"},
      {'Eval', torch.linspace(trainEpisodesNo, s * trainEpisodesNo, s), evalScores[{{1, s}}], "~"})
   gnuplot.figure(2)
   gnuplot.plot(
      {'Eval', statesNo[{{1, s}}], "~"}
      )

   print(N)
   print ("Done")
end
