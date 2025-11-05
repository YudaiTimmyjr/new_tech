#!/bin/bash
set -e

# const
DATETIME=$(date +"%Y%m%d%H%M%S")
WORKING_BRANCH="sync-dsg-project-template-$DATETIME"
DEFAULT_VERSION="main"
GIT_ROOT="$(git rev-parse --show-toplevel)"
ABEJA_GITHUB_ORG="abeja-inc"
DSG_PROJECT_TEMPLATE_REPO="dsg-project-template"
DSG_PROJECT_TEMPLATE_GIT_URL="git@github.com:$ABEJA_GITHUB_ORG/$DSG_PROJECT_TEMPLATE_REPO.git"
DSG_PROJECT_TEMPLATE_REMOTE_NAME="$DSG_PROJECT_TEMPLATE_REPO"
VERSION_FILE="$GIT_ROOT/.dsg-project-template.version"

# parse arguments
version="$DEFAULT_VERSION"
debug_mode=false
create_working_branch=true
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            if [[ -n "$2" ]]; then
                version="$2"
                shift 2
            else
                echo "❌ Error: --version requires an argument." >&2
                exit 1
            fi
            ;;
        -d|--debug)
            debug_mode=true
            shift
            ;;
        --no-branch)
            create_working_branch=false
            shift
            ;;
        -h|--help)
            echo "💡 A script to sync the DSG project template repository."
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -v, --version <version>    Specify the version of the template to sync (default: $DEFAULT_VERSION)"
            echo "  -d, --debug                Enable debug mode"
            echo "  --no-branch                Do not create a new working branch"
            echo "  -h, --help                 Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# show debug info
if [ "$debug_mode" = true ]; then
    set -x
    echo "🛠️ DEBUG MODE IS ON 🛠️"

    echo "🛠️ Consts.:"
    echo "🛠️   GIT_ROOT: $GIT_ROOT"
    echo "🛠️   DATETIME: $DATETIME"
    echo "🛠️   WORKING_BRANCH: $WORKING_BRANCH"
    echo "🛠️   DEFAULT_VERSION: $DEFAULT_VERSION"
    echo "🛠️   ABEJA_GITHUB_ORG: $ABEJA_GITHUB_ORG"
    echo "🛠️   DSG_PROJECT_TEMPLATE_REPO: $DSG_PROJECT_TEMPLATE_REPO"
    echo "🛠️   DSG_PROJECT_TEMPLATE_GIT_URL: $DSG_PROJECT_TEMPLATE_GIT_URL"
    echo "🛠️   DSG_PROJECT_TEMPLATE_REMOTE_NAME: $DSG_PROJECT_TEMPLATE_REMOTE_NAME"
    echo "🛠️   VERSION_FILE: $VERSION_FILE"
    echo "🛠️ Arguments:"
    echo "🛠️   version: ${version}"
    echo "🛠️   debug_mode: $debug_mode"
    echo "🛠️   create_working_branch: $create_working_branch"
fi

# move to git root
cd "$GIT_ROOT"
if [ "$debug_mode" = true ]; then
    echo "🛠️ Moved to GIT_ROOT: $GIT_ROOT"
fi

# Check if the working directory is clean
if ! git diff --quiet HEAD; then
    echo "❌ Error: Your working directory has uncommitted changes." >&2
    echo "👉 Please commit or stash them before running this script." >&2
    exit 1
fi

# check remote repository
if ! git remote | grep -q "^$DSG_PROJECT_TEMPLATE_REMOTE_NAME$"; then
    echo "🔎 Remote '$DSG_PROJECT_TEMPLATE_REMOTE_NAME' not found. Adding it..."
    git remote add "$DSG_PROJECT_TEMPLATE_REMOTE_NAME" "$DSG_PROJECT_TEMPLATE_GIT_URL"
    echo "✅ Successfully added remote repository."
fi

# fetch the template repository
git fetch "$DSG_PROJECT_TEMPLATE_REMOTE_NAME"
git fetch --tags "$DSG_PROJECT_TEMPLATE_REMOTE_NAME"
echo "✅ Fetched remote repository: $DSG_PROJECT_TEMPLATE_REMOTE_NAME"

# create a new branch where the template will be merged
if [ "$create_working_branch" = true ]; then
    git checkout -b "$WORKING_BRANCH"
    echo "✅ Created new branch: $WORKING_BRANCH"
else
    WORKING_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo "ℹ️ Using current branch: $WORKING_BRANCH"
fi

# merge the template repository
# NOTE: --allow-unrelated-histories is used to allow merging unrelated histories
# NOTE: || true is used to avoid aborting script in order to create a version file always
git merge "$DSG_PROJECT_TEMPLATE_REMOTE_NAME/$version" --allow-unrelated-histories --no-commit --no-ff || true

# create a version file
echo "📝 Recording $DSG_PROJECT_TEMPLATE_REPO version and adding it to the index..."
echo "$DSG_PROJECT_TEMPLATE_GIT_URL@$version" > "$VERSION_FILE"
# NOTE: Specifying the datetime to reveal the snapshot of the version, especially branch name
echo "$DATETIME" >> "$VERSION_FILE"
git add "$VERSION_FILE"

# detect conflicts
if ! git diff --quiet --check; then
    echo "------------------------------------------------------------------"
    echo "✅ The version file '$VERSION_FILE' has been created."
    echo "🔥 But merge conflict detected."
    echo "👉 Please resolve the remaining conflicts and then run 'git commit'."
    echo "------------------------------------------------------------------"
    exit 1
else
    echo "------------------------------------------------------------------"
    echo "✅ The version file '$VERSION_FILE' has been created."
    echo "✅ No merge conflicts detected."
    echo "👉 Please check the staged changes and run 'git commit' to complete the merge."
    echo "------------------------------------------------------------------"
    exit 0
fi
