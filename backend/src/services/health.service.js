const { prisma } = require('../config/prisma');

async function getHealthStatus() {
  let database = 'unavailable';

  try {
    await prisma.$queryRaw`SELECT 1`;
    database = 'connected';
  } catch {
    database = 'unavailable';
  }

  return {
    api: 'ok',
    database,
    timestamp: new Date().toISOString(),
  };
}

module.exports = { getHealthStatus };
