import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import Role from '../models/Role.js';
import Module from '../models/Module.js';
import { Op } from 'sequelize';

const generateAccessToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m'
  });
};

const generateRefreshToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'
  });
};

export const register = async (req, res, next) => {
  try {
    const { name, employeCode, phoneNumber, email, password } = req.body;

    // Check if user exists with employeCode or phoneNumber
    const whereConditions = [];
    if (employeCode) whereConditions.push({ employeCode });
    if (phoneNumber) whereConditions.push({ phoneNumber });
    if (email) whereConditions.push({ email });

    if (whereConditions.length > 0) {
      const userExists = await User.findOne({ 
        where: { [Op.or]: whereConditions } 
      });
      
      if (userExists) {
        return res.status(409).json({
          success: false,
          message: 'User already exists with this employee code, phone number, or email'
        });
      }
    }

    const user = await User.create({
      name,
      employeCode,
      phoneNumber,
      email,
      password
    });

    const accessToken = generateAccessToken(user.id);
    const refreshToken = generateRefreshToken(user.id);

    // Store refresh token in database
    await user.update({ refreshToken });

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user,
        accessToken,
        refreshToken
      }
    });
  } catch (error) {
    next(error);
  }
};

export const login = async (req, res, next) => {
  try {
    const { identifier, password } = req.body;

    // Find user by employeCode, phoneNumber, or email
    const user = await User.findOne({ 
      where: { 
        [Op.or]: [
          { employeCode: identifier },
          { phoneNumber: identifier },
          { email: identifier }
        ]
      } 
    });
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        message: 'Your account has been deactivated'
      });
    }

    const accessToken = generateAccessToken(user.id);
    const refreshToken = generateRefreshToken(user.id);

    // Store refresh token in database
    await user.update({ refreshToken });

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        user,
        accessToken,
        refreshToken,
        isAdmin: user.role_id === 2 //Admin id is 2
      }
    });
  } catch (error) {
    next(error);
  }
};

export const refreshAccessToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Refresh token is required'
      });
    }

    // Verify refresh token
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    } catch (error) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired refresh token'
      });
    }

    // Find user and verify refresh token matches
    const user = await User.findByPk(decoded.id);
    
    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'User not found or inactive'
      });
    }

    if (user.refreshToken !== refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }

    // Generate new tokens
    const newAccessToken = generateAccessToken(user.id);
    const newRefreshToken = generateRefreshToken(user.id);

    // Update refresh token in database
    await user.update({ refreshToken: newRefreshToken });

    res.status(200).json({
      success: true,
      message: 'Tokens refreshed successfully',
      data: {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken
      }
    });
  } catch (error) {
    next(error);
  }
};

export const logout = async (req, res, next) => {
  try {
    const user = req.user;
    
    // Clear refresh token from database
    await user.update({ refreshToken: null });

    res.status(200).json({
      success: true,
      message: 'Logout successful'
    });
  } catch (error) {
    next(error);
  }
};

export const getProfile = async (req, res, next) => {
  try {
    // Fetch user with role and modules
    const userWithDetails = await User.findByPk(req.user.id, {
      include: [
        { model: Role, attributes: ['id', 'name'] },
        { model: Module, attributes: ['id', 'name'], through: { attributes: [] } }
      ]
    });
    
    res.status(200).json({
      success: true,
      data: userWithDetails
    });
  } catch (error) {
    next(error);
  }
};

export const changePassword = async (req, res, next) => {
  try {
    const { oldPassword, newPassword } = req.body;
    const user = req.user;

    // Verify old password
    const isPasswordValid = await user.comparePassword(oldPassword);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Check if new password is different from old password
    const isSamePassword = await user.comparePassword(newPassword);
    if (isSamePassword) {
      return res.status(400).json({
        success: false,
        message: 'New password must be different from current password'
      });
    }

    // Update password (the beforeUpdate hook will hash it automatically)
    await user.update({ password: newPassword });

    res.status(200).json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    next(error);
  }
};