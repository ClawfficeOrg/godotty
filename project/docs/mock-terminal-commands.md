# Mock Terminal Commands - Test Cases

## Commands and Expected Behavior

### 1. `mkdir <name>`
- **Test Case 1**: Create a new directory
  - Input: `mkdir test`
  - Check: `ls` shows `test`
- **Test Case 2**: Attempt to create an existing directory
  - Input: `mkdir test`
  - Expected: Error message "mkdir: cannot create directory 'test': File exists"
- **Test Case 3**: Attempt to create directory in non-existent parent
  - Input: `mkdir /nonexistent/child`
  - Expected: Error message "mkdir: cannot create directory '/nonexistent/child': No such file or directory"

### 2. `touch <name>`
- **Test Case 1**: Create a new file
  - Input: `touch file.txt`
  - Check: `ls` shows `file.txt`
- **Test Case 2**: Touch an existing file
  - Input: `touch file.txt`
  - Expected: No changes (no error).

### 3. `rm <name>`
- **Test Case 1**: Remove an existing file
  - Input: `rm file.txt`
  - Check: `ls` no longer shows `file.txt`
- **Test Case 2**: Attempt to remove non-existent file
  - Input: `rm missing_file`
  - Expected: Error message "rm: cannot remove 'missing_file': No such file or directory"

### 4. `cat <file>`
- **Test Case 1**: Display contents of a file
  - Input: `cat readme.md`
  - Expected: File contents are displayed.
- **Test Case 2**: Attempt to cat a non-existent file
  - Input: `cat missing_file`
  - Expected: Error message "cat: missing_file: No such file or directory"

### 5. `whoami`
- **Test Case 1**: Display user name
  - Input: `whoami`
  - Expected: "user@clawffice" is displayed.

---

## Verification Steps
1. Execute input commands using the mock terminal.
2. Compare output against expected behavior as outlined above.
3. Document any discrepancies and fix issues within `project/autoload/terminal_manager.gd` if necessary.