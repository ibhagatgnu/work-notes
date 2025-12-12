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

# Define the pattern for the CFA rule we want to *INCLUDE* (ONLY 'exp').
TARGET_CFA_PATTERN = re.compile(r'^exp$') 

# State Machine Constants
STATE_SEARCHING_FDE = 0
STATE_IN_FDE_HEADER = 1
STATE_IN_FDE_ROWS = 2

# --- Helper Functions for PLT Filtering ---

def get_plt_section_range(file_path):
    """
    Runs objdump -h to find the start (VMA) and size of the .plt section.
    Returns (start_address_int, end_address_int) or (0, 0) if not found.
    """
    try:
        # Run objdump -h to get section headers
        result = subprocess.run(
            ['objdump', '-h', str(file_path)],
            capture_output=True,
            text=True,
            check=True,
            timeout=5
        )
    except Exception:
        return (0, 0)

    # Matches the start of the line, allows flexible whitespace/index, 
    # and anchors on ".plt" followed by the Size and VMA fields.
    PLT_HEADER_PATTERN = re.compile(
        r'^\s*\d+\s+\.plt\s+'      # Match start, section number, and ".plt"
        r'(?P<size>[0-9a-f]+)\s+'  # Capture Size
        r'(?P<vma>[0-9a-f]+)\s+'   # Capture VMA (Virtual Memory Address/Start Address)
    )
    
    for line in result.stdout.splitlines():
        match = PLT_HEADER_PATTERN.search(line)
        if match:
            try:
                # Convert hex strings to integers for arithmetic
                start_addr = int(match.group('vma'), 16)
                size = int(match.group('size'), 16)
                end_addr = start_addr + size
                return (start_addr, end_addr)
            except ValueError:
                # Handle conversion errors
                return (0, 0)
    
    return (0, 0)

def is_plt_fde(fde_start_addr_hex, plt_range):
    """Checks if an FDE address falls within the .plt section range (inclusive start)."""
    start_addr_int, end_addr_int = plt_range
    
    if start_addr_int == 0 and end_addr_int == 0:
        return False
        
    try:
        fde_addr_int = int(fde_start_addr_hex, 16)
        # Range check: Inclusive start (<=) and exclusive end (<).
        return start_addr_int <= fde_addr_int < end_addr_int
        
    except ValueError:
        return False

def is_custom_cfa(cfa_rule):
    """Checks if a given CFA rule is the targeted 'exp' type."""
    return TARGET_CFA_PATTERN.match(cfa_rule)

# --- Analysis Function ---

def analyze_objdump_output(objdump_output, plt_range):
    """
    Parses objdump -WF output, extracts the actual PC address, and filters out 
    FDEs whose start PC is within the PLT range.
    """
    fde_results = []
    current_fde_start_addr = None
    custom_cfa_rules = set()
    state = STATE_SEARCHING_FDE
    
    is_plt_entry = False

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
                # End of the current FDE reached, save the results IF it's not PLT
                if custom_cfa_rules and not is_plt_entry:
                    fde_results.append((current_fde_start_addr, custom_cfa_rules))
                
                # Reset and transition
                state = STATE_SEARCHING_FDE
                custom_cfa_rules = set()
                current_fde_start_addr = None
                is_plt_entry = False 
                
                if block_match.group(1) == 'FDE':
                    # Fall through to State 0 check below
                    pass
                else:
                    continue

            # If it's a regular row, parse it
            match = ROW_PATTERN.match(line)
            if match and not is_plt_entry: # Skip row processing for PLT FDEs
                cfa_rule = match.group('cfa_rule').strip()
                if is_custom_cfa(cfa_rule):
                    custom_cfa_rules.add(cfa_rule)
            
            continue
        
        # State 0: FDE/CIE Header Search
        if state == STATE_SEARCHING_FDE:
            # Matches the format: '... FDE cie=... pc=<ADDR>..<'
            fde_match = re.match(
                r'^[0-9a-f]{8}\s+[0-9a-f]{16}\s+[0-9a-f]{8}\s+FDE\s+cie=[0-9a-f]{8}\s+pc=(?P<addr>[0-9a-f]+)\.\.', 
                line
            )
            
            if fde_match:
                current_fde_start_addr = fde_match.group('addr')
                
                if is_plt_fde(current_fde_start_addr, plt_range):
                    is_plt_entry = True
                
                state = STATE_IN_FDE_HEADER
                continue

    # Final check for the last FDE
    if custom_cfa_rules and not is_plt_entry:
        fde_results.append((current_fde_start_addr, custom_cfa_rules))
        
    return fde_results

def process_directory(directory_path):
    """
    Iterates through files in a directory, runs objdump on executables/shared objects,
    and reports custom CFA rules found, excluding the PLT section.
    """
    print(f"## Analyzing Directory: {directory_path}\n")
    
    files_analyzed_count = 0
    files_with_custom_cfa_count = 0 

    for entry in os.scandir(directory_path):
        full_path = Path(entry.path)
        
        # 1. Skip directories and non-files
        if not entry.is_file():
            continue
            
        try:
            # 1a. Get the .plt section range first (using objdump -h)
            plt_range = get_plt_section_range(full_path)
            
            # 2. Run objdump -WF on the file and capture output
            result = subprocess.run(
                ['objdump', '-WF', str(full_path)],
                capture_output=True,
                text=True,
                check=True,  
                timeout=5    
            )
            
            files_analyzed_count += 1

        except subprocess.CalledProcessError:
            continue
        except FileNotFoundError:
            print("ERROR: 'objdump' command not found. Ensure it is installed and in your PATH.")
            sys.exit(1)
        except subprocess.TimeoutExpired:
            print(f"WARNING: Skipping {full_path.name} (objdump timed out).")
            continue
            
        objdump_output = result.stdout
        
        # 3. Analyze the objdump output, passing the PLT range for filtering
        custom_cfa_fdes = analyze_objdump_output(objdump_output, plt_range)

        if custom_cfa_fdes:
            files_with_custom_cfa_count += 1
            
            print(f"### Results for File: **{full_path.name}**")
            print(f"Total non-.plt FDEs found with 'exp' CFA rules: {len(custom_cfa_fdes)}\n")
            
            for addr, rules in custom_cfa_fdes:
                rules_list = sorted(list(rules))
                print(f"  FDE at 0x{addr}:") 
                print(f"    Unique Custom Rules: **{', '.join(rules_list)}**")
            print("-" * 40)
            
    # --- Final report including both counts ---
    print("\n## Analysis Complete.")
    print(f"**Total files analyzed successfully**: {files_analyzed_count}")
    print(f"**Total files with non-.plt 'exp' CFA rules**: {files_with_custom_cfa_count}")
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

# python -u cfa_exp_analyzer_dir.py /usr/lib64/ 2>&1 | tee usr_lib64_exp_report
