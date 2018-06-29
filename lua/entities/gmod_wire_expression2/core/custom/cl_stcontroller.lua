--[[ ******************************************************************************
 My custom state LQ-PID controller type handling process variables
****************************************************************************** ]]--

local xsc, par, trm = "state controller", {}, {"proportional", "integral", "derivative"}
par[1] = {"sampling time", "control bias", "controller type"}
par[2] = {trm[1].." term gain", trm[2].." term gain", trm[3].." term gain"}
par[3] = {trm[1].." term power", trm[2].." term power", trm[3].." term power"}
par[4] = {"windup lower bound", "windup upper bound"}
par[5] = {"process passed error", "process current error", "process error delta"}
par[6] = {"process passed time", "process current time", "process time delta", "process benchmark time", "process time ratio"}
E2Helper.Descriptions["noStController()"] = "Returns invalid "..xsc.." object"
E2Helper.Descriptions["newStController()"] = "Returns "..xsc.." object with dynamic "..par[1][1]
E2Helper.Descriptions["newStController(n)"] = "Returns "..xsc.." object with static "..par[1][1]
E2Helper.Descriptions["setGainP(xsc:n)"] = "Updates the "..xsc.." "..par[2][1]
E2Helper.Descriptions["setGainI(xsc:n)"] = "Updates the "..xsc.." "..par[2][2]
E2Helper.Descriptions["setGainD(xsc:n)"] = "Updates the "..xsc.." "..par[2][3]
E2Helper.Descriptions["setGainPI(xsc:nn)"] = "Updates the "..xsc.." "..par[2][1].." and "..par[2][2]
E2Helper.Descriptions["setGainPI(xsc:xv2)"] = "Updates the "..xsc.." "..par[2][1].." and "..par[2][2]
E2Helper.Descriptions["setGainPI(xsc:r)"] = "Updates the "..xsc.." "..par[2][1].." and "..par[2][2]
E2Helper.Descriptions["setGainPD(xsc:nn)"] = "Updates the "..xsc.." "..par[2][1].." and "..par[2][3]
E2Helper.Descriptions["setGainPD(xsc:xv2)"] = "Updates the "..xsc.." "..par[2][1].." and "..par[2][3]
E2Helper.Descriptions["setGainPD(xsc:r)"] = "Updates the "..xsc.." "..par[2][1].." and "..par[2][3]
E2Helper.Descriptions["setGainID(xsc:nn)"] = "Updates the "..xsc.." "..par[2][2].." and "..par[2][3]
E2Helper.Descriptions["setGainID(xsc:xv2)"] = "Updates the "..xsc.." "..par[2][3].." and "..par[2][3]
E2Helper.Descriptions["setGainID(xsc:r)"] = "Updates the "..xsc.." "..par[2][2].." and "..par[2][3]
E2Helper.Descriptions["setGain(xsc:nnn)"] = "Updates the "..xsc.." "..par[2][1]..", "..par[2][2].." and "..par[2][3]
E2Helper.Descriptions["setGain(xsc:v)"] = "Updates the "..xsc.." "..par[2][1]..", "..par[2][2].." and "..par[2][3]
E2Helper.Descriptions["setGain(xsc:r)"] = "Updates the "..xsc.." "..par[2][1]..", "..par[2][2].." and "..par[2][3]
E2Helper.Descriptions["remGainP(xsc:)"] = "Removes the "..xsc.." "..par[2][1]
E2Helper.Descriptions["remGainI(xsc:)"] = "Removes the "..xsc.." "..par[2][2]
E2Helper.Descriptions["remGainD(xsc:)"] = "Removes the "..xsc.." "..par[2][3]
E2Helper.Descriptions["remGainPI(xsc:)"] = "Removes the "..xsc.." "..par[2][1].." and "..par[2][2]
E2Helper.Descriptions["remGainPD(xsc:)"] = "Removes the "..xsc.." "..par[2][1].." and "..par[2][3]
E2Helper.Descriptions["remGainID(xsc:)"] = "Removes the "..xsc.." "..par[2][2].." and "..par[2][3]
E2Helper.Descriptions["remGain(xsc:)"] = "Removes the "..xsc.." "..par[2][1]..", "..par[2][2].." and "..par[2][3]
E2Helper.Descriptions["getGain(xsc:)"] = "Returns the "..xsc.." "..par[2][1]..", "..par[2][2].." and "..par[2][3]
E2Helper.Descriptions["getGainPI(xsc:)"] = "Returns the "..xsc.." "..par[2][1].." and "..par[2][2]
E2Helper.Descriptions["getGainPD(xsc:)"] = "Returns the "..xsc.." "..par[2][1].." and "..par[2][3]
E2Helper.Descriptions["getGainID(xsc:)"] = "Returns the "..xsc.." "..par[2][2].." and "..par[2][3]
E2Helper.Descriptions["getGainP(xsc:)"] = "Returns the "..xsc.." "..par[2][1]
E2Helper.Descriptions["getGainI(xsc:)"] = "Returns the "..xsc.." "..par[2][2]
E2Helper.Descriptions["getGainD(xsc:)"] = "Returns the "..xsc.." "..par[2][3]
E2Helper.Descriptions["setBias(xsc:n)"] = "Updates the "..xsc.." "..par[1][2]
E2Helper.Descriptions["getBias(xsc:)"] = "Returns the "..xsc.." "..par[1][2]
E2Helper.Descriptions["getType(xsc:)"] = "Returns the "..xsc.." "..par[1][3]
E2Helper.Descriptions["setWindup(xsc:nn)"] = "Updates the "..xsc.." "..par[4][1].." and "..par[4][2]
E2Helper.Descriptions["setWindup(xsc:r)"] = "Updates the "..xsc.." "..par[4][1].." and "..par[4][2]
E2Helper.Descriptions["setWindup(xsc:xv2)"] = "Updates the "..xsc.." "..par[4][1].." and "..par[4][2]
E2Helper.Descriptions["setWindupD(xsc:n)"] = "Updates the "..xsc.." "..par[4][1]
E2Helper.Descriptions["setWindupU(xsc:n)"] = "Updates the "..xsc.." "..par[4][2]
E2Helper.Descriptions["remWindup(xsc:)"] = "Rmoves the "..xsc.." "..par[4][1].." and "..par[4][2]
E2Helper.Descriptions["remWindupD(xsc:)"] = "Rmoves the "..xsc.." "..par[4][1]
E2Helper.Descriptions["remWindupU(xsc:)"] = "Rmoves the "..xsc.." "..par[4][2]
E2Helper.Descriptions["getWindup(xsc:)"] = "Returns the "..xsc.." "..par[4][1].." and "..par[4][2]
E2Helper.Descriptions["getWindupD(xsc:)"] = "Returns the "..xsc.." "..par[4][1]
E2Helper.Descriptions["getWindupU(xsc:)"] = "Returns the "..xsc.." "..par[4][2]
E2Helper.Descriptions["setPowerP(xsc:n)"] = "Updates the "..xsc.." "..par[3][1]
E2Helper.Descriptions["setPowerI(xsc:n)"] = "Updates the "..xsc.." "..par[3][2]
E2Helper.Descriptions["setPowerD(xsc:n)"] = "Updates the "..xsc.." "..par[3][3]
E2Helper.Descriptions["setPowerPI(xsc:nn)"] = "Updates the "..xsc.." "..par[3][1].." and "..par[3][2]
E2Helper.Descriptions["setPowerPI(xsc:xv2)"] = "Updates the "..xsc.." "..par[3][1].." and "..par[3][2]
E2Helper.Descriptions["setPowerPI(xsc:r)"] = "Updates the "..xsc.." "..par[3][1].." and "..par[3][2]
E2Helper.Descriptions["setPowerPD(xsc:nn)"] = "Updates the "..xsc.." "..par[3][1].." and "..par[3][3]
E2Helper.Descriptions["setPowerPD(xsc:xv2)"] = "Updates the "..xsc.." "..par[3][1].." and "..par[3][3]
E2Helper.Descriptions["setPowerPD(xsc:r)"] = "Updates the "..xsc.." "..par[3][1].." and "..par[3][3]
E2Helper.Descriptions["setPowerID(xsc:nn)"] = "Updates the "..xsc.." "..par[3][2].." and "..par[3][3]
E2Helper.Descriptions["setPowerID(xsc:xv2)"] = "Updates the "..xsc.." "..par[3][3].." and "..par[3][3]
E2Helper.Descriptions["setPowerID(xsc:r)"] = "Updates the "..xsc.." "..par[3][2].." and "..par[3][3]
E2Helper.Descriptions["setPower(xsc:nnn)"] = "Updates the "..xsc.." "..par[3][1]..", "..par[3][2].." and "..par[3][3]
E2Helper.Descriptions["setPower(xsc:v)"] = "Updates the "..xsc.." "..par[3][1]..", "..par[3][2].." and "..par[3][3]
E2Helper.Descriptions["setPower(xsc:r)"] = "Updates the "..xsc.." "..par[3][1]..", "..par[3][2].." and "..par[3][3]
E2Helper.Descriptions["getPower(xsc:)"] = "Returns the "..xsc.." "..par[3][1]..", "..par[3][2].." and "..par[3][3]
E2Helper.Descriptions["getPowerPI(xsc:)"] = "Returns the "..xsc.." "..par[3][1].." and "..par[3][2]
E2Helper.Descriptions["getPowerPD(xsc:)"] = "Returns the "..xsc.." "..par[3][1].." and "..par[3][3]
E2Helper.Descriptions["getPowerID(xsc:)"] = "Returns the "..xsc.." "..par[3][2].." and "..par[3][3]
E2Helper.Descriptions["getPowerP(xsc:)"] = "Returns the "..xsc.." "..par[3][1]
E2Helper.Descriptions["getPowerI(xsc:)"] = "Returns the "..xsc.." "..par[3][2]
E2Helper.Descriptions["getPowerD(xsc:)"] = "Returns the "..xsc.." "..par[3][3]
E2Helper.Descriptions["getErrorNow(xsc:)"] = "Returns the "..xsc.." "..par[5][2]
E2Helper.Descriptions["getErrorOld(xsc:)"] = "Returns the "..xsc.." "..par[5][1]
E2Helper.Descriptions["getErrorDelta(xsc:)"] = "Returns the "..xsc.." "..par[5][3]
E2Helper.Descriptions["getTimeNow(xsc:)"] = "Returns the "..xsc.." "..par[6][2]
E2Helper.Descriptions["getTimeOld(xsc:)"] = "Returns the "..xsc.." "..par[6][1]
E2Helper.Descriptions["getTimeDelta(xsc:)"] = "Returns the "..xsc.." "..par[6][3]
E2Helper.Descriptions["getTimeBench(xsc:)"] = "Returns the "..xsc.." "..par[6][4]
E2Helper.Descriptions["getTimeRatio(xsc:)"] = "Returns the "..xsc.." "..par[6][5]
E2Helper.Descriptions["setIsIntegrating(xsc:n)"] = "Updates the "..trm[2].." enabled flag"
E2Helper.Descriptions["isIntegrating(xsc:)"] = "Checks the "..trm[2].." enabled flag"
E2Helper.Descriptions["setIsCombined(xsc:n)"] = "Updates the combined flag spreading "..par[2][1].." across others"
E2Helper.Descriptions["isCombined(xsc:)"] = "Checks the "..xsc.." combined flag spreading "..par[2][1].." across others"
E2Helper.Descriptions["setIsManual(xsc:n)"] = "Updates the "..xsc.." manual control flag"
E2Helper.Descriptions["isManual(xsc:)"] = "Checks the "..xsc.." manual control flag"
E2Helper.Descriptions["setIsManual(xsc:n)"] = "Updates the "..xsc.." manual control signal value"
E2Helper.Descriptions["getManual(xsc:)"] = "Returns the "..xsc.." manual control signal value"
E2Helper.Descriptions["setIsInverted(xsc:n)"] = "Updates the "..xsc.." inverted feedback flag of the reference and set point"
E2Helper.Descriptions["isInverted(xsc:)"] = "Checks the "..xsc.." inverted feedback flag of the reference and set point"
E2Helper.Descriptions["setIsActive(xsc:n)"] = "Updates the "..xsc.." activated working flag"
E2Helper.Descriptions["isActive(xsc:)"] = "Checks the "..xsc.." activated working flag"
E2Helper.Descriptions["getControl(xsc:)"] = "Returns the "..xsc.." automated control signal value"
E2Helper.Descriptions["getControlTerm(xsc:)"] = "Returns the "..xsc.." automated control term values"
E2Helper.Descriptions["getControlTerm(xsc:)"] = "Returns the "..xsc.." automated control term values"
E2Helper.Descriptions["getManual(xsc:)"] = "Returns the "..xsc.." manual control signal value"
E2Helper.Descriptions["getControlTermP(xsc:)"] = "Returns the "..xsc.." "..trm[1].." automated control term value"
E2Helper.Descriptions["getControlTermI(xsc:)"] = "Returns the "..xsc.." "..trm[2].." automated control term value"
E2Helper.Descriptions["getControlTermD(xsc:)"] = "Returns the "..xsc.." "..trm[3].." automated control term value"
E2Helper.Descriptions["resState(xsc:)"] = "Resets the "..xsc.." automated internal parameters"
E2Helper.Descriptions["setState(xsc:nn)"] = "Processes the "..xsc.." automated internal parameters"
E2Helper.Descriptions["dumpConsole(xsc:s)"] = "Dumps the "..xsc.." internal parameters into the console"
