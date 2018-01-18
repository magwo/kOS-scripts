@lazyglobal off.

print "Loading ui util library...".


function addSliderControl {
  parameter gui.
  parameter description.
  parameter currentValue.
  parameter minValue.
  parameter maxValue.
  parameter changeHandler.

  // print "Max " + maxValue.
  // print "Min " + minValue.
  // print "Current " + currentValue.

  gui:ADDLABEL(description).
  LOCAL slider TO gui:ADDHSLIDER(currentValue, minValue, maxValue).
  SET slider:ONCHANGE TO changeHandler.
  return slider.
}


function getTimeStampedString {
  parameter str.
  LOCAL timestampStr TO "T+" + ROUND(MISSIONTIME).
  return timestampStr:PADRIGHT(7) + str.
}
