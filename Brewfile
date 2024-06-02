# This file is used for `brew bundle` command to automate the  of my brew packages for my development environment.
# To  all the packages in this file, run `brew bundle` in the same directory as this file.
# For more information, see this guide (https://miguelcrespo.co/posts/automate-ation-and-configuration-of-macos/).

# Brew Bundle Documentation: https://github.com/Homebrew/homebrew-bundle

# Homebrew casks for additional formulas
tap 'homebrew/cask'
tap 'homebrew/cask-fonts'
tap 'hashicorp/tap'
tap "qmk/qmk"

# set arguments for all 'brew install --cask' commands
cask_args appdir: "~/Applications", require_sha: true

# Keyboard firmware
cask 'qmk-toolbox'
brew "qmk/qmk/qmk"

# Development tools
brew 'go'
brew 'nvm'
brew 'openjdk'
brew 'hugo'
brew 'dotnet@6'
cask 'docker'
brew "docker"
brew "docker-machine"
brew 'hashicorp/tap/terraform'
brew 'lftp'
brew "hugo"

# Text editors
cask 'visual-studio-code'

# Version control
brew 'git'
brew 'gh'

# Database tools
brew 'postgresql@15'
brew 'sqlite'

# Browsers
cask 'google-chrome'

# Communication tools
cask 'discord'
cask 'slack'

# Terminal tools
brew 'wget'
brew 'make'
cask 'warp'

# Productivity tools
cask 'nextcloud'
brew 'stow'

# Configuration tools
brew 'mas' # Mac App Store manager

# Mac App Store apps
mas 'Bear', id: 1091189122
mas 'Logic Pro X', id: 634148309
mas 'Tailscale', id: 1475387142
mas 'Apple Configurator 2', id: 1037126344
mas 'WhatsApp', id: 310633997
mas 'Final Cut Pro', id: 424389933
mas 'WireGuard', id: 1451685025
mas 'Magnet', id: 441258766
mas "Screens 5", id: 1663047912