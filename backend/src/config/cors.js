// Widen this list as frontend origins (web/emulator) are added.
const allowedOrigins = ['http://localhost:3000', 'http://localhost:5173', 'http://localhost:1808'];

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
};

module.exports = { corsOptions };
