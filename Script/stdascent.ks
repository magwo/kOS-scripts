RUN "0:/util_ui.ks".
RUN "0:/util_generic.ks".
RUN "0:/util_ascent.ks".

print getTimeStampedString(SHIP:SHIPNAME + " is in startup").

LOCAL ALLOWED_AOA TO 5.

SET atmosphereAirspeedPid TO createAtmosphericAirSpeedPid().
SET timeToApoapsisPid TO createTimeToApoapsisPid().


SET hdg TO 90.0.
SET targetAltitude TO BODY:atm:height * 1.2.
SET curveExponent TO 0.7.

LOCAL gui IS GUI(240).
LOCAL apoapsisLabel IS gui:ADDLABEL("").
LOCAL hdgLabel IS gui:ADDLABEL("").
LOCAL curveLabel IS gui:ADDLABEL("").


function updateApoDisplay {
  parameter value.
  SET targetAltitude TO value.
  SET apoapsisLabel:TEXT TO ROUND(value / 1000) + " km".
}

function updateHeadingDisplay {
  parameter value.
  SET hdg TO value.
  SET hdgLabel:TEXT TO ROUND(value) + "°".
}

function updateCurveDisplay {
  parameter value.
  SET curveExponent TO value.
  LOCAL curveDesc TO "Normal".
  if value < 0.65 {
    SET curveDesc TO "Steep (for low twr)".
  } else if value > 0.81 {
    SET curveDesc TO "Flat (for high twr)".
  }
  SET curveLabel:TEXT TO ROUND(value, 3) + " (" + curveDesc + ")".
}

LOCAL desiredApoSlider TO addSliderControl(gui, "Target apoapsis", targetAltitude, BODY:atm:height, BODY:atm:height * 1.5, updateApoDisplay@).
LOCAL desiredHdgSlider TO addSliderControl(gui, "Launch heading", hdg, 0, 360, updateHeadingDisplay@).
LOCAL desiredCurveSlider TO addSliderControl(gui, "Curve", curveExponent, 0.5, 0.95, updateCurveDisplay@).

updateApoDisplay(targetAltitude).
updateHeadingDisplay(hdg).
updateCurveDisplay(curveExponent).

LOCAL ok TO gui:ADDBUTTON("OK").
gui:SHOW().

LOCAL isDone IS FALSE.
UNTIL isDone
{
  if (ok:TAKEPRESS)
    SET isDone TO TRUE.
  WAIT 0.1.
}
gui:HIDE().


print getTimeStampedString("Standing by to launch to "+ ROUND(targetAltitude/1000) + "km, hdg " + ROUND(hdg) + "°").
print getTimeStampedString("Waiting for non-zero thrust").

WAIT UNTIL SHIP:MAXTHRUST > 0.
print getTimeStampedString("Thrust detected, assuming control...").
SAS OFF.
LOCK THROTTLE TO 1.
WAIT 0.2.

// Main ascent loop
// TODO: Don't waste electricity

print getTimeStampedString("Activating lower atmosphere guidance...").
UNTIL SHIP:ALTITUDE > body:atm:height * 0.45 {
  autoStage(getTimeStampedString@).
  performAtmosphericThrottleControl(atmosphereAirspeedPid).
  performAtmosphericSteering(curveExponent, ALLOWED_AOA).
  WAIT 0.01.
}

print getTimeStampedString("Activating upper atmosphere guidance...").
UNTIL SHIP:APOAPSIS > BODY:atm:height AND SHIP:PERIAPSIS > BODY:atm:height {
  autoStage(getTimeStampedString@).
  performUpperAtmosphereSteering().

  // Throttle control
  if SHIP:APOAPSIS < 100000 OR ETA:APOAPSIS > ETA:PERIAPSIS {
    LOCK THROTTLE TO 1.
  } else {
    if SHIP:APOAPSIS < targetAltitude * 0.85 {
      SET timeToApoapsisPid:setpoint TO 1500. // always go full throttle until at reasonable apoapsis
    } else if SHIP:PERIAPSIS < -BODY:RADIUS * 0.8 {
      SET timeToApoapsisPid:setpoint TO 120.
    } else if SHIP:PERIAPSIS < -BODY:RADIUS * 0.2 {
      SET timeToApoapsisPid:setpoint TO 80.
    } else if SHIP:PERIAPSIS < -BODY:RADIUS * 0.05 {
      SET timeToApoapsisPid:setpoint TO 20.
    } else {
      SET timeToApoapsisPid:setpoint TO 10.
    }
    // print "DESIRED ETA TO APO: " + timeToApoapsisPid:setpoint.
    SET thrott TO timeToApoapsisPid:update(TIME:SECONDS, ETA:APOAPSIS).
    LOCK THROTTLE TO thrott.
  }

  WAIT 0.
}

print getTimeStampedString("Orbit reached: " + ROUND(SHIP:APOAPSIS / 1000) + "x" + ROUND(SHIP:PERIAPSIS / 1000) + " km, " + ROUND(SHIP:ORBIT:INCLINATION) + "°").


UNLOCK THROTTLE.
UNLOCK STEERING.
WAIT 0.3.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
print getTimeStampedString("Shutting down guidance computer").
WAIT 0.3.
SHUTDOWN.
