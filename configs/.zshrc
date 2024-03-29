# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && . "$HOME/.fig/shell/zshrc.pre.zsh"
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/stephonparker/.oh-my-zsh"

#################
# GOLANG CONFIG #
#################

export GOPATH=$HOME/go
export GOROOT="$(brew --prefix golang)/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"


#######################
# GOOGLE SDK SETTINGS #
#######################

# source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
# source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"

#################
# JAVA SETTINGS #
#################

# export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
# export CPPFLAGS="-I/opt/homebrew/opt/openjdk/include"

####################
# GITHUB SETTINGS  #
####################

export GONOPROXY="github.com/nytm/*,github.com/NYTimes/*,github.com/nytimes/*"
export GOPRIVATE="github.com/nytm/*,github.com/NYTimes/*,github.com/nytimes/*"
export GITHUB_TOKEN=""

####################
# NODE/NPM SETTINGS #
####################

# export LDFLAGS="-L/opt/homebrew/opt/node@12/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/node@12/include"
# export PATH="/opt/homebrew/opt/node@12/bin:$PATH"

####################
#  DOCKER SETTINGS #
####################

# export DOCKER_DEFAULT_PLATFORM=linux/amd64
# export DOCKER_BUILDKIT=0 
# export COMPOSE_DOCKER_CLI_BUILD=0

####################
#  PODMAN SETTINGS #
####################

alias pms="podman machine start"

######################
#  MINIKUBE SETTINGS #
######################

alias mksp="minikube start --driver=podman"
alias mksd="minikube start --driver=docker"
alias mkd="minikube delete"
alias mks="minikube stop"
alias mkdh="minikube dashboard"
alias mkda="minikube delete --all --purge"

#####################
#  KUBECTL SETTINGS #
#####################

alias kbpo="kubectl get po -A"

####################
#       ALIAS      #
####################

alias dcb="DOCKER_DEFAULT_PLATFORM=linux/amd64 docker-compose build"
alias dcba="DOCKER_DEFAULT_PLATFORM=linux/amd64 docker-compose build app-silicon"
alias dcu="docker-compose up -d app-silicon"
alias dcd="docker-compose down"
alias awslogin="aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 080387373610.dkr.ecr.us-east-1.amazonaws.com"
alias shell="exec zsh -l"
alias und="unset DOCKER_DEFAULT_PLATFORM"

####################
#   AWS SETTINGS   #
####################

# export AWS_PROFILE=
# export AWS_ACCESS_KEY_ID=
# export AWS_SECRET_ACCESS_KEY=

####################
#    HUGO ALIAS    #
####################

alias hsd="hugo server -D"
alias hs="hugo serve"
alias hnp="hugo new posts"
alias hsr="hugo server --disableFastRender"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="arrow"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && . "$HOME/.fig/shell/zshrc.post.zsh"
