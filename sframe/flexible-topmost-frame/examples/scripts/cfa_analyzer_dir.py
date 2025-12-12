import re
import sys
import os
import subprocess
from pathlib import Path

# --- Configuration ---
# Define the regex pattern for a row within an FDE/CIE.
ROW_PATTERN = re.compile(
    r'^[0-9a-f]{16}\s+'          # LOC (16 hex digits)
    r'(?P<cfa_rule>\S+)\s+'      # CFA rule (non-whitespace characters)
    r'.*$'
)

# Define the patterns for CFA rules we want to *exclude* (the common ones).
EXCLUDED_CFA_PATTERNS = [
    re.compile(r'^rsp\+\d+$'), # e.g., rsp+8
    re.compile(r'^rbp\+\d+$'), # e.g., rbp+8
    re.compile(r'^exp$'),      # e.g., exp (Expression)
    re.compile(r'^u$')         # e.g., u (Undefined)
]

# State Machine Constants
STATE_SEARCHING_FDE = 0
STATE_IN_FDE_HEADER = 1
STATE_IN_FDE_ROWS = 2

def is_custom_cfa(cfa_rule):
    """Checks if a given CFA rule is NOT one of the common/excluded types."""
    for pattern in EXCLUDED_CFA_PATTERNS:
        if pattern.match(cfa_rule):
            return False
    return True

def analyze_objdump_output(objdump_output):
    """
    Parses objdump -WF output to identify FDEs and list the unique custom CFA rules.
    Returns a list of (FDE_Start_Address, set_of_custom_rules).
    """
    fde_results = []
    current_fde_start_addr = None
    custom_cfa_rules = set()
    state = STATE_SEARCHING_FDE

    for line in objdump_output.splitlines():
        line = line.strip()

        # State 1 -> State 2 Transition
        if state == STATE_IN_FDE_HEADER:
            state = STATE_IN_FDE_ROWS
            continue

        # State 2: FDE Row Analysis
        if state == STATE_IN_FDE_ROWS:
            # Check for the start of the next block (CIE/FDE)
            block_match = re.match(r'^[0-9a-f]{8}\s+[0-9a-f]{16}\s+[0-9a-f]{8}\s+(CIE|FDE)', line)
            if block_match:
                # End of the current FDE reached, save the results
                if custom_cfa_rules:
                    fde_results.append((current_fde_start_addr, custom_cfa_rules))
                
                # Reset and transition (re-process the line in the next state)
                state = STATE_SEARCHING_FDE
                custom_cfa_rules = set()
                current_fde_start_addr = None
                
                if block_match.group(1) == 'FDE':
                    current_fde_start_addr = line.split()[0]
                    state = STATE_IN_FDE_HEADER
                continue

            # If it's a regular row, parse it
            match = ROW_PATTERN.match(line)
            if match:
                cfa_rule = match.group('cfa_rule').strip()
                if is_custom_cfa(cfa_rule):
                    custom_cfa_rules.add(cfa_rule)
            
            continue
        
        # State 0: FDE/CIE Header Search
        if state == STATE_SEARCHING_FDE:
            fde_match = re.match(r'^(?P<addr>[0-9a-f]{8})\s+[0-9a-f]{16}\s+[0-9a-f]{8}\s+FDE', line)
            if fde_match:
                current_fde_start_addr = fde_match.group('addr')
                state = STATE_IN_FDE_HEADER
                continue

    # Final check for the last FDE
    if custom_cfa_rules:
        fde_results.append((current_fde_start_addr, custom_cfa_rules))
        
    return fde_results

def process_directory(directory_path):
    """
    Iterates through files in a directory, runs objdump on executables/shared objects,
    and reports custom CFA rules found.
    """
    print(f"## Analyzing Directory: {directory_path}\n")
    
    # --- File counters initialization ---
    files_analyzed_count = 0
    files_with_custom_cfa_count = 0 # NEW COUNTER
    # ------------------------------------

    # Use os.scandir for an efficient way to check file type
    for entry in os.scandir(directory_path):
        full_path = Path(entry.path)
        
        # 1. Skip directories and non-files
        if not entry.is_file():
            continue
            
        try:
            # Run objdump -WF on the file and capture output
            result = subprocess.run(
                ['objdump', '-WF', str(full_path)],
                capture_output=True,
                text=True,
                check=True,  # Raise error if objdump fails
                timeout=5    # Prevent hangs on massive files
            )
            
            # Increment counter on successful objdump
            files_analyzed_count += 1

        except subprocess.CalledProcessError:
            # objdump failed (e.g., file is not an ELF binary, or no .eh_frame)
            continue
        except FileNotFoundError:
            print("ERROR: 'objdump' command not found. Ensure it is installed and in your PATH.")
            sys.exit(1)
        except subprocess.TimeoutExpired:
            print(f"WARNING: Skipping {full_path.name} (objdump timed out).")
            continue
            
        objdump_output = result.stdout
        
        # 3. Analyze the objdump output
        custom_cfa_fdes = analyze_objdump_output(objdump_output)

        if custom_cfa_fdes:
            # --- NEW: Increment custom CFA file counter ---
            files_with_custom_cfa_count += 1
            # ---------------------------------------------
            
            print(f"### Results for File: **{full_path.name}**")
            print(f"Total FDEs found with custom CFA rules: {len(custom_cfa_fdes)}\n")
            
            for addr, rules in custom_cfa_fdes:
                rules_list = sorted(list(rules))
                print(f"  FDE at 0x{addr}:")
                print(f"    Unique Custom Rules: **{', '.join(rules_list)}**")
            print("-" * 40)
            
    # --- Final report including both counts ---
    print("\n## Analysis Complete.")
    print(f"**Total files analyzed successfully**: {files_analyzed_count}")
    print(f"**Total files with custom CFA rules**: {files_with_custom_cfa_count}")
    # ----------------------------------------

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: python3 {sys.argv[0]} <directory_path>")
        sys.exit(1)
        
    target_dir = sys.argv[1]
    
    if not os.path.isdir(target_dir):
        print(f"Error: Directory not found or not a directory: {target_dir}")
        sys.exit(1)
        
    process_directory(target_dir)

# python -u cfa_analyzer_dir.py /usr/bin/ 2>&1 | tee usr_bin_non-standard-cfa_report
