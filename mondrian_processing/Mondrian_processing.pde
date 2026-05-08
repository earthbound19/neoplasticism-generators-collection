// DESCRIPTION
// Mondrian Composition Generator
// Ported from p5js (OpenProcessing sketch 381152) by Qeen Bee Art to desktop Processing: https://www.openprocessing.org/sketch/381152/
// From information metadata at source: (Piet) Mondrian compositions computed using shape grammar. 'A' adds vertical lines,
// 'B' adds 'horizontal lines, 'C' adds split vertical lines, and 'D' adds split horizontal lines. The slider controls the
// number of patches that are coloured. Play around with the buttons to get different compositions.
//
// DEPENDENCIES
// Processing
//
// USAGE
// Double click to open the sketch in the Processing IDE, or otherwise open it in anything else that can run processing.
// Run the sketch. Toy around with it to see what it does. Note the visual grammar given under DESCRIPTION
//
// Creative Commons Share-Alike Attribution, by Richard Alexander Hall 2026-05-08, ported as noted from another
// developer under DESCRIPTION.
//
//
// CODE
import java.util.Collections;

String rule = "AABBCCDDDDDD";
String s = rule;
int blinkTime;
boolean blinkOn;
boolean slide;
float keep = 0.5; 
float sl = (20 + 320)/2;

// Using ArrayLists for dynamic arrays
ArrayList<Integer> A_gr, B_gr;
ArrayList<Integer> A_add, B_add;
ArrayList<Integer> C_add, C_st, C_ed;
ArrayList<Integer> D_add, D_st, D_ed;
ArrayList<Integer> x1, y1, x2, y2;
ArrayList<Integer> xs1, ys1, xs2, ys2;
ArrayList<Integer> rec_col;
ArrayList<Integer> num;

int n, m, k, u;
int rec_c;

void setup() {
  size(800, 930);
  background(251, 252, 244);
  
  blinkTime = millis();
  blinkOn = true;
  slide = false;
  
  crv();
  patch();
  colour();
}

void crv() {
  // Initialize all ArrayLists
  A_gr = new ArrayList<Integer>();
  B_gr = new ArrayList<Integer>();
  A_add = new ArrayList<Integer>();
  B_add = new ArrayList<Integer>();
  C_add = new ArrayList<Integer>();
  C_st = new ArrayList<Integer>();
  C_ed = new ArrayList<Integer>();
  D_add = new ArrayList<Integer>();
  D_st = new ArrayList<Integer>();
  D_ed = new ArrayList<Integer>();
  x1 = new ArrayList<Integer>();
  y1 = new ArrayList<Integer>();
  x2 = new ArrayList<Integer>();
  y2 = new ArrayList<Integer>();
  
  // First rectangle as canvas (0,0) to (32,32)
  x1.add(0);
  y1.add(0);
  x2.add(32);
  y2.add(32);
  
  // Fill A_gr and B_gr with values 1..31
  for (int i = 1; i <= 31; i++) {
    A_gr.add(i);
    B_gr.add(i);
  }
  
  // Process each character in the rule
  for (int charIdx = 0; charIdx < rule.length(); charIdx++) {
    // Ensure rectangles have correct orientation (x1 <= x2, y1 <= y2)
    for (int f = 0; f < x1.size(); f++) {
      if (x1.get(f) > x2.get(f)) {
        int dum = x2.get(f);
        x2.set(f, x1.get(f));
        x1.set(f, dum);
      }
      if (y1.get(f) > y2.get(f)) {
        int dum = y2.get(f);
        y2.set(f, y1.get(f));
        y1.set(f, dum);
      }
    }
    
    char c = rule.charAt(charIdx);
    if (c == 'A') {
      // Add a vertical line
      if (A_gr.size() == 0) continue;
      int r_a = (int)random(A_gr.size());
      int val = A_gr.get(r_a);
      A_add.add(val);
      
      // Split rectangles that contain this x coordinate
      int rectCount = x1.size();
      for (int j = 0; j < rectCount; j++) {
        if (x1.get(j) < val && x2.get(j) > val) {
          x1.add(val);
          y1.add(y1.get(j));
          x2.add(x2.get(j));
          y2.add(y2.get(j));
          x2.set(j, val);
        }
      }
      A_gr.remove(r_a);
      
    } else if (c == 'B') {
      // Add a horizontal line
      if (B_gr.size() == 0) continue;
      int r_b = (int)random(B_gr.size());
      int val = B_gr.get(r_b);
      B_add.add(val);
      
      int rectCount = y1.size();
      for (int w = 0; w < rectCount; w++) {
        if (y1.get(w) < val && y2.get(w) > val) {
          x1.add(x1.get(w));
          y1.add(val);
          x2.add(x2.get(w));
          y2.add(y2.get(w));
          y2.set(w, val);
        }
      }
      B_gr.remove(r_b);
      
    } else if (c == 'C') {
      // Add a split vertical line
      if (A_gr.size() == 0) continue;
      int r_c = (int)random(A_gr.size());
      int val = A_gr.get(r_c);
      
      if (B_add.size() + D_add.size() == 0) {
        // No horizontal lines yet – behave like A
        A_add.add(val);
        int rectCount = x1.size();
        for (int j = 0; j < rectCount; j++) {
          if (x1.get(j) < val && x2.get(j) > val) {
            x1.add(val);
            y1.add(y1.get(j));
            x2.add(x2.get(j));
            y2.add(y2.get(j));
            x2.set(j, val);
          }
        }
        A_gr.remove(r_c);
      } else {
        C_add.add(val);
        ArrayList<Integer> C_cont = new ArrayList<Integer>();
        C_cont.add(0);
        for (int q = 0; q < B_add.size(); q++) C_cont.add(B_add.get(q));
        if (D_add.size() > 0) {
          for (int kk = 0; kk < D_add.size(); kk++) {
            if (D_st.get(kk) < val && D_ed.get(kk) > val) {
              C_cont.add(D_add.get(kk));
            }
          }
        }
        C_cont.add(32);
        Collections.sort(C_cont);
        int C_pick = (int)random(1, C_cont.size() - 1);
        C_st.add(C_cont.get(C_pick - 1));
        C_ed.add(C_cont.get(C_pick));
        
        int rectCount = x1.size();
        for (int j = 0; j < rectCount; j++) {
          if (x1.get(j) <= val && x2.get(j) >= val && 
              y1.get(j) >= C_cont.get(C_pick - 1) && y2.get(j) <= C_cont.get(C_pick)) {
            x1.add(val);
            y1.add(y1.get(j));
            x2.add(x2.get(j));
            y2.add(y2.get(j));
            x2.set(j, val);
          }
        }
        A_gr.remove(r_c);
      }
      
    } else if (c == 'D') {
      // Add a split horizontal line
      if (B_gr.size() == 0) continue;
      int r_d = (int)random(B_gr.size());
      int val = B_gr.get(r_d);
      
      if (A_add.size() + C_add.size() == 0) {
        // No vertical lines yet – behave like B
        B_add.add(val);
        int rectCount = y1.size();
        for (int w = 0; w < rectCount; w++) {
          if (y1.get(w) < val && y2.get(w) > val) {
            x1.add(x1.get(w));
            y1.add(val);
            x2.add(x2.get(w));
            y2.add(y2.get(w));
            y2.set(w, val);
          }
        }
        B_gr.remove(r_d);
      } else {
        D_add.add(val);
        ArrayList<Integer> D_cont = new ArrayList<Integer>();
        D_cont.add(0);
        for (int p = 0; p < A_add.size(); p++) D_cont.add(A_add.get(p));
        if (C_add.size() > 0) {
          for (int kk = 0; kk < C_add.size(); kk++) {
            if (C_st.get(kk) < val && C_ed.get(kk) > val) {
              D_cont.add(C_add.get(kk));
            }
          }
        }
        D_cont.add(32);
        Collections.sort(D_cont);
        int D_pick = (int)random(1, D_cont.size() - 1);
        D_st.add(D_cont.get(D_pick - 1));
        D_ed.add(D_cont.get(D_pick));
        
        int rectCount = y1.size();
        for (int w = 0; w < rectCount; w++) {
          if (y1.get(w) <= val && y2.get(w) >= val && 
              x1.get(w) >= D_cont.get(D_pick - 1) && x2.get(w) <= D_cont.get(D_pick)) {
            x1.add(x1.get(w));
            y1.add(val);
            x2.add(x2.get(w));
            y2.add(y2.get(w));
            y2.set(w, val);
          }
        }
        B_gr.remove(r_d);
      }
    }
  }
}

void patch() {
  num = new ArrayList<Integer>();
  for (int i = 0; i < x1.size(); i++) num.add(i);
  Collections.shuffle(num);
  
  int q = (int)(x1.size() * keep);
  xs1 = new ArrayList<Integer>();
  ys1 = new ArrayList<Integer>();
  xs2 = new ArrayList<Integer>();
  ys2 = new ArrayList<Integer>();
  
  for (int i = 0; i < q; i++) {
    int idx = num.get(i);
    xs1.add(x1.get(idx));
    xs2.add(x2.get(idx));
    ys1.add(y1.get(idx));
    ys2.add(y2.get(idx));
  }
}

void colour() {
  rec_col = new ArrayList<Integer>();
  int add_no = 0;
  for (int i = 0; i < x1.size(); i++) {
    int add = (int)random(12);
    if (add_no > x1.size() / 6) add = (int)random(10);
    rec_col.add(add);
    if (add > 9) add_no++;
  }
}

void draw() {
  background(251, 252, 244);
  
  // Draw colored patches
  for (int h = 0; h < xs1.size(); h++) {
    rectMode(CORNERS);
    noStroke();
    int g = rec_col.get(h);
    if (g < 4) fill(255, 247, 0);
    else if (g < 7) fill(247, 0, 4);
    else if (g < 10) fill(4, 4, 160);
    else fill(26, 20, 20);
    rect(xs1.get(h) * 25, ys1.get(h) * 25, xs2.get(h) * 25, ys2.get(h) * 25);
  }
  
  // Draw lines
  stroke(0);
  strokeWeight(7);
  strokeCap(SQUARE);
  
  for (int kk = 0; kk < A_add.size(); kk++) {
    line(A_add.get(kk) * 25, 0, A_add.get(kk) * 25, 800);
  }
  for (int kk = 0; kk < B_add.size(); kk++) {
    line(0, B_add.get(kk) * 25, 800, B_add.get(kk) * 25);
  }
  for (int kk = 0; kk < C_add.size(); kk++) {
    line(C_add.get(kk) * 25, C_st.get(kk) * 25, C_add.get(kk) * 25, C_ed.get(kk) * 25);
  }
  for (int kk = 0; kk < D_add.size(); kk++) {
    line(D_st.get(kk) * 25, D_add.get(kk) * 25, D_ed.get(kk) * 25, D_add.get(kk) * 25);
  }
  
  // UI panel
  rectMode(CORNERS);
  noStroke();
  fill(220);
  rect(0, 800, width, 900);
  
  fill(190);
  rect(width-80, 820, width-20, 880);
  rect(width-160, 820, width-100, 880);
  rect(width-240, 820, width-180, 880);
  rect(width-320, 820, width-260, 880);
  
  fill(255);
  textSize(12);
  textAlign(CENTER, BOTTOM);
  text("RESET", width-50, 850);
  text("SHUFFLE", width-130, 850);
  text("SHUFFLE", width-210, 850);
  text("SHUFFLE", width-290, 850);
  textAlign(CENTER, TOP);
  text("ALL", width-50, 850);
  text("CURVE", width-130, 850);
  text("PATCH", width-210, 850);
  text("COLOUR", width-290, 850);
  
  // Ruleset display
  fill(255);
  rect(20, 820, 320, 845);
  rect(20, 855, 320, 880);
  
  fill(0);
  textAlign(LEFT, CENTER);
  text(s, 25, 832);
  
  fill(100);
  text("RULESET (E TO ERASE", 327, 826);
  text("ENTER TO EXECUTE)", 327, 842);
  text("% COLOURED PATCH", 327, 867);
  text("0", 25, 867);
  text("100", 294, 867);
  
  // Slider
  fill(190);
  rectMode(CENTER);
  rect(sl, (855+880)/2, 17, 17);
  rectMode(CORNERS);
  
  // Blinking cursor
  stroke(0);
  strokeWeight(1);
  float textW = textWidth(s);
  if (blinkOn) line(25 + textW + 1, 830-7, 25 + textW + 1, 830+10);
  if (millis() - 500 > blinkTime) {
    blinkTime = millis();
    blinkOn = !blinkOn;
  }
  
  // Bottom instructions
  noStroke();
  fill(0);
  rect(0, 900, width, height);
  fill(200);
  textAlign(CENTER, CENTER);
  text("A - Vertical Line | B - Horizontal Line | C - Split Vertical Line | D - Split Horizontal Line", width/2, 915);
}

void mouseDragged() {
  if (mouseX < sl+12.5 && mouseX > sl-12.5 && mouseY < (855+880)/2 + 12.5 && mouseY > (855+880)/2 - 12.5) {
    sl = constrain(mouseX, 32.5, 307.5);
    slide = true;
  }
}

void mouseReleased() {
  keep = 1 - (307.5 - sl) / (307.5 - 32.5);
  if (slide) {
    patch();
    slide = false;
  }
}

void mouseClicked() {
  if (mouseX > width-80 && mouseX < width-20 && mouseY > 820 && mouseY < height-20) {
    rule = "AABBCCDDDDDD";
    s = rule;
    keep = 0.5;
    setup();
    sl = (20+333)/2;
  }
  if (mouseX > width-320 && mouseX < width-260 && mouseY > 820 && mouseY < height-20) colour();
  if (mouseX > width-240 && mouseX < width-180 && mouseY > 820 && mouseY < height-20) patch();
  if (mouseX > width-160 && mouseX < width-100 && mouseY > 820 && mouseY < height-20) {
    crv();
    patch();
  }
  if (mouseX > 32.5 && mouseX < 307.5 && mouseY > 855 && mouseY < 880) {
    sl = mouseX;
    slide = true;
    mouseReleased();
  }
}

void keyPressed() {
  int len = s.length();
  if ((key == 'e' || key == 'E') && len > 0) {
    s = s.substring(0, s.length()-1);
  } else if ((key == 'A' || key == 'a' || key == 'B' || key == 'b' || key == 'C' || key == 'c' || key == 'D' || key == 'd') && len < 32) {
    char upper = Character.toUpperCase(key);
    s = s + upper;
  } else if (key == ENTER) {
    rule = s;
    setup();
  }
}
