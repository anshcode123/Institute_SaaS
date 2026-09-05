const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { env } = require('../config/env');

// Access token payload: userId, role, instituteId (trusted source of
// tenant/role context for every downstream request - see authenticate.js).
function signAccessToken({ userId, role, instituteId }) {
  return jwt.sign({ sub: userId, role, instituteId: instituteId ?? null }, env.jwtAccessSecret, {
    expiresIn: env.accessTokenExpiresIn,
  });
}

function verifyAccessToken(token) {
  return jwt.verify(token, env.jwtAccessSecret);
}

// Refresh tokens are opaque JWTs too (so they self-expire), but the
// server never trusts a refresh token's claims alone - it also requires
// a matching, non-revoked, non-expired row in RefreshToken (looked up by
// hash) so a token can be individually revoked/rotated server-side.
function signRefreshToken({ userId }) {
  const jti = crypto.randomUUID();
  const token = jwt.sign({ sub: userId, jti }, env.jwtRefreshSecret, {
    expiresIn: env.refreshTokenExpiresIn,
  });
  return { token, jti };
}

function verifyRefreshToken(token) {
  return jwt.verify(token, env.jwtRefreshSecret);
}

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

module.exports = {
  signAccessToken,
  verifyAccessToken,
  signRefreshToken,
  verifyRefreshToken,
  hashToken,
};
