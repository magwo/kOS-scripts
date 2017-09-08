

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
SET Kp TO 0.06.
SET Ki TO 0.001.
SET Kd TO 0.7.
SET PID TO PIDLOOP(Kp, Ki, Kd).
SET PID:SETPOINT TO 120.


SET ABPID TO PIDLOOP(0.2, 0.0, 0.4).
SET ABPID:SETPOINT TO PID:SETPOINT.

WHEN AG1 THEN {
  TOGGLE AG1.
  PRINT "AG1 pressed".
  SET PID:SETPOINT TO PID:SETPOINT + 5.
  SET ABPID:SETPOINT TO PID:SETPOINT + 5.
  PRESERVE.
}

WHEN AG2 THEN {
  TOGGLE AG2.
  PRINT "AG2 pressed".
  SET PID:SETPOINT TO PID:SETPOINT - 5.
  SET ABPID:SETPOINT TO PID:SETPOINT - 5.
  PRESERVE.
}


SET thrott TO 1.
LOCK THROTTLE TO thrott.

SET knownDryThrust

UNTIL false {

    CLEARSCREEN.

    SET thrott TO PID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE).
    SET abthrott TO PID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE).

    print "thrott is " + thrott.
    print "PTERM component is " + PID:PTERM.
    print "ITERM component is " + PID:ITERM.
    print "DTERM component is " + PID:DTERM.

    print "MAXTHRUST is " + SHIP:MAXTHRUST.
    print "AVAILABLETHRUST is " + SHIP:AVAILABLETHRUST.
    print "MASS is " + SHIP:MASS.
    // pid:update() is given the input time and input and returns the output. gforce is the input.

    LIST ENGINES IN elist.
    FOR e IN elist {
      if abthrott >= 1.0 {
        //e:GETMODULE("MultiModeEngine"):DOACTION("turn light on", true).
        if e:GETMODULE("MultiModeEngine"):GETFIELD("mode") = "Dry" {
          e:GETMODULE("MultiModeEngine"):DOACTION("switch mode", true).
        }
        // print e:GETMODULE("MultiModeEngine").
        // print e:GETMODULE("MultiModeEngine"):GETFIELD("mode").
      }
      else if abthrott < 1.0 {
        if e:GETMODULE("MultiModeEngine"):GETFIELD("mode") = "Wet" {
          e:GETMODULE("MultiModeEngine"):DOACTION("switch mode", true).
        }
      }
    }

    WAIT 0.001.
}
