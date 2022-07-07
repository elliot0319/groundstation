// import libraries
import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

/* SETTINGS BEGIN */

// Image (instead of FPV feed)
PImage example_img = new PImage();

// Serial port to connect to
String serialPortName = "/dev/tty.usbmodem1411";

// If you want to debug the plotter without using a real serial port set this to true
boolean mockupSerial = true;

/* SETTINGS END */

Serial serialPort; // Serial port object

// interface stuff
ControlP5 cp5;

// Settings for the plotter are saved in this file
JSONObject plotterConfigJSON;

// Create Graph objects
Graph GraphLeftThrust = new Graph(680, 500, 90, 100, color(20, 20, 200));
Graph GraphRightThrust = new Graph(930, 500, 90, 100, color(200, 20, 20));
Graph GraphPowerR = new Graph(1180, 500, 90, 100, color(200, 20, 20));
Graph GraphAltitude = new Graph(110, 310, 90, 100, color(200, 20, 20));
Graph GraphOrX = new Graph(380, 75, 90, 90, color(200, 20, 20));
Graph GraphOrY = new Graph(380, 290, 90, 90, color(200, 20, 20));
Graph GraphOrZ = new Graph(380, 505, 90, 90, color(200, 20, 20));

float[] lineGraphSampleNumbers = new float[100];
float[][] lineGraphValuesLThr = new float[7][100];
float[] lineGraphSampleNumbersLThr = new float[100];
color[] graphColors = new color[7];

// helper for saving the executing path
String topSketchPath = "";

void setup() {
  surface.setTitle("Ground Control");
  size(1345, 675);

  // Load image instead of FPV feed
  example_img = loadImage("example1.jpg");
  
  // set line graph colors
  graphColors[0] = color(131, 255, 20);
  graphColors[1] = color(80, 106, 128);
  graphColors[2] = color(255, 0, 0);
  graphColors[3] = color(80, 106, 128);
  graphColors[4] = color(80, 106, 128);
  graphColors[5] = color(80, 106, 128);
  graphColors[6] = color(80, 106, 128);

  // settings save file
  topSketchPath = sketchPath();
  plotterConfigJSON = loadJSONObject(topSketchPath+"/plotter_config.json");

  // gui
  cp5 = new ControlP5(this);
  
  // init charts
  setChartSettings();
  
  // build x axis values for the Left Thrust Graph
  for (int i=0; i<lineGraphValuesLThr.length; i++) {
    for (int k=0; k<lineGraphValuesLThr[0].length; k++) {
      lineGraphValuesLThr[i][k] = 0;
      if (i==0)
        lineGraphSampleNumbersLThr[k] = k;
    }
  }
  
  // start serial communication
  if (!mockupSerial) {
    //String serialPortName = Serial.list()[3];
    serialPort = new Serial(this, serialPortName, 115200);
  }
  else
    serialPort = null;

  // build the gui
  int x = 170;
  int y = 135;
  cp5.addTextfield("lgMaxY").setPosition(610, 570).setText(getPlotterConfigString("lgMaxY")).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMinY").setPosition(610, 595).setText(getPlotterConfigString("lgMinY")).setWidth(40).setAutoClear(false);

  cp5.addTextlabel("label").setText("Graph on/off").setPosition(x=8, y).setColor(0);
  cp5.addToggle("lgVisible1").setPosition(x=x+5, y=y+10).setValue(int(getPlotterConfigString("lgVisible1"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[0]);
  cp5.addTextlabel("label_image").setText("Cam on/off").setPosition(x=10, y=y+25).setColor(0);
  cp5.addToggle("imageStatus").setPosition(x=x+13,y=y+10).setValue(int(getPlotterConfigString("imageStatus"))).setMode(ControlP5.SWITCH).setSize(20,20);
  cp5.addTextlabel("multipliers").setText("multipliers").setPosition(x=55, y).setColor(0);
  cp5.addTextfield("lgMultiplier1").setPosition(x=60, y=y+10).setText(getPlotterConfigString("lgMultiplier1")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  
  
}

byte[] inBuffer = new byte[100]; // holds serial message
int i = 0; // loop variable
void draw() {
  /* Read serial and update values */
  if (mockupSerial || serialPort.available() > 0) {
    String myString = "";
    if (!mockupSerial) {
      try {
        serialPort.readBytesUntil('\r', inBuffer);
      }
      catch (Exception e) {
      }
      myString = new String(inBuffer);
    }
    else {
      myString = mockupSerialFunction();
    }

    println(myString);

    // split the string at delimiter (space)
    String[] nums = split(myString, ' ');
    
    // count number of graphs to hide
    int numberOfInvisibleLineGraphs = 0;
    for (i=0; i<6; i++) {
      if (int(getPlotterConfigString("lgVisible"+(i+1))) == 0) {
        numberOfInvisibleLineGraphs++;
      }
    }
    // build a new array to fit the data to show

    // build the arrays for graphs
    for (i=0; i<nums.length; i++) {      
      // update Left Thrust Graph
      try {
        if (i<lineGraphValuesLThr.length) {
          for (int k=0; k<lineGraphValuesLThr[i].length-1; k++) {
            lineGraphValuesLThr[i][k] = lineGraphValuesLThr[i][k+1];
          }

          lineGraphValuesLThr[i][lineGraphValuesLThr[i].length-1] = float(nums[i]);
        }
      }
      catch (Exception e) {
      }
      
    }
  }

  // 
  background(255);
  // Frame for status/control panel
  stroke(101);
  noFill();
  rect(5, 5, 240, 230, 28); // status/control panel
  rect(5, 240, 258, 240, 28); // Altitude
  rect(273, 5, 263, 665, 28); // Orientation
  rect(570, 430, 770, 240, 28); // Thrust/Power
  rect(570, 5, 770, 420, 28); // Cam/status
  // draw the line graph for Left Thrust
  GraphLeftThrust.DrawAxis();
  for (int i=0;i<lineGraphValuesLThr.length; i++) {
    if (int(getPlotterConfigString("lgVisible1")) == 1){
      GraphLeftThrust.GraphColor = graphColors[i];
      GraphLeftThrust.smoothLine(lineGraphSampleNumbersLThr, lineGraphValuesLThr[0]);
    }
  }
  
  // draw the line graph for Right Thrust
  GraphRightThrust.DrawAxis();
  for (int i=0;i<lineGraphValuesLThr.length; i++) {
    if (int(getPlotterConfigString("lgVisible1")) == 1){
      GraphRightThrust.GraphColor = graphColors[i];
      GraphRightThrust.smoothLine(lineGraphSampleNumbersLThr, lineGraphValuesLThr[1]);
    }
  }
  
  GraphPowerR.DrawAxis();
  for (int i=0;i<lineGraphValuesLThr.length; i++) {
    if (int(getPlotterConfigString("lgVisible1")) == 1){
      GraphPowerR.GraphColor = graphColors[i];
      GraphPowerR.smoothLine(lineGraphSampleNumbersLThr, lineGraphValuesLThr[4]);
    }
  }
  
  GraphAltitude.DrawAxis();
  for (int i=0;i<lineGraphValuesLThr.length; i++) {
    if (int(getPlotterConfigString("lgVisible1")) == 1){
      GraphAltitude.GraphColor = graphColors[i];
      GraphAltitude.smoothLine(lineGraphSampleNumbersLThr, lineGraphValuesLThr[2]);
    }
  }
  
  GraphOrX.DrawAxis();
  for (int i=0;i<lineGraphValuesLThr.length; i++) {
    if (int(getPlotterConfigString("lgVisible1")) == 1){
      GraphOrX.GraphColor = graphColors[i];
      GraphOrX.smoothLine(lineGraphSampleNumbersLThr, lineGraphValuesLThr[6]);
    }
  }
  
  GraphOrY.DrawAxis();
  for (int i=0;i<lineGraphValuesLThr.length; i++) {
    if (int(getPlotterConfigString("lgVisible1")) == 1){
      GraphOrY.GraphColor = graphColors[i];
      GraphOrY.smoothLine(lineGraphSampleNumbersLThr, lineGraphValuesLThr[3]);
    }
  }
  
  GraphOrZ.DrawAxis();
  for (int i=0;i<lineGraphValuesLThr.length; i++) {
    if (int(getPlotterConfigString("lgVisible1")) == 1){
      GraphOrZ.GraphColor = graphColors[i];
      GraphOrZ.smoothLine(lineGraphSampleNumbersLThr, lineGraphValuesLThr[5]);
    }
  }
  
  // draw image (instead of camera feed)
  if(int(getPlotterConfigString("imageStatus")) == 1) {
    image(example_img, 585, 115, 500, 300);
  }
  else{
    textSize(30);
    text("Cam Off", 877, 295); 
    rect(585, 115, 500, 290);
    triangle(730, 320, 830, 190, 930, 320);
  }
}

// called each time the chart settings are changed by the user 
void setChartSettings() {
  // For Left Thrust
  GraphLeftThrust.xLabel=" Time ";
  GraphLeftThrust.yLabel="RPM";
  GraphLeftThrust.yMax=int(getPlotterConfigString("lgMaxY"));
  GraphLeftThrust.yMin=int(getPlotterConfigString("lgMinY"));
  GraphLeftThrust.Title=" Left Thrust ";
  
  // For Right Thrust
  GraphRightThrust.xLabel=" Time ";
  GraphRightThrust.yLabel="RPM";
  GraphRightThrust.yMax=int(getPlotterConfigString("lgMaxY"));
  GraphRightThrust.yMin=int(getPlotterConfigString("lgMinY"));
  GraphRightThrust.Title=" Right Thrust ";
  
  // For Power
  GraphPowerR.xLabel=" Time ";
  GraphPowerR.yLabel="Wh";
  GraphPowerR.yMax=int(getPlotterConfigString("lgMaxY"));
  GraphPowerR.yMin=int(getPlotterConfigString("lgMinY"));
  GraphPowerR.Title=" Battery Power ";
  
  // For Altitude
  GraphAltitude.xLabel=" Time ";
  GraphAltitude.yLabel="Meter";
  GraphAltitude.yMax=int(getPlotterConfigString("lgMaxY"));
  GraphAltitude.yMin=int(getPlotterConfigString("lgMinY"));
  GraphAltitude.Title=" Altitude ";
  
  // For Orientation in X-axis
  GraphOrX.xLabel=" Time ";
  GraphOrX.yLabel="Theta";
  GraphOrX.yMax=int(getPlotterConfigString("lgMaxY"));
  GraphOrX.yMin=int(getPlotterConfigString("lgMinY"));
  GraphOrX.Title=" Orientation X ";
  
  // For Orientation in Y-axis
  GraphOrY.xLabel=" Time ";
  GraphOrY.yLabel="Theta";
  GraphOrY.yMax=int(getPlotterConfigString("lgMaxY"));
  GraphOrY.yMin=int(getPlotterConfigString("lgMinY"));
  GraphOrY.Title=" Orientation Y ";
  
  // For Orientation in Z-axis
  GraphOrZ.xLabel=" Time ";
  GraphOrZ.yLabel="Theta";
  GraphOrZ.yMax=int(getPlotterConfigString("lgMaxY"));
  GraphOrZ.yMin=int(getPlotterConfigString("lgMinY"));
  GraphOrZ.Title=" Orientation Z ";
}

// handle gui actions
void controlEvent(ControlEvent theEvent) {
  
  if (theEvent.isAssignableFrom(Textfield.class) || theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class)) {
    String parameter = theEvent.getName();
    String value = "";
    if (theEvent.isAssignableFrom(Textfield.class))
      value = theEvent.getStringValue();
    else if (theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class))
      value = theEvent.getValue()+"";

    plotterConfigJSON.setString(parameter, value);
    saveJSONObject(plotterConfigJSON, topSketchPath+"/plotter_config.json");
  }
  setChartSettings();
}

// get gui settings from settings file
String getPlotterConfigString(String id) {
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}
