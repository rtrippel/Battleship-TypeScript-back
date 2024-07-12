#!/bin/bash

# Check if Docker Desktop is running
if ! docker info >/dev/null 2>&1; then
    # Docker Desktop is not running, attempt to start it
    open --background -a Docker
    echo "Starting Docker Desktop..."
    # Wait for Docker to start (adjust sleep time as needed)
    sleep 5
fi

# Continue with your deployment script here

# Load environment variables from deploy.env
set -o allexport
source .env
set +o allexport

# Remove old files on the remote server and local
rm ./my-app.tar
rm -r ./dist

ssh -i "$SSH_KEY" "$REMOTE_USER@$SERVER_IP" << EOF
docker-compose --env-file $REMOTE_PATH/.env -f $REMOTE_PATH/docker-compose.yml down
docker image rm my-app:latest || true
EOF

ssh -i "$SSH_KEY" "$REMOTE_USER@$SERVER_IP" "rm -r $REMOTE_PATH"

# Install dependencies
npm install

# Build the project
npm run build

Build the Docker image for amd64

docker build --platform linux/amd64 -t my-app .

# Save the Docker image to a file
docker save -o my-app.tar my-app:latest

## Wait until the Docker image file is completely created
#echo "Waiting for the Docker image file to be created..."
#sleep 10

# Create the directory if it doesn't exist
ssh -i "$SSH_KEY" "$REMOTE_USER@$SERVER_IP" "mkdir -p $REMOTE_PATH"

# Copy the Docker image file to the remote server
scp -i "$SSH_KEY" my-app.tar "$REMOTE_USER@$SERVER_IP:$REMOTE_PATH/my-app.tar"

# Copy the Docker Compose file to the remote server
scp -i "$SSH_KEY" "$DOCKER_COMPOSE_FILE" "$REMOTE_USER@$SERVER_IP:$REMOTE_PATH/docker-compose.yml"

# Copy the .env file to the remote server
scp -i "$SSH_KEY" "$ENV_FILE" "$REMOTE_USER@$SERVER_IP:$REMOTE_PATH/.env"

echo "Finished Copy Files..."

# SSH into the remote server, load the Docker image, and run Docker Compose
ssh -i "$SSH_KEY" "$REMOTE_USER@$SERVER_IP" << EOF
docker load -i $REMOTE_PATH/my-app.tar
docker-compose --env-file $REMOTE_PATH/.env -f $REMOTE_PATH/docker-compose.yml up
#docker-compose --env-file $REMOTE_PATH/.env -f $REMOTE_PATH/docker-compose.yml up -d
EOF
