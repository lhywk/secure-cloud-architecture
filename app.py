from flask import Flask, request, jsonify

app = Flask(__name__)

USERS = {
    "1": {"id": 1, "name": "Alice", "email": "alice@example.com", "role": "admin", "balance": 99999},
    "2": {"id": 2, "name": "Bob",   "email": "bob@example.com",   "role": "user",  "balance": 1000},
    "3": {"id": 3, "name": "Carol", "email": "carol@example.com", "role": "user",  "balance": 5000},
}

@app.route('/health')
def health():
    return 'ok', 200

@app.route('/')
def hello():
    return '<h1>IDOR 취약점 데모 앱</h1><p>/user?user_id=1, 2, 3 으로 접근해보세요</p>', 200

@app.route('/user')
def get_user():
    user_id = request.args.get('user_id')
    # ❌ 인가 체크 없음 → IDOR
    user = USERS.get(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify(user), 200