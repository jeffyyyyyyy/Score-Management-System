'''应用主入口，创建Flask实例并注册所有蓝图'''
from flask import Flask
from routes import admin_bp, teacher_bp, student_bp, common_bp
import os

app = Flask(__name__)
app.secret_key = os.urandom(24).hex()

# 注册蓝图
app.register_blueprint(common_bp)
app.register_blueprint(admin_bp)
app.register_blueprint(teacher_bp)
app.register_blueprint(student_bp)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)