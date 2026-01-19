const express = require("express");
const router = express.Router();

const productController = require("../controllers/product.controller");
const auth = require("../middleware/auth.middleware");

// Public list (for app browsing)
router.get("/", productController.getProducts);

// Protected CRUD
router.post("/", auth, productController.createProduct);
router.put("/:id", auth, productController.updateProduct);
router.delete("/:id", auth, productController.deleteProduct);

module.exports = router;
