const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const sql = require("mssql");

// Helper: basic email check (simple but ok for assignment)
function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// Helper: password strength (min 6; you can increase rules)
function isStrongPassword(password) {
  return typeof password === "string" && password.length >= 6;
}

async function signup(req, res) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Missing fields" });
    }
    if (!isValidEmail(email)) {
      return res.status(400).json({ message: "Invalid email format" });
    }
    if (!isStrongPassword(password)) {
      return res.status(400).json({ message: "Password too weak (min 6 chars)" });
    }

    // check duplicate
    const dup = await sql.query`
      SELECT id FROM Users WHERE email = ${email}
    `;
    if (dup.recordset.length > 0) {
      return res.status(409).json({ message: "Email already exists" });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    await sql.query`
      INSERT INTO Users (email, password_hash)
      VALUES (${email}, ${passwordHash})
    `;

    return res.status(201).json({ message: "Sign up successful" });
  } catch (err) {
    console.error("signup error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

async function login(req, res) {
  try {
    const { email, password } = req.body; // allow username later if you want

    if (!email || !password) {
      return res.status(400).json({ message: "Missing fields" });
    }

    const result = await sql.query`
      SELECT TOP 1 id, email, password_hash
      FROM Users
      WHERE email = ${email}
    `;

    if (!result.recordset.length) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const user = result.recordset[0];
    const ok = await bcrypt.compare(password, user.password_hash);

    if (!ok) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    return res.json({ token });
  } catch (err) {
    console.error("login error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

// Generates OTP and stores in PasswordOtps table (10 minutes expiry)
async function forgotPassword(req, res) {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: "Missing fields" });
    }
    if (!isValidEmail(email)) {
      return res.status(400).json({ message: "Invalid email format" });
    }

    const userRes = await sql.query`
      SELECT TOP 1 id, email FROM Users WHERE email = ${email}
    `;

    if (!userRes.recordset.length) {
      return res.status(404).json({ message: "Account not found" });
    }

    const userId = userRes.recordset[0].id;

    const otp = crypto.randomInt(100000, 999999).toString();
    await sql.query`
      INSERT INTO PasswordOtps (user_id, otp, expires_at)
      VALUES (${userId}, ${otp}, DATEADD(MINUTE, 10, GETDATE()))
    `;

    // TODO: send OTP via nodemailer (Phase 2.3)
    // For now: return success (DON'T return OTP in real app)
    return res.json({ message: "OTP sent to email" });
  } catch (err) {
    console.error("forgotPassword error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

module.exports = {
  signup,
  login,
  forgotPassword,
};
