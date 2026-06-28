const fs = require('fs');
const path = require('path');

const srcDir = path.join(__dirname, '..', 'assets', 'images', 'weeks');
const destDir = path.join(__dirname, 'uploads', 'weeks');

console.log(`Source directory: ${srcDir}`);
console.log(`Destination directory: ${destDir}`);

// Ensure destination directory exists
if (!fs.existsSync(destDir)) {
  fs.mkdirSync(destDir, { recursive: true });
  console.log('Created destination directory.');
}

if (!fs.existsSync(srcDir)) {
  console.error('Source directory does not exist! Please check path.');
  process.exit(1);
}

const files = fs.readdirSync(srcDir);
let copyCount = 0;

files.forEach(file => {
  if (file.startsWith('week_') && file.endsWith('.jpg')) {
    const srcPath = path.join(srcDir, file);
    const destPath = path.join(destDir, file);
    fs.copyFileSync(srcPath, destPath);
    copyCount++;
  }
});

console.log(`Successfully copied ${copyCount} weekly baby growth images to backend uploads.`);
