'''管理员专属功能的所有路由'''
from flask import Blueprint, render_template, request, redirect, url_for, session, jsonify
from db_utils import get_db_connection
import math
import pyodbc

admin_bp = Blueprint('admin', __name__)
# admin_bp = Blueprint('admin', __name__, url_prefix="/admin")

# 管理员首页（Dashboard）
@admin_bp.route('/admin_dashboard')
def admin_dashboard():
    # 权限校验：仅管理员可访问
    if 'user_role' in session and session['user_role'] == 'admin':
        return render_template('admin_dashboard.html')
    else:
        return redirect(url_for('common.login'))

# 学生信息分页展示
@admin_bp.route('/students')
def students_page():
    if 'user_role' in session and session['user_role'] == 'admin':
        page = request.args.get('page', 1, type=int)
        per_page = 5  # 每页显示5条
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM Students")
            total_students = cursor.fetchone()[0]
            total_pages = math.ceil(total_students / per_page)
            offset = (page - 1) * per_page
            cursor.execute(
                "SELECT * FROM Students ORDER BY StudentID OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
                (offset, per_page)
            )
            students = cursor.fetchall()
            return render_template('students.html', students=students, page=page, total_pages=total_pages)
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 教师信息分页展示
@admin_bp.route('/teachers')
def teachers_page():
    if 'user_role' in session and session['user_role'] == 'admin':
        page = request.args.get('page', 1, type=int)
        per_page = 5
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM Teachers")
            total_teachers = cursor.fetchone()[0]
            total_pages = math.ceil(total_teachers / per_page)
            offset = (page - 1) * per_page
            cursor.execute(
                "SELECT * FROM Teachers ORDER BY TeacherID OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
                (offset, per_page)
            )
            teachers = cursor.fetchall()
            return render_template('teachers.html', teachers=teachers, page=page, total_pages=total_pages)
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 课程信息分页展示
@admin_bp.route('/courses')
def courses_page():
    if 'user_role' in session and session['user_role'] == 'admin':
        page = request.args.get('page', 1, type=int)
        per_page = 5
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM Courses")
            total_courses = cursor.fetchone()[0]
            total_pages = math.ceil(total_courses / per_page)
            offset = (page - 1) * per_page
            cursor.execute(
                "SELECT * FROM Courses ORDER BY CourseID OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
                (offset, per_page)
            )
            courses = cursor.fetchall()
            return render_template('courses.html', courses=courses, page=page, total_pages=total_pages)
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 全体学生成绩分页展示
@admin_bp.route('/scores')
def scores_page():
    if 'user_role' in session and session['user_role'] == 'admin':
        page = request.args.get('page', 1, type=int)
        per_page = 5
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM AllStudentScores")
            total_scores = cursor.fetchone()[0]
            total_pages = math.ceil(total_scores / per_page)
            offset = (page - 1) * per_page
            cursor.execute(
                "SELECT * FROM AllStudentScores ORDER BY StudentID OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
                (offset, per_page)
            )
            scores = cursor.fetchall()
            return render_template('scores.html', scores=scores, page=page, total_pages=total_pages)
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 授课表分页展示
@admin_bp.route('/teachtable')
def teachtable_page():
    if 'user_role' in session and session['user_role'] == 'admin':
        page = request.args.get('page', 1, type=int)
        per_page = 5
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM TeachTable")
            total_teachtable = cursor.fetchone()[0]
            total_pages = math.ceil(total_teachtable / per_page)
            offset = (page - 1) * per_page
            cursor.execute(
                "SELECT * FROM TeachTable ORDER BY CourseID OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
                (offset, per_page)
            )
            teachtable = cursor.fetchall()
            return render_template('teachtable.html', teachtable=teachtable, page=page, total_pages=total_pages)
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-添加课程
@admin_bp.route('/add_course', methods=['POST'])
def add_course():
    if 'user_role' in session and session['user_role'] == 'admin':
        course_name = request.form['course_name']
        point = request.form['point']
        term = request.form['term']
        stu_number = request.form['stu_number']
        conn = get_db_connection()
        if conn:
            try:
                cursor = conn.cursor()
                # 调用存储过程添加课程
                cursor.execute("""
                    DECLARE @CourseID CHAR(16);
                    EXEC AddCourse @CourseID OUTPUT, ?, ?, ?, ?;
                    SELECT @CourseID AS CourseID;
                """, (course_name, point, term, stu_number))
                cursor.nextset()
                result = cursor.fetchone()
                if result:
                    course_id = result.CourseID
                    print(f"New Course ID: {course_id}")
                    conn.commit()
                    return redirect(url_for('admin.admin_dashboard'))
                else:
                    return 'Failed to retrieve the new course ID'
            except pyodbc.Error as e:
                print(f"Database error: {e}")
                return 'Database error occurred'
            finally:
                conn.close()
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-查询课程详情
@admin_bp.route('/get_course', methods=['POST'])
def get_course():
    if 'user_role' in session and session['user_role'] == 'admin':
        course_id = request.form['course_id']
        conn = get_db_connection()
        if conn:
            try:
                cursor = conn.cursor()
                cursor.execute("SELECT * FROM Courses WHERE CourseID = ?", course_id)
                course = cursor.fetchone()
                if course:
                    return render_template('admin_dashboard.html', course=course)
                else:
                    return 'course not found'
            except pyodbc.Error as e:
                print(f"Database error: {e}")
                return 'Database error occurred'
            finally:
                conn.close()
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-更新课程信息
@admin_bp.route('/update_course', methods=['POST'])
def update_course():
    if 'user_role' in session and session['user_role'] == 'admin':
        course_id = request.form['course_id']
        course_name = request.form['course_name']
        point = request.form['point']
        term = request.form['term']
        stu_number = request.form['stu_number']
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            # 调用存储过程更新课程
            cursor.execute("{CALL UpdateCourse (?, ?, ?, ?, ?)}", (course_id, course_name, point, term, stu_number))
            conn.commit()
            return redirect(url_for('admin.admin_dashboard'))
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-删除课程
@admin_bp.route('/delete_course', methods=['POST'])
def delete_course():
    if 'user_role' in session and session['user_role'] == 'admin':
        course_id = request.form['course_id']
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute("{CALL DeleteCourse (?)}", (course_id,))
            conn.commit()
            return redirect(url_for('admin.admin_dashboard'))
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-添加教师
@admin_bp.route('/add_teacher', methods=['POST'])
def add_teacher():
    if 'user_role' in session and session['user_role'] == 'admin':
        teacher_name = request.form['teacher_name']
        teacher_sex = request.form['teacher_sex']
        teacher_birthday = request.form['teacher_birthday']
        position = request.form['position']
        teacher_department = request.form['teacher_department']
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            # 调用存储过程添加教师
            cursor.execute("{CALL AddTeacher (?, ?, ?, ?, ?, ?)}", (0, teacher_name, teacher_sex, teacher_birthday, position, teacher_department))
            conn.commit()
            return redirect(url_for('admin.admin_dashboard'))
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-查询教师详情
@admin_bp.route('/get_teacher', methods=['POST'])
def get_teacher():
    if 'user_role' in session and session['user_role'] == 'admin':
        teacher_id = request.form['teacher_id']
        conn = get_db_connection()
        if conn:
            try:
                cursor = conn.cursor()
                cursor.execute("SELECT * FROM Teachers WHERE TeacherID = ?", teacher_id)
                teacher = cursor.fetchone()
                if teacher:
                    return render_template('admin_dashboard.html', teacher=teacher)
                else:
                    return 'Teacher not found'
            except pyodbc.Error as e:
                print(f"Database error: {e}")
                return 'Database error occurred'
            finally:
                conn.close()
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-更新教师信息
@admin_bp.route('/update_teacher', methods=['POST'])
def update_teacher():
    if 'user_role' in session and session['user_role'] == 'admin':
        teacher_id = request.form['teacher_id']
        teacher_name = request.form['teacher_name']
        teacher_sex = request.form['teacher_sex']
        teacher_birthday = request.form['teacher_birthday']
        position = request.form['position']
        teacher_department = request.form['teacher_department']
        conn = get_db_connection()
        if conn:
            try:
                cursor = conn.cursor()
                cursor.execute("""
                    UPDATE Teachers
                    SET TeacherName = ?, TeacherSex = ?, TeacherBirthday = ?, Position = ?, TeacherDepartment = ?
                    WHERE TeacherID = ?
                """, (teacher_name, teacher_sex, teacher_birthday, position, teacher_department, teacher_id))
                conn.commit()
                return redirect(url_for('admin.admin_dashboard'))
            except pyodbc.Error as e:
                print(f"Database error: {e}")
                return 'Database error occurred'
            finally:
                conn.close()
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-删除教师
@admin_bp.route('/delete_teacher', methods=['POST'])
def delete_teacher():
    if 'user_role' in session and session['user_role'] == 'admin':
        teacher_id = request.form['teacher_id']
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute("{CALL DeleteTeacher (?)}", (teacher_id,))
            conn.commit()
            return redirect(url_for('admin.admin_dashboard'))
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-添加学生课程成绩记录
@admin_bp.route('/admin_add_score_record', methods=['POST'])
def admin_add_score_record():
    if 'user_role' in session and session['user_role'] == 'admin':
        course_id = request.form['course_id']
        student_id = request.form['student_id']
        conn = get_db_connection()
        if conn:
            try:
                cursor = conn.cursor()
                cursor.execute("EXEC AddScoreRecord @CourseID = ?, @StudentID = ?", (course_id, student_id))
                conn.commit()
                return redirect(url_for('admin.admin_dashboard'))
            except Exception as e:
                print(f"Database error: {e}")
                return redirect(url_for('admin.admin_dashboard'))
            finally:
                conn.close()
        else:
            return redirect(url_for('admin.admin_dashboard'))
    else:
        return redirect(url_for('common.login'))

# 管理员-添加教师授课记录
@admin_bp.route('/add_teach_record', methods=['POST'])
def add_teach_record():
    if 'user_role' in session and session['user_role'] == 'admin':
        teacher_id = request.form['teacher_id']
        course_id = request.form['course_id']
        conn = get_db_connection()
        if conn:
            try:
                cursor = conn.cursor()
                cursor.execute("EXEC InsertIntoTeachTable @TeacherID = ?, @CourseID = ?", (teacher_id, course_id))
                conn.commit()
                print('Record added successfully', 'success')
            except pyodbc.Error as e:
                print(f"Database error: {e}")
                print('Database error occurred', 'danger')
            finally:
                conn.close()
        else:
            print('Database connection failed', 'danger')
        return redirect(url_for('admin.admin_dashboard'))
    else:
        return redirect(url_for('common.login'))

# 管理员-添加学生
@admin_bp.route('/add_student', methods=['POST'])
def add_student():
    if 'user_role' in session and session['user_role'] == 'admin':
        student_name = request.form['student_name']
        student_sex = request.form['student_sex']
        student_birthday = request.form['student_birthday']
        student_class = request.form['class']
        student_department = request.form['student_department']
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            # 调用存储过程添加学生
            cursor.execute("{CALL AddStudent (?, ?, ?, ?, ?, ?)}", (0, student_name, student_sex, student_birthday, student_class, student_department))
            conn.commit()
            return redirect(url_for('admin.admin_dashboard'))
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-查询学生信息
@admin_bp.route('/get_student', methods=['POST'])
def get_student():
    if 'user_role' in session and session['user_role'] == 'admin':
        student_id = request.form['student_id']
        conn = get_db_connection()
        if conn:
            try:
                cursor = conn.cursor()
                cursor.execute("SELECT * FROM Students WHERE StudentID = ?", student_id)
                student = cursor.fetchone()
                if student:
                    return render_template('admin_dashboard.html', student=student)
                else:
                    return 'Student not found'
            except pyodbc.Error as e:
                print(f"Database error: {e}")
                return 'Database error occurred'
            finally:
                conn.close()
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-更新学生信息
@admin_bp.route('/update_student', methods=['POST'])
def update_student():
    if 'user_role' in session and session['user_role'] == 'admin':
        student_id = request.form['student_id']
        student_name = request.form['student_name']
        student_sex = request.form['student_sex']
        student_birthday = request.form['student_birthday']
        student_class = request.form['class']
        student_department = request.form['student_department']
        conn = get_db_connection()
        if conn:
            try:
                cursor = conn.cursor()
                cursor.execute("""
                    UPDATE Students
                    SET StudentName = ?, StudentSex = ?, StudentBirthday = ?, Class = ?, StudentDepartment = ?
                    WHERE StudentID = ?
                """, (student_name, student_sex, student_birthday, student_class, student_department, student_id))
                conn.commit()
                return redirect(url_for('admin.admin_dashboard'))
            except pyodbc.Error as e:
                print(f"Database error: {e}")
                return 'Database error occurred'
            finally:
                conn.close()
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-删除学生
@admin_bp.route('/delete_student', methods=['POST'])
def delete_student():
    if 'user_role' in session and session['user_role'] == 'admin':
        student_id = request.form['student_id']
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute("{CALL DeleteStudent (?)}", (student_id,))
            conn.commit()
            return redirect(url_for('admin.admin_dashboard'))
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))

# 管理员-修改所有用户的登录权限
@admin_bp.route('/update_account_status', methods=['POST'])
def update_account_status():
    if 'user_role' in session and session['user_role'] == 'admin':
        user_id = request.form['user_id']
        account_status = request.form['account_status']
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            cursor.execute("{CALL UpdateAccountStatus (?, ?)}", (user_id, account_status))
            conn.commit()
            return redirect(url_for('admin.admin_dashboard'))
        else:
            return 'Database connection failed'
    else:
        return redirect(url_for('common.login'))