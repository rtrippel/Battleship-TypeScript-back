#!/bin/bash

# Load environment variables from deploy.env
set -o allexport
source .env
set +o allexport

# Install dependencies
npm install

# Build the project
npm run build

# Build the Docker image for amd64
docker build --platform linux/amd64 -t my-app .

# Save the Docker image to a file
docker save -o my-app.tar my-app:latest

# Wait until the Docker image file is completely created
echo "Waiting for the Docker image file to be created..."
sleep 10

ssh -i "$SSH_KEY" "$REMOTE_USER@$SERVER_IP" "mkdir -p $REMOTE_PATH"

echo "Trying to COPY...my-app.tar"
# Copy the Docker image file to the remote server
scp -i "$SSH_KEY" my-app.tar "$REMOTE_USER@$SERVER_IP:$REMOTE_PATH/my-app.tar"

echo "Trying to COPY...$DOCKER_COMPOSE_FILE"
# Copy the Docker Compose file to the remote server
scp -i "$SSH_KEY" "$DOCKER_COMPOSE_FILE" "$REMOTE_USER@$SERVER_IP:$REMOTE_PATH/docker-compose.yml"

echo "Trying to COPY...$ENV_FILE"
# Copy the .env file to the remote server
scp -i "$SSH_KEY" "$ENV_FILE" "$REMOTE_USER@$SERVER_IP:$REMOTE_PATH/.env"

# SSH into the remote server, load the Docker image, and run Docker Compose
ssh -i "$SSH_KEY" "$REMOTE_USER@$SERVER_IP" << EOF
docker load -i $REMOTE_PATH/my-app.tar
docker-compose --env-file .env -f $REMOTE_PATH/docker-compose.yml up -d
EOF
