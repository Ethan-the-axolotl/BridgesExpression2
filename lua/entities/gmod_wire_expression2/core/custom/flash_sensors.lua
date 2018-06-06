local arrSensors, curKey = {}

local function makeSensor(sType, oEnt, sKey)
  local oSensor, oKey = arrSensors, (sKey or curKey)
  if(not oSensor[sType]) then oSensor[sType] = {} end oSensor = oSensor[sType]
  if(not oSensor[oEnt] ) then oSensor[oEnt]  = {} end oSensor = oSensor[oEnt]
  if(not oSensor[oKey] ) then oSensor[oKey]  = {} end oSensor = oSensor[oKey]
  return oSensor
end

local function findSensor(sType, oEnt, sKey)
  local oSensor, oKey = arrSensors, (sKey or curKey)
  if(oSensor and sType) then oSensor = oSensor[sType] end
  if(oSensor and oEnt ) then oSensor = oSensor[oEnt]  end
  if(oSensor and oKey ) then oSensor = oSensor[oKey]  end
  return oSensor
end

--[[ **************************** TRACER **************************** ]]

__e2setcost(8)
e2function void entity:delTracer(string sKey)
  if(not (this and this:IsValid())) then return end
  if(sKey == "*") then arrSensors["TRACER"] = nil else
    local oTracer = findSensor("TRACER", this, sKey)
    if(oTracer) then arrSensors["TRACER"][this][sKey] = nil end
  end; return this
end

__e2setcost(20)
e2function void entity:addTracer(string sKey, vector vPos, vector vDir, number nLen)
  if(not (this and this:IsValid())) then return end
  local oTracer = makeSensor("TRACER", this, sKey)
  oTracer.Len = nLen -- How long the range is
  -- Local tracer position the trace starts from
  oTracer.Pos = Vector(vPos[1],vPos[2],vPos[3])
  -- Local tracer direction to read the data of
  oTracer.Dir = Vector(vDir[1],vDir[2],vDir[3])
  oTracer.Dir:Normalize() -- Normalize the direction
  oTracer.Dir:Mul(oTracer.Len) -- Multiply to add in real-time
  -- http://wiki.garrysmod.com/page/Structures/TraceResult
  oTracer.TrO = {} -- Trace output parameters
  -- http://wiki.garrysmod.com/page/Structures/Trace
  oTracer.TrI = {
    start  = Vector(), -- The start position of the trace
    endpos = Vector(), -- The end   position of the trace
    filter = {this},   -- Which entities the trace must ignore
    -- http://wiki.garrysmod.com/page/Enums/CONTENTS
    mask   = bit.bor(CONTENTS_HITBOX, CONTENTS_SOLID,
                     CONTENTS_WINDOW, CONTENTS_MOVEABLE),
    output = oTracer.TrO,  -- Give it output to save the data in
    ignoreworld = false }; return this -- Should the trace ignore world or not
end

__e2setcost(15)
e2function entity entity:smpTracer(string sKey)
  if(not (this and this:IsValid())) then return end
  local oTracer = findSensor("TRACER", this, sKey)
  if(not oTracer) then return end
  local entAng = this:GetAngles()
  local trData = oTracer.TrI
  trData.start:Set(oTracer.Pos)
  trData.start:Rotate(entAng)
  trData.start:Add(this:GetPos())
  trData.endpos:Set(oTracer.Dir)
  trData.endpos:Rotate(entAng)
  trData.endpos:Add(trData.start)
  -- http://wiki.garrysmod.com/page/util/TraceLine
  util.TraceLine(trData); curKey = sKey; return this
end

__e2setcost(5)
e2function number entity:getTracerHit(string sKey)
  if(not (this and this:IsValid())) then return 0 end
  local oTracer = findSensor("TRACER", this, sKey)
  return (oTracer and (oTracer.TrO.Hit and 1 or 0) or 0)
end

__e2setcost(5)
e2function number entity:getTracerHit()
  if(not (this and this:IsValid())) then return 0 end
  local oTracer = findSensor("TRACER", this)
  return (oTracer and (oTracer.TrO.Hit and 1 or 0) or 0)
end

__e2setcost(5)
e2function number entity:getTracerHitWorld(string sKey)
  if(not (this and this:IsValid())) then return 0 end
  local oTracer = findSensor("TRACER", this, sKey)
  return (oTracer and (oTracer.TrO.HitWorld and 1 or 0) or 0)
end

__e2setcost(5)
e2function number entity:getTracerHitWorld()
  if(not (this and this:IsValid())) then return 0 end
  local oTracer = findSensor("TRACER", this)
  return (oTracer and (oTracer.TrO.HitWorld and 1 or 0) or 0)
end

__e2setcost(8)
e2function vector entity:getTracerHitPosition(string sKey)
  if(not (this and this:IsValid())) then return {0,0,0} end
  local oTracer = findSensor("TRACER", this, sKey)
  local hitPos = oTracer and oTracer.TrO.HitPos
  return (hitPos and {hitPos[1], hitPos[2], hitPos[3]} or {0,0,0})
end

__e2setcost(8)
e2function vector entity:getTracerHitPosition()
  if(not (this and this:IsValid())) then return {0,0,0} end
  local oTracer = findSensor("TRACER", this)
  local hitPos = oTracer and oTracer.TrO.HitPos
  return (hitPos and {hitPos[1], hitPos[2], hitPos[3]} or {0,0,0})
end

__e2setcost(8)
e2function vector entity:getTracerHitNormal(string sKey)
  if(not (this and this:IsValid())) then return {0,0,0} end
  local oTracer = findSensor("TRACER", this, sKey)
  local hitNor = oTracer and oTracer.TrO.HitNormal
  return (hitNor and {hitNor[1], hitNor[2], hitNor[3]} or {0,0,0})
end

__e2setcost(8)
e2function vector entity:getTracerHitNormal()
  if(not (this and this:IsValid())) then return {0,0,0} end
  local oTracer = findSensor("TRACER", this)
  local hitNor = oTracer and oTracer.TrO.HitNormal
  return (hitNor and {hitNor[1], hitNor[2], hitNor[3]} or {0,0,0})
end

__e2setcost(8)
e2function string entity:getTracerHitTexture(string sKey)
  if(not (this and this:IsValid())) then return "" end
  local oTracer = findSensor("TRACER", this, sKey)
  return (oTracer and oTracer.TrO.HitTexture or "")
end

__e2setcost(8)
e2function string entity:getTracerHitTexture()
  if(not (this and this:IsValid())) then return "" end
  local oTracer = findSensor("TRACER", this)
  return (oTracer and oTracer.TrO.HitTexture or "")
end

__e2setcost(8)
e2function vector entity:getTracerPosition(string sKey)
  if(not (this and this:IsValid())) then return {0,0,0} end
  local oTracer = findSensor("TRACER", this, sKey)
  local orgPos = oTracer and oTracer.TrO.StartPos
  return (orgPos and {orgPos[1], orgPos[2], orgPos[3]} or {0,0,0})
end

__e2setcost(8)
e2function vector entity:getTracerPosition()
  if(not (this and this:IsValid())) then return {0,0,0} end
  local oTracer = findSensor("TRACER", this)
  local orgPos = oTracer and oTracer.TrO.StartPos
  return (orgPos and {orgPos[1], orgPos[2], orgPos[3]} or {0,0,0})
end

__e2setcost(5)
e2function number entity:getTracerDistance(string sKey)
  if(not (this and this:IsValid())) then return 0 end
  local oTracer = findSensor("TRACER", this, sKey)
  return (oTracer and (oTracer.TrO.Fraction * oTracer.Len) or 0)
end

__e2setcost(5)
e2function number entity:getTracerDistance()
  if(not (this and this:IsValid())) then return 0 end
  local oTracer = findSensor("TRACER", this)
  return (oTracer and (oTracer.TrO.Fraction * oTracer.Len) or 0)
end

__e2setcost(5)
e2function number entity:getTracerStartSolid(string sKey)
  if(not (this and this:IsValid())) then return 0 end
  local oTracer = findSensor("TRACER", this, sKey)
  return (oTracer and (oTracer.TrO.StartSolid and 1 or 0) or 0)
end

__e2setcost(5)
e2function number entity:getTracerStartSolid()
  if(not (this and this:IsValid())) then return 0 end
  local oTracer = findSensor("TRACER", this)
  return (oTracer and (oTracer.TrO.StartSolid and 1 or 0) or 0)
end

__e2setcost(5)
e2function number entity:getTracerAllSolid(string sKey)
  if(not (this and this:IsValid())) then return 0 end
  local oTracer = findSensor("TRACER", this, sKey)
  return (oTracer and (oTracer.TrO.AllSolid and 1 or 0) or 0)
end

__e2setcost(5)
e2function number entity:getTracerAllSolid()
  if(not (this and this:IsValid())) then return 0 end
  local oTracer = findSensor("TRACER", this)
  return (oTracer and (oTracer.TrO.AllSolid and 1 or 0) or 0)
end

__e2setcost(5)
e2function number entity:getTracerLeftSolid(string sKey)
  if(not (this and this:IsValid())) then return 0 end
  local oTracer = findSensor("TRACER", this, sKey)
  return (oTracer and (oTracer.TrO.FractionLeftSolid * oTracer.Len) or 0)
end

__e2setcost(5)
e2function number entity:getTracerLeftSolid()
  if(not (this and this:IsValid())) then return 0 end
  local oTracer = findSensor("TRACER", this)
  return (oTracer and (oTracer.TrO.FractionLeftSolid * oTracer.Len) or 0)
end

__e2setcost(5)
e2function entity entity:getTracerEntity(string sKey)
  if(not (this and this:IsValid())) then return nil end
  local oTracer = findSensor("TRACER", this, sKey)
  return (oTracer and oTracer.TrO.Entity or nil)
end

__e2setcost(5)
e2function entity entity:getTracerEntity()
  if(not (this and this:IsValid())) then return nil end
  local oTracer = findSensor("TRACER", this)
  return (oTracer and oTracer.TrO.Entity or nil)
end
