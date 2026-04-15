-- ============================================================
-- CSCI 432 Database Systems
-- Grade Book Database - Complete Implementation
-- Tasks 1-12 from Project Specification
-- ============================================================

DROP DATABASE IF EXISTS gradebook;
CREATE DATABASE gradebook;
USE gradebook;

-- ============================================================
-- TASK 2: TABLE CREATION
-- ============================================================

-- Stores each course the professor teaches
CREATE TABLE Course (
    course_id   INT                                         NOT NULL AUTO_INCREMENT,
    department  VARCHAR(100)                                NOT NULL,
    course_num  VARCHAR(20)                                 NOT NULL,
    course_name VARCHAR(255)                                NOT NULL,
    semester    ENUM('Spring','Summer','Fall','Winter')     NOT NULL,
    year        INT                                         NOT NULL CHECK (year >= 2000 AND year <= 2100),
    PRIMARY KEY (course_id),
    UNIQUE (department, course_num, semester, year)
) ENGINE=InnoDB;

-- Stores student info
CREATE TABLE Student (
    student_id INT          NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name  VARCHAR(100) NOT NULL,
    email      VARCHAR(255) NOT NULL,
    PRIMARY KEY (student_id),
    UNIQUE (email)
) ENGINE=InnoDB;

-- Links students to courses (many-to-many)
CREATE TABLE Enrollment (
    course_id   INT                                                      NOT NULL,
    student_id  INT                                                      NOT NULL,
    status      ENUM('enrolled','dropped','withdrawn','audit')           NOT NULL DEFAULT 'enrolled',
    enrolled_at DATE                                                      NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (course_id, student_id),
    FOREIGN KEY (course_id)  REFERENCES Course(course_id)  ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Grade categories for each course (e.g. Homework 20%, Tests 50%)
-- Weights must sum to 100 per course (enforced by triggers below)
CREATE TABLE Category (
    category_id   INT          NOT NULL AUTO_INCREMENT,
    course_id     INT          NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    weight        DECIMAL(5,2) NOT NULL CHECK (weight > 0 AND weight <= 100),
    PRIMARY KEY (category_id),
    UNIQUE (course_id, category_name),
    FOREIGN KEY (course_id) REFERENCES Course(course_id) ON DELETE CASCADE
) ENGINE=InnoDB;

DELIMITER $$

CREATE TRIGGER trg_category_weight_insert
BEFORE INSERT ON Category
FOR EACH ROW
BEGIN
    DECLARE total DECIMAL(6,2);
    SELECT COALESCE(SUM(weight), 0) INTO total
    FROM Category WHERE course_id = NEW.course_id;
    IF total + NEW.weight > 100.01 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Category weights would exceed 100% for this course';
    END IF;
END$$

CREATE TRIGGER trg_category_weight_update
BEFORE UPDATE ON Category
FOR EACH ROW
BEGIN
    DECLARE total DECIMAL(6,2);
    SELECT COALESCE(SUM(weight), 0) INTO total
    FROM Category
    WHERE course_id = NEW.course_id AND category_id <> OLD.category_id;
    IF total + NEW.weight > 100.01 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Category weights would exceed 100% for this course';
    END IF;
END$$

DELIMITER ;

-- Individual assignments that belong to a category
CREATE TABLE Assignment (
    assignment_id   INT          NOT NULL AUTO_INCREMENT,
    category_id     INT          NOT NULL,
    assignment_name VARCHAR(255) NOT NULL,
    max_score       DECIMAL(6,2) NOT NULL DEFAULT 100 CHECK (max_score > 0),
    due_date        DATE         NULL,
    PRIMARY KEY (assignment_id),
    UNIQUE (category_id, assignment_name),
    FOREIGN KEY (category_id) REFERENCES Category(category_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- One row per student per assignment; NULL score = not yet submitted
CREATE TABLE Score (
    assignment_id INT          NOT NULL,
    student_id    INT          NOT NULL,
    score         DECIMAL(6,2) DEFAULT NULL CHECK (score IS NULL OR score >= 0),
    PRIMARY KEY (assignment_id, student_id),
    FOREIGN KEY (assignment_id) REFERENCES Assignment(assignment_id) ON DELETE CASCADE,
    FOREIGN KEY (student_id)    REFERENCES Student(student_id)       ON DELETE RESTRICT
) ENGINE=InnoDB;


-- ============================================================
-- TASK 2 (cont.): INSERT SAMPLE DATA
-- ============================================================

-- Courses
INSERT INTO Course (department, course_num, course_name, semester, year) VALUES
    ('CSCI', '101',  'Intro to Computer Science',  'Fall',   2024),
    ('CSCI', '432',  'Database Systems',            'Spring', 2025),
    ('MATH', '201',  'Calculus II',                 'Spring', 2025);

-- Students
INSERT INTO Student (first_name, last_name, email) VALUES
    ('Alice',   'Johnson',  'alice.johnson@university.edu'),
    ('Bob',     'Smith',    'bob.smith@university.edu'),
    ('Carol',   'Quinn',    'carol.quinn@university.edu'),    -- last name contains Q
    ('David',   'Qureshi',  'david.qureshi@university.edu'), -- last name contains Q
    ('Eve',     'Martinez', 'eve.martinez@university.edu'),
    ('Frank',   'Lee',      'frank.lee@university.edu');

-- Enrollments
-- CSCI 101 (course_id=1): all students
INSERT INTO Enrollment (course_id, student_id) VALUES
    (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6);

-- CSCI 432 (course_id=2): students 1-4
INSERT INTO Enrollment (course_id, student_id) VALUES
    (2, 1), (2, 2), (2, 3), (2, 4);

-- MATH 201 (course_id=3): students 3-6
INSERT INTO Enrollment (course_id, student_id) VALUES
    (3, 3), (3, 4), (3, 5), (3, 6);

-- Categories for CSCI 101 (course_id=1): must sum to 100
INSERT INTO Category (course_id, category_name, weight) VALUES
    (1, 'Participation', 10.00),
    (1, 'Homework',      20.00),
    (1, 'Tests',         50.00),
    (1, 'Projects',      20.00);

-- Categories for CSCI 432 (course_id=2): must sum to 100
INSERT INTO Category (course_id, category_name, weight) VALUES
    (2, 'Homework',  30.00),
    (2, 'Midterm',   30.00),
    (2, 'Final',     40.00);

-- Categories for MATH 201 (course_id=3): must sum to 100
INSERT INTO Category (course_id, category_name, weight) VALUES
    (3, 'Homework',  40.00),
    (3, 'Tests',     60.00);

-- Assignments for CSCI 101
--   Participation  (category_id=1)
INSERT INTO Assignment (category_id, assignment_name, max_score, due_date) VALUES
    (1, 'Week 1 Participation',  10.00, '2024-09-06'),
    (1, 'Week 2 Participation',  10.00, '2024-09-13');

--   Homework (category_id=2) – 5 homeworks, each worth 20%/5 = 4% of grade
INSERT INTO Assignment (category_id, assignment_name, max_score, due_date) VALUES
    (2, 'HW1', 100.00, '2024-09-10'),
    (2, 'HW2', 100.00, '2024-09-24'),
    (2, 'HW3', 100.00, '2024-10-08'),
    (2, 'HW4', 100.00, '2024-10-22'),
    (2, 'HW5', 100.00, '2024-11-05');

--   Tests (category_id=3)
INSERT INTO Assignment (category_id, assignment_name, max_score, due_date) VALUES
    (3, 'Midterm Exam', 100.00, '2024-10-15'),
    (3, 'Final Exam',   100.00, '2024-12-10');

--   Projects (category_id=4)
INSERT INTO Assignment (category_id, assignment_name, max_score, due_date) VALUES
    (4, 'Project 1', 100.00, '2024-11-01'),
    (4, 'Project 2', 100.00, '2024-12-01');

-- Assignments for CSCI 432
--   Homework (category_id=5)
INSERT INTO Assignment (category_id, assignment_name, max_score, due_date) VALUES
    (5, 'DB HW1 - ER Diagrams',   100.00, '2025-02-10'),
    (5, 'DB HW2 - SQL Basics',    100.00, '2025-02-24'),
    (5, 'DB HW3 - Normalization', 100.00, '2025-03-10');

--   Midterm (category_id=6)
INSERT INTO Assignment (category_id, assignment_name, max_score, due_date) VALUES
    (6, 'Midterm Exam', 100.00, '2025-03-18');

--   Final (category_id=7)
INSERT INTO Assignment (category_id, assignment_name, max_score, due_date) VALUES
    (7, 'Final Exam', 100.00, '2025-05-06');

-- Scores for CSCI 101 students
-- assignment_id reference (CSCI 101): 1=Wk1 Participation, 2=Wk2 Participation,
--   3=HW1, 4=HW2, 5=HW3, 6=HW4, 7=HW5,
--   8=Midterm, 9=Final, 10=Project1, 11=Project2

INSERT INTO Score (assignment_id, student_id, score) VALUES
-- Alice (student 1)
    (1,1,9),(2,1,10),(3,1,88),(4,1,92),(5,1,85),(6,1,90),(7,1,95),
    (8,1,88),(9,1,91),(10,1,93),(11,1,87),
-- Bob (student 2)
    (1,2,7),(2,2,8),(3,2,72),(4,2,68),(5,2,75),(6,2,70),(7,2,65),
    (8,2,74),(9,2,71),(10,2,76),(11,2,69),
-- Carol Quinn (student 3) – contains Q
    (1,3,10),(2,3,10),(3,3,95),(4,3,98),(5,3,92),(6,3,97),(7,3,94),
    (8,3,96),(9,3,99),(10,3,100),(11,3,98),
-- David Qureshi (student 4) – contains Q
    (1,4,6),(2,4,7),(3,4,60),(4,4,55),(5,4,62),(6,4,58),(7,4,50),
    (8,4,63),(9,4,57),(10,4,65),(11,4,53),
-- Eve (student 5)
    (1,5,8),(2,5,9),(3,5,80),(4,5,83),(5,5,78),(6,5,85),(7,5,82),
    (8,5,79),(9,5,84),(10,5,88),(11,5,81),
-- Frank (student 6)
    (1,6,5),(2,6,6),(3,6,55),(4,6,60),(5,6,58),(6,6,52),(7,6,NULL), -- HW5 not submitted
    (8,6,66),(9,6,61),(10,6,70),(11,6,64);

-- Scores for CSCI 432 students
-- assignment_id reference: 12=DB HW1, 13=DB HW2, 14=DB HW3, 15=Midterm, 16=Final
INSERT INTO Score (assignment_id, student_id, score) VALUES
    (12,1,90),(13,1,85),(14,1,92),(15,1,88),(16,1,91),
    (12,2,70),(13,2,75),(14,2,68),(15,2,72),(16,2,74),
    (12,3,98),(13,3,95),(14,3,97),(15,3,99),(16,3,96),
    (12,4,50),(13,4,55),(14,4,48),(15,4,60),(16,4,52);


-- ============================================================
-- TASK 4: Average, highest, and lowest score for an assignment
-- (Example: HW1 in CSCI 101, assignment_id = 3)
-- ============================================================

SELECT
    a.assignment_name,
    c.course_name,
    ROUND(AVG(s.score), 2)  AS avg_score,
    MAX(s.score)             AS highest_score,
    MIN(s.score)             AS lowest_score
FROM Score s
JOIN Assignment a ON s.assignment_id = a.assignment_id
JOIN Category   ct ON a.category_id  = ct.category_id
JOIN Course     c  ON ct.course_id   = c.course_id
WHERE s.assignment_id = 3          -- change to target a different assignment
  AND s.score IS NOT NULL;


-- ============================================================
-- TASK 5: List all students in a given course
-- (Example: CSCI 101, course_id = 1)
-- ============================================================

SELECT
    s.student_id,
    s.first_name,
    s.last_name,
    s.email,
    e.status
FROM Enrollment e
JOIN Student s ON e.student_id = s.student_id
WHERE e.course_id = 1             -- change to target a different course
ORDER BY s.last_name, s.first_name;


-- ============================================================
-- TASK 6: List all students in a course with their scores
--         on every assignment
-- (Example: CSCI 101, course_id = 1)
-- ============================================================

SELECT
    s.last_name,
    s.first_name,
    ct.category_name,
    a.assignment_name,
    a.max_score,
    sc.score,
    CASE
        WHEN sc.score IS NULL THEN 'Not Submitted'
        ELSE CONCAT(ROUND(sc.score / a.max_score * 100, 1), '%')
    END AS pct
FROM Enrollment e
JOIN Student    s  ON e.student_id   = s.student_id
JOIN Category   ct ON ct.course_id   = e.course_id
JOIN Assignment a  ON a.category_id  = ct.category_id
LEFT JOIN Score sc ON sc.assignment_id = a.assignment_id
                   AND sc.student_id   = s.student_id
WHERE e.course_id = 1             -- change to target a different course
ORDER BY s.last_name, s.first_name, ct.category_name, a.assignment_name;


-- ============================================================
-- TASK 7: Add an assignment to a course
-- (Adds 'HW6' to the Homework category of CSCI 101)
-- ============================================================

INSERT INTO Assignment (category_id, assignment_name, max_score, due_date)
VALUES (
    (SELECT category_id FROM Category
     WHERE course_id = 1 AND category_name = 'Homework'),
    'HW6',
    100.00,
    '2024-11-19'
);

-- Verify
SELECT a.assignment_id, a.assignment_name, a.max_score, a.due_date,
       ct.category_name, c.course_name
FROM Assignment a
JOIN Category ct ON a.category_id = ct.category_id
JOIN Course   c  ON ct.course_id  = c.course_id
WHERE c.course_id = 1
ORDER BY ct.category_name, a.assignment_name;


-- ============================================================
-- TASK 8: Change the percentages of the categories for a course
-- (Redistribute CSCI 101 weights: keep total = 100)
-- ============================================================

UPDATE Category SET weight = 40.00
WHERE course_id = 1 AND category_name = 'Tests';      -- 50 → 40 (now total = 90)

UPDATE Category SET weight = 15.00
WHERE course_id = 1 AND category_name = 'Participation'; -- 10 → 15 (now total = 95)

UPDATE Category SET weight = 25.00
WHERE course_id = 1 AND category_name = 'Homework';    -- 20 → 25 (now total = 100)

UPDATE Category SET weight = 20.00
WHERE course_id = 1 AND category_name = 'Projects';    -- stays 20

-- Verify the new weights
SELECT category_name, weight,
       SUM(weight) OVER (PARTITION BY course_id) AS total_weight
FROM Category
WHERE course_id = 1;


-- ============================================================
-- TASK 9: Add 2 points to every student's score on an assignment
-- (Example: HW1, assignment_id = 3, max_score = 100)
-- ============================================================

UPDATE Score
SET score = LEAST(score + 2, (SELECT max_score FROM Assignment WHERE assignment_id = 3))
WHERE assignment_id = 3
  AND score IS NOT NULL;

-- Verify
SELECT s.first_name, s.last_name, sc.score
FROM Score sc
JOIN Student s ON sc.student_id = s.student_id
WHERE sc.assignment_id = 3
ORDER BY s.last_name;


-- ============================================================
-- TASK 10: Add 2 points only to students whose last name
--          contains a 'Q' (case-insensitive)
-- (Example: HW2, assignment_id = 4)
-- ============================================================

UPDATE Score sc
JOIN Student s ON sc.student_id = s.student_id
SET sc.score = LEAST(
    sc.score + 2,
    (SELECT max_score FROM Assignment WHERE assignment_id = 4)
)
WHERE sc.assignment_id = 4
  AND sc.score IS NOT NULL
  AND s.last_name LIKE '%Q%';

-- Verify
SELECT s.first_name, s.last_name, sc.score
FROM Score sc
JOIN Student s ON sc.student_id = s.student_id
WHERE sc.assignment_id = 4
ORDER BY s.last_name;


-- ============================================================
-- TASK 11: Compute the final grade for a student
--
-- Formula:
--   For each category:
--     category_score = SUM(score) / SUM(max_score)   (handles any # of assignments)
--     weighted_score = category_score * weight
--   Final grade = SUM(weighted_score) / SUM(weight)  (normalises if weights < 100)
--
-- NULL scores are treated as 0 (not submitted = 0 credit).
-- (Example: student Alice, student_id = 1, in CSCI 101, course_id = 1)
-- ============================================================

SELECT
    s.first_name,
    s.last_name,
    c.course_name,
    ROUND(
        SUM(
            (COALESCE(SUM(sc.score), 0) / SUM(a.max_score)) * ct.weight
        ) / SUM(ct.weight) * 100,
    2) AS final_grade_pct
FROM Enrollment e
JOIN Student    s  ON e.student_id   = s.student_id
JOIN Course     c  ON e.course_id    = c.course_id
JOIN Category   ct ON ct.course_id   = c.course_id
JOIN Assignment a  ON a.category_id  = ct.category_id
LEFT JOIN Score sc ON sc.assignment_id = a.assignment_id
                   AND sc.student_id   = s.student_id
WHERE e.course_id  = 1    -- change course
  AND e.student_id = 1    -- change student
GROUP BY s.student_id, s.first_name, s.last_name,
         c.course_id, c.course_name, ct.category_id, ct.weight;


-- Final grade for ALL students in a course (course_id = 1)
SELECT
    s.student_id,
    s.first_name,
    s.last_name,
    c.course_name,
    ROUND(
        SUM(cat_weighted) / SUM(DISTINCT ct.weight) * 100,
    2) AS final_grade_pct
FROM (
    SELECT
        e.student_id,
        ct.category_id,
        ct.weight,
        (COALESCE(SUM(sc.score), 0) / SUM(a.max_score)) * ct.weight AS cat_weighted
    FROM Enrollment e
    JOIN Category   ct ON ct.course_id   = e.course_id
    JOIN Assignment a  ON a.category_id  = ct.category_id
    LEFT JOIN Score sc ON sc.assignment_id = a.assignment_id
                       AND sc.student_id   = e.student_id
    WHERE e.course_id = 1
    GROUP BY e.student_id, ct.category_id, ct.weight
) AS cat_scores
JOIN Student s  ON cat_scores.student_id = s.student_id
JOIN Category ct ON cat_scores.category_id = ct.category_id
JOIN Course c ON ct.course_id = c.course_id
GROUP BY s.student_id, s.first_name, s.last_name, c.course_name
ORDER BY final_grade_pct DESC;


-- ============================================================
-- TASK 12: Compute the grade for a student, dropping the
--          lowest score in each category
-- (Example: all students in CSCI 101, course_id = 1)
-- ============================================================

-- Step 1: rank scores within each (student, category) group
-- Step 2: exclude the single lowest score (rank = 1) per group
-- Step 3: recompute weighted grade exactly as Task 11

SELECT
    s.student_id,
    s.first_name,
    s.last_name,
    c.course_name,
    ROUND(
        SUM(cat_weighted) / 100 * 100,
    2) AS final_grade_drop_lowest_pct
FROM (
    SELECT
        e.student_id,
        ct.category_id,
        ct.weight,
        -- Sum scores excluding the lowest in each category
        (
            COALESCE(
                SUM(CASE WHEN rk.rnk > 1 THEN sc.score ELSE 0 END),
                0
            )
            /
            -- Subtract the lowest max_score from denominator too (fair drop)
            NULLIF(
                SUM(CASE WHEN rk.rnk > 1 THEN a.max_score ELSE 0 END),
                0
            )
        ) * ct.weight AS cat_weighted
    FROM Enrollment e
    JOIN Category   ct ON ct.course_id    = e.course_id
    JOIN Assignment a  ON a.category_id   = ct.category_id
    LEFT JOIN Score sc ON sc.assignment_id = a.assignment_id
                       AND sc.student_id   = e.student_id
    -- Rank each student's scores within a category (lowest first)
    LEFT JOIN (
        SELECT
            sc2.student_id,
            sc2.assignment_id,
            RANK() OVER (
                PARTITION BY sc2.student_id, a2.category_id
                ORDER BY COALESCE(sc2.score, 0) ASC
            ) AS rnk
        FROM Score sc2
        JOIN Assignment a2 ON sc2.assignment_id = a2.assignment_id
    ) AS rk ON rk.student_id = e.student_id
           AND rk.assignment_id = a.assignment_id
    WHERE e.course_id = 1
    GROUP BY e.student_id, ct.category_id, ct.weight
) AS cat_scores
JOIN Student s ON cat_scores.student_id = s.student_id
GROUP BY s.student_id, s.first_name, s.last_name
ORDER BY final_grade_drop_lowest_pct DESC;
