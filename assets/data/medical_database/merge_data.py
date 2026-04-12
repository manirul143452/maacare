import csv
import json
import os

def merge_medical_data():
    base_path = 'assets/data/medical_database'
    
    # 1. Load Descriptions
    descriptions = {}
    with open(os.path.join(base_path, 'symptom_Description.csv'), mode='r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader) # skip header
        for row in reader:
            if len(row) >= 2:
                descriptions[row[0].strip()] = row[1].strip()
    
    # 2. Load Precautions
    precautions = {}
    with open(os.path.join(base_path, 'symptom_precaution.csv'), mode='r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader) # skip header
        for row in reader:
            if len(row) >= 2:
                disease = row[0].strip()
                p_list = [p.strip() for p in row[1:] if p.strip()]
                precautions[disease] = p_list

    # 3. Load Symptoms and Diseases from dataset.csv
    diseases_data = {}
    with open(os.path.join(base_path, 'dataset.csv'), mode='r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader) # skip header
        for row in reader:
            if not row: continue
            disease = row[0].strip()
            if disease not in diseases_data:
                diseases_data[disease] = set()
            
            # Symptoms are in columns 1 to end
            for s in row[1:]:
                if s.strip():
                    diseases_data[disease].add(s.strip())

    # 4. Load Symptom Weights
    symptom_weights = {}
    with open(os.path.join(base_path, 'Symptom-severity.csv'), mode='r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader) # skip header
        for row in reader:
            if len(row) >= 2:
                symptom_weights[row[0].strip()] = int(row[1].strip())

    # Build Final JSON
    final_diseases = []
    # Use the diseases found in dataset as the primary list
    for disease_name, symptom_set in diseases_data.items():
        final_diseases.append({
            "name": disease_name,
            "description": descriptions.get(disease_name, "No description available."),
            "precautions": precautions.get(disease_name, []),
            "symptoms": sorted(list(symptom_set))
        })

    # Sort diseases by name
    final_diseases.sort(key=lambda x: x["name"])

    result = {
        "diseases": final_diseases,
        "symptoms": symptom_weights
    }

    with open(os.path.join(base_path, 'medical_database.json'), 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2)
    
    print(f"Successfully merged {len(final_diseases)} diseases and {len(symptom_weights)} symptom weights.")

if __name__ == "__main__":
    merge_medical_data()
