# AIMan

AIMan is a basic package management system for open source AI projects. It is
entirely programmed in bash scripts and designed to be easily installed on any
Linux system without the need for additional languages or dependencies.

Please note that this project is currently in its early stages and may not be
actively maintained for a long time. It is primarily developed as a personal
tool but is also published on GitHub for source control, bug reporting,
feature requests, and potential pull requests.


## AI projects supported

 - [x] Stable Diffusion web UI
 - [ ] Stable Diffusion WebUI Forge
 - [x] ComfyUI
 - [x] InvokeAI
 

## Installation

To install AIMan from scratch, follow these steps:

1. Create a new user for AIMan and set a password:
    ```
    sudo useradd -m aiman && sudo passwd aiman
    ```

2. Set appropriate permissions for the AIMan user's home directory:
    ```
    sudo chmod 2750 /home/aiman
    ```

3. Switch to the AIMan user:
    ```
    su - aiman
    ```

4. Clone the AIMan repository from GitHub:
    ```
    git clone https://github.com/martin-rizzo/AIMan.git
    ```

5. (optional) Add AIMan to the PATH and update the shell session:
    ```
    AIMan/aiman add2path && source ~/.bashrc
    ```

6. (optional) Set the directory where the AI models are located:
    ```
    AIMan/aiman setdir @models /path/to/your/models/directory
    ```

7. (optional) Set the output directory for AIMan:
    ```
    AIMan/aiman setdir @output /path/to/your/output/directory
    ```

8. Install the web UI package (replace `webui` with the desired package name):
    ```
    AIMan/aiman install webui
    ```

9. Launch the web UI (replace `webui` with the desired package name):
    ```
    AIMan/aiman launch webui
    ```

Please note that these instructions assume a Linux system and may require
additional steps or modifications based on your specific environment.


## Contributing

As mentioned earlier, this project is experimental and primarily developed
for personal use. However, contributions, bug reports, and pull requests are
welcome. If you encounter any issues or have suggestions, please open an
issue on the GitHub repository.


## License

This project is licensed under the [MIT License](LICENSE).
