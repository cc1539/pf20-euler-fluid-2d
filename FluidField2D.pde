
public class FluidField2D {
  
  public static final int VX   = 0; // velocity x
  public static final int VY   = 1; // velocity y
  public static final int RHO  = 2; // pressure
  public static final int VORT = 3; // vorticity
  public static final int INK  = 4; // ink
  
  public static final int DIFFUSE      = 0;
  public static final int ADVECT       = 1;
  public static final int UPDATE_RHO   = 2;
  public static final int APPLY_RHO_X  = 3;
  public static final int APPLY_RHO_Y  = 4;
  public static final int UPDATE_VORT  = 5;
  public static final int APPLY_VORT_X = 6;
  public static final int APPLY_VORT_Y = 7;
  public static final int RENDER       = 8;
  public static final int CLEAR        = 9;
  
  private PGraphics[] data;
  private PGraphics[] back;
  private PShader frag;
  private PShader paint;
  
  public FluidField2D(int w, int h) {
    frag = loadShader("frag.glsl");
    data = new PGraphics[5];
    back = new PGraphics[5];
    for(int i=0;i<data.length;i++) {
      data[i] = createGraphics(w,h,P2D);
      back[i] = createGraphics(w,h,P2D);
      data[i].beginDraw();
      data[i].loadPixels();
      data[i].endDraw();
      back[i].beginDraw();
      back[i].loadPixels();
      back[i].endDraw();
    }
    paint = loadShader("paint.glsl");
    //frag.set("canvasSize",w,h);
    clear();
  }
  
  private void swapBuffers() {
    PGraphics[] temp = data;
    data = back;
    back = temp;
  }
  
  private void swapBuffers(int mode) {
    PGraphics temp = data[mode];
    data[mode] = back[mode];
    back[mode] = temp;
  }
  
  void applyFilter(PShader shader, PGraphics target) {
    target.beginDraw();
    target.clear();
    target.filter(shader);
    target.endDraw();
  }
  
  void diffuse(float dt) {
    frag.set("dt",dt);
    frag.set("mode",DIFFUSE);
    for(int i=0;i<data.length;i++) {
      frag.set("src",data[i]);
      applyFilter(frag,back[i]);
    }
    swapBuffers();
  }
  
  void viscosity(float dt) {
    frag.set("dt",dt);
    frag.set("mode",DIFFUSE);
    frag.set("src",data[VX]); applyFilter(frag,back[VX]);
    frag.set("src",data[VY]); applyFilter(frag,back[VY]);
    swapBuffers(VX);
    swapBuffers(VY);
  }
  
  void advect(float dt) {
    frag.set("velocity[0]",data[VX]);
    frag.set("velocity[1]",data[VY]);
    frag.set("dt",dt);
    frag.set("mode",ADVECT);
    for(int i=0;i<data.length;i++) {
      frag.set("src",data[i]);
      applyFilter(frag,back[i]);
    }
    swapBuffers();
  }
  
  void updatePressure(float dt) {
    frag.set("dt",dt);
    frag.set("velocity[0]",data[VX]);
    frag.set("velocity[1]",data[VY]);
    frag.set("src",data[RHO]);
    frag.set("mode",UPDATE_RHO);
    applyFilter(frag,back[RHO]);
    swapBuffers(RHO);
  }
  
  void applyPressure(float dt) {
    frag.set("dt",dt);
    
    frag.set("velocity[0]",data[VX]);
    frag.set("velocity[1]",data[VY]);
    frag.set("src",data[RHO]);
    
    frag.set("mode",APPLY_RHO_X); applyFilter(frag,back[VX]);
    frag.set("mode",APPLY_RHO_Y); applyFilter(frag,back[VY]);
    swapBuffers(VX);
    swapBuffers(VY);
  }
  
  void updateVorticity(float dt) {
    frag.set("dt",dt);
    frag.set("velocity[0]",data[VX]);
    frag.set("velocity[1]",data[VY]);
    frag.set("src",data[VORT]);
    frag.set("mode",UPDATE_VORT);
    applyFilter(frag,back[VORT]);
    swapBuffers(VORT);
  }
  
  void applyVorticity(float dt) {
    frag.set("dt",dt);
    
    frag.set("velocity[0]",data[VX]);
    frag.set("velocity[1]",data[VY]);
    frag.set("src",data[VORT]);
    
    frag.set("mode",APPLY_VORT_X); applyFilter(frag,back[VX]);
    frag.set("mode",APPLY_VORT_Y); applyFilter(frag,back[VY]);
    swapBuffers(VX);
    swapBuffers(VY);
  }
  
  void render(PGraphics canvas) {
    frag.set("velocity[0]",data[VX]);
    frag.set("velocity[1]",data[VY]);
    frag.set("src",data[VORT]);
    frag.set("mode",RENDER);
    applyFilter(frag,canvas);
  }
  
  void clear() {
    frag.set("mode",CLEAR);
    for(int i=0;i<data.length;i++) {
      applyFilter(frag,data[i]);
    }
  }
  
  void init(float vx, float vy) {
    for(int x=0;x<data[0].width;x++) {
    for(int y=0;y<data[0].height;y++) {
      int i = x+y*data[0].width;
      float factor = sin(TWO_PI*y/data[0].height*4);
      data[VX].pixels[i] = Float.floatToIntBits(vx*factor);
      data[VY].pixels[i] = Float.floatToIntBits(vy*factor);
    }
    }
    data[VX].updatePixels();
    data[VY].updatePixels();
  }
  
  void randomize(float amount) {
    for(int x=0;x<data[0].width;x++) {
    for(int y=0;y<data[0].height;y++) {
      int i = x+y*data[0].width;
      float range = sqrt(random(0,1))*amount;
      float angle = random(0,TWO_PI);
      data[VX].pixels[i] = Float.floatToIntBits(range*cos(angle));
      data[VY].pixels[i] = Float.floatToIntBits(range*sin(angle));
    }
    }
    data[VX].updatePixels();
    data[VY].updatePixels();
  }
  
  void fade(float dt, int mode) {
    
  }
  
  void paint(float x, float y, float r, float value, int mode) {
    paint.set("src",data[mode]);
    paint.set("mouse",x,y);
    paint.set("r",r);
    paint.set("value",value);
    applyFilter(paint,back[mode]);
    swapBuffers(mode);
  }
  
}
