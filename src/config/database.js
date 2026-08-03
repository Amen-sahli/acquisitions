import 'dotenv/config';
import {neon, neonConfig} from '@neondatabase/serverless';
import {drizzle} from 'drizzle-orm/neon-http';

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL environment variable is not set');
}

const isNeonLocal = !new URL(databaseUrl).hostname.endsWith('neon.tech');

if (isNeonLocal) {
  const {hostname, port} = new URL(databaseUrl);
  neonConfig.fetchEndpoint = `http://${hostname}:${port || '5432'}/sql`;
  neonConfig.useSecureWebSocket = false;
  neonConfig.poolQueryViaFetch = true;
}

export const sql = neon(databaseUrl);

export const db = drizzle(sql);
