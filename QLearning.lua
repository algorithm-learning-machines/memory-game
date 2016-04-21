require("torch")

local QLearning = {}
QLearning.__index = QLearning

local comp = require 'pl.comprehension' . new()

function QLearning.create(opt)     
   self = {}
   setmetatable(self, QLearning)
   self.Q = {}                    

   self.epsLearning = tonumber(opt.epsLearning) or 0.5
   self.epsEvaluate = tonumber(opt.epsEvaluate) or 0.1
   self.learningRate = tonumber(opt.learningRate) or 0.1
   self.discount = tonumber(opt.discount) or 0.99
   self.memorySize = tonumber(opt.memorySize) or 3
   self.idxCrt = 1
   self.oldStates = comp 'table(y, "" for y)' (seq.copy(seq.range(1,self.memorySize)))

   self.statesNo = 0

   return self
end

function QLearning:getIndex(n, m)
   return (n - 1) % m + 1
end

function QLearning:createMemory()
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


function QLearning:selectAction(state, actions, isTraining)
   local state = self:createMemory()
   if (not isTraining and math.random() >= self.epsEvaluate) or (isTraining and  math.random() >= self.epsLearning ) then
      return self:bestAction(state, actions)
   else
      return actions[torch.random(#actions)]
   end
end

-- function QLearning:selectAction(actions, isTraining)
--    local state = self:createMemory()
--    if (math.random() >= self.epsEvaluate) or (math.random() >= self.epsLearning ) then
--       return self:bestAction(state, actions)
--    else
--       return actions[torch.random(#actions)]
--    end
-- end


function QLearning:bestAction(state, actions)
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

function QLearning:getBestQ(state)
   bestQ = 0

   for a, q in pairs(self.Q[state] or {}) do
      if q > bestQ then
         bestQ = q
      end
   end

   return bestQ
end

function QLearning:feedback(state, action, reward, nextState)
   ind = self:getIndex(self.idxCrt, self.memorySize)
   local memory = self:createMemory() or state

   local newMemory = nextState
   if self.memorySize >= 1 then
      for i = ind - 1, 1, -1 do
         newMemory = (newMemory .. self.oldStates[i])
      end
      for i = self.memorySize, ind + 1, -1 do
         newMemory = (newMemory .. self.oldStates[i])
      end
   end

   local q = self:getBestQ(newMemory)

   if not self.Q[memory] then
      self.Q[memory] = {}
      self.statesNo = self.statesNo + 1
   end

   self.Q[memory][action] = self.Q[memory][action] or 0
   self.Q[memory][action] = self.Q[memory][action] + self.learningRate * 
                  (reward + self.discount * q - self.Q[memory][action])

   if self.memorySize >= 1 then
      self.oldStates[ind] = nextState
   end
   self.idxCrt = self.idxCrt + 1
end

return QLearning