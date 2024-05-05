#!/bin/bash

# Variable defentitions

# Define installation directory
INSTALL_DIR="/opt/anything-llm"

# Set the path and name for the systemd unit file
SYSTEMD_UNIT_FILE="/etc/systemd/system/anything-llm.service"
RUN_SCRIPT="$INSTALL_DIR/startupscript.sh"




# Function to install a dependency
install_dependency() {
  # Set package variable to input package name
  local package="$1"

  # Check if package is installed
  if ! command -v "$package" &> /dev/null; then
    # If not, print message and install it
    echo "Not found. Installing..."
    # Install nodejs using apt-get
    if [ "$package" = "nodejs" ] || [ "$package" = "git" ] || [ "$package" = "npm" ]; then
      sudo apt-get install -y $package
    else
      # Install package using npm
      sudo npm install -g "$package"
    fi
  fi
}

# Function to install multiple dependencies
install_dependencies() {
  # Define an array of dependencies
  local dependencies=("nodejs" "yarn" "prisma" "dialog" "npm" "node-llama-cpp" "git")

  # Loop through each dependency and install it
  for dep in "${dependencies[@]}"; do
    install_dependency "$dep"
  done
}

# Function to verify if all dependencies are installed
verify_dependencies() {
  # Define an array of dependencies
  local dependencies=("node" "yarn" "prisma" "node-llama-cpp")

  # Loop through each dependency and check if it's installed
  for dep in "${dependencies[@]}"; do
    # Check if package is installed
    if ! command -v "$dep" &> /dev/null; then
      # If not, print message and return an error code
      echo "Not installed: $dep"
      return 1
    fi
  done

  # If all dependencies are installed, print a success message
  echo "All dependencies installed!"
}

# Run the installation and verification scripts
install_dependencies
verify_dependencies



# Check if the directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating directory $INSTALL_DIR"
    if ! sudo mkdir -p "$INSTALL_DIR"; then
        echo "Failed to create directory $INSTALL_DIR"
        exit 1
    fi
fi

# Change ownership of the directory to the current user
sudo chown -R $(whoami):$(whoami) "$INSTALL_DIR"

# Change directory to the parent directory of the installation directory
cd "$(dirname "$INSTALL_DIR")" || exit 1

# If the directory is empty, clone the Git repository
if [ -z "$(ls -A "$INSTALL_DIR")" ]; then
    echo "Cloning repository into $INSTALL_DIR"
    if ! git clone https://github.com/straydog-1212/anything-llm-baremetal-setup "$(basename "$INSTALL_DIR")"; then
        echo "Failed to clone repository into $INSTALL_DIR"
        exit 1
    fi
    echo "Repository cloned successfully"
else
    echo "$INSTALL_DIR already exists. Syncing files with git pull"
    # Change directory to the installation directory
 cd "$INSTALL_DIR" || exit 1
    # Use git pull to sync files if the directory is not empty
    if ! git pull; then
        echo "Failed to sync files with git pull"
        exit 1
    fi
    echo "Files synced successfully"
fi

# Move into the cloned directory and install dependencies
cd ${INSTALL_DIR} && yarn setup && npm init -y


cp server/.env.example server/.env
# Build the frontend application
if [ -d frontend ]; then
  cd frontend && yarn build
else
  echo "Error: Frontend directory does not exist."
  exit 1
fi

# Copy frontend/dist to server/public
if  [ -d $INSTALL_DIR/server ]; then
  cp -R $INSTALL_DIR/frontend/dist $INSTALL_DIR/server/public
  mv $INSTALL_DIR/server/dist $INSTALL_DIR/server/public
else
  echo "Error: Frontend build or server public directory does not exist."
  exit 1
fi

# Build native LLM support if using native as your LLM.
if [ -d $INSTALL_DIR/server ]; then
 cd $INSTALL_DIR/server
 yarn add node-llama-cpp
 # npx update-browserslist-db@lat est
 npx prisma generate --schema=./prisma/schema.prisma
 npx prisma migrate deploy --schema=./prisma/schema.prisma
else
  echo "Error: Server directory does not exist at $(pwd)"
  exit 1
fi



if [ -f "$SYSTEMD_UNIT_FILE" ]; then
echo "systemd unit files already exist at $SYSTEMD_UNIT_FILE"
else
cd $INSTALL_DIR
sudo mv anything-llm.service "$SYSTEMD_UNIT_FILE" || echo {"moving systemd file failed"}
fi



cd $INSTALL_DIR 
chmod +x startupscript.sh
./startupscript.sh
sudo systemctl enable anything-llm
sudo systemctl start anything-llm


# Ensure that the .env file has at least these keys to start that will be overrwriten when it runs for the first time

#cd /


