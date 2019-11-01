# VIM Setup

## Pathogen

1) Create autoload and bundle folders
```
mkdir -p ~/.vim/autoload ~/.vim/bundle
```

2) Download and install Pathogen
```
curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
```

3) Setup syntax on. On ~/.vimrc add:  

```
:syntax on
```

3) Setup Oh my Zsh

4) Install Tmux Plugins
```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
``` 

5) Open iterm2 and on `Profiles>Colors>Color Presents` choose Solarized Dark

6) Update repeat key speed
```
defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)
```
