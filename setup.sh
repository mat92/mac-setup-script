#!/bin/bash

brews=(
  bash
  caskroom/cask/brew-cask
  dfc
  git
  git-extras
  htop-osx
  mackup
  macvim
  mtr
  node
  nmap
  python
  ruby
  scala
  sbt
  tmux
  wget
  zsh
)

casks=(
  airdroid
  asepsis
  atom
  betterzipql
  cakebrew
  chromecast
  cleanmymac
  dropbox
  google-chrome
  google-drive
  github
  hosts
  firefox
  intellij-idea
  istat-menus
  istat-server
  qlcolorcode
  qlmarkdown
  qlstephen
  quicklook-json
  quicklook-csv
  java
  launchrocket
  plex-home-theater
  plex-media-server
  satellite-eyes
  sidekick
  spotify
  steam
  teleport
  utorrent
  vlc
  zeroxdbe-eap
)

pips=(
  Glances
)

gems=(
  git-up
  travis
)

npms=(
  grunt
  coffee-script
  trash
  gitjk
  fenix-cli
)

######################################## End of app list ########################################
set +e

echo "Installing Xcode ..."
xcode-select --install

if test ! $(which brew); then
  echo "Installing Homebrew ..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Updating Homebrew ..."
  brew update
fi
brew doctor

fails=()

function print_red {
  red='\x1B[0;31m'
  NC='\x1B[0m' # no color
  echo -e "${red}$1${NC}"
}

function ping {
  url=$1
  shift
  for pkg in $@;
  do
    exec="curl -Ifsw '%{http_code}' -o /dev/null $url/$pkg.rb"
    if $exec ; then
      echo "$pkg is available"
    else
      print_red "$pkg not found"
    fi
  done
}

function install {
  cmd=$1
  shift
  for pkg in $@;
  do
    exec="$cmd $pkg"
    echo "Executing: $exec"
    if $exec ; then
      echo "Installed $pkg"
    else
      fails+=($pkg)
      print_red "Failed to execute: $exec"
    fi
  done
}

ping 'https://raw.githubusercontent.com/Homebrew/homebrew/master/Library/Formula/' ${brews[@]}
ping 'https://raw.githubusercontent.com/caskroom/homebrew-cask/master/Casks' ${casks[@]}

read -p "Proceed with installation? " -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]
then
    exit 1
fi

install 'brew install' ${brews[@]}
install 'brew cask --appdir=/Applications install' ${casks[@]}
install 'pip install' ${pips[@]}
install 'gem install' ${gems[@]}
install 'npm install -g' ${npms[@]}

echo "Setting up zsh ..."
curl -L http://install.ohmyz.sh | sh
chsh -s $(which zsh)
# TODO: Auto-set theme to "fino-time" in ~/.zshrc (using antigen?)
curl -sSL https://get.rvm.io | bash -s stable  # required for some zsh-themes

echo "Upgrading ..."
pip install --upgrade setuptools
pip install --upgrade pip
gem update --system

echo "Cleaning up ..."
brew cleanup
brew cask cleanup
brew linkapps

for fail in ${fails[@]}
do
  echo "Failed to install: $fail"
done

echo "Run `mackup restore` after DropBox has done syncing"

read -p "Hit enter to run [OSX for Hackers] script..." c
sh -c "$(curl -sL https://gist.githubusercontent.com/brandonb927/3195465/raw/osx-for-hackers.sh)"