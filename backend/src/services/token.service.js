const { prisma } = require('../config/prisma');
const { env } = require('../config/env');
const {
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
  hashToken,
} = require('../utils/jwt');
const { UnauthorizedError } = require('../utils/app-error');

// Issues a fresh access + refresh token pair for a user and persists the
// refresh token (hashed) so it can later be looked up, rotated, or revoked.
async function issueTokenPair(user) {
  const accessToken = signAccessToken({
    userId: user.id,
    role: user.role,
    instituteId: user.instituteId,
  });

  const { token: refreshToken } = signRefreshToken({ userId: user.id });

  await prisma.refreshToken.create({
    data: {
      userId: user.id,
      tokenHash: hashToken(refreshToken),
      expiresAt: new Date(Date.now() + env.refreshTokenExpiresInMs),
    },
  });

  return { accessToken, refreshToken };
}

// Verifies a refresh token's signature AND that a matching, non-revoked,
// non-expired row still exists in the DB - so a token can be individually
// killed server-side even if it hasn't expired yet (rotation/logout/theft).
// async function findValidRefreshTokenRecord(refreshToken) {
//   let payload;
//   try {
//     payload = verifyRefreshToken(refreshToken);
//   } catch {
//     throw new UnauthorizedError('Invalid or expired refresh token');
//   }

//   const record = await prisma.refreshToken.findUnique({
//     where: { tokenHash: hashToken(refreshToken) },
//     include: { user: true },
//   });

//   if (!record || record.revokedAt || record.expiresAt < new Date()) {
//     throw new UnauthorizedError('Refresh token is no longer valid');
//   }

//   if (record.userId !== payload.sub) {
//     throw new UnauthorizedError('Invalid refresh token');
//   }

//   return record;
// }
async function findValidRefreshTokenRecord(refreshToken) {
  console.log('[AUTH DEBUG] refresh token received:', !!refreshToken);

  let payload;

  try {
    payload = verifyRefreshToken(refreshToken);
    console.log('[AUTH DEBUG] JWT verification: PASS');
  } catch {
    console.log('[AUTH DEBUG] JWT verification: FAIL');
    throw new UnauthorizedError('Invalid or expired refresh token');
  }

  const record = await prisma.refreshToken.findUnique({
    where: { tokenHash: hashToken(refreshToken) },
    include: { user: true },
  });

  console.log('[AUTH DEBUG] database record found:', !!record);

  if (record) {
    console.log('[AUTH DEBUG] revoked:', !!record.revokedAt);
    console.log('[AUTH DEBUG] expired:', record.expiresAt < new Date());
    console.log('[AUTH DEBUG] user matches:', record.userId === payload.sub);
  }

  if (!record || record.revokedAt || record.expiresAt < new Date()) {
    throw new UnauthorizedError('Refresh token is no longer valid');
  }

  if (record.userId !== payload.sub) {
    throw new UnauthorizedError('Invalid refresh token');
  }

  return record;
}
async function revokeRefreshTokenRecord(recordId) {
  await prisma.refreshToken.update({
    where: { id: recordId },
    data: { revokedAt: new Date() },
  });
}

// Rotation: the presented refresh token is revoked and a brand new pair is
// issued. If a revoked/expired token is replayed, the caller must re-login.
async function rotateTokens(refreshToken) {
  const record = await findValidRefreshTokenRecord(refreshToken);
  await revokeRefreshTokenRecord(record.id);
  return issueTokenPair(record.user);
}

// Logout: revoke the specific refresh token presented. Idempotent - if it's
// already gone/invalid, logout still succeeds from the client's perspective.
async function revokeByToken(refreshToken) {
  try {
    const record = await findValidRefreshTokenRecord(refreshToken);
    await revokeRefreshTokenRecord(record.id);
  } catch {
    // Already invalid/expired/revoked - nothing to do.
  }
}

module.exports = {
  issueTokenPair,
  rotateTokens,
  revokeByToken,
  findValidRefreshTokenRecord,
};
