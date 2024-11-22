# Shardeum Local Development Setup Script

This script automates the setup of a complete Shardeum local development environment, including a local network, validator GUI/CLI, and RPC server.

## Overview

The setup script installs and configures the following components:
- Local Shardeum network (10 nodes)
- Validator CLI
- Validator GUI
- JSON RPC Server

## Prerequisites

The script will help install these, but your system should be capable of running:
- Node.js (v18.16.1)
- Rust (v1.74.1)
- Build essentials (gcc, make, etc.)
- Python 3
- Git

## Installation

1. Download the setup script: 

```bash
git clone `this repo`
chmod +x setup.sh
```

2. Run the script:

```bash
./setup.sh
```
## Usage

1. Clone this repository:   ```bash
   git clone <repository-url>
   cd <repository-name>   ```

2. Make the script executable:   ```bash
   chmod +x setup.sh   ```

3. Run the setup script:   ```bash
   ./setup.sh [REPO_PATH] [FORCE_INSTALL]   ```

   Parameters:
   - `REPO_PATH` (optional): Path to your local Shardeum repository (if you already have it)
   - `FORCE_INSTALL` (optional): Set to `true` to force fresh installation 


## The script will:

- Create a `.local` base directory for the installations
- Install all required services and dependencies
- Set up the local Shardeum network
- Set up the JSON RPC server
- Configure and start the validator tools (CLI and GUI)

## Components Installed

### 1. Local Shardeum Network
- 10-node local network for development
- Configured in debug mode
- Runs on localhost

### 2. Validator CLI
- Command-line interface for node management
- Configured to connect to the local network

### 3. Validator GUI
- Web interface for node management
- Runs at: http://localhost:3000 by default
- Requires the password set in Validator CLI

### 4. JSON RPC Server
- Ethereum-compatible RPC interface
- Runs at: http://localhost:8080
- Allows interaction with the network using Web3 tools


## Troubleshooting

If you encounter issues:
1. Ensure all prerequisites are properly installed
2. Check that no other services are using the required ports
3. Review the logs of the installation script
4. Look through the documentation for each component that is not working and see if you can find any issues.

## Note

> This setup is intended to quickly get a local development environment running for development purposes only