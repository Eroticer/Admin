const http = require('http');
const hostname = '0.0.0.0';
const port = 3000;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/html');
  res.end(`
    <html>
      <head><title>Node.js App</title></head>
      <body>
        <h1>Hello from Node.js server!</h1>
        <p>This Node.js application is running successfully.</p>
        <p>Current time: ${new Date().toISOString()}</p>
      </body>
    </html>
  `);
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});
