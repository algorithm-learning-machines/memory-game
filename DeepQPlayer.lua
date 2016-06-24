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
   self.width = tonumber(opt.width) or 4

   self.statesNo = 0

   self.experiences = {}
   self.partitionsNo = 3
   self.partitionSize = 20
   self.databaseFull = false
   self.crtIdx = 1
   self.crtPartition = 1

   for i = 1, self.partitionsNo do
      table.insert(
         self.experiences,
         {
            states = torch.Tensor(self.partitionSize, 1,
                                 self.width, self.width),
            actions = torch.LongTensor(self.partitionSize),
            rewards = torch.Tensor(self.partitionSize),
            nextStates = torch.Tensor(self.partitionSize, 1,
                                      self.width, self.width),
         }
      )
   end

   self.w, self.dw = self.Q1:getParameters()
   -- self.
   print (self)
end

function DeepQPlayer:selectAction(state, actionsAvailable, isTraining)
   if (not isTraining and math.random() >= self.epsEvaluate)
   or (isTraining and math.random() >= self.epsLearning) then
      local _, bestAction = torch.max(self.Q1:forward(state)) --o functie aici
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

   -- local net = nn.Sequential()
   --  net:add(nn.Reshape(unpack(args.input_dims)))

   --  --- first convolutional layer
   --  local convLayer = nn.SpatialConvolution

   --  net:add(convLayer(args.hist_len*args.ncols, args.n_units[1],
   --                      args.filter_size[1], args.filter_size[1],
   --                      args.filter_stride[1], args.filter_stride[1],1))
   --  net:add(args.nl())

   --  -- Add convolutional layers
   --  for i=1,(#args.n_units-1) do
   --      -- second convolutional layer
   --      net:add(convLayer(args.n_units[i], args.n_units[i+1],
   --                          args.filter_size[i+1], args.filter_size[i+1],
   --                          args.filter_stride[i+1], args.filter_stride[i+1]))
   --      net:add(args.nl())
   --  end

   --  local nel
   --  if args.gpu >= 0 then
   --      nel = net:cuda():forward(torch.zeros(1,unpack(args.input_dims))
   --              :cuda()):nElement()
   --  else
   --      nel = net:forward(torch.zeros(1,unpack(args.input_dims))):nElement()
   --  end

   --  -- reshape all feature planes into a vector per example
   --  net:add(nn.Reshape(nel))

   --  -- fully connected layer
   --  net:add(nn.Linear(nel, args.n_hid[1]))
   --  net:add(args.nl())
   --  local last_layer_size = args.n_hid[1]

   --  for i=1,(#args.n_hid-1) do
   --      -- add Linear layer
   --      last_layer_size = args.n_hid[i+1]
   --      net:add(nn.Linear(args.n_hid[i], last_layer_size))
   --      net:add(args.nl())
   --  end

   --  -- add the last fully connected layer (to actions)
   --  net:add(nn.Linear(last_layer_size, args.n_actions))

   --  if args.gpu >=0 then
   --      net:cuda()
   --  end
   --  if args.verbose >= 2 then
   --      print(net)
   --      print('Convolutional layers flattened output size:', nel)
   --  end
   --  return net