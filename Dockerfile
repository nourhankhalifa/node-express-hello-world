# Use the official Node.js 14 base image
FROM node:14

# Set the working directory inside the container
WORKDIR /app

# Copy app
COPY . .

# Install dependencies
RUN npm install

# Expose the port on which the application listens
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
