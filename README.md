## Grade Book Database
CSCI 432 - Database Systems | Group Project |
Group members: Camia Bellamy, Erin McCoomer, Leighla-Marie Dantes

## How to run it
Step 1 — Set up the database in MySQL,
Open MySQL Workbench (or the MySQL command line) and run the two SQL files in order: ```
sqlsource schema.sql
source seed.sql ```,
Or from the terminal: ```
mysql -u root -p < schema.sql
mysql -u root -p < seed.sql```

Step 2 — Update the connection settings,
Open gradebook.py and change the DB_CONFIG at the top to match your MySQL login:```
pythonDB_CONFIG = {
    "host":     "localhost",
    "user":     "root",
    "password": "your_password_here",
    "database": "gradebook"
} ```

Step 3 — Run the script ```
python gradebook.py```
This runs all tasks (3 through 12) in order and prints the results.

## Files
`schema.sql` Creates the gradebook database and all 6 tables 
`seed.sql` Inserts sample data (3 courses, 8 students, 26 assignments) 
`gradebook.py` Python script that runs all tasks and prints output 
`README.md` This file

## Sample data included

* 3 courses: CS 101, CS 301, MATH 201
* 8 students including Bob Quincy and David Qiang (last names with Q, used in Task 10)
* CS 101 grading: Participation 10%, Homework 20%, Tests 50%, Projects 20%
* 26 total assignments across all courses


## Notes

* Task 9 and 10 cap scores at max_score using LEAST() so no one goes over 100
* Task 12 only drops the lowest score in a category if there are 2 or more assignments
* We used a separate Enrollment table instead of putting course_id on the Student
table because students can be in multiple courses
