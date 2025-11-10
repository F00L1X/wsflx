#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const question = (query) => new Promise((resolve) => rl.question(query, resolve));

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function execGitCommand(command, cwd) {
  try {
    return execSync(command, { cwd, encoding: 'utf-8' }).trim();
  } catch (error) {
    return null;
  }
}

function findGitRepos(rootDir) {
  const repos = [];
  
  function scanDirectory(dir) {
    try {
      const items = fs.readdirSync(dir);
      
      for (const item of items) {
        const fullPath = path.join(dir, item);
        const stat = fs.statSync(fullPath);
        
        if (stat.isDirectory()) {
          if (item === '.git') {
            repos.push(path.dirname(fullPath));
          } else if (item !== 'node_modules' && item !== '.git' && !item.startsWith('.')) {
            scanDirectory(fullPath);
          }
        }
      }
    } catch (error) {
      // Skip directories we can't read
    }
  }
  
  scanDirectory(rootDir);
  return repos;
}

async function selectFromList(items, prompt) {
  log(`\n${prompt}`, 'cyan');
  items.forEach((item, index) => {
    console.log(`${colors.yellow}${index + 1}.${colors.reset} ${item}`);
  });
  
  while (true) {
    const answer = await question(`\nEnter number (1-${items.length}): `);
    const index = parseInt(answer) - 1;
    
    if (index >= 0 && index < items.length) {
      return { index, value: items[index] };
    }
    
    log('Invalid selection. Please try again.', 'red');
  }
}

async function main() {
  log('\n🔍 Git Reset Helper', 'bright');
  log('==================\n', 'bright');
  
  // Find all git repositories
  const currentDir = process.cwd();
  log(`Scanning for Git repositories in: ${currentDir}`, 'dim');
  
  const repos = findGitRepos(currentDir);
  
  if (repos.length === 0) {
    log('\n❌ No Git repositories found in the current directory.', 'red');
    rl.close();
    return;
  }
  
  // Select repository
  const repoSelection = await selectFromList(
    repos.map(r => path.relative(currentDir, r) || '.'),
    '📁 Select a repository:'
  );
  const selectedRepo = repos[repoSelection.index];
  
  log(`\n✅ Selected repository: ${path.relative(currentDir, selectedRepo) || '.'}`, 'green');
  
  // Get branches
  const branches = execGitCommand('git branch -a', selectedRepo);
  if (!branches) {
    log('\n❌ Failed to get branches.', 'red');
    rl.close();
    return;
  }
  
  const branchList = branches
    .split('\n')
    .map(b => b.trim())
    .filter(b => b && !b.includes('HEAD'))
    .map(b => b.replace(/^\* /, '').replace(/^remotes\//, ''));
  
  // Select branch
  const branchSelection = await selectFromList(
    branchList,
    '🌿 Select a branch:'
  );
  const selectedBranch = branchSelection.value;
  
  log(`\n✅ Selected branch: ${selectedBranch}`, 'green');
  
  // Checkout branch if needed
  const currentBranch = execGitCommand('git rev-parse --abbrev-ref HEAD', selectedRepo);
  if (currentBranch !== selectedBranch) {
    log(`\nSwitching to branch: ${selectedBranch}...`, 'dim');
    execGitCommand(`git checkout ${selectedBranch}`, selectedRepo);
  }
  
  // Get commits
  log('\nLoading commits...', 'dim');
  const commits = execGitCommand(
    'git log --oneline --graph --max-count=20',
    selectedRepo
  );
  
  if (!commits) {
    log('\n❌ Failed to get commits.', 'red');
    rl.close();
    return;
  }
  
  const commitList = commits.split('\n').filter(c => c.trim());
  
  // Select commit
  const commitSelection = await selectFromList(
    commitList,
    '📝 Select a commit to reset to:'
  );
  
  // Extract commit hash
  const commitHash = commitSelection.value.match(/[a-f0-9]{7,}/)?.[0];
  if (!commitHash) {
    log('\n❌ Could not extract commit hash.', 'red');
    rl.close();
    return;
  }
  
  // Confirm reset type
  log('\n⚠️  Select reset type:', 'yellow');
  log('1. Soft reset (keeps changes staged)', 'dim');
  log('2. Mixed reset (keeps changes unstaged) [default]', 'dim');
  log('3. Hard reset (discards all changes) ⚠️', 'dim');
  
  const resetType = await question('\nEnter choice (1-3) or press Enter for default: ');
  
  let resetCommand = `git reset `;
  switch (resetType) {
    case '1':
      resetCommand += '--soft ';
      break;
    case '3':
      resetCommand += '--hard ';
      break;
    default:
      resetCommand += '--mixed ';
  }
  resetCommand += commitHash;
  
  // Final confirmation
  log('\n📋 Summary:', 'bright');
  log(`Repository: ${path.relative(currentDir, selectedRepo) || '.'}`, 'dim');
  log(`Branch: ${selectedBranch}`, 'dim');
  log(`Commit: ${commitSelection.value}`, 'dim');
  log(`Command: ${resetCommand}`, 'dim');
  
  const confirm = await question(`\n⚠️  Are you sure you want to proceed? (y/N): `);
  
  if (confirm.toLowerCase() === 'y') {
    try {
      execSync(resetCommand, { cwd: selectedRepo, stdio: 'inherit' });
      log('\n✅ Reset completed successfully!', 'green');
      
      // Check if we're behind/ahead of remote after reset
      const remoteBranch = execGitCommand(`git rev-parse --abbrev-ref --symbolic-full-name @{u}`, selectedRepo);
      if (remoteBranch) {
        const status = execGitCommand('git status -sb', selectedRepo);
        
        if (status && (status.includes('[behind') || status.includes('[ahead'))) {
          log('\n⚠️  Your local branch has diverged from the remote branch.', 'yellow');
          
          if (resetType === '3') {
            log('\n🔄 Would you like to force push your local changes to overwrite the remote?', 'cyan');
            log('   This will replace the remote branch with your local version.', 'dim');
            log('   ⚠️  Warning: This cannot be undone and may affect other developers!', 'red');
            
            const forcePush = await question('\nForce push to remote? (y/N): ');
            
            if (forcePush.toLowerCase() === 'y') {
              try {
                log('\nForce pushing to remote...', 'dim');
                execSync(`git push --force-with-lease origin ${selectedBranch}`, { 
                  cwd: selectedRepo, 
                  stdio: 'inherit' 
                });
                log('\n✅ Force push completed successfully!', 'green');
                log('   Remote branch has been overwritten with your local changes.', 'dim');
              } catch (error) {
                log(`\n❌ Force push failed: ${error.message}`, 'red');
                log('   You may need to use: git push --force origin ' + selectedBranch, 'dim');
              }
            } else {
              log('\n📝 Note: Your local branch remains different from remote.', 'yellow');
              log('   To sync with remote later, you can:', 'dim');
              log('   - Force push: git push --force origin ' + selectedBranch, 'dim');
              log('   - Pull remote: git pull origin ' + selectedBranch, 'dim');
            }
          } else {
            log('\n📝 Note: Your local branch is different from remote.', 'yellow');
            log('   To sync, you can:', 'dim');
            log('   - Push changes: git push origin ' + selectedBranch, 'dim');
            log('   - Pull remote: git pull origin ' + selectedBranch, 'dim');
            log('   - Force push: git push --force origin ' + selectedBranch, 'dim');
          }
        }
      }
    } catch (error) {
      log(`\n❌ Reset failed: ${error.message}`, 'red');
    }
  } else {
    log('\n❌ Reset cancelled.', 'yellow');
  }
  
  rl.close();
}

main().catch(error => {
  log(`\n❌ Error: ${error.message}`, 'red');
  rl.close();
  process.exit(1);
});