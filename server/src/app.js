const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { registerRoutes } = require('./routes');
const { notFound, errorHandler } = require('./middleware/errorHandler');

function createApp() {
  const app = express();
  app.use(helmet());
  app.use(cors());
  app.use(express.json({ limit: '1mb' }));

  app.get('/health', (_, res) => res.json({ ok: true, name: 'world-empire-game-server' }));

  registerRoutes(app);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
