// DESCRIPTION
// GrammarGenerator.pde
// Generates all ordered sequences of letters A,B,C,D where:
// - Each letter appears consecutively (all As, then all Bs, then all Cs, then all Ds)
// - Each letter appears between 1 and N times (N = maxRepetition, default 5)
// - Total sequences = N^4 (e.g., 5^4 = 625 grammars)
// 
// This is a Cartesian product of counts: [1..N] × [1..N] × [1..N] × [1..N]
// Each grammar is a concatenation of repeated letters: Aᵃ Bᵇ Cᶜ Dᵈ
// where a,b,c,d ∈ {1,2,...,N}
//
// Example with N=3: "ABCD", "AABCD", "AAABCD", "ABBCD", "AAABBBCCCDDD", etc.
//
// Companion script (imported) to Mondrian_processing.pde.


// CODE

class GrammarGenerator {
  ArrayList<String> allGrammars;
  int maxRepetition;  // 1-5 typically, but can be any number
  
  // Constructor with default maxRepetition = 5
  GrammarGenerator() {
    this(5);  // Default to 5
  }
  
  // Constructor with custom maxRepetition
  GrammarGenerator(int maxRep) {
    maxRepetition = maxRep;
    allGrammars = new ArrayList<String>();
    generateAllGrammars();
    println("Generated " + allGrammars.size() + " grammars (max " + maxRepetition + " per letter)");
  }
  
  void generateAllGrammars() {
    for (int aCount = 1; aCount <= maxRepetition; aCount++) {
      for (int bCount = 1; bCount <= maxRepetition; bCount++) {
        for (int cCount = 1; cCount <= maxRepetition; cCount++) {
          for (int dCount = 1; dCount <= maxRepetition; dCount++) {
            String grammar = "";
            for (int i = 0; i < aCount; i++) grammar += "A";
            for (int i = 0; i < bCount; i++) grammar += "B";
            for (int i = 0; i < cCount; i++) grammar += "C";
            for (int i = 0; i < dCount; i++) grammar += "D";
            allGrammars.add(grammar);
          }
        }
      }
    }
    
    println("GrammarGenerator: Generated " + allGrammars.size() + " grammars");
    // Print first 10 as sample
    for (int i = 0; i < min(10, allGrammars.size()); i++) {
      println("  Sample " + i + ": " + allGrammars.get(i));
    }
  }
  
  String getRandomGrammar() {
    if (allGrammars.isEmpty()) return "AABBCCDDDDDD"; // fallback
    int randomIndex = (int)random(allGrammars.size());
    String selected = allGrammars.get(randomIndex);
    println("GrammarGenerator: Selected grammar #" + randomIndex + ": " + selected);
    return selected;
  }
  
  int getTotalCount() {
    return allGrammars.size();
  }
  
  int getMaxRepetition() {
    return maxRepetition;
  }
}