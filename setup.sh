#!/bin/bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define colors for better output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize arrays to track results
successful_links=()
skipped_links=()
backup_created=()
failed_links=()

echo -e "${BLUE}Setting up dotfiles from: ${BASEDIR}${NC}"
echo "======================="

# Function to safely create a symbolic link
create_symlink() {
    local source_file="$1"
    local target_file="$2"
    local file_description="$3"
   
    # Check if the target file exists and is a symlink
    if [ -L "${target_file}" ]; then
        echo -e "${YELLOW}⟳ Updating:${NC} ${file_description}"
        rm "${target_file}"
    # Check if it's a regular file or directory
    elif [ -e "${target_file}" ]; then
        echo -e "${YELLOW}⚠ Backing up:${NC} ${file_description} → ${target_file}.backup"
        if mv "${target_file}" "${target_file}.backup"; then
            backup_created+=("${file_description}")
        else
            echo -e "${RED}✗ Failed to back up:${NC} ${target_file}"
            failed_links+=("${file_description}")
            return 1
        fi
    else
        echo -e "${BLUE}+ Creating:${NC} ${file_description}"
    fi
   
    # Create the symbolic link
    if ln -s "${source_file}" "${target_file}"; then
        successful_links+=("${file_description}")
        return 0
    else
        echo -e "${RED}✗ Failed to link:${NC} ${source_file} → ${target_file}"
        failed_links+=("${file_description}")
        return 1
    fi
}

# Create all necessary directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p "${HOME}/.zsh_functions"

# Install ZSH plugins if missing
echo -e "${BLUE}Setting up ZSH plugins...${NC}"
ZSH_CUSTOM="${HOME}/.oh-my-zsh/custom"

# Install zsh-syntax-highlighting if missing
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
    echo -e "${BLUE}Installing zsh-syntax-highlighting...${NC}"
    if git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"; then
        successful_links+=("ZSH syntax highlighting plugin")
        echo -e "${GREEN}✓ Installed:${NC} zsh-syntax-highlighting plugin"
    else
        echo -e "${RED}✗ Failed to install:${NC} zsh-syntax-highlighting plugin"
        failed_links+=("ZSH syntax highlighting plugin")
    fi
else
    echo -e "${YELLOW}⟳ Already installed:${NC} zsh-syntax-highlighting plugin"
    skipped_links+=("ZSH syntax highlighting plugin")
fi

# ZSH
create_symlink "${BASEDIR}/.zshrc" "${HOME}/.zshrc" "ZSH configuration (.zshrc)"

# Vim
create_symlink "${BASEDIR}/.vimrc" "${HOME}/.vimrc" "Vim configuration (.vimrc)"

# Tmux
create_symlink "${BASEDIR}/.tmux.conf" "${HOME}/.tmux.conf" "Tmux configuration (.tmux.conf)"
create_symlink "${BASEDIR}/.tmuxinator.zsh" "${HOME}/.tmuxinator.zsh" "Tmuxinator for ZSH (.tmuxinator.zsh)"

# ZSH Functions
create_symlink "${BASEDIR}/.zsh_functions/git-worktree.zsh" "${HOME}/.zsh_functions/git-worktree.zsh" "Git worktree utilities (git-worktree.zsh)"

# Display final summary
echo ""
echo -e "${BLUE}=== Setup Summary ===${NC}"
echo ""

if [ ${#successful_links[@]} -gt 0 ]; then
    echo -e "${GREEN}Successfully configured:${NC}"
    for item in "${successful_links[@]}"; do
        echo -e "  ${GREEN}✓${NC} $item"
    done
    echo ""
fi

if [ ${#skipped_links[@]} -gt 0 ]; then
    echo -e "${YELLOW}Already installed:${NC}"
    for item in "${skipped_links[@]}"; do
        echo -e "  ${YELLOW}⟳${NC} $item"
    done
    echo ""
fi

if [ ${#backup_created[@]} -gt 0 ]; then
    echo -e "${YELLOW}Backups created for:${NC}"
    for item in "${backup_created[@]}"; do
        echo -e "  ${YELLOW}⚠${NC} $item"
    done
    echo ""
fi

if [ ${#failed_links[@]} -gt 0 ]; then
    echo -e "${RED}Failed to configure:${NC}"
    for item in "${failed_links[@]}"; do
        echo -e "  ${RED}✗${NC} $item"
    done
    echo ""
    echo -e "${RED}Please check the errors above and try again.${NC}"
    exit 1
else
    echo -e "${GREEN}All dotfiles were configured successfully!${NC}"
    echo -e "To apply changes in your current shell, run: ${YELLOW}source ~/.zshrc${NC}"
fi