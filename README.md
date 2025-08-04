# General Question

a. What is the earliest date you can join?

- I can join starting September 1st.

b. Please mention your years of experience with Android programming.

- I have 1 year of job experience in Android development and have been practicing Android app development for 4 years now.

3. Write SQL query for SQL Server:

   i. Duplicate "Emp_ID" from the table "tbl_Emp".

   ```sql
   SELECT Emp_ID, COUNT(*) as DuplicateCount
   FROM tbl_Emp
   GROUP BY Emp_ID
   HAVING COUNT(*) > 1;
   ```

   ii. Last 5 entered data (entry_date).

   ```sql
   SELECT TOP 5 *
   FROM tbl_Emp
   ORDER BY entry_date DESC;
   ```

# prf_task

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
