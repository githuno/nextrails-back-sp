// check-module.js

function check() {
    try {
        require('fs');
        console.log('module OK !');
    } catch (error) {
        console.error('Error loading fs module:', error);
        process.exit(1);
    }
}

// check関数を呼び出す
check();