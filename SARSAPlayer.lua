require("torch")
require("utils")
local tds = require("tds")
local class = require("class")
local comp = require 'pl.comprehension' . new()

local SARSAPlayer = class("SARSAPlayer")

function SARSAPlayer:__init(opt)
   opt = opt or {}
   self.Q = tds.Hash({})

   self.epsLearning = tonumber(opt.epsLearning) or 0.5
   self.epsEvaluate = tonumber(opt.epsEvaluate) or 0.1
   self.learningRate = tonumber(opt.learningRate) or 0.1
   self.discount = tonumber(opt.discount) or 0.99
   self.memorySize = tonumber(opt.memorySize) or 3
   self.oldStates =
   comp 'table(y, "" for y)' (seq.copy(seq.range(1,self.memorySize)))

   self.statesNo = 0
   self.lastAction = ""
end

function SARSAPlayer:selectAction(state, actions, isTraining)
   if (not isTraining and math.random() >= self.epsEvaluate)
   or (isTraining and math.random() >= self.epsLearning) then
      return self:bestAction(state, actions)
   else
      return actions[torch.random(#actions)], 0
   end
end

function SARSAPlayer:bestAction(state, actions)
   local Qs = self.Q[state] or {}
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

function SARSAPlayer:feedback(state, action, reward, nextState, newAction)
   local q

   if not self.Q[state] then
      self.Q[state] = tds.Hash({})
      self.statesNo = self.statesNo + 1
   end

   if not self.Q[nextState] then
      self.Q[nextState] = tds.Hash({})
      self.statesNo = self.statesNo + 1
      q = 0
   else
      q = self.Q[nextState][newAction] or 0
   end

   self.Q[state][action] = self.Q[state][action] or 0
   self.Q[state][action] = self.Q[state][action] + self.learningRate *
      (reward + self.discount * q - self.Q[state][action])

end


function SARSAPlayer:getStatesNo()
   return self.statesNo
end

return SARSAPlayer
