/*****************************************************************************/
/* By Nils Napp and Kirstin Petersen, March 2016                             */
/* Robots has additional functions overlayed on Part                         */
/*****************************************************************************/

class Robot extends Part {

  // parameters for moving
  int move_count=0;
  Vec2 position;  //holds coords of position 5 seconds previous
  int time;       //holds system time of 5 seconds previous

  // Constructor
  Robot(float x, float y) {
    super(x, y, "robot.json");
  }

  //Constructor
  Robot(float x, float y, String fname) {
    super(x, y, fname);
    position = new Vec2(x,y);
    time = millis();
  }
  
  //To get position 5 seconds ago
  Vec2 get_last_pos() {
    return position;
  }
  
  //To get system time 5 seconds ago
  int get_last_time() {
    return time;
  }
  
  //To update position, time vars to current position, time
  void set_prev_deadlock(Vec2 newpos, int newtime) {
    position = newpos;
    time = newtime;
  }

  //To determine if mouse click is within robot boundaries
  boolean contains(float x, float y) {
    Vec2 worldPoint = box2d.coordPixelsToWorld(x, y);
    Fixture f = body.getFixtureList();
    boolean inside = f.testPoint(worldPoint);
    return inside;
  }

  //Function to implement robot motion 
  void move() {
    float a = body.getAngle();
    if (millis() - 5000 < get_last_time()) {  //If robot hasn't been deadlocked in the same position for more than 5 seconds
      int move_skips=(int)random(30, 100);    //Determines how often random rotations are applied
      move_count=move_count + 1;
      if ( ( move_count % move_skips ) == 0) { //At random intervals apply a small random rotation
        move_count=0;
        body.setTransform(body.getPosition(), a+random(-PI/8, PI/8));
      }
      Vec2 forceVector = new Vec2(force_scale*sin(a), -cos(a)*force_scale);  
      body.applyForce(forceVector.mul(random(0.8*1.2)), body.getWorldCenter());                  //Apply a force to the robot
    } else {   //If robot has been deadlocked in the same position for more than 5 seconds
      set_prev_deadlock(box2d.getBodyPixelCoord(body),millis());
      body.setTransform(body.getPosition(), a+random(-PI/2, PI/2));  // Applies larger random rotation to escape deadlock
      Vec2 forceVector = new Vec2(force_scale*sin(a), -cos(a)*force_scale);  
      body.applyForce(forceVector.mul(random(0.8*1.2)), body.getWorldCenter());                  //Apply a force to the robot
    }
   
  }
}
