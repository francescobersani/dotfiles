#!/usr/bin/env bash

# Install command-line tools using Homeapt-get.

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


#add custom apt repositories
add-apt-repository ppa:webupd8team/java

# Make sure we’re using the latest Homeapt-get.
apt-get update

# Upgrade any already-installed formulae.
apt-get upgrade



# install java
apt-get install oracle-java8-installer





# Install GNU core utilities (those that come with OS X are outdated).
# Don’t forget to add `$(apt-get --prefix coreutils)/libexec/gnubin` to `$PATH`.
apt-get install coreutils
# Install some other useful utilities like `sponge`.
apt-get install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
apt-get install findutils


# Install more recent versions of some OS X tools.
apt-get install vim

# Install some CTF tools; see https://github.com/ctfs/write-ups.
apt-get install binutils
apt-get install dns2tcp
apt-get install knock
apt-get install nmap
apt-get install socat
apt-get install sqlmap
apt-get install tcpflow
apt-get install tcpreplay
apt-get install tcptrace
apt-get install xpdf


#apt-get install exiv2
apt-get install git
apt-get install git-lfs
apt-get install imagemagick
apt-get install lua
apt-get install lynx
apt-get install p7zip
apt-get install rename
apt-get install ssh-copy-id
apt-get install tree


#install font for console reading
apt-get install xfonts-terminus


#install developer tools
apt-get install gnome-commander
apt-get install libxml2-utils
apt-get install curl
# Remove outdated versions from the cellar.
apt-get clean
apt-get autoclean
apt-get autoremove