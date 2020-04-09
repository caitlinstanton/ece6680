/*****************************************************************************/
/* By Nils Napp and Kirstin Petersen, March 2016                             */
/* Robots has additional functions overlayed on Part                         */
/*****************************************************************************/

class Robot extends Part {

  // parameters for moving
  int move_count=0;

  // Constructor
  Robot(float x, float y) {
    super(x, y, "robot.json");
  }

  //Constructor
  Robot(float x, float y, String fname) {
    super(x, y, fname);
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
    int move_skips=(int)random(30, 100);    //Determines how often random rotations are applied
    move_count=move_count + 1;
    if ( ( move_count % move_skips ) == 0) { //At random intervals apply a small random rotation
      move_count=0;
      body.setTransform(body.getPosition(), a+random(-PI/8, PI/8));
    }
    Vec2 forceVector = new Vec2(force_scale*sin(a), -cos(a)*force_scale);  
    body.applyForce(forceVector.mul(random(0.8*1.2)), body.getWorldCenter());                  //Apply a force to the robot
   
  }
}