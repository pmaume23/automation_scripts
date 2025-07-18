# Quick Reference Guide - Camel Case Renaming Script

## 🚀 Quick Start

```bash
# Make executable
chmod +x camel_case_rename.sh

# Basic usage
./camel_case_rename.sh "filename.txt"

# Process directory recursively
./camel_case_rename.sh -r .
```

## 📋 Cheat Sheet

### Most Common Commands

```bash
# Current directory (non-recursive)
./camel_case_rename.sh .

# Current directory (recursive)
./camel_case_rename.sh -r .

# Specific directory (recursive)
./camel_case_rename.sh -r ~/Documents

# Multiple directories
./camel_case_rename.sh -r ~/Documents ~/Downloads

# All PDF files
./camel_case_rename.sh *.pdf

# Get help
./camel_case_rename.sh -h
```

### Quick Conversions

| Input | Output |
|-------|--------|
| `my file.pdf` | `MyFile.pdf` |
| `user_data.json` | `UserData.json` |
| `old-file-name.txt` | `OldFileName.txt` |
| `82426017_PhysiwellMaume.py` | `82426017PhysiwellMaume.py` |
| `EEG-BasedSystem.pdf` | `EEGBasedSystem.pdf` |

### Flags

| Flag | Description |
|------|-------------|
| `-r` | Recursive processing |
| `-h` | Show help |

### Safety Features

✅ **Preserves file extensions**  
✅ **Won't overwrite existing files**  
✅ **Maintains proper camelCase**  
✅ **Handles complex patterns**  
✅ **Provides detailed feedback**

### What It Processes

- **Spaces** → Removed, next letter capitalized
- **Underscores** → Removed, next letter capitalized  
- **Hyphens** → Removed, next letter capitalized
- **Dots** (in names) → Removed, next letter capitalized
- **Multiple separators** → Treated as single separator

### What It Preserves

- **File extensions** (`.pdf`, `.txt`, etc.)
- **Existing camelCase** (`PhysiwellMaume` stays as is)
- **Acronyms** (`EEG`, `HTTP`, `XML`)
- **Numeric prefixes** (`82426017PhysiwellMaume`)

## 🎯 Use Cases

### Research Papers
```bash
./camel_case_rename.sh -r ~/Documents/Research
```

### Project Files
```bash
./camel_case_rename.sh -r ~/Projects
```

### Downloads Cleanup
```bash
./camel_case_rename.sh -r ~/Downloads
```

### Specific File Types
```bash
./camel_case_rename.sh *.pdf *.txt *.doc
```

## ⚠️ Remember

- Always **backup important files** before mass renaming
- Test on a **small directory** first
- Check for **name conflicts** in the output
- Use **absolute paths** if relative paths don't work

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| Permission denied | `chmod +x camel_case_rename.sh` |
| Script not found | Use `./camel_case_rename.sh` or full path |
| Files not renamed | Check write permissions |
| Already exists warning | Resolve conflicts manually |

---

**For full documentation, see [README.md](README.md)**
