--课程表
CREATE TABLE Courses(
	CourseID CHAR(16) PRIMARY KEY,	--课程编号（主键）
	CourseName CHAR(16) NOT NULL,	--课程名称
	Point FLOAT,					--课程学分
	Term CHAR(10),					--课程所在学期
	StuNumber INT					--选课学生人数	
)


--登录表
CREATE TABLE Login(					
	UserID CHAR(10) PRIMARY KEY,	--用户ID（主键）
	Password CHAR(10) NOT NULL,		--用户密码
	UserRole CHAR(10),				--用户角色，可选值为学生/教师/管理员
	--其中学生、教师可以有多个，管理员只有一个，相当于是有一个超级管理员
	AccountStatus INT DEFAULT 1		--登录权限，0不可登录，1可以登录。
									--默认可以登录，学生/教师登录权限可以由管理员修改
)

--学生表
CREATE TABLE Students(
	StudentID CHAR(14) PRIMARY KEY,	--学生ID
	StudentName CHAR(10) NOT NULL,	--学生姓名
	StudentSex CHAR(2) NOT NULL,	--学生性别
	StudentBirthday DATETIME,		--学生生日
	Class CHAR(16),					--学生所在班级
	StudentDeptartment CHAR(20)				--学生所在院系
)

--教师表
CREATE TABLE Teachers(
	TeacherID CHAR(10) PRIMARY KEY,	--教师编号
	TeacherName CHAR(10) NOT NULL,	--教师姓名
	TeacherSex CHAR(2),				--教师性别
	TeacherBirthday DATETIME,		--教师生日
	Position CHAR(10),				--教师职称
	TeacherDepartment CHAR(20)		--教师院系
)

--教师——课程关系表
CREATE TABLE TeachTable(
	CourseID CHAR(16),
	TeacherID CHAR(10),
	CourseLocation CHAR(10),
	PRIMARY KEY (CourseID, TeacherID),
	FOREIGN KEY (CourseID) REFERENCES Courses ON DELETE CASCADE,
	FOREIGN KEY (TeacherID) REFERENCES Teachers ON DELETE CASCADE
)

--学生——课程成绩关系表
CREATE TABLE ScoreTable(
	CourseID CHAR(16),				--课程号
	StudentID CHAR(14),				--学生号
	Score INT,						--学生课程成绩
	FOREIGN KEY (CourseID) REFERENCES Courses ON DELETE CASCADE,
	FOREIGN KEY (StudentID) REFERENCES Students ON DELETE CASCADE,
	PRIMARY KEY (CourseID, StudentID)
)


--添加课程信息
CREATE PROCEDURE AddCourse
    @CourseID CHAR(16) OUTPUT,
    @CourseName CHAR(16),
    @Point FLOAT,
    @Term CHAR(10),
    @StuNumber INT
AS
BEGIN
    SET @CourseID = CAST((SELECT ISNULL(MAX(CAST(CourseID AS INT)), 0) + 1 FROM Courses) AS CHAR(16));
    INSERT INTO Courses (CourseID, CourseName, Point, Term, StuNumber)
    VALUES (@CourseID, @CourseName, @Point, @Term, @StuNumber);

    SELECT @CourseID AS CourseID;  -- 返回新生成的 CourseID
END;

--修改课程信息
CREATE PROCEDURE UpdateCourse
    @CourseID CHAR(16),
    @CourseName CHAR(16),
    @Point FLOAT,
    @Term CHAR(10),
    @StuNumber INT
AS
BEGIN
    UPDATE Courses
    SET CourseName = @CourseName, Point = @Point, Term = @Term, StuNumber = @StuNumber
    WHERE CourseID = @CourseID;
END;


--删除课程信息
CREATE PROCEDURE DeleteCourse
    @CourseID CHAR(16)
AS
BEGIN
    DELETE FROM Courses
    WHERE CourseID = @CourseID;
END;

--添加教师信息
drop proc AddTeacher
CREATE PROCEDURE AddTeacher
    @TeacherID CHAR(10) OUTPUT,
    @TeacherName CHAR(10),
    @TeacherSex CHAR(2),
    @TeacherBirthday DATETIME,
    @Position CHAR(10),
    @TeacherDepartment CHAR(20)
AS
BEGIN
    SET @TeacherID = CAST((SELECT ISNULL(MAX(CAST(TeacherID AS INT)), 2024000000) + 1 FROM Teachers) AS CHAR(10));
    INSERT INTO Teachers (TeacherID, TeacherName, TeacherSex, TeacherBirthday, Position, TeacherDepartment)
    VALUES (@TeacherID, @TeacherName, @TeacherSex, @TeacherBirthday, @Position, @TeacherDepartment);
    SELECT @TeacherID AS TeacherID;  -- 返回新生成的 TeacherID
END;


--通过触发器实现登录表和教师表的统一
CREATE TRIGGER LoginByTeacher ON Teachers
FOR INSERT
AS
BEGIN
    INSERT INTO Login VALUES((SELECT TeacherID FROM INSERTED),'123456','teacher',1)
END


CREATE TRIGGER LoginByStudent ON Students
FOR INSERT
AS
BEGIN
    INSERT INTO Login VALUES((SELECT StudentID FROM INSERTED),'123456','student',1)
END


--修改教师信息
CREATE PROCEDURE UpdateTeacher
    @TeacherID CHAR(10),
    @TeacherName CHAR(10),
    @TeacherSex CHAR(2),
    @TeacherBirthday DATETIME,
    @Position CHAR(10),
    @TeacherDepartment CHAR(20)
AS
BEGIN
    UPDATE Teachers
    SET TeacherName = @TeacherName, TeacherSex = @TeacherSex, TeacherBirthday = @TeacherBirthday,
        Position = @Position, TeacherDepartment = @TeacherDepartment
    WHERE TeacherID = @TeacherID;
END;

--删除教师信息
CREATE PROCEDURE DeleteTeacher
    @TeacherID CHAR(10)
AS
BEGIN
    DELETE FROM Teachers
    WHERE TeacherID = @TeacherID;
END;
--同步删除User表中记录
CREATE TRIGGER DeleteLoginByTeacher ON Teachers
FOR DELETE
AS
BEGIN
    DELETE FROM Login WHERE UserID=(SELECT TeacherID FROM DELETED)
END
--TeachTable
CREATE PROCEDURE InsertIntoTeachTable
    @TeacherID CHAR(10),
    @CourseID CHAR(16)
AS
BEGIN
    -- 检查TeacherID是否存在
    IF NOT EXISTS (SELECT 1 FROM Teachers WHERE TeacherID = @TeacherID)
    BEGIN
        RAISERROR('TeacherID does not exist', 16, 1);
        RETURN;
    END

    -- 检查CourseID是否存在
    IF NOT EXISTS (SELECT 1 FROM Courses WHERE CourseID = @CourseID)
    BEGIN
        RAISERROR('CourseID does not exist', 16, 1);
        RETURN;
    END

    -- 插入记录
    INSERT INTO TeachTable (TeacherID, CourseID)
    VALUES (@TeacherID, @CourseID);
END;

--查看教师授课表
CREATE PROCEDURE GetTeachTablePage
    @PageNumber INT,
    @PageSize INT
AS
BEGIN
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    SELECT TeacherID, CourseID
    FROM TeachTable
    ORDER BY TeacherID, CourseID
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;


--添加学生信息
DROP PROCEDURE AddStudent
CREATE PROCEDURE AddStudent
    @StudentID CHAR(14) output,
    @StudentName CHAR(10),
    @StudentSex CHAR(2),
    @StudentBirthday DATETIME,
    @Class CHAR(16),
    @StudentDepartment CHAR(20)
AS
BEGIN
    SET @StudentID = CAST((SELECT ISNULL(MAX(CAST(StudentID AS BIGINT)), 22920212204000) + 1 FROM Students) AS CHAR(14));
    INSERT INTO Students (StudentID, StudentName, StudentSex, StudentBirthday, Class, StudentDepartment)
    VALUES (@StudentID, @StudentName, @StudentSex, @StudentBirthday, @Class, @StudentDepartment);
	SELECT @StudentID AS StudentID;
END;



--修改学生信息
CREATE PROCEDURE UpdateStudent
    @StudentID CHAR(14),
    @StudentName CHAR(10),
    @StudentSex CHAR(2),
    @StudentBirthday DATETIME,
    @Class CHAR(16),
    @StudentDepartment CHAR(20)
AS
BEGIN
    UPDATE Students
    SET StudentName = @StudentName, StudentSex = @StudentSex, StudentBirthday = @StudentBirthday,
        Class = @Class, StudentDepartment = @StudentDepartment
    WHERE StudentID = @StudentID;
END;


--删除学生信息
CREATE PROCEDURE DeleteStudent
    @StudentID CHAR(14)
AS
BEGIN
    DELETE FROM Students
    WHERE StudentID = @StudentID;
END;
--同步删除User表中记录
CREATE TRIGGER DeleteLoginByStudent ON Students
FOR DELETE
AS
BEGIN
    DELETE FROM Login WHERE UserID = (SELECT StudentID FROM DELETED)
END

--修改登入密码
CREATE PROCEDURE ChangePassword
    @UserID CHAR(10),
    @NewPassword CHAR(10)
AS
BEGIN
    UPDATE Login
    SET Password = @NewPassword
    WHERE UserID = @UserID;
END;

--更新用户登录权限
Drop PROCEDURE UpdateAccountStatus
CREATE PROCEDURE UpdateAccountStatus
    @UserID CHAR(14),
    @AccountStatus INT
AS
BEGIN
    UPDATE Login
    SET AccountStatus = @AccountStatus
    WHERE UserID = @UserID;
END;


--查询全体学生信息
SELECT * FROM Students

--查询全体教师信息
SELECT * FROM Teachers

--查询全体课程信息
SELECT * FROM Courses

--录入成绩
CREATE PROCEDURE EnterScore
    @CourseID CHAR(16),
    @StudentID CHAR(14),
    @Score INT
AS
BEGIN
     IF EXISTS (SELECT * FROM ScoreTable WHERE CourseID = @CourseID AND StudentID = @StudentID)
        BEGIN
            UPDATE ScoreTable
            SET Score = @Score
            WHERE CourseID = @CourseID AND StudentID = @StudentID;
        END
     ELSE
        BEGIN
            INSERT INTO ScoreTable (CourseID, StudentID, Score)
            VALUES (@CourseID, @StudentID, @Score);
        END
END

--查询某个教师信息
CREATE PROCEDURE GetTeacherInfo
    @TeacherID CHAR(10)
AS
BEGIN
    SELECT * FROM Teachers
    WHERE TeacherID = @TeacherID;
END;

--查询老师教授的课程
drop PROCEDURE GetTeacherCourses
CREATE PROCEDURE GetTeacherCourses
    @TeacherID CHAR(10)
AS
BEGIN
    SELECT c.CourseID, c.CourseName, c.Point, c.Term, c.StuNumber
    FROM Courses c
    JOIN TeachTable tc ON c.CourseID = tc.CourseID
    WHERE tc.TeacherID = @TeacherID;
END;
--查询老师教授的课程（按学期）
drop PROCEDURE GetTeacherCoursesByTerm
CREATE PROCEDURE GetTeacherCoursesByTerm
    @TeacherID CHAR(10),
    @Term CHAR(10)
AS
BEGIN
	IF @Term = 'ALL'
	BEGIN
		SELECT c.CourseID, c.CourseName, c.Point, c.Term, c.StuNumber
		FROM Courses c
		JOIN TeacherCourses tc ON c.CourseID = tc.CourseID
		WHERE tc.TeacherID = @TeacherID
	END
	ELSE
	BEGIN
		SELECT c.CourseID, c.CourseName, c.Point, c.Term, c.StuNumber
		FROM Courses c
		JOIN TeacherCourses tc ON c.CourseID = tc.CourseID
		WHERE tc.TeacherID = @TeacherID AND c.Term = @Term;
	END
END;
--查询某门课全体学生成绩
CREATE PROCEDURE GetCoursesScores
	@CourseID CHAR(16)
AS
BEGIN
    select * FROM AllStudentScores WHERE CourseID=@CourseID;
    --SELECT s.StudentID, s.StudentName, c.CourseID, c.CourseName, sc.Score
    --FROM Students s
    --JOIN ScoreTable sc ON s.StudentID = sc.StudentID
    --JOIN Courses c ON sc.CourseID = c.CourseID
    --WHERE s.StudentID = @StudentID;
END;

--查询某个学生某门课成绩
CREATE PROCEDURE GetStudentScores
    @StudentID CHAR(14),
	@CourseID CHAR(16)
AS
BEGIN
    select * FROM AllStudentScores WHERE StudentID = @StudentID AND CourseID=@CourseID;
    --SELECT s.StudentID, s.StudentName, c.CourseID, c.CourseName, sc.Score
    --FROM Students s
    --JOIN ScoreTable sc ON s.StudentID = sc.StudentID
    --JOIN Courses c ON sc.CourseID = c.CourseID
    --WHERE s.StudentID = @StudentID;
END;

--查询学生个人信息
CREATE PROCEDURE GetStudentInfo
    @StudentID CHAR(14)
AS
BEGIN
    SELECT * FROM Students
    WHERE StudentID = @StudentID;
END;

--查询全体学生成绩（创建成绩视图）
CREATE VIEW AllStudentScores AS
SELECT s.StudentID, s.StudentName, c.CourseID, c.CourseName, sc.Score,c.Point
FROM Students s
JOIN ScoreTable sc ON s.StudentID = sc.StudentID
JOIN Courses c ON sc.CourseID = c.CourseID;

select * from AllStudentScores

--根据学期查成绩
drop PROCEDURE GetStudentScoresByTerm
CREATE PROCEDURE GetStudentScoresByTerm
    @StudentID CHAR(14),
    @Term CHAR(10)
AS
BEGIN
    IF @Term = 'All'
    BEGIN
        SELECT * FROM AllStudentScores WHERE StudentID = @StudentID
    END
    ELSE
    BEGIN
        SELECT * FROM AllStudentScores WHERE StudentID = @StudentID AND Term = @Term
    END
END;


--计算学生个人加权绩点
drop FUNCTION CalculateWeightedGPA 
CREATE FUNCTION CalculateWeightedGPA (@StudentID CHAR(14))
RETURNS FLOAT
AS
BEGIN
    DECLARE @WeightedGPA FLOAT;

    SELECT @WeightedGPA = SUM(CASE 
                                WHEN sc.Score >= 95 THEN 4.0 * c.Point
                                WHEN sc.Score >= 90 THEN 4.0 * c.Point
                                WHEN sc.Score >= 85 THEN 3.7 * c.Point
                                WHEN sc.Score >= 81 THEN 3.3 * c.Point
                                WHEN sc.Score >= 78 THEN 3.0 * c.Point
                                WHEN sc.Score >= 75 THEN 2.7 * c.Point
                                WHEN sc.Score >= 72 THEN 2.3 * c.Point
                                WHEN sc.Score >= 68 THEN 2.0 * c.Point
                                WHEN sc.Score >= 64 THEN 1.7 * c.Point
                                WHEN sc.Score >= 60 THEN 1.0 * c.Point
                                ELSE 0 * c.Point
                              END) / SUM(c.Point)
    FROM ScoreTable sc
    JOIN Courses c ON sc.CourseID = c.CourseID
    WHERE sc.StudentID = @StudentID;

    RETURN @WeightedGPA;
END;

--查询学生个人加权绩点
CREATE PROCEDURE GetStudentWeightedGPA
    @StudentID CHAR(14)
AS
BEGIN
    SELECT dbo.CalculateWeightedGPA(@StudentID) AS WeightedGPA;
END;

--计算学生个人加权平均分
CREATE FUNCTION CalculateWeightedAverageScore (@StudentID CHAR(14))
RETURNS FLOAT
AS
BEGIN
    DECLARE @WeightedAverageScore FLOAT;

    SELECT @WeightedAverageScore = SUM(sc.Score * c.Point) / SUM(c.Point)
    FROM ScoreTable sc
    JOIN Courses c ON sc.CourseID = c.CourseID
    WHERE sc.StudentID = @StudentID;

    RETURN @WeightedAverageScore;
END;

--查询学生个人加权平均分
CREATE PROCEDURE GetStudentWeightedAverageScore
    @StudentID CHAR(14)
AS
BEGIN
    SELECT dbo.CalculateWeightedAverageScore(@StudentID) AS WeightedAverageScore;
END;

insert into TeachTable
values(select c.CourseID,t.TeacherID from Courses c,Teachers t where c.CourseID = '1'and t.TeacherID = '200400001')























