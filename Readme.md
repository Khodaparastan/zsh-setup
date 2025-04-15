# My Zsh Configuration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository contains my personal Zsh configuration, optimized for a balance
of features, performance, and cross-platform compatibility (macOS, Ubuntu,
RHEL/Fedora). It leverages the [`zi`](https://github.com/z-shell/zi) plugin
manager for efficient handling of plugins, completions, and tools.

## Goals

- **Cross-Platform:** Works consistently across macOS, Ubuntu, and RHEL-based
  Linux distributions.
- **Fast Startup:** Uses `zi`'s deferred loading (`lucid`, `wait`) to keep
  prompt latency low.
- **Modular & Maintainable:** Configuration is broken down into logical files.
  Package dependencies are managed externally in `packages.yaml`.
- **Modern Tools:** Integrates well with tools like `fzf`, `eza`, `zoxide`,
  `nvim`, `pyenv`, `starship`, `atuin`, etc.
- **XDG Compliance:** Follows XDG Base Directory Specification for cache,
  config, and data files where possible.

## Features

- **Plugin Management:** Uses `zi` for robust and fast plugin loading.
- **Modular Structure:** Configuration files organized under `conf.d/`,
  `aliases/`, `completions/`. Package definitions in `packages.yaml`.
- **Rich Completions:** Enhanced tab completion via `zsh-completions`, `fzf-tab`
  (optional), and dynamic completions for tools like `kubectl`, `gcloud`, etc.
- **Syntax Highlighting:** Provided by `zsh-users/zsh-syntax-highlighting`.
- **Autosuggestions:** Command suggestions via `zsh-users/zsh-autosuggestions`.
- **Modern Utilities:** Integration and configuration for `eza` (modern `ls`),
  `bat` (modern `cat`), `fd` (modern `find`), `zoxide` (smarter `cd`).
- **Developer Tools:** Seamless integration with `pyenv`, `direnv`, `git`
  helpers.
- **Custom Prompt:** Uses [`starship.rs`](https://starship.rs/) for a fast,
  customizable, cross-shell prompt (requires separate `starship.toml`
  configuration).
- **Enhanced History:** Uses `atuin` for syncable, searchable, context-aware
  shell history (optional but recommended).
- **Helpful Aliases & Functions:** Includes custom aliases (`aliases/`) and
  functions (`conf.d/51_functions.zsh`).
- **Automated Setup:** Includes `setup_zsh_env.sh` to automate dependency
  installation based on `packages.yaml`.

## Prerequisites

Basic requirements are `git`, `curl`/`wget`, and `sudo` access. The included
setup script handles most other dependencies.

**For detailed prerequisites and setup instructions, please see the
[Environment Setup Guide (SETUP.md)](https://github.com/Khodaparastan/zsh-setup/blob/main/setup.md).**

## Installation

Installation involves cloning this repository and running the included setup
script.

**Please follow the detailed steps in the
[Environment Setup Guide (SETUP.md)](https://github.com/Khodaparastan/zsh-setup/blob/main/setup.md).**

## Structure Overview

- **`~/.zshrc`**: Minimal entry point; sources `conf.d/` files.
- **`conf.d/`**: Modular Zsh configuration files, loaded numerically.
- **`aliases/`**: Alias definition files, loaded via `conf.d/50_aliases.zsh`.
- **`completions/`**: Custom/vendored completion files, loaded via
  `conf.d/70_completions_dynamic.zsh`.
- **`packages.yaml`**: Defines package dependencies for different operating
  systems. Used by the setup script.
- **`setup_zsh_env.sh`**: Script to install dependencies and set up the
  environment.
- **`README.md`**: This overview file.
- **`SETUP.md`**: Detailed installation instructions.

## Customization

- **Plugins:** Add/remove plugins by editing the relevant `conf.d/4*.zsh` files.
  Refer to the [`zi` documentation](https://github.com/z-shell/zi).
- **Aliases:** Add personal aliases in `conf.d/50_aliases.zsh` or create new
  files in `aliases/`.
- **Functions:** Add custom functions in `conf.d/51_functions.zsh`.
- **Packages:** Modify dependencies for the setup script by editing
  `packages.yaml`.
- **Starship Prompt:** Customize your prompt via `~/.config/starship.toml`. See
  [Starship docs](https://starship.rs/config/).
- **Atuin Config:** Configure via `atuin config` or
  `~/.config/atuin/config.toml`.

## Troubleshooting (Zsh Configuration)

- **`zi: command not found`:** Ensure `00_init.zsh` ran correctly. Check
  permissions in `~/.local/share/zi/bin`.
- **Slow Startup:** Use `zsh -x -i -l +e` to trace. Consider moving slow plugins
  to `42_plugins_defer.zsh`.
- **Icons Not Rendering:** Install and select a Nerd Font in your terminal
  emulator.

_(For setup script issues, see `SETUP.md`)_

## License

This configuration is licensed under the MIT License.
