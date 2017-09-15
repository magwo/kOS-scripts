// REQUIRES A GRAVIOLI

runpath("0:/gpshold.ks").

SET MIN_THROTTLE TO -1.0.
SET MAX_THROTTLE TO 1.0.

function shipHasEmptyStage {
  LIST ENGINES IN elist.
  FOR e IN elist {
    IF e:FLAMEOUT {
      return true.
    }
  }
  return false.
}


function setAllEnginesToMode {
  parameter mode.

  LIST ENGINES IN elist.
  FOR e IN elist {
    if e:GETMODULE("MultiModeEngine"):GETFIELD("mode") <> mode {
      e:GETMODULE("MultiModeEngine"):DOACTION("switch mode", true).
    }
  }
}


function getAvailableDryThrust {
  setAllEnginesToMode("Dry").
  LOCAL availableDryThrust TO SHIP:AVAILABLETHRUST.
  return availableDryThrust.
}

function calculateDryHoverThrottle {
  parameter availableDryThrust.

  LOCAL requiredForce TO SHIP:SENSORS:GRAV:MAG * SHIP:MASS.
  print "REquired force: " + requiredForce.
  return requiredForce / availableDryThrust.
}

//LOCK STEERING TO HEADING(90,90).

// TODO: Try some sort of feed-forward of the acceleration/speed values
// TODO: Smooth out the setpoint changes to avoid Kd freak-out
// TODO: Let these tweak values be a function of TWR
SET PID TO PIDLOOP(0.04, 0.02, 0.43, MIN_THROTTLE, MAX_THROTTLE).
SET PID:SETPOINT TO 120.

SET ABPID TO PIDLOOP(0.2, 0.0, 0.4, MIN_THROTTLE, MAX_THROTTLE).
SET ABPID:SETPOINT TO PID:SETPOINT.

SET targetAltitude TO 120.

function updatePidSetPoints {
  SET PID:SETPOINT TO targetAltitude.
  SET ABPID:SETPOINT TO targetAltitude.
}

WHEN AG1 THEN {
  TOGGLE AG1.
  SET targetAltitude TO targetAltitude + 5.
  updatePidSetPoints().
  PRESERVE.
}

WHEN AG2 THEN {
  TOGGLE AG2.
  SET targetAltitude TO targetAltitude - 5.
  updatePidSetPoints().
  PRESERVE.
}

WAIT UNTIL SHIP:AVAILABLETHRUST > 0.

SET availableDryThrust TO getAvailableDryThrust().

SET thrott TO 1.
LOCK THROTTLE TO thrott.

SET currentHoldPos TO SHIP:GEOPOSITION.

SET latPid TO createLatLngPid().
SET lngPid TO createLatLngPid().

SET inputPreviousFrame TO false.

UNTIL false {

    CLEARSCREEN.

    if SHIP:CONTROL:PILOTPITCH <> 0 OR SHIP:CONTROL:PILOTYAW <> 0 {
      SET currentHoldPos TO LATLNG(SHIP:GEOPOSITION:LAT - 0.004 * SHIP:CONTROL:PILOTPITCH, SHIP:GEOPOSITION:LNG + 0.006 * SHIP:CONTROL:PILOTYAW).
      SET inputPreviousFrame TO true.
    } else if inputPreviousFrame {
      SET currentHoldPos TO SHIP:GEOPOSITION.
    }

    SET dryHoverThrottle TO calculateDryHoverThrottle(availableDryThrust).

    SET thrott TO dryHoverThrottle + 0.7 * PID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE).
    SET abthrott TO ABPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE).

    print "Target altitude is " + targetAltitude.
    print "Altitude is " + SHIP:ALTITUDE.
    print "Error           " + (targetAltitude - SHIP:ALTITUDE).
    print "throttle        " + thrott.
    print "PTERM           " + PID:PTERM.
    print "ITERM           " + PID:ITERM.
    print "DTERM           " + PID:DTERM.

    print "MAXTHRUST       " + SHIP:MAXTHRUST.
    print "AVAILABLETHRUST " + SHIP:AVAILABLETHRUST.
    print "MASS            " + SHIP:MASS.
    print "GRAV:MAG        " + SHIP:SENSORS:GRAV:MAG.
    print "AVAILABLETHRUST " + availableDryThrust.
    print "Dry hover throt " + dryHoverThrottle.
    // pid:update() is given the input time and input and returns the output. gforce is the input.

    LIST ENGINES IN elist.
    FOR e IN elist {
      if abthrott >= 0.9 {
        setAllEnginesToMode("Wet").
      }
      else if abthrott < 0.85 {
        setAllEnginesToMode("Dry").
      }
    }

    holdCoordinates(currentHoldPos, latPid, lngPid).

    WAIT 0.
}
