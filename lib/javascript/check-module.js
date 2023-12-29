// check-fs.js
try {
    require('fs');
    console.log('fs OK');
  } catch (error) {
    console.error('Error loading fs module:', error);
    process.exit(1);
  }