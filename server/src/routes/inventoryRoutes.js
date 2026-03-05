import express from 'express';
import { body, param } from 'express-validator';
import { validate } from '../middleware/validator.js';
import {
  addStock,
  getAllAssets,
  getAssetById,
  updateAsset,
  deleteAsset,
  getLowStockAssets,
  getAllCompanies,
  addCompany,
  getAllAssetTypes,
  addAssetType,
  getDashboardStats
} from '../controllers/inventoryController.js';

const router = express.Router();

// Health check
router.get("/health", (req, res) => {
  res.json({ message: "Inventory routes OK" });
});

// ==================== ASSET ROUTES ====================

/**
 * @route   POST /api/inventory/add-stock
 * @desc    Add new stock to inventory (creates new asset or updates existing)
 * @access  Private (add authentication middleware as needed)
 */
router.post(
  '/add-stock',
  [
    body('company')
      .notEmpty()
      .withMessage('Company is required')
      .trim(),
    body('assetType')
      .notEmpty()
      .withMessage('Asset type is required')
      .trim(),
    body('batchQty')
      .notEmpty()
      .withMessage('Batch quantity is required')
      .isInt({ min: 1 })
      .withMessage('Batch quantity must be a positive integer'),
    body('threshold')
      .optional()
      .isInt({ min: 0 })
      .withMessage('Threshold must be a non-negative integer'),
    body('orgId')
      .optional()
      .isUUID()
      .withMessage('Invalid organization ID'),
  ],
  validate,
  addStock
);

/**
 * @route   GET /api/inventory/assets
 * @desc    Get all assets with filtering, searching, and pagination
 * @access  Private
 * @query   page, limit, search, assetType, company, orgId, showInactive
 */
router.get('/assets', getAllAssets);

/**
 * @route   GET /api/inventory/assets/:id
 * @desc    Get single asset by ID
 * @access  Private
 */
router.get(
  '/assets/:id',
  [
    param('id')
      .isUUID()
      .withMessage('Invalid asset ID')
  ],
  validate,
  getAssetById
);

/**
 * @route   PUT /api/inventory/assets/:id
 * @desc    Update asset details
 * @access  Private
 */
router.put(
  '/assets/:id',
  [
    param('id')
      .isUUID()
      .withMessage('Invalid asset ID'),
    body('assetType')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('Asset type cannot be empty'),
    body('company')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('Company cannot be empty'),
    body('totalIn')
      .optional()
      .isInt({ min: 0 })
      .withMessage('Total in must be a non-negative integer'),
    body('totalOut')
      .optional()
      .isInt({ min: 0 })
      .withMessage('Total out must be a non-negative integer'),
    body('addToOut')
      .optional()
      .isInt({ min: 1 })
      .withMessage('Add to out must be a positive integer'),
    body('threshold')
      .optional()
      .isInt({ min: 0 })
      .withMessage('Threshold must be a non-negative integer'),
  ],
  validate,
  updateAsset
);

/**
 * @route   DELETE /api/inventory/assets/:id
 * @desc    Delete (soft delete) an asset
 * @access  Private
 */
router.delete(
  '/assets/:id',
  [
    param('id')
      .isUUID()
      .withMessage('Invalid asset ID')
  ],
  validate,
  deleteAsset
);

/**
 * @route   GET /api/inventory/low-stock
 * @desc    Get assets with low stock (balance <= threshold)
 * @access  Private
 */
router.get('/low-stock', getLowStockAssets);

/**
 * @route   GET /api/inventory/dashboard
 * @desc    Get dashboard statistics and analytics
 * @access  Private
 */
router.get('/dashboard', getDashboardStats);

// ==================== COMPANY ROUTES ====================

/**
 * @route   GET /api/inventory/companies
 * @desc    Get all companies
 * @access  Private
 */
router.get('/companies', getAllCompanies);

/**
 * @route   POST /api/inventory/companies
 * @desc    Add new company
 * @access  Private (Admin only)
 */
router.post(
  '/companies',
  [
    body('companyCode')
      .notEmpty()
      .withMessage('Company code is required')
      .trim()
      .isLength({ min: 2, max: 10 })
      .withMessage('Company code must be 2-10 characters'),
    body('companyName')
      .notEmpty()
      .withMessage('Company name is required')
      .trim(),
    body('orgId')
      .optional()
      .isUUID()
      .withMessage('Invalid organization ID'),
  ],
  validate,
  addCompany
);

// ==================== ASSET TYPE ROUTES ====================

/**
 * @route   GET /api/inventory/asset-types
 * @desc    Get all asset types
 * @access  Private
 */
router.get('/asset-types', getAllAssetTypes);

/**
 * @route   POST /api/inventory/asset-types
 * @desc    Add new asset type
 * @access  Private (Admin only)
 */
router.post(
  '/asset-types',
  [
    body('typeName')
      .notEmpty()
      .withMessage('Type name is required')
      .trim(),
    body('typeCode')
      .notEmpty()
      .withMessage('Type code is required')
      .trim()
      .isLength({ min: 2, max: 20 })
      .withMessage('Type code must be 2-20 characters'),
    body('description')
      .optional()
      .trim(),
    body('orgId')
      .optional()
      .isUUID()
      .withMessage('Invalid organization ID'),
  ],
  validate,
  addAssetType
);

export default router;