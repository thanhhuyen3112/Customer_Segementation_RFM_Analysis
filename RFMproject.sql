SELECT 	CustomerID,
		DATEDIFF(day, MAX(cast(Purchase_Date as date)), '2022-09-01') as Recency,
		1.0*COUNT(DISTINCT Purchase_Date)
			/DATEDIFF(YEAR , cast(cr.created_date as date), '2022-09-01') as Frequency,
		1.0*sum(GMV)
			/DATEDIFF(year, cast(cr.created_date as date), '2022-09-01') as Monetary,
		ROW_NUMBER() over(order by DATEDIFF(day, MAX(cast(Purchase_Date as date)), '2022-09-01')) as rn_recency,
		ROW_NUMBER() over(order by 1.0*COUNT(DISTINCT Purchase_Date)
			/DATEDIFF(YEAR , cast(cr.created_date as date), '2022-09-01')) as rn_frequency ,
		ROW_NUMBER() over(order by 1.0*sum(GMV)
			/DATEDIFF(YEAR , cast(cr.created_date as date), '2022-09-01')) as rn_Monetary
into #Customer_Statistics
from Customer_Transaction as ct 
join Customer_Registered as cr on ct.CustomerID = cr.ID 
group by CustomerID, cast(cr.created_date as date)

SELECT 	*, 
case
	when  Recency >= 	(select MIN(Recency) from #Customer_Statistics )
		and Recency < 	(SELECT Recency from #Customer_Statistics
										WHERE rn_recency= (SELECT ROUND(COUNT(CustomerID)*0.25,0) from #Customer_Statistics)) then 4
	when  Recency >= 	(SELECT Recency from #Customer_Statistics
										WHERE rn_recency= (SELECT ROUND(COUNT(CustomerID)*0.25,0) from #Customer_Statistics))
		and Recency < 	(SELECT Recency from #Customer_Statistics
										WHERE rn_recency= (SELECT ROUND(COUNT(CustomerID)*0.5,0)  from #Customer_Statistics)) then 3
	when  Recency >= 	(SELECT Recency from #Customer_Statistics
											WHERE rn_recency= (SELECT ROUND(COUNT(CustomerID)*0.5,0) from #Customer_Statistics))
		and Recency < 	(SELECT Recency from #Customer_Statistics
										WHERE rn_recency= (SELECT ROUND(COUNT(CustomerID)*0.75,0) from #Customer_Statistics)) then 2
else 1 end as R,
case
	when  Frequency >= 	(select MIN(Frequency) from #Customer_Statistics )
		and Frequency < 	(SELECT Frequency 	from #Customer_Statistics
												WHERE rn_frequency= (SELECT ROUND(COUNT(CustomerID)*0.25,0) from #Customer_Statistics)) then 1
	when  Frequency >= 	(SELECT Frequency 	from #Customer_Statistics
											WHERE rn_frequency= (SELECT ROUND(COUNT(CustomerID)*0.25,0) from #Customer_Statistics))
		and Frequency < 	(SELECT Frequency 	from #Customer_Statistics
												WHERE rn_frequency= (SELECT ROUND(COUNT(CustomerID)*0.5,0) from #Customer_Statistics)) then 2
	when  Frequency >= 	(SELECT Frequency 	from #Customer_Statistics
											WHERE rn_frequency= (SELECT ROUND(COUNT(CustomerID)*0.5,0) from #Customer_Statistics))
		and Frequency < 	(SELECT Frequency 	from #Customer_Statistics
												WHERE rn_frequency= (SELECT ROUND(COUNT(CustomerID)*0.75,0) from #Customer_Statistics)) then 3
else 4 end as F,
case
	when  Monetary >= 	(select min(Monetary) from #Customer_Statistics )
		and Monetary < 	(SELECT Monetary 	from #Customer_Statistics
											WHERE rn_Monetary= (SELECT ROUND(COUNT(CustomerID)*0.25,0) from #Customer_Statistics)) then 1
	when  Monetary >= 	(SELECT Monetary 	from #Customer_Statistics
											WHERE rn_Monetary= (SELECT ROUND(COUNT(CustomerID)*0.25,0) from #Customer_Statistics))
		and Monetary < 	(SELECT Monetary 	from #Customer_Statistics
											WHERE rn_Monetary= (SELECT ROUND(COUNT(CustomerID)*0.5,0) from #Customer_Statistics)) then 2
	when  Monetary >= 	(SELECT Monetary 	from #Customer_Statistics
											WHERE rn_Monetary= (SELECT ROUND(COUNT(CustomerID)*0.5,0) from #Customer_Statistics))
		and Monetary < 	(SELECT Monetary 	from #Customer_Statistics
											WHERE rn_Monetary= (SELECT ROUND(COUNT(CustomerID)*0.75,0) from #Customer_Statistics)) then 3
else 4 end as M
into #RFM
from #Customer_Statistics

SELECT *, CONCAT(R, F, M) as RFM,
CASE 
    WHEN CONCAT(R, F, M) IN ('444', '443', '434', '433', '344', '343', '334', '333') THEN 'VIP'
    WHEN CONCAT(R, F, M) IN ('442', '441', '432', '424', '423', '422', '414', '413', '412', '342', '332', '324', '323', '322', '314', '313', '312', '244', '243', '242', '234', '233', '232', '224', '223', '222') THEN 'THAN THIET'
    WHEN CONCAT(R, F, M) IN ('431', '421', '411', '341', '331', '321', '311', '241', '231', '221', '211') THEN 'TIEM NANG'
    ELSE 'VANGLAI'
END AS seg 
FROM #RFM

