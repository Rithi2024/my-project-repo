const { getPool, sql } = require("../config/db");


// POST /api/categories
async function createCategory(req, res) {
  try {
    const { name, description } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ message: "Missing category name" });
    }

    // Optional: prevent duplicates (same name)
    const dup = await sql.query`
      SELECT TOP 1 id
      FROM Categories
      WHERE name COLLATE Khmer_100_CI_AI = ${name.trim()}
    `;
    if (dup.recordset.length > 0) {
      return res.status(409).json({ message: "Category already exists" });
    }

    await sql.query`
      INSERT INTO Categories (name, description)
      VALUES (${name.trim()}, ${description || null})
    `;

    return res.status(201).json({ message: "Category created" });
  } catch (err) {
    console.error("createCategory error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

// GET /api/categories?search=abc
async function getCategories(req, res) {
  try {
    const search = (req.query.search || "").trim();

    let result;

    if (search) {
      // Khmer-safe LIKE search
      result = await sql.query`
        SELECT id, name, description, created_at
        FROM Categories
        WHERE name COLLATE Khmer_100_CI_AI LIKE '%' + ${search} + '%'
        ORDER BY name COLLATE Khmer_100_CI_AI
      `;
    } else {
      result = await sql.query`
        SELECT id, name, description, created_at
        FROM Categories
        ORDER BY name COLLATE Khmer_100_CI_AI
      `;
    }

    return res.json({ data: result.recordset });
  } catch (err) {
    console.error("getCategories error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

// PUT /api/categories/:id
async function updateCategory(req, res) {
  try {
    const id = parseInt(req.params.id, 10);
    const { name, description } = req.body;

    if (!id) return res.status(400).json({ message: "Invalid category id" });
    if (!name || !name.trim()) {
      return res.status(400).json({ message: "Missing category name" });
    }

    // Ensure exists
    const existing = await sql.query`
      SELECT TOP 1 id FROM Categories WHERE id = ${id}
    `;
    if (!existing.recordset.length) {
      return res.status(404).json({ message: "Category not found" });
    }

    // Optional: avoid duplicates with other rows
    const dup = await sql.query`
      SELECT TOP 1 id
      FROM Categories
      WHERE id <> ${id}
        AND name COLLATE Khmer_100_CI_AI = ${name.trim()}
    `;
    if (dup.recordset.length > 0) {
      return res.status(409).json({ message: "Category name already exists" });
    }

    await sql.query`
      UPDATE Categories
      SET name = ${name.trim()},
          description = ${description || null}
      WHERE id = ${id}
    `;

    return res.json({ message: "Category updated" });
  } catch (err) {
    console.error("updateCategory error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

// DELETE /api/categories/:id
async function deleteCategory(req, res) {
  try {
    const id = parseInt(req.params.id, 10);
    if (!id) return res.status(400).json({ message: "Invalid category id" });

    const existing = await sql.query`
      SELECT TOP 1 id FROM Categories WHERE id = ${id}
    `;
    if (!existing.recordset.length) {
      return res.status(404).json({ message: "Category not found" });
    }

    await sql.query`
      DELETE FROM Categories WHERE id = ${id}
    `;

    return res.json({ message: "Category deleted" });
  } catch (err) {
    // If later Products has FK referencing Categories, delete may fail -> handle nicely
    console.error("deleteCategory error:", err);
    return res.status(500).json({
      message: "Server error (maybe category is used by products)"
    });
  }
}

module.exports = {
  createCategory,
  getCategories,
  updateCategory,
  deleteCategory,
};
