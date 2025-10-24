const express = require("express");
const app = express();

app.use(express.json());
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  console.log('Headers:', req.headers);
  console.log('Body:', req.body);
  next();
});

app.all("*", (req, res) => {
  console.log("RECIBIDO:", req.method, req.url, req.body);
  res.json({ok: true, received: req.body, timestamp: new Date().toISOString()});
});

app.listen(3001, "0.0.0.0", () => {
  console.log(" Servidor de captura en puerto 3001");
});
