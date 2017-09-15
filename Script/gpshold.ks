

function createLatLngPid {
  LOCAL LAT_LNG_MULTIPLIER TO -1000000.
  return PIDLOOP(LAT_LNG_MULTIPLIER * 0.1, 0, LAT_LNG_MULTIPLIER * 0.5).
}



function holdCoordinates {
  parameter coordinates.
  parameter latPid.
  parameter lngPid.

  LOCAL current TO SHIP:GEOPOSITION.

  SET latPid:SETPOINT TO coordinates:LAT.
  SET lngPid:SETPOINT TO coordinates:LNG.

  SET latDiff TO latPid:UPDATE(TIME:SECONDS, current:LAT).
  SET lngDiff TO lngPid:UPDATE(TIME:SECONDS, current:LNG).

  print "pter lat " + latPid:PTERM.
  print "dter lat " + latPid:DTERM.

  LOCAL MAX_ANGLE TO 35.

  LOCAL latSteer TO max(-MAX_ANGLE, min(MAX_ANGLE, latDiff)).
  LOCAL lngSteer TO max(-MAX_ANGLE, min(MAX_ANGLE, lngDiff)).

  lock steering to up + r(latSteer, lngSteer, 0).
}
