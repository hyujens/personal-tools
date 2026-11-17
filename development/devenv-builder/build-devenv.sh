#!/bin/bash

build_base() {
  docker build -t devenv-base - <<'EOF'
FROM fedora:latest

# add non-root user to avoid run docker container in root
RUN useradd -m developer

RUN dnf -y update

# install to have `clear` command
RUN dnf -y install ncurses procps-ng && dnf clean all

# prepare for neovim + LazyVim
RUN dnf copr enable -y dejan/lazygit
RUN dnf install -y git lazygit fd-find curl ripgrep tree-sitter-cli neovim fzf && dnf clean all

USER developer
# install codex command tool
RUN curl -fsSL https://chatgpt.com/codex/install.sh | sh

RUN git clone https://github.com/LazyVim/starter /home/developer/.config/nvim
RUN nvim --headless "+Lazy! sync " +qa

# NEOVIM GARBAGE CHARACTERS (+q4D73) IN QTERMINAL INVESTIGATION REPORT
# https://github.com/neovim/neovim/issues/40988
RUN sed -i '1i vim.g.termfeatures = { osc52 = false }' \
    /home/developer/.config/nvim/init.lua

WORKDIR /workspace
EOF
}

build_go() {
  docker build -t devenv:go -f ./dockerfiles/Dockerfile.goenv ./dockerfiles
}

build_python() {
  docker build -t devenv:py -f ./dockerfiles/Dockerfile.pyenv ./dockerfiles
}

build_cpp() {
  docker build -t devenv:cpp -f ./dockerfiles/Dockerfile.cppenv ./dockerfiles
}

target="${1:-}"

case "$target" in
base)
  build_base
  ;;
python)
  build_python
  ;;
go)
  build_go
  ;;
cpp)
  build_cpp
  ;;
rust)
  build_rust
  ;;
*)
  echo "unsupport target, $1, to build"
  exit 1
  ;;
esac
