# wtree: Create a new worktree for each given branch.
# Usage: wtree [ -p|--pnpm ] [ -n|--no-env ] [ -q|--quiet ] branch1 branch2 ...
#
# Options:
#   -p, --pnpm: Run "pnpm install" in the new worktree after creating it
#   -n, --no-env: Skip copying environment files from the main repository
#   -q, --quiet: Show minimal output (only errors and final path)
#
# This function does the following:
#   1. Parses command-line arguments.
#   2. Determines the current branch and repository root.
#   3. Uses a fixed parent directory (~/dev) to house all worktree directories.
#   4. For each branch passed:
#        - If the branch does not exist locally:
#          - Checks if a remote branch with the same name exists and sets up tracking
#          - If no remote branch exists, creates a new branch from the current branch
#        - It checks that a worktree for that branch does not already exist.
#        - It then creates a worktree in ~/dev using a naming convention: <repoName>-<branch>.
#        - It copies all environment files (.env*) from the main repository to the new worktree.
#        - If the --pnpm flag is set, it runs "pnpm install" inside the new worktree.
#        - Finally, it either opens the new worktree via the custom "cursor" command (if defined)
#          or prints its path.
wtree() {
  # Flags for optional behavior
  local install_deps=false
  local copy_env=true
  local quiet_mode=false
  local branches=()

  # Parse command-line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--pnpm)
        install_deps=true
        shift
        ;;
      -n|--no-env)
        copy_env=false
        shift
        ;;
      -q|--quiet)
        quiet_mode=true
        shift
        ;;
      *)
        branches+=("$1")
        shift
        ;;
    esac
  done

  # Ensure at least one branch name is provided.
  if [[ ${#branches[@]} -eq 0 ]]; then
    echo "Usage: wtree [ -p|--pnpm ] [ -n|--no-env ] [ -q|--quiet ] branch1 branch2 ..."
    echo "  -p, --pnpm: Run \"pnpm install\" in the new worktree"
    echo "  -n, --no-env: Skip copying environment files"
    echo "  -q, --quiet: Show minimal output"
    return 1
  fi

  # Determine the current branch; exit if not in a git repository.
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD) || {
    echo "Error: Not a git repository."
    return 1
  }

  # Determine repository root and name.
  local repo_root repo_name
  repo_root=$(git rev-parse --show-toplevel) || {
    echo "Error: Cannot determine repository root."
    return 1
  }
  repo_name=$(basename "$repo_root")

  # Set fixed parent directory for worktrees.
  local worktree_parent="$HOME/dev"
  # Ensure the worktree parent directory exists.
  if [[ ! -d "$worktree_parent" ]]; then
    if ! mkdir -p "$worktree_parent"; then
      echo "Error: Failed to create worktree parent directory: $worktree_parent"
      return 1
    fi
  fi

  # Loop over each branch provided as argument.
  for branch in "${branches[@]}"; do
    # Define the target path using a naming convention: <repoName>-<branch>
    local target_path="$worktree_parent/${repo_name}-${branch}"
    
    if ! $quiet_mode; then
      echo "\033[1;36m→ Processing branch: \033[1;33m${branch}\033[0m"
    fi

    # Check if a worktree already exists at the target path.
    if git worktree list | grep -q "^${target_path}[[:space:]]"; then
      echo "\033[1;31m✖ Worktree already exists at ${target_path}\033[0m"
      continue
    fi

    # If the branch does not exist, check for a remote branch
    if ! git show-ref --verify --quiet "refs/heads/${branch}"; then
      # Check if a remote branch with the same name exists
      if git ls-remote --exit-code --heads origin "${branch}" &>/dev/null; then
        if ! $quiet_mode; then
          echo "\033[1;34m↓ Found remote branch 'origin/${branch}', setting up tracking...\033[0m"
        fi
        
        if ! git fetch origin "${branch}" 2>/dev/null; then
          echo "\033[1;31m✖ Failed to fetch 'origin/${branch}'\033[0m"
          continue
        fi
        
        if ! git branch --track "${branch}" "origin/${branch}" 2>/dev/null; then
          echo "\033[1;31m✖ Failed to create tracking branch\033[0m"
          continue
        fi
        
        if ! $quiet_mode; then
          echo "\033[1;32m✓ Tracking branch created\033[0m"
        fi
      else
        # No remote branch exists, create from current branch
        if ! $quiet_mode; then
          echo "\033[1;34mℹ Creating new branch from '${current_branch}'...\033[0m"
        fi
        
        if ! git branch "${branch}" 2>/dev/null; then
          echo "\033[1;31m✖ Failed to create branch '${branch}'\033[0m"
          continue
        fi
      fi
    fi

    # Create the new worktree for the branch.
    if ! $quiet_mode; then
      echo "\033[1;34mℹ Creating worktree...\033[0m"
    fi
    
    if ! git worktree add "$target_path" "${branch}" &>/dev/null; then
      echo "\033[1;31m✖ Failed to create worktree\033[0m"
      continue
    fi

    # Copy all .env files recursively from the main repository to the new worktree
    if $copy_env; then
      # Find all .env* files in the main repository (including .env, .env.local, .env.development, etc.)
      local env_files=()
      while IFS= read -r -d '' file; do
        # Skip files in node_modules, .git, and other common directories to exclude
        if [[ "$file" != *"node_modules"* && "$file" != *".git"* && "$file" != *"dist"* && "$file" != *"build"* ]]; then
          env_files+=("$file")
        fi
      done < <(find "$repo_root" -type f -name ".env*" -print0 2>/dev/null)
      
      if [[ ${#env_files[@]} -gt 0 ]]; then
        if ! $quiet_mode; then
          echo "\033[1;34mℹ Copying environment files...\033[0m"
        fi
        
        local copied_count=0
        local skipped_count=0
        
        for env_file in "${env_files[@]}"; do
          # Get the relative path from the repo root
          local rel_path="${env_file#$repo_root/}"
          # Create the target directory if it doesn't exist
          local target_dir="$target_path/$(dirname "$rel_path")"
          local target_file="$target_dir/$(basename "$env_file")"
          
          # Check if the file already exists in the target
          if [[ -f "$target_file" ]]; then
            skipped_count=$((skipped_count + 1))
            continue
          fi
          
          # Create directory if needed
          if [[ ! -d "$target_dir" ]]; then
            if ! mkdir -p "$target_dir" &>/dev/null; then
              skipped_count=$((skipped_count + 1))
              continue
            fi
          fi
          
          # Copy the file
          if cp "$env_file" "$target_file" &>/dev/null; then
            copied_count=$((copied_count + 1))
          else
            skipped_count=$((skipped_count + 1))
          fi
        done
        
        if ! $quiet_mode; then
          echo "\033[1;32m✓ Environment files: \033[0m\033[1;33m$copied_count\033[0m copied, \033[1;30m$skipped_count\033[0m skipped"
        fi
      else
        if ! $quiet_mode; then
          echo "\033[1;33m⚠ No environment files found\033[0m"
        fi
      fi
    fi

    # If the install flag is set, run "pnpm install" in the new worktree.
    if $install_deps; then
      if ! $quiet_mode; then
        echo "\033[1;34mℹ Installing dependencies...\033[0m"
      fi
      
      if ! ( cd "$target_path" && pnpm install &>/dev/null ); then
        echo "\033[1;31m✖ Failed to install dependencies\033[0m"
      elif ! $quiet_mode; then
        echo "\033[1;32m✓ Dependencies installed\033[0m"
      fi
    fi

    # Display result
    echo "\033[1;32m✅ Worktree created:\033[0m \033[1;33m${branch}\033[0m → \033[1;36m${target_path}\033[0m"

    # Optionally, open the worktree directory via a custom "cursor" command if available.
    if type cursor >/dev/null 2>&1; then
      cursor "$target_path" &>/dev/null
    fi
  done
}

# wtls: List and optionally clean up selected git worktrees
#
# Usage: wtls [-n|--no-status] [-d|--debug]
#
# Options:
#   -n, --no-status: Hide git status for each worktree (uncommitted changes, etc.)
#   -d, --debug: Show detailed debug output about worktree detection
#
# This function:
#   1. Lists all worktrees in the ~/dev directory related to the current repository
#   2. Shows git status information for each worktree by default
#   3. Allows the user to select which worktrees to clean up by entering branch names
#   4. Deletes the selected worktrees and their branches (except main/master)
wtls() {
  # Parse command-line arguments
  local debug=false
  local show_status=true # Default to showing status
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--debug)
        debug=true
        shift
        ;;
      -n|--no-status)
        show_status=false
        shift
        ;;
      -s|--status) # Keep for backward compatibility
        show_status=true
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  # Determine repository root and name
  local repo_root repo_name
  repo_root=$(git rev-parse --show-toplevel) || {
    echo "Error: Not a git repository."
    return 1
  }
  repo_name=$(basename "$repo_root")

  if $debug; then
    echo "DEBUG: Repository root: $repo_root"
    echo "DEBUG: Repository name: $repo_name"
  fi

  # Fixed parent directory where worktrees are located
  local worktree_parent="$HOME/dev"

  # Get current worktree path to mark it
  local current_worktree
  current_worktree=$(git rev-parse --show-toplevel)
  
  echo "Gathering worktree information..."
  
  # Get worktrees from git worktree list
  local git_worktree_output
  git_worktree_output=$(git worktree list)
  
  # Show raw data in debug mode
  if $debug; then
    echo "DEBUG: Raw git worktree list output:"
    echo "$git_worktree_output"
    echo "DEBUG: Current worktree: $current_worktree"
    echo "---"
  fi
  
  # Print header for worktree list
  echo "\033[1;36m=== Worktrees for repository '$repo_name' ===\033[0m"
  echo "\033[1;30m----------------------------------------------------------\033[0m"
  
  # Initialize counters
  local main_count=0
  local worktree_count=0
  
  # Print the main repository first
  local main_branch=$(git rev-parse --abbrev-ref HEAD)
  echo "\033[1;32m[MAIN]\033[0m \033[1;33m$main_branch\033[0m (current)"
  echo "    Path: $repo_root"
  main_count=1
  
  # Process git worktree list output
  while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue
    
    # Extract the worktree path (first field)
    local wt_path=$(echo "$line" | awk '{print $1}')
    
    if $debug; then
      echo "Processing line: $line"
      echo "wt_path: $wt_path"
    fi
    
    # Skip empty paths
    [[ -z "$wt_path" ]] && continue
    
    # Skip the main repository (already displayed)
    [[ "$wt_path" == "$repo_root" ]] && continue
    
    # Extract branch from square brackets [branch]
    local wt_branch=""
    if [[ "$line" =~ \[([^]]+)\] ]]; then
      wt_branch="${BASH_REMATCH[1]}"
      if $debug; then echo "Branch from regex: $wt_branch"; fi
    else
      # Try to get branch from git
      if [[ -d "$wt_path/.git" || -f "$wt_path/.git" ]]; then
        wt_branch=$(cd "$wt_path" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if $debug; then echo "Branch from git: $wt_branch"; fi
      fi
      
      # If still no branch, use directory name
      if [[ -z "$wt_branch" ]]; then
        local dir_name=$(basename "$wt_path")
        if [[ "$dir_name" == "$repo_name-"* ]]; then
          wt_branch="${dir_name#$repo_name-}"
          if $debug; then echo "Branch from directory name: $wt_branch"; fi
        else
          wt_branch="unknown"
        fi
      fi
    fi
    
    # Skip main/master branches
    if [[ "$wt_branch" == "main" || "$wt_branch" == "master" ]]; then
      if $debug; then echo "Skipping protected branch: $wt_branch"; fi
      main_count=$((main_count + 1))
      continue
    fi
    
    # Add this worktree if it's in our dev directory
    if [[ "$wt_path" == "$worktree_parent/$repo_name"* ]]; then
      # Mark if current
      local marker=""
      [[ "$wt_path" == "$current_worktree" ]] && marker=" (current)"
      
      # Check status if requested
      local wt_state="state not checked"
      if $show_status; then
        if [[ -d "$wt_path" ]]; then
          if $debug; then
            echo "DEBUG: Checking status for '$wt_branch' at '$wt_path'"
          fi

          # First check for uncommitted changes
          if ( cd "$wt_path" && git diff --no-ext-diff --quiet --exit-code && git diff --no-ext-diff --quiet --exit-code --cached ); then
            # No uncommitted changes
            if $debug; then
              echo "DEBUG: No uncommitted changes"
            fi
            
            # Check if current worktree has unique commits compared to main worktree
            # Get the commit hash of the main worktree
            local main_commit=$(cd "$repo_root" && git rev-parse HEAD)
            # Get the commit hash of this worktree
            local wt_commit=$(cd "$wt_path" && git rev-parse HEAD)
            
            if $debug; then
              echo "DEBUG: Main commit: $main_commit"
              echo "DEBUG: Worktree commit: $wt_commit"
            fi
            
            if [[ "$main_commit" != "$wt_commit" ]]; then
              # Commits are different, this branch has unique changes
              if $debug; then
                echo "DEBUG: Commits are different"
              fi
              
              # Get the merge base to see which is ahead
              local merge_base=$(cd "$wt_path" && git merge-base "$main_commit" "$wt_commit")
              if $debug; then
                echo "DEBUG: Merge base: $merge_base"
              fi
              
              if [[ "$merge_base" == "$main_commit" ]]; then
                # Main is an ancestor of the worktree, so worktree is ahead
                local ahead_count=$(cd "$wt_path" && git rev-list --count "$main_commit..$wt_commit")
                wt_state="\033[1;33m✨ $ahead_count new commit(s)\033[0m"
                if $debug; then
                  echo "DEBUG: Worktree is ahead of main by $ahead_count commits"
                fi
              elif [[ "$merge_base" == "$wt_commit" ]]; then
                # Worktree is an ancestor of main, so worktree is behind
                local behind_count=$(cd "$wt_path" && git rev-list --count "$wt_commit..$main_commit")
                wt_state="\033[1;36m⬇️ behind main by $behind_count commit(s)\033[0m"
                if $debug; then
                  echo "DEBUG: Worktree is behind main by $behind_count commits"
                fi
              else
                # They have diverged
                local ahead_count=$(cd "$wt_path" && git rev-list --count "$merge_base..$wt_commit")
                local behind_count=$(cd "$wt_path" && git rev-list --count "$merge_base..$main_commit")
                wt_state="\033[1;33m🔀 diverged from main\033[0m"
                if $debug; then
                  echo "DEBUG: Worktree has diverged: ahead $ahead_count, behind $behind_count"
                fi
              fi
            else
              wt_state="\033[1;32m✓ identical to main\033[0m"
              if $debug; then
                echo "DEBUG: Commits are identical"
              fi
            fi
            
            # Check for remote status
            if ( cd "$wt_path" && git ls-remote --exit-code --heads origin "$wt_branch" &>/dev/null ); then
              if $debug; then
                echo "DEBUG: Branch exists on remote"
              fi
              
              # Check if we're ahead/behind remote
              local ahead_count=$(cd "$wt_path" && git rev-list --count "origin/$wt_branch..$wt_branch" 2>/dev/null || echo "0")
              local behind_count=$(cd "$wt_path" && git rev-list --count "$wt_branch..origin/$wt_branch" 2>/dev/null || echo "0")
              
              if [[ $ahead_count -gt 0 ]]; then
                wt_state="$wt_state \033[1;33m(unpushed changes ↑)\033[0m"
              fi
            else
              if [[ "$wt_state" != "\033[1;32m✓ identical to main\033[0m" ]]; then
                wt_state="$wt_state \033[1;30m(local only)\033[0m"
              else
                wt_state="\033[1;32m✓ clean\033[0m \033[1;30m(local only)\033[0m"
              fi
            fi
          else
            # Has uncommitted changes
            if ( cd "$wt_path" && git diff --no-ext-diff --quiet --exit-code ); then
              wt_state="\033[1;31m⚠️ staged changes\033[0m"
            else
              wt_state="\033[1;31m⚠️ uncommitted changes\033[0m"
            fi
            if $debug; then
              echo "DEBUG: Has changes: $wt_state"
            fi
          fi
        else
          wt_state="\033[1;37m⚠️ directory not accessible\033[0m"
          if $debug; then
            echo "DEBUG: Directory not accessible"
          fi
        fi
      fi
      
      # Display the worktree with improved formatting
      if $show_status; then
        echo "\033[1;34m[$wt_branch]\033[0m \033[1;33m$wt_branch\033[0m$marker - $wt_state"
      else
        echo "\033[1;34m[$wt_branch]\033[0m \033[1;33m$wt_branch\033[0m$marker"
      fi
      echo "    Path: $wt_path"
      
      worktree_count=$((worktree_count + 1))
      
      if $debug; then
        echo "Added worktree: $wt_path ($wt_branch) - $wt_state"
      fi
    fi
  done <<< "$git_worktree_output"
  
  # Show total count
  echo "\033[1;30m----------------------------------------------------------\033[0m"
  echo "Found $main_count main worktree(s) and $worktree_count additional worktree(s)"
  
  # Exit if no additional worktrees found
  if [[ $worktree_count -eq 0 ]]; then
    echo "No additional worktrees found for cleanup."
    return 0
  fi
  
  # Prompt for cleanup with clearer instructions
  echo "\033[1;30m----------------------------------------------------------\033[0m"
  echo "\033[1;36mTo clean up worktrees, enter the branch names shown in [brackets].\033[0m"
  echo "\033[1;36mExample: to remove [test-wt], type 'test-wt'\033[0m"
  echo "Enter branch names to clean up (space-separated), or press Enter to exit:"
  read -r selection
  
  if [[ -z "$selection" ]]; then
    echo "No worktrees selected for cleanup. Exiting."
    return 0
  fi
  
  # Process selection
  for branch in $selection; do
    # Skip if empty
    [[ -z "$branch" ]] && continue
    
    # Skip main/master
    if [[ "$branch" == "main" || "$branch" == "master" ]]; then
      echo "\033[1;31mCannot remove main/master branch. Skipping.\033[0m"
      continue
    fi
    
    # Find the worktree path for this branch
    local branch_path=""
    
    # Use a more reliable method to extract the path from git worktree list output
    while IFS= read -r line; do
      # Only process lines that have our branch name in brackets
      if [[ "$line" =~ \[([^]]+)\] && "${BASH_REMATCH[1]}" == "$branch" ]]; then
        # Extract path (first field) by trimming everything after the first space
        branch_path="${line%% *}"
        break
      fi
    done <<< "$git_worktree_output"
    
    # If not found in git worktree list, try looking in the dev directory
    if [[ -z "$branch_path" ]]; then
      local potential_path="$worktree_parent/$repo_name-$branch"
      if [[ -d "$potential_path" ]]; then
        branch_path="$potential_path"
      fi
    fi
    
    # Skip if not found
    if [[ -z "$branch_path" ]]; then
      echo "\033[1;31mNo worktree found for branch '$branch'. Skipping.\033[0m"
      continue
    fi
    
    # Skip if it's the current worktree
    if [[ "$branch_path" == "$current_worktree" ]]; then
      echo "\033[1;31mCannot remove current worktree at $branch_path. Skipping.\033[0m"
      continue
    fi
    
    echo "\033[1;36mCleaning up worktree for branch '$branch' at $branch_path...\033[0m"
    
    # Check for changes
    if $show_status; then
      if ! ( cd "$branch_path" && git diff --no-ext-diff --quiet --exit-code && git diff --no-ext-diff --quiet --exit-code --cached ); then
        echo "\033[1;33mWarning: This worktree has uncommitted changes.\033[0m"
        read -q "REPLY?Are you sure you want to remove it? (y/n) "
        echo
        
        if [[ $REPLY != "y" ]]; then
          echo "Skipping worktree for branch '$branch'."
          continue
        fi
      fi
    fi
    
    # Remove the worktree
    if git worktree remove "$branch_path" --force; then
      echo "\033[1;32mWorktree at $branch_path removed.\033[0m"
      
      # Delete the branch
      echo "Deleting branch '$branch'..."
      if git branch -D "$branch"; then
        echo "\033[1;32mBranch '$branch' deleted.\033[0m"
      else
        echo "\033[1;33mWarning: Failed to delete branch '$branch'.\033[0m"
      fi
    else
      echo "\033[1;33mWarning: Failed to remove worktree at $branch_path.\033[0m"
      
      # Try manual removal
      echo "Attempting manual directory removal..."
      if rm -rf "$branch_path"; then
        echo "\033[1;32mDirectory $branch_path manually removed.\033[0m"
      else
        echo "\033[1;31mError: Failed to manually remove directory $branch_path.\033[0m"
      fi
    fi
  done
  
  echo "\033[1;32mCleanup complete.\033[0m"
}


# wtmerge: Merge changes from a specified worktree branch into main.
#
# Usage: wtmerge <branch-to-keep> [--cleanup-all]
#
# This function does the following:
#   1. Verifies that the branch to merge (branch-to-keep) exists as an active worktree.
#   2. Checks for uncommitted changes in that worktree:
#        - If changes exist, it attempts to stage and commit them.
#        - It gracefully handles the situation where there are no changes.
#   3. Switches the current (main) worktree to the "main" branch.
#   4. Merges the specified branch into main, with proper error checking.
#   5. If --cleanup-all flag is provided, it removes all worktrees and deletes their branches (except main).
wtmerge() {
  # Parse arguments - check if we should cleanup all worktrees
  local branch_to_keep=""
  local cleanup_all=false
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --cleanup-all)
        cleanup_all=true
        shift
        ;;
      *)
        branch_to_keep="$1"
        shift
        ;;
    esac
  done

  # Ensure branch name is provided
  if [ -z "$branch_to_keep" ]; then
    echo "Usage: wtmerge <branch-to-keep> [--cleanup-all]"
    echo "  --cleanup-all: Also remove all worktrees and their branches after merging"
    return 1
  fi

  # Determine the repository root and its name.
  local repo_root repo_name
  repo_root=$(git rev-parse --show-toplevel) || {
    echo "Error: Not a git repository."
    return 1
  }
  repo_name=$(basename "$repo_root")

  # Fixed parent directory where worktrees are located.
  local worktree_parent="$HOME/dev"

  # Retrieve all active worktrees (from git worktree list) that match our naming convention.
  local worktrees=()
  while IFS= read -r line; do
    # Extract the worktree path (first field)
    local wt_path
    wt_path=$(echo "$line" | awk '{print $1}')
    # Only consider worktrees under our fixed parent directory that match "<repo_name>-*"
    if [[ "$wt_path" == "$worktree_parent/${repo_name}-"* ]]; then
      worktrees+=("$wt_path")
    fi
  done < <(git worktree list)

  # Check that the target branch worktree exists.
  local target_worktree=""
  for wt in "${worktrees[@]}"; do
    if [[ "$wt" == "$worktree_parent/${repo_name}-${branch_to_keep}" ]]; then
      target_worktree="$wt"
      break
    fi
  done

  if [[ -z "$target_worktree" ]]; then
    echo "Error: No active worktree found for branch '${branch_to_keep}' under ${worktree_parent}."
    return 1
  fi

  # Step 1: In the target worktree, check for uncommitted changes.
  echo "Checking for uncommitted changes in worktree for branch '${branch_to_keep}'..."
  if ! ( cd "$target_worktree" && git diff --quiet && git diff --cached --quiet ); then
    echo "Changes detected in branch '${branch_to_keep}'. Attempting auto-commit..."
    if ! ( cd "$target_worktree" &&
            git add . &&
            git commit -m "chore: auto-commit changes in '${branch_to_keep}' before merge" ); then
      echo "Error: Auto-commit failed in branch '${branch_to_keep}'. Aborting merge."
      return 1
    else
      echo "Auto-commit successful in branch '${branch_to_keep}'."
    fi
  else
    echo "No uncommitted changes found in branch '${branch_to_keep}'."
  fi

  # Step 2: Switch to the main worktree (assumed to be the current directory) and check out main.
  echo "Switching to 'main' branch in the main worktree..."
  if ! git checkout main; then
    echo "Error: Failed to switch to 'main' branch."
    return 1
  fi

  # Step 3: Merge the target branch into main.
  echo "Merging branch '${branch_to_keep}' into 'main'..."
  if ! git merge "${branch_to_keep}" -m "feat: merge changes from '${branch_to_keep}'"; then
    echo "Error: Merge failed. Please resolve conflicts and try again."
    return 1
  fi

  echo "Successfully merged branch '${branch_to_keep}' into 'main'."

  # Step 4: Clean up worktrees only if --cleanup-all flag is provided
  if $cleanup_all; then
    echo "Cleanup flag detected. Cleaning up worktrees and deleting temporary branches..."
    for wt in "${worktrees[@]}"; do
      # Extract branch name from worktree path.
      local wt_branch
      wt_branch=$(basename "$wt")
      wt_branch=${wt_branch#${repo_name}-}  # Remove the repo name prefix

      echo "Processing worktree for branch '${wt_branch}' at ${wt}..."
      # Remove the worktree using --force to ensure removal.
      if git worktree remove "$wt" --force; then
        echo "Worktree at ${wt} removed."
      else
        echo "Warning: Failed to remove worktree at ${wt}."
      fi

      # Do not delete the 'main' branch.
      if [[ "$wt_branch" != "main" ]]; then
        if git branch -D "$wt_branch"; then
          echo "Branch '${wt_branch}' deleted."
        else
          echo "Warning: Failed to delete branch '${wt_branch}'."
        fi
      fi
    done
    echo "Merge and cleanup complete: Branch '${branch_to_keep}' merged into 'main', and all worktrees cleaned up."
  else
    echo "Merge complete: Branch '${branch_to_keep}' merged into 'main'. Other worktrees preserved."
  fi
} 