/******************************************************************************\
  My custom flash sensor tracer type ( Based on wire rangers )
\******************************************************************************/

-- Register the type up here before the extension registration so that the fsensor still works
registerType("fsensor", "xfs", nil,
	nil,
	nil,
	function(retval)
		if retval == nil then return end
		if !istable(retval) then error("Return value is neither nil nor a table, but a "..type(retval).."!",0) end
	end,
	function(v)
		return !istable(v) or not v.HitPos
	end
)

/******************************************************************************/

E2Lib.RegisterExtension("fsensor", true, "Lets E2 chips trace ray attachments and check for hits.")

--[[ **************************** TRACER **************************** ]]

__e2setcost(20)
e2function void entity:setFSensor(vector vPos, vector vDir, number nLen)
  if(not (this and this:IsValid())) then return end; local oFSensor = {}
  oFSensor.Ent = this -- Store the base entity
  oFSensor.Len = nLen -- How long the range is
  -- Local tracer position the trace starts from
  oFSensor.Pos = Vector(vPos[1],vPos[2],vPos[3])
  -- Local tracer direction to read the data of
  oFSensor.Dir = Vector(vDir[1],vDir[2],vDir[3])
  oFSensor.Dir:Normalize() -- Normalize the direction
  oFSensor.Dir:Mul(oFSensor.Len) -- Multiply to add in real-time
  -- http://wiki.garrysmod.com/page/Structures/TraceResult
  oFSensor.TrO = {} -- Trace output parameters
  -- http://wiki.garrysmod.com/page/Structures/Trace
  oFSensor.TrI = {
    start  = Vector(), -- The start position of the trace
    endpos = Vector(), -- The end   position of the trace
    filter = {this},   -- Which entities the trace must ignore
    -- http://wiki.garrysmod.com/page/Enums/CONTENTS
    mask   = bit.bor(CONTENTS_HITBOX, CONTENTS_SOLID,
                     CONTENTS_WINDOW, CONTENTS_MOVEABLE),
    output = oFSensor.TrO,  -- Give it output to save the data in
    ignoreworld = false }; return oFSensor -- Should the trace ignore world or not
end

__e2setcost(15)
e2function fsensor fsensor:smp()
  if(not this) then return nil end; local entLoc = this.Ent
  if(not (entLoc and entLoc:IsValid())) then return this end
  local entAng, trData = entLoc:GetAngles(), this.TrI
  trData.start:Set(this.Pos)
  trData.start:Rotate(entAng)
  trData.start:Add(entLoc:GetPos())
  trData.endpos:Set(this.Dir)
  trData.endpos:Rotate(entAng)
  trData.endpos:Add(trData.start)
  -- http://wiki.garrysmod.com/page/util/TraceLine
  util.TraceLine(trData); return this
end

__e2setcost(5)
e2function number fsensor:getHit()
  if(not this) then return 0 end
  return (this.TrO.Hit and 1 or 0)
end

__e2setcost(5)
e2function number fsensor:getHitWorld()
  if(not this) then return 0 end
  return (this.TrO.HitWorld and 1 or 0)
end

__e2setcost(8)
e2function vector fsensor:getHitPosition()
  if(not this) then return {0,0,0} end
  local hitPos = this.TrO.HitPos
  return (hitPos and {hitPos[1], hitPos[2], hitPos[3]} or {0,0,0})
end

__e2setcost(8)
e2function vector fsensor:getHitNormal()
  if(not this) then return {0,0,0} end
  local hitNor = this.TrO.HitNormal
  return (hitNor and {hitNor[1], hitNor[2], hitNor[3]} or {0,0,0})
end

__e2setcost(8)
e2function string fsensor:getHitTexture()
  if(not this) then return "" end
  return tostring(this.TrO.HitTexture or "")
end

__e2setcost(8)
e2function vector fsensor:getPosition()
  if(not this) then return {0,0,0} end
  local orgPos = this.TrO.StartPos
  return (orgPos and {orgPos[1], orgPos[2], orgPos[3]} or {0,0,0})
end

__e2setcost(5)
e2function number fsensor:getDistance()
  if(not this) then return 0 end
  return (this.TrO.Fraction * this.Len)
end

__e2setcost(5)
e2function number fsensor:getStartSolid()
  if(not this) then return 0 end
  return (this.TrO.StartSolid and 1 or 0)
end

__e2setcost(5)
e2function number fsensor:getAllSolid()
  if(not this) then return 0 end
  return (this.TrO.AllSolid and 1 or 0)
end

__e2setcost(5)
e2function number fsensor:getLeftSolid()
  if(not this) then return 0 end
  return (this.TrO.FractionLeftSolid * this.Len)
end

__e2setcost(5)
e2function entity fsensor:getEntity()
  if(not this) then return nil end
  return (this and this.TrO.Entity or nil)
end
