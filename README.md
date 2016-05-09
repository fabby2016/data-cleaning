Please note that:
------------------

- The code is for Microsoft SQL Server 2014 but it supports MS SQL 2008 R2 and 2012

- Depending on which IDE you are using, the code format and the indentation may appear funny. 
  I wrote the code by using Microsoft SQL Server 2014 Management Studio (SSMS).


The outlier detection engine:
-----------------------------
To give you a high level picture of my first thoughts, I will probably design the system at the
database level as follows:

- Having a main generic stored procedure for outliers detection. As an example, the provided
  stored procedure in my answer can detect outliers for a given column (assuming it contains
  only numeric values) and can return the list of them.

  Just pass the name of the table and column that needs to be inspected

- Having a few configuration tables that will store for example the name of the tables/columns
  to inspect, the process history of each analysis with the time when it was ran,...

- Having another stored procedure or so that scans (on a specific schedule) the table containing the
  result of each analysis and send email notification to the appropriate staff for investigation

- I will use a scheduler (for example SQL Server Agent for SQL Server database) or other tools
  (depending on the database) to schedule a job to execution the process

- I will let the cleaning process to be performed manually. Indeed some outliers might be valid and
  only a manual inspection with the right business knowledge will tell whether or not to keep it.


I run a the stored procedure on the price_usd column which contains lots of outliers with huge amount:
Here a sample of offer_id / price_usd returned by the stored procedure


offer_id	hotel_id	price_usd	checkin		checkout
--------------------------------------------------------------------------
130610334	138		1000000	   	2015-11-23	2015-11-24
130610349	410		1000000	   	2015-11-13	2015-11-14
130610356	138		1000000	    	2015-12-26	2015-12-27
130610375	138		1000000	    	2015-12-25	2015-12-26
130611154	8243		1000000	    	2015-11-21	2015-11-22
130611358	12278		1000000	    	2015-11-12	2015-11-13
130611365	12278		1000000	    	2015-11-14	2015-11-15
130611370	12278		1000000	    	2015-11-13	2015-11-14
132030534	4411		1054567.75	2015-11-15	2015-11-20
132044507	4411		1197888.125	2015-11-15	2015-11-20
132092249	4411		1198131.625	2015-11-16	2015-11-21
132092254	4411		843654.25	2015-11-16	2015-11-20
132547703	4411		1197888.125	2015-11-15	2015-11-20
132548528	4411		843654.25	2015-11-16	2015-11-20

135455635	8012		22032634	2015-11-19	2015-11-22	
135455715	8012		37710840	2015-11-19	2015-11-24	
135456037	8012		29871738	2015-11-19	2015-11-23	
137013805	8012		37942672	2015-11-20	2015-11-25	
137013812	8012		30116994	2015-11-20	2015-11-24	
137013815	8012		25194988	2015-11-20	2015-11-25	
137013828	8012		27417532	2015-11-20	2015-11-25	
137013837	8012		22291318	2015-11-20	2015-11-23			

Even if the price were stored in cents it would be too much for one or a few nights...
