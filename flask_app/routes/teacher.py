'''教师专属功能路由'''
from flask import Blueprint, render_template, request, redirect, url_for, session, jsonify
from db_utils import get_db_connection

teacher_bp = Blueprint('teacher', __name__)
# teacher_bp = Blueprint('teacher', __name__, url_prefix="/teacher")

# 教师主页/dashboard，支持 GET（初始页面）和 POST（按条件筛选/查看成绩）
@teacher_bp.route('/teacher_dashboard', methods=['GET', 'POST'])
def teacher_dashboard():
    # 判断 session 是否为已登录教师
    if 'user_role' in session and session['user_role'] == 'teacher':
        teacher_id = session['user_id']
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            # 查询教师基础信息
            cursor.execute("EXEC GetTeacherInfo @TeacherID = ?", teacher_id)
            teacher_info = cursor.fetchone()

            terms = []
            # 查询所有开设学期
            cursor.execute("SELECT DISTINCT Term FROM Courses ORDER BY Term")
            terms = cursor.fetchall()

            selected_term = None  # 选中的学期
            courses = []          # 当前学期的教师课程列表

            # 如果是POST且选择了学期，查询该学期课程
            if request.method == 'POST' and 'term' in request.form:
                selected_term = request.form['term']
                cursor.execute("EXEC GetTeacherCoursesByTerm @TeacherID = ?, @Term = ?", (teacher_id, selected_term))
                courses = cursor.fetchall()

            # 如果是POST且选择了课程，查询该课程学生成绩
            if request.method == 'POST' and 'course_id' in request.form:
                course_id = request.form['course_id']
                cursor.execute("EXEC GetCoursesScores @CourseID = ?", course_id)
                student_scores = cursor.fetchall()
                # 渲染单门课程学生成绩页面
                return render_template('course_student_scores.html', student_scores=student_scores, course_id=course_id)

            if teacher_info:
                # 渲染教师主页，显示教师信息、教师课程、学期等
                return render_template(
                    'teacher_dashboard.html',
                    teacher=teacher_info,
                    courses=courses,
                    terms=terms,
                    selected_term=selected_term
                )
            else:
                return 'Teacher information not found'
        else:
            # 数据库连接失败
            return 'Database connection failed'
    else:
        # 未登录或不是教师，跳转登录页
        return redirect(url_for('common.login'))

# 教师更新学生成绩（AJAX接口，POST）
@teacher_bp.route('/update_score', methods=['POST'])
def update_score():
    # 只允许已登录教师操作
    if 'user_role' in session and session['user_role'] == 'teacher':
        course_id = request.form['course_id']
        student_id = request.form['student_id']
        new_score = request.form['score']
        conn = get_db_connection()
        if conn:
            try:
                cursor = conn.cursor()
                # 调用存储过程更新成绩
                cursor.execute(
                    "EXEC UpdateStudentScore @CourseID = ?, @StudentID = ?, @Score = ?",
                    (course_id, student_id, new_score)
                )
                conn.commit()
                return jsonify({'status': 'success'})
            except Exception as e:
                print(f"Database error: {e}")
                return jsonify({'status': 'error', 'message': str(e)})
        else:
            return jsonify({'status': 'error', 'message': 'Database connection failed'})
    else:
        # 未登录或不是教师，禁止操作
        return jsonify({'status': 'error', 'message': 'Unauthorized access'})