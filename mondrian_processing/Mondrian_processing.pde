// DESCRIPTION
// Ported from p5js (OpenProcessing sketch 381152) by Queen Bee Art to desktop Processing: https://www.openprocessing.org/sketch/381152/
// From information metadata at source: (Piet) Mondrian compositions computed using shape grammar. 'A' adds vertical lines,
// 'B' adds horizontal lines, 'C' adds split vertical lines, and 'D' adds split horizontal lines. The text field controls the
// number of patches that are coloured. Play around with the buttons to get different compositions.
//
// ADDITIONAL FEATURES
// Features have been added since that base port:
// - update to dynamic grid system that keeps grid division (resultant cells) roughly (or exactly) square for any canvas aspect ratio
// - implement color palette retrieval, via button press, from a palette collection API: https://earthbound.io/data/random_ebPalette/
//   - with a text field for how many colors from the palette so use (subset, 0 = all colors, a number higher than available will
//     auto-clamp to the total available)
// - PNG and SVG export with full embedded (SVG) or txt sidecar (PNG) metadata of all creation paramaters (grammar, palette name etc.)
// - line collision avoidance to prevent overlapping lines (lines may still cluster closely)
// - redesign parameter UI with better contrast and for new features
// - custom Mondrian palette with colors I reckon he used in his neoplastic paintings
// - dynamic line weight scaling based on canvas width (proportional to 1022px reference)
// - random line weight per sketch run between scaled minimum and maximum
// - option to randomize line construction grammar
// - RAPID GEN mode: infinite, rapid generation of variants (frame-based state machine, no background threading)
//   - auto-save of variants to PNG and / or SVG controlle by global booleans that can be hacked (exportPNG, exportSVG)
// - RAPID GEN sub-modes: control random lines, patches, colours, API retrieval from a collection, and grid grammar per variant
//
// ===============================================================
// REQUIRED: controlP5 LIBRARY; see:
// ===============================================================
// DEPENDENCIES
// Processing (possibly only v4 or higher), with the controlP5 library installed. From the Processing IDE:
// Tools menu > Manage Tools.. > Libraries tab > type controlp5 in the search field > click the library in the search
// result > click install, wait for download and install to complete. Possibly restart the Processing IDE thereafter.
//
// USAGE
// Double click to open the sketch in the Processing IDE, or otherwise open it in anything else that can run Processing.
// Run the sketch. Click on the GRAMMAR STRING text box to edit line construction grammar (any combination of the letters A, B, C, and D,
// repetition allowed). Edit other parameters in text areas to your wishes also.
// Press ENTER in any field where you have edited the values to generate a new composition based on that grammar.
// Press S to save PNG and/or SVG (see booleans at top). Click PNG/SVG buttons to export (buttons override booleans).
// Click "RAPID GEN" to enter generation mode. The text "RAPID GEN" on the button will change to "STOP." Press "STOP" to exit
// RAPID GEN mode. In RAPID GEN mode, the sketch generates and saves endless variations with the current grammar etc. settings.
// Use the RAPID LINES, RAPID PATCH, etc. buttons to control which elements change per generation. RAPID API retrieves
// a new palette from an API and uses it with new variants.
//
// LICENSE
// Creative Commons Share-Alike Attribution, by Richard Alexander Hall, May 2026, ported from another developer,
// as noted under DESCRIPTION.
//
//
// CODE
// TO DO
// - make a global basefile name with random string append before script version, which is set ONCE before PNG and / or SVG export; to:
//  - avoid clobbers of files exported in the same microsecond (it could happen? -- as the file name only captures seconds)
//  - ensure PNG and SVGs are unambiguosly paired via basename in the case of some second overlap during export
// - print errors to UI errorlabel in these cases:
//  - API fetch failures
//  - Invalid grammar entered (though the filter already handles this)
//  - Attempting to start RAPID GEN with no sub-modes active
// - museum mode: only display artwork area, fullscreen, no UI controls, with RAPID API (new palettes) etc. active
//   for every new render, then doing the render when ready.
// - in museum mode, every 7th iteration use default Mondrian palette as throwback?
// - CLI mode accepting a JSON config and dynamically patching settings
//   - to start any mode thereby also?
//   - to override globals like dimensions
//   - to override palette, specifying the config as "source" in written metadata
// - rare line behind other lines which is a color from the palette and not black?? re: https://www.wikiart.org/en/piet-mondrian/composition-with-red-yellow-and-blue-1942
//  - how? simply delete or never render the black lines around them? I think they may be fills, not lines. also at: https://www.wikiart.org/en/piet-mondrian/composition-no-10-1942
// BACKLOG; apparently not a critical / recurrent issue: fix this crash:
// I ran it in rapidgen mode and encountered a crash:
// --- RAPID GEN: Generating variant ---
// GrammarGenerator: Selected grammar #254: AAAABBBBCCCCDDD
// RAPID GRAMMAR: Generated: AAAABBBBCCCCDDD
// RAPID GRAMMAR: Applying: AAAABBBBCCCCDDD
// DEBUG: crv() called with grammar = AAAABBBBCCCCDDD
// --- RAPID GEN: Exports queued (will export in 3 frames) ---
// IndexOutOfBoundsException: Index 15 out of bounds for length 15
// IndexOutOfBoundsException: Index 15 out of bounds for length 15
//
// I hope it's easy to figure out the cause. I note that the generated grammar has 15
// characters and the error is out of bounds for length 15. I've added a crash handling
// try / catch block for a crash scenario that may catch that in rapid gen mode, and ran
// it in rapid gen mode for hours and nothing ever crashed, even reducing the grammar to
// 4 characters for a long stretch either. It's ephemeral and probably rare enough that
// a museum could just reboot the art on any extremely rare occassion it happens. Or for
// all I know it was a cosmic ray flipping a bit.

String scriptVersion = "2.12.7";
String scriptName = "Mondrian_Processing";
String paletteSource = "custom_mondrian";
String lastAPIPaletteName = "";
String lastAPIPaletteURL = "";
String paletteString = "";
int errorLabelHideTime = 0;

import processing.svg.*;
import java.util.Collections;
import java.util.Calendar;

// Export settings
boolean exportPNG = true;
boolean exportSVG = true;

// if the adaptElementsToCanvasScale is true, no matter what size you make the canvas, the Mondrian-esque
// lines (and resulting related area fills) will scale up or down so that the proportions or
// wight of lines are typical of his paintings at any scale; for a larger or smaller canvas
// it will effectively be a blown up or miniaturized Mondrian painting. If the following is false,
// lines will remain at "life size" no matter how large or small the canvas, and for example
// with a much larger canvas it will be filled with more work detail if the lines grammar allows.
// Whereas a smaller canvas will be more filled with "real" scale lines. You can think of
// adaptElementsToCanvasScale = true as meaning "Extend canvas mode;" a larger canvas will keep "real life"
// line weights but distribute lines over a wider area, and make more of them if you enter
// a more complex line grammar. Hard-coded default true:
boolean adaptElementsToCanvasScale = true;
// furtherScaleFactor is an additional percent calculation after the hard-coded scale calculation
// to make the line weight heaver or lighter after that. To make lines heavier, set furtherScaleFactor
// higher than 1, e.g. 1.2 will makes lines 120% of default scale; it is a percent as decimal
// multiplier. Or set it to a decimal lower than 1 to make a lighter than default line weight.
// The hard-coded default 1.
// NOTE: in either and all cases, an absolute minimum line weight is enforced that overrides anything
// deemed too light; see the ABSOLUTE_MIN_WEIGHT variable declaration:
float furtherScaleFactor = 1;

// Layout settings
// An assumed real life "average" art width and height from surveying many Mondrian works is; 66.95cm x 62.97cm;
// or 26.36in x	24.79x, which @ 72dpi is 1898px x	1785px; aspect w/h = 1.06 -- pretty much, he
// liked squares, but there was variation -- AND from another survey (different image set) I got 
// average 839 x 886 px; this hard-coded may proportionally scale down from that (aspect w/h = 0.9469) :
int artWidth = 840;
int artHeight = 886;
int uiPanelHeight = 120;  // Height reserved for UI controls below artwork
int gridSizeReference = 28;  // Reference grid size for the shorter dimension; orig. 32 and hard-coded may differ

// - line weight notes:
//  - piet-mondriaan-1930-mondrian-composition-ii-in-red-blue-and-yellow.jpg resized to real life dimension (72dpi @ cm size match) ; ref width 2438; line match at weight 68
//  - Composition_A_by_Piet_Mondrian_Galleria_Nazionale_d'Arte_Moderna_e_Contemporanea.jpg resized to real life dimension (72dpi @ cm size match) ; ref width 2594; line match at weight 22
// FROM THAT ^ : Line weight configuration - PROPORTIONAL SCALING
// Reference dimensions: max canvas width = 2438px
// - At 2438px width:
//  - minimum line weight matching Mondrian neoplastic paintings real-world size is: 22px
//  - maximum line weight matching Mondrian neoplastic paintings real-world size is: 68px
final float REFERENCE_WIDTH = 2438;
final float REFERENCE_MIN_WEIGHT = 22;
final float REFERENCE_MAX_WEIGHT = 68;

float currentLineWeight;  // Will be set randomly on each run
float minLineDistance;    // Minimum distance between lines (currentLineWeight * 2)

// Calculated dimensions
int canvasWidth;
int canvasHeight;
int gridSizeX;           // Number of horizontal divisions
int gridSizeY;           // Number of vertical divisions

String grammar = "AAAABBBBCCCCDDD";
// see comments at grammarGenerator initialization and in GrammarGenerator.pde:
int maxLetterRepetitionForGrammarGenerator = 4;
float percentToPatch = 0.33;

// RAPID GEN mode - frame-based state machine (no background thread)
boolean rapidGenMode = false;
boolean rapidGenGenerating = false;
int rapidGenExportDelay = 0;
boolean rapidGenExportQueued = false;

// RAPID GEN sub-modes
boolean rapidLines = true;    // Shuffle lines with every new variant (default ON)
boolean rapidPatch = true;    // Shuffle patches with every new variant (default ON)
boolean rapidColour = true;   // Shuffle colours with every new variant (default ON)
boolean rapidAPI = false;     // Fetch new palette for every variant (default OFF)
boolean rapidGrammar = false;  // Randomize grammar (types and combinations of lines) for every variant (default OFF)
boolean pendingAPICall = false;
int apiCallStartTime = 0;
boolean newPaletteReady = false;
final int API_TIMEOUT_MS = 12000;  // 12 seconds timeout

// Export flags for frame-synchronized capture
boolean pendingExportPNG = false;
boolean pendingExportSVG = false;

String statusMessage = "";
int statusMessageTimer = 0;

// We can do this because of the tab or import of the code file GrammarGenerator.pde, in the same directory:
GrammarGenerator grammarGenerator;

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
  
  // Initialize grammar generator; can pass any integer but counts will explode at higher numbers;
  // Generates grammars like A...B...C...D... with configurable max per letter; passing it 4 will
  // allow up to 4 repetition of A like AAAA, or B like BBBB, etc, or C or D:
  grammarGenerator = new GrammarGenerator(maxLetterRepetitionForGrammarGenerator);
  println("Grammar generator ready with " + grammarGenerator.getTotalCount() + " grammars");

  calculateLineWeight();
  
  background(CANVAS_WHITE);
  
  calculateGrid();
  minLineDistance = currentLineWeight * 2; // Minimum pixels between line centers
  
  // Initialize ControlP5 UI FIRST so text fields exist for palette functions
  setupUI();
  
  // Initialize with custom Mondrian palette (now safe - colorCountField exists)
  initCustomMondrianPalette();
  
  // Update the color count field with actual palette size
  colorCountField.setText(str(fullPalette.length));

  // Enable grammar rapid gen mode by default
  rapidGrammar = true;
  // Update the toggle UI to reflect the enabled state
  if (rapidGrammarToggle != null) {
    rapidGrammarToggle.setValue(1);
    rapidGrammarToggle.setColorCaptionLabel(color(64));
  }  

  crv();
  patch();
  colour();

  // Force nearest-neighbor sampling, which disables anti-aliasing
  // for all geometry, which would cause inconsistent line (black box)
  // width appearance:
  ((PGraphicsOpenGL)g).textureSampling(2);
  
  println("Line weight: " + currentLineWeight + "px (scaled from " + artWidth + "px width)");
  println("Min line distance: " + minLineDistance + "px");
  println("Using custom Mondrian palette with " + fullPalette.length + " colors (white reserved for canvas)");
}

// The setupUI() function could be here but it is in UI_Controls.pde in the same folder, auto-imported by Processing.

void grammarField(String value) {
  // Filter to only A,B,C,D
  String cleaned = "";
  for (int i = 0; i < value.length(); i++) {
    char c = Character.toUpperCase(value.charAt(i));
    if (c == 'A' || c == 'B' || c == 'C' || c == 'D') {
      cleaned += c;
    }
  }
  if (cleaned.length() > 0) {
    grammar = cleaned;
    grammarField.setText(grammar);
    if (!rapidGenMode) {
      crv();
      patch();
      colour();
    }
  }
}

void percentField(String value) {
  int percent = int(value);
  if (percent >= 0 && percent <= 100) {
    percentToPatch = percent / 100.0;
    if (!rapidGenMode) {
      patch();
    }
  }
}

void colorCountField(String value) {
  int limit = int(value);
  if (limit < 0) limit = 0;
  if (fullPalette != null && limit > fullPalette.length) limit = fullPalette.length;
  colorCountField.setText(str(limit));
  updateActivePalette();
  if (!rapidGenMode) {
    colour();
  }
}

// Reset status message
void resetStatusMessage() {
  statusMessage = "";
  statusMessageTimer = 0;
}

// Toggle event handlers with text color inversion
void rapidLinesToggle(boolean value) {
  resetStatusMessage();
  rapidLines = value;
  if (value) {
    rapidLinesToggle.setColorCaptionLabel(color(64));   // Dark text when ON (white button)
  } else {
    rapidLinesToggle.setColorCaptionLabel(color(255));  // White text when OFF (dark button)
  }
  println("Rapid Lines: " + (rapidLines ? "ON" : "OFF"));
}

void rapidPatchToggle(boolean value) {
  resetStatusMessage();
  rapidPatch = value;
  if (value) {
    rapidPatchToggle.setColorCaptionLabel(color(64));
  } else {
    rapidPatchToggle.setColorCaptionLabel(color(255));
  }
  println("Rapid Patch: " + (rapidPatch ? "ON" : "OFF"));
}

void rapidColourToggle(boolean value) {
  resetStatusMessage();
  rapidColour = value;
  if (value) {
    rapidColourToggle.setColorCaptionLabel(color(64));
  } else {
    rapidColourToggle.setColorCaptionLabel(color(255));
  }
  println("Rapid Colour: " + (rapidColour ? "ON" : "OFF"));
}

void resetAll() {
  resetStatusMessage();
  if (rapidGenMode) stopRapidGenMode();
  grammar = "AABBCCDDDDDD";
  grammarField.setText(grammar);
  percentToPatch = 0.33;
  percentField.setText("33");
  initCustomMondrianPalette();
  colorCountField.setText(str(fullPalette.length));
  crv();
  patch();
  colour();
}

void rapidAPIToggle(boolean value) {
  resetStatusMessage();
  rapidAPI = value;
  if (value) {
    rapidAPIToggle.setColorCaptionLabel(color(64));
  } else {
    rapidAPIToggle.setColorCaptionLabel(color(255));
  }
  println("Rapid API: " + (rapidAPI ? "ON" : "OFF"));
}

void rapidGrammarToggle(boolean value) {
  resetStatusMessage();
  rapidGrammar = value;
  if (value) {
    rapidGrammarToggle.setColorCaptionLabel(color(64));
  } else {
    rapidGrammarToggle.setColorCaptionLabel(color(255));
  }
  println("Rapid Grammar: " + (rapidGrammar ? "ON" : "OFF"));
}

// Button event handlers
void shuffleLines() {
  resetStatusMessage();
  if (!rapidGenMode) {
    crv();
    patch();
  } else {
    println("Can't shuffle while RAPID GEN active");
  }
}

void shufflePatch() {
  resetStatusMessage();
  if (!rapidGenMode) {
    patch();
  } else {
    println("Can't shuffle while RAPID GEN active");
  }
}

void shuffleColour() {
  resetStatusMessage();
  if (!rapidGenMode) {
    colour();
  } else {
    println("Can't shuffle while RAPID GEN active");
  }
}

void shuffleGrammar() {
  resetStatusMessage();
  if (!rapidGenMode) {
    // Get a random grammar from the generator
    String newGrammar = grammarGenerator.getRandomGrammar();
    println("SHUFFLE GRAMMAR: Generated: " + newGrammar);
    
    if (!newGrammar.equals(grammar)) {
      grammar = newGrammar;
      println("SHUFFLE GRAMMAR: Applying: " + grammar);
      
      // Update the text field display
      grammarField.setText(grammar);
      
      // Regenerate the composition with the new grammar
      crv();
      patch();
      colour();
      
      // No status message - grammar appears in main status line
    } else {
      println("SHUFFLE GRAMMAR: Random gave same grammar, trying again...");
      // Try one more time with a different grammar
      newGrammar = grammarGenerator.getRandomGrammar();
      if (!newGrammar.equals(grammar)) {
        grammar = newGrammar;
        println("SHUFFLE GRAMMAR: Applying on second try: " + grammar);
        grammarField.setText(grammar);
        crv();
        patch();
        colour();
      } else {
        println("SHUFFLE GRAMMAR: Same grammar twice - keeping current");
      }
    }
  } else {
    println("Can't shuffle grammar while RAPID GEN active");
    errorLabel.setText("ERROR: Stop RAPID GEN first");
    errorLabel.setVisible(true);
    errorLabelHideTime = millis() + 6000;
  }
}

void rapidGenToggle() {
  resetStatusMessage();
  if (rapidGenMode) {
    stopRapidGenMode();
    cp5.get(Button.class, "rapidGenToggle").setLabel("RAPID GEN");
  } else {
    boolean started = startRapidGenMode();
    if (started) {
      cp5.get(Button.class, "rapidGenToggle").setLabel("STOP");
    }
    // If start failed, button label stays "RAPID GEN"
  }
}

void apiColors() {
  resetStatusMessage();
  fetchColorsFromAPI();
}

void exportPNGButton() {
  resetStatusMessage();
  exportToPNG();
}

void exportSVGButton() {
  resetStatusMessage();
  exportToSVG();
}

float scaleFactor = 1;
void calculateLineWeight() {
  // Calculate proportional scaling additional factor; SEE COMMENTS AT adaptElementsToCanvasScale declaraction:
  if (adaptElementsToCanvasScale == true) {
    scaleFactor = artWidth / REFERENCE_WIDTH;
  }
  // A wasted calculation if further ScaleFactor = 1; but so would a conditional check sorta be:
  scaleFactor *= furtherScaleFactor;
  
  // Calculate min and max for this canvas size
  float scaledMin = REFERENCE_MIN_WEIGHT * scaleFactor;
  float scaledMax = REFERENCE_MAX_WEIGHT * scaleFactor;
  
  // Apply lower bound clamping to prevent lines from being too thin
  // Minimum practical line weight may be 3px
  final float ABSOLUTE_MIN_WEIGHT = 4;
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
  updateActivePalette();
  println("Using custom Mondrian palette with " + fullPalette.length + " colors");
}

void updateActivePalette() {
  // Get limit from the text field, not from activePalette (which may be null)
  int limit = int(colorCountField.getText());
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
        
        // Update the color count field to show the full palette size
        colorCountField.setText(str(fullPalette.length));
        // and use the palette (including that fields' potentially changed number from the palette color count)
        updateActivePalette();
        // Signal that new palette is ready
        newPaletteReady = true;
        
        println("Successfully loaded " + fullPalette.length + " colors from API");
        println("Palette name: " + lastAPIPaletteName);
        println("Palette URL: " + lastAPIPaletteURL);
      } catch (Exception e) {
        println("API fetch failed: " + e.getMessage());
        errorLabel.setText("ERROR: API fetch failed");
        errorLabel.setVisible(true);
        errorLabelHideTime = millis() + 6000;
        // On failure, signal that call is done but no new palette
        newPaletteReady = true;
      }
    }
  });
  t.start();
}

// String randomString(int length) {
//   String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
//   String result = "";
//   for (int i = 0; i < length; i++) {
//     int index = (int)random(chars.length());
//     result += chars.charAt(index);
//   }
//   return result;
// }

void crv() {
  // println("DEBUG: crv() called with grammar = " + grammar);

  // Re-randomize line weight for this new composition
  calculateLineWeight();
  if (paletteSource.equals("api") && lastAPIPaletteName.length() > 0) {
    paletteString = " | Palette: " + lastAPIPaletteName;
  } else if (paletteSource.equals("api") && pendingAPICall) {
    paletteString = " | Fetching palette...";
  } else {
    paletteString = " | Palette: Built-in Mondrian";
  }
  // hacky: make the remainder of the status label a blank string, to clear otherwise not clearing text as the function draws "nothing" to text background:
  int maxLength = 200;
  String labelString = scriptName + " v" + scriptVersion + " | Line: " + nf(currentLineWeight, 0, 0) + "px" + (rapidGenMode ? " | RAPID GEN ACTIVE" : "") + paletteString;
  labelString = String.format("%-" + maxLength + "s", labelString);
  statusLabel.setText(labelString);
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
  
  for (int charIdx = 0; charIdx < grammar.length(); charIdx++) {
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
    
    char c = grammar.charAt(charIdx);
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
  
  int q = (int)(x1.size() * percentToPatch);
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

boolean startRapidGenMode() {
  if (rapidGenMode) return false;
  
  // Check if at least one sub-mode is active
  if (!rapidLines && !rapidPatch && !rapidColour && !rapidAPI && !rapidGrammar) {
    println("ERROR: Cannot start RAPID GEN mode - no sub-modes are active!");
    println("  Enable at least one of: Rapid Lines, Rapid Patch, Rapid Colour, or Rapid API");
    println("  Rapid Grammar: " + (rapidGrammar ? "ON" : "OFF"));
    statusMessage = "ERROR: Enable at least one RAPID mode (Lines, Patch, Colour, or API)";
    errorLabel.setText(statusMessage);
    errorLabel.setVisible(true);
    errorLabelHideTime = millis() + 6000;
    return false;
  }
  
  rapidGenMode = true;
  rapidGenGenerating = false;
  rapidGenExportDelay = 0;
  rapidGenExportQueued = false;
  println("RAPID GEN mode started - generating and saving variations");
  println("  Rapid Lines: " + (rapidLines ? "ON" : "OFF"));
  println("  Rapid Patch: " + (rapidPatch ? "ON" : "OFF"));
  println("  Rapid Colour: " + (rapidColour ? "ON" : "OFF"));
  println("  Rapid API: " + (rapidAPI ? "ON" : "OFF"));
  println("  Rapid Grammar: " + (rapidGrammar ? "ON" : "OFF"));
  return true;
}

void stopRapidGenMode() {
  rapidGenMode = false;
  rapidGenGenerating = false;
  rapidGenExportQueued = false;
  // Clear any pending API calls
  pendingAPICall = false;
  newPaletteReady = false;
  println("RAPID GEN mode stopped.");
}

void generateRapidVariant() {
  boolean linesChanged = false;
  
  // Randomize grammar if rapidGrammar is on
  if (rapidGrammar) {
    String newGrammar = grammarGenerator.getRandomGrammar();
    println("RAPID GRAMMAR: Generated: " + newGrammar);  // Print to stdout
    
    if (!newGrammar.equals(grammar)) {
      grammar = newGrammar;
      println("RAPID GRAMMAR: Applying: " + grammar);  // Print to stdout
      
      // Update the text field display
      grammarField.setText(grammar);
      // Force the text field to redraw
      grammarField.setColorBackground(color(64));
      
      linesChanged = true;
    }
  }
  
  if (rapidLines || linesChanged) {
    crv();  // Generates new line configuration and random line weight
    linesChanged = true;
  }
  
  // If lines changed, we MUST also run patch() to update patch geometry,
  // regardless of rapidPatch setting. Otherwise patches from old grid
  // will be drawn on new grid lines.
  if (rapidPatch || linesChanged) {
    patch();  // Shuffle which patches are colored
  }
  
  if (rapidColour) {
    colour();  // Shuffle colors assignment
  }
  
  // API handling is separate and happens in draw()
}

int crashCount = 0;
void draw() {
  // Draw background for the UI panel area (below the artwork)
  fill(color(uiBackgroundColor));
  noStroke();
  rect(0, artHeight, width, uiPanelHeight);

  // Now draw the white artwork background
  fill(CANVAS_WHITE);
  rect(0, 0, artWidth, artHeight);
  
  // RAPID GEN state machine
  if (rapidGenMode) {
    // Check for pending API response if rapidAPI is on
    if (rapidAPI && pendingAPICall) {
      // Check for timeout
      if (millis() - apiCallStartTime > API_TIMEOUT_MS) {
        println("RAPID API: Timeout after 12 seconds - continuing with existing palette");
        pendingAPICall = false;
        newPaletteReady = false;
      } else if (newPaletteReady) {
        // API call completed successfully (or failed but newPaletteReady flagged)
        if (fullPalette != null && fullPalette.length > 0) {
          updateActivePalette();
          colour();  // Recolor with new palette
          println("RAPID API: New palette applied (" + fullPalette.length + " colors)");
        }
        pendingAPICall = false;
        newPaletteReady = false;
      } else {
        // Still waiting for API - pause generation cycle
        // Don't proceed with generation until API responds
        // We'll just redraw current artwork
        drawArtwork();
        // Don't return - let exports still happen
      }
    }
    
    if (rapidGenExportDelay > 0) {
      rapidGenExportDelay--;
    } else if (rapidGenExportQueued) {
      // Export now (after delay frames have passed)
      if (exportPNG) pendingExportPNG = true;
      if (exportSVG) pendingExportSVG = true;
      rapidGenExportQueued = false;
      rapidGenExportDelay = 2;  // Brief pause between cycles
      println("--- RAPID GEN: Cycle complete ---");
    } else if (!rapidGenGenerating) {
      // Start new generation
      rapidGenGenerating = true;
      println("--- RAPID GEN: Generating variant ---");
      
      try {
        generateRapidVariant();
      } catch (IndexOutOfBoundsException e) {
        crashCount++;
        println("!!! CRASH #" + crashCount + " !!!");
        println("  Failed grammar: " + grammar);
        println("  Grammar length: " + grammar.length());
        println("  Exception: " + e.getMessage());
        rapidGenGenerating = false;
        rapidGenExportQueued = false;
        rapidGenExportDelay = 0;
        return;
      }
      
      // Trigger API call if rapidAPI is on and no pending call
      if (rapidAPI && !pendingAPICall) {
        pendingAPICall = true;
        newPaletteReady = false;
        apiCallStartTime = millis();
        fetchColorsFromAPI();
        println("RAPID API: Fetching new palette...");
        // Note: We already generated the variant, now wait for API to update colors for NEXT cycle
      }
      
      rapidGenGenerating = false;
      rapidGenExportQueued = true;
      rapidGenExportDelay = 3;  // Wait 3 frames for rendering to stabilize
      println("--- RAPID GEN: Exports queued (will export in " + rapidGenExportDelay + " frames) ---");
    }
  }
  
  drawArtwork();
  
  if (pendingExportPNG) {
    exportToPNG();
    pendingExportPNG = false;
  }
  if (pendingExportSVG) {
    exportToSVG();
    pendingExportSVG = false;
  }

  if (errorLabelHideTime > 0 && millis() > errorLabelHideTime) {
    String clearString = String.format("%-80s", "");
    errorLabel.setText(clearString);
    errorLabelHideTime = 0;
  }
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
  output.println("Grammar: " + grammar);
  output.println("Fill percentage: " + int(percentToPatch * 100) + "%");
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

  output.println("Active colors: " + activePalette.length);

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
  output.println("          Grammar: " + grammar);
  output.println("          Fill percentage: " + int(percentToPatch * 100) + "%");
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

// keypress overrides exportPNG and exportSVG booleans:
void keyPressed() {
  if (key == 's' || key == 'S') {
    exportToPNG();
    exportToSVG();
    println("Manual export triggered via keyboard; PNG and SVG of current variant saved.");
  }
}
