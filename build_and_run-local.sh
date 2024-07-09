#!/bin/bash

# Install dependencies
npm install

# Build the project
npm run build

# Build the Docker image
docker build -t my-app .

# Run the Docker container
docker run -p 3000:3000 --env-file .env my-app
