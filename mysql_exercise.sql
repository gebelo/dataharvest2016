
NEW YORK CITY STUDENT PERFORMANCE

-- In the U.S., the education system is obsessed with test scores. Exams that were originally designed to help teachers discover what students still needed to learn
--  are now being deployed in a "high stakes" environment, where a school's very existence can sometimes hinge on how well students perform on standardized tests.

-- In this exercise, we will work with actual data from the New York City school system. We bring to the data a set of questions we'd like to answer. Then we'll
-- peruse the data to see what type of data transformations we'll need to make to be able to write good queries. And finally, we'll use a series of advanced query
-- techniques to produce results that answer our initial questions.

-- To begin, please import the csv file testscores into a database on your server.  This file is comma and quote delimited. Once you tell SQL Server Express that the file
-- has fields defined by quotes, click on the "reset fields" button to let it know the header fields are also surrounded by quotes and separated by columns.

-- You should end up with 19,787 rows, and the following columns:

-- school_id: This is unique code for each school, and like many administrative IDs, it is comprised of other codes. The first two digits tell us which of 32 school districts
-- within New York City the school belongs to; The third character tells us which of the five New York City boroughs the school is located in; And the last three digits are a unique school 
-- ID for that borough. So, for example, school_id 01M015 means: District 1, Manhattan School #15.

-- grade: For this exercise, I've extracted grade 3 and grade 4 mathematics test results.

-- year: There is data for the years 2013,2014 and 2015 included in this data.

-- category: There is data for "All Students" in the school, plus breakdowns of students by race and ethnicity. Usually in the U.S., these breakdowns will note if the student is Asian, Black, Hispanic, White or 
-- Native American.

-- tested: This is the number of students who took the test

-- mean_score: This is the average score on the test -- note that many U.S. tests are scored on unique and hard-to-understand scale. In this case, students can score between 137 and 405 (somebody will have
-- to explain this to me one day). However, later in this exercise, we will make more sense of this using some math tricks.

-- l1 - l4 -- Depending on how each individual student scores, they are assigned to level 1 through 4, with 4 being the best and 1 being the worst. A student needs to score in level 3 or 4 to be considered "proficient".

-- p1 - p4 -- this is the percentage of students at each level.

 -- To start with, let's review some basic queries. A simple query to peruse our data:

 SELECT * FROM testscores;

 -- Let's rank schools by the percentage of students that passed in 4th grade:

 SELECT *, (p3+p4) AS passing FROM testscores
 WHERE grade=4 AND YEAR=2015 AND category='All Students'
 ORDER BY (p3+p4) DESC;

 -- note that the percentages provided are truncated; let's calculate the percentage ourselves to get it more precise:
  SELECT *, (l3+l4)/tested AS passing FROM testscores
 WHERE grade=4 AND YEAR=2015 AND category='All Students'
 ORDER BY (l3+l4)/tested DESC;

 -- We'd like to see if there's a broader pattern. So let's rank the results by geographic district. As mentioned, the geographic district is not provided in the data, except as
 -- the first two characters of the school_id. Thankfully, in SQL we can use a string function to incorporate that into our group by query:

 SELECT LEFT(school_id,2) AS district, SUM(l3+l4) AS passing, SUM(tested) AS tested, SUM(l3+l4)/SUM(tested) AS passing_rate FROM testscores
  WHERE grade=4 AND YEAR=2015 AND category='All Students'
  GROUP BY  LEFT(school_id,2)
  ORDER BY 4 DESC;

  -- now let's use a different string function to group by borough. There are five boroughs in New York City, and each is represented in a single letter, the third character in our
  -- school_id field. M= Manhattan, Q=Queens, K=Brooklyn, X=The Bronx, R=Staten Island:

   SELECT MID(school_id,3,1) AS borough, SUM(l3+l4) AS passing, SUM(tested) AS tested, SUM(l3+l4)/SUM(tested) AS passing_rate FROM testscores
  WHERE grade=4 AND YEAR=2015 AND category='All Students'
  GROUP BY  MID(school_id,3,1)
  ORDER BY 4 DESC;

  -- The U.S. education system has struggled with racial disparity for years. Let's see how the performance in each borough compares by the race of students. If you remember,
  -- this data is organized in a way that the race category is a row in the data, not a column, so you can't put the performance by race side-by-side with a simple query.
  -- However, we will use the the powerful 'if' function to solve this problem.

   SELECT MID(school_id,3,1) AS borough, 
   SUM(IF(category='White',l3+l4,0)) AS white_passing, SUM(IF(category='White',tested,0)) AS white_tested,  SUM(IF(category='White',l3+l4,0))/SUM(IF(category='White',tested,0)) AS white_rate,
   SUM(IF(category='Black',l3+l4,0)) AS black_passing, SUM(IF(category='Black',tested,0)) AS black_tested,  SUM(IF(category='Black',l3+l4,0))/SUM(IF(category='Black',tested,0)) AS black_rate,
   SUM(IF(category='Hispanic',l3+l4,0)) AS Hispanic_passing, SUM(IF(category='Hispanic',tested,0)) AS Hispanic_tested,  SUM(IF(category='Hispanic',l3+l4,0))/SUM(IF(category='Hispanic',tested,0)) AS Hispanic_rate,
   SUM(IF(category='Asian',l3+l4,0)) AS Asian_passing, SUM(IF(category='Asian',tested,0)) AS Asian_tested,  SUM(IF(category='Asian',l3+l4,0))/SUM(IF(category='Asian',tested,0)) AS Asian_rate,
  SUM(IF(category='White',l3+l4,0))/SUM(IF(category='White',tested,0))-SUM(IF(category='Black',l3+l4,0))/SUM(IF(category='Black',tested,0)) AS white_black_gap
    FROM testscores
  WHERE grade=4 AND YEAR=2015 
  GROUP BY  MID(school_id,3,1)
  ORDER BY 4 DESC;

  -- the passing rate is just one metric available to us. We also have the average score for students in every school.  We'd like to calculate the average for the entire borough though, for
  -- every test, and every year. For this, we'll need to do a weighted average.

  SELECT MID(school_id,3,1) AS borough, YEAR, grade, SUM(mean_score*tested) AS total_points, 
  SUM(tested) AS tested, SUM(mean_score*tested)/SUM(tested) AS weighted_average
  FROM testscores
  WHERE category='All Students'
  GROUP BY MID(school_id,3,1), YEAR, grade
  ORDER BY  MID(school_id,3,1) , grade, YEAR

  -- One thing we'd like to do with the average score is check to see how well each school did in relation to the average school. We could measure this by comparing each school's average score
  -- to the citywide average score, but then we'd run into the problem of scale. Is a five point difference a little or a lot? 
  -- This is where a subquery, and some SQL mathematical functions come in handy -- they will
  -- allow us to convert the scores into a common scale.

  SELECT a.year, school_id, tested, mean_score, city_average, the_std, (mean_score-city_average)/the_std AS z_score FROM
  (SELECT YEAR, school_id, tested, mean_score FROM testscores WHERE grade=4 AND category='all students') a
  INNER JOIN
  (SELECT YEAR, AVG(mean_score) AS city_average, STD(mean_score) AS the_std FROM testscores WHERE  grade=4  AND category='all students' GROUP BY YEAR) b
  ON a.year=b.year
  ORDER BY school_id, YEAR

  -- Let's take this a step further and do this by race. In this case, we will be comparing the students of each race and each school the citywide average score for students of that race.

    SELECT a.year, a.category,school_id, tested, mean_score, city_average, the_std, (mean_score-city_average)/the_std AS z_score FROM
  (SELECT YEAR, school_id, category,tested, mean_score FROM testscores WHERE grade=4 AND mean_score>0) a
  INNER JOIN
  (SELECT YEAR,category, AVG(mean_score) AS city_average, STD(mean_score) AS the_std FROM testscores WHERE  grade=4  GROUP BY YEAR,category) b
  ON a.year=b.year AND a.category=b.category
  ORDER BY school_id,category, YEAR

  -- the cool thing about z-scores is that in addition to being a 'mathematically correct' way of measuring differences, they can be converted back into a more understandable scale.
  -- explaining how this works is beyond the scope of this class, but essentially, researchers and journalists have used z-scores to create their own scales. Let's say we've decided 
  -- we want to grade the schools on a five point scale based on the z-scores, with 1 being "well under average", 2 being "under average", 3 being "about average", 4 being "above average", and 5 being
  -- "well above average". We can do this using a Case...When statement

    SELECT a.year, a.category,school_id, tested, mean_score, city_average, the_std, (mean_score-city_average)/the_std AS z_score,
	 CASE 
         WHEN (mean_score-city_average)/the_std  >=1   THEN 'Well Above Average'
         WHEN (mean_score-city_average)/the_std  >=.25 AND (mean_score-city_average)/the_std < 1 THEN 'Above Average'
         WHEN (mean_score-city_average)/the_std  >=-.25 AND (mean_score-city_average)/the_std <.25 THEN 'Average'
         WHEN (mean_score-city_average)/the_std  >= -1 AND (mean_score-city_average)/the_std < -.25  THEN 'Below Average'
         ELSE 'Well Below Average'
      END AS performance
	
	FROM
   (SELECT YEAR, school_id, category,tested, mean_score FROM testscores WHERE grade=4 AND mean_score>0) a
   INNER JOIN
  (SELECT YEAR,category, AVG(mean_score) AS city_average, STD(mean_score) AS the_std FROM testscores WHERE  grade=4  GROUP BY YEAR,category) b
  ON a.year=b.year AND a.category=b.category
  ORDER BY school_id,category, YEAR

  -- So this is cool, but now we're getting back to the point where it's hard to see any patterns. Wouldn't it be great if we could store the results of this last query as 
  -- another table, and then write more queries against it? In SQL, there are two options -- creating a new table from this query, or storing the query results
  -- as a 'View' -- a view is a virtual table that gets stored in memory and is very convenient for these purposes.


  CREATE TABLE zscores AS
      SELECT a.year, a.category,school_id, tested, mean_score, city_average, the_std, (mean_score-city_average)/the_std AS z_score,
	 CASE 
         WHEN (mean_score-city_average)/the_std  >=1   THEN 'Well Above Average'
         WHEN (mean_score-city_average)/the_std  >=.25 AND (mean_score-city_average)/the_std < 1 THEN 'Above Average'
         WHEN (mean_score-city_average)/the_std  >=-.25 AND (mean_score-city_average)/the_std <.25 THEN 'Average'
         WHEN (mean_score-city_average)/the_std  >= -1 AND (mean_score-city_average)/the_std < -.25  THEN 'Below Average'
         ELSE 'Well Below Average'
      END AS performance
	FROM
   (SELECT YEAR, school_id, category,tested, mean_score FROM testscores WHERE grade=4 AND mean_score>0) a
   INNER JOIN
  (SELECT YEAR, AVG(mean_score) AS city_average, STD(mean_score) AS the_std FROM testscores WHERE  grade=4 AND mean_score>0  GROUP BY YEAR) b
  ON a.year=b.year ;

  SELECT * FROM zscores ORDER BY school_id, YEAR, category;


-- Finally, let's write a query that compares relative performance of black and white students in 4th grade in 2015


SELECT a.school_id, black_tested,black_mean_score, black_z_score, white_tested, white_z_score,white_mean_score, white_z_score-black_z_score AS gap FROM
(SELECT school_id, tested AS black_tested, mean_score AS black_mean_score, z_score AS black_z_score, performance AS black_performance FROM zscores WHERE YEAR=2015 AND category='black') a
LEFT JOIN
(SELECT school_id, tested AS white_tested, mean_score AS white_mean_score, z_score AS white_z_score, performance AS white_performance FROM zscores WHERE YEAR=2015 AND category='white') b
  ON a.school_id=b.school_id
  ORDER BY gap DESC


  -- You'll notice in 106 out of the 127 schools for which there is enough data for black and white students, white students have higher test scores. This arms you with specific data to ask
  -- questions about the racial disparity in specific locations. But one broader policy question -- notice all of the schools that have black students but no white students? A question one
  -- might ask -- how do black students perform in these segregated schools vs black students that attend integrated schools? Again, we can use our a subquery with string functions to do the calculation:


  SELECT SUM(IF(white_tested IS NULL, black_tested, 0)) AS black_students_no_whites, 
  SUM(IF(white_tested IS NULL, black_tested*black_mean_score, 0)) AS black_students_no_whites_scores, 
   SUM(IF(white_tested IS NULL, black_tested*black_mean_score, 0))/SUM(IF(white_tested IS NULL, black_tested, 0)) AS black_average_no_whites,
  SUM(IF(white_tested IS NOT NULL, black_tested, 0)) AS black_students_with_whites, 
  SUM(IF(white_tested IS NOT NULL, black_tested*black_mean_score, 0)) AS black_students_with_whites_scores,
  SUM(IF(white_tested IS NOT NULL, black_tested*black_mean_score, 0))/SUM(IF(white_tested IS NOT NULL, black_tested, 0)) AS black_average_with_whites
  FROM
(SELECT school_id, tested AS black_tested, mean_score AS black_mean_score, z_score AS black_z_score, performance AS black_performance FROM zscores WHERE YEAR=2015 AND category='black') a
LEFT JOIN
(SELECT school_id, tested AS white_tested, mean_score AS white_mean_score, z_score AS white_z_score, performance AS white_performance FROM zscores WHERE YEAR=2015 AND category='white') b
  ON a.school_id=b.school_id
