const { PrismaClient } = require('@prisma/client');

// Singleton so we don't exhaust Postgres connections with hot-reload in dev.
const prisma = global.__prisma || new PrismaClient();

if (process.env.NODE_ENV !== 'production') {
  global.__prisma = prisma;
}

module.exports = { prisma };
