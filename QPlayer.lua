require("torch")
require("utils")
local tds = require("tds")

local class = require("class")

local comp = require 'pl.comprehension' . new()

local QPlayer = class("QPlayer")

function QPlayer:__init(opt)
   opt = opt or {}
   self.Q = tds.Hash({})

   self.epsLearning = tonumber(opt.epsLearning) or 0.5
   self.epsEvaluate = tonumber(opt.epsEvaluate) or 0.1
   self.learningRate = tonumber(opt.learningRate) or 0.1
   self.discount = tonumber(opt.discount) or 0.99
   self.memorySize = tonumber(opt.memorySize) or 3
   self.idxCrt = 1
   self.oldStates =
   comp 'table(y, "" for y)' (seq.copy(seq.range(1,self.memorySize)))

   self.statesNo = 0
end

function QPlayer:getIndex(n, m)
   return (n - 1) % m + 1
end

function QPlayer:createMemory()
   if self.memorySize == 0 then
      return nil
   end

   local memory = ""

   local ind = self:getIndex(self.idxCrt, self.memorySize)

   for i = ind - 1, 1, -1 do
      memory = (memory .. self.oldStates[i])
   end

   for i = self.memorySize, ind, -1 do
      memory = (memory .. self.oldStates[i])
   end

   return memory
end


function QPlayer:selectAction(state, actions, isTraining)
   if (not isTraining and math.random() >= self.epsEvaluate)
   or (isTraining and math.random() >= self.epsLearning) then
      return self:bestAction(state, actions)
   else
      return actions[torch.random(#actions)]
   end
end

function QPlayer:bestAction(state, actions)
   if self.memorySize > 0 then
      for i = 1, self.memorySize - 1 do
         for l in string.gmatch(self.oldStates[i], "%a") do
            local pos = string.find(self.oldStates[i], l)

            for j = i + 1, self.memorySize do
               pos2 = string.find(self.oldStates[j], l)
               if pos2 and pos ~= pos2 then
                  return getString(pos, pos2)
               end
            end
         end
      end
   end

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

function QPlayer:getBestQ(state)
   local bestQ = 0

   for a, q in pairs(self.Q[state] or {}) do
      if q > bestQ then
         bestQ = q
      end
   end

   return bestQ
end

function QPlayer:feedback(state, action, reward, nextState)
   local ind = self:getIndex(self.idxCrt, self.memorySize)
   local q = self:getBestQ(nextState)

   if not self.Q[state] then
      self.Q[state] = tds.Hash({})
      self.statesNo = self.statesNo + 1
   end

   self.Q[state][action] = self.Q[state][action] or 0
   self.Q[state][action] = self.Q[state][action] + self.learningRate *
      (reward + self.discount * q - self.Q[state][action])

   if self.memorySize >= 1 then
      self.oldStates[ind] = nextState
   end
   self.idxCrt = self.idxCrt + 1
end


function QPlayer:getStatesNo()
   return self.statesNo
end


return QPlayer
