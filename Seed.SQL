-- CSCI 432 Database Systems
-- Grade Book Database - Sample Data
-- Group Project
 
USE gradebook;
 
-- Courses
INSERT INTO Course (department, course_num, course_name, semester, year) VALUES
    ('CS',   '101', 'Introduction to Computer Science', 'Fall',   2024),
    ('CS',   '301', 'Database Systems',                 'Fall',   2024),
    ('MATH', '201', 'Linear Algebra',                   'Spring', 2024);
 
-- Students
-- Note: Bob Quincy and David Qiang have Q in their last name (used in task 10)
INSERT INTO Student (first_name, last_name, email) VALUES
    ('Alice', 'Smith',    'asmith@uni.edu'),
    ('Bob',   'Quincy',   'bquincy@uni.edu'),
    ('Carol', 'Johnson',  'cjohnson@uni.edu'),
    ('David', 'Qiang',    'dqiang@uni.edu'),
    ('Eve',   'Martinez', 'emartinez@uni.edu'),
    ('Frank', 'Brown',    'fbrown@uni.edu'),
    ('Grace', 'Lee',      'glee@uni.edu'),
    ('Hank',  'Nguyen',   'hnguyen@uni.edu');
 
-- Enrollments
-- CS 101: Alice, Bob, Carol, David, Eve
INSERT INTO Enrollment (course_id, student_id) VALUES
    (1,1),(1,2),(1,3),(1,4),(1,5);
 
-- CS 301: Alice, Carol, Frank, Grace, Hank
INSERT INTO Enrollment (course_id, student_id) VALUES
    (2,1),(2,3),(2,6),(2,7),(2,8);
 
-- MATH 201: Bob, David, Eve, Frank
INSERT INTO Enrollment (course_id, student_id) VALUES
    (3,2),(3,4),(3,5),(3,6);
 
-- Categories
-- CS 101: Participation 10%, Homework 20%, Tests 50%, Projects 20%
INSERT INTO Category (course_id, category_name, weight) VALUES
    (1, 'Participation', 10),
    (1, 'Homework',      20),
    (1, 'Tests',         50),
    (1, 'Projects',      20);
 
-- CS 301: Participation 15%, Homework 25%, Tests 40%, Projects 20%
INSERT INTO Category (course_id, category_name, weight) VALUES
    (2, 'Participation', 15),
    (2, 'Homework',      25),
    (2, 'Tests',         40),
    (2, 'Projects',      20);
 
-- MATH 201: Participation 10%, Homework 30%, Tests 60%
INSERT INTO Category (course_id, category_name, weight) VALUES
    (3, 'Participation', 10),
    (3, 'Homework',      30),
    (3, 'Tests',         60);
 
-- Assignments
-- CS 101
INSERT INTO Assignment (category_id, assignment_name, max_score) VALUES
    (1, 'Participation Week1-7', 100);
INSERT INTO Assignment (category_id, assignment_name, max_score) VALUES
    (2, 'HW1', 100), (2, 'HW2', 100), (2, 'HW3', 100), (2, 'HW4', 100), (2, 'HW5', 100);
INSERT INTO Assignment (category_id, assignment_name, max_score) VALUES
    (3, 'Midterm', 100), (3, 'Final', 100);
INSERT INTO Assignment (category_id, assignment_name, max_score) VALUES
    (4, 'Project1', 100), (4, 'Project2', 100);
 
-- CS 301
INSERT INTO Assignment (category_id, assignment_name, max_score) VALUES
    (5, 'Participation Score', 100);
INSERT INTO Assignment (category_id, assignment_name, max_score) VALUES
    (6, 'HW1', 100), (6, 'HW2', 100), (6, 'HW3', 100);
INSERT INTO Assignment (category_id, assignment_name, max_score) VALUES
    (7, 'Midterm', 100), (7, 'Final', 100);
INSERT INTO Assignment (category_id, assignment_name, max_score) VALUES
    (8, 'DB Design Project', 100);
 
-- MATH 201
INSERT INTO Assignment (category_id, assignment_name, max_score) VALUES
    (9, 'Participation Score', 100);
INSERT INTO Assignment (category_id, assignment_name, max_score) VALUES
    (10, 'HW1', 100), (10, 'HW2', 100), (10, 'HW3', 100), (10, 'HW4', 100);
INSERT INTO Assignment (category_id, assignment_name, max_score) VALUES
    (11, 'Quiz1', 100), (11, 'Quiz2', 100), (11, 'Midterm', 100), (11, 'Final', 100);
 
-- Scores
-- CS 101 (assignment IDs 1-10, student IDs 1-5)
INSERT INTO Score (assignment_id, student_id, score) VALUES
    (1,1,90),(1,2,85),(1,3,95),(1,4,80),(1,5,88);
INSERT INTO Score (assignment_id, student_id, score) VALUES
    (2,1,92),(2,2,78),(2,3,88),(2,4,95),(2,5,70),
    (3,1,88),(3,2,82),(3,3,90),(3,4,91),(3,5,75),
    (4,1,95),(4,2,70),(4,3,85),(4,4,88),(4,5,80),
    (5,1,90),(5,2,74),(5,3,92),(5,4,87),(5,5,78),
    (6,1,85),(6,2,68),(6,3,91),(6,4,90),(6,5,72);
INSERT INTO Score (assignment_id, student_id, score) VALUES
    (7,1,88),(7,2,72),(7,3,91),(7,4,85),(7,5,76),
    (8,1,91),(8,2,75),(8,3,93),(8,4,88),(8,5,80);
INSERT INTO Score (assignment_id, student_id, score) VALUES
    (9,1,94),(9,2,80),(9,3,89),(9,4,92),(9,5,83),
    (10,1,90),(10,2,77),(10,3,95),(10,4,88),(10,5,85);
 
-- CS 301 (assignment IDs 11-17, student IDs 1,3,6,7,8)
INSERT INTO Score (assignment_id, student_id, score) VALUES
    (11,1,92),(11,3,88),(11,6,80),(11,7,95),(11,8,85);
INSERT INTO Score (assignment_id, student_id, score) VALUES
    (12,1,88),(12,3,90),(12,6,75),(12,7,92),(12,8,78),
    (13,1,91),(13,3,85),(13,6,70),(13,7,88),(13,8,82),
    (14,1,87),(14,3,92),(14,6,68),(14,7,95),(14,8,80);
INSERT INTO Score (assignment_id, student_id, score) VALUES
    (15,1,85),(15,3,90),(15,6,72),(15,7,91),(15,8,78),
    (16,1,90),(16,3,88),(16,6,74),(16,7,94),(16,8,82);
INSERT INTO Score (assignment_id, student_id, score) VALUES
    (17,1,93),(17,3,87),(17,6,78),(17,7,96),(17,8,84);
 
-- MATH 201 (assignment IDs 18-26, student IDs 2,4,5,6)
INSERT INTO Score (assignment_id, student_id, score) VALUES
    (18,2,82),(18,4,88),(18,5,90),(18,6,75);
INSERT INTO Score (assignment_id, student_id, score) VALUES
    (19,2,78),(19,4,92),(19,5,85),(19,6,70),
    (20,2,80),(20,4,88),(20,5,90),(20,6,72),
    (21,2,75),(21,4,91),(21,5,87),(21,6,68),
    (22,2,82),(22,4,94),(22,5,89),(22,6,74);
INSERT INTO Score (assignment_id, student_id, score) VALUES
    (23,2,76),(23,4,88),(23,5,82),(23,6,70),
    (24,2,80),(24,4,90),(24,5,85),(24,6,72),
    (25,2,74),(25,4,87),(25,5,88),(25,6,68),
    (26,2,78),(26,4,92),(26,5,90),(26,6,74);
