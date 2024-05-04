import http, { IncomingMessage, ServerResponse } from "http";
import dotenv from 'dotenv';
dotenv.config();

const host = "0.0.0.0";
const port = +process.env.APP_PORT! || 4000;

const requestListener = function (req: IncomingMessage, res: ServerResponse) {
  res.writeHead(200);
  res.end("Hello world 2");
};

const server = http.createServer(requestListener);
server.listen(port, host, () => {
  console.log(`Server is running on http://${host}:${port}`);
});
