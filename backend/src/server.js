const app = require("./app");
const { connectDb } = require("./config/db");

const PORT = process.env.PORT || 3000;

connectDb()
  .then(() => {
    app.listen(PORT, () => {
      console.log("Server running on port " + PORT);
    });
  })
  .catch(() => {
    console.log("Server NOT started because DB connection failed.");
  });
