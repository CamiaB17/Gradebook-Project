# CSCI 432 - Database Systems
# Grade Book Project
# Group members: Camia Bellamy, Erin McCoomer, Leighla-Marie Dantes
#
# Runs all tasks (3-12) against a MySQL gradebook database.
 
import mysql.connector
import getpass

# --- connection settings ---
# change these to match your MySQL login
DB_CONFIG = {
    "host":     "localhost",
    "user":     "root",
    "password": getpass.getpass("Enter MySQL password: "),
    "database": "gradebook"
}
 
def get_conn():
    return mysql.connector.connect(**DB_CONFIG)
 
def run_query(cursor, sql, params=None):
    cursor.execute(sql, params or ())
    return cursor.fetchall()
 
def print_results(rows, headers):
    if not rows:
        print("  (no results)")
        return
    print("  " + " | ".join(headers))
    print("  " + "-+-".join("-" * len(h) for h in headers))
    for row in rows:
        print("  " + " | ".join(str(v) for v in row))
    print()
 
 
# ------------------------------------------------------------------
# TASK 3 - Show table contents
# ------------------------------------------------------------------
def task3(cursor):
    print("\n===== TASK 3: Show Tables =====")
 
    tables = ["Course", "Student", "Enrollment", "Category", "Assignment", "Score"]
    for t in tables:
        print(f"\n-- {t} --")
        cursor.execute(f"SELECT * FROM {t}")
        rows = cursor.fetchall()
        if cursor.description:
            headers = [d[0] for d in cursor.description]
            print_results(rows, headers)
 
 
# ------------------------------------------------------------------
# TASK 4 - Compute average, highest, lowest score for an assignment
# ------------------------------------------------------------------
def task4(cursor, assignment_id):
    print("\n===== TASK 4: Avg / Highest / Lowest Score =====")
 
    sql = """
        SELECT
            a.assignment_name,
            cat.category_name,
            COUNT(sc.score)        AS num_students,
            ROUND(AVG(sc.score),2) AS avg_score,
            MAX(sc.score)          AS highest,
            MIN(sc.score)          AS lowest
        FROM Assignment a
        JOIN Category cat ON a.category_id = cat.category_id
        LEFT JOIN Score sc ON a.assignment_id = sc.assignment_id
        WHERE a.assignment_id = %s
        GROUP BY a.assignment_id, a.assignment_name, cat.category_name
    """
    rows = run_query(cursor, sql, (assignment_id,))
    print_results(rows, ["assignment","category","# students","avg","highest","lowest"])
 
 
# ------------------------------------------------------------------
# TASK 5 - List all students in a given course
# ------------------------------------------------------------------
def task5(cursor, course_id):
    print("\n===== TASK 5: Students in Course =====")
 
    sql = """
        SELECT s.student_id, s.first_name, s.last_name, s.email
        FROM Student s
        JOIN Enrollment e ON s.student_id = e.student_id
        WHERE e.course_id = %s
        ORDER BY s.last_name, s.first_name
    """
    rows = run_query(cursor, sql, (course_id,))
    print_results(rows, ["id", "first_name", "last_name", "email"])
 
 
# ------------------------------------------------------------------
# TASK 6 - List all students and all their scores in a course
# ------------------------------------------------------------------
def task6(cursor, course_id):
    print("\n===== TASK 6: All Students and Scores in Course =====")
 
    sql = """
        SELECT
            s.last_name,
            s.first_name,
            cat.category_name,
            a.assignment_name,
            sc.score,
            a.max_score
        FROM Student s
        JOIN Enrollment e  ON s.student_id    = e.student_id
        JOIN Category cat  ON e.course_id     = cat.course_id
        JOIN Assignment a  ON cat.category_id = a.category_id
        LEFT JOIN Score sc ON sc.student_id   = s.student_id
                          AND sc.assignment_id = a.assignment_id
        WHERE e.course_id = %s
        ORDER BY s.last_name, s.first_name, cat.category_name, a.assignment_name
    """
    rows = run_query(cursor, sql, (course_id,))
    print_results(rows, ["last","first","category","assignment","score","max"])
 
 
# ------------------------------------------------------------------
# TASK 7 - Add an assignment to a course
# ------------------------------------------------------------------
def task7(cursor, conn, category_id, assignment_name, max_score=100):
    print("\n===== TASK 7: Add Assignment =====")

    # insert the assignment
    cursor.execute("""
        INSERT INTO Assignment (category_id, assignment_name, max_score)
        VALUES (%s, %s, %s)
    """, (category_id, assignment_name, max_score))
    new_assignment_id = cursor.lastrowid

    # find the course this category belongs to
    cursor.execute(
        "SELECT course_id FROM Category WHERE category_id = %s", (category_id,)
    )
    course_id = cursor.fetchone()[0]

    # get all students enrolled in that course
    cursor.execute(
        "SELECT student_id FROM Enrollment WHERE course_id = %s", (course_id,)
    )
    students = cursor.fetchall()

    # insert a default score of 0 for each enrolled student
    for (student_id,) in students:
        cursor.execute("""
            INSERT INTO Score (assignment_id, student_id, score)
            VALUES (%s, %s, 0)
        """, (new_assignment_id, student_id))

    conn.commit()
    print(f"  Added '{assignment_name}' to category {category_id} (max: {max_score})")
    print(f"  Inserted default score of 0 for {len(students)} enrolled student(s).")

    cursor.execute(
        "SELECT assignment_id, assignment_name, max_score FROM Assignment WHERE category_id = %s",
        (category_id,)
    )
    rows = cursor.fetchall()
    print_results(rows, ["id", "name", "max_score"])
 
 
# ------------------------------------------------------------------
# TASK 8 - Change the weight of a category for a course
# ------------------------------------------------------------------
def task8(cursor, conn, category_id, new_weight):
    print("\n===== TASK 8: Update Category Weight =====")

    cursor.execute(
        "SELECT category_name, weight FROM Category WHERE category_id = %s",
        (category_id,)
    )
    row = cursor.fetchone()
    print(f"  Before: {row[0]} = {row[1]}%")

    try:
        cursor.execute(
            "UPDATE Category SET weight = %s WHERE category_id = %s",
            (new_weight, category_id)
        )
        conn.commit()
        cursor.execute(
            "SELECT category_name, weight FROM Category WHERE category_id = %s",
            (category_id,)
        )
        row = cursor.fetchone()
        print(f"  After:  {row[0]} = {row[1]}%")
    except mysql.connector.Error as e:
        conn.rollback()
        print(f"  ERROR: {e.msg}")
    print()


# ------------------------------------------------------------------
# TASK 9 - Add 2 points to every student score on an assignment
# ------------------------------------------------------------------
def task9(cursor, conn, assignment_id):
    print("\n===== TASK 9: Add 2 Points to All Students =====")
 
    # get max score so we don't go over
    cursor.execute("SELECT max_score FROM Assignment WHERE assignment_id = %s", (assignment_id,))
    max_score = cursor.fetchone()[0]
 
    cursor.execute(
        "UPDATE Score SET score = LEAST(score + 2, %s) WHERE assignment_id = %s",
        (max_score, assignment_id)
    )
    conn.commit()
    print(f"  Updated {cursor.rowcount} row(s). Scores capped at {max_score}.")
 
    # show updated scores
    sql = """
        SELECT s.last_name, s.first_name, sc.score
        FROM Score sc
        JOIN Student s ON sc.student_id = s.student_id
        WHERE sc.assignment_id = %s
        ORDER BY s.last_name
    """
    rows = run_query(cursor, sql, (assignment_id,))
    print_results(rows, ["last_name", "first_name", "score"])
 
 
# ------------------------------------------------------------------
# TASK 10 - Add 2 points only to students whose last name has 'Q'
# ------------------------------------------------------------------
def task10(cursor, conn, assignment_id):
    print("\n===== TASK 10: Add 2 Points to Students with Q in Last Name =====")
 
    cursor.execute("SELECT max_score FROM Assignment WHERE assignment_id = %s", (assignment_id,))
    max_score = cursor.fetchone()[0]
 
    sql = """
        UPDATE Score
        SET score = LEAST(score + 2, %s)
        WHERE assignment_id = %s
          AND student_id IN (
              SELECT student_id FROM Student
              WHERE last_name LIKE '%Q%' OR last_name LIKE '%q%'
          )
    """
    cursor.execute(sql, (max_score, assignment_id))
    conn.commit()
    print(f"  Updated {cursor.rowcount} row(s).")
 
    # show just the affected students
    sql2 = """
        SELECT s.last_name, s.first_name, sc.score
        FROM Score sc
        JOIN Student s ON sc.student_id = s.student_id
        WHERE sc.assignment_id = %s
          AND (s.last_name LIKE '%Q%' OR s.last_name LIKE '%q%')
        ORDER BY s.last_name
    """
    rows = run_query(cursor, sql2, (assignment_id,))
    print_results(rows, ["last_name", "first_name", "score"])
 
 
# ------------------------------------------------------------------
# TASK 11 - Compute the final grade for a student in a course
#
# Formula: for each category, compute (earned / possible) * weight
# then sum those up across all categories.
# Each assignment in a category contributes equally to that category.
# ------------------------------------------------------------------
def task11(cursor, course_id, student_id):
    print("\n===== TASK 11: Compute Student Grade =====")
 
    # get student and course name for display
    cursor.execute(
        "SELECT first_name, last_name FROM Student WHERE student_id = %s", (student_id,)
    )
    stu = cursor.fetchone()
    cursor.execute("SELECT course_name FROM Course WHERE course_id = %s", (course_id,))
    crs = cursor.fetchone()
    print(f"  Student: {stu[0]} {stu[1]}")
    print(f"  Course:  {crs[0]}\n")
 
    # get all categories for this course
    cursor.execute(
        "SELECT category_id, category_name, weight FROM Category WHERE course_id = %s",
        (course_id,)
    )
    categories = cursor.fetchall()
 
    total_grade = 0.0
    print(f"  {'Category':<20} {'Weight':>6}  {'Score %':>7}  {'Points'}")
    print(f"  {'-'*20} {'------':>6}  {'-------':>7}  {'------'}")
 
    for cat_id, cat_name, weight in categories:
        # get all assignments and scores for this category/student
        cursor.execute("""
            SELECT a.max_score, sc.score
            FROM Assignment a
            LEFT JOIN Score sc ON a.assignment_id = sc.assignment_id
                              AND sc.student_id = %s
            WHERE a.category_id = %s
        """, (student_id, cat_id))
        rows = cursor.fetchall()
 
        earned   = sum(r[1] for r in rows if r[1] is not None)
        possible = sum(r[0] for r in rows if r[1] is not None)
 
        if possible > 0:
            cat_pct = (earned / possible) * 100
        else:
            cat_pct = 0.0
 
        contribution = float(weight) * cat_pct / 100
        total_grade += float(contribution)
        print(f"  {cat_name:<20} {weight:>5}%  {cat_pct:>7.2f}  {contribution:.2f}")
 
    print(f"\n  Final Grade: {total_grade:.2f} / 100")
 
 
# ------------------------------------------------------------------
# TASK 12 - Same as task 11 but drop the lowest score per category
# ------------------------------------------------------------------
def task12(cursor, course_id, student_id):
    print("\n===== TASK 12: Compute Student Grade (Drop Lowest per Category) =====")
 
    cursor.execute(
        "SELECT first_name, last_name FROM Student WHERE student_id = %s", (student_id,)
    )
    stu = cursor.fetchone()
    cursor.execute("SELECT course_name FROM Course WHERE course_id = %s", (course_id,))
    crs = cursor.fetchone()
    print(f"  Student: {stu[0]} {stu[1]}")
    print(f"  Course:  {crs[0]}")
    print(f"  Mode: dropping lowest score in each category (if 2+ assignments)\n")
 
    cursor.execute(
        "SELECT category_id, category_name, weight FROM Category WHERE course_id = %s",
        (course_id,)
    )
    categories = cursor.fetchall()
 
    total_grade = 0.0
    print(f"  {'Category':<20} {'Weight':>6}  {'Score %':>7}  {'Points'}  {'Note'}")
    print(f"  {'-'*20} {'------':>6}  {'-------':>7}  {'------'}  {'----'}")
 
    for cat_id, cat_name, weight in categories:
        cursor.execute("""
            SELECT a.max_score, sc.score
            FROM Assignment a
            LEFT JOIN Score sc ON a.assignment_id = sc.assignment_id
                              AND sc.student_id = %s
            WHERE a.category_id = %s
            ORDER BY sc.score ASC
        """, (student_id, cat_id))
        rows = cursor.fetchall()
 
        # only keep rows where the student actually has a score
        scored = [r for r in rows if r[1] is not None]
 
        note = ""
        # drop the lowest only if there are at least 2 scored assignments
        if len(scored) > 1:
            scored = scored[1:]  # sorted ASC so index 0 is lowest
            note = "dropped lowest"
 
        earned   = sum(r[1] for r in scored)
        possible = sum(r[0] for r in scored)
 
        if possible > 0:
            cat_pct = (earned / possible) * 100
        else:
            cat_pct = 0.0
 
        contribution = float(weight) * cat_pct / 100
        total_grade += float(contribution)
        print(f"  {cat_name:<20} {weight:>5}%  {cat_pct:>7.2f}  {contribution:.2f}    {note}")
 
    print(f"\n  Final Grade: {total_grade:.2f} / 100")
 
 
# ------------------------------------------------------------------
# Main - run all tasks
# ------------------------------------------------------------------
def main():
    conn   = get_conn()
    cursor = conn.cursor()
 
    print("Connected to gradebook database.\n")
 
    # Task 3 - show all tables
    task3(cursor)
 
    # Task 4 - stats for CS101 Midterm (assignment_id = 7)
    task4(cursor, assignment_id=7)
 
    # Task 5 - students in CS101 (course_id = 1)
    task5(cursor, course_id=1)
 
    # Task 6 - all students and scores in CS101
    task6(cursor, course_id=1)
 
    # Task 7 - add a new assignment to CS101 Homework category (category_id = 2)
    task7(cursor, conn, category_id=2, assignment_name="HW7", max_score=100)
 
    # Task 8 - change CS101 Homework weight from 20% to 15%
    task8(cursor, conn, category_id=2, new_weight=15)
 
    # Task 9 - add 2 pts to all students on CS101 Midterm (assignment_id = 7)
    task9(cursor, conn, assignment_id=7)
 
    # Task 10 - add 2 pts to students with Q in last name on CS101 Final (assignment_id = 8)
    task10(cursor, conn, assignment_id=8)
 
    # Task 11 - grade for Alice Smith in CS101 (student_id=1, course_id=1)
    task11(cursor, course_id=1, student_id=1)
 
    # Task 12 - same but drop lowest per category
    task12(cursor, course_id=1, student_id=1)
 
    cursor.close()
    conn.close()
 
 
if __name__ == "__main__":
    main()
