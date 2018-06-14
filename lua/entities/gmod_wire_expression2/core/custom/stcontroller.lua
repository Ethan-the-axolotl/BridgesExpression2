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

local function setStControllerGains(oStCon, vP, vI, vD)
  if(not oStCon) then return nil end
  local nP = (tonumber(vP) or 0)
  local nI = (tonumber(vI) or 0)
  local nD = (tonumber(vD) or 0)
  if(nP <= 0) then return nil end
  local sT = "P"; oStCon.mkP = nP
  if(nI > 0) then oStCon.mkI, sT = (nI / 2), (sT.."I")
    if(oStCon.mbCmb) then oStCon.mkI = oStCon.mkI * oStCon.mkP end
  end
  if(nD > 0) then oStCon.mkD, sT = nD, (sT.."D")
    if(oStCon.mbCmb) then oStCon.mkD = oStCon.mkD * oStCon.mkP end
  end; oStCon.mType[2] = sT; return oStCon
end

local function getPowerCode(nN)
  local nW, nF = math.modf(nN, 1)
  if(nN == 1) then return "Nr" end -- [Natural conventional][y=k*x]
  if(nN ==-1) then return "Rr" end -- [Reciprocal relation][y=1/k*x]
  if(nN == 0) then return "Sr" end -- [Sign function relay term][y=k*sign(x)]
  if(nF ~= 0) then
    if(nW ~= 0) then
      if(nF > 0) then return "Gs" end -- [Power positive fractional][y=x^( n); n> 1]
      if(nF < 0) then return "Gn" end -- [Power negative fractional][y=x^(-n); n<-1]
    else
      if(nF > 0) then return "Fs" end -- [Power positive fractional][y=x^( n); 0<n< 1]
      if(nF < 0) then return "Fn" end -- [Power negative fractional][y=x^(-n); 0>n>-1]
    end
  else
    if(nN > 0) then return "Ex" end -- [Exponential relation][y=x^n]
    if(nN < 0) then return "Er" end -- [Reciprocal-exp relation][y=1/x^n]
  end
  return "Xx" -- [Invalid settings][N/A]
end

local function setStControllerPower(oStCon, vP, vI, vD)
  if(not oStCon) then return nil end
  oStCon.mpP = (tonumber(vP) or 1)
  oStCon.mpI = (tonumber(vI) or 1)
  oStCon.mpD = (tonumber(vD) or 1)
  oStCon.mType[1] = ("(%s%s%s)"):format(getPowerCode(oStCon.mpP),
    getPowerCode(oStCon.mpI), getPowerCode(oStCon.mpD))
  return oStCon
end

local function resStControllerState(oStCon)
  if(not oStCon) then return nil end
  oStCon.mErrO, oStCon.mErrN = 0, 0 -- Reset the error
  oStCon.mvCon, oStCon.meInt = 0, true -- Control value and integral enabled
  oStCon.mvP, oStCon.mvI, oStCon.mvD = 0, 0, 0 -- Term values
  oStCon.mTimN = getTime(); oStCon.mTimO = oStCon.mTimN; -- Update clock
  return oStCon
end

local function makeStController(nTo)
  local oStCon = {}; oStCon.mnTo = tonumber(nTo) -- Place to store the object
  if(oStCon.mnTo and oStCon.mnTo <= 0) then return nil end
  oStCon.mTimN = getTime(); oStCon.mTimO = oStCon.mTimN; -- Reset clock
  oStCon.mErrO, oStCon.mErrN, oStCon.mType = 0, 0, {"(NrNrNr)","N/A"} -- Error state values
  oStCon.mvCon, oStCon.mTimB, oStCon.meInt = 0, 0, true -- Control value and integral enabled
  oStCon.mBias, oStCon.mSatD, oStCon.mSatU = 0, nil, nil -- Saturation limits and settings
  oStCon.mvP, oStCon.mvI, oStCon.mvD = 0, 0, 0 -- Term values
  oStCon.mkP, oStCon.mkI, oStCon.mkD = 0, 0, 0 -- P, I and D term gains
  oStCon.mpP, oStCon.mpI, oStCon.mpD = 1, 1, 1 -- Raise the error to power of that much
  oStCon.mbCmb, oStCon.mbInv, oStCon.mbOn, oStCon.mbMan = false, false, false, false
  oStCon.mvMan = 0; return oStCon
end

--[[ **************************** CONTROLLER **************************** ]]

registerOperator("ass", "xsc", "xsc", function(self, args)
  local lhs, op2, scope = args[2], args[3], args[4]
  local rhs = op2[1](self, op2)
  self.Scopes[scope][lhs] = rhs
  self.Scopes[scope].vclk[lhs] = true
  return rhs
end)

__e2setcost(1)
e2function stcontroller noStController()
  return nil
end

__e2setcost(20)
e2function stcontroller newStController()
  return makeStController()
end

__e2setcost(20)
e2function stcontroller newStController(number nTo)
  return makeStController(nTo)
end

__e2setcost(7)
e2function stcontroller stcontroller:setGain(number nP)
  return setStControllerGains(this, nP, nil, nil)
end

__e2setcost(7)
e2function stcontroller stcontroller:setGainPI(number nP, number nI)
  return setStControllerGains(this, nP, nI, nil)
end

__e2setcost(7)
e2function stcontroller stcontroller:setGainPI(vector2 vV)
  return setStControllerGains(this, vV[1], vV[2], nil)
end

__e2setcost(7)
e2function stcontroller stcontroller:setGainPD(number nP, number nD)
  return setStControllerGains(this, nP, nil, nD)
end

__e2setcost(7)
e2function stcontroller stcontroller:setGainPD(vector2 vV)
  return setStControllerGains(this, vV[1], nil, vV[2])
end

__e2setcost(7)
e2function stcontroller stcontroller:setGain(number nP, number nI, number nD)
  return setStControllerGains(this, nP, nI, nD)
end

__e2setcost(7)
e2function stcontroller stcontroller:setGain(array aA)
  return setStControllerGains(this, aA[1], aA[2], aA[3])
end

__e2setcost(7)
e2function stcontroller stcontroller:setGain(vector vV)
  return setStControllerGains(this, vV[1], vV[2], vV[3])
end

__e2setcost(3)
e2function array stcontroller:getGain()
  if(not this) then return {0,0,0} end
  return {this.mkP, this.mkI, this.mkD}
end

__e2setcost(3)
e2function vector stcontroller:getGain()
  if(not this) then return {0,0,0} end
  return {this.mkP, this.mkI, this.mkD}
end

__e2setcost(3)
e2function number stcontroller:getGainP()
  if(not this) then return nil end
  return this.mkP
end

__e2setcost(3)
e2function number stcontroller:getGainI()
  if(not this) then return nil end
  return this.mkI
end

__e2setcost(3)
e2function number stcontroller:getGainD()
  if(not this) then return nil end
  return this.mkD
end

__e2setcost(3)
e2function stcontroller stcontroller:setBias(number nN)
  if(not this) then return nil end
  this.mBias = nN; return this
end

__e2setcost(3)
e2function number stcontroller:getBias(number nN)
  if(not this) then return 0 end
  return this.mBias
end

__e2setcost(3)
e2function string stcontroller:getType()
  if(not this) then return "" end
  return table.concat(this.mType, "-")
end

__e2setcost(3)
e2function stcontroller stcontroller:setWindup(number nD, number nU)
  if(not this) then return nil end
  if(nD < nU) then this.mSatD, this.mSatU = nD, nU end
  return this
end

__e2setcost(3)
e2function stcontroller stcontroller:remWindup()
  if(not this) then return nil end
  this.mSatD, this.mSatU = nil, nil; return this
end

__e2setcost(3)
e2function stcontroller stcontroller:setWindupD(number nD)
  if(not this) then return nil end
  this.mSatD = nD; return this
end

__e2setcost(3)
e2function stcontroller stcontroller:getWindupD(number nD)
  if(not this) then return nil end
  return (this.mSatD or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:remWindupD(number nD)
  if(not this) then return nil end
  this.mSatD = nil; return this
end

__e2setcost(3)
e2function stcontroller stcontroller:setWindupU(number nU)
  if(not this) then return nil end
  this.mSatU = nU; return this
end

__e2setcost(3)
e2function stcontroller stcontroller:getWindupU(number nU)
  if(not this) then return nil end
  return (this.mSatU or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:remWindupU(number nU)
  if(not this) then return nil end
  this.mSatU = nil; return this
end

__e2setcost(8)
e2function stcontroller stcontroller:setPower(number nP)
  return setStControllerPower(this, nP, nil, nil)
end

__e2setcost(8)
e2function stcontroller stcontroller:setPowerPI(number nP, number nI)
  return setStControllerPower(this, nP, nI, nil)
end

__e2setcost(8)
e2function stcontroller stcontroller:setPowerPI(vector2 vV)
  return setStControllerPower(this, vV[1], vV[2], nil)
end

__e2setcost(8)
e2function stcontroller stcontroller:setPowerPD(number nP, number nD)
  return setStControllerPower(this, nP, nil, nD)
end

__e2setcost(8)
e2function stcontroller stcontroller:setPowerPD(vector2 vV)
  return setStControllerPower(this, vV[1], nil, vV[2])
end

__e2setcost(8)
e2function stcontroller stcontroller:setPower(number nP, number nI, number nD)
  return setStControllerPower(this, nP, nI, nD)
end

__e2setcost(8)
e2function stcontroller stcontroller:setPower(array aA)
  return setStControllerPower(this, aA[1], aA[2], aA[3])
end

__e2setcost(8)
e2function stcontroller stcontroller:setPower(vector vV)
  return setStControllerPower(this, vV[1], vV[2], vV[3])
end

__e2setcost(3)
e2function array stcontroller:getPower()
  if(not this) then return {0,0,0} end
  return {this.mpP, this.mpI, this.mpD}
end

__e2setcost(3)
e2function vector stcontroller:getPower()
  if(not this) then return {0,0,0} end
  return {this.mpP, this.mpI, this.mpD}
end

__e2setcost(3)
e2function number stcontroller:getPowerP()
  if(not this) then return nil end
  return this.mpP
end

__e2setcost(3)
e2function number stcontroller:getPowerI()
  if(not this) then return nil end
  return this.mpI
end

__e2setcost(3)
e2function number stcontroller:getPowerD()
  if(not this) then return nil end
  return this.mpD
end

__e2setcost(3)
e2function number stcontroller:getErrorNow()
  if(not this) then return 0 end
  return this.mErrN
end

__e2setcost(3)
e2function number stcontroller:getErrorOld()
  if(not this) then return 0 end
  return this.mErrO
end

__e2setcost(3)
e2function number stcontroller:getErrorDelta()
  if(not this) then return 0 end
  return (this.mErrN - this.mErrO)
end

__e2setcost(3)
e2function number stcontroller:getTimeNow()
  if(not this) then return 0 end
  return this.mTimN
end

__e2setcost(3)
e2function number stcontroller:getTimeOld()
  if(not this) then return 0 end
  return this.mTimO
end

__e2setcost(3)
e2function number stcontroller:getTimeDelta()
  if(not this) then return 0 end
  return (this.mTimN - this.mTimO)
end

__e2setcost(3)
e2function number stcontroller:getTimeBench()
  if(not this) then return nil end
  return (this.mTimB or 0)
end

__e2setcost(3)
e2function number stcontroller:getTimeRatio()
  if(not this) then return nil end
  local timDt = (this.mTimN - this.mTimO)
  if(timDt == 0) then return timDt and
  return ((this.mTimB or 0) / timDt)
end

__e2setcost(3)
e2function stcontroller stcontroller:isIntegrating(number nN)
  if(not this) then return nil end
  this.meInt = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:isIntegrating()
  if(not this) then return nil end
  return (this.meInt and 1 or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:isCombined(number nN)
  if(not this) then return nil end
  this.mbCmb = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:isCombined()
  if(not this) then return nil end
  return (this.mbCmb and 1 or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:isManual(number nN)
  if(not this) then return nil end
  this.mbMan = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:isManual()
  if(not this) then return nil end
  return (this.mbMan and 1 or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:setManual(number nN)
  if(not this) then return nil end
  this.mvMan = nN; return this
end

__e2setcost(3)
e2function number stcontroller:getManual()
  if(not this) then return nil end
  return (this.mvMan or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:isInverted(number nN)
  if(not this) then return nil end
  this.mbInv = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:isInverted()
  if(not this) then return nil end
  return (this.mbInv and 1 or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:isActive(number nN)
  if(not this) then return nil end
  this.mbOn = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:isActive()
  if(not this) then return nil end
  return (this.mbOn and 1 or 0)
end

__e2setcost(3)
e2function number stcontroller:getControl()
  if(not this) then return nil end
  return (this.mvCon or 0)
end

__e2setcost(3)
e2function array stcontroller:getControlTerm()
  if(not this) then return nil end
  return {this.mvP, this.mvI, this.mvD}
end

__e2setcost(3)
e2function vector stcontroller:getControlTerm()
  if(not this) then return nil end
  return {this.mvP, this.mvI, this.mvD}
end

__e2setcost(3)
e2function number stcontroller:getControlTermP()
  if(not this) then return nil end
  return this.mvP
end

__e2setcost(3)
e2function number stcontroller:getControlTermI()
  if(not this) then return nil end
  return this.mvI
end

__e2setcost(3)
e2function number stcontroller:getControlTermD()
  if(not this) then return nil end
  return this.mvD
end

__e2setcost(3)
e2function stcontroller stcontroller:resState()
  return resStControllerState(this)
end

__e2setcost(20)
e2function stcontroller stcontroller:setState(number nR, number nY)
  if(not this) then return nil end
  if(this.mbOn) then
    if(this.mbMan) then
      this.mvCon = (this.mvMan + this.mBias); return this end
    this.mTimO = this.mTimN; this.mTimN = getTime()
    this.mErrO = this.mErrN; this.mErrN = (this.mbInv and (nY-nR) or (nR-nY))
    local timDt = (this.mnTo and this.mnTo or (this.mTimN - this.mTimO))
    if(this.mkP > 0) then -- P-Term
      this.mvP = getValue(this.mkP, this.mErrN, this.mpP) end
    if((this.mkI > 0) and (this.mErrN ~= 0) and this.meInt) then -- I-Term
      local arInt = (this.mErrN + this.mErrO) * timDt -- The current integral value
      this.mvI = getValue(this.mkI * timDt, arInt, this.mpI) + this.mvI end
    if((this.mkD > 0) and (this.mErrN ~= this.mErrO) and (timDt ~= 0)) then -- D-Term
      local arDif = (this.mErrN - this.mErrO) / timDt -- Derivative dY/dT
      this.mvD = getValue(this.mkD * timDt, arDif, this.mpD) end
    this.mvCon = this.mvP + this.mvI + this.mvD -- Calculate the control signal
    if(this.mSatD and this.mvCon < this.mSatD) then -- Saturate lower limit
      this.mvCon, this.meInt = this.mSatD, false -- Integral is disabled
    elseif(this.mSatU and this.mvCon > this.mSatU) then -- Saturate upper limit
      this.mvCon, this.meInt = this.mSatU, false -- Integral is disabled
    else this.meInt = true end -- Saturation disables the integrator
    this.mvCon = (this.mvCon + this.mBias) -- Apply the saturated signal bias
    this.mTimB = (getTime() - this.mTimN) -- Benchmark the process
  else return resStControllerState(this) end; return this
end

__e2setcost(15)
e2function stcontroller stcontroller:dumpConsole(string sI)
  print("["..sI.."]["..tostring(this.mnTo or "X").."]["..table.concat(this.mType,"-").."]["..tostring(this.mTimN).."] Data:")
  print(" Human: ["..tostring(this.mbMan).."] {V="..tostring(this.mvMan)..", B="..tostring(this.mBias).."}" )
  print(" Gains: {P="..tostring(this.mkP)..", I="..tostring(this.mkI)..", D="..tostring(this.mkD).."}")
  print(" Power: {P="..tostring(this.mpP)..", I="..tostring(this.mpI)..", D="..tostring(this.mpD).."}")
  print(" Limit: {D="..tostring(this.mSatD)..", U="..tostring(this.mSatU).."}")
  print(" Error: {O="..tostring(this.mErrO)..", N="..tostring(this.mErrN).."}")
  print(" Value: ["..tostring(this.mvCon).."] {P="..tostring(this.mvP)..", I="..tostring(this.mvI)..", D=" ..tostring(this.mvD).."}")
  print(" Flags: ["..tostring(this.mbOn).."] {C="..tostring(this.mbCmb)..", R=" ..tostring(this.mbInv)..", I="..tostring(this.meInt).."}")
  return this -- The dump method
end
