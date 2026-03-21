# =================================================================
# Master Config: Shared between Bash and Zsh
# Location: ~/Desktop/GitHub/Security Sentinel -IT135/.bashrc
# =================================================================

# --- 1. Environment & Colors ---
export CLICOLOR=1
export LS_COLORS='di=34:fi=0:ln=35:pi=33:so=32:bd=46:cd=43:ex=31'
alias grep='grep --color=auto'

# --- 2. Helpful Aliases ---
alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias cls='clear'

# --- 3. The "Google" Function ---
google() {
    local search=""
    for i in "$@"; do
        search="$search%20$i"
    done
    echo "Searching Google for: $*"
    open "http://www.google.com/search?q=$search" 2>/dev/null || xdg-open "http://www.google.com/search?q=$search"
}

# --- 4. Path & Project Helpers ---
# Use the absolute path so it works from ANY directory
PROJECT_ROOT="$HOME/Desktop/GitHub/Security Sentinel -IT135"

# Add your project bin to the PATH securely
case ":$PATH:" in
    *":$PROJECT_ROOT/bin:"*) ;;
    *) export PATH="$PATH:$PROJECT_ROOT/bin" ;;
esac

# Source your git helper script
if [ -f "$PROJECT_ROOT/bin/repo.sh" ]; then
    source "$PROJECT_ROOT/bin/repo.sh"
fi

# --- 5. Cross-Shell Prompt Logic ---
if [ -n "$ZSH_VERSION" ]; then
    # Zsh specific prompt (uses % instead of \)
    PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '
elif [ -n "$BASH_VERSION" ]; then
    # Bash specific prompt
    export PS1="\[\e[32m\]\u@\h\[\e[m\]:\[\e[34m\]\w\[\e[m\]\$ "
fi