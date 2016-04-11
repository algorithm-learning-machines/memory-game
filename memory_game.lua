require("torch")
require("utils")

local class = require("class")

local MemoryGame = class("MemoryGame")

-- Static function that transforms a number to a printable symbol
function MemoryGame.getSymbol(n)
   assert(n > 0 and n < 27, "Out of range")
   return string.char(n + 64)
end

-- Initialize game
function MemoryGame:__init(opt)
   opt = opt or {}

   self.width = opt.width or 4                           -- Configure board size
   assert(self.width % 2, "Board width should be even!")
   self.size = self.width * self.width

   self.hidden = torch.zeros(self.size):int()           -- These are the symbols

   local order = torch.randperm(self.size)
   for idx = 1, self.size do
      self.hidden[order[idx]] = math.ceil(idx/2)
   end

   self.solved = torch.zeros(self.size):int()

   self.lastAction = nil
   self.lastReward = nil
   self.score = 0
end

function MemoryGame:isOver()
   return self.solved:sum() == self.size
end

function MemoryGame:serialize(fst, snd)
   local state = ""
   for i = 1, self.size do
      if self.solved[i] > 0.5 or fst == i or snd == i then
         state = state .. MemoryGame.getSymbol(self.hidden[i])
      else
         state = state .. " "
      end
   end
   return state
end

function MemoryGame:getAvailableActions()
   local actions = {}
   for first = 1, self.size do
      if self.solved[first] < 0.5 then
         for second = first + 1, self.size do
            if self.solved[second] < 0.5 then
               actions[#actions + 1] = getString(first, second)
            end
         end
      end
   end
   return actions
end

function MemoryGame:applyAction(action)
   self.lastAction = action
   first, second = getNumbers(action)
   assert(first > 0 and first <= self.size
             and second > 0 and second <= self.size)
   reward = -0.01
   if self.hidden[first] == self.hidden[second] and self.solved[first] == 0 then
      self.solved[first] = 1
      self.solved[second] = 1
      reward = 0.2
   end
   -- if self:isOver() then reward = 1.0 end
   self.lastReward = reward
   self.score = self.score + reward
   return self:serialize(first, second), reward
end

function MemoryGame:display(displayLastAction)
   local fst, snd, line, border, fill
   print("")
   if self.lastAction and displayLastAction then
      fst, snd = getNumbers(self.lastAction)
   end
   border = "+"
   fill = "|"
   for i = 1, self.width do
      border = border .. "---+"
      fill = fill .. "   |"
   end
   print(border)

   local idx = 1
   for i = 1, self.width do
      print(fill)
      line = "|"
      for j = 1, self.width do
         if fst == idx or snd == idx then
            line = line .. ">" .. MemoryGame.getSymbol(self.hidden[idx]) .. "<|"
         elseif self.solved[idx] > 0.5 then
            line = line .. " " .. MemoryGame.getSymbol(self.hidden[idx]) .. " |"
         else
            line = line .. "   |"
         end
         idx = idx + 1
      end
      print(line); print(fill); print(border)
   end

   -- Print info about last reward and total score
   if self.lastReward then print("Last reward: " .. self.lastReward) end
   print(string.format("TOTAL SCORE: %2.4f", self.score))
   print("")
end

return MemoryGame
