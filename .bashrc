# ~/.bashrc

# Enable colorful ls and grep output
export CLICOLOR=1
export LS_COLORS='di=34:fi=0:ln=35:pi=33:so=32:bd=46:cd=43:ex=31'

# Helpful aliases
alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias cls='clear'

# Enable color for grep
alias grep='grep --color=auto'

# Make prompt user-friendly
PS1='\[\e[32m\]\u@\h\[\e[m\]:\[\e[34m\]\w\[\e[m\]\$ '

#Google from the command line
google() {
    search=""
    for i in "$@"; do
        search="$search%20$i"
    done
    echo "Searching Google for: $@"
    # Works for WSL, Linux (xdg-open), or macOS (open)
    xdg-open "http://www.google.com/search?q=$search" 2>/dev/null || open "http://www.google.com/search?q=$search"
}

# Only add to PATH if it isn't already there
if [[ ":$PATH:" != *":$(pwd)/bin:"* ]]; then
    export PATH="$PATH:$(pwd)/bin"
fi

./bin/repo.sh