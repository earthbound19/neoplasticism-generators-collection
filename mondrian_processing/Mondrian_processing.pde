// DESCRIPTION
// Ported from p5js (OpenProcessing sketch 381152) by Queen Bee Art to desktop Processing: https://www.openprocessing.org/sketch/381152/
// From information metadata at source: (Piet) Mondrian compositions computed using shape grammar. 'A' adds vertical lines,
// 'B' adds horizontal lines, 'C' adds split vertical lines, and 'D' adds split horizontal lines. The text field controls the
// number of patches that are coloured. Play around with the buttons to get different compositions.
//
// ADDITIONAL FEATURES
// Features have been added since that base port:
// - update to dynamic grid system that keeps grid division (resultant cells) roughly (or exactly) square for any canvas aspect ratio
// - implement color palette retrieval from a palette collection API: https://earthbound.io/data/random_ebPalette/ -- via button press
//   - with color subset selection with color count text field (0 = all colors)
// - add PNG and SVG export with full metadata (grammar, grid, palette name / URL)
// - add line collision avoidance to prevent overlapping/clustered lines
// - redesign UI with buttons for new features and better contrast
// - custom Mondrian palette with colors I reckon he used in his neoplastic paintings
// - dynamic line weight scaling based on canvas width (proportional to 1022px reference)
// - random line weight per sketch run (integer between scaled min/max)
// - make many mode: infinite generation of variants with auto-save (frame-based state machine, no background threading)
//
// DEPENDENCIES
// Processing
//
// USAGE
// Double click to open the sketch in the Processing IDE, or otherwise open it in anything else that can run processing.
// Run the sketch. Click on the rule text box to edit rules (type A/B/C/D). Click on percent box to edit percentage.
// Press ENTER to generate a new composition based on the rule string.
// Press S to save PNG and/or SVG (see booleans at top). Click PNG/SVG buttons to export (buttons override booleans).
// Click "MAKE MANY" to enter generation mode (button toggles to STOP). In MAKE MANY mode, the sketch generates
// and saves endless variations (new random curves + line weights) with the current grammar and color settings.
// Click STOP (which the MAKE MANY button changes to when that mode is active) to halt generation.
//
// LICENSE
// Creative Commons Share-Alike Attribution, by Richard Alexander Hall - 2026-05-12, ported from another developer,
// as noted under DESCRIPTION.
//
//
// CODE
// TO DO
// - museum mode; only display artwork area, fullscreen, no UI controls, getting a new palette in the background
//   for every new render, then doing the render when ready.
// - in museum mode, every 7th iteration use Mondrian palette as throwback?
// - rapid creation mode (many renders and PNG + SVG saves up to N renders)
// - CLI mode accepting a JSON config and dynamically patching settings
//   - to start any mode thereby also?
//   - to override globals like dimensions
//   - to override palette, specifying the config as "source" in written metadata

String scriptVersion = "2.4.18";
String scriptName = "Mondrian_Processing";
String paletteSource = "custom_mondrian";
String lastAPIPaletteName = "";
String lastAPIPaletteURL = "";

import processing.svg.*;
import java.util.Collections;
import java.util.Calendar;

// Export settings
boolean exportPNG = true;
boolean exportSVG = true;

// Layout settings - DYNAMIC GRID
int artWidth = 1022;      // Width of the neo-or-postplastic artwork; an assumed "average" width from many surveyed works
int artHeight = 1092;     // Height of the neo-or-postplastic artwork; an assumed "average" height from many surveyed works
int gridSizeReference = 32;  // Reference grid size for the shorter dimension
int uiPanelHeight = 135; // Height of the UI panel at bottom

// Line weight configuration - PROPORTIONAL SCALING
// Reference dimensions: max canvas width = 1022px
// At 1022px width: min line weight = 6px, max line weight = 32px
final float REFERENCE_WIDTH = 1022.0;
final float REFERENCE_MIN_WEIGHT = 6.0;
final float REFERENCE_MAX_WEIGHT = 32.0;

float currentLineWeight;  // Will be set randomly on each run
float minLineDistance;    // Minimum distance between lines (currentLineWeight * 2)

// Calculated dimensions
int canvasWidth;
int canvasHeight;
int gridSizeX;           // Number of horizontal divisions
int gridSizeY;           // Number of vertical divisions

String rule = "AABBCCDDDDDD";
String ruleInput = rule;
float keep = 0.5;
String percentText = "50";
String colorCountText = "0";

// Text input focus
boolean focusRule = true;
boolean focusPercent = false;
boolean focusColorCount = false;
int cursorBlinkTime;
boolean cursorVisible;

// MAKE MANY mode - frame-based state machine (no background thread)
boolean makeManyMode = false;
boolean makeManyGenerating = false;
int makeManyExportDelay = 0;
boolean makeManyExportQueued = false;

// Export flags for frame-synchronized capture
boolean pendingExportPNG = false;
boolean pendingExportSVG = false;

// CUSTOM MONDRIAN PALETTE (inspired by color analysis of original works)
// NOTE: #f6f6f6 (white) is EXCLUDED from this palette - it's reserved for canvas background only!
color[] customMondrianPalette = {
  #f22a27,  // Vibrant Mondrian red, and
  #f89027,  // Warm Mondrian orange,
  #ffcf30,  // Golden yellow,
  #0f0c9b,  // Deep ultramarine blue,
  #5168a3,  // Muted slate blue,
  #b1b1b1,  // Cool gray, and
  #050506   // Mondrian black
};

// Canvas white color (never used for patches)
final color CANVAS_WHITE = #f6f6f6;

// Line color (almost-black, warm)
final color LINE_COLOR = #050506;

// Color palette system
color[] fullPalette;
color[] activePalette;

String apiURL = "https://earthbound.io/data/random_ebPalette/";

// ArrayLists for dynamic arrays
ArrayList<Integer> A_gr;
ArrayList<Integer> B_gr;
ArrayList<Integer> A_add;
ArrayList<Integer> B_add;
ArrayList<Integer> C_add;
ArrayList<Integer> C_st;
ArrayList<Integer> C_ed;
ArrayList<Integer> D_add;
ArrayList<Integer> D_st;
ArrayList<Integer> D_ed;
ArrayList<Integer> x1;
ArrayList<Integer> y1;
ArrayList<Integer> x2;
ArrayList<Integer> y2;
ArrayList<Integer> xs1;
ArrayList<Integer> ys1;
ArrayList<Integer> xs2;
ArrayList<Integer> ys2;
ArrayList<Integer> rec_col;
ArrayList<Integer> num;

void settings() {
  pixelDensity(1);
  
  canvasWidth = artWidth;
  canvasHeight = artHeight + uiPanelHeight;
  
  size(canvasWidth, canvasHeight, P2D);
  
  // Disable global smoothing
  noSmooth();
}

void setup() {
  surface.setTitle(scriptName + " v" + scriptVersion);
  
  // Calculate line weight based on current canvas width
  calculateLineWeight();
  
  background(CANVAS_WHITE);
  
  // Calculate dynamic grid based on canvas proportions
  calculateGrid();
  minLineDistance = currentLineWeight * 2; // Minimum pixels between line centers
  
  // Initialize with custom Mondrian palette
  initCustomMondrianPalette();
  
  cursorBlinkTime = millis();
  cursorVisible = true;
  focusRule = true;
  focusPercent = false;
  focusColorCount = false;
  
  crv();
  patch();
  updateActivePalette();
  colour();

  // CRITICAL FIX: Force nearest-neighbor sampling
  // This completely disables anti-aliasing for
  // all geometry, which was causing inconsistent
  // line (black box) width appearance:
  ((PGraphicsOpenGL)g).textureSampling(2);
  
  println("Line weight: " + currentLineWeight + "px (scaled from " + artWidth + "px width)");
  println("Min line distance: " + minLineDistance + "px");
  println("Using custom Mondrian palette with " + fullPalette.length + " colors (white reserved for canvas)");
}

void calculateLineWeight() {
  // Calculate proportional scaling factor based on actual artWidth
  float scaleFactor = artWidth / REFERENCE_WIDTH;
  
  // Calculate min and max for this canvas size
  float scaledMin = REFERENCE_MIN_WEIGHT * scaleFactor;
  float scaledMax = REFERENCE_MAX_WEIGHT * scaleFactor;
  
  // Apply lower bound clamping to prevent lines from being too thin
  // Minimum practical line weight is 3px (anything smaller loses visual impact)
  final float ABSOLUTE_MIN_WEIGHT = 3.0;
  if (scaledMin < ABSOLUTE_MIN_WEIGHT) {
    scaledMin = ABSOLUTE_MIN_WEIGHT;
    // Adjust max proportionally if min was clamped
    if (scaledMax < scaledMin + 2) {
      scaledMax = scaledMin + 2;
    }
  }
  
  // Randomly select line weight between scaled min and max
  currentLineWeight = random(scaledMin, scaledMax);
  
  // Round to nearest integer
  currentLineWeight = round(currentLineWeight);
  
  if (currentLineWeight < 1) currentLineWeight = 1;
}

void calculateGrid() {
  if (artWidth <= artHeight) {
    // Width is the shorter or equal dimension
    float cellSize = (float)artWidth / (float)gridSizeReference;
    gridSizeX = gridSizeReference;
    gridSizeY = Math.round((float)artHeight / cellSize);
  } else {
    // Height is the shorter dimension
    float cellSize = (float)artHeight / (float)gridSizeReference;
    gridSizeY = gridSizeReference;
    gridSizeX = Math.round((float)artWidth / cellSize);
  }
  
  // Ensure we have at least 2 divisions so lines can be placed
  if (gridSizeX < 2) gridSizeX = 2;
  if (gridSizeY < 2) gridSizeY = 2;
  
  println("Canvas: " + artWidth + "x" + artHeight);
  println("Grid: " + gridSizeX + " x " + gridSizeY);
  println("Cell size: ~" + ((float)artWidth / gridSizeX) + "px x " + ((float)artHeight / gridSizeY) + "px");
}

float getX(int gridPos) {
  return (float)gridPos * (float)artWidth / (float)gridSizeX;
}

float getY(int gridPos) {
  return (float)gridPos * (float)artHeight / (float)gridSizeY;
}

// Check if a vertical line at gridX would be too close to existing vertical lines
boolean isVerticalLineTooClose(int gridX, ArrayList<Integer> existingLines) {
  float pixelX = getX(gridX);
  for (int existing : existingLines) {
    float existingPixelX = getX(existing);
    if (Math.abs(pixelX - existingPixelX) < minLineDistance) {
      return true;
    }
  }
  return false;
}

// Check if a horizontal line at gridY would be too close to existing horizontal lines
boolean isHorizontalLineTooClose(int gridY, ArrayList<Integer> existingLines) {
  float pixelY = getY(gridY);
  for (int existing : existingLines) {
    float existingPixelY = getY(existing);
    if (Math.abs(pixelY - existingPixelY) < minLineDistance) {
      return true;
    }
  }
  return false;
}

void initCustomMondrianPalette() {
  fullPalette = new color[customMondrianPalette.length];
  for (int i = 0; i < customMondrianPalette.length; i++) {
    fullPalette[i] = customMondrianPalette[i];
  }
  paletteSource = "custom_mondrian";
  lastAPIPaletteName = "";
  lastAPIPaletteURL = "";
  colorCountText = str(fullPalette.length);
  updateActivePalette();
  println("Using custom Mondrian palette with " + fullPalette.length + " colors");
}

void updateActivePalette() {
  int limit = int(colorCountText);
  if (limit <= 0 || limit >= fullPalette.length) {
    activePalette = new color[fullPalette.length];
    for (int i = 0; i < fullPalette.length; i++) {
      activePalette[i] = fullPalette[i];
    }
    println("Using all " + fullPalette.length + " colors");
  } else {
    ArrayList<Integer> indices = new ArrayList<Integer>();
    for (int i = 0; i < fullPalette.length; i++) {
      indices.add(i);
    }
    Collections.shuffle(indices);
    
    activePalette = new color[limit];
    for (int i = 0; i < limit; i++) {
      activePalette[i] = fullPalette[indices.get(i)];
    }
    println("Using " + limit + " random colors from palette of " + fullPalette.length);
  }
}

void fetchColorsFromAPI() {
  println("Fetching colors from earthbound.io API...");
  Thread t = new Thread(new Runnable() {
    public void run() {
      try {
        JSONObject json = loadJSONObject(apiURL);
        JSONArray colorArray = json.getJSONArray("colors");
        
        // Extract metadata
        lastAPIPaletteName = json.getString("paletteName");
        lastAPIPaletteURL = json.getString("textSourceURL");
        
        color[] newPalette = new color[colorArray.size()];
        for (int i = 0; i < colorArray.size(); i++) {
          String hexColor = colorArray.getString(i);
          newPalette[i] = unhex("FF" + hexColor.substring(1));
        }
        
        fullPalette = new color[newPalette.length];
        for (int i = 0; i < newPalette.length; i++) {
          fullPalette[i] = newPalette[i];
        }
        paletteSource = "api";
        colorCountText = str(fullPalette.length);
        updateActivePalette();
        colour();
        
        println("Successfully loaded " + fullPalette.length + " colors from API");
        println("Palette name: " + lastAPIPaletteName);
        println("Palette URL: " + lastAPIPaletteURL);
      } catch (Exception e) {
        println("API fetch failed: " + e.getMessage());
        lastAPIPaletteName = "";
        lastAPIPaletteURL = "";
      }
    }
  });
  t.start();
}

void crv() {
  // Re-randomize line weight for this new composition
  calculateLineWeight();
  minLineDistance = currentLineWeight * 2;

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
  
  // First rectangle as canvas (0,0) to (gridSizeX, gridSizeY)
  x1.add(0);
  y1.add(0);
  x2.add(gridSizeX);
  y2.add(gridSizeY);
  
  // Fill A_gr with values 1..gridSizeX-1 (possible vertical split positions)
  // Fill B_gr with values 1..gridSizeY-1 (possible horizontal split positions)
  for (int i = 1; i < gridSizeX; i++) {
    A_gr.add(i);
  }
  for (int i = 1; i < gridSizeY; i++) {
    B_gr.add(i);
  }
  
  for (int charIdx = 0; charIdx < rule.length(); charIdx++) {
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
      // Add a vertical line with collision avoidance
      if (A_gr.size() == 0) continue;
      
      // Find valid positions not too close to existing lines
      ArrayList<Integer> validPositions = new ArrayList<Integer>();
      for (int pos : A_gr) {
        if (!isVerticalLineTooClose(pos, A_add)) {
          validPositions.add(pos);
        }
      }
      
      // If no valid positions, fall back to any position
      ArrayList<Integer> sourceList = validPositions.size() > 0 ? validPositions : A_gr;
      int r_a = (int)random(sourceList.size());
      int val = sourceList.get(r_a);
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
      A_gr.remove(Integer.valueOf(val));
      
    } else if (c == 'B') {
      // Add a horizontal line with collision avoidance
      if (B_gr.size() == 0) continue;
      
      // Find valid positions not too close to existing lines
      ArrayList<Integer> validPositions = new ArrayList<Integer>();
      for (int pos : B_gr) {
        if (!isHorizontalLineTooClose(pos, B_add)) {
          validPositions.add(pos);
        }
      }
      
      // If no valid positions, fall back to any position
      ArrayList<Integer> sourceList = validPositions.size() > 0 ? validPositions : B_gr;
      int r_b = (int)random(sourceList.size());
      int val = sourceList.get(r_b);
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
      B_gr.remove(Integer.valueOf(val));
      
    } else if (c == 'C') {
      // Add a split vertical line
      if (A_gr.size() == 0) continue;
      
      int r_c = (int)random(A_gr.size());
      int val = A_gr.get(r_c);
      
      if (B_add.size() + D_add.size() == 0) {
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
        C_cont.add(gridSizeY);
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
        D_cont.add(gridSizeX);
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
  if (activePalette == null || activePalette.length == 0) {
    initCustomMondrianPalette();
  }
  for (int i = 0; i < x1.size(); i++) {
    rec_col.add((int)random(activePalette.length));
  }
}

// Draw a rectangle representing a line segment
void drawLineBox(float x1, float y1, float x2, float y2, float thickness) {
  float halfThick = thickness / 2.0f;
  
  rectMode(CORNERS);
  noStroke();
  fill(LINE_COLOR);
  
  if (abs(x1 - x2) < 0.1) {
    // Vertical box - force integer coordinates
    float centerX = round(x1);
    float top = round(y1);
    float bottom = round(y2);
    rect(centerX - halfThick, top, centerX + halfThick, bottom);
  } else if (abs(y1 - y2) < 0.1) {
    // Horizontal box - force integer coordinates
    float centerY = round(y1);
    float left = round(x1);
    float right = round(x2);
    rect(left, centerY - halfThick, right, centerY + halfThick);
  }
}

void drawArtwork() {
  // Draw colored patches using active palette (white NEVER appears here)
  for (int h = 0; h < xs1.size(); h++) {
    rectMode(CORNERS);
    noStroke();
    int paletteIndex = rec_col.get(h);
    if (activePalette != null && activePalette.length > 0) {
      fill(activePalette[paletteIndex % activePalette.length]);
    } else {
      fill(200);  // Fallback gray (should never happen)
    }
    
    float rx1 = round(getX(xs1.get(h)));
    float ry1 = round(getY(ys1.get(h)));
    float rx2 = round(getX(xs2.get(h)));
    float ry2 = round(getY(ys2.get(h)));
    rect(rx1, ry1, rx2, ry2);
  }
  
  // Draw grid lines as boxes
  fill(LINE_COLOR);
  noStroke();
  float halfThick = currentLineWeight / 2.0f;
  
  for (int kk = 0; kk < A_add.size(); kk++) {
    float x = round(getX(A_add.get(kk)));
    rect(x - halfThick, 0, x + halfThick, artHeight);
  }
  
  for (int kk = 0; kk < B_add.size(); kk++) {
    float y = round(getY(B_add.get(kk)));
    rect(0, y - halfThick, artWidth, y + halfThick);
  }
  
  for (int kk = 0; kk < C_add.size(); kk++) {
    float x = round(getX(C_add.get(kk)));
    float y1 = round(getY(C_st.get(kk)));
    float y2 = round(getY(C_ed.get(kk)));
    rect(x - halfThick, y1, x + halfThick, y2);
  }
  
  for (int kk = 0; kk < D_add.size(); kk++) {
    float x1 = round(getX(D_st.get(kk)));
    float x2 = round(getX(D_ed.get(kk)));
    float y = round(getY(D_add.get(kk)));
    rect(x1, y - halfThick, x2, y + halfThick);
  }
}

void startMakeManyMode() {
  if (makeManyMode) return;
  makeManyMode = true;
  makeManyGenerating = false;
  makeManyExportDelay = 0;
  makeManyExportQueued = false;
  println("MAKE MANY mode started - generating and saving variations");
}

void stopMakeManyMode() {
  makeManyMode = false;
  makeManyGenerating = false;
  makeManyExportQueued = false;
  println("MAKE MANY mode stopped.");
}

void draw() {
  background(CANVAS_WHITE);
  
  // MAKE MANY state machine
  if (makeManyMode) {
    if (makeManyExportDelay > 0) {
      makeManyExportDelay--;
    } else if (makeManyExportQueued) {
      // Export now (after delay frames have passed)
      if (exportPNG) pendingExportPNG = true;
      if (exportSVG) pendingExportSVG = true;
      makeManyExportQueued = false;
      makeManyExportDelay = 2;  // Brief pause between cycles
      println("--- MAKE MANY: Cycle complete ---");
    } else if (!makeManyGenerating) {
      // Start new generation
      makeManyGenerating = true;
      println("--- MAKE MANY: Generating variant ---");
    }
    
    if (makeManyGenerating) {
      calculateLineWeight();
      minLineDistance = currentLineWeight * 2;
      crv();
      patch();
      colour();
      makeManyGenerating = false;
      makeManyExportQueued = true;
      makeManyExportDelay = 3;  // Wait 3 frames for rendering to stabilize
      println("--- MAKE MANY: Exports queued (will export in " + makeManyExportDelay + " frames) ---");
    }
  }
  
  drawArtwork();
  
  if (millis() - cursorBlinkTime > 500) {
    cursorBlinkTime = millis();
    cursorVisible = !cursorVisible;
  }
  
  int uiY = artHeight;
  rectMode(CORNERS);
  noStroke();
  fill(50);
  rect(0, uiY, width, height);
  
  int buttonWidth = 70;
  int buttonHeight = 28;
  int buttonSpacing = 10;
  int startX = width - (buttonWidth * 4 + buttonSpacing * 3);
  int row1Y = uiY + 12;
  int row2Y = uiY + 50;
  
  // Row 1 buttons
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
  
  // Row 2 buttons
  int row2ButtonCount = 4;
  int row2TotalWidth = buttonWidth * row2ButtonCount + buttonSpacing * (row2ButtonCount - 1);
  int row2StartX = width - row2TotalWidth;
  
  fill(80);
  rect(row2StartX, row2Y, row2StartX + buttonWidth, row2Y + buttonHeight);
  rect(row2StartX + buttonWidth + buttonSpacing, row2Y, row2StartX + buttonWidth * 2 + buttonSpacing, row2Y + buttonHeight);
  rect(row2StartX + (buttonWidth + buttonSpacing) * 2, row2Y, row2StartX + buttonWidth * 3 + buttonSpacing * 2, row2Y + buttonHeight);
  rect(row2StartX + (buttonWidth + buttonSpacing) * 3, row2Y, row2StartX + buttonWidth * 4 + buttonSpacing * 3, row2Y + buttonHeight);
  
  fill(255);
  if (makeManyMode) {
    text("STOP", row2StartX + buttonWidth/2, row2Y + buttonHeight/2);
  } else {
    text("MAKE\nMANY", row2StartX + buttonWidth/2, row2Y + buttonHeight/2);
  }
  text("API\nCOLORS", row2StartX + buttonWidth + buttonSpacing + buttonWidth/2, row2Y + buttonHeight/2);
  text("EXPORT\nPNG", row2StartX + (buttonWidth + buttonSpacing) * 2 + buttonWidth/2, row2Y + buttonHeight/2);
  text("EXPORT\nSVG", row2StartX + (buttonWidth + buttonSpacing) * 3 + buttonWidth/2, row2Y + buttonHeight/2);
  
  // Input fields
  int inputX = 20;
  int inputY = uiY + 12;
  int ruleWidth = 140;
  int percentWidth = 50;
  int colorCountWidth = 50;
  int inputHeight = 28;
  int spacing = 8;
  
  // Rule input
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
  if (focusRule && cursorVisible) {
    float textW = textWidth(ruleInput);
    stroke(0);
    strokeWeight(1);
    line(inputX + 5 + textW, inputY + 5, inputX + 5 + textW, inputY + inputHeight - 5);
  }
  
  // Percentage input
  int percentX = inputX + ruleWidth + spacing;
  if (focusPercent) {
    stroke(100);
    strokeWeight(2);
  } else {
    noStroke();
  }
  fill(255);
  rect(percentX, inputY, percentX + percentWidth, inputY + inputHeight);
  fill(0);
  textAlign(CENTER, CENTER);
  text(percentText, percentX + percentWidth/2, inputY + inputHeight/2);
  if (focusPercent && cursorVisible) {
    float textW = textWidth(percentText);
    stroke(0);
    strokeWeight(1);
    line(percentX + percentWidth/2 + textW/2, inputY + 5,
         percentX + percentWidth/2 + textW/2, inputY + inputHeight - 5);
  }
  
  // Color count input
  int colorCountX = percentX + percentWidth + spacing;
  if (focusColorCount) {
    stroke(100);
    strokeWeight(2);
  } else {
    noStroke();
  }
  fill(255);
  rect(colorCountX, inputY, colorCountX + colorCountWidth, inputY + inputHeight);
  fill(0);
  textAlign(CENTER, CENTER);
  text(colorCountText, colorCountX + colorCountWidth/2, inputY + inputHeight/2);
  if (focusColorCount && cursorVisible) {
    float textW = textWidth(colorCountText);
    stroke(0);
    strokeWeight(1);
    line(colorCountX + colorCountWidth/2 + textW/2, inputY + 5,
         colorCountX + colorCountWidth/2 + textW/2, inputY + inputHeight - 5);
  }
  
  // Labels
  noStroke();
  fill(200);
  textSize(9);
  textAlign(LEFT, CENTER);
  text("Rule String (ENTER to apply)", inputX, inputY + inputHeight + 12);
  text("Fill %", percentX + percentWidth/2, inputY + inputHeight + 12);
  text("Colors\n(0=all)", colorCountX + colorCountWidth/2, inputY + inputHeight + 12);
  
  // Version and instructions
  String paletteInfo = " | Palette: " + paletteSource;
  if (paletteSource.equals("api") && lastAPIPaletteName.length() > 0) {
    paletteInfo += " - " + lastAPIPaletteName;
  }
  if (fullPalette != null) {
    paletteInfo += " (" + fullPalette.length + " colors";
    if (activePalette != null) {
      paletteInfo += ", using " + activePalette.length;
    }
    paletteInfo += ")";
  }
  
  // Add line weight info to status display
  String lineWeightInfo = " | Line weight: " + nf(currentLineWeight, 0, 0) + "px";
  
  fill(200);
  textAlign(LEFT, CENTER);
  textSize(9);
  text(scriptName + " v" + scriptVersion + " | " + artWidth + "x" + artHeight + " | Grid: " + gridSizeX + "x" + gridSizeY + paletteInfo + lineWeightInfo, 20, height - 25);
  
  textAlign(CENTER, CENTER);
  String modeInfo = "";
  if (makeManyMode) {
    modeInfo = " | MAKE MANY ACTIVE - Click STOP to halt generation";
  }
  text("S - Save PNG/SVG | Click API COLORS to fetch new palette | Line weight varies per run (proportional to canvas width)" + modeInfo, width/2, height - 12);
  
  if (pendingExportPNG) {
    exportToPNG();
    pendingExportPNG = false;
  }
  if (pendingExportSVG) {
    exportToSVG();
    pendingExportSVG = false;
  }
}

void mouseClicked() {
  int uiY = artHeight;
  int buttonWidth = 70;
  int buttonSpacing = 10;
  int row1StartX = width - (buttonWidth * 4 + buttonSpacing * 3);
  int row1Y = uiY + 12;
  int row2ButtonCount = 4;
  int row2TotalWidth = buttonWidth * row2ButtonCount + buttonSpacing * (row2ButtonCount - 1);
  int row2StartX = width - row2TotalWidth;
  int row2Y = uiY + 50;
  
  // Row 1 buttons
  if (mouseX > row1StartX && mouseX < row1StartX + buttonWidth && mouseY > row1Y && mouseY < row1Y + 28) {
    if (makeManyMode) stopMakeManyMode();
    rule = "AABBCCDDDDDD";
    ruleInput = rule;
    keep = 0.5;
    percentText = "50";
    initCustomMondrianPalette();
    focusRule = true;
    focusPercent = false;
    focusColorCount = false;
    crv();
    patch();
    colour();
    return;
  }
  
  if (mouseX > row1StartX + buttonWidth + buttonSpacing && mouseX < row1StartX + buttonWidth * 2 + buttonSpacing && 
      mouseY > row1Y && mouseY < row1Y + 28) {
    if (makeManyMode) stopMakeManyMode();
    crv();
    patch();
    return;
  }
  
  if (mouseX > row1StartX + (buttonWidth + buttonSpacing) * 2 && mouseX < row1StartX + buttonWidth * 3 + buttonSpacing * 2 && 
      mouseY > row1Y && mouseY < row1Y + 28) {
    patch();
    return;
  }
  
  if (mouseX > row1StartX + (buttonWidth + buttonSpacing) * 3 && mouseX < row1StartX + buttonWidth * 4 + buttonSpacing * 3 && 
      mouseY > row1Y && mouseY < row1Y + 28) {
    colour();
    return;
  }
  
  // Row 2 buttons
  if (mouseX > row2StartX && mouseX < row2StartX + buttonWidth && mouseY > row2Y && mouseY < row2Y + 28) {
    if (makeManyMode) {
      stopMakeManyMode();
    } else {
      startMakeManyMode();
    }
    return;
  }
  
  if (mouseX > row2StartX + buttonWidth + buttonSpacing && mouseX < row2StartX + buttonWidth * 2 + buttonSpacing && 
      mouseY > row2Y && mouseY < row2Y + 28) {
    fetchColorsFromAPI();
    return;
  }
  
  if (mouseX > row2StartX + (buttonWidth + buttonSpacing) * 2 && mouseX < row2StartX + buttonWidth * 3 + buttonSpacing * 2 && 
      mouseY > row2Y && mouseY < row2Y + 28) {
    exportToPNG();
    return;
  }
  
  if (mouseX > row2StartX + (buttonWidth + buttonSpacing) * 3 && mouseX < row2StartX + buttonWidth * 4 + buttonSpacing * 3 && 
      mouseY > row2Y && mouseY < row2Y + 28) {
    exportToSVG();
    return;
  }
  
  // Text field clicks
  int inputX = 20;
  int ruleWidth = 140;
  int percentWidth = 50;
  int colorCountWidth = 50;
  int spacing = 8;
  int inputY = uiY + 12;
  int inputHeight = 28;
  
  if (mouseX > inputX && mouseX < inputX + ruleWidth && mouseY > inputY && mouseY < inputY + inputHeight) {
    focusRule = true;
    focusPercent = false;
    focusColorCount = false;
    cursorBlinkTime = millis();
    cursorVisible = true;
    return;
  }
  
  int percentX = inputX + ruleWidth + spacing;
  if (mouseX > percentX && mouseX < percentX + percentWidth && mouseY > inputY && mouseY < inputY + inputHeight) {
    focusRule = false;
    focusPercent = true;
    focusColorCount = false;
    cursorBlinkTime = millis();
    cursorVisible = true;
    return;
  }
  
  int colorCountX = percentX + percentWidth + spacing;
  if (mouseX > colorCountX && mouseX < colorCountX + colorCountWidth && mouseY > inputY && mouseY < inputY + inputHeight) {
    focusRule = false;
    focusPercent = false;
    focusColorCount = true;
    cursorBlinkTime = millis();
    cursorVisible = true;
    return;
  }
  
  focusRule = false;
  focusPercent = false;
  focusColorCount = false;
}

void keyPressed() {
  if (focusPercent) {
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
        // keep and patch NOT updated here
      }
    } else if ((key == BACKSPACE || key == DELETE) && percentText.length() > 0) {
      percentText = percentText.substring(0, percentText.length() - 1);
      if (percentText.length() == 0) percentText = "0";
      // keep and patch NOT updated here
    } else if (key == ENTER) {
      int percent = int(percentText);
      if (percent >= 0 && percent <= 100) {
        keep = percent / 100.0;
        patch();
      }
    }
  } else if (focusColorCount) {
    if (key >= '0' && key <= '9') {
      String newText = colorCountText;
      if (newText.equals("0") && key != '0') {
        newText = "" + key;
      } else if (newText.length() < 3) {
        newText = newText + key;
      }
      colorCountText = newText;
    } else if ((key == BACKSPACE || key == DELETE) && colorCountText.length() > 0) {
      colorCountText = colorCountText.substring(0, colorCountText.length() - 1);
      if (colorCountText.length() == 0) colorCountText = "0";
    } else if (key == ENTER) {
      int limit = int(colorCountText);
      if (limit < 0) limit = 1;
      if (fullPalette != null && limit > fullPalette.length) limit = fullPalette.length;
      colorCountText = str(limit);
      updateActivePalette();
      colour();
    }
  } else if (focusRule) {
    if (key == ENTER) {
      String cleaned = "";
      for (int i = 0; i < ruleInput.length(); i++) {
        char c = Character.toUpperCase(ruleInput.charAt(i));
        if (c == 'A' || c == 'B' || c == 'C' || c == 'D') {
          cleaned += c;
        }
      }
      if (cleaned.length() > 0) {
        rule = cleaned;
        ruleInput = cleaned;
        crv();
        patch();
        colour();
      }
    } else if ((key == BACKSPACE || key == DELETE) && ruleInput.length() > 0) {
      ruleInput = ruleInput.substring(0, ruleInput.length() - 1);
    } else if (key != CODED && key != ENTER && key != BACKSPACE && key != DELETE) {
      if (ruleInput.length() < 32) {
        ruleInput = ruleInput + key;
      }
    }
  }
  
  if (key == 's' || key == 'S') {
    if (exportPNG) exportToPNG();
    if (exportSVG) exportToSVG();
  }
  
  cursorBlinkTime = millis();
  cursorVisible = true;
}

String getTimestamp() {
  Calendar cal = Calendar.getInstance();
  return String.format("%04d_%02d_%02d_%02d_%02d_%02d",
    cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH),
    cal.get(Calendar.HOUR_OF_DAY), cal.get(Calendar.MINUTE), cal.get(Calendar.SECOND));
}

void exportToPNG() {
  String timestamp = getTimestamp();
  String baseFilename = timestamp + "_" + scriptName + "_v" + scriptVersion;
  String filename = baseFilename + ".png";
  
  // Force rendering to complete before capture
  loadPixels();
  
  // Capture just the artwork area
  PImage artwork = get(0, 0, artWidth, artHeight);
  artwork.save(filename);
  
  // Save metadata as .txt with same base name
  String metadataFile = baseFilename + ".txt";
  PrintWriter output = createWriter(metadataFile);
  output.println("Created with " + scriptName + ".pde v" + scriptVersion);
  output.println("Dimensions: " + artWidth + "x" + artHeight);
  output.println("Grid: " + gridSizeX + "x" + gridSizeY);
  output.println("Grammar: " + rule);
  output.println("Fill percentage: " + percentText + "%");
  output.println("Line weight: " + currentLineWeight + "px (proportional to " + artWidth + "px width)");
  output.println("Line color: #" + hex(LINE_COLOR, 6));
  output.println("Canvas white: #" + hex(CANVAS_WHITE, 6));
  if (paletteSource.equals("api") && lastAPIPaletteURL.length() > 0) {
    output.println("Color palette source URL: " + lastAPIPaletteURL);
    if (lastAPIPaletteName.length() > 0) {
      output.println("Palette name: " + lastAPIPaletteName);
    }
  } else {
    output.println("Color palette source: " + paletteSource);
  }
  if (fullPalette != null) {
    output.println("Full palette size: " + fullPalette.length);
    output.println("Colors in full palette (excluding white):");
    for (int i = 0; i < fullPalette.length; i++) {
      output.println("#" + hex(fullPalette[i], 6));
    }
  }
  if (activePalette != null) {
    output.println("Active colors: " + activePalette.length);
  }
  output.flush();
  output.close();
  println("Saved PNG: " + filename);
}

void exportToSVG() {
  String timestamp = getTimestamp();
  String baseFilename = timestamp + "_" + scriptName + "_v" + scriptVersion;
  String filename = baseFilename + ".svg";
  
  PrintWriter output = createWriter(filename);
  
  // Write SVG header - NO SCALING
  output.println("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
  output.println("<svg xmlns=\"http://www.w3.org/2000/svg\"");
  output.println("     xmlns:xlink=\"http://www.w3.org/1999/xlink\"");
  output.println("     xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"");
  output.println("     xmlns:cc=\"http://creativecommons.org/ns#\"");
  output.println("     xmlns:dc=\"http://purl.org/dc/elements/1.1/\"");
  output.println("     width=\"" + artWidth + "\"");
  output.println("     height=\"" + artHeight + "\"");
  output.println("     viewBox=\"0 0 " + artWidth + " " + artHeight + "\">");
  
  // Add metadata using variables
  output.println("  <metadata>");
  output.println("    <rdf:RDF>");
  output.println("      <cc:Work rdf:about=\"\">");
  output.println("        <dc:description>");
  output.println("          Created with " + scriptName + ".pde v" + scriptVersion);
  output.println("          Dimensions: " + artWidth + "x" + artHeight);
  output.println("          Grid: " + gridSizeX + "x" + gridSizeY);
  output.println("          Grammar: " + rule);
  output.println("          Fill percentage: " + percentText + "%");
  output.println("          Line weight: " + currentLineWeight + "px");
  output.println("          Line color: #" + hex(LINE_COLOR, 6));
  output.println("          Canvas white: #" + hex(CANVAS_WHITE, 6));
  if (lastAPIPaletteURL.length() > 0) {
    output.println("          Color palette source URL: " + lastAPIPaletteURL);
    output.println("          Palette name: " + lastAPIPaletteName);
  } else {
    output.println("          Color palette source: " + paletteSource);
  }
  if (fullPalette != null) {
    output.println("          Full palette size: " + fullPalette.length);
    output.println("          Colors in full palette (excluding white):");
    for (int i = 0; i < fullPalette.length; i++) {
      output.println("          #" + hex(fullPalette[i], 6));
    }
  }
  if (activePalette != null) {
    output.println("          Active colors: " + activePalette.length);
  }
  output.println("        </dc:description>");
  output.println("      </cc:Work>");
  output.println("    </rdf:RDF>");
  output.println("  </metadata>");
  
  // Draw canvas background using variable
  output.println("  <rect x=\"0\" y=\"0\" width=\"" + artWidth + "\" height=\"" + artHeight + "\" fill=\"#" + hex(CANVAS_WHITE, 6) + "\"/>");
  
  // Draw all colored rectangles
  for (int h = 0; h < xs1.size(); h++) {
    float x = getX(xs1.get(h));
    float y = getY(ys1.get(h));
    float w = getX(xs2.get(h)) - x;
    float hgt = getY(ys2.get(h)) - y;
    
    int paletteIndex = rec_col.get(h);
    color c = activePalette[paletteIndex % activePalette.length];
    
    output.println("  <rect x=\"" + x + "\" y=\"" + y + "\" width=\"" + w + "\" height=\"" + hgt + 
                   "\" fill=\"#" + hex(c, 6) + "\" stroke=\"none\"/>");
  }
  
  // Draw all grid lines as RECTANGLES using color from variable
  output.println("  <g fill=\"#" + hex(LINE_COLOR, 6) + "\" stroke=\"none\">");
  
  float halfThick = currentLineWeight / 2.0f;
  
  // Full vertical lines (boxes)
  for (int kk = 0; kk < A_add.size(); kk++) {
    float x = getX(A_add.get(kk));
    output.println("    <rect x=\"" + (x - halfThick) + "\" y=\"0\" width=\"" + currentLineWeight + "\" height=\"" + artHeight + "\"/>");
  }
  
  // Full horizontal lines (boxes)
  for (int kk = 0; kk < B_add.size(); kk++) {
    float y = getY(B_add.get(kk));
    output.println("    <rect x=\"0\" y=\"" + (y - halfThick) + "\" width=\"" + artWidth + "\" height=\"" + currentLineWeight + "\"/>");
  }
  
  // Segmented vertical lines (boxes)
  for (int kk = 0; kk < C_add.size(); kk++) {
    float x = getX(C_add.get(kk));
    float y1 = getY(C_st.get(kk));
    float y2 = getY(C_ed.get(kk));
    output.println("    <rect x=\"" + (x - halfThick) + "\" y=\"" + y1 + "\" width=\"" + currentLineWeight + "\" height=\"" + (y2 - y1) + "\"/>");
  }
  
  // Segmented horizontal lines (boxes)
  for (int kk = 0; kk < D_add.size(); kk++) {
    float x1 = getX(D_st.get(kk));
    float x2 = getX(D_ed.get(kk));
    float y = getY(D_add.get(kk));
    output.println("    <rect x=\"" + x1 + "\" y=\"" + (y - halfThick) + "\" width=\"" + (x2 - x1) + "\" height=\"" + currentLineWeight + "\"/>");
  }
  
  output.println("  </g>");
  output.println("</svg>");
  output.flush();
  output.close();
  
  println("Saved SVG: " + filename);
}