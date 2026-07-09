require('dotenv').config();
const http = require('http');
const { createApp } = require('./app');
const { attachWebSocketServer } = require('./websocket');
const { runEconomyTick } = require('./economy');
const broadcaster = require('./services/broadcaster');

const app = createApp();
const server = http.createServer(app);
attachWebSocketServer(server);

const tickMs = Math.max(10, Number(process.env.TICK_SECONDS || 30)) * 1000;
setInterval(() => runEconomyTick(payload => broadcaster.broadcast(payload)).catch(console.error), tickMs);

const port = Number(process.env.PORT || 3000);
server.listen(port, () => console.log(`World Empire server running on :${port}`));
