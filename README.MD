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
 - [x] Stable Diffusion WebUI Forge
 - [x] ComfyUI
 - [x] InvokeAI


## Installation

To securely install AIMan, follow these straightforward steps. This process
involves creating a dedicated user account called `aiman` that will be used
to run the AIMan script. Having a separate user account enhances the security
of the installation by limiting the access and permissions on your system.

1. Create a new user for AIMan and set a password:
    ```
    sudo useradd -m aiman && sudo passwd aiman
    ```

2. Switch to the AIMan user:
    ```
    su - aiman
    ```

3. Clone the AIMan repository from GitHub:
    ```
    git clone https://github.com/martin-rizzo/AIMan.git
    cd AIMan
    ```

4. (optional) Add AIMan to the PATH and update the shell session:
    ```
    ./aiman add2path && source ~/.bashrc
    ```

5. (optional) Set the directory where the AI models are located:
    ```
    ./aiman setdir @models /path/to/your/models/directory
    ```

6. (optional) Set the output directory for AIMan:
    ```
    ./aiman setdir @output /path/to/your/output/directory
    ```

7. Install the web UI project (replace `webui` with the desired project name):
    ```
    ./aiman webui.install
    ```

8. Launch the web UI (replace `webui` with the desired project name):
    ```
    ./aiman webui.launch
    ```

Please note that these instructions assume a Linux system and may require
additional steps or modifications based on your specific environment.


## Launching any AI project

To launch any AI project after the initial installation, follow these steps:

1. Switch to the AIMan user:
    ```
    su - aiman
    ```

2. Launch the web UI (replace `webui` with the desired project name):
   ```
   ./aiman webui.launch
   ```


## Contributing

As mentioned earlier, this project is experimental and primarily developed
for personal use. However, contributions, bug reports, and pull requests are
welcome. If you encounter any issues or have suggestions, please open an
issue on the GitHub repository.


## Lincense

Copyright (c) 2023-2024 Martin Rizzo  
This project is licensed under the MIT license.  
See the ["LICENSE"](LICENSE) file for details.
