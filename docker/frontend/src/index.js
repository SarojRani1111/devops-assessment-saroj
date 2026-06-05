const express = require('express');
const pino = require('pino');
const pinoHttp = require('pino-http');

// ── Logger setup ─────────────────────────────────────────────
const logger = pino({
  level: 'info',
  formatters: {
    level: (label) => ({ level: label })
  }
});

const app = express();
const PORT = process.env.PORT || 3000;
const BACKEND_URL = process.env.BACKEND_URL || 'http://backend:3001';

app.use(pinoHttp({ logger }));
app.use(express.json());

// ── Routes ────────────────────────────────────────────────────
app.get('/', (req, res) => {
  logger.info({
    method: req.method,
    path: req.path,
    status: 200,
    message: 'Frontend homepage accessed'
  });
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>CloudMaven DevOps Assessment</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          max-width: 800px;
          margin: 50px auto;
          padding: 20px;
          background: #f5f5f5;
        }
        .card {
          background: white;
          padding: 30px;
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 { color: #2c3e50; }
        .status { color: #27ae60; font-weight: bold; }
        .info { margin: 10px 0; color: #555; }
        .badge {
          background: #3498db;
          color: white;
          padding: 4px 10px;
          border-radius: 4px;
          font-size: 12px;
          margin-right: 5px;
        }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>CloudMaven DevOps Assessment</h1>
        <p class="status">● Application Running</p>
        <div class="info"><strong>Service:</strong> frontend</div>
        <div class="info"><strong>Version:</strong> 1.0.0</div>
        <div class="info"><strong>Author:</strong> Saroj</div>
        <div class="info"><strong>Backend URL:</strong> ${BACKEND_URL}</div>
        <div class="info"><strong>Timestamp:</strong> ${new Date().toISOString()}</div>
        <br/>
        <span class="badge">Kubernetes</span>
        <span class="badge">Docker</span>
        <span class="badge">Terraform</span>
        <span class="badge">AWS EKS</span>
      </div>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  logger.info({
    path: '/health',
    status: 200,
    message: 'Health check ok'
  });
  res.json({
    status: 'ok',
    service: 'frontend',
    timestamp: new Date().toISOString()
  });
});

app.get('/about', (req, res) => {
  logger.info({ path: '/about', status: 200 });
  res.json({
    service: 'frontend',
    description: 'CloudMaven DevOps Assessment',
    author: 'Saroj'
  });
});

// ── 404 handler ───────────────────────────────────────────────
app.use((req, res) => {
  logger.warn({
    path: req.path,
    status: 404,
    message: 'Route not found'
  });
  res.status(404).json({
    error: 'Route not found',
    path: req.path
  });
});

// ── Error handler ─────────────────────────────────────────────
app.use((err, req, res, next) => {
  logger.error({
    error: err.message,
    status: 500
  });
  res.status(500).json({
    error: 'Internal server error'
  });
});

// ── Start server ──────────────────────────────────────────────
app.listen(PORT, () => {
  logger.info({
    message: `Frontend running on port ${PORT}`
  });
});