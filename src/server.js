'use strict';

const express = require('express');
const path = require('path');

const APP_VERSION =
  process.env.APP_VERSION?.trim() || process.env.npm_package_version || '1.0.0';

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/health', (_req, res) => {
  res.status(200).json({ ok: true, version: APP_VERSION });
});

app.get('/hello/:name', (req, res) => {
  const name = String(req.params.name ?? '');
  res.type('json').json({
    greeting: `Hello, ${name}`,
    slot: process.env.DEPLOY_SLOT || 'direct',
  });
});

app.get('/', (_req, res) => {
  res.redirect('/form');
});

app.get('/form', (_req, res) => {
  res.sendFile(path.join(__dirname, 'views', 'form.html'));
});

app.post('/api/message', (req, res) => {
  const message =
    typeof req.body?.message === 'string'
      ? req.body.message
      : req.body?.message != null
        ? String(req.body.message)
        : '';
  const trimmed = message.trim();
  if (!trimmed) {
    res.status(400).json({ error: 'message is required' });
    return;
  }
  res.status(200).json({ echo: trimmed, receivedAt: new Date().toISOString() });
});

const port = Number(process.env.PORT) || 3000;

function listen() {
  return app.listen(port, () => {
    // eslint-disable-next-line no-console
    console.log(`Listening on ${port} version=${APP_VERSION}`);
  });
}

module.exports = { app, listen, APP_VERSION };

if (require.main === module) {
  listen();
}
