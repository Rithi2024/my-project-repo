const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const path = require("path");


dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

// routes
const authRoutes = require("./routes/auth.routes");
app.use("/api/auth", authRoutes);

const categoryRoutes = require("./routes/category.routes");
app.use("/api/categories", categoryRoutes);

const productRoutes = require("./routes/product.routes");
app.use("/api/products", productRoutes);
// test
app.get("/", (req, res) => res.send("Backend is working"));

app.use("/images", express.static(path.join(__dirname, "..", "upload", "images")));


module.exports = app;
