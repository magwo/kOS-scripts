
SET MIN_THROTTLE TO 0.0.
SET MAX_THROTTLE TO 1.0.
SET ALLOWED_AOA TO 5.

SET atmosphereAirspeedPid TO PIDLOOP(0.15, 0.05, 0.03, MIN_THROTTLE, MAX_THROTTLE).
SET timeToApoapsisPid TO PIDLOOP(0.15, 0.05, 0.03, MIN_THROTTLE, MAX_THROTTLE).

function shipHasEmptyStage {
  LIST ENGINES IN elist.
  FOR e IN elist {
    IF e:FLAMEOUT {
      return true.
    }
  }
  return false.
}

function desiredAtmosphereSpeed {
  parameter altitude.
  SET altitudeOver12k TO MAX(altitude - 12000, 0). // Increase more agressively
  return 350 + altitude * (1/100) + altitudeOver12k * (1/100).
}

function performAtmosphericThrottleControl {
  SET desiredAirSpeed TO desiredAtmosphereSpeed(SHIP:ALTITUDE).
  print "airspeed is " + SHIP:AIRSPEED.
  print "desired airspeed is " + desiredAirSpeed.
  SET atmosphereAirspeedPid:setpoint TO desiredAirSpeed.
  SET thrott TO atmosphereAirspeedPid:update(TIME:SECONDS, SHIP:AIRSPEED).
  LOCK THROTTLE TO thrott.
}


// TODO: Add support for selecting steep or unsteep ascent (0.5, 0.7, 0.8 exponent?)
function getAtmosphericPitch {
  parameter curve.
  return 14*(SHIP:altitude*23.3/BODY:atm:height)^curve.
}

SET hdg TO 90.0.
SET targetAltitude TO BODY:atm:height * 1.2.
SET curveExponent TO 0.7.



function addSliderControl {
  parameter gui.
  parameter description.
  parameter currentValue.
  parameter minValue.
  parameter maxValue.
  parameter changeHandler.

  print "Max " + maxValue.
  print "Min " + minValue.
  print "Current " + currentValue.

  gui:ADDLABEL(description).
  LOCAL slider TO gui:ADDHSLIDER(currentValue, minValue, maxValue).
  SET slider:ONCHANGE TO changeHandler.
  return slider.
}


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
  print "curve is now " + curveExponent.
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


HUDTEXT( "Standing by to launch to apoapsis of " + targetAltitude + ", initial heading " + hdg + "°", 5, 2, 50, green, true).

WAIT UNTIL SHIP:MAXTHRUST > 0.
SAS OFF.
LOCK THROTTLE TO 1.
HUDTEXT( "Let's go", 3, 2, 50, green, true).
WAIT 0.2.


// // Antenna deployer
// WHEN SHIP:altitude > BODY:atm:height THEN {
//   AG1 ON.
//   AG1 OFF.
// }

// Main ascent loop
// TODO: Don't waste electricity
UNTIL SHIP:APOAPSIS > BODY:atm:height AND SHIP:PERIAPSIS > BODY:atm:height {
  CLEARSCREEN.

  print "hdg is now " + hdg.
  print "curve is now " + curveExponent.

  print "SHIP:APOAPSIS: " + SHIP:APOAPSIS.
  print "SHIP:PERIAPSIS: " + SHIP:PERIAPSIS.
  print "BODY:atm:height: " + BODY:atm:height.

  if SHIP:MAXTHRUST = 0 OR shipHasEmptyStage() {
    LOCK THROTTLE TO 0.2.
    WAIT 0.1.
    UNTIL STAGE:READY {
      WAIT 0.
    }
    STAGE.
    PRINT "Stage activated.".
    LOCK THROTTLE TO 0.4.
    WAIT 1.0.
    LOCK THROTTLE TO 0.5.
    WAIT 0.1.
    LOCK THROTTLE TO 0.6.
    WAIT 0.1.
    LOCK THROTTLE TO 0.7.
    WAIT 0.1.
    LOCK THROTTLE TO 0.8.
    WAIT 0.1.
    LOCK THROTTLE TO 1.0.
  }
  else if SHIP:AIRSPEED < 0.1 { // Simple extra check for clamps that are not released by first staging
    UNTIL STAGE:READY {
      WAIT 0.
    }
    STAGE.
  }

  // Throttle control
  if SHIP:ALTITUDE < body:atm:height * 0.15 {
    performAtmosphericThrottleControl().
  } else if SHIP:APOAPSIS < 100000 OR ETA:APOAPSIS > ETA:PERIAPSIS {
    LOCK THROTTLE TO 1.
  } else {
    if SHIP:APOAPSIS < targetAltitude * 0.85 {
      SET timeToApoapsisPid:setpoint TO 1500. // always go full throttle until at reasonable apoapsis
    } else if SHIP:PERIAPSIS < -BODY:RADIUS * 0.8 {
      SET timeToApoapsisPid:setpoint TO 120.
    } else if SHIP:PERIAPSIS < -BODY:RADIUS * 0.5 {
      SET timeToApoapsisPid:setpoint TO 100.
    } else if SHIP:PERIAPSIS < -BODY:RADIUS * 0.2 {
      SET timeToApoapsisPid:setpoint TO 80.
    } else if SHIP:PERIAPSIS < -BODY:RADIUS * 0.05 {
      SET timeToApoapsisPid:setpoint TO 20.
    } else {
      SET timeToApoapsisPid:setpoint TO 10.
    }
    print "ETA TO APOAPSIS: " + ETA:APOAPSIS.
    print "DESIRED ETA TO APO: " + timeToApoapsisPid:setpoint.
    SET thrott TO timeToApoapsisPid:update(TIME:SECONDS, ETA:APOAPSIS).
    LOCK THROTTLE TO thrott.
  }

  // Steering

  if SHIP:ALTITUDE < body:atm:height * 0.45 {
    // Normal atmospheric ascent steering
    SET progradePitch TO VANG(SHIP:SRFPROGRADE:VECTOR, UP:VECTOR).
    SET atmosphericPitch TO getAtmosphericPitch(curveExponent).

    // Never pitch more than n degrees from prograde
    SET desiredPitch TO MAX(progradePitch - ALLOWED_AOA, MIN(progradePitch + ALLOWED_AOA, atmosphericPitch)).

    LOCK STEERING TO HEADING(hdg, 90 - desiredPitch).
  }
  else {
    // Upper atmosphere steering
    SET progradePitch TO VANG(SHIP:PROGRADE:VECTOR, UP:VECTOR).
    SET MAX_PITCH TO 90.

    SET desiredPitchChange TO 90 - progradePitch.

    if desiredPitchChange < 3 AND SHIP:ALTITUDE < body:atm:height {
      // Ship altitude is very low - emergency pitch up
      SET desiredPitchChange TO desiredPitchChange - 40.
    }
    else if desiredPitchChange < 0 AND SHIP:ALTITUDE < body:atm:height * 1.5 {
      // Apoapsis is not very high - compensate and
      // exaggerate counter-pitch to attempt to get prograde above horizon more quickly
      SET desiredPitchChange TO desiredPitchChange - 10.
    }

    // Finally, never allow a positive value beyond logic
    SET desiredPitchChange TO MIN(0, desiredPitchChange).

    LOCK STEERING TO SHIP:PROGRADE * R(desiredPitchChange, 0, 0):VECTOR.
  }
  WAIT 0.
}

print "DONE!".

UNLOCK THROTTLE.
UNLOCK STEERING.
WAIT 0.3.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
WAIT 0.3.
SHUTDOWN.
