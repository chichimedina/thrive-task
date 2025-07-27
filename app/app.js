const http = require('http'); // Import the built-in http module

const hostname = '0.0.0.0'; // Localhost IP address
const port = 5050; // Port for the server to listen on

// Input variable from the Jenkins pipeline
const user_input = process.env.USER_NAME || 'No name';

// Create a server instance
const server = http.createServer((req, res) => {
// Set the response HTTP header
res.statusCode = 200; // OK status
res.setHeader('Content-Type', 'text/plain'); // Plain text content

// Send the response body
res.end(`Hello ${user_input}!\n`);
});

// Start the server and listen for requests
server.listen(port, hostname, () => {
console.log(`Server running at http://${hostname}:${port}/`);
});
