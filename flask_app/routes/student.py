'''学生专属功能路由'''
from flask import Blueprint, render_template, request, redirect, url_for, session
from db_utils import get_db_connection

student_bp = Blueprint('student', __name__)
# student_bp = Blueprint('student', __name__, url_prefix="/student")

# 学生个人主页/dashboard，支持 GET（初始页面）和 POST（按学期筛选成绩）
@student_bp.route('/student_dashboard', methods=['GET', 'POST'])
def student_dashboard():
    # 判断当前 session 是否为已登录学生
    if 'user_role' in session and session['user_role'] == 'student':
        student_id = session['user_id']  # 当前学生ID
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            # 获取学生基础信息
            cursor.execute("EXEC GetStudentInfo @StudentID = ?", student_id)
            student_info = cursor.fetchone()
            
            student_scores = []  # 当前页面显示的成绩列表（默认为空）
            terms = []
            
            # 获取所有开设学期
            cursor.execute("SELECT DISTINCT Term FROM Courses ORDER BY Term")
            terms = cursor.fetchall()
            
            selected_term = None  # 当前筛选的学期
            
            # 如果是 POST，说明学生选了某个学期，需要查该学期成绩
            if request.method == 'POST':
                selected_term = request.form['term']
                cursor.execute("EXEC GetStudentScoresByTerm @StudentID = ?, @Term = ?", (student_id, selected_term))
                student_scores = cursor.fetchall()
            
            # 获取学生加权绩点
            cursor.execute("EXEC GetStudentWeightedGPA @StudentID = ?", student_id)
            weighted_gpa = cursor.fetchone().WeightedGPA
            
            # 获取学生加权平均分
            cursor.execute("EXEC GetStudentWeightedAverageScore @StudentID = ?", student_id)
            weighted_avg_score = cursor.fetchone().WeightedAverageScore
            
            if student_info:
                # 渲染学生主页模板，并传递所有相关信息
                return render_template(
                    'student_dashboard.html', 
                    student_info=student_info, 
                    student_scores=student_scores, 
                    terms=terms, 
                    selected_term=selected_term, 
                    weighted_gpa=weighted_gpa, 
                    weighted_avg_score=weighted_avg_score
                )
            else:
                return 'Student information not found'
        else:
            # 数据库连接失败
            return 'Database connection failed'
    else:
        # 未登录或不是学生角色，跳转到登录页
        return redirect(url_for('common.login'))