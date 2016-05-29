local arrSensors = {}

local function makeSensor(sType, oEnt, sKey)
  local Sensor = arrSensors
  if(not Sensor[sType]) then Sensor[sType] = {} end Sensor = Sensor[sType]
  if(not Sensor[oEnt] ) then Sensor[oEnt]  = {} end Sensor = Sensor[oEnt]
  if(not Sensor[sKey] ) then Sensor[sKey]  = {} end Sensor = Sensor[sKey]
  return Sensor
end

local function findSensor(sType, oEnt, sKey)
  local Sensor = arrSensors
  if(Sensor and sType) then Sensor = Sensor[sType] end
  if(Sensor and oEnt ) then Sensor = Sensor[oEnt]  end
  if(Sensor and sKey ) then Sensor = Sensor[sKey]  end
  return Sensor
end

__e2setcost(8)
e2function void entity:delTracer(string sKey)
  if(not (this and this:IsValid())) then return end
  if(sKey == "ALL") then arrSensors["TRACER"] = nil else
    local Tracer = findSensor("TRACER", this, sKey)
    if(Tracer) then arrSensors["TRACER"][this][sKey] = nil end
  end
end

__e2setcost(20)
e2function void entity:addTracer(string sKey, vector vPos, vector vDir, number nLen)
  if(not (this and this:IsValid())) then return end
  local Tracer = makeSensor("TRACER", this, sKey)
  Tracer.Len = nLen -- How long the range is
  -- Local tracer position the trace starts from
  Tracer.Pos = Vector(vPos[1],vPos[2],vPos[3])
  -- Local tracer direction to read the data of
  Tracer.Dir = Vector(vDir[1],vDir[2],vDir[3])
  Tracer.Dir:Normalize() -- Normalize the direction
  Tracer.Dir:Mul(Tracer.Len) -- Multiply to add in real-time
  -- http://wiki.garrysmod.com/page/Structures/TraceResult
  Tracer.TrO = {--[[Trace output parameters]]}
  -- http://wiki.garrysmod.com/page/Structures/Trace
  Tracer.TrI = {
    start  = Vector(), -- The start position of the trace
    endpos = Vector(), -- The end   position of the trace
    filter = {this},   -- Which entities the trace must ignore
    -- http://wiki.garrysmod.com/page/Enums/CONTENTS
    mask   = bit.bor(CONTENTS_HITBOX, CONTENTS_SOLID,
                     CONTENTS_WINDOW, CONTENTS_MOVEABLE),
    output = Tracer.TrO,  -- Give it output to save the data in
    ignoreworld = false } -- Should the trace ignore world or not
end

__e2setcost(15)
e2function void entity:smpTracer(string sKey)
  if(not (this and this:IsValid())) then return end
  local Tracer = findSensor("TRACER", this, sKey)
  if(not Tracer) then return end
  local entAng = this:GetAngles()
  local trData = Tracer.TrI
  trData.start:Set(Tracer.Pos)
  trData.start:Rotate(entAng)
  trData.start:Add(this:GetPos())
  trData.endpos:Set(Tracer.Dir)
  trData.endpos:Rotate(entAng)
  trData.endpos:Add(trData.start)
  -- http://wiki.garrysmod.com/page/util/TraceLine
  util.TraceLine(trData)
end

__e2setcost(5)
e2function number entity:getTracerHit(string sKey)
  if(not (this and this:IsValid())) then return 0 end
  local Tracer = findSensor("TRACER", this, sKey)
  return (Tracer and (Tracer.TrO.Hit and 1 or 0) or 0)
end

__e2setcost(5)
e2function number entity:getTracerHitWorld(string sKey)
  if(not (this and this:IsValid())) then return 0 end
  local Tracer = findSensor("TRACER", this, sKey)
  return (Tracer and (Tracer.TrO.HitWorld and 1 or 0) or 0)
end

__e2setcost(8)
e2function vector entity:getTracerHitPosition(string sKey)
  if(not (this and this:IsValid())) then return {0,0,0} end
  local Tracer = findSensor("TRACER", this, sKey)
  local HitPos = Tracer and Tracer.TrO.HitPos
  return (HitPos and {HitPos[1], HitPos[2], HitPos[3]} or {0,0,0})
end
  
__e2setcost(8)
e2function vector entity:getTracerHitNormal(string sKey)
  if(not (this and this:IsValid())) then return {0,0,0} end
  local Tracer = findSensor("TRACER", this, sKey)
  local HitNor = Tracer and Tracer.TrO.HitNormal
  return (HitNor and {HitNor[1], HitNor[2], HitNor[3]} or {0,0,0})
end

__e2setcost(8)
e2function string entity:getTracerHitTexture(string sKey)
  if(not (this and this:IsValid())) then return "" end
  local Tracer = findSensor("TRACER", this, sKey)
  return (Tracer and Tracer.TrO.HitTexture or "")
end

__e2setcost(8)
e2function vector entity:getTracerPosition(string sKey)
  if(not (this and this:IsValid())) then return {0,0,0} end
  local Tracer = findSensor("TRACER", this, sKey)
  local OrgPos = Tracer and Tracer.TrO.StartPos
  return (OrgPos and {OrgPos[1], OrgPos[2], OrgPos[3]} or {0,0,0})
end

__e2setcost(5)
e2function number entity:getTracerDistance(string sKey)
  if(not (this and this:IsValid())) then return 0 end
  local Tracer = findSensor("TRACER", this, sKey)
  return (Tracer and (Tracer.TrO.Fraction * Tracer.Len) or 0)
end

__e2setcost(5)
e2function number entity:getTracerStartSolid(string sKey)
  if(not (this and this:IsValid())) then return 0 end
  local Tracer = findSensor("TRACER", this, sKey)
  return (Tracer and (Tracer.TrO.StartSolid and 1 or 0) or 0)
end

__e2setcost(5)
e2function number entity:getTracerAllSolid(string sKey)
  if(not (this and this:IsValid())) then return 0 end
  local Tracer = findSensor("TRACER", this, sKey)
  return (Tracer and (Tracer.TrO.AllSolid and 1 or 0) or 0)
end

__e2setcost(5)
e2function number entity:getTracerLeftSolid(string sKey)
  if(not (this and this:IsValid())) then return 0 end
  local Tracer = findSensor("TRACER", this, sKey)
  return (Tracer and (Tracer.TrO.FractionLeftSolid * Tracer.Len) or 0)
end

__e2setcost(5)
e2function entity entity:getTracerEntity(string sKey)
  if(not (this and this:IsValid())) then return nil end
  local Tracer = findSensor("TRACER", this, sKey)
  return (Tracer and Tracer.TrO.Entity or nil)
end
