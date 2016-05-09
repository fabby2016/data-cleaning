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

Please have a look of a sample of outliers (returned by the sp) in the outliers.txt file.
