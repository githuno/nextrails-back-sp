# bin/sh
node -e \
" \
try {  \
        require('fs'); \
    console.log('module OK !'); \
} catch (error) { \
        console.error('Error loading fs module:', error); \
    process.exit(1); \
} \
"