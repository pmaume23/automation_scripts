# Camel Case Renaming Script

A powerful and intelligent shell script that converts filenames and folder names to camelCase format while preserving file extensions and existing proper formatting.

## 🚀 Features

- **Smart camelCase conversion** - Capitalizes first letter of each word and removes separators
- **Preserves file extensions** - Maintains `.pdf`, `.txt`, `.jpg`, etc.
- **Intelligent processing** - Recognizes already well-formatted names and skips unnecessary changes
- **Recursive directory processing** - Handles nested folder structures
- **Preserves existing camelCase** - Won't break already properly formatted names like "PhysiwellMaume"
- **Handles complex patterns** - Processes hyphens, underscores, spaces, and punctuation
- **Batch processing** - Can process multiple files and directories at once
- **Safety checks** - Prevents overwriting existing files and provides detailed feedback

## 📋 Requirements

- **macOS** or **Linux** with bash shell
- **Execute permissions** on the script file
- **Write permissions** in the target directories

## 🛠️ Installation

1. **Download the script:**
   ```bash
   # Clone the repository
   git clone https://github.com/pmaume23/automation_scripts.git
   cd automation_scripts
   ```

2. **Make the script executable:**
   ```bash
   chmod +x camel_case_rename.sh
   ```

3. **Optional: Add to PATH for global access:**
   ```bash
   # Add to your ~/.bashrc or ~/.zshrc
   export PATH="$PATH:/path/to/automation_scripts"
   ```

## 🎯 Usage

### Basic Syntax
```bash
./camel_case_rename.sh [OPTIONS] [FILE/DIRECTORY...]
```

### Options
- `-r, --recursive` - Process directories recursively
- `-h, --help` - Show help message

### Examples

#### 1. Rename Individual Files
```bash
./camel_case_rename.sh "my document.pdf"
# Result: "my document.pdf" → "MyDocument.pdf"

./camel_case_rename.sh "user_data.json" "old-file-name.txt"
# Results: 
# "user_data.json" → "UserData.json"
# "old-file-name.txt" → "OldFileName.txt"
```

#### 2. Rename All Files in Current Directory
```bash
./camel_case_rename.sh .
# Processes all files in current directory (non-recursive)
```

#### 3. Recursive Directory Processing
```bash
./camel_case_rename.sh -r .
# Processes all files and folders in current directory and subdirectories

./camel_case_rename.sh -r "/path/to/directory"
# Processes specific directory recursively
```

#### 4. Process Multiple Directories
```bash
./camel_case_rename.sh -r ~/Documents ~/Downloads ~/Desktop/Projects
# Processes multiple directories recursively
```

#### 5. Wildcard Processing
```bash
./camel_case_rename.sh *.txt
# Processes all .txt files in current directory
```

## 📚 Conversion Rules

### Standard Conversions
| Input | Output |
|-------|--------|
| `my document.pdf` | `MyDocument.pdf` |
| `user_data.json` | `UserData.json` |
| `old-file-name.txt` | `OldFileName.txt` |
| `folder name` | `FolderName` |
| `research-paper-v2.pdf` | `ResearchPaperV2.pdf` |

### Smart Preservation
| Input | Output | Notes |
|-------|--------|-------|
| `AlreadyGoodFileName.doc` | `AlreadyGoodFileName.doc` | No change needed |
| `82426017_PhysiwellMaume.py` | `82426017PhysiwellMaume.py` | Preserves existing camelCase |
| `EEG-BasedSystem.pdf` | `EEGBasedSystem.pdf` | Handles acronyms intelligently |

### Complex Patterns
| Input | Output |
|-------|--------|
| `folder.with.dots` | `FolderWithDots` |
| `file--with--double-hyphens` | `FileWithDoubleHyphens` |
| `folder   with   spaces` | `FolderWithSpaces` |
| `123numeric_start.txt` | `123numericStart.txt` |

## 🧠 Intelligent Features

### 1. Existing camelCase Preservation
The script recognizes and preserves existing proper camelCase formatting:
- `PhysiwellMaume` stays as `PhysiwellMaume` (not `Physiwellmaume`)
- `XMLHttpRequest` stays as `XMLHttpRequest`
- `iPhone` stays as `iPhone`

### 2. Acronym Handling
- `EEG-Based` becomes `EEGBased` (preserves acronym)
- `HTTP-Server` becomes `HTTPServer`
- `PDF-Reader` becomes `PDFReader`

### 3. Numeric Handling
- `82426017_PhysiwellMaume.py` becomes `82426017PhysiwellMaume.py`
- `file123_test.txt` becomes `File123Test.txt`
- `123abc.txt` becomes `123abc.txt`

### 4. Safety Features
- **Conflict detection**: Warns if target filename already exists
- **Backup-friendly**: Never overwrites existing files
- **Detailed feedback**: Shows exactly what was renamed
- **Error handling**: Continues processing even if some files fail

## 📁 Directory Processing

### Non-Recursive Mode
```bash
./camel_case_rename.sh /path/to/directory
```
- Processes files in the specified directory only
- Renames subdirectory names but doesn't enter them
- Safe for shallow processing

### Recursive Mode
```bash
./camel_case_rename.sh -r /path/to/directory
```
- Processes all files at every level of nesting
- Renames all directories and subdirectories
- Handles unlimited depth of folder structures

### Example Directory Structure
```
Before:
my_project/
├── source_code/
│   ├── main_file.py
│   └── helper_functions.js
├── documentation/
│   └── user_guide.md
└── test_files/
    └── sample_data.json

After (-r flag):
MyProject/
├── SourceCode/
│   ├── MainFile.py
│   └── HelperFunctions.js
├── Documentation/
│   └── UserGuide.md
└── TestFiles/
    └── SampleData.json
```

## ⚠️ Important Notes

### File Extensions
- **Always preserved**: `.pdf`, `.txt`, `.jpg`, `.png`, etc.
- **Case maintained**: Extensions keep their original case
- **No modification**: Only filename (before extension) is processed

### Hidden Files
- **System files**: `.DS_Store`, `.gitignore` are processed but usually no change needed
- **Dot files**: `.bashrc`, `.profile` are handled appropriately

### Permissions
- **Requires write access** to the directory containing files to rename
- **Preserves file permissions** and ownership
- **Maintains timestamps** and other metadata

## 🔧 Advanced Usage

### Batch Processing Script
Create a batch script to process multiple common directories:

```bash
#!/bin/bash
# batch_rename.sh
./camel_case_rename.sh -r ~/Documents/Research
./camel_case_rename.sh -r ~/Downloads
./camel_case_rename.sh -r ~/Desktop/Projects
echo "Batch processing complete!"
```

### Integration with Other Tools
```bash
# Find and process all directories containing specific files
find ~/Documents -name "*.pdf" -execdir ~/path/to/camel_case_rename.sh {} \;

# Process only recently modified files
find . -mtime -7 -name "*.txt" -exec ~/path/to/camel_case_rename.sh {} \;
```

## 🐛 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   chmod +x camel_case_rename.sh
   ```

2. **No Files Processed**
   - Check if files exist in the specified directory
   - Verify you have write permissions
   - Use absolute paths if relative paths don't work

3. **"Already Exists" Warnings**
   - The script prevents overwriting existing files
   - Manually resolve conflicts before rerunning

4. **Script Not Found**
   ```bash
   # Use absolute path
   /full/path/to/camel_case_rename.sh
   
   # Or ensure script is executable and in current directory
   ./camel_case_rename.sh
   ```

### Debug Mode
For troubleshooting, you can add debug output:
```bash
# Add this line after the shebang for verbose output
set -x
```

## 📊 Performance

- **Speed**: Processes hundreds of files per second
- **Memory**: Minimal memory usage, processes files individually
- **Scalability**: Handles directories with thousands of files
- **Safety**: Built-in safeguards prevent data loss

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the need for consistent file naming conventions
- Built for researchers and developers who work with large file collections
- Designed with safety and intelligence as primary concerns

## 📞 Support

For issues, questions, or suggestions:
- Create an issue in the GitHub repository
- Check the troubleshooting section above
- Review the examples for common use cases

---

**Happy renaming!** 🎉
