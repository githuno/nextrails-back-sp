import execjs

# JavaScriptコード
JS_COMMAND = """
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
"""

# JavaScriptエンジンを初期化
ctx = execjs.compile(JS_COMMAND)

# JavaScript関数を呼び出す
result = ctx.call("check")
# import subprocess

# # JavaScriptファイルの内容を読み込む
# with open('/opt/check-module.js', 'r') as js_file:
#    js_code = js_file.read()

# # Node.jsでJavaScriptコードを実行する
# subprocess.call(['node', '-e', js_code])
