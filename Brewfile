# This file is used for `brew bundle` command to automate the  of my brew packages for my development environment.
# To  all the packages in this file, run `brew bundle` in the same directory as this file.
# For more information, see this guide (https://miguelcrespo.co/posts/automate-ation-and-configuration-of-macos/).

# Brew Bundle Documentation: https://github.com/Homebrew/homebrew-bundle

# Homebrew casks for additional formulas
# tap 'homebrew/cask'
# tap 'homebrew/cask-fonts'
tap 'hashicorp/tap'
tap 'homebrew/bundle'

# set arguments for all 'cask' commands
cask_args appdir: '~/Applications', require_sha: true

# Keyboard firmware
tap 'qmk/qmk'
cask 'qmk-toolbox'
brew 'qmk/qmk/qmk'

# Development tools
brew 'go'
brew 'nvm'
brew 'openjdk'
brew 'hugo'
brew 'dotnet@6'
cask 'docker'
brew 'docker'
brew 'docker-machine'
cask 'docker', args: { appdir: '~/Applications' }
brew 'hashicorp/tap/terraform'
brew 'lftp'
brew 'hugo'
brew 'pillow'
brew 'libraqm'
brew 'hashicorp/tap/hcp'
brew 'yarn'
cask 'iterm2'
cask 'itermai'
cask 'parallels'

# Sys Admin Tools
tap 'powershell/tap'
brew 'powershell/tap/powershell'
brew 'wireshark'
cask 'paragon-extfs'
cask 'paragon-ntfs'

# Text editors
cask 'visual-studio-code', args: { appdir: '~/Applications' }

# Version control
brew 'git'
brew 'gh'
brew 'git-lfs'

# Database tools
brew 'postgresql@15'
brew 'sqlite'
cask 'dbeaver-community'
cask 'pgadmin4'

# Browsers
cask 'google-chrome'
cask 'firefox'

# Communication tools
cask 'discord', args: { appdir: '~/Applications' }
cask 'slack', args: { appdir: '~/Applications' }

# Terminal tools
brew 'wget'
brew 'make'
cask 'warp', args: { appdir: '~/Applications' }

# Productivity tools
brew 'stow'
cask 'zoom'
cask 'microsoft-office-businesspro'
cask 'cyberduck'
cask 'mullvadvpn'
cask 'obs'
cask '1password'
cask 'thunderbird'
cask 'notion

# Media tools
cask 'vlc'
brew 'handbrake'
cask 'imazing'
cask 'blender'
cask 'prusaslicer'

# Configuration tools
brew 'mas' # Mac App Store manager

# Mac App Store apps
mas '1Password for Safari', id: 1569813296
mas 'Apple Configurator', id: 1037126344
mas 'Final Cut Pro', id: 424389933
mas 'GarageBand', id: 682658836
mas 'iMovie', id: 408981434
mas 'Keynote', id: 409183694
mas 'Logic Pro', id: 634148309
mas 'Magnet', id: 441258766
mas 'Numbers', id: 409203825
mas 'Pages', id: 409201541
mas 'Screens 5', id: 1663047912
mas 'WireGuard', id: 1451685025
mas 'Keka', id: 470158793

#Internet Applications
cask 'steam'
cask 'duplicacy-web-edition'