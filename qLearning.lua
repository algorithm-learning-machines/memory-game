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
cmd:option("--epsEvaluate", 0.01, "Epsilon pentru evaluare")
cmd:option("--discout", 0.9, "Gama")

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


local trainEpisodesNo = tonumber(opt.episodes) or 10
local sessionsNo = tonumber(opt.sessionsNo) or 10
local evalEpisodesNo = tonumber(opt.evalEpisodesNo) or 200
trainingScores = torch.Tensor(trainEpisodesNo * sessionsNo)
evalScores = torch.Tensor(sessionsNo)

local Q = {}

for s = 1, sessionsNo do
   for e = 1, trainEpisodesNo do
      local game = MemoryGame(opt)
      local oldState, action, reward
      local state = game:serialize()

      while not game:isOver() do
         oldState = state
         -- if opt.display then game:display(); sys.sleep(tonumber(opt.sleep)) end

         local actionsAvailable = game:getAvailableActions()
         action = selectAction(Q, state, actionsAvailable, true)


         state, reward = game:applyAction(action)

         local q = getBestQ(Q, state)

         if not Q[oldState] then
            Q[oldState] = {}
         end

         Q[oldState][action] = Q[oldState][action] or 0
         Q[oldState][action] = Q[oldState][action] + opt.learning_rate * 
                        (reward + opt.discout * q - Q[oldState][action])
         -- if opt.display then game:display(true); sys.sleep(tonumber(opt.sleep))
         -- end
      end

      print("Score:" .. game.score)

      trainingScores[(s - 1) * trainEpisodesNo + e] = game.score
   end

   -- gnuplot.figure(1)
   -- gnuplot.plot({'Training scores', trainingScores[{{1, s * trainEpisodesNo}}], "-"})

   local totalScore = 0

   for e = 1, evalEpisodesNo do
      local game = MemoryGame(opt)
      local state = game:serialize()

      while not game:isOver() do
         -- if opt.display then game:display(); sys.sleep(tonumber(opt.sleep)) end
         actionsAvailable = game:getAvailableActions()

         action, _ = selectAction(Q, state, actionsAvailable, false)
         state, reward = game:applyAction(action)
         -- if opt.display then game:display(true); sys.sleep(tonumber(opt.sleep)) end
      end

      -- print("EvalScore:" .. game.score .. " " .. e)
      totalScore = totalScore + game.score
      -- evalScoreEveryEpisode = 
   end -- for e

   print("Finished eval session")
   evalScores[s] = (totalScore / evalEpisodesNo)

   gnuplot.figure(2)
   -- gnuplot.plot({'Train',trainingScores[{{1, s * trainEpisodesNo}}], "-"},{'Eval',evalScores[{{1, s * evalEpisodesNo, evalEpisodesNo}}], "|"})

   -- np.linspace(1, args.train_episodes, args.train_episodes),
   -- np.linspace(args.eval_every, args.train_episodes, len(eval_scores))
   -- print(#evalScores)
   evaluate = torch.linspace(1, evalEpisodesNo, evalScores:size(1))

   gnuplot.plot(
      {'Train', torch.linspace(1, s * trainEpisodesNo, s * trainEpisodesNo), trainingScores[{{1, s * trainEpisodesNo}}], "-"},
      {'Eval', torch.linspace(trainEpisodesNo, s * trainEpisodesNo, s), evalScores[{{1, s}}], "~"})

   -- gnuplot.figure(2)
   -- gnuplot.plot({'Evaluation scores', evalScores[{{1, s}}], "-"})

   print ("Done")
end

-- evaluate = torch.linspace(trainEpisodesNo, evalEpisodesNo, evalScores:size(1))
--    print(evaluate)

-- gnuplot.plot({'Train',trainingScores[{{1, s * trainEpisodesNo}}], "-"},
--    {'Eval',evalScores[{{1, #evaluate}}], "|"})