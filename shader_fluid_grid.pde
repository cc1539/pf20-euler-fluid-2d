
FluidField2D ff2d;
PGraphics canvas;

boolean running = true;

void setup() {
  size(840,840,P2D);
  ((PGraphicsOpenGL)g).textureSampling(3);
  canvas = createGraphics(width,height,P2D);
  ff2d = new FluidField2D(canvas.width,canvas.height);
}

void keyPressed() {
  switch(key) {
    case 'c': {
      ff2d.clear();
    } break;
    case 'r': {
      ff2d.randomize(50);
    } break;
    case 's': {
      ff2d.init(500,0);
    } break;
    case ' ': {
      running = !running;
    } break;
  }
}

void draw() {
  
  //ff2d.updateVorticity(0.125);
  
  if(mousePressed) {
    float x = (float)mouseX/width*canvas.width;
    float y = (1-(float)mouseY/height)*canvas.height;
    float r = 30./width*canvas.width;
    if(mouseButton==LEFT) {
      ff2d.paint(x,y,r,100,FluidField2D.VORT);
    } else if(mouseButton==RIGHT) {
      ff2d.paint(x,y,r, (mouseX-pmouseX)*2.5,FluidField2D.VX);
      ff2d.paint(x,y,r,-(mouseY-pmouseY)*2.5,FluidField2D.VY);
    } else if(mouseButton==CENTER) {
      ff2d.paint(x,y,r,-20,FluidField2D.RHO);
    }
  }
  
  if(running) {
    for(int t=0;t<1;t++) {
      //ff2d.diffuse(5e-3);
      //ff2d.viscosity(0.2);
      ff2d.advect(.1);
      for(int i=0;i<5;i++) {
        ff2d.updatePressure(0.125);
        ff2d.applyPressure(1);
      }
      ff2d.applyVorticity(0.0625);
      //ff2d.fade(.1,FluidField2D.RHO);
    }
  }
  
  ff2d.render(canvas);
  image(canvas,0,0,width,height);
  
  surface.setTitle("FPS: "+frameRate);
}
