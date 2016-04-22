require("torch")
require("util")
local class = require("class")

local Batman = class("Batman")

function Batman:__init()
   do return end
end

function Batman:selectAction(state, actionAvailable)
   if (#state %2 == 1) then
      state = state:sub(1,#state-1)
   end

   local d = {}
   local s = 0
   local z = 0

   for i = 1, #state do
      if state:sub(i,i) ~= " " then
         z = z + 1
         d[state:sub(i,i)] = (d[state:sub(i,i)] or 0) + 1
         if d[state:sub(i,i)] % 2 == 1 then s = s + 1 else s = s - 1 end
      end
   end

   if z == 0 then return getString(1, 2) end
   if s == 0 then
      local fstEmpty
      for i = 1, #state do
         if state:sub(i,i) == " " then
            if not fstEmpty then
               fstEmpty = i
            else
               return getString(fstEmpty, i)
            end
         end
      end
   else

      local a, b
      for k, v in pairs(d) do
         if v == 1 then if not a then a = k else b = k end end
      end
      local ia, ib
      for i = 1, #state do
         if state:sub(i,i) == a then ia = i end
         if state:sub(i,i) == b then ib = i end
      end
      local fst, snd

      if ia < ib then fst = ia; snd = ib else fst = ib; snd = ia end
      for i = snd+1, #state do
         if state:sub(i,i) == " " then return getString(fst, i) end
      end
   end
end

function Batman:feedback()
   do return end
end

function Batman:getStatesNo()
   return 0
end

return Batman
