const express = require('express');

const app = express();
// Khong tiet lo framework qua header "X-Powered-By: Express" (SonarQube rule S5689)
app.disable('x-powered-by');
app.use(express.json());

// Root endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Welcome to NT548 DevOps Microservice API',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Health check endpoint (dung cho Kubernetes / Docker healthcheck)
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    uptime: process.uptime(),
    memoryUsage: process.memoryUsage()
  });
});

// Business microservice endpoint (danh sach sinh vien / thanh vien nhom)
app.get('/api/info', (req, res) => {
  res.status(200).json({
    course: 'NT548 - Cong nghe DevOps va Ung dung',
    team: 'Nhom 04',
    members: [
      { name: 'Vo Duy Hieu', role: 'Leader', id: '23520498' },
      { name: 'Hoang Le Nhat Minh', role: 'DevOps QA Lead', id: '23520926' },
      { name: 'Cam Hong Manh', role: 'Terraform IaC', id: '23520914' },
      { name: 'Le Doan Phuc Thanh', role: 'CloudFormation IaC', id: '24520030' }
    ]
  });
});

module.exports = app;
