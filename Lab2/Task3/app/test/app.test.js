const request = require('supertest');
const app = require('../src/app');

describe('Microservice API Endpoints Tests', () => {

  it('GET / should return welcome message and status 200', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('status', 'success');
    expect(res.body).toHaveProperty('message');
  });

  it('GET /api/health should return health metrics and status 200', async () => {
    const res = await request(app).get('/api/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('status', 'healthy');
    expect(res.body).toHaveProperty('uptime');
  });

  it('GET /api/info should return team info and 4 members', async () => {
    const res = await request(app).get('/api/info');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('team', 'Nhom 04');
    expect(res.body.members).toHaveLength(4);
  });

  it('should not disclose framework via X-Powered-By header', async () => {
    const res = await request(app).get('/api/health');
    expect(res.headers).not.toHaveProperty('x-powered-by');
  });

});
