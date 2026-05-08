// DESCRIPTION
// Mondrian Composition Generator
// Ported from p5js (OpenProcessing sketch 381152) by Queen Bee Art to desktop Processing: https://www.openprocessing.org/sketch/381152/
// From information metadata at source: (Piet) Mondrian compositions computed using shape grammar. 'A' adds vertical lines,
// 'B' adds horizontal lines, 'C' adds split vertical lines, and 'D' adds split horizontal lines. The text field controls the
// number of patches that are coloured. Play around with the buttons to get different compositions.
//
// DEPENDENCIES
// Processing
//
// USAGE
// Double click to open the sketch in the Processing IDE, or otherwise open it in anything else that can run processing.
// Run the sketch. Click on the rule text box to edit rules (type A/B/C/D). Click on percent box to edit percentage.
// Press ENTER to generate a new composition based on the rule string.
// Press S to save PNG and/or SVG (see booleans at top). Click PNG/SVG buttons to export (buttons override booleans).
//
// Creative Commons Share-Alike Attribution, by Richard Alexander Hall 2026-05-08, ported as noted from another
// developer under DESCRIPTION.
//
//
// CODE
String scriptVersion = "1.2.0"

import processing.svg.*;
import java.util.Collections;
import java.util.Calendar;

// Export settings - set these to true to enable auto-export on 's' key
boolean exportPNG = true;
boolean exportSVG = true;

// Layout settings - adjust these for different canvas sizes
int artWidth = 640;      // Width of the Mondrian artwork
int artHeight = 800;     // Height of the Mondrian artwork
int uiPanelHeight = 100; // Height of the UI panel at bottom

// Calculated dimensions - these will be set in settings()
int canvasWidth;
int canvasHeight;

String rule = "AABBCCDDDDDD";
String ruleInput = rule;  // For text input
int blinkTime;
boolean blinkOn;
boolean slide;
float keep = 0.5;
String percentText = "50";  // Text for percentage input

// Text input focus management
boolean focusRule = true;
boolean focusPercent = false;
int cursorBlinkTime;
boolean cursorVisible;

// Using ArrayLists for dynamic arrays
ArrayList<Integer> A_gr, B_gr;
ArrayList<Integer> A_add, B_add;
ArrayList<Integer> C_add, C_st, C_ed;
ArrayList<Integer> D_add, D_st, D_ed;
ArrayList<Integer> x1, y1, x2, y2;
ArrayList<Integer> xs1, ys1, xs2, ys2;
ArrayList<Integer> rec_col;
ArrayList<Integer> num;

int rec_c;

void settings() {
  // Calculate canvas dimensions BEFORE setting size
  canvasWidth = artWidth;
  canvasHeight = artHeight + uiPanelHeight;
  size(canvasWidth, canvasHeight);
}

void setup() {
  background(251, 252, 244);
  
  blinkTime = millis();
  cursorBlinkTime = millis();
  blinkOn = true;
  cursorVisible = true;
  slide = false;
  focusRule = true;  // Start with rule input focused
  focusPercent = false;
  
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

void drawArtwork(int offsetX, int offsetY, int sizeMultiplier) {
  // Draw colored patches
  for (int h = 0; h < xs1.size(); h++) {
    rectMode(CORNERS);
    noStroke();
    int g = rec_col.get(h);
    if (g < 4) fill(255, 247, 0);
    else if (g < 7) fill(247, 0, 4);
    else if (g < 10) fill(4, 4, 160);
    else fill(26, 20, 20);
    rect(offsetX + xs1.get(h) * sizeMultiplier, 
         offsetY + ys1.get(h) * sizeMultiplier, 
         offsetX + xs2.get(h) * sizeMultiplier, 
         offsetY + ys2.get(h) * sizeMultiplier);
  }
  
  // Draw lines
  stroke(0);
  strokeWeight(7);
  strokeCap(SQUARE);
  
  for (int kk = 0; kk < A_add.size(); kk++) {
    line(offsetX + A_add.get(kk) * sizeMultiplier, offsetY, 
         offsetX + A_add.get(kk) * sizeMultiplier, offsetY + artHeight);
  }
  for (int kk = 0; kk < B_add.size(); kk++) {
    line(offsetX, offsetY + B_add.get(kk) * sizeMultiplier, 
         offsetX + artWidth, offsetY + B_add.get(kk) * sizeMultiplier);
  }
  for (int kk = 0; kk < C_add.size(); kk++) {
    line(offsetX + C_add.get(kk) * sizeMultiplier, offsetY + C_st.get(kk) * sizeMultiplier,
         offsetX + C_add.get(kk) * sizeMultiplier, offsetY + C_ed.get(kk) * sizeMultiplier);
  }
  for (int kk = 0; kk < D_add.size(); kk++) {
    line(offsetX + D_st.get(kk) * sizeMultiplier, offsetY + D_add.get(kk) * sizeMultiplier,
         offsetX + D_ed.get(kk) * sizeMultiplier, offsetY + D_add.get(kk) * sizeMultiplier);
  }
}

void draw() {
  background(251, 252, 244);
  
  // Draw the artwork
  drawArtwork(0, 0, 25);
  
  // Update cursor blink
  if (millis() - cursorBlinkTime > 500) {
    cursorBlinkTime = millis();
    cursorVisible = !cursorVisible;
  }
  
  // Draw UI panel
  int uiY = artHeight;
  rectMode(CORNERS);
  noStroke();
  fill(50);
  rect(0, uiY, width, height);
  
  // Button dimensions (responsive)
  int buttonWidth = 70;
  int buttonHeight = 28;
  int buttonSpacing = 10;
  int startX = width - (buttonWidth * 4 + buttonSpacing * 3);
  int row1Y = uiY + 12;
  int row2Y = uiY + 50;
  
  // Row 1 buttons - dark gray
  fill(80);
  rect(startX, row1Y, startX + buttonWidth, row1Y + buttonHeight);
  rect(startX + buttonWidth + buttonSpacing, row1Y, startX + buttonWidth * 2 + buttonSpacing, row1Y + buttonHeight);
  rect(startX + (buttonWidth + buttonSpacing) * 2, row1Y, startX + buttonWidth * 3 + buttonSpacing * 2, row1Y + buttonHeight);
  rect(startX + (buttonWidth + buttonSpacing) * 3, row1Y, startX + buttonWidth * 4 + buttonSpacing * 3, row1Y + buttonHeight);
  
  fill(255);
  textSize(10);
  textAlign(CENTER, CENTER);
  text("RESET ALL", startX + buttonWidth/2, row1Y + buttonHeight/2);
  text("SHUFFLE\nCURVE", startX + buttonWidth + buttonSpacing + buttonWidth/2, row1Y + buttonHeight/2);
  text("SHUFFLE\nPATCH", startX + (buttonWidth + buttonSpacing) * 2 + buttonWidth/2, row1Y + buttonHeight/2);
  text("SHUFFLE\nCOLOUR", startX + (buttonWidth + buttonSpacing) * 3 + buttonWidth/2, row1Y + buttonHeight/2);
  
  // Row 2 export buttons
  fill(80);
  rect(startX, row2Y, startX + buttonWidth, row2Y + buttonHeight);
  rect(startX + buttonWidth + buttonSpacing, row2Y, startX + buttonWidth * 2 + buttonSpacing, row2Y + buttonHeight);
  
  fill(255);
  text("EXPORT PNG", startX + buttonWidth/2, row2Y + buttonHeight/2);
  text("EXPORT SVG", startX + buttonWidth + buttonSpacing + buttonWidth/2, row2Y + buttonHeight/2);
  
  // Input area - Ruleset and Percentage side by side
  int inputX = 20;
  int inputY = uiY + 12;
  int ruleWidth = 180;
  int percentWidth = 60;
  int inputHeight = 28;
  int spacing = 10;
  
  // Ruleset input box - highlight if focused
  if (focusRule) {
    stroke(100);
    strokeWeight(2);
  } else {
    noStroke();
  }
  fill(255);
  rect(inputX, inputY, inputX + ruleWidth, inputY + inputHeight);
  
  fill(0);
  textAlign(LEFT, CENTER);
  textSize(11);
  text(ruleInput, inputX + 5, inputY + inputHeight/2);
  
  // Draw cursor in rule field if focused
  if (focusRule && cursorVisible) {
    float textW = textWidth(ruleInput);
    stroke(0);
    strokeWeight(1);
    line(inputX + 5 + textW, inputY + 5, 
         inputX + 5 + textW, inputY + inputHeight - 5);
  }
  
  // Percentage text box - highlight if focused (no % sign inside box)
  noStroke();
  if (focusPercent) {
    stroke(100);
    strokeWeight(2);
  } else {
    noStroke();
  }
  fill(255);
  rect(inputX + ruleWidth + spacing, inputY, inputX + ruleWidth + spacing + percentWidth, inputY + inputHeight);
  
  fill(0);
  textAlign(CENTER, CENTER);
  text(percentText, inputX + ruleWidth + spacing + percentWidth/2, inputY + inputHeight/2);
  
  // Draw cursor in percent field if focused
  if (focusPercent && cursorVisible) {
    float textW = textWidth(percentText);
    stroke(0);
    strokeWeight(1);
    // Position cursor after the text
    line(inputX + ruleWidth + spacing + percentWidth/2 + textW/2, inputY + 5,
         inputX + ruleWidth + spacing + percentWidth/2 + textW/2, inputY + inputHeight - 5);
  }
  
  // Labels
  noStroke();
  fill(200);
  textSize(9);
  textAlign(LEFT, CENTER);
  text("Rule String (type anything, ENTER strips non-A/B/C/D)", inputX, inputY + inputHeight + 12);
  text("Fill %", inputX + ruleWidth + spacing, inputY + inputHeight + 12);
  
  // Instructions
  textAlign(CENTER, CENTER);
  textSize(9);
  text("S - Save PNG/SVG (see booleans at top of code)", width/2, height - 12);
}

void mouseClicked() {
  int uiY = artHeight;
  int buttonWidth = 70;
  int buttonSpacing = 10;
  int startX = width - (buttonWidth * 4 + buttonSpacing * 3);
  int row1Y = uiY + 12;
  int row2Y = uiY + 50;
  
  // Check button clicks first
  // RESET ALL
  if (mouseX > startX && mouseX < startX + buttonWidth && mouseY > row1Y && mouseY < row1Y + 28) {
    rule = "AABBCCDDDDDD";
    ruleInput = rule;
    keep = 0.5;
    percentText = "50";
    focusRule = true;
    focusPercent = false;
    setup();
    return;
  }
  
  // SHUFFLE CURVE
  if (mouseX > startX + buttonWidth + buttonSpacing && mouseX < startX + buttonWidth * 2 + buttonSpacing && 
      mouseY > row1Y && mouseY < row1Y + 28) {
    crv();
    patch();
    return;
  }
  
  // SHUFFLE PATCH
  if (mouseX > startX + (buttonWidth + buttonSpacing) * 2 && mouseX < startX + buttonWidth * 3 + buttonSpacing * 2 && 
      mouseY > row1Y && mouseY < row1Y + 28) {
    patch();
    return;
  }
  
  // SHUFFLE COLOUR
  if (mouseX > startX + (buttonWidth + buttonSpacing) * 3 && mouseX < startX + buttonWidth * 4 + buttonSpacing * 3 && 
      mouseY > row1Y && mouseY < row1Y + 28) {
    colour();
    return;
  }
  
  // PNG EXPORT button - overrides exportPNG boolean
  if (mouseX > startX && mouseX < startX + buttonWidth && mouseY > row2Y && mouseY < row2Y + 28) {
    exportToPNG();
    return;
  }
  
  // SVG EXPORT button - overrides exportSVG boolean
  if (mouseX > startX + buttonWidth + buttonSpacing && mouseX < startX + buttonWidth * 2 + buttonSpacing && 
      mouseY > row2Y && mouseY < row2Y + 28) {
    exportToSVG();
    return;
  }
  
  // Check text box clicks
  int inputX = 20;
  int ruleWidth = 180;
  int percentWidth = 60;
  int spacing = 10;
  int inputY = uiY + 12;
  int inputHeight = 28;
  
  // Click on rule input box
  if (mouseX > inputX && mouseX < inputX + ruleWidth && 
      mouseY > inputY && mouseY < inputY + inputHeight) {
    focusRule = true;
    focusPercent = false;
    cursorBlinkTime = millis();
    cursorVisible = true;
    return;
  }
  
  // Click on percentage text box
  if (mouseX > inputX + ruleWidth + spacing && mouseX < inputX + ruleWidth + spacing + percentWidth && 
      mouseY > inputY && mouseY < inputY + inputHeight) {
    focusRule = false;
    focusPercent = true;
    cursorBlinkTime = millis();
    cursorVisible = true;
    return;
  }
  
  // Click anywhere else - remove focus
  focusRule = false;
  focusPercent = false;
}

void keyPressed() {
  // Handle input based on which field has focus
  if (focusPercent) {
    // Percentage input handling
    if (key >= '0' && key <= '9') {
      String newText = percentText;
      if (newText.equals("0") && key != '0') {
        newText = "" + key;
      } else if (newText.length() < 3) {
        newText = newText + key;
      }
      int percent = int(newText);
      if (percent >= 0 && percent <= 100) {
        percentText = newText;
        keep = percent / 100.0;
        patch();
      }
    } else if (key == BACKSPACE && percentText.length() > 0) {
      percentText = percentText.substring(0, percentText.length() - 1);
      if (percentText.length() == 0) percentText = "0";
      int percent = int(percentText);
      keep = percent / 100.0;
      patch();
    } else if (key == DELETE && percentText.length() > 0) {
      percentText = percentText.substring(0, percentText.length() - 1);
      if (percentText.length() == 0) percentText = "0";
      int percent = int(percentText);
      keep = percent / 100.0;
      patch();
    }
  } else if (focusRule) {
    // Rule input handling - accept ANY key and add to ruleInput
    if (key == ENTER) {
      // Validate and process rule input
      String cleaned = "";
      for (int i = 0; i < ruleInput.length(); i++) {
        char c = Character.toUpperCase(ruleInput.charAt(i));
        if (c == 'A' || c == 'B' || c == 'C' || c == 'D') {
          cleaned += c;
        }
      }
      if (cleaned.length() > 0) {
        rule = cleaned;
        ruleInput = cleaned;  // Update the display to show the cleaned rule
        setup();
      }
    } else if (key == BACKSPACE && ruleInput.length() > 0) {
      ruleInput = ruleInput.substring(0, ruleInput.length() - 1);
    } else if (key == DELETE && ruleInput.length() > 0) {
      ruleInput = ruleInput.substring(0, ruleInput.length() - 1);
    } else if (key != CODED && key != ENTER && key != BACKSPACE && key != DELETE) {
      // Add any typed character to ruleInput (will be filtered on ENTER)
      if (ruleInput.length() < 32) {
        ruleInput = ruleInput + key;
      }
    }
  }
  
  // S key for export (respects booleans) - works regardless of focus
  if (key == 's' || key == 'S') {
    if (exportPNG) exportToPNG();
    if (exportSVG) exportToSVG();
  }
  
  // Reset cursor blink on any keypress
  cursorBlinkTime = millis();
  cursorVisible = true;
}

String getTimestamp() {
  Calendar cal = Calendar.getInstance();
  return String.format("%04d_%02d_%02d_%02d_%02d_%02d",
    cal.get(Calendar.YEAR),
    cal.get(Calendar.MONTH) + 1,
    cal.get(Calendar.DAY_OF_MONTH),
    cal.get(Calendar.HOUR_OF_DAY),
    cal.get(Calendar.MINUTE),
    cal.get(Calendar.SECOND)
  );
}

void exportToPNG() {
  String timestamp = getTimestamp();
  PImage artwork = get(0, 0, artWidth, artHeight);
  artwork.save(timestamp + "_Mondrian_Processing.png");
  println("Saved: " + timestamp + "_Mondrian_Processing.png");
}

void exportToSVG() {
  String timestamp = getTimestamp();
  beginRecord(SVG, timestamp + "_Mondrian_Processing.svg");
  drawArtwork(0, 0, 25);
  endRecord();
  println("Saved: " + timestamp + "_Mondrian_Processing.svg");
}
