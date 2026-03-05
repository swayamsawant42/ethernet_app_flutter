import express from 'express';
import authRoutes from './authRoutes.js';
import userRoutes from './userRoutes.js';
import leadRoutes from './leadRoutes.js';
import roleRoutes from './roleRoutes.js';
import moduleRoutes from './moduleRoutes.js';
import travelTrackerRoutes from './travelTrackerRoute.js';
import inventoryRoutes from './inventoryRoutes.js';
const router = express.Router();

// Health check
router.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

// API routes
router.use('/auth', authRoutes);
router.use('/leads', leadRoutes);
router.use('/inventory', inventoryRoutes);
router.use('/role', roleRoutes);
router.use('/module', moduleRoutes);
router.use('/users', userRoutes);
router.use('/travelTracker', travelTrackerRoutes);

export default router;