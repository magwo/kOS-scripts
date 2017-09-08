// you must specify both minimum and maximum output directly.


SET atmosphereAirspeedPid TO PIDLOOP(0.15, 0.05, 0.03, 0, 1).
SET timeToApoapsisPid TO PIDLOOP(0.15, 0.05, 0.03, 0, 1).

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
  return 300 + altitude * (1/100) + altitudeOver12k * (1/100).
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
  return (SHIP:altitude*23.3/BODY:atm:height)^0.7*15.
}

SET hdg TO 90.
SET targetAltitude TO BODY:atm:height * 1.5.


// "Hello World" program for kOS GUI.
//
// Create a GUI window
LOCAL gui IS GUI(200).
// Add widgets to the GUI
gui:ADDLABEL("Select target apoapsis:").
LOCAL label IS gui:ADDLABEL("Hello world!").
SET label:STYLE:ALIGN TO "CENTER".
SET label:STYLE:HSTRETCH TO True. // Fill horizontally
LOCAL ok TO gui:ADDBUTTON("OK").
LOCAL desiredApoSlider TO gui:ADDHSLIDER(targetAltitude, BODY:atm:height, BODY:atm:height * 3).

function updateSliderDisplay {
  parameter value.
  SET label:TEXT TO ROUND(desiredApoSlider:VALUE / 1000) + " km".
}
SET desiredApoSlider:ONCHANGE TO updateSliderDisplay@.
updateSliderDisplay(targetAltitude).

gui:SHOW().

LOCAL isDone IS FALSE.
UNTIL isDone
{
  if (ok:TAKEPRESS)
    SET isDone TO TRUE.
  WAIT 0.1. // No need to waste CPU time checking too often.
}
print "OK pressed.  Now closing demo.".
// Hide when done (will also hide if power lost).
gui:HIDE().

SET targetAltitude TO desiredApoSlider:VALUE.

WAIT UNTIL SHIP:MAXTHRUST > 0.
SAS OFF.
LOCK THROTTLE TO 1.
HUDTEXT( "Let's go", 3, 2, 50, green, true).
WAIT 0.2.

UNTIL SHIP:APOAPSIS > BODY:atm:height AND SHIP:PERIAPSIS > BODY:atm:height {

  CLEARSCREEN.

  print "SHIP:APOAPSIS: " + SHIP:APOAPSIS.
  print "SHIP:PERIAPSIS: " + SHIP:PERIAPSIS.
  print "BODY:atm:height: " + BODY:atm:height.

  if SHIP:MAXTHRUST = 0 OR shipHasEmptyStage() {
    LOCK THROTTLE TO 0.
    WAIT 0.5.
    UNTIL STAGE:READY {
      WAIT 0.
    }
    STAGE.
    PRINT "Stage activated.".
    WAIT 0.5.
  }
  else if SHIP:AIRSPEED < 0.1 { // Simple extra check for clamps that are not released by first staging
    UNTIL STAGE:READY {
      WAIT 0.
    }
    STAGE.
  }

  // Throttle control
  if SHIP:ALTITUDE < 20000 {
    performAtmosphericThrottleControl().
  } else if SHIP:APOAPSIS < 100000 OR ETA:APOAPSIS > ETA:PERIAPSIS {
    LOCK THROTTLE TO 1.
  } else {
    if SHIP:APOAPSIS < targetAltitude * 0.85 {
      SET timeToApoapsisPid:setpoint TO 1500. // always go full throttle until at reasonable apoapsis
    } else if SHIP:PERIAPSIS < -BODY:RADIUS * 0.8 {
      SET timeToApoapsisPid:setpoint TO 120.
    } else if SHIP:PERIAPSIS < -BODY:RADIUS * 0.5 {
      SET timeToApoapsisPid:setpoint TO 90.
    } else if SHIP:PERIAPSIS < -BODY:RADIUS * 0.3 {
      SET timeToApoapsisPid:setpoint TO 60.
    } else {
      SET timeToApoapsisPid:setpoint TO 20.
    }
    print "ETA TO APOAPSIS: " + ETA:APOAPSIS.
    print "DESIRED ETA TO APO: " + timeToApoapsisPid:setpoint.
    SET thrott TO timeToApoapsisPid:update(TIME:SECONDS, ETA:APOAPSIS).
    LOCK THROTTLE TO thrott.
  }


  // Steering
  if SHIP:ALTITUDE < body:atm:height * 0.25 {
    print "getAtmosphericPitch() -> " + getAtmosphericPitch().
    LOCK STEERING TO HEADING(hdg, 90 - getAtmosphericPitch()).
  }
  else {
    LOCK STEERING TO SHIP:PROGRADE.
  }
  WAIT 0.
}

print "DONE!".

UNLOCK THROTTLE.
UNLOCK STEERING.
WAIT 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
