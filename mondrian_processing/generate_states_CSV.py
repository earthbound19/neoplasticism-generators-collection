import csv
from itertools import product

subfeatures = ['rapidLines', 'rapidPatch', 'rapidColour', 'rapidAPI']
output_file = 'mondrian_test_matrix.csv'

with open(output_file, 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['State_ID', 'rapidLines', 'rapidPatch', 'rapidColour', 'rapidAPI', 'Expected_Result_per_generated_variant', 'Actual_Result_per_generated_variant', 'status'])
    
    for i, combo in enumerate(product([0,1], repeat=4)):
        lines, patch, colour, api = combo
        writer.writerow([i, lines, patch, colour, api, '', ''])

print(f"Created {output_file}")
print("\nImport into your spreadsheet to track behaviors.")
print("Column mapping: A=State_ID, B=rapidLines, C=rapidPatch, D=rapidColour, E=rapidAPI, F=Observed_Behavior, G=Notes")