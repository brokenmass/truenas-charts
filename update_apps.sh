#!/bin/bash

VERSION="v4.31.1"
BINARY="yq_linux_amd64"
YQ_PATH="$(pwd)/yq"
BASE_PATH="library/dev"

if [[ ! -f "$YQ_PATH" ]]; then
    echo "Downloading yq..."
    wget -q "https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}" -O "$YQ_PATH" && \
    chmod +x "$YQ_PATH"
    echo "Done"
fi

function check_args(){
    local arg=$1
    if [[ -z "$arg" ]]; then
        echo "Error: $2 not specified"
        exit 1
    fi
}

NOW=$(date '+%Y-%m-%d %H:%M:%S')

function copy_app() {
    local train=$1
    local app=$2

    # Check arguments have values
    check_args "$train"
    check_args "$app"
    local sourcePath="$BASE_PATH/$train/$app"

    echo "🚂 Updating [$train] $app..."
    # Grab version from Chart.yaml
    version=$("$YQ_PATH" '.version' "$sourcePath/Chart.yaml")
    appVersion=$("$YQ_PATH" '.appVersion' "$sourcePath/Chart.yaml")
    check_args "$version"
    check_args "$appVersion"


    local targetPath="$train/$app/${version}"
    # Make sure directories exist
    rm -rf $train/$app/*
    echo "rm -rf $train/$app/*"
    mkdir -p "$targetPath"

    helm dependency update "$sourcePath" >> /dev/null
    # Copy files over
    rsync --archive --delete "$sourcePath/" "$targetPath"
    # Rename values.yaml to ix_values.yaml
    mv "$targetPath/values.yaml" "$targetPath/ix_values.yaml"

    # Grab icon and categories from Chart.yaml
    icon=$("$YQ_PATH" '.icon' "$sourcePath/Chart.yaml")
    check_args "$icon"
    categories=$("$YQ_PATH" '.keywords' "$sourcePath/Chart.yaml")
    check_args "$categories"

    # Create item.yaml
    echo "" > "$train/$app/item.yaml"
    ICON="$icon" "$YQ_PATH" '.icon_url = env(ICON)' --inplace "$train/$app/item.yaml"
    CATEGORIES="$categories" "$YQ_PATH" '.categories = env(CATEGORIES)' --inplace "$train/$app/item.yaml"


    $YQ_PATH ".charts.$app.latest_version=\"${version}\"" -o=json -I2 --inplace ./catalog.json
    $YQ_PATH ".charts.$app.latest_human_version=\"${appVersion}_${version}\"" -o=json -I2 --inplace ./catalog.json
    $YQ_PATH ".charts.$app.latest_app_version=\"$appVersion\"" -o=json -I2 --inplace ./catalog.json
    $YQ_PATH ".charts.$app.last_update=\"$NOW\"" -o=json -I2 --inplace ./catalog.json
}

# TODO: Call this function for each changed app
trains=("charts")

for train in "${trains[@]}"; do


    for app in "$BASE_PATH/$train"/*; do
      copy_app "$train" "$(basename $app)"
    done
done