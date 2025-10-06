--�γ̱�
CREATE TABLE Courses(
	CourseID CHAR(16) PRIMARY KEY,	--�γ̱�ţ�������
	CourseName CHAR(16) NOT NULL,	--�γ�����
	Point FLOAT,					--�γ�ѧ��
	Term CHAR(10),					--�γ�����ѧ��
	StuNumber INT					--ѡ��ѧ������	
)


--��¼��
CREATE TABLE Login(					
	UserID CHAR(10) PRIMARY KEY,	--�û�ID��������
	Password CHAR(10) NOT NULL,		--�û�����
	UserRole CHAR(10),				--�û���ɫ����ѡֵΪѧ��/��ʦ/����Ա
	--����ѧ������ʦ�����ж��������Աֻ��һ�����൱������һ����������Ա
	AccountStatus INT DEFAULT 1		--��¼Ȩ�ޣ�0���ɵ�¼��1���Ե�¼��
									--Ĭ�Ͽ��Ե�¼��ѧ��/��ʦ��¼Ȩ�޿����ɹ���Ա�޸�
)

--ѧ����
CREATE TABLE Students(
	StudentID CHAR(14) PRIMARY KEY,	--ѧ��ID
	StudentName CHAR(10) NOT NULL,	--ѧ������
	StudentSex CHAR(2) NOT NULL,	--ѧ���Ա�
	StudentBirthday DATETIME,		--ѧ������
	Class CHAR(16),					--ѧ�����ڰ༶
	StudentDeptartment CHAR(20)				--ѧ������Ժϵ
)

--��ʦ��
CREATE TABLE Teachers(
	TeacherID CHAR(10) PRIMARY KEY,	--��ʦ���
	TeacherName CHAR(10) NOT NULL,	--��ʦ����
	TeacherSex CHAR(2),				--��ʦ�Ա�
	TeacherBirthday DATETIME,		--��ʦ����
	Position CHAR(10),				--��ʦְ��
	TeacherDepartment CHAR(20)		--��ʦԺϵ
)

--��ʦ�����γ̹�ϵ��
CREATE TABLE TeachTable(
	CourseID CHAR(16),
	TeacherID CHAR(10),
	CourseLocation CHAR(10),
	PRIMARY KEY (CourseID, TeacherID),
	FOREIGN KEY (CourseID) REFERENCES Courses ON DELETE CASCADE,
	FOREIGN KEY (TeacherID) REFERENCES Teachers ON DELETE CASCADE
)

--ѧ�������γ̳ɼ���ϵ��
CREATE TABLE ScoreTable(
	CourseID CHAR(16),				--�γ̺�
	StudentID CHAR(14),				--ѧ����
	Score INT,						--ѧ���γ̳ɼ�
	FOREIGN KEY (CourseID) REFERENCES Courses ON DELETE CASCADE,
	FOREIGN KEY (StudentID) REFERENCES Students ON DELETE CASCADE,
	PRIMARY KEY (CourseID, StudentID)
)


--��ӿγ���Ϣ
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

    SELECT @CourseID AS CourseID;  -- ���������ɵ� CourseID
END;

--�޸Ŀγ���Ϣ
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


--ɾ���γ���Ϣ
CREATE PROCEDURE DeleteCourse
    @CourseID CHAR(16)
AS
BEGIN
    DELETE FROM Courses
    WHERE CourseID = @CourseID;
END;

--��ӽ�ʦ��Ϣ
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
    SELECT @TeacherID AS TeacherID;  -- ���������ɵ� TeacherID
END;


--ͨ��������ʵ�ֵ�¼��ͽ�ʦ���ͳһ
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


--�޸Ľ�ʦ��Ϣ
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

--ɾ����ʦ��Ϣ
CREATE PROCEDURE DeleteTeacher
    @TeacherID CHAR(10)
AS
BEGIN
    DELETE FROM Teachers
    WHERE TeacherID = @TeacherID;
END;
--ͬ��ɾ��User���м�¼
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
    -- ���TeacherID�Ƿ����
    IF NOT EXISTS (SELECT 1 FROM Teachers WHERE TeacherID = @TeacherID)
    BEGIN
        RAISERROR('TeacherID does not exist', 16, 1);
        RETURN;
    END

    -- ���CourseID�Ƿ����
    IF NOT EXISTS (SELECT 1 FROM Courses WHERE CourseID = @CourseID)
    BEGIN
        RAISERROR('CourseID does not exist', 16, 1);
        RETURN;
    END

    -- �����¼
    INSERT INTO TeachTable (TeacherID, CourseID)
    VALUES (@TeacherID, @CourseID);
END;

--�鿴��ʦ�ڿα�
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


--���ѧ����Ϣ
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



--�޸�ѧ����Ϣ
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


--ɾ��ѧ����Ϣ
CREATE PROCEDURE DeleteStudent
    @StudentID CHAR(14)
AS
BEGIN
    DELETE FROM Students
    WHERE StudentID = @StudentID;
END;
--ͬ��ɾ��User���м�¼
CREATE TRIGGER DeleteLoginByStudent ON Students
FOR DELETE
AS
BEGIN
    DELETE FROM Login WHERE UserID = (SELECT StudentID FROM DELETED)
END

--�޸ĵ�������
CREATE PROCEDURE ChangePassword
    @UserID CHAR(10),
    @NewPassword CHAR(10)
AS
BEGIN
    UPDATE Login
    SET Password = @NewPassword
    WHERE UserID = @UserID;
END;

--�����û���¼Ȩ��
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


--��ѯȫ��ѧ����Ϣ
SELECT * FROM Students

--��ѯȫ���ʦ��Ϣ
SELECT * FROM Teachers

--��ѯȫ��γ���Ϣ
SELECT * FROM Courses

--¼��ɼ�
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

--��ѯĳ����ʦ��Ϣ
CREATE PROCEDURE GetTeacherInfo
    @TeacherID CHAR(10)
AS
BEGIN
    SELECT * FROM Teachers
    WHERE TeacherID = @TeacherID;
END;

--��ѯ��ʦ���ڵĿγ�
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
--��ѯ��ʦ���ڵĿγ̣���ѧ�ڣ�
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
--��ѯĳ�ſ�ȫ��ѧ���ɼ�
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

--��ѯĳ��ѧ��ĳ�ſγɼ�
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

--��ѯѧ��������Ϣ
CREATE PROCEDURE GetStudentInfo
    @StudentID CHAR(14)
AS
BEGIN
    SELECT * FROM Students
    WHERE StudentID = @StudentID;
END;

--��ѯȫ��ѧ���ɼ��������ɼ���ͼ��
CREATE VIEW AllStudentScores AS
SELECT s.StudentID, s.StudentName, c.CourseID, c.CourseName, sc.Score,c.Point
FROM Students s
JOIN ScoreTable sc ON s.StudentID = sc.StudentID
JOIN Courses c ON sc.CourseID = c.CourseID;

select * from AllStudentScores

--����ѧ�ڲ�ɼ�
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


--����ѧ�����˼�Ȩ����
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

--��ѯѧ�����˼�Ȩ����
CREATE PROCEDURE GetStudentWeightedGPA
    @StudentID CHAR(14)
AS
BEGIN
    SELECT dbo.CalculateWeightedGPA(@StudentID) AS WeightedGPA;
END;

--����ѧ�����˼�Ȩƽ����
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

--��ѯѧ�����˼�Ȩƽ����
CREATE PROCEDURE GetStudentWeightedAverageScore
    @StudentID CHAR(14)
AS
BEGIN
    SELECT dbo.CalculateWeightedAverageScore(@StudentID) AS WeightedAverageScore;
END;

insert into TeachTable
values(select c.CourseID,t.TeacherID from Courses c,Teachers t where c.CourseID = '1'and t.TeacherID = '200400001')























