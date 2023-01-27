#!/bin/bash

# Create a temporary directory and store its name in a variable.
TEMPD=$(mktemp -d)

# Exit if the temp directory wasn't created successfully.
if [ ! -e "$TEMPD" ]; then
    >&2 read -p "Failed to create temp directory. Press any button to exit."
    exit 1
fi

# Make sure the temp directory gets removed on script exit.
trap "exit 1"           HUP INT PIPE QUIT TERM
trap 'rm -rf "$TEMPD"'  EXIT

# These three variables must match the redis tarball file name
REDIS_DOWNLOAD_URL="https://download.redis.io/redis-stable.tar.gz"
REDIS_FILE_NAME="redis-stable.tar.gz"
REDIS_FOLDER_NAME="redis-stable"
# Path to built redis-cli executable (make)
REDIS_CLI_BUILT_PATH="src/redis-cli"
# Where the redis-cli executable will be copied to (must start with and not finish with /)
DESTINATION_FOLDER="/usr/local/bin"
DESTINATION_FILE="$DESTINATION_FOLDER/redis-cli"

printBanner() {
    clear
    echo "=================================================="
    echo "============  Auto install redis-cli  ============"
    echo "=================================================="
    echo ""
}

download() {
    url="$1"
    filename="$2"

    if [ -x "$(which curl)" ]; then
        curl -sL "$url" -o "$filename"
    elif [ -x "$(which wget)" ]; then
        wget -q "$url" -O "$filename"
    else
        read -p "Could not find curl or wget, please install one of them. Press any button to exit."
        exit 1
    fi
}

userInput='\0'

readKeys() {
    validKeys=("$@")
    while true; do
        read -s -n 1 userInput <&1
        for validKey in "${validKeys[@]}"; do
            if [ "${validKey,,}" = "${userInput,,}" ]; then
                userInput="${validKey,,}"
                return 0
            fi
        done
    done
}

# Access the temporary directory
cd "$TEMPD" || exit 1

step=0

# Dummy command to get sudo permissions
sudo printf ""

printBanner

echo "$((++step)). Downloading and installing necessary dependencies..."
sudo apt-get update >/dev/null && \
    sudo apt-get install gcc make openssl libssl-dev -y >/dev/null
echo "Finished installing dependencies."

echo "$((++step)). Downloading and extracting redis source files..."
download "$REDIS_DOWNLOAD_URL" "$REDIS_FILE_NAME" && \
    tar xzf "$REDIS_FILE_NAME"

# Exit if the redis compressed file wasn't extracted successfully
if [ ! -e "$REDIS_FOLDER_NAME" ]; then
    >&2 read -p "Failed to extract redis-cli tarball! Press any button to exit."
    exit 1
fi
echo "Finished download and extraction of redis source files."

# Access the extracted redis files
cd "$REDIS_FOLDER_NAME" || exit 1

echo "$((++step)). Building redis-cli from source files, sit back and relax, this operation can take a while..."

start_time=$(date +%s.%2N)
# Build the actual redis files, which will also build our desired 'redis-cli'
make BUILD_TLS=yes &>/dev/null
end_time=$(date +%s.%2N)

# Exit if the redis wasn't built successfully
if [ ! -e "$REDIS_CLI_BUILT_PATH" ]; then
    echo ""
    >&2 read -p "Failed to build redis-cli! Press any button to exit."
    exit 1
fi
echo "Build time of redis-cli: $(echo "scale=2; $end_time - $start_time" | bc)s"

new_redis_version=$("$REDIS_CLI_BUILT_PATH" --version | grep -E -o "[0-9\.]+")

# Verify if the redis-cli already exists, and if so, ask the user if he really wants to get rid of the old file
if [ -f "$DESTINATION_FILE" ]; then
    current_redis_version=$("$DESTINATION_FILE" --version | grep -E -o "[0-9\.]+")
    printBanner && \
        printf "WARNING: You already have a redis-cli in your %s folder.\nCurrent redis-cli version: %s. New redis-cli version: %s.\nDo you want to replace it? (y/n) " "$DESTINATION_FILE" "$current_redis_version" "$new_redis_version"
    readKeys "y" "n"

    if [ "$userInput" != "y" ]; then
        printBanner && echo "Fair enough, bye..."
        sleep 3
        clear && exit 1
    else
        echo ""
        echo "$((++step)). Removing old redis-cli file..."
        sudo rm "$DESTINATION_FILE"
        if [ -f "$DESTINATION_FILE" ]; then
            read -p "Failed to remove redis-cli file from '$DESTINATION_FOLDER' folder. Press any button to exit."
            exit 1
        fi
        echo "Successfully removed old redis-cli file."
    fi
fi

echo "$((++step)). Copying redis-cli file to $DESTINATION_FOLDER folder..."

# Copy the built 'redis-cli' to the binary folder so we can use it
sudo cp "$REDIS_CLI_BUILT_PATH" "$DESTINATION_FOLDER"

if [ ! -e "$DESTINATION_FILE" ]; then
    read -p "Failed to copy redis-cli file to '$DESTINATION_FOLDER' folder. Press any button to exit."
    exit 1
fi
echo "$((++step)). Successfully copied redis-cli file, setting its permissions to 755..."

# Set 'redis-cli' permissions so we can execute it as normal user
sudo chmod 755 "$DESTINATION_FILE"

echo ""
read -p "Finished installation of redis-cli version $new_redis_version, press any button to exit..."
exit 0
