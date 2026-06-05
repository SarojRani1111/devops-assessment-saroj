const express = require('express');
const pino = require('pino');
const pinoHttp = require('pino-http');
const client = require('prom-client');

// ── Logger setup ─────────────────────────────────────────────
const logger = pino({
  level: 'info',
  formatters: {
    level: (label) => ({ level: label })
  }
});

// ── Prometheus metrics setup ──────────────────────────────────
const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10]
});

const httpRequestTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);

// ── Express setup ─────────────────────────────────────────────
const app = express();
const PORT = process.env.PORT || 3001;

app.use(pinoHttp({ logger }));
app.use(express.json());

// ── Middleware: track metrics ─────────────────────────────────
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(duration);
    httpRequestTotal
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .inc();
  });
  next();
});

// ── Routes ────────────────────────────────────────────────────
app.get('/', (req, res) => {
  logger.info({ method: req.method, path: '/', status: 200 });
  res.json({
    service: 'backend',
    status: 'running',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  logger.info({ path: '/health', status: 200, message: 'Health check ok' });
  res.json({
    status: 'ok',
    service: 'backend',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
    logger.info({ path: '/metrics', status: 200 });
  } catch (err) {
    logger.error({ path: '/metrics', error: err.message });
    res.status(500).json({ error: 'Failed to collect metrics' });
  }
});

app.get('/api/users', (req, res) => {
  logger.info({ path: '/api/users', status: 200 });
  res.json({
    users: [
      { id: 1, name: 'Alice', role: 'admin' },
      { id: 2, name: 'Bob', role: 'user' }
    ]
  });
});

app.get('/api/status', (req, res) => {
  logger.info({ path: '/api/status', status: 200 });
  res.json({
    status: 'ok',
    database: 'connected',
    cache: 'connected',
    timestamp: new Date().toISOString()
  });
});

app.use((req, res) => {
  logger.warn({ path: req.path, status: 404, message: 'Route not found' });
  res.status(404).json({ error: 'Route not found', path: req.path });
});

app.use((err, req, res, next) => {
  logger.error({ error: err.message, status: 500 });
  res.status(500).json({ error: 'Internal server error' });
});

// ── Start server ──────────────────────────────────────────────
app.listen(PORT, () => {
  logger.info({ message: `Backend API running on port ${PORT}` });
});