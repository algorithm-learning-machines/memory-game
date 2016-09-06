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
   self.lastAction = nil

   self.statesNo = 0
end

function QPlayer.getIndex(n, m)
   return (n - 1) % m + 1
end


function QPlayer:selectAction(state, actions, isTraining, newGame)
   if newGame then
      self.oldStates =
      comp 'table(y, "" for y)' (seq.copy(seq.range(1,self.memorySize)))
   end
   
   if (not isTraining and math.random() >= self.epsEvaluate)
   or (isTraining and math.random() >= self.epsLearning) then
      return self:bestAction(state, actions)
   else
      return actions[torch.random(#actions)], 0
   end
end

function QPlayer:bestAction(state, actions)
   if self.memorySize > 1 then
      for i = 1, self.memorySize - 1 do
         for l in string.gmatch(self.oldStates[i], "%a") do
            local pos = string.find(self.oldStates[i], l)

            for j = i + 1, self.memorySize do
               local pos2 = string.find(self.oldStates[j], l)

               -- print("aici state" .. state)
               -- print(pos)
               -- print(pos2)
               if pos2 and pos ~= pos2 and (string.sub(state,pos,pos) == ' ' 
                  or string.sub(state,pos2,pos2) == ' ') then
                  -- print("return la memorySize")
                  return getString(pos, pos2), 0
               end
            end
         end
      end
   end

   -- function QPlayer:bestAction(state, actions)
   -- if self.memorySize > 1 then
   --    print("in if")
   --    print(state)
   --    for i = 1, self.memorySize - 1 do
   --       print("in primul for si i e" .. i)
   --       print("oldStates de i" .. self.oldStates[i][1])
   --       for l in string.gmatch(self.oldStates[i], "%a") do
   --          print("in for 2")
   --          local pos = string.find(self.oldStates[i][1], l)
   --          print("in for 2 si l e si pos e" .. l .. pos)

   --          for j = i + 1, self.memorySize do
   --             local pos2 = string.find(self.oldStates[j][1], l)
   --             symb1 = string.sub(state,pos,pos)
   --             symb2 = string.sub(state,pos2,pos2)
   --             if pos2 and pos ~= pos2 and symb1 ~= ' ' and symb2 ~= ' ' then
   --                print(string.sub(state,pos,pos))
   --                print("inainte de return" .. getString(pos, pos2))
                  
   --                return getString(pos, pos2), 0
   --             end
   --          end
   --       end
   --    end
   -- end

   local Qs = self.Q[state] or {}
   local bestAction = nil
   local bestQ

   -- for a, q in pairs(Qs) do
      -- if self.memorySize == 1 and getString(getNumbers(a)) == a then
      --    do break end
      -- else
      --    if (not bestQ or q > bestQ) and getString(getNumbers(a)) ~= a then
      --       bestQ = q
      --       bestAction = {}
      --       bestAction[1] = a
      --       -- print(bestAction)
      --    elseif q == bestQ then
      --       bestAction[#bestAction] = a
      --    end
      -- end

      for a, q in pairs(Qs) do
         if self.memorySize > 0 then
            local ind = self.getIndex(self.idxCrt, self.memorySize)
            if self.memorySize == 1 and 
               self.lastAction ~= getString(getNumbers(a)) then
               do break end
            end
         else
            if not bestQ or q > bestQ then
               bestQ = q
               bestAction = {}
               bestAction[1] = a
               -- print(bestAction)
            elseif q == bestQ then
               bestAction[#bestAction] = a
            end
         end
      end

   if bestAction then
      local ind = torch.random(#bestAction)
      -- print("return de aici si bestAction are " .. #bestAction .. bestAction[1])
      return bestAction[ind], bestQ
   else
      return actions[torch.random(#actions)], 0
   end

end

function QPlayer:getBestQ(state)
   local bestQ = 0

   for _, q in pairs(self.Q[state] or {}) do
      if q > bestQ then
         bestQ = q
      end
   end

   return bestQ
end

function QPlayer:feedback(state, action, reward, nextState)
   local ind = self.getIndex(self.idxCrt, self.memorySize)
   local q = self:getBestQ(nextState)

   if not self.Q[state] then
      self.Q[state] = tds.Hash({})
      self.statesNo = self.statesNo + 1
   end

   self.Q[state][action] = self.Q[state][action] or 0
   self.Q[state][action] = self.Q[state][action] + self.learningRate *
      (reward + self.discount * q - self.Q[state][action])

   if self.memorySize >= 1 then
      -- local first, second = getNumbers(action)
      -- print(getNumbers(action))
      -- print(nextState)
      -- first_l = string.sub(nextState, first, first)
      -- second_l = string.sub(nextState, second, second)
      -- -- print(first .. "si" .. second)
      -- print(oldStates)
      -- if first_l ~= second_l then
      --    self.oldStates[ind] = nextState
      --    self.idxCrt = self.idxCrt + 1
      -- end
      self.oldStates[ind] = nextState
      self.lastAction = action

      print("am adaugat si oldStates arata")
      print(self.oldStates)
      self.idxCrt = self.idxCrt + 1
   end
   
end


function QPlayer:getStatesNo()
   return self.statesNo
end


return QPlayer
