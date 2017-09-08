
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
  return 100.// + altitude * (1/100) + altitudeOver12k * (2/100).
}

function performAtmosphericThrottleControl {
  SET desiredAirSpeed TO desiredAtmosphereSpeed(SHIP:ALTITUDE).
  SET desiredThrottle TO 0.1 + 0.03 * (desiredAirSpeed - SHIP:AIRSPEED).  //SHIP:ALTITUDE) / (SHIP:AIRSPEED + 0.1).
  LOCK THROTTLE TO desiredThrottle.
}


SET hdg TO 90.

CLEARSCREEN.
WAIT 2.
print "Stage number" + STAGE:NUMBER.
WAIT UNTIL STAGE:NUMBER > 1.
WAIT 0.1.
SAS OFF.
LOCK THROTTLE TO 1.

HUDTEXT( "Let's go", 3, 2, 50, green, true).


UNTIL SHIP:APOAPSIS > 250000 {
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


  if SHIP:ALTITUDE < 20000 {
    performAtmosphericThrottleControl().
  } else if SHIP:APOAPSIS < 100000 {
    LOCK THROTTLE TO 1.
  } else {
    //print "ETA TO APOAPSIS: " + ETA:APOAPSIS.
    LOCK THROTTLE TO 0.3.
  }

  if SHIP:ALTITUDE < 2000 {
    LOCK STEERING TO HEADING(hdg,89).
  }
  else if SHIP:ALTITUDE < 4000 {
    LOCK STEERING TO HEADING(hdg,85).
  }
  else if SHIP:ALTITUDE < 10000 {
    LOCK STEERING TO HEADING(hdg,80).
  }
  else {
    LOCK STEERING TO SHIP:SRFPROGRADE.
  }
  WAIT 0.
}.
