const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const studentRoutes = require('./services/student');
const clubRoutes = require('./services/club');
const adminRoutes = require('./services/admin');
const eventRoutes = require('./services/ClubHome');
// const adminLogRoutes = require('./services/admin-logs');


const app = express();

// Middleware
const corsOrigins = process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : ['http://localhost:30000', 'http://localhost:3000'];
app.use(cors({
  origin: corsOrigins,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// MongoDB Connection
const mongoURI = 'mongodb+srv://druthi:druthi%402004@devops-cc.w5sl0nw.mongodb.net/?retryWrites=true&w=majority&appName=devops-cc'; // Change to your DB name
mongoose.connect(mongoURI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// Routes
app.use('/api/students', studentRoutes);
app.use('/api/clubs', clubRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/events', eventRoutes);
// app.use('/api/admin/logs', adminLogRoutes);


// Start server
const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || 'localhost';

app.listen(PORT, HOST, () => {
  console.log(`Server running on ${HOST}:${PORT}`);
  console.log('CORS enabled for:', process.env.CORS_ORIGIN || 'http://localhost:3000');
});