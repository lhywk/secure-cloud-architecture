from flask import Flask, request, jsonify
import sqlite3

app = Flask(__name__)

# ❌ 하드코딩된 시크릿 (p/secrets 룰셋에 탐지됨)
AWS_SECRET_KEY = "AKIAIOSFODNN7EXAMPLE"
DB_PASSWORD = "admin1234!"

@app.route('/health')
def health():
    return 'ok', 200

@app.route('/user')
def get_user():
    user_id = request.args.get('user_id')

    # ❌ SQLi 패턴 — f-string으로 쿼리 직접 조합 (p/owasp-top-ten 룰셋에 탐지됨)
    # 동시에 IDOR 유발 패턴 — 인가 체크 없이 user_id를 그대로 사용
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
    result = cursor.fetchone()
    conn.close()

    return jsonify(result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)