@lazyglobal off.

print "Loading generic util library...".


function shipHasEmptyStage {
  LOCAL engineList IS List().
  LIST ENGINES IN engineList.
  FOR e IN engineList {
    IF e:FLAMEOUT {
      return true.
    }
  }
  return false.
}


function autoStage {
  parameter loggingFunction.
  if SHIP:MAXTHRUST = 0 OR shipHasEmptyStage() {
    print loggingFunction("Staging...").
    LOCK THROTTLE TO 0.2.
    WAIT 0.1.
    UNTIL STAGE:READY {
      WAIT 0.
    }
    STAGE.
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
    print loggingFunction("Staging completed, throttle at 100%").
  }
  else if SHIP:AIRSPEED < 0.1 { // Simple extra check for clamps that are not released by first staging
    UNTIL STAGE:READY {
      WAIT 0.
    }
    STAGE.
  }
}

// // Antenna deployer
// WHEN SHIP:altitude > BODY:atm:height THEN {
//   AG1 ON.
//   AG1 OFF.
// }
