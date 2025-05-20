{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Python toolchain
    python3
    python3Packages.pip
    python3Packages.virtualenv
    poetry-core

    # Development tools
    ruff  # Fast Python linter
    black  # Code formatter
    mypy  # Type checker
    python3Packages.pylint  # Linter
    python3Packages.pytest  # Testing
    python3Packages.pytest-cov  # Coverage
    python3Packages.ipython  # Interactive shell
    python3Packages.jupyter  # Notebooks
    python3Packages.pylsp  # LSP server
  ];
} 