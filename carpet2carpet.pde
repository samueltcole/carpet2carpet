import beads.*;
import org.jaudiolibs.beads.*;

import processing.video.*;

static final int IMAGE_WIDTH = 1280;
static final int IMAGE_HEIGHT = 720;
static final int CAPTURE_WIDTH = 10;
static final int CAPTURE_HEIGHT = 200;
static final int CAPTURE_X = IMAGE_WIDTH/2 - (CAPTURE_WIDTH/2);
static final int CAPTURE_Y = IMAGE_HEIGHT/2 - (CAPTURE_HEIGHT/2);
static final int FINISH_WIDTH = 1000;
static final int FINISH_HEIGHT = 200;
static final int FINISH_X = IMAGE_WIDTH/2 - (FINISH_WIDTH/2);
static final int FINISH_Y = IMAGE_HEIGHT/2 - (FINISH_HEIGHT/2);
final float DIFF_FRACTION = 0.2; // fraction of pixels that have to be different to trigger
final float NOTICABLE_DIFF = 60; // RGB total difference to count

AudioContext ac;
PImage backgroundImage;
PImage photoFinish;
int startTime = 0;
int savedTime = 0;
boolean timing = false;

Capture video;

void setup() {
  size(1280, 720);
  
  ac = new AudioContext();
  
  strokeWeight(1);
  rectMode(CORNER);
  textSize(30);
  
  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(" - " + cameras[i]);
    }
    println("Chosen camera: " + cameras[0]);
    video = new Capture(this, cameras[0]);
    video.start();     
  }
  backgroundImage = get(CAPTURE_X, CAPTURE_Y, CAPTURE_WIDTH, CAPTURE_HEIGHT);
  
  ac.start();
}

void draw() {
  // video feed
  if (video.available() == true) {
    video.read();
  }
  set(0, 0, video);
  
  // draw the capture zone
  noFill();
  stroke(0, 255, 0);
  rect(CAPTURE_X, CAPTURE_Y, CAPTURE_WIDTH, CAPTURE_HEIGHT);
  
  // draw the finish zone
  stroke(255, 0, 0);
  rect(FINISH_X, FINISH_Y, FINISH_WIDTH, FINISH_HEIGHT);
  
  // current background (debug)
  if(backgroundImage != null) {
    image(backgroundImage, 0, 0);
  }
  // photo finish
  if(photoFinish != null) {
    image(photoFinish, IMAGE_WIDTH - FINISH_WIDTH, 0);
  }
  
  // time
  fill(0, 255, 0);
  textAlign(LEFT);
  text((millis() - startTime), 0, IMAGE_HEIGHT);
  textAlign(RIGHT);
  text(savedTime, IMAGE_WIDTH, IMAGE_HEIGHT);
  
  // if timing then compare backgroundImage
  if(timing) {
    PImage currentCapture = get(CAPTURE_X, CAPTURE_Y, CAPTURE_WIDTH, CAPTURE_HEIGHT);
    PImage currentFinish = get(FINISH_X, FINISH_Y, FINISH_WIDTH, FINISH_HEIGHT);
    if(!isSameImage(currentCapture, backgroundImage)) {
      println("Stopping Clock!");
      savedTime = millis() - startTime;
      timing = false;
      photoFinish = currentFinish;
    }
  }
}

void keyPressed() {
  if(key == '`') {
    println("Setting new backgroundImage");
    backgroundImage = get(CAPTURE_X, CAPTURE_Y, CAPTURE_WIDTH, CAPTURE_HEIGHT);
  } else if (key == ' ') {
    println("Starting timer");
    startTime = millis();
    timing = true;
    makeBeep();
  }
}

boolean isSameImage(PImage a, PImage b) {
  a.loadPixels();
  b.loadPixels();
  int numPixels = a.pixels.length;
  int numDiff = 0;
  for(int i=0; i<numPixels; i++) {
    float redDiff = abs(red(a.pixels[i]) - red(b.pixels[i]));
    float greenDiff = abs(green(a.pixels[i]) - green(b.pixels[i]));
    float blueDiff = abs(blue(a.pixels[i]) - blue(b.pixels[i]));
    if((redDiff + greenDiff + blueDiff) > NOTICABLE_DIFF) {
      numDiff++;
    }
  }
  //println(numDiff + " of " + numPixels);
  if(numDiff > (numPixels * DIFF_FRACTION)) {
    return false;
  } else {
    return true;
  }
}

void makeBeep() {
  Gain g = new Gain(ac, 1, 1);
  Envelope freqEnv = new Envelope(ac, 750);
  WavePlayer wp = new WavePlayer(ac, freqEnv, Buffer.SINE);
  g.addInput(wp);
  freqEnv.addSegment(750, 400, new KillTrigger(g));
  ac.out.addInput(g);
}
