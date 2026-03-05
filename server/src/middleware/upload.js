import multer from 'multer';

const storage = multer.diskStorage({
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname);
  }
});

export const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  fileFilter: (req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) return cb(new Error('Only images allowed'));
    cb(null, true);
  }
});

// KYC upload middleware - accepts images and PDFs
export const uploadKycFiles = multer({
  storage: multer.memoryStorage(), // Store in memory for processing
  limits: { 
    fileSize: 10 * 1024 * 1024, // 10 MB per file
    fieldSize: 50 * 1024 * 1024 // 50 MB total
  },
  fileFilter: (req, file, cb) => {
    // Accept images and PDFs
    if (file.mimetype.startsWith('image/') || file.mimetype === 'application/pdf') {
      cb(null, true);
    } else {
      cb(new Error('Only images and PDF files are allowed'));
    }
  }
}).fields([
  { name: 'id_document', maxCount: 1 },
  { name: 'address_proof_document', maxCount: 1 },
  { name: 'signature', maxCount: 1 }
]);
