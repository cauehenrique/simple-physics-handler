--[[
MIT License
Copyright 2019 lcrabbit
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

local SPH = {}
local Actor = {}
local mtActor = { __index = Actor }
local Solid = {}
local mtSolid = { __index = Solid }

local actors = {}
local solids = {}

-- Utils math functions

function math.round(n, deci)
  deci = 10 ^ (deci or 0)
  return math.floor(n * deci + .5) / deci
end

function math.sign(n)
  return n > 0 and 1 or n < 0 and -1 or 0
end

local function hasValue (tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

-- SPH functions

function SPH.newActor(x, y, w, h, tags)
  local actor = Actor.new(x, y, w, h, tags)
  table.insert(actors, actor)

  return actor
end

-- function SPH.setLinearVelocity(vector, onCollide)
  -- return actor:setLinearVelocity(vector, onCollide, solids)
-- end

function SPH.newSolid(x, y, w, h, tags)
  local solid = Solid.new(x, y, w, h, tags)
  table.insert(solids, solid)

  return solid
end

function SPH.draw(alpha)
  Actor:draw(alpha)
  Solid:draw(alpha)
end

-- Actor Object

function Actor.new(x, y, width, height, tags)
  local actor = {}


  actor.x = x
  actor.y = y
  actor.w = width
  actor.h = height
  actor.xRemainder = 0
  actor.yRemainder = 0
  actor.tags = {'actor'}

  if (tags ~= nil) then
    for _, tag in ipairs(tags) do
      table.insert(actor.tags, tag)
    end
  end

  setmetatable(actor, mtActor)

  return actor
end

function Actor:collideAt(collisionList, vector)
  local hasCollision = false

  if (solids == nil) then
    return false
  end

  for _, solid in ipairs(collisionList) do
    if (solid ~= self) then
      hasCollision = (self.x + vector.x < solid.x + solid.w and
              self.x + self.w + vector.x > solid.x and
              self.y + vector.y < solid.y + solid.h and
              self.y + self.h + vector.y > solid.y)
    end

    if (not solid.collidable) then
      hasCollision = false
    end

    if (hasCollision) then
      return true, solid
    end
  end

  return false
end

function Actor:triggerAt(collisionList, vector)
  local hasCollision = false

  if (actors == nil) then
    return false
  end

  for _, actor in ipairs(collisionList) do
    if (actor ~= self) then
      hasCollision = (self.x + vector.x < actor.x + actor.w and
              self.x + self.w + vector.x > actor.x and
              self.y + vector.y < actor.y + actor.h and
              self.y + self.h + vector.y > actor.y)
    end

    if (hasCollision) then
      return true, actor
    end
  end

  return false
end

function Actor:moveX (amount, onCollide)
  self.xRemainder = self.xRemainder + amount
  local move = math.round(self.xRemainder)

  if (move ~= 0) then
    self.xRemainder  = self.xRemainder - move
    local sign = math.sign(move)

    while (move ~= 0) do
      local collisionVector = { x = sign, y = 0 }
      local triggerAt, trigger = self:triggerAt(actors, collisionVector)
      if (triggerAt and onCollide ~= self.squish) then
        onCollide(trigger)
      end

      local collideAt, collider = self:collideAt(solids, collisionVector)
      if (not collideAt) then
        self.x = self.x + sign
        move = move - sign
      else
        if (onCollide ~= nil) then
          onCollide(self, collider)
        end
        break
      end
    end
  end
end

function Actor:moveY (amount, onCollide)
  self.yRemainder = self.yRemainder + amount
  local move = math.round(self.yRemainder)

  if (move ~= 0) then
    self.yRemainder = self.yRemainder - move
    local sign = math.sign(move)

    while (move ~= 0) do
      local collisionVector = { x = 0, y = sign }
      local triggerAt, trigger = self:triggerAt(actors, collisionVector)
      if (triggerAt and onCollide ~= self.squish) then
        onCollide(trigger)
      end

      local collideAt, collider = self:collideAt(solids, collisionVector)
      if (not collideAt) then
        self.y = self.y + sign
        move = move - sign
      else
        if (onCollide ~= nil) then
          onCollide(collider)
        end
        break
      end
    end
  end
end

function Actor:setLinearVelocity (vector, onCollide)
  if (vector.x ~= nil) then
    -- self:moveX(vector.x, onCollide, sollids)
    self:moveX(vector.x, onCollide)
  end

  if (vector.y ~= nil) then
    -- self:moveY(vector.y, onCollide, sollids)
    self:moveY(vector.y, onCollide)
  end
end

function Actor:squish()
  -- The squish is a separated function equals to destroy in case you want to override it
  for key, actor in ipairs(actors) do
    if (actor == self) then
      table.remove(actors, key)
      break
    end
  end
end

function Actor:destroy()
  for key, actor in ipairs(actors) do
    if (actor.tags == self.tags) then
      table.remove(actors, key)
    end
  end
end

function Actor:draw(alpha)
  for _, actor in ipairs(actors) do
    love.graphics.setColor(0.2, 1, 0.2, alpha ~= nil and alpha or 1)
    love.graphics.rectangle('line', actor.x, actor.y, actor.w, actor.h)
  end
end

function Actor:isRiding(solid)
  return self:collideAt({ solid }, { x = 0, y = 1 })
end

-- Solids
function Solid.new(x, y, width, height, tags)
  local solid = {}

  solid.x = x
  solid.y = y
  solid.w = width
  solid.h = height
  solid.xRemainder = 0
  solid.yRemainder = 0
  solid.tags = {'solid'}
  solid.collidable = true

  if (tags ~= nil) then
    for _, tag in ipairs(tags) do
      table.insert(solid.tags, tag)
    end
  end

  setmetatable(solid, mtSolid)

  return solid
end

function Solid:isOverlapping(actor)
  return (self.x < actor.x + actor.w and
          self.x + self.w > actor.x and
          self.y < actor.y + actor.h and
          self.y + self.h > actor.y)
end

function Solid:setLinearVelocity(x, y)
  self.xRemainder = self.xRemainder + x
  self.yRemainder = self.yRemainder + y

  local moveX = math.round(self.xRemainder)
  local moveY = math.round(self.yRemainder)

  if (moveX ~= 0 or moveY ~= 0) then
    local riding = {}

    for _, actor in ipairs(actors) do
      if (actor:isRiding(self)) then
        table.insert(riding, actor)
      end
    end

    self.collidable = false

    if (moveX ~= 0) then
      self.xRemainder = self.xRemainder - moveX
      self.x = self.x + moveX

      if (moveX > 0) then
        for _, actor in ipairs(actors) do
          if (self:isOverlapping(actor)) then
            actor:moveX(moveX, actor.squish, actor)
          elseif (hasValue(riding, actor)) then
            actor:moveX(moveX)
          end
        end
      else
        for _, actor in ipairs(actors) do
          if (self:isOverlapping(actor)) then
            actor:moveX(moveX)
          elseif (hasValue(riding, actor)) then
            actor:moveX(moveX)
          end
        end
      end
    end
  end

  if (moveY ~= 0 or moveY ~= 0) then
    local riding = {}

    for _, actor in ipairs(actors) do
      if (actor:isRiding(self)) then
        table.insert(riding, actor)
      end
    end

    self.collidable = false

    if (moveY ~= 0) then
      self.yRemainder = self.xRemainder - moveX
      self.y = self.y + moveY

      if (moveY > 0) then
        for _, actor in ipairs(actors) do
          if (self:isOverlapping(actor)) then
            actor:moveY(moveY, actor.squish)
          elseif (hasValue(riding, actor)) then
            actor:moveY(moveY)
          end
        end
      else
        for _, actor in ipairs(actors) do
          if (self:isOverlapping(actor)) then
            actor:moveY(moveY)
          elseif (hasValue(riding, actor)) then
            actor:moveY(moveY)
          end
        end
      end
    end
  end

  self.collidable = true
end

function Solid:draw(alpha)
  for _, currentSolid in ipairs(solids) do
    love.graphics.setColor(1, 0.2, 0.2, alpha ~= nil and alpha or 1)
    love.graphics.rectangle('line', currentSolid.x, currentSolid.y, currentSolid.w, currentSolid.h)
  end
  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)
end

return SPH
