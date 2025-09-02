{ pkgs, lib }:
let
  common = with pkgs; [ 
    git 
    gcc 
    gnumake 
    cmake 
    pkg-config 
    openssl
    vim 
    tmux 
    htop 
    tree 
    ripgrep 
    fzf 
    jq 
    curl 
    wget 
    unzip 
    zip 
    rsync 
    sshfs 
    fuse3
  ];
  
  rust = with pkgs; [ 
    rustc 
    cargo 
    rust-analyzer 
    rustfmt 
    clippy
    cargo-edit
    cargo-outdated
    cargo-udeps
    cargo-watch
    cargo-expand
    cargo-audit
    cargo-deny
    cargo-msrv
    cargo-nextest
    cargo-tarpaulin
  ];
  
  goTools = with pkgs; [
    pkgs.go
    gopls
    gotools
    delve
  ];
  
  node = with pkgs; [
    nodejs_22
    nodePackages.typescript
  ];
  
  python = let py = pkgs.python312; in [
    (py.withPackages (ps: with ps; [ 
      pip 
      virtualenv 
      ipython 
      jupyterlab 
      black 
      ruff 
      mypy 
      pytest 
      pytest-cov
      pylint
      python-lsp-server
    ]))
  ];
  
  network = with pkgs; [
    inetutils
    mtr
    iperf3
    nmap
  ];
  
  container = with pkgs; [
    docker
    docker-compose
    kubectl
    helm
  ];
  
  editors = with pkgs; [
    vim
    neovim
    emacs
  ];
  
  terminal = with pkgs; [
    tmux
    zsh
  ];
  
  filemgmt = with pkgs; [
    ranger
    mc
    ncdu
    duf
  ];
  
  monitoring = with pkgs; [
    htop
    iotop
    nethogs
    btop
  ];
in {
  inherit common rust node python network container editors terminal filemgmt monitoring;
  
  # Export the renamed lists under non-conflicting names
  go = goTools;
  
  # Full development environment
  devAll = lib.concatLists [ 
    common 
    rust 
    goTools
    node 
    python 
    network 
    container 
    editors 
    terminal 
    filemgmt 
    monitoring 
  ];
  
  # Server/CI-lean bundles
  ciLean = with pkgs; [ 
    git 
    jq 
    curl 
    bash 
    go 
    rustc 
    cargo 
    nodejs_22 
    python312 
    vim 
    htop 
    tmux 
  ];
  
  # Minimal server tools
  serverMinimal = with pkgs; [
    vim
    htop
    jq
    curl
    wget
    tmux
    git
  ];
}
