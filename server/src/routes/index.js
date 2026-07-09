const authRoutes = require('./auth.routes');
const worldRoutes = require('./world.routes');
const cityRoutes = require('./cities.routes');
const propertyRoutes = require('./properties.routes');
const businessRoutes = require('./businesses.routes');
const adminRoutes = require('./admin.routes');

function registerRoutes(app) {
  app.use('/api/auth', authRoutes);
  app.use('/api/world', worldRoutes);
  app.use('/api/cities', cityRoutes);
  app.use('/api/properties', propertyRoutes);
  app.use('/api/businesses', businessRoutes);
  app.use('/api/admin', adminRoutes);
}

module.exports = { registerRoutes };
