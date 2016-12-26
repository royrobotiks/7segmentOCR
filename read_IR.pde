/* 
  
  This code  - reads a 3-digit 7-segment display via webcam
             - is written by Niklas Roy in Processing 3.2.3
             - is licensed under a beer-ware license
 
  Segment order:

    +---1---+
    |       |
    2       3
    |       |
    +---4---+
    |       |
    5       6
    |       |
    +---7---+
  
*/

import processing.video.*;
Capture cam;
PFont font;
  
int[][] segToDec = {                    // used to convert segments to decimal number
  {1,1,1,0,1,1,1}, /*0*/
  {0,0,1,0,0,1,0}, /*1*/
  {1,0,1,1,1,0,1}, /*2*/
  {1,0,1,1,0,1,1}, /*3*/
  {0,1,1,1,0,1,0}, /*4*/
  {1,1,0,1,0,1,1}, /*5*/
  {1,1,0,1,1,1,1}, /*6*/
  {1,0,1,0,0,1,0}, /*7*/
  {1,1,1,1,1,1,1}, /*8*/
  {1,1,1,1,0,1,1} /*9*/
}; 

float[] segX = {.5,0,1,.5,0,1,.5};      //position of each segment
float[] segY = {0,.5,.5,1,1.5,1.5,2}; 
int[] segments= new int[7];             //stores on / off value for each segment?
int refX=100;                           // reference pixel position
int refY=100;
int segI2X[]= {158,308,482};            // segment overlay positioning interface : coordinates of the 3 buttons per digit
int segI2Y[]= {158,158,300};
int segI3X[]= {127,275,458};
int segI3Y[]= {442,440,450};
int segI4X[]= {218,375,510};
int segI4Y[]= {442,440,450};
int Gdrag=0;                            // global button drag index
float Greference=0;                     // brightness reference value
int[] digit = new int [3];              // value of each digit

void setup() {
  
font = loadFont("OpenSans-16.vlw");

size(740, 580);

  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    cam = new Capture(this, cameras[0]);
    cam.start();     
  }      
}

void draw() {
  
   // ----------------------------------------------------------------------------------------------- draw webcam image
  if (cam.available() == true) {
    cam.read();
  }
  background(0);
  image(cam, 50, 50);
  filter(GRAY);
  textFont(font, 16);
  fill(255);
  float number=readLCD(); // reads 3-digit 7-segment value from webcam image - segments must be darker than reference point //value is returned as float
  fill(255);
  if (number>-1){text("NUMBER: "+number,50,560);}else{text("NUMBER: ----",50,560);}
}

//-------------------------------------------------- brightness picker - draws a square and returns brightness value
int getPixel(float xSense,float ySense){
  color c = get(int(xSense),int(ySense));
  int b=int(brightness(c));
  //text(b, xSense-3, ySense-7);
  stroke(255);
  noFill();
  rect(xSense-3,ySense-3,6,6);
  return (b);
}

//-------------------------------------------------- button with index to drag
  boolean buttonHit(int buttonX, int buttonY, int buttonI){
    /*x,y,index returns true if dragged*/
    boolean drag=false;
    if ((abs(mouseX-buttonX)<6 && abs(mouseY-buttonY)<6) || Gdrag==buttonI){
      if (mousePressed && Gdrag == 0){
        Gdrag=buttonI;
      }
    }
    if (Gdrag==buttonI && !mousePressed){
      Gdrag=0;
    }
    noFill();
    if ((abs(mouseX-buttonX)<6 && abs(mouseY-buttonY)<6)){fill (0);}
    if (Gdrag==buttonI){fill (255);drag=true;}
    rect(buttonX-5,buttonY-5,10,10);
    line(buttonX-7,buttonY-7,buttonX-3,buttonY-7);
    line(buttonX+3,buttonY-7,buttonX+7,buttonY-7);
    line(buttonX+7,buttonY-7,buttonX+7,buttonY-3);
    line(buttonX+7,buttonY+3,buttonX+7,buttonY+7);
    line(buttonX+7,buttonY+7,buttonX+3,buttonY+7);
    line(buttonX-3,buttonY+7,buttonX-7,buttonY+7);
    line(buttonX-7,buttonY+7,buttonX-7,buttonY+3);
    line(buttonX-7,buttonY-3,buttonX-7,buttonY-7);
    return drag;
    
  }
  
  
//-------------------------------------------------- print coordinates
  void printCoo(){
    println("int segI2X[]= {"+segI2X[0]+","+segI2X[1]+","+segI2X[2]+"};");
    println("int segI2Y[]= {"+segI2Y[0]+","+segI2Y[1]+","+segI2Y[2]+"};");
    println("int segI3X[]= {"+segI3X[0]+","+segI3X[1]+","+segI3X[2]+"};");
    println("int segI3Y[]= {"+segI3Y[0]+","+segI3Y[1]+","+segI3Y[2]+"};");
    println("int segI4X[]= {"+segI4X[0]+","+segI4X[1]+","+segI4X[2]+"};");
    println("int segI4Y[]= {"+segI4Y[0]+","+segI4Y[1]+","+segI4Y[2]+"};");
    println("----------------------------------");
  }
  
  float readLCD(){
   // ----------------------------------------------------------------------------------------------- position and read brightness reference pixel
   Greference=getPixel(refX,refY);
   Greference=Greference*.75;
   if(buttonHit(refX,refY,1)){ // button1: reference
    refX=mouseX;
    refY=mouseY;
   }
   fill(255);
   text("BRIGHT_REF: "+int(Greference), refX+10,refY+7);
   
   
   // =============================================================================================== read 3 digits
   
   for (int d=0; d<3; d++){ // d= digit index; iterating through 3 7-segment overlays
     
     // ----------------------------------------------------------------------------------------------- calculate origin, scale and skewion of 7 segment overlay
     int segIposX=segI2X[d];
     int segIposY=segI2Y[d];
     int segIscalX=(segI4X[d]-segI2X[d]);
     int segIscalY=(segI4Y[d]-segI2Y[d])/2;
     int skew=segI3X[d]-segI2X[d];
     
     // ----------------------------------------------------------------------------------------------- draw and pick brightness values of 7 segments
     for (int i=0;i<7;i++){  
       if(getPixel((segIposX+segX[i]*(segIscalX-skew)) + (segY[i]/2)*skew , segIposY+segY[i]*segIscalY)<Greference){
         segments[i]=1;
         fill(255);
         rect((segIposX+segX[i]*(segIscalX-skew)) + (segY[i]/2)*skew -7, segIposY+segY[i]*segIscalY -7,14,14);     
         noFill();
         stroke(0);
         rect((segIposX+segX[i]*(segIscalX-skew)) + (segY[i]/2)*skew -5, segIposY+segY[i]*segIscalY -5,10,10);
       }else{
         segments[i]=0;
       }
         stroke(255);
       }
     
     // ----------------------------------------------------------------------------------------------- convert segment readings to decimal digit value
       digit[d]=-1;
       for (int i=0;i<=9;i++){
          boolean b=true;
          for (int j=0; j<7;j++){
            if (segments[j]!=segToDec[i][j]){
              b=false;
              break;
            }
          }
         if (b){digit[d]=i;}
     }
     fill(255);
     text("DIGIT_"+d+": "+digit[d],segIposX +skew, segIposY+2*segIscalY+30);
     
     // ----------------------------------------------------------------------------------------------- 3-button interface to position 7 segment overlay
     
     if(buttonHit(segI2X[d],segI2Y[d],2+d*3)){ // --------- button2: top left 7segmentA 
      segI2X[d]=mouseX;
      segI2Y[d]=mouseY;
      if (segI2Y[d]+30>segI3Y[d]){segI3Y[d]=segI2Y[d]+30;segI4Y[d]=segI2Y[d]+30;}
      printCoo();
     }
     
     if(buttonHit(segI3X[d],segI3Y[d],3+d*3)){ // --------- button3: bottom left 7segmentA 
      segI3X[d]=mouseX;
      segI3Y[d]=mouseY;
      segI4Y[d]=mouseY;
      if (segI3Y[d]-30<segI2Y[d]){segI2Y[d]=segI3Y[d]-30;}
      if (segI3X[d]+30>segI4X[d]){segI4X[d]=segI3X[d]+30;}
      printCoo();
     }
     
     if(buttonHit(segI4X[d],segI4Y[d],4+d*3)){ // --------- button4: bottom right 7segmentA 
      segI4X[d]=mouseX;
      segI4Y[d]=mouseY;
      segI3Y[d]=mouseY;
      if (segI4Y[d]-30<segI2Y[d]){segI2Y[d]=segI4Y[d]-30;}
      if (segI4X[d]-30<segI3X[d]){segI3X[d]=segI4X[d]-30;}
      printCoo();
     } 
     
     // ----------------------------------------------------------------------------------------------- draw 7 segment overlay
     line(segIposX ,                  segIposY              , segIposX+segIscalX-skew ,         segIposY );
     line(segIposX,                   segIposY              , segIposX+skew ,                   segIposY+2*segIscalY );
     line(segIposX+segIscalX -skew,   segIposY              , segIposX+segIscalX ,              segIposY+2*segIscalY );
     line(segIposX +skew/2,           segIposY+segIscalY    , segIposX+segIscalX -skew/2,       segIposY+segIscalY );
     line(segIposX +skew,             segIposY+2*segIscalY  , segIposX+segIscalX ,              segIposY+2*segIscalY );
   }
   
   // =============================================================================================== end of reading 3 digits
   
   float value=digit[0]*100+digit[1]*10+digit[2];
   value=value/10;
   if (digit[0]==-1 || digit[1]==-1 || digit[2]==-1){value=-1;}
   return value;
  }
