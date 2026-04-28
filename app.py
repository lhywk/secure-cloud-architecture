from flask import Flask

app = Flask(__name__)

@app.route('/health')
def health():
    return 'ok', 200

@app.route('/')
def hello():
    return '<h1>Hello from Vibe Coding!</h1>', 200

# 배포되자