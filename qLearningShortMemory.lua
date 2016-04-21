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
cmd:option("--trainEpisodes", 10000, "Number of training episodes")
cmd:option("--evalEpisodes", 200, "Number of evaluating episodes")
cmd:option("--sessions", 10000, "Number of sessions")
cmd:option("--memorySize", 3, "Size of memory")

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


local trainEpisodesNo = tonumber(opt.trainEpisodes) or 10000   
local sessionsNo = tonumber(opt.sessions) or 1000000
local evalEpisodesNo = tonumber(opt.evalEpisodes) or 100
trainingScores = torch.Tensor(trainEpisodesNo * sessionsNo)
evalScores = torch.Tensor(sessionsNo)
statesNo = torch.Tensor(sessionsNo)

local Q = {}
local N = 0

local comp = require 'pl.comprehension' . new()

local memorySize = opt.memorySize or 1
-- local oldStates = torch.Tensor(memorySize)


local oldStates = comp 'table(y, "" for y)' (seq.copy(seq.range(1,memorySize)))
local crt_idx = 1

print(sessionsNo)
-- os.exit()

for s = 1, sessionsNo do
   for e = 1, trainEpisodesNo do
      local game = MemoryGame(opt)
      local state = ""
      local oldState = ""

      while not game:isOver() do
         oldState = state

         memory = ""
         for i = crt_idx, 1, -1 do
            memory = (memory .. oldStates[i])
         end
         for i = memorySize, crt_idx + 1, -1 do
            memory = (memory .. oldStates[i])
         end

         local actionsAvailable = game:getAvailableActions()
         action = selectAction(Q, memory, actionsAvailable, true)

         state, reward = game:applyAction(action)

         
         local newMemory = state
         for i = crt_idx, 1, -1 do
            newMemory = (newMemory .. oldStates[i])
         end
         for i = memorySize, crt_idx + 2, -1 do
            newMemory = (newMemory .. oldStates[i])
         end

         q = getBestQ(Q, newMemory)

         if not Q[memory] then
            Q[memory] = {}
            N = N + 1
         end

         Q[memory][action] = Q[memory][action] or 0
         Q[memory][action] = Q[memory][action] + opt.learning_rate * 
                        (reward + opt.discout * q - Q[memory][action])

         oldStates[crt_idx] = state
         crt_idx = (crt_idx + 1) % memorySize

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

      print("EvalScore:" .. game.score .. " " .. e .. " " .. s)
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
   print ("Done" .. s)
end
