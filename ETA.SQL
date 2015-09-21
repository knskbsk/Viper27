/*The following segment of code based on SQL will be able to determine availability of reports based on some benchmark jobs example Latest Job=LJ,END Job=EJ,Start Job=SJ
The code loops through n number of clients AND calculates ETA of reports timing to the END client using distributed SQL AND stores the data in a final table named ETAData*/
/*variable declaration*/
DECLARE @olap TABLE (cust_id INT,vid INT IDENTITY ,olap_srvr VARCHAR(30),olap_db VARCHAR(20),env_name VARCHAR(100),env_sts VARCHAR(10),hr_dIFf INT)
DECLARE @query nVARCHAR(max),@SJ DATETIME,@EJ DATETIME,@sql nVARCHAR(max),@OLAP_Srvr VARCHAR(40),@olap_db VARCHAR(20),@job_time VARCHAR(20),@avg_rde_comp_tm INT,@eta VARCHAR(30),@vmax_cnt INT,@vmin_cnt INT,@sql1 nVARCHAR(max),@job_name VARCHAR(30),@env_name VARCHAR(100),@EJ_time VARCHAR(30),@avg_EJ_time VARCHAR(30),@SJ_time VARCHAR(30),@env_sts VARCHAR(10),@cust_id INT,@hr_dIFf INT,@env_comp_ind INT
/*SETting the max AND min counter variable for the loop*/
SELECT @vmin_cnt=1 
/*All master data of the client is stored in the master table mstr_CustomerEnvironment*/ 
SELECT @vmax_cnt=COUNT(*) FROM dbo.mstr_CustomerEnvironment
INSERT INTO @olap (cust_id,olap_srvr,olap_db,env_name,hr_dIFf)SELECT ObjectId,RDE_Server,RDE_Database,EnvironmentName,Hour_DIFf FROM dbo.mstr_CustomerEnvironment 
WHILE @vmin_cnt<=@vmax_cnt/*LOOP BEGINs*/
BEGIN /*Try block begins*/BEGIN TRY 
SELECT @cust_id=cust_id,@env_name=env_name,@OLAP_Srvr=olap_srvr,@olap_db=olap_db,@hr_dIFf=hr_dIFf FROM @olap WHERE vid=@vmin_cnt
/*find the lastest job  that has completed*/
SET @sql1='SELECT @job_name=h.job_name FROM OPENDATASOURCE(''SQLOLEDB'''+','+CHAR(39)+'Data Source'+'='+@OLAP_Srvr+';INTegrated Security=SSPI;Connect Timeout=2'+CHAR(39)+').'+@olap_db+'.History h WHERE h.END_dtime=(SELECTMAX(END_dtime) FROM OPENDATASOURCE(''SQLOLEDB'''+','+CHAR(39)+'Data Source'+'='+@OLAP_Srvr+';INTegrated Security=SSPI;Connect Timeout=2'+CHAR(39)+').'+@olap_db+'.History WHERE sts_cd=''success'')'EXEC sp_executesql @Query=@sql1, @Params = N'@job_name VARCHAR(30) OUTPUT',@job_name=@job_name OUTPUT
IF Object_Id('tempdb..#Temp_data1') is Not NULL drop table #Temp_data1 CREATE TABLE #Temp_data1(latest_job_tm DATETIME,EJ DATETIME) IF Object_Id('tempdb..#Temp_data2') is Not NULL drop table #Temp_data2 CREATE TABLE #Temp_data2(job_time VARCHAR(30))
/*calculate last 10 days time for the LJ AND EJ*/
SET @sql='with t1 (latest_job_tm) as(
SELECT h.END_dtime FROM OPENDATASOURCE(''SQLOLEDB'''+','+CHAR(39)+'Data Source'+'='+@OLAP_Srvr+';INTegrated Security=SSPI;Connect Timeout=2'+CHAR(39)+').'+@olap_db+'.History h WHERE job_name='''+@job_name+'''AND CONVERT(VARCHAR(10),h.start_dtime,101)> ( case when DATEPART(DD,getdate())=1 then GETDATE()-32 else GETDATE()-10 END )AND h.sts_cd=''success''),t2 (EJ) as (SELECTh.END_dtime FROM OPENDATASOURCE(''SQLOLEDB'''+','+CHAR(39)+'Data Source'+'='+@OLAP_Srvr+';INTegrated Security=SSPI;Connect Timeout=2'+CHAR(39)+').'+@olap_db+'.History h WHERE (job_name=''EJ'' or job_name=''EJ'')AND CONVERT(VARCHAR(10),h.start_dtime,101)> ( case when DATEPART(DD,getdate())=1 then GETDATE()-32else GETDATE()-10 END )AND h.sts_cd=''success'')'+' SELECTt1.latest_job_tm,t2.EJ FROM t1,t2 WHERE substring(CONVERT(VARCHAR(10),t1.latest_job_tm,101),1,12)=substring(CONVERT(VARCHAR(10),t2.EJ,101),1,12)'
INSERT INTO #Temp_data1(latest_job_tm,EJ)
EXECUTE sp_executesql @sql
/*find the lastest job time that has completed*/
SET @sql1='SELECT @job_time=h.END_dtime FROM OPENDATASOURCE(''SQLOLEDB'''+','+CHAR(39)+'Data Source'+'='+@OLAP_Srvr+';INTegrated Security=SSPI;Connect Timeout=2'+CHAR(39)+').'+@olap_db+'.History h WHERE h.END_dtime=(SELECTMAX(END_dtime) FROM OPENDATASOURCE(''SQLOLEDB'''+','+CHAR(39)+'Data Source'+'='+@OLAP_Srvr+';INTegrated Security=SSPI;Connect Timeout=2'+CHAR(39)+').'+@olap_db+'.History WHERE sts_cd=''success'') ' EXEC sp_executesql
@Query=@sql1,@Params = N'@job_time VARCHAR(30) OUTPUT',@job_time=@job_time OUTPUT
INSERT INTO #Temp_data2(job_time)VALUES(@job_time)
/*find IF EJ has finished for the day*/
SET @sql1='SELECT @EJ_time=h.END_dtime FROM OPENDATASOURCE(''SQLOLEDB'''+','+CHAR(39)+'Data Source'+'='+@OLAP_Srvr+';INTegrated Security=SSPI;Connect Timeout=2'+CHAR(39)+').'+@olap_db+'.History h WHERE (job_name=''EJ'' or job_name=''EJ'')AND CONVERT(VARCHAR(10),h.start_dtime,101)=CONVERT(VARCHAR(10),getdate(),101) 'EXEC sp_executesql
@Query=@sql1,@Params = N'@EJ_time VARCHAR(30) OUTPUT',@EJ_time=@EJ_time OUTPUT
/*find IF SJ has finished for the day*/
SET @sql1='SELECT @SJ_time=h.END_dtime FROM OPENDATASOURCE(''SQLOLEDB'''+','+CHAR(39)+'Data Source'+'='+@OLAP_Srvr+';INTegrated Security=SSPI;Connect Timeout=2'+CHAR(39)+').'+@olap_db+'.History h WHERE (job_name=''SJ'' or job_name=''SJ'')AND CONVERT(VARCHAR(10),h.start_dtime,101)=CONVERT(VARCHAR(10),getdate(),101) 'EXEC sp_executesql @Query=@sql1,@Params = N'@SJ_time VARCHAR(30) OUTPUT',@SJ_time=@SJ_time OUTPUT
/*find EJ avg completion time for last 7 days*/
SET @sql1='SELECT @avg_EJ_time=CONVERT(VARCHAR(50),RIGHT(DATEADD(SECOND, AVG( DATEDIFF( SECOND, 0, CAST(h.END_dtime as TIME) ) ), 0),8)) FROM OPENDATASOURCE(''SQLOLEDB'''+','+CHAR(39)+'Data Source'+'='+@OLAP_Srvr+';INTegrated Security=SSPI;Connect Timeout=2'+CHAR(39)+').'+@olap_db+'.History h WHERE (job_name=''EJ'' or job_name=''EJ'')AND h.start_dtime>GETDATE()-8 AND sts_cd=''success'' 'EXEC sp_executesql @Query=@sql1,@Params = N'@avg_EJ_time VARCHAR(30) OUTPUT',@avg_EJ_time=@avg_EJ_time OUTPUT
/*Process has not started for the day hence there is no need to calculate ETA*/
IF @SJ_time  is  NULL AND @EJ_time is NULL
BEGIN INSERT INTO dbo.ETAData(CustObjId,eta) VALUES(@cust_id,'ETA not available now') END 
/*Process has  started for the day but has not completed hence calculate ETA*/
IF @EJ_time IS NULL AND @SJ_time  is not NULL
BEGIN SELECT @avg_rde_comp_tm=avg(DATEDIFF(MI,latest_job_tm,EJ)) FROM #Temp_data1 SET @eta=dateadd(mi,@avg_rde_comp_tm,@job_time)
IF @eta>GETDATE()   BEGIN INSERT INTO dbo.ETAData(CustObjId,eta,avg_EJ_time) VALUES(@cust_id,'Reports are expected by'+SUBSTRING(@eta,12,8),@avg_EJ_time) END
/*IF ETA prediction has surpassed the last ETA time*/
IF @eta<GETDATE()   BEGIN INSERT INTO dbo.ETAData(CustObjId,eta,avg_EJ_time) VALUES(@cust_id,'One or more processes are running long!!ETA not available now',@avg_EJ_time) END
END
/*Process has completed for the day AND reports are available to the END client*/
IF @EJ_time  IS NOT NULL BEGIN INSERT INTO dbo.ETAData(CustObjId,eta,avg_EJ_time)VALUES(@cust_id,'Reports are available FROM'+SUBSTRING(@EJ_time,12,8),@avg_EJ_time) END 
/*reset the value of the variables to NULL for next run*/
SET @job_time=NULL;SET @avg_rde_comp_tm=NULL;SET @eta=NULL;SET @EJ_time=NULL;SET @SJ_time=NULL;
/*Try block ends*/
END TRY
/*hANDle error bypassed during one script cycle*/
/*Catch block ends*/
BEGIN CATCH  PRINT @env_name+' '+ERROR_MESSAGE() END CATCH
/*Catch block ends*/
SET @vmin_cnt=@vmin_cnt+1
END /*LOOP ENDs*/
/* Run the select statement to get data for all clients -->SELECT* FROM dbo.ETAData*/
