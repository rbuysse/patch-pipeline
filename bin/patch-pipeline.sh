#!/bin/bash

if [[ ! -n $(which gum) || ! -n $(which yq) ]]; then
    echo "ERROR: patch-pipeline requires 'gum' and 'yq'. " \
         "Run 'brew install gum yq'."
    exit 1
fi

set -e

# housekeeping
top_dir=$(cd $(dirname $(dirname $0)) && pwd)

YELLOW='\033[1;33m'
RESET='\033[0m'

# required 
REMOTES=$(git remote -v | awk {'print $2'} |sort | uniq)
FIXED_REMOTES=$(echo $REMOTES | sed 's/git@github\.com:\(.*\)\.git/https:\/\/github.com\/\1/g')

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

PIPELINE_FILES=$(grep -l -i pathInRepo $top_dir/pipelines/*.yaml)

# TRIGGER_TEMPLATE_FILES=$(grep -l -i pathInRepo $top_dir/helm/*.yaml)

echo "Which file would you like to patch?"
FILE_CHOICE=$(gum choose $PIPELINE_FILES)
echo -e " ${YELLOW}$FILE_CHOICE${RESET}"

echo "What remote would you like to use?"
REMOTE_CHOICE=$(gum choose $FIXED_REMOTES)
echo -e " ${YELLOW}$REMOTE_CHOICE${RESET}"

echo "What branch would you like to use?"
BRANCH_CHOICE=$(gum input --value $CURRENT_BRANCH)
echo -e " ${YELLOW}$BRANCH_CHOICE${RESET}"

echo "Patching $FILE_CHOICE..."

# wrap this
yq eval -i '(.spec.tasks[].taskRef.params += [{"name": "url", "value": "'"$REMOTE_CHOICE"'"}, {"name": "revision", "value": "'"$BRANCH_CHOICE"'"}])' $FILE_CHOICE

echo "Committing changes..."
git add $FILE_CHOICE && git commit -m "OVERRIDE RESOLVER - DO NOT MERGE"
