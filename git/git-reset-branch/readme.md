# Git Reset Helper

An interactive Node.js CLI tool that simplifies the process of resetting Git branches to specific commits. Perfect for undoing mistakes, reverting changes, or managing your Git history with ease.

## Features

- **Repository Scanner**: Automatically finds all Git repositories in the current directory
- **Interactive Selection**: User-friendly menus for selecting repositories, branches, and commits
- **Visual Commit History**: Shows commit graph with the last 20 commits
- **Multiple Reset Types**: Choose between soft, mixed, or hard reset
- **Smart Branch Switching**: Automatically checks out the selected branch if needed
- **Remote Sync Detection**: Warns when local branch diverges from remote
- **Force Push Support**: Option to force push changes after hard reset
- **Colorful Output**: ANSI color-coded terminal output for better readability
- **Safety Confirmations**: Multiple confirmation prompts to prevent accidental data loss

## Quick Start

### Option 1: Download and run (recommended)
Downloads and runs the script directly without cloning the entire repository:
```bash
curl -o git-reset-helper.js https://raw.githubusercontent.com/F00L1X/wsflx/main/git/git-reset-branch/git-reset-helper.js && node git-reset-helper.js
```

**What this does:**
1. Downloads the script from GitHub to your current directory
2. Runs the script with Node.js
3. Launches the interactive Git reset interface

### Option 2: Clone and run locally
Clones the entire repository to your machine for offline access and easier updates:
```bash
git clone https://github.com/F00L1X/wsflx.git
cd wsflx/git/git-reset-branch
node git-reset-helper.js
```

**What this does:**
1. Clones the entire wsflx repository to your current directory
2. Navigates to the git-reset-branch folder
3. Runs the Git reset helper script

**Benefits of cloning:**
- Access to all scripts in the repository
- Easy to update with `git pull`
- Can customize the script locally
- No internet required after initial clone

### Option 3: Make it globally available (recommended for frequent use)
```bash
# Clone the repository
git clone https://github.com/F00L1X/wsflx.git
cd wsflx/git/git-reset-branch

# Make the script executable (Linux/Mac)
chmod +x git-reset-helper.js

# Create a symlink to make it globally available
# Linux/Mac:
sudo ln -s $(pwd)/git-reset-helper.js /usr/local/bin/git-reset

# Windows (PowerShell as Admin):
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps\git-reset.cmd" -Value "$PWD\git-reset-helper.js"

# Now you can run it from anywhere:
git-reset
```

## Requirements

- Node.js 12.0 or higher
- Git installed and configured
- Terminal with ANSI color support (most modern terminals)

## Usage

1. **Navigate to the directory** containing your Git repositories (or the repository itself)
   ```bash
   cd /path/to/your/projects
   ```

2. **Run the script**
   ```bash
   node git-reset-helper.js
   ```

3. **Follow the interactive prompts:**
   - Select a repository from the list
   - Choose the branch you want to reset
   - Pick a commit to reset to from the visual history
   - Select the reset type (soft, mixed, or hard)
   - Confirm the operation

4. **Optional: Force push** (if you performed a hard reset and want to update the remote)

## Reset Types Explained

| Reset Type | Staged Changes | Working Directory | Use Case |
|------------|----------------|-------------------|----------|
| **Soft** | Preserved | Preserved | Keep all changes but move HEAD back. Good for recommitting. |
| **Mixed** (default) | Cleared | Preserved | Unstage changes but keep them in working directory. Good for reorganizing commits. |
| **Hard** | Cleared | Cleared | Discard all changes completely. Good for starting fresh. ⚠️ **Destructive!** |

## Example Workflow

```bash
$ node git-reset-helper.js

🔍 Git Reset Helper
==================

Scanning for Git repositories in: /home/user/projects

📁 Select a repository:
1. ./my-project
2. ./another-project

Enter number (1-2): 1

✅ Selected repository: my-project

🌿 Select a branch:
1. main
2. develop
3. feature/new-feature

Enter number (1-3): 1

✅ Selected branch: main

Loading commits...

📝 Select a commit to reset to:
1. * 1a2b3c4 Fix bug in authentication
2. * 5d6e7f8 Add new feature
3. * 9g0h1i2 Update dependencies
4. * 3j4k5l6 Refactor code structure

Enter number (1-4): 3

⚠️  Select reset type:
1. Soft reset (keeps changes staged)
2. Mixed reset (keeps changes unstaged) [default]
3. Hard reset (discards all changes) ⚠️

Enter choice (1-3) or press Enter for default: 2

📋 Summary:
Repository: my-project
Branch: main
Commit: * 9g0h1i2 Update dependencies
Command: git reset --mixed 9g0h1i2

⚠️  Are you sure you want to proceed? (y/N): y

✅ Reset completed successfully!
```

## Safety Features

- **Multiple Confirmations**: The script asks for confirmation before executing any destructive operation
- **Visual Summary**: Shows exactly what will happen before executing
- **Remote Tracking**: Warns when your local branch diverges from the remote
- **Force Push Protection**: Requires explicit confirmation for force push operations
- **Error Handling**: Graceful error handling with helpful error messages

## Troubleshooting

### Script won't run
- Ensure Node.js is installed: `node --version`
- Check file permissions: `chmod +x git-reset-helper.js` (Linux/Mac)

### No repositories found
- Make sure you're running the script from a directory that contains Git repositories
- The script recursively scans subdirectories, excluding `node_modules` and hidden folders

### Reset failed
- Ensure you have uncommitted changes backed up before hard reset
- Check if you have proper permissions for the repository
- Verify the repository is not in a detached HEAD state

### Force push blocked
- The remote may have branch protection enabled
- Use `git push --force` instead of `--force-with-lease` if you're certain
- Contact your repository administrator about branch protection rules

## Advanced Usage

### Running from any directory
After making the script globally available (see Option 3), you can run it from anywhere:
```bash
cd /path/to/any/project
git-reset
```

### Scanning specific directory
Navigate to the parent directory containing multiple repositories:
```bash
cd ~/projects
node /path/to/git-reset-helper.js
```

## Files in this Folder

- `git-reset-helper.js` - Main interactive Git reset script
- `readme.md` - This documentation file

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details.
