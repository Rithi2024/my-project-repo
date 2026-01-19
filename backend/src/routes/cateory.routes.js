const express = require("express");
const router = express.Router();

const categoryController = require("../controllers/category.controller");
const auth = require("../middleware/auth.middleware");

// Public
router.get("/", categoryController.getCategories);

// Protected
router.post("/", auth, categoryController.createCategory);
router.put("/:id", auth, categoryController.updateCategory);
router.delete("/:id", auth, categoryController.deleteCategory);

module.exports = router;
