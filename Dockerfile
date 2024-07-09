# Use the official Node.js image as a base
FROM node:20-alpine

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy the compiled files (assuming they were compiled outside Docker)
COPY dist ./dist

# Set environment variables
ENV NODE_ENV=production

# Expose port
EXPOSE 3000

# Command to run the application
CMD ["node", "dist/index.js"]
