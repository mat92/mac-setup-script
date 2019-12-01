#!/usr/bin/env bash

# Install some stuff before others!
important_casks=(
)

brews=(
  awscli
  bash
  brew-cask-completion
  cloc
  git
  gnu-sed
  gnupg
  gnutls
  gradle
  htop
  jenv
  kotlin
  m-cli
  mackup
  mas
  maven
  md5sha1sum
  node
  openssl
  openssl@1.1
  perl
  python
  python@2
  ruby
  shellcheck
  sqlite
  telegram-cli
  trash
  tree
  unrar
  vim
  wget
  xz
  yarn
  zsh
  zsh-syntax-highlighting
)

casks=(
  alfred
  appcleaner
  avast-security
  balenaetcher
  cheatsheet
  dashlane
  docker
  dropbox
  firefox
  font-fira-code
  font-source-code-pro
  gimp
  gitkraken
  google-chrome
  gpg-suite
  handbrake
  intellij-idea
  itsycal
  jdownloader
  libreoffice
  near-lock
  nordvpn
  onyx
  oversight
  postman
  signal
  silverlight
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
  whatsapp
  xquartz
)

pips=()

gems=()

npms=()

#gpg_key='3E219504'
git_email='webhofer.m@gmail.com'
git_configs=(
  "user.email webhofer.m@gmail.com"
  "user.name 'Matthias Webhofer'"
)

vscode=()

fonts=(
  font-fira-code
  font-source-code-pro
)

JDK_VERSION=openjdk@1.13.0-1

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

prompt "Install JDK=${JDK_VERSION}"
curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash && . ~/.jabba/jabba.sh
jabba install ${JDK_VERSION}
jabba alias default ${JDK_VERSION}
java -version

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

prompt "Install zplug"
sudo chsh -s $(which zsh)
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh

prompt "Configure mackup"
echo "[storage]
engine = icloud" > ~/.mackup.cfg
mackup restore

prompt "Install software"
install 'brew cask install' "${casks[@]}"

#prompt "Install secondary packages"
#install 'pip3 install --upgrade' "${pips[@]}"
#install 'gem install' "${gems[@]}"
#install 'npm install --global' "${npms[@]}"
#install 'code --install-extension' "${vscode[@]}"
brew tap caskroom/fonts
install 'brew cask install' "${fonts[@]}"

if [[ -z "${CI}" ]]; then
  prompt "Install software from App Store"
  mas list
fi

prompt "Cleanup"
brew cleanup
brew cask cleanup

echo "Run [mackup restore] after DropBox has done syncing ..."
echo "Done!"
