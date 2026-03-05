import express from 'express';
import { body } from 'express-validator';
import { 
  register, 
  login, 
  getProfile, 
  refreshAccessToken, 
  logout,
  changePassword
} from '../controllers/authController.js';
import { authenticate } from '../middleware/auth.js';
import { validate } from '../middleware/validator.js';

const router = express.Router();

// Validation rules
const registerValidation = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  body('employeCode')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Employee code cannot be empty if provided'),
  body('phoneNumber')
    .optional()
    .matches(/^[0-9]{10,15}$/)
    .withMessage('Phone number must be 10-15 digits'),
  body('email')
    .optional()
    .isEmail()
    .withMessage('Valid email is required if provided')
].concat([
  body().custom((value, { req }) => {
    if (!req.body.employeCode && !req.body.phoneNumber && !req.body.email) {
      throw new Error('At least one of employeCode, phoneNumber, or email is required');
    }
    return true;
  })
]);

const loginValidation = [
  body('identifier')
    .trim()
    .notEmpty()
    .withMessage('Email, employee code, or phone number is required'),
  body('password').notEmpty().withMessage('Password is required')
];

const refreshTokenValidation = [
  body('refreshToken').notEmpty().withMessage('Refresh token is required')
];

const changePasswordValidation = [
  body('oldPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword')
    .isLength({ min: 6 })
    .withMessage('New password must be at least 6 characters long')
];

// Routes
router.post('/register', registerValidation, validate, register);
router.post('/login', loginValidation, validate, login);
router.post('/refresh', refreshTokenValidation, validate, refreshAccessToken);
router.post('/logout', authenticate, logout);
router.get('/profile', authenticate, getProfile);
router.post('/change-password', authenticate, changePasswordValidation, validate, changePassword);

export default router;