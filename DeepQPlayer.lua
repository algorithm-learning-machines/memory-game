require("torch")
require("nn")

local class = require("class")

local DeepQPlayer = class("DeepQPlayer")

function DeepQPlayer:__init(opt)
   opt = opt or {}

   self.Q1 = nn.Sequential()

   -- local convLayer = nn.SpatialConvolution(ninput, noutput, kw, kh, dw, 
   --    dh, padw, padH)
   -- local spatialmaxpooling = nn.SpatialMaxPooling(2, 2, 2, 2)

   self.Q1:add(nn.SpatialConvolution(1, 32, 3, 3, 1, 1, 1, 1))
   self.Q1:add(nn.ReLU())
   self.Q1:add(nn.SpatialMaxPooling(2, 2, 2, 2))

   self.Q1:add(nn.SpatialConvolution(32, 32, 3, 3, 1, 1, 1, 1))
   self.Q1:add(nn.ReLU())
   self.Q1:add(nn.SpatialMaxPooling(2, 2, 2, 2))

   self.Q1:add(nn.Reshape(32 * 16))
   self.Q1:add(nn.Linear(32 * 16, 32))

   self.epsLearning = tonumber(opt.epsLearning) or 0.5
   self.epsEvaluate = tonumber(opt.epsEvaluate) or 0.1
   self.learningRate = tonumber(opt.learningRate) or 0.1
   self.discount = tonumber(opt.discount) or 0.99
   self.gameWidth = tonumber(opt.width) or 4

   self.statesNo = 0

   self.experiences = {}
   self.partitionsNo = 3
   self.partitionSize = 20
   self.databaseFull = false
   self.crtIdx = 1
   self.crtPartition = 1

   if self.gameWidth % 2 == 0 then 
      self.gameSize = self.gameWidth * self.gameWidth
   else
      self.gameSize = self.gameWidth * self.gameWidth - 1
   end
   self.stateDim = self.gameSize / 2 + 2
   

   for i = 1, self.partitionsNo do
      table.insert(
         self.experiences,
         {
            states = torch.Tensor(self.partitionSize, 1,
                                 self.gameSize, self.stateDim),
            actions = torch.LongTensor(self.partitionSize),
            rewards = torch.Tensor(self.partitionSize),
            nextStates = torch.Tensor(self.partitionSize, 1,
                                      self.gameSize, self.stateDim),
         }
      )
   end

   self.w, self.dw = self.Q1:getParameters()
end

function DeepQPlayer:resizeState(state)
   -- state is a string with " " and letters 

   -- indexes = matrix with indexes of symbols
   local indexes = torch.Tensor(self.gameSize):fill(0)
   for i=1,#state do
      if state:sub(i,i) ~= " " then
         if #state%2 == 0 or (#state%2 == 1 and i ~= #state) then
            indexes[i] = state:sub(i,i)
         end

      end
   end

   local newState = torch.Tensor(self.gameSize, self.stateDim)

   for i=1,self.gameSize do
      newState[i]:fill(0)

      if indexes[i] ~= 0 then
         ok = false
         for j=1,self.gameSize do
            if j ~= i then
               if str:sub(j,j) == indexes[i] then
                  newState[i][2] = 1
                  ok = true
                  break
               end
            end
         end

         if not ok then
            newState[i][2+string.byte(indexes[i])-64] = 1
         end
      else 
         newState[i][1] = 1
      end
   end

   return newState
end

function DeepQPlayer:selectAction(state, actionsAvailable, isTraining)
   if (not isTraining and math.random() >= self.epsEvaluate)
   or (isTraining and math.random() >= self.epsLearning) then
      local _, bestAction = torch.max(self.Q1:forward(self:resizeState(state))) --o functie aici
      return bestAction[1]
   else
      return actions[torch.random(#actionsAvailable)]
   end
end

function DeepQPlayer:getQUpdates(oldState, action, reward, newState)
   --  delta = r + gamma * max_a Q(s2, a) - Q(s, a)
   -- term = term:clone():float():mul(-1):add(1)

   q2_max = self.Q1:forward(newState):max()

   q2 = q2_max:clone():mul(self.discount)

   delta = reward:clone():float()

   delta:add(q2)

   local q_all = self.network:forward(oldState)
    q = torch.FloatTensor(q_all:size(1))
    for i=1,q_all:size(1) do
        q[i] = q_all[i][a[i]]
    end
    delta:add(-1, q)

    return tdelta
end

function DeepQPlayer:qLearnMinibatch(s, a, r, s2)

   local targets, delta, q2_max = self:getQUpdate(s, a, r, s2)

    -- zero gradients of parameters
   self.dw:zero()

    -- get new gradient
   self.Q1:backward(s, targets)

    -- add weight cost to gradient
   self.dw:add(-self.wc, self.w)

    -- use gradients
   self.g:mul(0.95):add(0.05, self.dw)

    -- accumulate update
   self.deltas:mul(0):addcdiv(self.lr, self.dw, self.tmp)
   self.w:add(self.deltas)
end

function DeepQPlayer:feedback(state, action, reward, nextState)

   self.experiences[self.crtPartition].states[self.crtIdx]:copy(state)
   self.experiences[self.crtPartition].actions[self.crtIdx] = action
   self.experiences[self.crtPartition].rewards[self.crtIdx] = reward * 0.1
   self.experiences[self.crtPartition].nextStates[self.crtIdx]:copy(nextState)

   local shouldLearn = false
   local shouldCopy = false

   self.crtIdx = self.crtIdx + 1
   if self.crtIdx > self.partitionSize then
      self.crtIdx = 1
      self.crtPartition = self.crtPartition + 1
      if self.crtPartition > self.partitionsNo then
         self.databaseFull = true
         self.crtPartition = 1
      end
      shouldLearn = self.databaseFull
   end

   if shouldLearn then
      self:qLearnMinibatch()
   end

   if shouldCopy then
      local q1Params = self.Q1:getParameters()
      local q2Params = self.Q2:getParameters()
      q2Params:copy(q1Params)
   end

   return 0
end

function DeepQPlayer:getStatesNo()
   return 0
end

return DeepQPlayer
