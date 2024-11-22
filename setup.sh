#!/bin/bash
export NVM_DIR="${XDG_CONFIG_HOME:-${HOME}/.nvm}"
if [ ! -f "$NVM_DIR/nvm.sh" ]; then
    echo "Please install nvm before running this script"
    exit 1
fi

source "$NVM_DIR/nvm.sh"

REPO_PATH="${1:-/path/to/your/local/shardeum/repo}"
REPO_NAME="shardeum"
CLI_NAME="validator-cli"
GUI_NAME="validator-gui"
RPC_NAME="json-rpc-server"
FORCE_INSTALL=${2:-false}  # Second parameter to force fresh install

# Function to check if node_modules is valid
check_node_modules() {
    local dir=$1
    if [ ! -d "$dir/node_modules" ]; then
        return 1
    fi
    # Check if package.json is newer than node_modules
    if [ "$dir/package.json" -nt "$dir/node_modules" ]; then
        return 1
    fi
    return 0
}

if [ -d "$REPO_PATH" ]; then
    echo "Repository path exists: $REPO_PATH"
    pushd "$REPO_PATH"
else
    echo "No existing Shardeum installation found, cloning..."
    mkdir -p .local
    pushd .local
    if [ -d $REPO_NAME ]; then
        rm -rf $REPO_NAME
    fi
    git clone https://github.com/shardeum/shardeum.git || exit 1
    pushd "$REPO_NAME"
    FORCE_INSTALL=true  # Force install for fresh clone
fi

if ! node --version | grep -q "v18"; then
    echo "Installing Node.js 18.16.1..."
    nvm install 18.16.1 && nvm use 18.16.1 || exit 1
fi

if ! command -v rustc &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    rustup toolchain install 1.74.1
    rustup default 1.74.1
fi

install_linux() {
    sudo apt-get update && sudo apt-get install -y build-essential
}

install_macos() {
    if ! command -v brew &> /dev/null; then
        echo "Please install Homebrew first"
        exit 1
    fi
    brew update
    brew install gcc
}

case "$OSTYPE" in
    linux-gnu*) install_linux ;;
    darwin*) install_macos ;;
    *) echo "Unsupported OS: $OSTYPE"; exit 1 ;;
esac

if [ "$FORCE_INSTALL" = true ] || ! check_node_modules "$PWD"; then
    echo "Installing Shardeum dependencies..."
    npm ci
else
    echo "Skipping Shardeum dependencies installation (already installed)"
fi

echo "Applying debug configuration..."
CONFIG_FILE="src/config/index.ts"
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    sed -i.bak -e '
        s/baselineNodes: process.env.baselineNodes ? parseInt(process.env.baselineNodes) : 640/baselineNodes: process.env.baselineNodes ? parseInt(process.env.baselineNodes) : 10/g
        s/minNodes: process.env.minNodes ? parseInt(process.env.minNodes) : 640/minNodes: process.env.minNodes ? parseInt(process.env.minNodes) : 10/g
        s/forceBogonFilteringOn: true/forceBogonFilteringOn: false/g
        s/mode: '\''release'\''/mode: '\''debug'\''/g
        s/startInFatalsLogMode: true/startInFatalsLogMode: false/g
        s/startInErrorLogMode: false/startInErrorLogMode: true/g
    ' "$CONFIG_FILE"
    rm -f "${CONFIG_FILE}.bak"
fi

npm run prepare

command -v shardus &> /dev/null || npm install -g shardus @shardus/archiver

echo "Starting local network..."
shardus start 10 || exit 1

echo "Setting up JSON RPC Server..."
cd ..
if [ ! -d "$RPC_NAME" ]; then
    git clone https://github.com/shardeum/json-rpc-server.git || exit 1
fi
cd json-rpc-server

if [ "$FORCE_INSTALL" = true ] || ! check_node_modules "$PWD"; then
    echo "Installing RPC Server dependencies..."
    npm install
else
    echo "Skipping RPC Server dependencies installation (already installed)"
fi

npm run compile
echo "Starting RPC Server in background..."
node pm2.js 1 &

echo "Waiting for RPC server to start..."
sleep 10

echo "Setting up Validator CLI..."
cd ..
if [ ! -d "$CLI_NAME" ]; then
    git clone https://github.com/shardeum/validator-cli.git || exit 1
fi
cd validator-cli

echo "Creating symlink to Shardeum repository..."
ln -sf "../$REPO_NAME" ../validator
ls ../validator || exit 1

if [ "$FORCE_INSTALL" = true ] || ! check_node_modules "$PWD"; then
    echo "Installing CLI dependencies..."
    npm ci
else
    echo "Skipping CLI dependencies installation (already installed)"
fi

npm link

cat > src/config/default-network-config.ts << EOL
export const defaultNetworkConfig = {
  server: {
    baseDir: '.',
    p2p: {
      existingArchivers: [
        {
          ip: '127.0.0.1',
          port: 4000,
          publicKey: '758b1c119412298802cd28dbfa394cdfeecc4074492d60844cc192d632d84de3',
        },
      ],
    },
    ip: {
      externalIp: '127.0.0.1',
      externalPort: 9050,
      internalIp: '127.0.0.1',
      internalPort: 10045,
    },
    reporting: {
      report: true,
      recipient: 'http://localhost:3000/api',
      interval: 2,
      console: false,
    },
  },
};
EOL

npm run compile

echo "Setting up Validator GUI..."
cd ..
if [ ! -d "$GUI_NAME" ]; then
    git clone https://github.com/shardeum/validator-gui.git || exit 1
fi
cd validator-gui

if [ "$FORCE_INSTALL" = true ] || ! check_node_modules "$PWD"; then
    echo "Installing GUI dependencies..."
    npm install
else
    echo "Skipping GUI dependencies installation (already installed)"
fi

npm link operator-cli

cat > .env << EOL
NEXT_PUBLIC_RPC_URL=http://127.0.0.1:8080
PORT=8081
RPC_SERVER_URL=http://127.0.0.1:8080
NODE_ENV=development
EOL

npm run build
npm run start &

echo "Setup complete! Your local Shardeum environment is ready:"
echo "1. Shardeum Network (10 nodes)"
echo "2. JSON RPC Server (running on port 8080)"
echo "3. Validator CLI (linked to network)"
echo "4. Validator GUI (running on port 8081)"
echo ""
echo "Access GUI: http://localhost:8081"
echo "Set password with: operator-cli gui set password <your-password>"