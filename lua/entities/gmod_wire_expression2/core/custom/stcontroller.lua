/******************************************************************************\
  Expression 2 ability to process sttacets with LQ-PID controller
\******************************************************************************/

-- Register the type up here before the Extension Registration so that the Wire LQ-PID still works
registerType("stcontroller", "xsc", nil,
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

E2Lib.RegisterExtension("state_controller", true, "Lets E2 to include mutiple controller state objects")

--[[
 * NewControl: Class hovering state processing manager. Implements a controller unit
 * nTo   > Controller sampling time in seconds
 * sName > Controller hash name differentiation
]]--
local mtControl = {}
      mtControl.__index = mtControl
      mtControl.__tostring = function(oCon)
        return oCon:getType().."["..mtControl.__type.."] ["..tostring(oCon:getPeriod()).."]"..
          "{T="..oCon:getTune()..",W="..oCon:getWindup()..",P="..oCon:getPower().."}"
      end
function NewControl(nTo, sName)
  local mTo = (tonumber(nTo) or 0); if(mTo <= 0) then -- Sampling time [s]
    return LogStatus("NewControl: Sampling time <"..tostring(nTo).."> invalid",nil) end
  local self  = {}                 -- Place to store the methods
  local mfAbs = math.abs           -- Function used for error absolute
  local mfSgn = GetSign            -- Function used for error sign
  local mErrO, mErrN  = 0, 0       -- Error state values
  local mvCon, meInt  = 0, true    -- Control value and integral enabled
  local mvP, mvI, mvD = 0, 0, 0    -- Term values
  local mkP, mkI, mkD = 0, 0, 0    -- P, I and D term gains
  local mpP, mpI, mpD = 1, 1, 1    -- Raise the error to power of that much
  local mbCmb, mbInv, mbOn, mSatD, mSatU = true, false, true -- Saturation limits and settings
  local mName, mType, mTune, mWind, mPow = tostring(sName or "N/A"), "", "", "", ""
  setmetatable(self, mtControl)    -- Save the settings internally
  function self:getValue(kV,eV,pV) return (kV*mfSgn(eV)*mfAbs(eV)^pV) end
  function self:getGains() return mkP, mkI, mkD end
  function self:setEnInt(bSt) meInt = tobool(bSt); return self end
  function self:getEnInt() return meInt end
  function self:getError() return mErrO, mErrN end
  function self:getControl() return mvCon end
  function self:getTune() return mTune end
  function self:getWindup() return mWind end
  function self:getPower() return mPow end
  function self:getType() return mType end
  function self:getPeriod() return mTo end
  function self:setTune(sTune)
    local symComp = GetOpVar("OPSYM_COMPONENT")
    local sTune  = tostring(sTune or ""):Trim()
    local arTune = symComp:Explode(sTune)
    if(arTune[1] and (tonumber(arTune[1] or 0) > 0)) then
      mkP = (tonumber(arTune[1] or 0)) -- Proportional term
    else return LogStatus("NewControl.setTune: P-gain <"..tostring(arTune[1]).."> invalid",nil) end
    if(arTune[2] and (tonumber(arTune[2] or 0) > 0)) then
      mkI = (mTo / (2 * (tonumber(arTune[2] or 0)))) -- Discrete integral term approximation
      if(mbCmb) then mkI = mkI * mkP end
    else LogStatus("NewControl.setTune: I-gain <"..tostring(arTune[2]).."> skip") end
    if(arTune[3] and (tonumber(arTune[3] or 0) > 0)) then
      mkD = (tonumber(arTune[3] or 0) * mTo)  -- Discrete derivative term approximation
      if(mbCmb) then mkD = mkD * mkP end
    else LogStatus("NewControl.setTune: D-gain <"..tostring(arTune[3]).."> skip") end
    mType = ((mkP > 0) and "P" or "")..((mkI > 0) and "I" or "")..((mkD > 0) and "D" or "")
    -- Init multiple states using the table, so on duplication can be created easily
    mTune = tostring(sTune or ""); return LogStatus("NewControl.setTune: <"..tostring(sTune or "")..">", self)
  end
  function self:setWindup(sWind)
    local symComp = GetOpVar("OPSYM_COMPONENT")
    local sWind = tostring(sWind or ""):Trim()
    local arSat = symComp:Explode(sWind)
    if(arSat and tonumber(arSat[1]) and tonumber(arSat[2])) then
      arSat[1], arSat[2] = tonumber(arSat[1]), tonumber(arSat[2]) -- Saturation windup
      if(arSat[1] < arSat[2]) then
        mSatD, mSatU = arSat[1], arSat[2]
        LogStatus("NewControl.setWindup: Bounds {"..tostring(mSatD).."<"..tostring(mSatU).."} load")
      else LogStatus("NewControl.setWindup: Bounds {"..tostring(arSat[1]).."<"..tostring(arSat[2]).."} skip") end
    else LogStatus("NewControl.setWindup: Windup <"..tostring(sWind or "").."> skip") end
    mWind = tostring(sWind or ""); return LogStatus("NewControl.setWindup: OK", self)
  end
  function self:setPower(sPow)
    local symComp = GetOpVar("OPSYM_COMPONENT")
    local sPow  = tostring(sPow or ""):Trim()
    local arPow = symComp:Explode(sPow) -- Power ignored when missing
    if(arPow and tonumber(arPow[1]) and tonumber(arPow[2]) and tonumber(arPow[3])) then
      mpP = (tonumber(arPow[1]) or 1) -- Proportional power
      mpI = (tonumber(arPow[2]) or 1) -- Integral power
      mpD = (tonumber(arPow[3]) or 1) -- Derivative power
      LogStatus("NewControl.setPower: Power <"..tostring(mpP)..symComp..tostring(mpI)..symComp..tostring(mpD).."> load")
    else LogStatus("NewControl.setPower: Power <"..tostring(sPow or "").."> skip") end
    mPow = tostring(sPow or ""); return LogStatus("NewControl.setPower: OK", self)
  end
  function self:setFlags(bCmb, bInv)
    mbCmb, mbInv = tobool(bCmb), tobool(bInv)
    return LogStatus("NewControl.setFlags: OK", self) end
  function self:Toggle(bOn) -- Executed in realtime
    mbOn = tobool(bOn); return self end
  function self:Reset() -- Executed in realtime
    mErrO, mErrN, mvP, mvI, mvD, mvCon, meInt = 0, 0, 0, 0, 0, 0, true; return self end
  function self:Process(vRef,vOut) -- Executed in realtime
    if(not mbOn) then return self:Reset() end
    mErrO = mErrN -- Refresh error state sample
    mErrN = (mbInv and (vOut-vRef) or (vRef-vOut))
    if(mkP > 0) then -- P-Term
      mvP = self:getValue(mkP, mErrN, mpP) end
    if((mkI > 0) and (mErrN ~= 0) and meInt) then -- I-Term
      mvI = self:getValue(mkI, mErrN + mErrO, mpI) + mvI end
    if((mkD > 0) and (mErrN ~= mErrO)) then -- D-Term
      mvD = self:getValue(mkD, mErrN - mErrO, mpD) end
    mvCon = mvP + mvI + mvD  -- Calculate the control signal
    if(mSatD and mSatU) then -- Apply anti-windup effect
      if    (mvCon < mSatD) then mvCon, meInt = mSatD, false
      elseif(mvCon > mSatU) then mvCon, meInt = mSatU, false
      else meInt = true end
    end; return self
  end
  function self:Dump()
    local sLabel = IfSelect(not IsEmptyString(mType), mType.."-", mType)
    LogStatus("["..sLabel..mtControl.__type.."] Properties:")
    LogStatus("  Name : "..mName.." ["..tostring(mTo).."]s")
    LogStatus("  Param: {"..mTune.."}")
    LogStatus("  Gains: {P="..tostring(mkP)..", I="..tostring(mkI)..", D="..tostring(mkD).."}")
    LogStatus("  Power: {P="..tostring(mpP)..", I="..tostring(mpI)..", D="..tostring(mpD).."}\n")
    LogStatus("  Limit: {D="..tostring(mSatD)..",U="..tostring(mSatU).."}")
    LogStatus("  Error: {"..tostring(mErrO)..", "..tostring(mErrN).."}")
    LogStatus("  Value: ["..tostring(mvCon).."] {P="..tostring(mvP)..", I="..tostring(mvI)..", D="..tostring(mvD).."}")
    return self -- The dump method
  end; return LogStatus("NewControl: Create ["..mName.."]", self) -- The control object
end


local function newStateController(self, string sName)
  local data = {}
end