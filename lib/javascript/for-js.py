import subprocess

# JavaScriptファイルの内容を読み込む
with open('/opt/check-module.js', 'r') as js_file:
   js_code = js_file.read()

# Node.jsでJavaScriptコードを実行する
subprocess.call(['node', '-e', js_code])
