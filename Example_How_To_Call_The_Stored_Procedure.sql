USE HQ;
GO

-- This script is an example how to call the stored procedure dbo.p_Get_Outliers
-- that detects outliers in a specific column of a table
-- It took about 2 minutes to execute this script on my machine

DECLARE	@OutlierLowerLimit  AS INT;
DECLARE	@OutlierUpperLimit  AS INT;
DECLARE @OutlierCount       AS INT;
DECLARE @OutlierMin	        AS INT;
DECLARE @OutlierMax			    AS BIGINT;
DECLARE @RerturnCode        AS INT;

SET NOCOUNT ON;

-- Find outliers on column price_usd of valid_offers table
EXEC @RerturnCode = dbo.p_Get_Outliers
                            @prmSchemaName					= 'bi_data',
                            @prmTableName						= 'valid_offers',
                            @prmColumnName					= 'price_usd',
                            @prmDisplayTopNOutliers	= 10,
                            @prmOutlierLowerLimit		= @OutlierLowerLimit  OUTPUT,
                            @prmOutlierUpperLimit		= @OutlierUpperLimit  OUTPUT,
                            @prmOutlierCount				= @OutlierCount       OUTPUT,
                            @prmOutlierMin  				= @OutlierMin         OUTPUT,
		                        @prmOutlierMax  				= @OutlierMax         OUTPUT;																							

-- Display results
SELECT
	@RerturnCode        AS [Error Code]
	,@OutlierLowerLimit AS [Outlier Lower Linit]
	,@OutlierUpperLimit AS [Outlier Upper Linit]
	,@OutlierCount      AS [Outlier Total Count]
	,@OutlierMin	      AS [Outlier Min Value]
	,@OutlierMax	      AS [Outlier Max Value];