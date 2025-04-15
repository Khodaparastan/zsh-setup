# Zsh Environment Setup Guide

This guide details the steps required to set up the necessary environment and install this Zsh configuration on a new macOS, Ubuntu, or RHEL-based (Fedora, CentOS, Rocky, Alma) system.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

1.  **`git`**: Required to clone the configuration repository.
2.  **`curl` or `wget`**: Needed by the setup script to download installers (like Homebrew or external tool scripts).
3.  **`sudo` access**: Required for installing system packages and changing the default shell.

**Recommended:**

* **Nerd Font:** For optimal rendering of icons used by tools like `eza` and `starship`, install a [Nerd Font](https://www.nerdfonts.com/) and configure your terminal emulator to use it *after* completing the setup.

The setup script (`setup_zsh_env.sh`) included in this repository will attempt to install most other dependencies (`zsh`, build tools, `jq`, `yq`, `nvim`, `fzf`, `eza`, etc.) based on the definitions in `packages.yaml`.

## Installation Steps

1.  **Clone this Repository:**
    Clone this repository directly into your Zsh configuration directory (`~/.config/zsh`). If `~/.config/zsh` already exists from a previous setup, you might want to back it up or remove it first.

    ```bash
    # Ensure ~/.config directory exists
    mkdir -p ~/.config

    # Clone the repository (replace with your actual repo URL)
    # Using HTTPS:
    git clone [https://github.com/Khodaparastan/zsh-setup.git](https://github.com/Khodaparastan/zsh-setup.git) ~/.config/zsh
    # Or using SSH:
    # git clone git@github.com:Khodaparastan/zsh-setup.git ~/.config/zsh

    # Verify clone was successful before proceeding
    if [ ! -d "$HOME/.config/zsh/.git" ]; then
        echo "ERROR: Failed to clone repository into ~/.config/zsh"
        exit 1
    fi
    ```

2.  **Navigate to Directory:**
    Change into the newly cloned directory. All subsequent commands assume you are in this directory.

    ```bash
    cd ~/.config/zsh
    ```

3.  **Make Setup Script Executable:**

    ```bash
    chmod +x setup_zsh_env.sh
    ```

4.  **Run the Setup Script:**
    Execute the script. It will guide you through the process.

    ```bash
    ./setup_zsh_env.sh
    ```

    **What the script does:**
    * Detects your Operating System and package manager (`apt`, `dnf`, `brew`).
    * Checks for and attempts to install `yq` (YAML parser) and `jq` (JSON processor).
    * Parses `packages.yaml` to determine necessary dependencies.
    * Installs core system packages (build tools, `curl`, etc.).
    * Installs required tools (like `nvim`, `fzf`, `eza`, `bat`, `ripgrep`, `lua`, `luarocks`, etc.) using either the system package manager or external installation scripts (as defined in `packages.yaml`).
    * Prompts for confirmation before executing any external installation scripts downloaded via `curl`.
    * Installs `pyenv` and its dependencies using the official installer (requires confirmation).
    * Attempts to set `zsh` as your default login shell (requires `sudo` and may prompt for your password).
    * Creates necessary XDG directories (`~/.local/share`, `~/.local/state`, `~/.cache`).

5.  **Log Out and Log In:**
    After the script successfully completes, **log out** of your system and log back in. This is crucial for the default shell change to take effect. Alternatively, you can manually start Zsh in your current terminal by typing `zsh`.

## Post-Installation

1.  **First Zsh Launch:** The very first time you start Zsh after logging back in, the `zi` plugin manager (installed automatically by the Zsh config itself) will download and install all the configured plugins and tools defined in the `conf.d/` files. This might take a minute or two and will only happen once.
2.  **Install Python Versions:** Use `pyenv` to install desired Python versions:
    ```bash
    pyenv install 3.13.2 # Example version
    pyenv global 3.13.2 # Set a default global version
    ```
3.  **Configure Tools (Optional):**
    * **Starship Prompt:** Customize your prompt by creating/editing `~/.config/starship.toml`. See the [Starship documentation](https://starship.rs/config/).
    * **Atuin History:** Configure sync/search settings via `atuin config` or by editing `~/.config/atuin/config.toml`. You might need to run `atuin register` or `atuin login`.
    * **Neovim:** Launch `nvim`. Your Neovim config (if included or separate) might trigger plugin installations.
4.  **(Recommended) Configure Terminal Font:** Set your terminal emulator to use a Nerd Font you installed earlier to ensure icons display correctly.

## Troubleshooting Setup

* **Permission Denied:** Ensure `setup_zsh_env.sh` has execute permissions (`chmod +x`). If errors occur during package installation, ensure you have `sudo` privileges and entered your password correctly.
* **`yq` / `jq` Installation Fails:** If the script cannot install `yq` or `jq` automatically, try installing them manually using your system package manager (`sudo apt install yq jq`, `sudo dnf install yq jq`, `brew install yq jq`) and re-run the setup script.
* **Package Not Found:** Definitions in `packages.yaml` might be incorrect for your specific OS version or repository configuration. Check the package names (`bat` vs `batcat`, `eza` vs `exa`, `fd` vs `fd-find`) and update `packages.yaml` if necessary.
* **External Script Fails:** The URLs or commands for external installers (Starship, Atuin, Pyenv) might change. Check the official installation instructions for those tools if the script fails.
* **`chsh` Fails:** Sometimes changing the shell requires specific permissions or group memberships. Ensure the target Zsh path (`command -v zsh`) is listed in `/etc/shells`. If `chsh` fails consistently, you might need to use `usermod --shell $(command -v zsh) $USER` (Linux).

Enjoy your configured Zsh environment!
