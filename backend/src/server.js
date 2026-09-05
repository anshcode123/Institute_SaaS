const { createApp } = require('./app');
const { env } = require('./config/env');

const app = createApp();

app.listen(env.port, () => {
  console.log(`[server] running in ${env.nodeEnv} mode on http://localhost:${env.port}`);
  console.log(`[server] health check: http://localhost:${env.port}/api/health`);
});
