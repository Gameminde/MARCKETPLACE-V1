require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const mongoose = require('mongoose');

const app = express();
const PORT = process.env.PORT || 3000;

// ========== MIDDLEWARES ==========
app.use(helmet());
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:8080'],
  credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));

// ========== MONGODB CONNECTION ==========
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ MongoDB Atlas connecté !'))
  .catch(err => console.error('❌ MongoDB erreur:', err));

// ========== CLOUDINARY CONFIG ==========
const cloudinary = require('cloudinary').v2;
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// ========== HEALTH CHECK ==========
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
    mongodb: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected',
    cloudinary: 'Configured'
  });
});

// ========== API ROUTES BASIQUES ==========
app.get('/api/v1/templates', (req, res) => {
  res.json({
    success: true,
    data: [
      {
        id: 'feminine',
        name: 'Féminin',
        description: 'Design élégant avec couleurs douces',
        config: {
          colors: { primary: '#FF69B4', secondary: '#FFC0CB' },
          typography: { fontFamily: 'Poppins' }
        }
      },
      {
        id: 'masculine',
        name: 'Masculin', 
        description: 'Design moderne avec couleurs neutres',
        config: {
          colors: { primary: '#2C3E50', secondary: '#34495E' },
          typography: { fontFamily: 'Roboto' }
        }
      }
    ]
  });
});

// ========== START SERVER ==========
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
  console.log(`📡 API Base: http://localhost:${PORT}/api/v1`);
});

module.exports = app;
