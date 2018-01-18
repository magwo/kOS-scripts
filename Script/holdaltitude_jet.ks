// REQUIRES A GRAVIOLI

runpath("0:/gpshold.ks").

// SET MIN_THROTTLE TO -1.0.
// SET MAX_THROTTLE TO 1.0.

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

function getAvailableWetThrust {
  setAllEnginesToMode("Wet").
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

// TODO: Predict overshoot vertically, both upwards (based on gravity) and downwards (based on max wet thrust)
// TODO: Use VERTICALSPEED, apply pid to speed instead of altitude, make speed P to altitude.
// TODO: Smooth out the setpoint changes to avoid Kd freak-out
// TODO: Let these tweak values be a function of TWR
SET PID TO PIDLOOP(0.029, 0.0, 0.09).
SET PID:SETPOINT TO 120.

SET ABPID TO PIDLOOP(0.1, 0.0, 0.4).
SET ABPID:SETPOINT TO PID:SETPOINT.

SET targetAltitude TO SHIP:ALTITUDE + 3.
SET targetHeading TO -90.

function updatePidSetPoints {
  parameter _targetAltitude.
  SET PID:SETPOINT TO _targetAltitude.
  SET ABPID:SETPOINT TO _targetAltitude.
}

WHEN AG1 THEN {
  TOGGLE AG1.
  SET targetAltitude TO targetAltitude + 5.
  PRESERVE.
}

WHEN AG2 THEN {
  TOGGLE AG2.
  SET targetAltitude TO targetAltitude + 0.5.
  PRESERVE.
}

WHEN AG3 THEN {
  TOGGLE AG3.
  SET targetAltitude TO targetAltitude - 0.5.
  PRESERVE.
}

WHEN AG4 THEN {
  TOGGLE AG4.
  SET targetAltitude TO targetAltitude - 5.
  PRESERVE.
}


WHEN ALT:RADAR + SHIP:VERTICALSPEED < 15 AND NOT GEAR THEN {
  LIGHTS ON.
  GEAR ON.
  BRAKES ON.
  PRESERVE.
}

WHEN ALT:RADAR + SHIP:VERTICALSPEED > 25 AND GEAR THEN {
  LIGHTS OFF.
  GEAR OFF.
  BRAKES OFF.
  PRESERVE.
}

WAIT UNTIL SHIP:AVAILABLETHRUST > 0.

SET availableDryThrust TO getAvailableDryThrust().
SET availableWetThrust TO getAvailableWetThrust().

SET thrott TO 1.
LOCK THROTTLE TO thrott.

SET currentHoldPos TO SHIP:GEOPOSITION.

SET latPid TO createLatLngPid().
SET lngPid TO createLatLngPid().

SET inputPreviousFrame TO false.

UNTIL false {

    CLEARSCREEN.

    LOCAL actualTargetAltitude TO MAX(targetAltitude, SHIP:ALTITUDE - ALT:RADAR - 1).
    updatePidSetPoints(actualTargetAltitude).

    if SHIP:CONTROL:PILOTPITCH <> 0 OR SHIP:CONTROL:PILOTYAW <> 0 {
      print "MOOOOOO!!!!!!!!!!!!".
      SET currentHoldPos TO LATLNG(SHIP:GEOPOSITION:LAT - 0.004 * SHIP:CONTROL:PILOTPITCH, SHIP:GEOPOSITION:LNG + 0.006 * SHIP:CONTROL:PILOTYAW).
      SET inputPreviousFrame TO true.
    } else if inputPreviousFrame {
      SET currentHoldPos TO SHIP:GEOPOSITION.
      SET inputPreviousFrame TO false.
    }

    print "Target heading " + targetHeading.
    print "Pilot roll " + SHIP:CONTROL:PILOTROLL.
    if SHIP:CONTROL:PILOTROLL <> 0 {
      SET targetHeading TO targetHeading + SHIP:CONTROL:PILOTROLL * 5.
    }

    LOCAL dryHoverThrottle TO calculateDryHoverThrottle(availableDryThrust).

    LOCAL dryTwr TO availableDryThrust / (SHIP:MASS * SHIP:SENSORS:GRAV:MAG).
    LOCAL throttleGain TO 2 / dryTwr. // Higher twr => lower gain

    print "THROTTLE GAIN IS " + throttleGain.

    SET thrott TO dryHoverThrottle + throttleGain * PID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE).
    SET abthrott TO ABPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE).

    // Universal fallback - always full throttle when below target altitude and moving wrong direction
    if (SHIP:ALTITUDE - actualTargetAltitude) < 1.0 AND SHIP:VERTICALSPEED < -1.0 {
      SET abthrott TO 1.0.
    }

    print "Target altitude is " + actualTargetAltitude.
    print "Altitude is " + SHIP:ALTITUDE.

    print "MASS            " + SHIP:MASS.
    print "GRAV:MAG        " + SHIP:SENSORS:GRAV:MAG.
    print "Dry thrust max  " + availableDryThrust.
    print "Wet thrust max  " + availableWetThrust.
    print "Dry hover throt " + dryHoverThrottle.
    print "Dry twr is      " + dryTwr.
    print "Mass is         " + SHIP:MASS.
    // pid:update() is given the input time and input and returns the output. gforce is the input.

    LIST ENGINES IN elist.
    FOR e IN elist {
      if abthrott >= 1.0 {
        setAllEnginesToMode("Wet").
      }
      else if abthrott < 1.0 {
        setAllEnginesToMode("Dry").
      }
    }

    LOCAL maxAngle TO 10.0 + dryTwr * 6 - 0.02 * SHIP:MASS * SHIP:SENSORS:GRAV:MAG.
    print "maxAngle  " + maxAngle.
    holdCoordinates(currentHoldPos, latPid, lngPid, maxAngle, targetHeading).

    WAIT 0.01.
}
