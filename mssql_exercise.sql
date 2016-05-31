
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

 select * from testscores;

 -- Let's rank schools by the percentage of students that passed in 4th grade:

 Select *, (p3+p4) as passing from testscores
 where grade=4 and year=2015 and category='All Students'
 order by (p3+p4) desc;

 -- note that the percentages provided are truncated; let's calculate the percentage ourselves to get it more precise:
  Select *, (l3+l4)/tested as passing from testscores
 where grade=4 and year=2015 and category='All Students'
 order by (l3+l4)/tested desc;

 -- We'd like to see if there's a broader pattern. So let's rank the results by geographic district. As mentioned, the geographic district is not provided in the data, except as
 -- the first two characters of the school_id. Thankfully, in SQL we can use a string function to incorporate that into our group by query:

 select left(school_id,2) as district, sum(l3+l4) as passing, sum(tested) as tested, sum(l3+l4)/sum(tested) as passing_rate from testscores
  where grade=4 and year=2015 and category='All Students'
  group by  left(school_id,2)
  order by 4 desc;

  -- now let's use a different string function to group by borough. There are five boroughs in New York City, and each is represented in a single letter, the third character in our
  -- school_id field. M= Manhattan, Q=Queens, K=Brooklyn, X=The Bronx, R=Staten Island:

   select substring(school_id,3,1) as borough, sum(l3+l4) as passing, sum(tested) as tested, sum(l3+l4)/sum(tested) as passing_rate from testscores
  where grade=4 and year=2015 and category='All Students'
  group by  substring(school_id,3,1)
  order by 4 desc;

  -- The U.S. education system has struggled with racial disparity for years. Let's see how the performance in each borough compares by the race of students. If you remember,
  -- this data is organized in a way that the race category is a row in the data, not a column, so you can't put the performance by race side-by-side with a simple query.
  -- However, we will use the the powerful 'iif' function to solve this problem.

   select substring(school_id,3,1) as borough, 
   sum(iif(category='White',l3+l4,0)) as white_passing, sum(iif(category='White',tested,0)) as white_tested,  sum(iif(category='White',l3+l4,0))/sum(iif(category='White',tested,0)) as white_rate,
   sum(iif(category='Black',l3+l4,0)) as black_passing, sum(iif(category='Black',tested,0)) as black_tested,  sum(iif(category='Black',l3+l4,0))/sum(iif(category='Black',tested,0)) as black_rate,
   sum(iif(category='Hispanic',l3+l4,0)) as Hispanic_passing, sum(iif(category='Hispanic',tested,0)) as Hispanic_tested,  sum(iif(category='Hispanic',l3+l4,0))/sum(iif(category='Hispanic',tested,0)) as Hispanic_rate,
   sum(iif(category='Asian',l3+l4,0)) as Asian_passing, sum(iif(category='Asian',tested,0)) as Asian_tested,  sum(iif(category='Asian',l3+l4,0))/sum(iif(category='Asian',tested,0)) as Asian_rate,
  sum(iif(category='White',l3+l4,0))/sum(iif(category='White',tested,0))-sum(iif(category='Black',l3+l4,0))/sum(iif(category='Black',tested,0)) as white_black_gap
    from testscores
  where grade=4 and year=2015 
  group by  substring(school_id,3,1)
  order by 4 desc;

  -- the passing rate is just one metric available to us. We also have the average score for students in every school.  We'd like to calculate the average for the entire borough though, for
  -- every test, and every year. For this, we'll need to do a weighted average.

  Select substring(school_id,3,1) as borough, year, grade, sum(mean_score*tested) as total_points, 
  sum(tested) as tested, sum(mean_score*tested)/sum(tested) as weighted_average
  from testscores
  where category='All Students'
  group by substring(school_id,3,1), year, grade
  order by  substring(school_id,3,1) , grade, year

  -- One thing we'd like to do with the average score is check to see how well each school did in relation to the average school. We could measure this by compariing each school's average score
  -- to the citywide average score, but then we'd run into the problem of scale. Is a five point difference a little or a lot? This is where a subquery, and some SQL mathematical functions come in handy -- they will
  -- allow us to convert the scores into a common scale.

  Select a.year, school_id, tested, mean_score, city_average, the_std, (mean_score-city_average)/the_std as z_score from
  (Select year, school_id, tested, mean_score from testscores where grade=4 and category='all students') a
  inner join
  (select year, avg(mean_score) as city_average, stdev(mean_score) as the_std from testscores where  grade=4  and category='all students' group by year) b
  on a.year=b.year
  order by school_id, year

  -- Let's take this a step further and do this by race. In this case, we will be comparing the students of each race and each school the citywide average score for students of that race.

    Select a.year, a.category,school_id, tested, mean_score, city_average, the_std, (mean_score-city_average)/the_std as z_score from
  (Select year, school_id, category,tested, mean_score from testscores where grade=4 and mean_score>0) a
  inner join
  (select year,category, avg(mean_score) as city_average, stdev(mean_score) as the_std from testscores where  grade=4  group by year,category) b
  on a.year=b.year and a.category=b.category
  order by school_id,category, year

  -- the cool thing about z-scores is that in addition to being a 'mathematically correct' way of measuring differences, they can be converted back into a more understandable scale.
  -- explaining how this works is beyond the scope of this class, but essentially, researchers and journalists have used z-scores to create their own scales. Let's say we've decided 
  -- we want to grade the schools on a five point scale based on the z-scores, with 1 being "well under average", 2 being "under average", 3 being "about average", 4 being "above average", and 5 being
  -- "well above average". We can do this using a Case...When statement

    Select a.year, a.category,school_id, tested, mean_score, city_average, the_std, (mean_score-city_average)/the_std as z_score,
	 CASE 
         WHEN (mean_score-city_average)/the_std  >=1   THEN 'Well Above Average'
         WHEN (mean_score-city_average)/the_std  >=.25 and (mean_score-city_average)/the_std < 1 THEN 'Above Average'
         WHEN (mean_score-city_average)/the_std  >=-.25 and (mean_score-city_average)/the_std <.25 THEN 'Average'
         WHEN (mean_score-city_average)/the_std  >= -1 and (mean_score-city_average)/the_std < -.25  THEN 'Below Average'
         ELSE 'Well Below Average'
      END as performance
	
	from
   (Select year, school_id, category,tested, mean_score from testscores where grade=4 and mean_score>0) a
   inner join
  (select year,category, avg(mean_score) as city_average, stdev(mean_score) as the_std from testscores where  grade=4  group by year,category) b
  on a.year=b.year and a.category=b.category
  order by school_id,category, year

  -- So this is cool, but now we're getting back to the point where it's hard to see any patterns. Wouldn't it be great if we could store the results of this last query as 
  -- another table, and then write more queries against it? In SQL, there are two options -- creating a new table from this query, or storing the query results
  -- as a 'View' -- a view is a virtual table that gets stored in memory and is very convenient for these purposes.


  create view zscores as
      Select a.year, a.category,school_id, tested, mean_score, city_average, the_std, (mean_score-city_average)/the_std as z_score,
	 CASE 
         WHEN (mean_score-city_average)/the_std  >=1   THEN 'Well Above Average'
         WHEN (mean_score-city_average)/the_std  >=.25 and (mean_score-city_average)/the_std < 1 THEN 'Above Average'
         WHEN (mean_score-city_average)/the_std  >=-.25 and (mean_score-city_average)/the_std <.25 THEN 'Average'
         WHEN (mean_score-city_average)/the_std  >= -1 and (mean_score-city_average)/the_std < -.25  THEN 'Below Average'
         ELSE 'Well Below Average'
      END as performance
	
	from
   (Select year, school_id, category,tested, mean_score from testscores where grade=4 and mean_score>0) a
   inner join
  (select year, avg(mean_score) as city_average, stdev(mean_score) as the_std from testscores where  grade=4 and mean_score>0  group by year) b
  on a.year=b.year ;

  Select * from zscores order by school_id, year, category;


-- Finally, let's write a query that compares relative performance of black and white students in 4th grade in 2015


select a.school_id, black_tested,black_mean_score, black_z_score, white_tested, white_z_score,white_mean_score, white_z_score-black_z_score as gap from
(select school_id, tested as black_tested, mean_score as black_mean_score, z_score as black_z_score, performance as black_performance from zscores where year=2015 and category='black') a
left join
(select school_id, tested as white_tested, mean_score as white_mean_score, z_score as white_z_score, performance as white_performance from zscores where year=2015 and category='white') b
  on a.school_id=b.school_id
  order by gap desc


  -- You'll notice in 106 out of the 127 schools for which there is enough data for black and white students, white students have higher test scores. This arms you with specific data to ask
  -- questions about the racial disparity in specific locations. But one broader policy question -- notice all of the schools that have black students but no white students? A question one
  -- might ask -- how do black students perform in these segregated schools vs black students that attend integrated schools? Again, we can use our a subquery with string functions to do the calculation:


  select sum(iif(white_tested is null, black_tested, 0)) as black_students_no_whites, 
  sum(iif(white_tested is null, black_tested*black_mean_score, 0)) as black_students_no_whites_scores, 
   sum(iif(white_tested is null, black_tested*black_mean_score, 0))/sum(iif(white_tested is null, black_tested, 0)) as black_average_no_whites,
  sum(iif(white_tested is not null, black_tested, 0)) as black_students_with_whites, 
  sum(iif(white_tested is not null, black_tested*black_mean_score, 0)) as black_students_with_whites_scores,
  sum(iif(white_tested is not null, black_tested*black_mean_score, 0))/sum(iif(white_tested is not null, black_tested, 0)) as black_average_with_whites
  from
(select school_id, tested as black_tested, mean_score as black_mean_score, z_score as black_z_score, performance as black_performance from zscores where year=2015 and category='black') a
left join
(select school_id, tested as white_tested, mean_score as white_mean_score, z_score as white_z_score, performance as white_performance from zscores where year=2015 and category='white') b
  on a.school_id=b.school_id
