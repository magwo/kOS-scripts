

function shipHasEmptyStage {
  LIST ENGINES IN elist.
  FOR e IN elist {
    IF e:FLAMEOUT {
      return true.
    }
  }
  return false.
}

//LOCK STEERING TO HEADING(90,90).

// TODO: Let these tweak values be a function of TWR
SET Kp TO 0.1.
SET Ki TO 0.0.
SET Kd TO 0.4.
SET PID TO PIDLOOP(Kp, Kp, Kd).
SET PID:SETPOINT TO 95.


WHEN AG1 THEN {
  TOGGLE AG1.
  PRINT "AG1 pressed".
  SET PID:SETPOINT TO PID:SETPOINT + 5.
  PRESERVE.
}

WHEN AG2 THEN {
  TOGGLE AG2.
  PRINT "AG2 pressed".
  SET PID:SETPOINT TO PID:SETPOINT - 5.
  PRESERVE.
}


SET thrott TO 1.
LOCK THROTTLE TO thrott.

UNTIL false {
  if SHIP:MAXTHRUST = 0 OR shipHasEmptyStage() {
    UNTIL STAGE:READY {
      WAIT 0.
    }
    STAGE.
    PRINT "Stage activated.".
  }
  // else if SHIP:AIRSPEED < 0.1 { // Simple extra check for clamps that are not released by first staging
  //   UNTIL STAGE:READY {
  //     WAIT 0.
  //   }
  //   STAGE.
  // }


    SET thrott TO PID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE).
    // pid:update() is given the input time and input and returns the output. gforce is the input.
    WAIT 0.001.
}
