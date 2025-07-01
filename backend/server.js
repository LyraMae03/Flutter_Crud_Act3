const express = require('express');
const cors = require('cors');
const multer = require('multer');
const mysql = require('mysql2');
const path = require('path');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// MySQL Connection
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '', // Your MySQL password
  database: 'fbpost'
});

db.connect(err => {
  if (err) throw err;
  console.log('MySQL connected');
});


// Multer config
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads'),
  filename: (req, file, cb) => {
    const uniqueName = Date.now() + '-' + file.originalname;
    cb(null, uniqueName);
  }
});
const upload = multer({ storage });

// Routes
app.get('/api/posts', (req, res) => {
  db.query('SELECT * FROM posts ORDER BY created_at DESC', (err, results) => {
    if (err) return res.status(500).json({ error: err });
    res.json(results);
  });
});

app.post('/api/posts/upload', upload.single('image'), (req, res) => {
  const { subtext } = req.body;
  const image = req.file ? req.file.filename : null;

  db.query('INSERT INTO posts (subtext, image) VALUES (?, ?)', [subtext, image], (err, result) => {
    if (err) return res.status(500).json({ error: err });
    res.json({ message: 'Post uploaded successfully', id: result.insertId });
  });
});

app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
