const { createApp } = require('./app');
const { env } = require('./config/env');
const { startFeeReminderScheduler } = require('./services/fee-reminder.service');

const app = createApp();

app.listen(env.port, '0.0.0.0', () => {
  console.log(`[server] running in ${env.nodeEnv} mode on http://localhost:${env.port}`);
  console.log(`[server] health check: http://localhost:${env.port}/api/health`);
  startFeeReminderScheduler();
});
