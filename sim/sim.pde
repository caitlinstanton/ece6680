 /*****************************************************************************/ //<>// //<>// //<>// //<>//
/* Original: The Nature of Code <http://www.shiffman.net/teaching/nature>    */
/*           Spring 2011, Box2DProcessing example                            */
/* Edited:   Spring 2016 by Nils Napp, Petra Jennings, and Kirstin Petersen  */
/*****************************************************************************/


import shiffman.box2d.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.contacts.*;
import java.time.Instant;

Box2DProcessing box2d;            //A reference to our box2d world

PImage bg;                        //Background image

int boundaryWidth = 150;

ArrayList<Boundary> boundaries;   //List of fixed objects

//Objects in the world:

ArrayList<Robot> robots;          //List of robot ojbects used in simulation
ArrayList<Part>  parts;           //List of part objects used in simulation

// list for the name / number of different parts and robots
int robotTypes; // number of different robot types
int partTypes;  // number of different part  types

String[] robotFileNames;
String[] partFileNames;

int[] robotCounts;
int[] partCounts;

boolean robotsDone;
boolean partsDone;

int edge_offset_part=300;           //Distance from edge for randomly placing parts and robots
int edge_offset_mover=100;         //?

//Variables for logging
PrintWriter logfile;
String logname = "logs/logfile";
boolean printHeader;

//timer
long startTime;
long lastTime;
long deltaTms=30000; // Time between logging and frame saving events

Boolean globalCollison=false;

//start button
int rectX, rectY;      // Position of square button
int rectSizeX = 100;     
int rectSizeY = 30;
boolean rectOver = false;
boolean start = false;

//statistics
boolean[] displayedParts;

//simulation length
long elapsed = 0;
boolean setupStatus = false;
/*****************************************************/
/* Setup world                                       */
/*****************************************************/

void readSimDef(String fname) {
  JSONObject obj;
  JSONArray  jar;
  JSONObject jprt;

  try {
    obj = loadJSONObject(fname); 

    try {
      jar= obj.getJSONArray("parts");
      partTypes = jar.size();
      print("Found "  +  partTypes  +" different part types in " + fname + ":\n");

      // instantiate the part count array 
      partCounts = new int[partTypes];
      partFileNames = new String[partTypes];

      int totalParts = 0;
      // loop through different robot parts
      for (int i=0; i < partTypes; i++) {
        jprt=jar.getJSONObject(i);
        partFileNames[i]=jprt.getString("file");
        partCounts[i]=jprt.getInt("count");
        print("    " + partCounts[i] + " times " + partFileNames[i] + "\n");
        totalParts = totalParts + partCounts[i];
      }
      displayedParts = new boolean[totalParts];
      for (int i = 0; i < totalParts; i++) {
        displayedParts[i] = true;
      }
    } 
    catch(RuntimeException e) {
      print("Couldn't read part array in simulation file.\n\n");
    }

    try {
      jar= obj.getJSONArray("robots");
      robotTypes = jar.size();

      print("Found "  + robotTypes  +" different robot types in " + fname + ":\n");

      // instantiate the part count array
      robotTypes = jar.size();
      robotCounts = new int[robotTypes];
      robotFileNames = new String[robotTypes];
  
      // loop through different robot parts
      for (int i=0; i < jar.size(); i++) {
        jprt=jar.getJSONObject(i);
        robotFileNames[i]=jprt.getString("file");
        robotCounts[i]=jprt.getInt("count");
        print("    " + robotCounts[i] + " times " + robotFileNames[i] + "\n");
      }
    } 
    catch(RuntimeException e) {
      print("Couldn't read robot array in simulation file.\n\n");
    }
  }  
  catch(RuntimeException e) {
    print("Could not parse " +  fname + ".\nEXCEPTION MESSAGE: " + e.getMessage() + "\n");
    print("Defaulting to preset values.\n\n");
  }
}

void setup() {

  size(800, 800);                            //Size of canvas
  smooth();
  box2d = new Box2DProcessing(this);          //Initialize box2d physics
  box2d.createWorld();                        //Create world
  box2d.setGravity(0, 0);                     //Neglect gravity

  //start button
  rectX = width-rectSizeX-10;
  rectY = rectSizeY+10;

  // Turn on collision listening!
  box2d.listenForCollisions();

  readSimDef("SimInfo.json");

  //Create parts lists:
  boundaries = new ArrayList<Boundary>();
  parts = new ArrayList<Part>();
  robots = new ArrayList<Robot>();

  //Create boundaries
  boundaries.add(new Boundary(width-5, height/2, 10, height));
  boundaries.add(new Boundary(5, height/2, 10, height));  
  boundaries.add(new Boundary(width/2, 5, width-20, 10));
  boundaries.add(new Boundary(width/2, height-5, width-20, 10));

  //  bg = loadImage("background.jpg");
  //  bg.resize(width, height);

  // file name and inital logging related variables
  logfile=createWriter(logname + "_" + System.currentTimeMillis() + ".log");
  printHeader=true;

  lastTime=System.currentTimeMillis();
  startTime=lastTime;
  setupStatus = true;
  logfile.print("time.s   ,   parts displayed\n");
}

/*************************************************************/
/* Interrupt: click on a robot to make it change direction   */
/*************************************************************/

//void mousePressed () {
//  for (Robot r : robots) {
//    if (r.contains(mouseX, mouseY)) {
//      float angle = r.body.getAngle()+PI/3 + random(PI*4/3);
//      r.body.setTransform(r.body.getWorldCenter(), angle);
//    }
//  }
//}

/*************************************************************/
/* Draw, called for every time step                          */
/*************************************************************/

void draw() {

  update(mouseX,mouseY);
  background(70);

  //Advance time one step
  box2d.step();

  if (!start) {
    fill(255);
    stroke(0);
    rect(rectX, rectY, rectSizeX, rectSizeY);
    textAlign(CENTER, CENTER);
    textSize(15);
    fill(0);
    text("START SIM", rectX+(rectSizeX/2)-50, rectY+(rectSizeY/2)-20);
  }

  if (start) {
    if (System.currentTimeMillis() - elapsed > 305000) {
     exit(); 
    }
  
    rect(rectX, rectY, rectSizeX, rectSizeY);
    textAlign(CENTER, CENTER);
    textSize(15);
    fill(0);
    text(numParts(), rectX+(rectSizeX/2)-50, rectY+(rectSizeY/2)-20);
    rect(rectX, rectY + rectSizeY + 10, rectSizeX, rectSizeY);
    textAlign(CENTER,CENTER);
    textSize(15);
    fill(255,255,255);
    text(0.001*(System.currentTimeMillis() - elapsed), rectX+(rectSizeX/2)-50, rectY + rectSizeY + 10 +(rectSizeY/2)-20);
  }

  //Create parts/robots:
  robotsDone=true;
  for (int i=0; i<robotTypes; i++) {
    // print("type=" + i + "   counts=" + robotCounts[i] + "\n");
    if (robotsDone) {
      for (int j=0; j<robotCounts[i]; j++) {
        robotCounts[i]=robotCounts[i]-1;
        Robot r = new Robot(edge_offset_part/2 + random(width-edge_offset_part), edge_offset_part/2 + random(height-edge_offset_part), robotFileNames[i]);
        robots.add(r);
        robotsDone=false;
        break;
      }
    }
  }

  partsDone=true;
  for (int i=0; i<partTypes; i++) {
    // print("part=" + i + "   counts=" + partCounts[i] + "\n");
    if (partsDone) {
      for (int j=0; j<partCounts[i]; j++) {
        partCounts[i]=partCounts[i]-1;
        Part p = new Robot(edge_offset_part/2 + random(width-edge_offset_part), edge_offset_part/2 + random(height-edge_offset_part), partFileNames[i]);
        parts.add(p);
        partsDone=false;
        break;
      }
    }
  }

  for (Part p : parts) {
    if (p.inCollision && !p.placed) {
      p.jumpRandom();
      p.inCollision=false;
    } else {
      p.placed=true;
      p.inCollision=false;
    }
  }



  for (Part p : robots) {
    if (p.inCollision && !p.placed) {
      p.jumpRandom();
      p.inCollision=false;
      p.freeSteps=3;
      //    print("Jump for overlap.\n");
    } else {
      // p.placed=true;
      p.inCollision=false;
      if (p.freeSteps-- < 0) {
        p.placed=true;
      }
    }
  }

  if (start) {
    //Apply forces / move robots 
    for (Robot r : robots) {

      r.move();

      Vec2 pos = box2d.getBodyPixelCoord(r.body);

      if (pos.x<boundaryWidth) {
        r.applySoftBoundary(0.0, 100);
      }
      if (pos.x>(width-boundaryWidth)) {
        r.applySoftBoundary(PI, 100);
      }   

      if (pos.y<boundaryWidth) {
        r.applySoftBoundary(-PI/2, 100);
      }
      if (pos.y>(height-boundaryWidth)) {
        r.applySoftBoundary(PI/2, 100);
      }
    }
  }

  //Draw all the boundaries, parts, and robots:
  for (Boundary wall : boundaries) {
    wall.display();
  }

  for (Part p : parts) {
    Vec2 pos = box2d.getBodyPixelCoord(p.body);
    int index = parts.indexOf(p);
    if (!( (pos.x<boundaryWidth) || (pos.x>(width-boundaryWidth)) || (pos.y<boundaryWidth) || (pos.y>(height-boundaryWidth)) )) {
      p.display();
      displayedParts[index] = true;
    } else {
      displayedParts[index] = false;
    }
  }
  for (Robot r : robots) {
    r.display();
  }

  //Write user guide: 
  //fill(255, 255, 255);
  //textSize(15);
  //text("Change direction of a robot by clicking on it.", 20, 20);

  //Write screenshot to file, appends to old image sequences 
  if ( deltaTms < (System.currentTimeMillis()-lastTime)) {

    lastTime=System.currentTimeMillis();

    fill(0);
    saveFrame("movie/line-######.png"); 

    //log stuff
    if (partsDone && robotsDone) {

      logfile.print(( System.currentTimeMillis()-elapsed)/1000 + "  ,  " + numParts());


      logfile.print("\n");
      logfile.flush();
    }// end log entry
  }// end log / image save timer
}

boolean overRect(int x, int y, int width, int height)  {
  if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

void update(int x, int y) {
  if ( overRect(rectX, rectY, rectSizeX, rectSizeY) ) {
    rectOver = true;
  } else {
    rectOver = false;
  }
}

void mousePressed() {
  if (rectOver && setupStatus) {
    start=true;
    elapsed = System.currentTimeMillis();
    print(elapsed);
  }
}

// Collision event functions!
void beginContact(Contact cp) {

  // Get both fixtures
  Fixture f1 = cp.getFixtureA();

  // Get both bodies
  Body b1 = f1.getBody();

  // Get our objects that reference these bodies
  Object o1 = b1.getUserData();

  if (o1.getClass() == Part.class   || (o1.getClass() == Robot.class   ) ) {
    Part p = (Part) o1;
    p.inCollision=true;
  }
}


// Objects stop touching each other
void endContact(Contact cp) {
}

int numParts() {
  int tmp = 0;
  for (int i = 0; i < displayedParts.length;i++) {
    if (displayedParts[i]) tmp++;
  }
  return tmp;
}
