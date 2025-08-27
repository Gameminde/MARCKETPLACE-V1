const express = require('express');
const router = express.Router();

router.get('/status', (req, res) => {
  res.json({ success: true, status: 'ok' });
});

module.exports = router;



