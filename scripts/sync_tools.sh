#!/bin/bash
set -e

# const
DEFAULT_VERSION="main"
GIT_ROOT="$(git rev-parse --show-toplevel)"
LIB_DIR="${GIT_ROOT}/libs"
ABEJA_TOOLKIT="abeja-toolkit"
ABEJA_TOOLKIT_DIR="${LIB_DIR}/${ABEJA_TOOLKIT}"
ABEJA_GITHUB_ORG="abeja-inc"

# parse arguments
tool_args=()
version=""
debug_mode=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -d| --debug)
            debug_mode=true
            shift
            ;;
        -v| --version)
            if [ -n "$2" ]; then
                version="$2"
                shift 2
            else
                echo "❌ Error: --version option requires a value." >&2
                exit 1
            fi
            ;;
        -h| --help)
            echo "💡 Usage: $0 [options] [tool_name ...]"
            echo "Options:"
            echo "  -d, --debug          Enable debug mode"
            echo "  -v, --version <version>  Specify the version to checkout (default: main)"
            echo "  -h, --help           Show this help message"
            echo "Examples:"
            echo "  $0 exp_logger"
            echo "  $0 exp_logger slack_logger --version v0.3.2"
            echo "  $0 exp_logger exp_logger --version main"
            echo "  $0 --version c1053852559f9f622b51a727d2bd2600ca677821"
            exit 0
            ;;
        *)
            tool_args+=("$1")
            shift
            ;;
    esac
done

if [ "$debug_mode" = true ]; then
    echo "🛠️ DEBUG MODE IS ON. 🛠️"

    echo "🛠️ Consts:"
    echo "🛠️   GIT_ROOT: ${GIT_ROOT}"
    echo "🛠️   LIB_DIR: ${LIB_DIR}"
    echo "🛠️   ABEJA_TOOLKIT_DIR: ${ABEJA_TOOLKIT_DIR}"
    echo "🛠️   ABEJA_GITHUB_ORG: ${ABEJA_GITHUB_ORG}"
    echo "🛠️   ABEJA_TOOLKIT: ${ABEJA_TOOLKIT}"
    echo "🛠️   DEFAULT_VERSION: ${DEFAULT_VERSION}"
    echo "🛠️ Arguments:"
    echo "🛠️   tool_args: ${tool_args[*]}"
    echo "🛠️   version: ${version}"
fi

# Move to the libs directory
cd "${LIB_DIR}"
if [ "$debug_mode" = true ]; then
    echo "🛠️ Moved to libs directory: ${LIB_DIR}"
fi

# If abeja-toolkit exists, get the directory name under abeja-toolkit.
if [ -d "$ABEJA_TOOLKIT_DIR" ]; then
    echo "🔍 Checking existing directories in ${ABEJA_TOOLKIT_DIR}..."
    cd "$ABEJA_TOOLKIT_DIR"
    existing_dirs=()
    for d in */ ; do
        # d is in the form "dirname/", so exclude the trailing slash
        dir_name="${d%/}"

        # If dir_name is not *, add to array
        if [ "$dir_name" != "*" ]; then
            existing_dirs+=("$dir_name")
        fi
    done
    echo "🟢 Existing directories found: ${existing_dirs[*]}"
    cd ../
else
    existing_dirs=()
fi

# Remove abeja-toolkit if it exists
if [ -d "$ABEJA_TOOLKIT_DIR" ]; then
    echo "🗑️ Removing existing abeja-toolkit directory..."
    rm -rf "$ABEJA_TOOLKIT_DIR"
    echo "✅ Removed existing abeja-toolkit directory."
fi

# Clone abeja-toolkit
if [ ! -d "$ABEJA_TOOLKIT_DIR" ]; then
    echo "🔄 Cloning abeja-toolkit repository..."
    git clone --filter=blob:none --no-checkout "git@github.com:$ABEJA_GITHUB_ORG/$ABEJA_TOOLKIT.git"
    echo "✅ Cloned abeja-toolkit repository."
fi

# Go to the abeja-toolkit directory
cd "$ABEJA_TOOLKIT_DIR"
if [ "$debug_mode" = true ]; then
    echo "🛠️ Moved to abeja-toolkit directory: ${ABEJA_TOOLKIT_DIR}"
fi

# Combine arguments with existing directory name
final_args_str=$(printf "%s\n" "${tool_args[@]}" "${existing_dirs[@]}" | sort -u)
# Use bash 3.2 compatible method instead of readarray
# Filter out empty lines to handle the case where no tools are specified
final_args=()
while IFS= read -r line; do
    if [ -n "$line" ]; then
        final_args+=("$line")
    fi
done <<<"$final_args_str"

# Execute sparse-checkout only if final_args is non-empty
if [ ${#final_args[@]} -gt 0 ]; then
    echo "🔧 Syncing tools: ${final_args[*]}"

    # sparse-checkout only the tools you need
    git sparse-checkout init --no-cone
    git sparse-checkout set "${final_args[@]}"

    # checkout the specified version or default to main
    checkout_target="${version:-$DEFAULT_VERSION}"
    echo "🔍 Checking out version: ${checkout_target}"
    git checkout "$checkout_target" || {
        echo "❌ Error: Failed to checkout version ${checkout_target}. Please check the version or branch name." >&2
        echo "⚠️ This script has deleted $ABEJA_TOOLKIT_DIR. If you need to undo the change, simply discard it." >&2
        echo "Run 'git status' to see the changes." >&2
        exit 1
    }
    echo "✅ Checked out to version: ${checkout_target}"

    # To avoid leaking out our assets through the git history of the abeja-toolkit
    rm -rf .git 
    cd "${GIT_ROOT}"

    # update pyproject.toml
    # NOTE: retry the number of tools + 1 times at max in order to solve the dependencies between the tools.
    n_tools=$(ls -1q "$ABEJA_TOOLKIT_DIR" | wc -l)
    max_retries=$((n_tools + 1))
    echo "🔄 Updating pyproject.toml with a maximum of $max_retries attempts..."
    attempt=1
    while [ $attempt -le $max_retries ]; do
        echo "🔄 Attempt $attempt to update pyproject.toml..."
        success_flag=true
        for dir in "$ABEJA_TOOLKIT_DIR"/* ; do
            echo "🔧 Adding $dir to pyproject.toml"
            if uv add "$dir" --workspace; then
                echo "✅ Added $dir to pyproject.toml as workspace."
            else
                echo "⚠️ Failed to add $dir. Will retry if dependencies are missing."
                success_flag=false
            fi
        done
        if [ "$success_flag" = true ]; then
            echo "All tools added to pyproject.toml successfully! 🎉🎉🎉"
            break
        fi
        attempt=$((attempt + 1))
    done
    if [ "$success_flag" = false ]; then
        echo "❌ Error: Failed to add some tools to pyproject.toml after $max_retries attempts. Please check for dependency issues." >&2
        exit 1
    fi

    echo "✅ SYNC COMPLETED SUCCESSFULLY! 🎉🎉🎉"
    echo "📂 The following directories synced:"
    for dir in "${final_args[@]}"; do
        echo "  - $dir"
    done
    echo "Commit the changes to your repository if needed."
else
    echo "❌ No tools specified for sync. Please provide at least one tool name."
    cd ${GIT_ROOT}
fi


# NOTE: How to test this script
# 1. Ensure you have the necessary permissions to clone the repository.
# 2. Run the script with various combinations of arguments to test different scenarios in the root of the directory.
#    - For example:
#      - Normal Case
#        - ./sync_tools.sh exp_logger  # with default version
#        - ./sync_tools.sh -v v0.3.2  # with specific version
#        - ./sync_tools.sh exp_logger slack_logger --version c1053852559f9f622b51a727d2bd2600ca677821  # multiple tools with specific version
#        - ./sync_tools.sh exp_logger exp_logger --version main  # duplicate tool name
#      - Invalid Case
#        - ./sync_tools.sh INVALID_TOOL  # NOTE: Non-existent tool name should be ignored and other exsting tools should be synced.
#        - ./sync_tools.sh --version INVALID_VERSION  # NOTE: If with invalid version, it should print an error message and exit.
