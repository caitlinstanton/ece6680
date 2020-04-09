/*****************************************************************************/
/* By Nils Napp and Kirstin Petersen, March 2016                             */
/* Reads in part parameters from files and creates parts                     */
/*****************************************************************************/         

// A rectangular box
class Part {

  int move_skips=10;           //Determines how often random rotations are applied
  int move_count=0;
  
  //To keep track of bodies
  Body body;

  //used in placement
  boolean inCollision=false;
  boolean placed=false;
  int     freeSteps=5;

  //Lists of polygons and circles that make up parts
  ArrayList<PolygonShape> polygons;
  ArrayList<CircleShape> circles;

  //logging variales
  Boolean printHeader=true;
  String name;

  //parameters that get read from the file (or set to defautls if the read fails) 
  
  float force_scale;      //Only for robots, strength  THESE SHOULD MOVE THE THE ROBOT CLASS
  float noise_frac;       //Only for robots, randomness in movement  
 
  float scale;            //Option to scale the size of the object
  float damping;      
  float density;
  float friction;        
  float restitution;      //Bounciness of the object
  color partColor;
  
  //JSON Object for parsing 
  // This could move inside the functions since it is only
  // Needed during initalizaiton
  JSONObject obj;

  
  //Constructor(s) 
  //Try to parse the file name
  //If it's not there use the defaul(s)
  
  //Constructor
  Part(float x, float y, String partname) {
        polygons = new ArrayList<PolygonShape>();
        circles = new ArrayList<CircleShape>();

        if(loadFile(partname)){
          parseJSON();     
        }else{
         setDefaults(); 
        }
        
        makeBody(new Vec2(x, y));
        body.setUserData(this);
}

// Constructor that takes JSON object instead of string, that way the robot class can
// parse the robot paramteters and give the rest to the Part 
  Part(float x, float y, JSONObject initObj) {
     polygons = new ArrayList<PolygonShape>();
     circles = new ArrayList<CircleShape>();
     obj=initObj;
     parseJSON();
    body.setUserData(this);
  
}
  
  //This function removes the particle from the box2d world
  void killBody() {
    box2d.destroyBody(body);
  }
  
  
  boolean loadFile(String fname){
  
    try{
         obj = loadJSONObject(fname);
         return true;
    }catch(RuntimeException e){
         print("Could not parse " + fname + ".\nEXCEPTION MESSAGE: " + e.getMessage() + "\n");
         print("If the filname is correct, check for matching \"{}\", \"[]\", and missing \",\" etc.\n");
         print("Defaulting to preset values.\n\n");
         return false;  
      }

  }  
  
  //This function parses the part from the JSON ojbect
  //It assums a file has been parsed or the construcor is called 
  //with the JSON Object
  void parseJSON(){
        
    JSONObject polyObj;
    JSONObject polyPt;
    JSONArray polyPtArray;
    JSONObject circObj;
 
    try{
      name = obj.getString("name");            
    } 
    catch(RuntimeException e){
      print("Engry for \"name\" missing or not parsable.\nEXCEPTION MESSAGE: " + e.getMessage() + "\n");
      name = "part"; 
    }  
    
     try{
        force_scale= obj.getFloat("force");
     }  
     catch(RuntimeException e){
//            print("Entry \"force\" not found.\nEXCEPTION MESSAGE: " + e.getMessage() + "\n");
//            print("Setting \"force\" to 1\n\n");
        force_scale=1; 
     }
     try{
        noise_frac= obj.getFloat("noise");
     }  
     catch(RuntimeException e){
//        print("Entry \"noise\" not found.\nEXCEPTION MESSAGE: " + e.getMessage() + "\n");
//        print("Setting \"noise\" to 1\n\n");
        noise_frac=1; 
     }
     try{
        JSONObject colObj= obj.getJSONObject("color");
        partColor = color(colObj.getInt("r"), colObj.getInt("g"),colObj.getInt("b"));
     }  
     catch(RuntimeException e){
        print("Color missing or not parsable.\nEXCEPTION MESSAGE: " + e.getMessage() + "\n");
        partColor = color(50,50,50); 
     }
     try{
        scale= obj.getFloat("scale");
     }  
     catch(RuntimeException e){
        print("Entry \"scale\" not found.\nEXCEPTION MESSAGE: " + e.getMessage() + "\n");
        print("Setting \"scale\" to 1\n\n");
        scale=1; 
     }
     try{
        damping= obj.getFloat("table_friction");
     }  
     catch(RuntimeException e){
        print("Entry \"friction\" not found.\nEXCEPTION MESSAGE: " + e.getMessage() + "\n");
        print("Setting \"friction\" to 0.5\n\n");
        damping = 10; 
     }
     try{
        density= obj.getFloat("density");
     }  
     catch(RuntimeException e){
        print("Entry \"density\" not found.\nEXCEPTION MESSAGE: " + e.getMessage() + "\n");
        print("Setting \"density\" to 0.5\n\n");
        density=0.5; 
     }
     try{
        friction= obj.getFloat("part_friction");
     }
     catch(RuntimeException e){
        print("Entry \"damping\" not found.\nEXCEPTION MESSAGE: " + e.getMessage() + "\n");
        print("Setting \"damping\" to 5\n\n");
        friction=0.2; 
     }
     try{
          JSONArray polyArray = obj.getJSONArray("polygons");
          for(int i=0; i<polyArray.size(); i++){                                // Loop through polygons
            polyObj = polyArray.getJSONObject(i);                               //Extract polygon object
            polyPtArray = polyObj.getJSONArray("poly");
            Vec2[] vertices = new Vec2[polyPtArray.size()];                     //Set up vector for vertices of the appropriate size
            for(int p=0; p<polyPtArray.size(); p++){                            //Add vertices to the polygon        
              polyPt = polyPtArray.getJSONObject(p);
              vertices[p] = box2d.vectorPixelsToWorld(new Vec2(polyPt.getFloat("x")*scale, polyPt.getFloat("y")*scale)); 
            }      
            PolygonShape sd = new PolygonShape();
            sd.set(vertices, vertices.length);                
            polygons.add(sd);                                                    //Add shape to shape array of part class 
          }
      }catch(RuntimeException e){                                              //Polygon exception catch, set default shape
//          print("No polygons found in " + fname + ".\n\n");                
      }
      try{  
          JSONArray circArray = obj.getJSONArray("circles");                    //Check for circles            
          for(int i=0; i<circArray.size(); i++){                                //Loop through circles in file
            circObj = circArray.getJSONObject(i);                               //Extract circle object
            Vec2 point = new Vec2();                                            //Read circle center
            point = box2d.vectorPixelsToWorld(new Vec2(circObj.getFloat("x")*scale, circObj.getFloat("y")*scale));
            float r = box2d.scalarPixelsToWorld(circObj.getFloat("r")*scale);         //Read circle radius
            CircleShape cs = new CircleShape();                                 //Setup cs
            cs.m_p.set(point.x, point.y);
            cs.m_radius = r;
            circles.add(cs);                                                    //Add shape to shape array of part class  
          }
      }
      catch(RuntimeException e){
//            print("No circles found.\n\n");                
      }

  }                                                                                //End of load file

  // Function to populate defaults
 void setDefaults(){
          scale=1;
          damping=0.2;
          density=0.1;
          friction=0.5;
          restitution=0.1;
          partColor=color(0,150,150);
          PolygonShape sd = new PolygonShape();
          Vec2[] vertices = new Vec2[4];
          vertices[0] = box2d.vectorPixelsToWorld(new Vec2(-15*scale, 25*scale));
          vertices[1] = box2d.vectorPixelsToWorld(new Vec2(15*scale, 0*scale));
          vertices[2] = box2d.vectorPixelsToWorld(new Vec2(20*scale, -15*scale));
          vertices[3] = box2d.vectorPixelsToWorld(new Vec2(-10*scale, -10*scale));
          sd.set(vertices, vertices.length);              
          polygons.add(sd);  
   
 }
 
/*****************************************************/
/* Drawing the part (in pixels)                      */
/*****************************************************/
  void display() {

    Vec2 pos = box2d.getBodyPixelCoord(body);                     //Get screen position of each body
    float a = body.getAngle();                                    //Get rotation angle of each body

    for (PolygonShape p: polygons) {
      rectMode(CENTER);
      pushMatrix();
      translate(pos.x, pos.y);
      rotate(-a);
      fill(partColor);
      stroke(partColor*1.01);
      beginShape();
      for (int i = 0; i < p.getVertexCount(); i++) {
        Vec2 v = box2d.vectorWorldToPixels(p.getVertex(i));
        vertex(v.x, v.y);
      }
      endShape(CLOSE);
      popMatrix() ;
    }
    
    for (CircleShape cs: circles) {
      rectMode(CENTER);
      pushMatrix();
      translate(pos.x,pos.y);
      rotate(-a);
      fill(partColor);
      stroke(partColor*1.01);
      beginShape();
      Vec2 v = box2d.vectorWorldToPixels(cs.m_p);
      float r = box2d.scalarWorldToPixels(cs.m_radius);
      ellipse(v.x, v.y, 2*r, 2*r);
      endShape(CLOSE);
      popMatrix() ;
    } 
 }


/* Funciton applies torque to body */
/*
Angles are measured CCW with zero in The x direction. 
For exmple the left hand side of the frame should have 
an angle of PI, pointing into the center.
*/

void applySoftBoundary(float normalDirection, float strength){
  float heading = body.getAngle()-PI/2;
  Vec2 pos = body.getWorldCenter();
  
  Vec2 normal = new Vec2(cos(normalDirection),sin(normalDirection));
  Vec2 headingVec = new Vec2(cos(heading),sin(heading));
  
  // this is not quite working (it alwyas spins in the same direction).
  float torque = normal.x*headingVec.y - normal.y*headingVec.x;
  
  // not sure this is right in terms of direction  
  body.applyTorque(-strength*0.5*torque);
  
  body.applyForce(new Vec2(strength*cos(normalDirection),strength*sin(normalDirection)), pos);
  
}

/*****************************************************/
/* Making the body, creating the physics             */
/*****************************************************/
/*
This function assumes that some infromation has been put into the shape arrays 
and parameters such as scale, friciton, etc.
*/

void makeBody(Vec2 center) {

    // Define the body and make it from the shape
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position.set(box2d.coordPixelsToWorld(center));
    bd.angle = random(TWO_PI);               //Start object at random angle

    bd.linearDamping =  damping;
    bd.angularDamping = damping;
        
    body = box2d.createBody(bd);

    //Make polygons
    for (PolygonShape p: polygons) {
      // Define a fixture
      FixtureDef fd = new FixtureDef();
      fd.shape = p;
      // Parameters that affect physics
      fd.density  =    density;
      fd.friction =    friction;
      fd.restitution = restitution;  
      body.createFixture(fd);
    }
    
    for (CircleShape cs: circles) {
      // Define a fixture
      FixtureDef fd = new FixtureDef();
      fd.shape = cs;
      // Parameters that affect physics
      fd.density = density;
      fd.friction = friction;
      fd.restitution = restitution;
      body.createFixture(fd);
    } 
    
  }
  
  
// write yourself to a space separated value file
 void logpose(PrintWriter ofile){
   String separator=", "; 
   if(printHeader){
   printHeader=false; 
   ofile.print(separator + name+".x" + separator + name+".y"+ separator + name+".theta");
  }else{
   Vec2 pos = box2d.getBodyPixelCoord(body);  
   ofile.print(separator + pos.x + separator + pos.y + separator + body.getAngle());
  }
 }
  
  
  void jumpRandom(){
    
    //only randomly place Dynamice objects
   
    body.setTransform(box2d.vectorPixelsToWorld(new Vec2(random(-width/2+100,width/2-100), random(-height/2+100,height/2-100))),random(TWO_PI));
 
}//jumpRandom 
}//Part