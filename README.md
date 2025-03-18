# dot-files
My VIM/TMUX configurations

## Requirements
- tmux
- nvm (`mkdir /Users/XXX/.nvm`)
- pyenv

## Setup
1) `git clone https://github.com/VasilyShelkov/dot-files.git`

2) `cd dot-files`

3) make sure to change https://github.com/VasilyShelkov/dot-files/blob/master/.zshrc#L10 and https://github.com/VasilyShelkov/dot-files/blob/master/.zshrc#L77

5) `./setup.sh`

6) `gem install tmuxinator`

7) `git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim` to get the package manager working

8) vim .vimrc then `:PluginInstall`

9) restart terminal and voila

## Git Worktree Utilities

This repository includes powerful ZSH functions for managing Git worktrees, helping you work with multiple branches simultaneously without constant branch switching.

### Quick Installation (Worktree Utilities Only)

If you only want the Git worktree utilities without installing all dotfiles:

```bash
# 1. Create the directory if it doesn't exist
mkdir -p ~/.zsh_functions

# 2. Download the file
curl -o ~/.zsh_functions/git-worktree.zsh https://raw.githubusercontent.com/vasilyshelkov/dot-files/master/.zsh_functions/git-worktree.zsh

# 3. Add this line to your .zshrc
echo 'source ~/.zsh_functions/git-worktree.zsh' >> ~/.zshrc

# 4. Apply the change to your current shell
source ~/.zshrc
```

### Available Commands

#### `wtree` - Create new worktrees easily
- `wtree feature-branch` - Creates a worktree at ~/dev/[repo]-feature-branch
- `wtree -p feature-branch` - Also runs "pnpm install" after creation
- `wtree -n feature-branch` - Skip copying .env files
- `wtree -q feature-branch` - Minimal output mode
- Automatically checks for remote branches with the same name

#### `wtls` - List and clean up worktrees
- `wtls` - List all worktrees with status (shows ahead/behind, unique commits)
- `wtls -c` - Automatic cleanup mode for all non-main worktrees
- `wtls -c -y` - Cleanup without confirmation prompts (use carefully!)

#### `wtmerge` - Merge changes from a worktree into main
- `wtmerge feature-branch` - Merges and keeps other worktrees
- `wtmerge feature-branch --cleanup-all` - Merges and removes all worktrees

### Use Cases

- Run E2E tests on a feature branch while continuing work on another branch
- Quickly respond to PR feedback without interrupting current work
- Run multiple composer/npm tasks in separate branches simultaneously  
- Create exploratory branches that don't pollute your main workspace
- Keep long-running feature work isolated in separate directories

### Features

- **Special Character Support**: Works with branches like `feature/branch-name` or `hotfix/fix-name`
- **Environment File Copying**: Automatically copies .env files to new worktrees
- **Status Reporting**: See which branches have unpushed changes or are ahead/behind main
- **One-command Cleanup**: Easily remove multiple worktrees when you're done
