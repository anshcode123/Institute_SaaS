require('dotenv').config();

function required(key, fallback) {
  const value = process.env[key] ?? fallback;
  if (value === undefined) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

// Parses simple durations like "15m", "7d", "30s", "1h" into milliseconds.
// Only needed server-side to compute RefreshToken.expiresAt; jsonwebtoken
// parses the same strings itself for the JWT "exp" claim.
function parseDurationMs(duration) {
  const match = /^(\d+)\s*(ms|s|m|h|d)$/.exec(duration.trim());
  if (!match) throw new Error(`Invalid duration format: ${duration}`);
  const value = parseInt(match[1], 10);
  const unitMs = { ms: 1, s: 1000, m: 60_000, h: 3_600_000, d: 86_400_000 };
  return value * unitMs[match[2]];
}

const refreshTokenExpiresIn = required('REFRESH_TOKEN_EXPIRES_IN', '7d');

const env = {
  nodeEnv: required('NODE_ENV', 'development'),
  port: parseInt(required('PORT', '4000'), 10),
  databaseUrl: required('DATABASE_URL'),

  jwtAccessSecret: required('JWT_ACCESS_SECRET'),
  jwtRefreshSecret: required('JWT_REFRESH_SECRET'),
  accessTokenExpiresIn: required('ACCESS_TOKEN_EXPIRES_IN', '15m'),
  refreshTokenExpiresIn,
  refreshTokenExpiresInMs: parseDurationMs(refreshTokenExpiresIn),
};

const isProduction = env.nodeEnv === 'production';

module.exports = { env, isProduction };
