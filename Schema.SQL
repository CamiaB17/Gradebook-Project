-- CSCI 432 Database Systems
-- Grade Book Database - Schema
-- Group Project
 
DROP DATABASE IF EXISTS gradebook;
CREATE DATABASE gradebook;
USE gradebook;
 
-- Stores each course the professor teaches
CREATE TABLE Course (
    course_id   INT          NOT NULL AUTO_INCREMENT,
    department  VARCHAR(100) NOT NULL,
    course_num  VARCHAR(20)  NOT NULL,
    course_name VARCHAR(255) NOT NULL,
    semester    VARCHAR(20)  NOT NULL,
    year        INT          NOT NULL,
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
-- We kept this as its own table so a student can be in multiple courses
-- and a course can have multiple students
CREATE TABLE Enrollment (
    enrollment_id INT NOT NULL AUTO_INCREMENT,
    course_id     INT NOT NULL,
    student_id    INT NOT NULL,
    PRIMARY KEY (enrollment_id),
    UNIQUE (course_id, student_id),
    FOREIGN KEY (course_id)  REFERENCES Course(course_id)  ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES Student(student_id) ON DELETE CASCADE
) ENGINE=InnoDB;
 
-- Grade categories for each course e.g. Homework 20%, Tests 50%
-- Weights should add up to 100 per course
CREATE TABLE Category (
    category_id   INT          NOT NULL AUTO_INCREMENT,
    course_id     INT          NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    weight        DECIMAL(5,2) NOT NULL,
    PRIMARY KEY (category_id),
    UNIQUE (course_id, category_name),
    FOREIGN KEY (course_id) REFERENCES Course(course_id) ON DELETE CASCADE
) ENGINE=InnoDB;

DELIMITER $$

CREATE TRIGGER trg_category_weight_insert
AFTER INSERT ON Category
FOR EACH ROW
BEGIN
    DECLARE total DECIMAL(6,2);
    SELECT SUM(weight) INTO total FROM Category WHERE course_id = NEW.course_id;
    IF total > 100.01 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Category weights exceed 100% for this course';
    END IF;
END$$

CREATE TRIGGER trg_category_weight_update
AFTER UPDATE ON Category
FOR EACH ROW
BEGIN
    DECLARE total DECIMAL(6,2);
    SELECT SUM(weight) INTO total FROM Category WHERE course_id = NEW.course_id;
    IF total > 100.01 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Category weights exceed 100% for this course';
    END IF;
END$$

DELIMITER ;
 
-- Individual assignments that belong to a category
CREATE TABLE Assignment (
    assignment_id   INT          NOT NULL AUTO_INCREMENT,
    category_id     INT          NOT NULL,
    assignment_name VARCHAR(255) NOT NULL,
    max_score       DECIMAL(6,2) NOT NULL DEFAULT 100,
    PRIMARY KEY (assignment_id),
    UNIQUE (category_id, assignment_name),
    FOREIGN KEY (category_id) REFERENCES Category(category_id) ON DELETE CASCADE
) ENGINE=InnoDB;
 
-- One row per student per assignment
CREATE TABLE Score (
    score_id      INT          NOT NULL AUTO_INCREMENT,
    assignment_id INT          NOT NULL,
    student_id    INT          NOT NULL,
    score         DECIMAL(6,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (score_id),
    UNIQUE (assignment_id, student_id),
    FOREIGN KEY (assignment_id) REFERENCES Assignment(assignment_id) ON DELETE CASCADE,
    FOREIGN KEY (student_id)    REFERENCES Student(student_id)       ON DELETE CASCADE
) ENGINE=InnoDB;
