'use strict';

const request = require('supertest');
const { app } = require('../src/server');

describe('HTTP API', () => {
  test('GET /health returns OK', async () => {
    const res = await request(app).get('/health').expect(200);
    expect(res.body).toMatchObject({ ok: true });
    expect(typeof res.body.version).toBe('string');
  });

  test('GET /hello/:name dynamic route', async () => {
    const res = await request(app).get('/hello/DevOps').expect(200);
    expect(res.body.greeting).toBe('Hello, DevOps');
  });

  test('POST /api/message echoes JSON payload', async () => {
    const res = await request(app)
      .post('/api/message')
      .send({ message: '  hi there  ' })
      .expect(200);
    expect(res.body.echo).toBe('hi there');
    expect(res.body.receivedAt).toBeTruthy();
  });

  test('POST /api/message rejects empty message', async () => {
    const res = await request(app).post('/api/message').send({ message: '' }).expect(400);
    expect(res.body.error).toBeTruthy();
  });
});
