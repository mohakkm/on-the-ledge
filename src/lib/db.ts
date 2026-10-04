import mysql, { type ResultSetHeader } from "mysql2/promise";

/**
 * Server-only MySQL pool. Import from Server Components, Route Handlers,
 * or Server Actions — never from client components.
 */
const globalForDb = globalThis as unknown as {
  mysqlPool?: mysql.Pool;
};

function createPool() {
  return mysql.createPool({
    host: process.env.MYSQL_HOST ?? "127.0.0.1",
    port: Number(process.env.MYSQL_PORT ?? "3306"),
    user: process.env.MYSQL_USER,
    password: process.env.MYSQL_PASSWORD,
    database: process.env.MYSQL_DATABASE ?? "on_the_ledge",
    waitForConnections: true,
    connectionLimit: 10,
    namedPlaceholders: true,
  });
}

export function getPool(): mysql.Pool {
  if (!globalForDb.mysqlPool) {
    globalForDb.mysqlPool = createPool();
  }
  return globalForDb.mysqlPool;
}

type QueryParams = Record<string, string | number | null>;

export async function query<T>(
  sql: string,
  params?: QueryParams,
): Promise<T[]> {
  const [rows] = await getPool().execute(sql, params);
  return rows as T[];
}

export async function execute(
  sql: string,
  params?: QueryParams,
): Promise<ResultSetHeader> {
  const [result] = await getPool().execute(sql, params);
  return result as ResultSetHeader;
}
