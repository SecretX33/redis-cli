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

printBanner() {
    clear
    echo "===================================================="
    echo "=============  Auto install redis-cli  ============="
    echo "===================================================="
    echo ""
}

download() {
    url="$1"
    filename="$2"

    if [ -x "$(which wget)" ] ; then
        wget -q "$url" -O "$filename"
    elif [ -x "$(which curl)" ]; then
        curl -sL "$url" -o "$filename"
    else
        read -p "Could not find curl or wget, please install one. Press any button to exit."
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
sudo apt-get update > /dev/null && \
    sudo apt-get install gcc make -y >/dev/null

echo "$((++step)). Downloading and extracting redis source files..."
download http://download.redis.io/redis-stable.tar.gz redis-stable.tar.gz && \
    tar xzf redis-stable.tar.gz

# Exit if the redis compressed file wasn't extracted successfully
if [ ! -e "redis-stable" ]; then
    >&2 read -p "Failed to extract redis-cli tarball! Press any button to exit."
    exit 1
fi
echo "Finished download and extraction of redis source files!"

# Access the extracted redis files
cd redis-stable || exit 1

echo "$((++step)). Building redis-cli from source files, sit back and relax for some minutes, this operation can take a while..."

start_time=$(date +%s.%2N)
# Build the actual redis files, which will also build our desired 'redis-cli'
make &>/dev/null
end_time=$(date +%s.%2N)

# Exit if the redis wasn't built successfully
if [ ! -e "src/redis-cli" ]; then
    echo ""
    >&2 read -p "Failed to build redis-cli! Press any button to exit."
    exit 1
fi
echo "Build time of redis-cli: $(echo "scale=2; $end_time - $start_time" | bc)s"


# Verify if the redis-cli already exists, and if so, ask the user if he really wants to get rid of the old file
if [ -f "/usr/local/bin/redis-cli" ]; then
    printBanner && \
        printf "WARNING: redis-cli already exists in your /usr/local/bin folder.\nDo you want to replace it? (y/n) "
    readKeys "y" "n"

    if [ "$userInput" != "y" ]; then
        printBanner && echo "Fair enough, bye..."
        sleep 3
        clear && exit 1
    else
        echo ""
        echo "$((++step)). Removing old redis-cli file..."
        sudo rm "/usr/local/bin/redis-cli"
        if [ -f "/usr/local/bin/redis-cli" ]; then
            read -p "Failed to remove redis-cli file from '/usr/local/bin' folder. Press any button to exit."
            exit 1
        fi
        echo "Successfully removed old redis-cli file!"
    fi
fi

echo "$((++step)). Copying redis-cli file to /usr/local/bin folder..."

# Copy the built 'redis-cli' to the binary folder so we can use it
sudo cp src/redis-cli /usr/local/bin/

if [ ! -e "/usr/local/bin/redis-cli" ]; then
    read -p "Failed to copy redis-cli file to '/usr/local/bin' folder. Press any button to exit."
    exit 1
fi
echo "$((++step)). Successfully copied redis-cli file, setting its permissions to 755..."

# Set 'redis-cli' permissions so we can execute it as normal user
sudo chmod 755 /usr/local/bin/redis-cli

read -p "Finished installation of redis-cli, press any button to exit..."
exit 1
