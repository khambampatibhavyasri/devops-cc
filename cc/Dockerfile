# Frontend Dockerfile
FROM node:18

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Set environment variable for React development server
ENV PORT=3000

# Expose port 3000
EXPOSE 3000

# Start the React development server
CMD ["npm", "start"]
