USE HQ;
GO

IF OBJECT_ID ( 'dbo.p_Get_Outliers', 'P' ) IS NOT NULL
DROP PROCEDURE dbo.p_Get_Outliers;
GO

/************************************************************************************
*
* Project:			HQ Assignment
* File Name:		dbo.p_Get_Outliers.sql
*	Object Name:	dbo.p_Get_Outliers
* Object Type:	Stored Procedure
* Author:				Fabrice Trarieux
* Created Date:	2016-05-08
*
* Description:	The purpose of this stored procedure is to detect the outliers
*								contained in a specific column of a table.
*
*								The definition of outlier used is the following:
*								An extreme value is considered to be an outlier if it is at least 
*								1.5 interquartile ranges below the first quartile (Q1), or at least 
*								1.5 interquartile ranges above the third quartile (Q3).
*
*								Please note that the column must contains only numerical values
*
* Inputs:
*				@prmSchemaName					AS SYSNAME		Specify the schema name of the table
*				@prmTableName						AS SYSNAME		Specify the table name to query
*				@prmColumnName					AS SYSNAME		specify the column name to be analysed
*				@prmDisplayTopNOutliers	AS INT				Optional input parameter to display the outliers
*																								-1:	display all outliers (be aware that it may affect performances)
*																								0:	don't display in outliers (defautl option)
*																								N:	return the top N outliers (descent sorting)
* Outputs:
*			@prmOutlierLowerLimit			AS INT	Return the lower limit of that define an outlier
*			@prmOutlierUpperLimit			AS INT	Return the upper limit of that define an outlier
*			@prmOutlierCount					AS INT	Return the total number of outliers
*			@prmOutlierMin						AS INT	Return the minimum value from the outliers
*			@prmOutlierMax						AS BIGINT Return the maximum value from the outliers
*
* Output resulset:
*		Optional, the stored procedure may return the data of the table defined in @prmTableName
*		depending on the value of @prmDisplayTopNOutliers
*
* Return value:
*				return 0 if no error encountered
*
* HISTORY:
* $History: dbo.p_Get_Outliers.sql $
 * 
 * *****************  Version 1  *****************
 * History
 * User: FTrarieux        Date: 2016-05-08   Time: 1:30p
 *				Creation of the stored procedure
* *****************  Version 2  *****************
 * History
 * User: FTrarieux        Date: 2016-05-08   Time: 2:30p
 *				Add input variable validation to prevent sql injections in the dynamic sql
* *****************  Version 3  *****************
 * History
 * User: FTrarieux        Date: 2016-05-09   Time: 9:30p
 *				Add 2 new output parameters min and max values of outliers
 *************************************************************************************/

CREATE PROCEDURE dbo.p_Get_Outliers
	@prmSchemaName								AS SYSNAME,
	@prmTableName									AS SYSNAME,
	@prmColumnName								AS SYSNAME,
	@prmDisplayTopNOutliers				AS INT = 0,
	@prmOutlierLowerLimit					AS INT OUTPUT,
	@prmOutlierUpperLimit					AS INT OUTPUT,
	@prmOutlierCount							AS INT OUTPUT,
	@prmOutlierMin								AS INT OUTPUT,
	@prmOutlierMax								AS BIGINT OUTPUT

AS
BEGIN

	-- To suppress informative messages for performance purposes
	SET NOCOUNT ON;

	BEGIN TRY

		-- Declare variables
		DECLARE @Pattern			AS NVARCHAR ( 25 );
		DECLARE @Sql_Command	AS NVARCHAR ( MAX );
		DECLARE @ErrorMessage	AS NVARCHAR ( 4000 );
		DECLARE	@ReturnCode		AS INT;
		DECLARE @OutlierInfo AS TABLE ( OutlierCount INT NOT NULL, OutlierMin INT NOT NULL, OutlierMax BIGINT NOT NULL );
		DECLARE @QuaterTile		AS TABLE ( First_QuaterTile INT, Third_QuaterTile INT );

		-- Input validation 1, check if parameters are not null
		IF ( @prmSchemaName IS NULL OR @prmTableName IS NULL OR 
				 @prmColumnName IS NULL OR @prmDisplayTopNOutliers IS NULL )

			THROW 50001, 'Invalid input parameters.', 1;
		
		-- Input validation 2, only alphanumeric and _ characters are allowed for @prmSchemaName, @prmTableName, @prmColumnName
		SET @Pattern = N'%[^A-Za-z0-9_]%';

		IF ( PATINDEX ( @Pattern, @prmSchemaName ) > 0 OR
				 PATINDEX ( @Pattern, @prmTableName ) > 0 OR
				 PATINDEX ( @Pattern, @prmColumnName ) > 0 )

			THROW 50001, 'Schema or Table or Column name, pattern not supported. Possibly a SQL injection attempt.', 1;

		-- Construct SQL command dynamically to calculate first and third quatertile
		SET @Sql_Command = N'SELECT DISTINCT PERCENTILE_CONT ( 0.25 ) WITHIN GROUP ( ORDER BY ' 
											+ QUOTENAME ( @prmColumnName ) + ' ) OVER () AS [First_QuaterTile] '
											+ ',PERCENTILE_CONT ( 0.75 ) WITHIN GROUP ( ORDER BY '
											+ QUOTENAME ( @prmColumnName ) + ' ) OVER () AS [Third_QuaterTile] '
											+ 'FROM ' + QUOTENAME ( @prmSchemaName ) + '.' + QUOTENAME ( @prmTableName ) + ';';

		--PRINT @Sql_Command; -- For debug purposes

		-- Insert result in @QuaterTile table variable
		INSERT INTO @QuaterTile
		EXEC sys.sp_executesql @stmt = @Sql_Command;

		-- To determine the outliers, I am using the following definition
		-- IQR: third quartile - first quartile
		-- lower bound: first quartile – 1.5·IQR
		-- Upper bound: third quartile + 1.5·IQR
		-- Outliers are outside this interval
		SELECT
			@prmOutlierLowerLimit = First_QuaterTile - 1.5 * ( Third_QuaterTile - First_QuaterTile ),
			@prmOutlierUpperLimit = Third_QuaterTile + 1.5 * ( Third_QuaterTile - First_QuaterTile )
		FROM 
			@QuaterTile

		-- Calculate the total number of Outliers
		SET @Sql_Command = N'SELECT COUNT(*), MIN ( '
											+ QUOTENAME ( @prmColumnName ) + ' ), MAX ( '
											+ QUOTENAME ( @prmColumnName ) + ' ) FROM '
											+ QUOTENAME ( @prmSchemaName ) + '.' + QUOTENAME ( @prmTableName ) + ' WHERE '
											+ QUOTENAME ( @prmColumnName ) + ' > ' + CAST ( @prmOutlierUpperLimit AS NVARCHAR ( 10 ) ) + ' OR '
											+ QUOTENAME ( @prmColumnName ) + ' < ' + CAST ( @prmOutlierLowerLimit AS NVARCHAR ( 10 ) ) +';';

		--PRINT @Sql_Command; -- For debug purposes

		-- Insert result in @OutlierCount table variable
		INSERT INTO @OutlierInfo
		EXEC sys.sp_executesql @stmt = @Sql_Command;

		-- Set output parameter @prmOutlierCount
		IF EXISTS ( SELECT 1 FROM @OutlierInfo )
			
			SELECT
				@prmOutlierCount	= OutlierCount
				,@prmOutlierMin		= OutlierMin
				,@prmOutlierMax		= OutlierMax
			FROM @OutlierInfo;

		ELSE
			SET @prmOutlierCount = 0;

		-- Display top @prmDisplayTopNOutliers outliers if required
		IF @prmDisplayTopNOutliers <> 0
		BEGIN 
			SET @Sql_Command = N'SELECT ' + CASE WHEN @prmDisplayTopNOutliers > 0 THEN ' TOP ( ' + CAST ( @prmDisplayTopNOutliers AS NVARCHAR ( 10 ) ) + ' ) ' ELSE '' END
												+ '* FROM '
												+ QUOTENAME ( @prmSchemaName ) + '.' + QUOTENAME ( @prmTableName ) + ' WHERE '
												+ QUOTENAME ( @prmColumnName ) + ' > ' + CAST ( @prmOutlierUpperLimit AS NVARCHAR ( 10 ) ) + ' OR '
												+ QUOTENAME ( @prmColumnName ) + ' < ' + CAST ( @prmOutlierLowerLimit AS NVARCHAR ( 10 ) ) + ' ORDER BY '
												+ QUOTENAME ( @prmColumnName ) + ' DESC;';

			--PRINT @Sql_Command; -- For debug purposes

			-- Return resultset
			EXEC sys.sp_executesql @stmt = @Sql_Command;

		END;

		-- SELECT @prmOutlierCount, @prmOutlierLowerLimit,  @prmOutlierUpperLimit; -- For debug purposes

		-- No error
		SET @ReturnCode = 0;
		
	END TRY

	-- Error handling
	BEGIN CATCH

		SET @Returncode = 1;

		SET @ErrorMessage =	'Error message: ' + ERROR_MESSAGE();

		-- Throw error to the caller
		RAISERROR (	@ErrorMessage,	-- Message text
								16,							-- Severity
								1								-- State
								);

	END CATCH;

	-- Return error code
	RETURN ( @ReturnCode );

END;

SET NOCOUNT OFF;

GO
