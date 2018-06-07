/******************************************************************************\
  My custom flash sensor tracer type ( Based on wire rangers )
\******************************************************************************/

-- Register the type up here before the extension registration so that the fsensor still works
registerType("fsensor", "xfs", nil,
	nil,
	nil,
	function(retval)
		if(retval == nil) then return end
		if(not istable(retval)) then error("Return value is neither nil nor a table, but a "..type(retval).."!",0) end
	end,
	function(v)
		return (not istable(v)) or (not v.StartPos)
	end
)

/******************************************************************************/

E2Lib.RegisterExtension("fsensor", true, "Lets E2 chips trace ray attachments and check for hits.")

local function newFSensor(oEnt, vPos, vDir, nLen)
  if(not (oEnt and oEnt:IsValid())) then return nil end
  local oFSensor = {}
  oFSensor.Ent = oEnt -- Store the base entity
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
    output = oFSensor.TrO,
    start  = Vector(), -- The start position of the trace
    endpos = Vector(), -- The end   position of the trace
    filter = {oEnt},   -- Which entities the trace must ignore
    -- http://wiki.garrysmod.com/page/Enums/CONTENTS
    mask   = bit.bor(CONTENTS_HITBOX, CONTENTS_SOLID,
                     CONTENTS_WINDOW, CONTENTS_MOVEABLE),
    ignoreworld = false } -- Should the trace ignore world or not
  return oFSensor
end

--[[ **************************** TRACER **************************** ]]

registerOperator("ass", "xfs", "xfs", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local      rhs = op2[1](self, op2)
	self.Scopes[scope][lhs] = rhs
	self.Scopes[scope].vclk[lhs] = true
	return rhs
end)

__e2setcost(20)
e2function fsensor entity:setFSensor(vector vP, vector vD, number nL)
  return newFSensor(this, vP, vD, nL)
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
  local trV = this.TrO.Hit
  return (trV and 1 or 0)
end

__e2setcost(5)
e2function number fsensor:getHitWorld()
  if(not this) then return 0 end
  local trV = this.TrO.HitWorld
  return (trV and 1 or 0)
end

__e2setcost(8)
e2function vector fsensor:getHitPosition()
  if(not this) then return {0,0,0} end
  local trV = this.TrO.HitPos
  return (trV and {trV[1], trV[2], trV[3]} or {0,0,0})
end

__e2setcost(8)
e2function vector fsensor:getHitNormal()
  if(not this) then return {0,0,0} end
  local trV = this.TrO.HitNormal
  return (trV and {trV[1], trV[2], trV[3]} or {0,0,0})
end

__e2setcost(8)
e2function string fsensor:getHitTexture()
  if(not this) then return "" end
  local trV = this.TrO.StartPos
  return tostring(trV or "")
end

__e2setcost(8)
e2function vector fsensor:getPosition()
  if(not this) then return {0,0,0} end
  local trV = this.TrO.StartPos
  return (trV and {trV[1], trV[2], trV[3]} or {0,0,0})
end

__e2setcost(5)
e2function number fsensor:getDistance()
  if(not this) then return 0 end
  local trV = this.TrO.Fraction
  return (trV and (trV * this.Len) or 0)
end

__e2setcost(5)
e2function number fsensor:getStartSolid()
  if(not this) then return 0 end
  local trV = this.TrO.StartSolid
  return (trV and 1 or 0)
end

__e2setcost(5)
e2function number fsensor:getAllSolid()
  if(not this) then return 0 end
  local trV = this.TrO.AllSolid
  return (trV and 1 or 0)
end

__e2setcost(5)
e2function number fsensor:getLeftSolid()
  if(not this) then return 0 end
  local trV = this.TrO.FractionLeftSolid
  return (trV and (trV * this.Len) or 0)
end

__e2setcost(5)
e2function entity fsensor:getEntity()
  if(not this) then return nil end
  local trV = this.TrO.Entity
  return (trV and trV or nil)
end
