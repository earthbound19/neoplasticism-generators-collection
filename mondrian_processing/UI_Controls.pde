// DESCRIPTION
// UI control declarations etc. for Mondrian_Processing.pde

// CODE
// UI_Controls.pde
// Centralized UI declaration and initialization for Mondrian_Processing

// To resolve an import error related to the next line: from the Processing IDE:
// Tools menu > Manage Tools.. > Libraries tab > type controlp5 in the search
// field > click the library in the search result > click install, wait for
// download and install to complete. Possibly restart the Processing IDE thereafter.
import controlP5.*;

// UI appearance constants
color uiBackgroundColor = color(#050506);    // Mondrian black
color uiTextColor = color(#f6f6f6);    // Mondrian white
color uiErrorColor = color(#f22a27);      // Mondrian red

// ControlP5 components (declared globally)
ControlP5 cp5;
Textfield grammarField;
Textfield percentField;
Textfield colorCountField;
Toggle rapidLinesToggle;
Toggle rapidPatchToggle;
Toggle rapidColourToggle;
Toggle rapidAPIToggle;
Toggle rapidGrammarToggle;
Textlabel statusLabel;
Textlabel errorLabel;

// Reference to main sketch variables (passed or accessed via outer scope)
// These will be accessible because they're in the main tab

void setupUI() {
   cp5 = new ControlP5(this);

   cp5.setColorBackground(color(30));
   cp5.setColorForeground(color(100));
   cp5.setColorActive(color(120));

  int uiY = artHeight;
  int fieldWidth = 120;
  int smallFieldWidth = 60;
  int buttonWidth = 70;
  int spacing = 10;
  int rowHeight = 25;
  int labelX = 20;
  int fieldY = uiY + 10;
  
  grammarField = cp5.addTextfield("grammarField")
     .setPosition(labelX, fieldY)
     .setSize(fieldWidth, rowHeight)
     .setText(grammar)
     .setLabel("GRAMMAR STRING (only letters A, B, C or D")
     .setAutoClear(false)
     .setColorCaptionLabel(color(255));

   cp5.addButton("shuffleGrammar")
      .setPosition(labelX + fieldWidth + spacing, fieldY)
      .setSize(buttonWidth, rowHeight)
      .setLabel("SHUFFLE GRAMMAR")
      .setColorCaptionLabel(color(255));

  percentField = cp5.addTextfield("percentField")
     .setPosition(labelX + spacing + buttonWidth + spacing + fieldWidth + spacing, fieldY)
     .setSize(smallFieldWidth, rowHeight)
     .setText(str(int(percentToPatch * 100)))
     .setLabel("FILL %")
     .setAutoClear(false)
     .setColorCaptionLabel(color(255));

  colorCountField = cp5.addTextfield("colorCountField")
     .setPosition(labelX + spacing + buttonWidth + spacing + fieldWidth + spacing + smallFieldWidth + spacing, fieldY)
     .setSize(smallFieldWidth, rowHeight)
     .setText("7")
     .setLabel("# COLORS USED (0=all)")
     .setAutoClear(false)
     .setColorCaptionLabel(color(255));

  int toggleY = fieldY + rowHeight + 15;
  int toggleWidth = 70;
  
  color offColor = color(64);
  color onColor = color(255);
  color hoverColor = color(100);
  
  rapidLinesToggle = cp5.addToggle("rapidLinesToggle")
     .setPosition(labelX, toggleY)
     .setSize(toggleWidth, rowHeight)
     .setBroadcast(false)
     .setValue(rapidLines ? 1 : 0)
     .setBroadcast(true)
     .setLabel("RAPID LINES")
     .setColorBackground(offColor)
     .setColorActive(onColor)
     .setColorForeground(hoverColor)
     .setColorCaptionLabel(rapidLines ? offColor : onColor);
  rapidLinesToggle.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
  
  rapidPatchToggle = cp5.addToggle("rapidPatchToggle")
     .setPosition(labelX + (toggleWidth + spacing), toggleY)
     .setSize(toggleWidth, rowHeight)
     .setBroadcast(false)
     .setValue(rapidPatch ? 1 : 0)
     .setBroadcast(true)
     .setLabel("RAPID PATCH")
     .setColorBackground(offColor)
     .setColorActive(onColor)
     .setColorForeground(hoverColor)
     .setColorCaptionLabel(rapidPatch ? offColor : onColor);
  rapidPatchToggle.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
  
  rapidColourToggle = cp5.addToggle("rapidColourToggle")
     .setPosition(labelX + (toggleWidth + spacing) * 2, toggleY)
     .setSize(toggleWidth, rowHeight)
     .setBroadcast(false)
     .setValue(rapidColour ? 1 : 0)
     .setBroadcast(true)
     .setLabel("RAPID COLOUR")
     .setColorBackground(offColor)
     .setColorActive(onColor)
     .setColorForeground(hoverColor)
     .setColorCaptionLabel(rapidColour ? offColor : onColor);
  rapidColourToggle.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
  
  rapidAPIToggle = cp5.addToggle("rapidAPIToggle")
     .setPosition(labelX + (toggleWidth + spacing) * 3, toggleY)
     .setSize(toggleWidth, rowHeight)
     .setBroadcast(false)
     .setValue(rapidAPI ? 1 : 0)
     .setBroadcast(true)
     .setLabel("RAPID API")
     .setColorBackground(offColor)
     .setColorActive(onColor)
     .setColorForeground(hoverColor)
     .setColorCaptionLabel(rapidAPI ? offColor : onColor);
  rapidAPIToggle.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
  
  rapidGrammarToggle = cp5.addToggle("rapidGrammarToggle")
     .setPosition(labelX + (toggleWidth + spacing) * 4, toggleY)
     .setSize(toggleWidth, rowHeight)
     .setBroadcast(false)
     .setValue(rapidGrammar ? 1 : 0)
     .setBroadcast(true)
     .setLabel("RAPID GRAMMAR")
     .setColorBackground(offColor)
     .setColorActive(onColor)
     .setColorForeground(hoverColor)
     .setColorCaptionLabel(rapidGrammar ? offColor : onColor);
  rapidGrammarToggle.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);

  int rightX = width - (buttonWidth * 4 + spacing * 5);
  
  cp5.addButton("resetAll")
     .setPosition(rightX, fieldY)
     .setSize(buttonWidth, rowHeight)
     .setLabel("RESET ALL")
     .setColorCaptionLabel(color(255));
  
  cp5.addButton("shuffleLines")
     .setPosition(rightX + buttonWidth + spacing, fieldY)
     .setSize(buttonWidth, rowHeight)
     .setLabel("SHUFFLE LINES")
     .setColorCaptionLabel(color(255));
  
  cp5.addButton("shufflePatch")
     .setPosition(rightX + (buttonWidth + spacing) * 2, fieldY)
     .setSize(buttonWidth, rowHeight)
     .setLabel("SHUFFLE PATCH")
     .setColorCaptionLabel(color(255));
  
  cp5.addButton("shuffleColour")
     .setPosition(rightX + (buttonWidth + spacing) * 3, fieldY)
     .setSize(buttonWidth, rowHeight)
     .setLabel("SHUFFLE COLOUR")
     .setColorCaptionLabel(color(255));

  int secondRowY = fieldY + rowHeight + spacing;
  
  cp5.addButton("rapidGenToggle")
     .setPosition(rightX, secondRowY)
     .setSize(buttonWidth, rowHeight)
     .setLabel("RAPID GEN")
     .setColorCaptionLabel(color(255));
  
  cp5.addButton("apiColors")
     .setPosition(rightX + buttonWidth + spacing, secondRowY)
     .setSize(buttonWidth, rowHeight)
     .setLabel("API COLORS")
     .setColorCaptionLabel(color(255));
  
  cp5.addButton("exportPNGButton")
     .setPosition(rightX + (buttonWidth + spacing) * 2, secondRowY)
     .setSize(buttonWidth, rowHeight)
     .setLabel("EXPORT PNG")
     .setColorCaptionLabel(color(255));
  
  cp5.addButton("exportSVGButton")
     .setPosition(rightX + (buttonWidth + spacing) * 3, secondRowY)
     .setSize(buttonWidth, rowHeight)
     .setLabel("EXPORT SVG")
     .setColorCaptionLabel(color(255));

  statusLabel = cp5.addTextlabel("statusLabel")
     .setText(scriptName + " v" + scriptVersion)
     .setPosition(20, artHeight + uiPanelHeight - 25)
     .setColorValue(0xFFFFFFFF) // White text
     .setFont(createFont("SansSerif", 10));
  // Get the internal Label object and force it to clear its background on update
  Label statusLabelInternal = statusLabel.get();
  statusLabelInternal.enableColorBackground().setColorBackground(0x00000000); // NORTHING, as it's transparent
  
  errorLabel = cp5.addTextlabel("errorLabel")
     .setText("")
     .setPosition(20, artHeight + uiPanelHeight - 12)
     .setColorValue(0xFFFF6464) // Light red text
     .setFont(createFont("SansSerif", 10))
     .setVisible(false);
  // Get the internal Label object and force it to clear its background on update
  Label errorLabelInternal = errorLabel.get();
  errorLabelInternal.enableColorBackground().setColorBackground(0x00000000); // NORTHING, as it's transparent
  
  // Hide error label initially
  errorLabel.setVisible(false);
}