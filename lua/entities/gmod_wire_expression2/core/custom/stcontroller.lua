/******************************************************************************\
  My custom state LQ-PID controller type handling process variables
\******************************************************************************/

-- Register the type up here before the extension registration so that the state controller still works
registerType("stcontroller", "xsc", nil,
	nil,
	nil,
	function(retval)
		if(retval == nil) then return end
		if(not istable(retval)) then error("Return value is neither nil nor a table, but a "..type(retval).."!",0) end
	end,
	function(v)
		return (not istable(v))
	end
)

/******************************************************************************/

E2Lib.RegisterExtension("stcontroller", true, "Lets E2 chips have dedicated state controller objects")

local getTime = SysTime

local function getSign(nV) return ((nV > 0 and 1) or (nV < 0 and -1) or 0) end
local function getValue(kV,eV,pV) return (kV*getSign(eV)*math.abs(eV)^pV) end

local function makeSControl()
  local oSControl = {}; oSControl.mType = ""  -- Place to store the object
  oSControl.mTimO, oSControl.mTimN = getTime(), getTime() -- Time delta of the E2 chop for derivative
  oSControl.mErrO, oSControl.mErrN = 0, 0     -- Error state values
  oSControl.mvCon, oSControl.meInt = 0, true  -- Control value and integral enabled
  oSControl.mSatD, oSControl.mSatU = nil, nil -- Saturation limits and settings
  oSControl.mvP  , oSControl.mvI  , oSControl.mvD = 0, 0, 0 -- Term values
  oSControl.mkP  , oSControl.mkI  , oSControl.mkD = 0, 0, 0 -- P, I and D term gains
  oSControl.mpP  , oSControl.mpI  , oSControl.mpD = 1, 1, 1 -- Raise the error to power of that much
  oSControl.mbCmb, oSControl.mbInv, oSControl.mbOn = true, false, true
  return oSControl
end

--[[ **************************** CONTROLLER **************************** ]]

registerOperator("ass", "xsc", "xsc", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local      rhs = op2[1](self, op2)
	self.Scopes[scope][lhs] = rhs
	self.Scopes[scope].vclk[lhs] = true
	return rhs
end)

__e2setcost(1)
e2function stcontroller noSControl()
	return nil
end

__e2setcost(20)
e2function stcontroller newSControl()
  return makeSControl()
end

__e2setcost(3) -- Kp, Ti, Td
e2function stcontroller stcontroller:setGains(nP, nI, nD)
  if(not this) then return nil end
  if(nP <= 0) then return nil end
  this.mkP, this.mType = nP, "P"
  if(nI > 0) then
    this.mkI, this.mType = (nI / 2), (this.mType.."I")
    if(this.mbCmb) then this.mkI = this.mkI * this.mkP end
  end
  if(nD > 0) then
    this.mkD, this.mType = nD, (this.mType.."D")
    if(this.mbCmb) then this.mkD = this.mkD * this.mkP end
  end
  return this
end

__e2setcost(3)
e2function array stcontroller:getGains()
  if(not this) then return {0,0,0} end
  return {this.mkP, this.mkI, this.mkD}
end

__e2setcost(3)
e2function string stcontroller:getType()
  if(not this) then return "" end
  return this.mType
end

__e2setcost(3)
e2function stcontroller stcontroller:setWindup(nD, nU)
  if(not this) then return nil end
  if(nD < nU) then
    this.mSatD, this.mSatU = nD, nU end 
  return this
end

__e2setcost(3)
e2function array stcontroller:getWindup()
  if(not this) then return {0,0} end
  return {this.mSatD, this.mSatU}
end

__e2setcost(3)
e2function stcontroller stcontroller:setPower(nP, nI, nD)
  if(not this) then return nil end
  this.mpP, this.mpI, this.mpD = nP, nI, nD
  return this
end

__e2setcost(3)
e2function array stcontroller:getPower()
  if(not this) then return {0,0,0} end
  return {this.mpP, this.mpI, this.mpD}
end

__e2setcost(3)
e2function array stcontroller:getError()
  if(not this) then return {0,0} end
  return {this.mErrO, this.mErrN}
end

__e2setcost(3)
e2function number stcontroller:getErrorDelta()
  if(not this) then return 0 end
  return (this.mErrN - this.mErrO)
end

__e2setcost(3)
e2function array stcontroller:getTime()
  if(not this) then return {0,0} end
  return {this.mTimO, this.mTimN}
end

__e2setcost(3)
e2function number stcontroller:getTimeDelta()
  if(not this) then return 0 end
  return (this.mTimN - this.mTimO)
end

__e2setcost(3)
e2function stcontroller stcontroller:setFlagIntegral(number nN)
  if(not this) then return nil end
  this.meInt = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:getFlagIntegral()
  if(not this) then return nil end
  return (this.meInt and 1 or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:setCombined(number nN)
  if(not this) then return nil end
  this.mbCmb = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:getCombined()
  if(not this) then return nil end
  return (this.mbCmb and 1 or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:setInverted(number nN)
  if(not this) then return nil end
  this.mbInv = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:getInverted()
  if(not this) then return nil end
  return (this.mbInv and 1 or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:setToggle(number nN)
  if(not this) then return nil end
  this.mbOn = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:getToggle()
  if(not this) then return nil end
  return (this.mbOn and 1 or 0)
end

__e2setcost(3)
e2function number stcontroller:getControl()
  if(not this) then return nil end
  return (this.mvCon or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:resState()
  if(not this) then return nil end
  this.mErrO, this.mErrN = 0, 0 -- Reset the error
  this.mvCon, this.meInt = 0, true  -- Control value and integral enabled
  this.mvP, this.mvI, this.mvD = 0, 0, 0 -- Term values
  this.mTimO, this.mTimN = getTime(), getTime() -- Reset clock
  return this
end

__e2setcost(20)
e2function stcontroller stcontroller:setState(number nR, number nY)
  if(not this) then return nil end
  if(not this.mbOn) then
    this.mErrO, this.mErrN = 0, 0 -- Reset the error
    this.mvCon, this.meInt = 0, true  -- Control value and integral enabled
    this.mvP, this.mvI, this.mvD = 0, 0, 0 -- Term values
    this.mTimO, this.mTimN = getTime(), getTime() -- Reset clock
  else
    this.mTimO = this.mTimN; this.mTimN = getTime()
    this.mErrO = this.mErrN; this.mErrN = (this.mbInv and (nY-nR) or (nR-nY))
    local timDt = (this.mTimN - this.mTimO)
    if(this.mkP > 0) then -- P-Term
      this.mvP = getValue(this.mkP, this.mErrN, this.mpP) end
    if((this.mkI > 0) and (this.mErrN ~= 0) and this.meInt) then -- I-Term
      local arInt = (this.mErrN + this.mErrO) -- The current integral value
      this.mvI = getValue(this.mkI * timDt, arInt, this.mpI) + this.mvI end
    if((this.mkD > 0) and (this.mErrN ~= this.mErrO)) then -- D-Term
      local arDif = (this.mErrN - this.mErrO) -- Derivative dY/dT
      this.mvD = getValue(this.mkD * timDt, arDif, this.mpD) end
    this.mvCon = this.mvP + this.mvI + this.mvD  -- Calculate the control signal
    if(this.mSatD and this.mSatU) then -- Apply anti-windup effect
      if    (this.mvCon < this.mSatD) then this.mvCon, this.meInt = this.mSatD, false
      elseif(this.mvCon > this.mSatU) then this.mvCon, this.meInt = this.mSatU, false
      else this.meInt = true end
    end
  end; return this
end

__e2setcost(15)
e2function stcontroller stcontroller:dumpConsole(string sI)
  print("["..sI.."]["..this.mType.."] Properties:")
  print("  Gains: {P="..tostring(mkP)..", I="..tostring(mkI)..", D="..tostring(mkD).."}")
  print("  Power: {P="..tostring(mpP)..", I="..tostring(mpI)..", D="..tostring(mpD).."}\n")
  print("  Limit: {D="..tostring(mSatD)..",U="..tostring(mSatU).."}")
  print("  Error: {"..tostring(mErrO)..", "..tostring(mErrN).."}")
  print("  Value: ["..tostring(mvCon).."] {P="..tostring(mvP)..", I="..tostring(mvI)..", D="..tostring(mvD).."}")
  return this -- The dump method
end