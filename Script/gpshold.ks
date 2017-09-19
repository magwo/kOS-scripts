

function createLatLngPid {
  LOCAL LAT_LNG_MULTIPLIER TO -600000.
  return PIDLOOP(LAT_LNG_MULTIPLIER * 0.1, 0, LAT_LNG_MULTIPLIER * 0.5).
}



function holdCoordinates {
  parameter coordinates.
  parameter latPid.
  parameter lngPid.
  parameter maxAngle.

  LOCAL current TO SHIP:GEOPOSITION.


  print "Instructed to hold   " + coordinates.
  print "Current position is  " + current.

  SET latPid:SETPOINT TO coordinates:LAT.
  SET lngPid:SETPOINT TO coordinates:LNG.

  SET latDiff TO latPid:UPDATE(TIME:SECONDS, current:LAT).
  SET lngDiff TO lngPid:UPDATE(TIME:SECONDS, current:LNG).

  LOCAL latSteer TO max(-maxAngle, min(maxAngle, latDiff)).
  LOCAL lngSteer TO max(-maxAngle, min(maxAngle, lngDiff)).

  lock steering to up + r(latSteer, lngSteer, 0).
}
