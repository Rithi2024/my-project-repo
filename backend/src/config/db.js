const sql = require("mssql");

const config = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  server: process.env.DB_SERVER,
  options: {
    encrypt: false,
    trustServerCertificate: true,
  },
};

let pool; // reuse one pool

async function connectDb() {
  try {
    pool = await sql.connect(config);
    console.log("SQL Server connected");
    return pool;
  } catch (err) {
    console.error("SQL Server connection failed:", err.message);
    throw err;
  }
}

function getPool() {
  if (!pool) throw new Error("DB not connected yet");
  return pool;
}

module.exports = { sql, connectDb, getPool };
