function proceed {
  parameter altitude.
  parameter pitch.
  HUDTEXT( "Waiting for altitude " + altitude, 3, 2, 50, yellow, true).
  WAIT UNTIL SHIP:ALTITUDE > altitude.
  HUDTEXT( "Pitch to " + pitch, 3, 2, 50, green, true).
  LOCK STEERING TO HEADING(66,pitch).
  WAIT 6.0.
  HUDTEXT( "Holding prograde", 3, 2, 50, green, true).
  LOCK STEERING TO SHIP:SRFPROGRADE.
}


function turnOnLight {
  parameter lightPart.
  lightPart:GETMODULE("ModuleLight"):DOACTION("turn light on", true).
}

CLEARSCREEN.
WAIT 2.

DECLARE TARGET_AT_SEA TO LATLNG(43.699, 158.42).
ADDONS:TR:SETTARGET(TARGET_AT_SEA).

SET light1 TO SHIP:PARTSDUBBED("light1")[0].
SET light2 TO SHIP:PARTSDUBBED("light2")[0].
SET light3 TO SHIP:PARTSDUBBED("light3")[0].

SET cherry1 TO SHIP:PARTSDUBBED("cherry1")[0].
SET cherry2 TO SHIP:PARTSDUBBED("cherry2")[0].
SET cherry3 TO SHIP:PARTSDUBBED("cherry3")[0].

turnOnLight(cherry1).
turnOnLight(cherry2).
turnOnLight(cherry3).
WAIT 3.
turnOnLight(light1).
turnOnLight(light2).
turnOnLight(light3).


SAS OFF.
HUDTEXT( "Assuming command on behalf of Glorious Leader", 3, 2, 50, green, true).



WAIT 1.
FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    HUDTEXT("..." + countdown, 1, 2, 50, yellow, true).
    IF countdown = 1 { LOCK THROTTLE TO 1. }
    WAIT 1. // pauses the script here for 1 second.
}

WAIT 0.1.
STAGE.
WAIT 0.1.
LOCK STEERING TO HEADING(66,89).
WAIT 1.0.
HUDTEXT("Lift-off of Hwasong-12", 3, 2, 50, green, true).
WAIT 1.0.
proceed(1000, 86).
proceed(2000, 82).
proceed(4000, 77).
proceed(10000, 65).
proceed(14000, 58).
proceed(20000, 55).
proceed(40000, 46).

WAIT UNTIL SHIP:ALTITUDE > 50000.
LOCK STEERING TO SHIP:SRFPROGRADE.

WAIT UNTIL SHIP:ALTITUDE > 90000.
HUDTEXT( "Throttle to 70%", 3, 2, 50, yellow, true).
LOCK THROTTLE TO 0.7.

WAIT UNTIL APOAPSIS > 550000.
HUDTEXT("Apogee is " + ROUND(SHIP:APOAPSIS/1000, 1) + " km", 3, 2, 50, yellow, true).
LOCK THROTTLE TO 0.
WAIT 3.
AG1 ON.
AG1 OFF.
HUDTEXT("Main engine cut off", 3, 2, 50, yellow, true).
WAIT 4.
STAGE.
HUDTEXT( "Fairing separation completed", 3, 2, 50, yellow, true).

WAIT UNTIL SHIP:ALTITUDE > 547000.
HUDTEXT("Preparing corrective burn", 3, 2, 50, green, true).
LOCK STEERING TO ADDONS:TR:CORRECTEDVEC.
WAIT UNTIL SHIP:ALTITUDE < 545000.
HUDTEXT("Performing corrective burn", 3, 2, 50, green, true).
LOCK THROTTLE TO 1.0.
WAIT UNTIL (ADDONS:TR:IMPACTPOS:position - TARGET_AT_SEA:position):mag < 10000.
HUDTEXT("Corrective burn completed", 2, 2, 50, yellow, true).
WAIT 2.
HUDTEXT("Impact at Lat " + ROUND(ADDONS:TR:IMPACTPOS:LAT, 3) + " Lng " + ROUND(ADDONS:TR:IMPACTPOS:LNG, 3), 14, 2, 50, red, true).

LOCK THROTTLE TO 0.
LOCK STEERING TO SHIP:SRFPROGRADE.

WAIT UNTIL SHIP:ALTITUDE < 100000.
HUDTEXT( "Preparing payload separation", 3, 2, 50, green, true).
WAIT 3.
STAGE.
WAIT 3.
STAGE.
WAIT 3.
STAGE.
HUDTEXT( "Payload delivered", 3, 2, 50, yellow, true).

WAIT UNTIL FALSE. // CTRL+C to break out
