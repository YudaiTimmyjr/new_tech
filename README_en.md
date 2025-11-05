[Japanese](./README.md)

# Using Project Templates
To streamline repository initialization within the ABEJA, first click the **Use this template** button located in the upper-right corner of the repository interface. Next, select **Create a new repository**. During the repository creation process, ensure that you select the appropriate template without accessing the repository’s detailed screen.

# Setup docker container
## Specify Python version
In the `docker-compose.yml` file within the `context/<cpu or gpu>` directory, explicitly define the Python version. If you are using Jupyter Lab, ensure that the `ports` configuration is uncommented and that the port specified in the `start-jupyter` command within the Makefile aligns with the one in `docker-compose.yml`. Since port 8888 is the default, verify available ports on shared systems (such as DGX) and modify the `ports` configuration accordingly, including the port used by the `start-jupyter` command.

## Build & Run docker container
Run the following command to build a Docker image and launch a container. This command generates a `.env_project` file in the `experimentation/` directory, which is then utilized as the environment variable file in docker-compose.yml. 

With cpu
```
make init-docker-cpu
```

With gpu
```
make init-docker-gpu
```

# Setup experimentation environment
## VSCode Integration for Containerized Development

### Attaching VSCode to a Docker Container  
Employ Visual Studio Code’s `Dev Containers` extension to attach to your active Docker container. 

### Configuring the VSCode Environment within the Container  
Once connected, navigate to the `experimentation/` directory within the container and run the following commands to install the needed VSCode extensions. 
```
# If you use stable VSCode
make setup-vscode

# If you use VSCode Insiders
make setup-vscode-insiders

```

## For JupyterLab
If operating in a local environment, execute the following command to launch Jupyter Lab.
```
make start-jupyter
```

Once started, access [http://127.0.0.1:8888/lab](http://127.0.0.1:8888/lab). If you modify the default port, adjust the '8888' entry accordingly. Additionally, when operating on a shared machine (such as a DGX server), establish SSH port forwarding before connecting as described below.
```
$ ssh -N -L 8888:localhost:{Port number of the DGX connected to the container} dgx1a
```

For Windows-based host environments, generate the `%USERPROFILE%/.wslconfig` file and include the subsequent configuration details. After creation, shut down WSL once to ensure the new settings take effect.
```
[wsl2] 
localhostForwarding=true
```

Upon completion of your work, gracefully terminate JupyterLab either by shutting it down via the graphical interface or by stopping the container using the following command.
```
make docker-stop
```

Alternatively, if you wish to terminate only the Jupyter Lab service without stopping the entire container, run the following command.
```
make stop-jupyter
```

# Install Python packages

Creating a virtual environment and installing packages

```bash
uv sync  # Synchronizes all groups (basically run this)
uv sync --dev  # Synchronizes packages in the dev group
uv sync --no-dev  # Synchronizes packages excluding the dev group
uv sync --group <group_name1> --no-group  <group_name2>  # Synchronizes specific groups, excludes specific groups
```

To update project dependencies, run the following:

```bash
uv add <package_name>  # Adds a package
uv add <package_name> --group <group_name>  # Adds a package to a specific group
uv add <package_name> --dev  # Adds a package to the dev group
uv add --editable <path_to_package>  # Adds a local package in editable mode
uv remove <package_name>  # Removes a package
```

For more details, please refer to [https://docs.astral.sh/uv/concepts/projects/dependencies/](https://docs.astral.sh/uv/concepts/projects/dependencies/).

*Note: If you want to update the dependencies of `project_module`, move to `./project_module` and then run `uv add` or similar commands.*

# Sync abeja-toolkit

To update the abeja-toolkit to the latest version or add new tools, run the following command:

```shell
chmod +x ./scripts/sync_tools.sh # Just execute it once.
./scripts/sync_tools.sh [<tool1> <tool2> ...]
```

If you want to sync a specific version of abeja-toolkit, execute the following command with the `--version` option.

```shell
./scripts/sync_tools.sh [<tool1> <tool2> ...] --version <version>
```

For more details, run the following command:

```shell
./sync_tools.sh --help
```

# Sync dsg-project-template

The dsg-project-template can be synchronized to the latest version with the following command.

```shell
chmod +x ./scripts/sync_dsg-project-template.sh # Just execute it once.
./scripts/sync_dsg-project-template.sh [--version <version:branch or tag>] [--debug]
```

or

```shell
make sync-template VERSION=<version:branch or tag>
```

For details, please refer to `./scripts/sync_dsg-project-template.sh --help`.

# Directory Structure
The directory structure of this project is as follows:

This repository is organized into the following directories.
- .github: GitHub workflow, etc.
    - [pull_request_template.md](./.github/pull_request_template.md): PR template configuration file
    - workflows
        - [lint.yaml](./.github/workflows/lint.yaml): Dockerfile lint and Python package lint workflow configuration file
            - About lint_python_scripts
                - Run lint against the Python package containing the Python scripts with differences compared to the base commit.
                - If there is no difference, lint is not executed.
- [.vscode](./.vscode): settings file when using VSCode
    - [settings.json](./.vscode/settings.json): Please change the setting accordingly. formatOnSave is off by default.
- context: Dockerfile and docker-compose.yml for CPU and GPU environments, respectively, are stored.
    - [Dockerfile](./context/Dockerfile)
    - [.hadolint.yaml](./context/.hadolint.yaml)
    - cpu
        - [docker-compose.yml](./context/cpu/docker-compose.yml)
    - gpu
        - [docker-compose.yml](./context/gpu/docker-compose.yml)
- experimentation: Directory for storing experimental notebooks, datasets, and output
    - [dataset](./experimentation/dataset/): Directory where the data set is located
    - [latest](./experimentation/latest/): Directory for storing the latest experimental parameters and results
    - [notebooks](./experimentation/notebooks/): Directory where the experimental notebook is placed
    - [outputs](./experimentation/outputs/): Directory to store the output of the experiment
- libs: A place to put non-project specific modules and git submodules
    - [abeja-toolkit](./libs/abeja-toolkit/): Part of ABEJA's in-house Python library. The following tools are included by default
        - [notebook_exporter](./libs/abeja-toolkit/notebook_exporter/): Tool to convert notebook to notion page
        - [notion_extension](./libs/abeja-toolkit/notion_extension/): Tools for handling Notion API
        - [spreadsheet](./libs/abeja-toolkit/spreadsheet/): Tools to read data from and write data to spreadsheets
- [project_module](./project_module/): A Python package template that implements a project-specific module.This Python package is used by installing in editable mode and import in scripts or notebooks. Add scripts as needed.
    - [tests](./project_module/tests/): Implement test modules such as unit tests
    - src
        - [project_module](./project_module/src/project_module/): Scripts are stored under this directory.
    - [pyproject.toml](./project_module/pyproject.toml): A file describing the dependencies of `project_module`.
    - [README.md](./project_module/README.md): File describing the usage of `project_module`
- [pyproject.toml](./pyproject.toml): pyproject.toml, directly under the root directory, where dependencies and other information on development packages are defined.
- README.md: A file that describes how to use this project template
- README_en.md: How to use the project template (English version)


# Linting
If the dev group dependencies are installed, you can perform a lint check using MyPy and Ruf with the following command:

```shell
make lint /path/to/module
```

# Transfer Notebook to Notion
After authentication and related procedures, executing the following command will automatically generate a Notion page with the specified title, converting the Markdown cells and corresponding cell outputs in the notebook into Notion blocks. For detailed instructions on utilizing the `notebook_exporter`, please refer to [README.md](./libs/abeja-toolkit/notebook_exporter/README.md).

```
make to-notion /path/to/notebook.ipynb <notion_page_title>
```

# Notify Slack Upon the Creation of an Issue or Pull Request


1. Initiate access to the Slack app and instantiate an automated bot dedicated to disseminating notifications.
2. Within the application's administrative interface, navigate to the Incoming Webhooks section via the left-hand navigation panel and activate webhook functionality.
3. Scroll further down the interface and formally submit a request for webhook instantiation, noting that this procedure necessitates prior approval from your organization's designated administrator.
4. Upon receipt of the requisite administrative clearance, proceed with the creation of the webhook.
5. Finally, configure the newly generated webhook URL within the GitHub repository's Secrets under the identifier `SLACK_WEBHOOK_URL`.


# **How to Run Automated Tests**

If you want to run the automated tests, please refer to the following information.

### **Test Code Structure**

- **Test code location and naming convention:**
    - Place your test code in the `project_module/tests` directory.
    - Name your test files in the format `test_*.py`.


### **Test Configuration File**

- Test code settings are defined in the `pytest.ini` file located in the root directory.
- By default, the following arguments are automatically added to the test run:
    - `-v`: Enables **verbose** output, providing more detailed information about the test execution.
    - `--strict-markers`: Raises an error instead of a warning if an unregistered marker is used, which helps prevent typos in marker names.
    - `--cov=project_module/src/project_module`: Specifies the `project_module/src/project_module` directory as the target for **test coverage** measurement.
    - `--cov-branch`: Also measures **branch coverage** (the percentage of conditional branches tested).
    - `--cov-report=term-missing`: Outputs the coverage report to the console, specifically highlighting lines that are missing coverage.


### **Running Tests**

- You can run all tests by using the `make test` command.
- You can also specify a specific path to run tests for a particular module or file:
    - `make test (path_to_target)`
- **Note:** By default, pytest exits with code **5** when no tests are collected. In this project, a pytest hook in `./conftest.py` treats this case as success (**exit code 0**) after emitting a warning. If you want to change this behavior, edit the hook in `./conftest.py`.



### **GitHub Workflow Definition**

- The workflow for automated testing is defined in `.github/workflows/test.yaml`.
- This workflow automatically runs tests on changed Python packages whenever there's a `push` or `pull request`.
- The tests are executed in the latest Ubuntu environment using Python 3.10.


# Troubleshooting

- [Case: When executing `make init-docker-cpu` or `make init-docker-gpu`, an error occurs if `~/.gitconfig` or `~/.ssh` does not exist.](https://github.com/abeja-inc/dsg-project-template/wiki/Troubleshooting#case-make-init-docker-cpu%E3%82%84make-init-docker-gpu%E3%82%92%E5%AE%9F%E8%A1%8C%E6%99%82%E3%81%AB-gitconfig-%E3%82%82%E3%81%97%E3%81%8F%E3%81%AF-ssh-%E3%81%8C%E3%81%AA%E3%81%84%E3%81%A8%E3%82%A8%E3%83%A9%E3%83%BC%E3%81%8C%E5%87%BA%E3%82%8B)

- [Case: When executing `sudo make init-docker-cpu` or `sudo make init-docker-gpu`, an error occurs with the message `useradd: user 'root' already exists`.](https://github.com/abeja-inc/dsg-project-template/wiki/Troubleshooting#case-sudo-make-init-docker-cpu-%E3%82%84sudo-make-init-docker-gpu%E3%82%92%E5%AE%9F%E8%A1%8C%E6%99%82%E3%81%AB-useradd-user-root-already-exists-%E3%81%A8%E3%81%84%E3%81%86%E3%83%A1%E3%83%83%E3%82%BB%E3%83%BC%E3%82%B8%E3%81%A8%E3%81%A8%E3%82%82%E3%81%AB%E3%82%A8%E3%83%A9%E3%83%BC%E3%81%8C%E7%94%9F%E3%81%98%E3%82%8B)

# Contributing

## Notes on Auto Labeling and Branch Prefixes

For the full branching policy, refer to the project wiki: [Development Guide](https://github.com/abeja-inc/dsg-project-template/wiki/Development-Guide). Below are additional rules specific to auto labeling and validation introduced in this repository.

- Pull requests must target `main`, `develop`, or `release/**`. If the branch name does not match the allowed prefixes, the **Branch Name Verifier** workflow will fail.
- Allowed prefixes (`prefix/short-summary` or `prefix-short-summary`):
  - `feat/` or `feature/` – New features → `feature` label
  - `fix/` – Bug fixes → `bug`
  - `doc/` – Documentation updates → `documentation`
  - `change/` / `rename/` – Specification or breaking changes → `change`
  - `refactor/` / `style/` / `chore/` – Refactoring, formatting, or miscellaneous updates → `other`
  - `test/` – Test updates → `enhancement` or `other`
  - `dep/` / `dependabot/` – Dependency upgrades → `dependencies`
  - `release/` – Release branches (only for `release/**`)

- Whenever files under `.github/workflows/**` are modified, the `cicd` label is applied automatically. Changes that include `pyproject.toml`, `poetry.lock`, `uv.lock`, or `requirements*.txt` receive the `dependencies` label.
- These checks are handled by the **Release Drafter and PR Auto Labeler** workflow together with the **Branch Name Verifier**. If your branch name or target branch does not comply, the PR check will fail—rename the branch as needed.