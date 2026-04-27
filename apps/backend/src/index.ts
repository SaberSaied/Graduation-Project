import app from './app';
import { env } from './config/env';

const PORT = env.PORT;

app.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════════════════╗
  ║   💰 Finance Manager API                      ║
  ║   Running on: http://localhost:${PORT}        ║
  ║   Environment: ${env.NODE_ENV.padEnd(29)}     ║
  ╚═══════════════════════════════════════════════╝
  `);
});
