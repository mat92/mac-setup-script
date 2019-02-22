#!/usr/bin/env bash

# Install some stuff before others!
important_casks=(
  adoptopenjdk
  corretto
)

brews=(
  awscli
  brew-cask-completion
  cocoapods
  fontconfig
  git
  gnu-sed
  gpg
  gradle
  htop
  jenv
  kotlin
  maven
  m-cli
  mackup
  mas
  node
  ntfs-3g
  openssl
  python
  python@2
  ruby
  shellcheck
  tree
  trash
  unrar
  vim
  wget
  zsh
)

casks=(
  alfred
  avast-security
  appcleaner
  balenaetcher
  cheatsheet
  dashlane
  docker
  dropbox
  gimp
  gitkraken
  google-chrome
  firefox
  handbrake
  intellij-idea
  itsycal
  libreoffice
  nordvpn
  onyx
  oversight
  postman
  skype
  slack
  spectacle
  spotify
  steam
  teamviewer
  telegram
  the-unarchiver
  tor-browser
  virtualbox
  visual-studio-code
  vlc
  xquartz
)

pips=()

gems=()

npms=()

#gpg_key='3E219504'
git_email='webhofer.m@gmail.com'
git_configs=(
  "user.email=webhofer.m@gmail.com"
  "user.name=Matthias Webhofer"
)

vscode=()

fonts=(
  font-fira-code
  font-source-code-pro
)

######################################## End of app list ########################################
set +e
set -x

function prompt {
  if [[ -z "${CI}" ]]; then
    read -p "Hit Enter to $1 ..."
  fi
}

function install {
  cmd=$1
  shift
  for pkg in "$@";
  do
    exec="$cmd $pkg"
    #prompt "Execute: $exec"
    if ${exec} ; then
      echo "Installed $pkg"
    else
      echo "Failed to execute: $exec"
      if [[ ! -z "${CI}" ]]; then
        exit 1
      fi
    fi
  done
}

function brew_install_or_upgrade {
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" > /dev/null); then 
      echo "Upgrading already installed package $1 ..."
      brew upgrade "$1"
    else 
      echo "Latest $1 is already installed"
    fi
  else
    brew install "$1"
  fi
}

if [[ -z "${CI}" ]]; then
  sudo -v # Ask for the administrator password upfront
  # Keep-alive: update existing `sudo` time stamp until script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

if test ! "$(command -v brew)"; then
  prompt "Install Homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  if [[ -z "${CI}" ]]; then
    prompt "Update Homebrew"
    brew update
    brew upgrade
    brew doctor
  fi
fi
export HOMEBREW_NO_AUTO_UPDATE=1

echo "Install important software ..."
brew tap caskroom/versions
install 'brew cask install' "${important_casks[@]}"

prompt "Install packages"
install 'brew_install_or_upgrade' "${brews[@]}"
brew link --overwrite ruby

prompt "Set git defaults"
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

if [[ -z "${CI}" ]]; then
 # gpg --keyserver hkp://pgp.mit.edu --recv ${gpg_key}
  prompt "Export key to Github"
  ssh-keygen -t rsa -b 4096 -C ${git_email}
  pbcopy < ~/.ssh/id_rsa.pub
  open https://github.com/settings/ssh/new
fi  

prompt "Install software"
install 'brew cask install' "${casks[@]}"

#prompt "Install secondary packages"
#install 'pip3 install --upgrade' "${pips[@]}"
#install 'gem install' "${gems[@]}"
#install 'npm install --global' "${npms[@]}"
#install 'code --install-extension' "${vscode[@]}"
brew tap caskroom/fonts
install 'brew cask install' "${fonts[@]}"

prompt "Install oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

prompt "Update packages"
m update install all

if [[ -z "${CI}" ]]; then
  prompt "Install software from App Store"
  mas list
fi

prompt "Cleanup"
brew cleanup
brew cask cleanup

echo "Run [mackup restore] after DropBox has done syncing ..."
echo "Done!"
