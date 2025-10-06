'''存放全系统通用的路由（登录、登出），与用户角色无关'''
from flask import Blueprint, render_template, request, redirect, url_for, session
from db_utils import get_db_connection

common_bp = Blueprint('common', __name__)
# common_bp = Blueprint('common', __name__, url_prefix="/common")

# 登录页（GET方式）
@common_bp.route('/')
def login():
    return render_template('login.html')

# 登出路由，清除 session 后重定向回登录页
@common_bp.route('/logout')
def logout():
    # 清除用户登录状态
    session.pop('user_id', None)
    session.pop('user_role', None)
    # 重定向到登录页（endpoint 用 common.login）
    return redirect(url_for('common.login'))

# 更改密码（POST），所有登录用户都可用
@common_bp.route('/change_password', methods=['POST'])
def change_password():
    # 判断当前 session 是否已登录
    if 'user_role' in session:
        user_id = session['user_id']
        new_password = request.form['new_password']

        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            # 调用存储过程修改密码
            cursor.execute("{CALL ChangePassword (?, ?)}", (user_id, new_password))
            conn.commit()
            return 'Password changed successfully'
        else:
            return 'Database connection failed'
    else:
        # 未登录时跳转到登录页
        return redirect(url_for('common.login'))

# 登录处理（POST），校验用户名和密码
@common_bp.route('/login', methods=['POST'])
def login_post():
    user_name = request.form['username']
    user_password = request.form['password']

    conn = get_db_connection()
    if conn:
        cursor = conn.cursor()
        # 校验用户名和密码
        cursor.execute("SELECT * FROM Login WHERE UserID = ? AND Password = ?", (user_name, user_password))
        user = cursor.fetchone()

        if user:
            account_status = user.AccountStatus
            if account_status == 1:
                # 登录成功，保存用户信息到 session
                session['user_id'] = user.UserID
                session['user_role'] = user.UserRole.strip()
                # 按用户角色跳转到对应 dashboard
                if session['user_role'] == 'admin':
                    return redirect(url_for('admin.admin_dashboard'))
                elif session['user_role'] == 'student':
                    return redirect(url_for('student.student_dashboard'))
                elif session['user_role'] == 'teacher':
                    return redirect(url_for('teacher.teacher_dashboard'))
                else:
                    # 数据库里角色字段异常
                    return 'Invalid User Role'
            else:
                # 账号被禁用
                return '该账号已被限制登陆,请联系管理员400-823-823'
        else:
            # 用户名或密码不正确
            return 'Invalid Credentials'
    else:
        # 数据库连接失败
        return 'Database connection failed'