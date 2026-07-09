const WebSocket = require('ws');
const { verify } = require('../auth');
const { query } = require('../db');
const broadcaster = require('../services/broadcaster');

function attachWebSocketServer(server) {
  const wss = new WebSocket.Server({ server });
  const sockets = new Map();

  function broadcast(payload) {
    const json = JSON.stringify(payload);
    for (const ws of sockets.keys()) {
      if (ws.readyState === WebSocket.OPEN) ws.send(json);
    }
  }

  broadcaster.setSender(broadcast);

  wss.on('connection', (ws, req) => {
    try {
      const url = new URL(req.url, 'http://localhost');
      const token = url.searchParams.get('token');
      const user = verify(token);
      sockets.set(ws, user);
      ws.send(JSON.stringify({ type: 'hello', user }));

      ws.on('message', async raw => {
        try {
          const msg = JSON.parse(raw.toString());
          if (msg.type === 'chat') {
            const text = String(msg.message || '').slice(0, 300).trim();
            if (!text) return;
            await query('INSERT INTO chat_messages(city_id,user_id,message) VALUES($1,$2,$3)', [msg.cityId || null, user.id, text]);
            broadcast({ type: 'chat', cityId: msg.cityId || null, userId: user.id, name: user.display_name || user.email, message: text, at: new Date().toISOString() });
          }
        } catch {
          ws.send(JSON.stringify({ type: 'error', error: 'bad_message' }));
        }
      });

      ws.on('close', () => sockets.delete(ws));
    } catch {
      ws.close(1008, 'auth required');
    }
  });

  return { wss, broadcast };
}

module.exports = { attachWebSocketServer };
