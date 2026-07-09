const { ZodError } = require('zod');

function notFound(req, res) {
  res.status(404).json({ error: 'route_not_found', path: req.path });
}

function errorHandler(err, req, res, next) {
  console.error(err);
  if (err instanceof ZodError) {
    return res.status(400).json({ error: 'validation_error', details: err.errors });
  }
  res.status(500).json({ error: 'server_error' });
}

module.exports = { notFound, errorHandler };
