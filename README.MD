# AIMan

AIMan is a basic package management system for open source AI projects. It is
entirely programmed in bash scripts and designed to be easily installed on any
Linux system without the need for additional languages or dependencies.
Please note that this project is currently in its early stages and may not be
actively maintained for a long time. It is primarily developed as a personal
tool but is published on GitHub for source control and to facilitate bug
reporting and feature requests.

## Installation

To install AIMan from scratch, follow these steps:

1. Create a new user for AIMan:
    ```
    sudo useradd aiman
    ```

2. Set a password for the AIMan user:
    ```
    sudo passwd aiman
    ```

3. Set appropriate permissions for the AIMan user's home directory:
    ```
    sudo chmod 2750 /home/aiman
    ```

4. Switch to the AIMan user:
    ```
    su - aiman
    ```

5. Clone the AIMan repository from GitHub:
    ```
    git clone https://github.com/martin-rizzo/AIMan.git
    ```

6. Add AIMan to the system's PATH:
    ```
    AIMan/aiman add2path
    ```

7. Update the current shell session to include the AIMan changes:
    ```
    source ~/.bashrc
    ```

8. Set the directory for AI models:
    ```
    aiman setdir @models /mnt/disk_x/marti/AI-Models
    ```

9. Set the output directory for AIMan:
    ```
    aiman setdir @output /var/tmp/aiman-output
    ```

10. Install the web UI package (replace `webui` with the desired package name):
    ```
    aiman install webui
    ```

11. Launch the web UI (replace `webui` with the desired package name):
    ```
    aiman launch webui
    ```

Please note that these instructions assume a Linux system and may require
additional steps or modifications based on your specific environment.

## Contributing

As mentioned earlier, this project is experimental and primarily developed for
personal use. However, contributions, bug reports, and feature requests are
welcome. If you encounter any issues or have suggestions, please open an issue
on the GitHub repository.

## License

This project is licensed under the [MIT License](LICENSE).
