import os
import glob
import yaml
import sys
import json

MANDATORY_FIELDS = [
    'type',
    'status',
    'depends_on',
    'stage_scope',
    'country',
    'last_updated'
]

ROOT_DIR = r"c:\ReposGitHub\Capacity-Utilization-US_Chile"

DIRS_TO_SCAN = [
    os.path.join(ROOT_DIR, "chapter2_vault"),
    os.path.join(ROOT_DIR, "drafts"),
    os.path.join(ROOT_DIR, "reports"),
    os.path.join(ROOT_DIR, "chapter2_paper") # check if exists or relevant
]

def check_file(file_path):
    rel_path = os.path.relpath(file_path, ROOT_DIR)
    
    with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()
    
    lines = content.splitlines()
    
    if not lines or lines[0].strip() != '---':
        return {
            'file': rel_path,
            'valid_yaml_header': False,
            'reason': 'No starting YAML frontmatter delimiter (---)',
            'missing_fields': MANDATORY_FIELDS,
            'empty_fields': [],
            'parsed_data': None
        }
    
    # find closing ---
    closing_idx = -1
    for idx in range(1, len(lines)):
        if lines[idx].strip() == '---':
            closing_idx = idx
            break
            
    if closing_idx == -1:
        return {
            'file': rel_path,
            'valid_yaml_header': False,
            'reason': 'No closing YAML frontmatter delimiter (---)',
            'missing_fields': MANDATORY_FIELDS,
            'empty_fields': [],
            'parsed_data': None
        }
        
    yaml_str = "\n".join(lines[1:closing_idx])
    
    try:
        data = yaml.safe_load(yaml_str)
    except Exception as e:
        return {
            'file': rel_path,
            'valid_yaml_header': False,
            'reason': f'YAML syntax error: {str(e)}',
            'missing_fields': MANDATORY_FIELDS,
            'empty_fields': [],
            'parsed_data': None
        }
        
    if not isinstance(data, dict):
        return {
            'file': rel_path,
            'valid_yaml_header': False,
            'reason': f'YAML frontmatter is not a dictionary (type: {type(data)})',
            'missing_fields': MANDATORY_FIELDS,
            'empty_fields': [],
            'parsed_data': str(data)
        }
        
    missing = []
    empty = []
    
    for field in MANDATORY_FIELDS:
        if field not in data:
            missing.append(field)
        else:
            val = data[field]
            # check if null or empty (string/list)
            if val is None:
                empty.append(field)
            elif isinstance(val, str) and val.strip() == "":
                empty.append(field)
            elif isinstance(val, (list, dict)) and len(val) == 0:
                empty.append(field)
                
    is_valid = (len(missing) == 0) and (len(empty) == 0)
    
    return {
        'file': rel_path,
        'valid_yaml_header': is_valid,
        'reason': 'OK' if is_valid else f'Missing: {missing}, Empty: {empty}',
        'missing_fields': missing,
        'empty_fields': empty,
        'parsed_data': data
    }

class DateEncoder(json.JSONEncoder):
    def default(self, obj):
        import datetime
        if isinstance(obj, (datetime.date, datetime.datetime)):
            return obj.isoformat()
        return super().default(obj)

def main():
    all_files = []
    for d in DIRS_TO_SCAN:
        if os.path.exists(d):
            for root, _, files in os.walk(d):
                for f in files:
                    if f.endswith('.md'):
                        all_files.append(os.path.join(root, f))
                        
    print(f"Total markdown files found across target directories: {len(all_files)}")
    
    results = []
    passed = 0
    failed = 0
    
    for file_path in sorted(all_files):
        res = check_file(file_path)
        results.append(res)
        if res['valid_yaml_header']:
            passed += 1
        else:
            failed += 1
            print(f"FAIL: {res['file']} -> {res['reason']}")
            
    print(f"\nSummary:")
    print(f"Total: {len(all_files)}")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    
    with open(r"c:\ReposGitHub\Capacity-Utilization-US_Chile\.agents\teamwork_preview_reviewer_m4_1\audit_results.json", "w", encoding="utf-8") as out:
        json.dump(results, out, cls=DateEncoder, indent=2)

if __name__ == '__main__':
    main()
