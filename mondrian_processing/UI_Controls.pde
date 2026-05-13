// DESCRIPTION
// UI control declarations etc. for Mondrian_Processing.pde

// CODE
// UI_Controls.pde
// Centralized UI declaration and initialization for Mondrian_Processing

import controlP5.*;

// ControlP5 components (declared globally)
ControlP5 cp5;
Textfield ruleField;
Textfield percentField;
Textfield colorCountField;
Toggle rapidLinesToggle;
Toggle rapidPatchToggle;
Toggle rapidColourToggle;
Toggle rapidAPIToggle;
Toggle rapidGrammarToggle;

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
  int spacing = 10;
  int rowHeight = 25;
  int labelX = 20;
  int fieldY = uiY + 10;
  
  ruleField = cp5.addTextfield("ruleField")
     .setPosition(labelX, fieldY)
     .setSize(fieldWidth, rowHeight)
     .setText(rule)
     .setLabel("Rule String")
     .setAutoClear(false)
     .setColorCaptionLabel(color(255));

  percentField = cp5.addTextfield("percentField")
     .setPosition(labelX + fieldWidth + spacing, fieldY)
     .setSize(smallFieldWidth, rowHeight)
     .setText(str(int(keep * 100)))
     .setLabel("Fill %")
     .setAutoClear(false)
     .setColorCaptionLabel(color(255));

  colorCountField = cp5.addTextfield("colorCountField")
     .setPosition(labelX + fieldWidth + spacing + smallFieldWidth + spacing, fieldY)
     .setSize(smallFieldWidth, rowHeight)
     .setText("7")
     .setLabel("Colors (0=all)")
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
     .setLabel("LINES")
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
     .setLabel("PATCH")
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
     .setLabel("COLOUR")
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
     .setLabel("API")
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
     .setLabel("GRAMMAR")
     .setColorBackground(offColor)
     .setColorActive(onColor)
     .setColorForeground(hoverColor)
     .setColorCaptionLabel(rapidGrammar ? offColor : onColor);
  rapidGrammarToggle.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);

  int buttonWidth = 70;
  int rightX = width - (buttonWidth * 4 + spacing * 3);
  
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
}