@lazyglobal off.

print "Loading ascent util library...".

LOCAL MIN_THROTTLE TO 0.0.
LOCAL MAX_THROTTLE TO 1.0.


function desiredAtmosphereSpeed {
  parameter _altitude.
  // TODO: Make dependent on atmosphere pressure
  if _altitude > BODY:ATM:HEIGHT * 0.13 {
    return 100000000.
  } else {
    LOCAL atmFraction TO _altitude / BODY:ATM:HEIGHT.
    LOCAL velocityGainPerPercentageAtm TO 25.
    return 200 + velocityGainPerPercentageAtm * 100 * atmFraction.
  }
}

function desiredAtmosphericPitch {
  parameter _curve. // Should be 0.5 - 0.9 ish
  return 14*(SHIP:ALTITUDE*23.3/BODY:ATM:HEIGHT)^_curve.
}

function performAtmosphericThrottleControl {
  parameter _atmosphereAirspeedPid.
  LOCAL desiredAirSpeed TO desiredAtmosphereSpeed(SHIP:ALTITUDE).
  SET _atmosphereAirspeedPid:setpoint TO desiredAirSpeed.
  LOCK THROTTLE TO _atmosphereAirspeedPid:update(TIME:SECONDS, SHIP:AIRSPEED).
}


function performAtmosphericSteering {
  parameter curveExponent.
  parameter allowedAoA.

  // Normal atmospheric ascent steering
  LOCAL progradePitch TO VANG(SHIP:SRFPROGRADE:VECTOR, UP:VECTOR).
  LOCAL atmosphericPitch TO desiredAtmosphericPitch(curveExponent).

  // Never pitch more than n degrees from prograde
  LOCAL desiredPitch TO MAX(progradePitch - allowedAoA, MIN(progradePitch + allowedAoA, atmosphericPitch)).

  LOCK STEERING TO HEADING(hdg, 90 - desiredPitch).
}

function performUpperAtmosphereSteering {
  // Upper atmosphere steering
  LOCAL progradePitch TO VANG(SHIP:PROGRADE:VECTOR, UP:VECTOR).
  LOCAL MAX_PITCH TO 90.

  LOCAL desiredPitchChange TO 90 - progradePitch.

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

function createAtmosphericAirSpeedPid {
  return PIDLOOP(0.15, 0.05, 0.03, MIN_THROTTLE, MAX_THROTTLE).
}

function createTimeToApoapsisPid {
  return PIDLOOP(0.15, 0.05, 0.03, MIN_THROTTLE, MAX_THROTTLE).
}
