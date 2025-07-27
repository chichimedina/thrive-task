## Use an official Node.js runtime as the base image
FROM node:latest

## Set the working directory inside the container
WORKDIR /app

## Copy package.json and package-lock.json to install dependencies
COPY ../app/app.js ./

## Install application dependencies
RUN npm init -y && npm install

## Expose the port your Node.js application listens on
EXPOSE 5050

## Define the command to run your application
CMD ["node", "app.js"]
