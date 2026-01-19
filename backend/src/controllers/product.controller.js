const { getPool, sql } = require("../config/db");

// Helpers
function toInt(value, fallback) {
  const n = parseInt(value, 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function toSort(sortBy) {
  // allowed: name, price
  if (sortBy === "price") return "price";
  return "name";
}

function toOrder(order) {
  // allowed: asc, desc
  return (String(order || "").toLowerCase() === "desc") ? "DESC" : "ASC";
}

// POST /api/products
async function createProduct(req, res) {
  try {
    const pool = getPool();
    const { name, description, category_id, price, image_url } = req.body;

    if (!name || !String(name).trim()) {
      return res.status(400).json({ message: "Missing product name" });
    }
    if (!category_id) {
      return res.status(400).json({ message: "Missing category_id" });
    }
    const parsedPrice = Number(price);
    if (!Number.isFinite(parsedPrice) || parsedPrice < 0) {
      return res.status(400).json({ message: "Invalid price" });
    }

    // Ensure category exists
    const cat = await pool.request()
      .input("cid", sql.Int, parseInt(category_id, 10))
      .query("SELECT TOP 1 id FROM Categories WHERE id = @cid");

    if (!cat.recordset.length) {
      return res.status(404).json({ message: "Category not found" });
    }

    await pool.request()
      .input("name", sql.NVarChar, String(name).trim())
      .input("desc", sql.NVarChar, description || null)
      .input("cid", sql.Int, parseInt(category_id, 10))
      .input("price", sql.Decimal(10, 2), parsedPrice)
      .input("img", sql.NVarChar, image_url || null)
      .query(`
        INSERT INTO Products (name, description, category_id, price, image_url, updated_at)
VALUES (@name, @desc, @cid, @price, @img, GETDATE())
      `);

    return res.status(201).json({ message: "Product created" });
  } catch (err) {
    console.error("createProduct error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

// GET /api/products?page=1&limit=20&search=&category_id=&sort_by=name|price&order=asc|desc
async function getProducts(req, res) {
  try {
    const pool = getPool();

    const page = toInt(req.query.page, 1);
    const limit = toInt(req.query.limit, 20); // required 20 per page (Flutter can pass 20)
    const offset = (page - 1) * limit;

    const search = (req.query.search ? String(req.query.search) : "").trim();
    const categoryId = req.query.category_id ? parseInt(req.query.category_id, 10) : null;

    const sortBy = toSort(req.query.sort_by);
    const order = toOrder(req.query.order);

    // Build WHERE
    // We keep raw SQL but still safe by parameterizing values.
    // Only sort column/order is whitelisted (cannot be parameterized).
    const whereParts = [];
    if (search) whereParts.push("p.name COLLATE Khmer_100_CI_AI LIKE '%' + @search + '%'");
    if (categoryId) whereParts.push("p.category_id = @category_id");
    const whereSql = whereParts.length ? ("WHERE " + whereParts.join(" AND ")) : "";

    // total count (for pagination UI)
    const countReq = pool.request();
    if (search) countReq.input("search", sql.NVarChar, search);
    if (categoryId) countReq.input("category_id", sql.Int, categoryId);

    const totalRes = await countReq.query(`
      SELECT COUNT(*) AS total
      FROM Products p
      ${whereSql}
    `);
    const total = totalRes.recordset[0].total;

    // data query
    const dataReq = pool.request()
      .input("offset", sql.Int, offset)
      .input("limit", sql.Int, limit);

    if (search) dataReq.input("search", sql.NVarChar, search);
    if (categoryId) dataReq.input("category_id", sql.Int, categoryId);

    // Sorting: whitelist only
    const orderBySql =
      sortBy === "price"
        ? `ORDER BY p.price ${order}`
        : `ORDER BY p.name COLLATE Khmer_100_CI_AI ${order}`;

    const dataRes = await dataReq.query(`
      SELECT
        p.id, p.name, p.description, p.price, p.image_url, p.created_at, p.updated_at,
        p.category_id, c.name AS category_name
      FROM Products p
      JOIN Categories c ON c.id = p.category_id
      ${whereSql}
      ${orderBySql}
      OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `);

    return res.json({
      paging: {
        page,
        limit,
        total,
        total_pages: Math.ceil(total / limit)
      },
      data: dataRes.recordset
    });
  } catch (err) {
    console.error("getProducts error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

// PUT /api/products/:id
async function updateProduct(req, res) {
  try {
    const pool = getPool();
    const id = parseInt(req.params.id, 10);

    const { name, description, price, image_url, category_id } = req.body;

    if (!id) return res.status(400).json({ message: "Invalid product id" });

    // ensure product exists
    const existing = await pool.request()
      .input("id", sql.Int, id)
      .query("SELECT TOP 1 id FROM Products WHERE id = @id");

    if (!existing.recordset.length) {
      return res.status(404).json({ message: "Product not found" });
    }

    // validate optional fields
    if (name !== undefined && !String(name).trim()) {
      return res.status(400).json({ message: "Invalid product name" });
    }
    if (price !== undefined) {
      const parsedPrice = Number(price);
      if (!Number.isFinite(parsedPrice) || parsedPrice < 0) {
        return res.status(400).json({ message: "Invalid price" });
      }
    }

    // if category_id is provided, ensure exists
    if (category_id !== undefined && category_id !== null) {
      const cid = parseInt(category_id, 10);
      const cat = await pool.request()
        .input("cid", sql.Int, cid)
        .query("SELECT TOP 1 id FROM Categories WHERE id = @cid");
      if (!cat.recordset.length) {
        return res.status(404).json({ message: "Category not found" });
      }
    }

    // build dynamic update
    const sets = [];
    const reqq = pool.request().input("id", sql.Int, id);

    if (name !== undefined) {
      sets.push("name = @name");
      reqq.input("name", sql.NVarChar, String(name).trim());
    }
    if (description !== undefined) {
      sets.push("description = @desc");
      reqq.input("desc", sql.NVarChar, description || null);
    }
    if (price !== undefined) {
      sets.push("price = @price");
      reqq.input("price", sql.Decimal(10, 2), Number(price));
    }
    if (image_url !== undefined) {
      sets.push("image_url = @img");
      reqq.input("img", sql.NVarChar, image_url || null);
    }
    if (category_id !== undefined && category_id !== null) {
      sets.push("category_id = @cid");
      reqq.input("cid", sql.Int, parseInt(category_id, 10));
    }

    if (!sets.length) {
      return res.status(400).json({ message: "No fields to update" });
    }

    // always update updated_at
sets.push("updated_at = GETDATE()");

await reqq.query(`
  UPDATE Products
  SET ${sets.join(", ")}
  WHERE id = @id
`);


    return res.json({ message: "Product updated" });
  } catch (err) {
    console.error("updateProduct error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

// DELETE /api/products/:id
async function deleteProduct(req, res) {
  try {
    const pool = getPool();
    const id = parseInt(req.params.id, 10);

    if (!id) return res.status(400).json({ message: "Invalid product id" });

    const existing = await pool.request()
      .input("id", sql.Int, id)
      .query("SELECT TOP 1 id FROM Products WHERE id = @id");

    if (!existing.recordset.length) {
      return res.status(404).json({ message: "Product not found" });
    }

    await pool.request()
      .input("id", sql.Int, id)
      .query("DELETE FROM Products WHERE id = @id");

    return res.json({ message: "Product deleted" });
  } catch (err) {
    console.error("deleteProduct error:", err);
    return res.status(500).json({ message: "Server error" });
  }
}

module.exports = {
  createProduct,
  getProducts,
  updateProduct,
  deleteProduct,
};
