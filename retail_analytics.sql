Create database retail_analytics;
use retail_analytics;
CREATE TABLE Transactions(
	   Invoice_No VARCHAR(20),
       Stock_Code VARCHAR(20),
       Description TEXT,
       Quantity INT,
       Invoice_Date VARCHAR(50),
       Unit_Price DECIMAL(10,2),
       Customer_ID varchar(20),
       Country VARCHAR(50));
       
show variables like'secure_file_priv';
USE retail_analytics;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/online_retail.csv'
INTO TABLE Transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

select count(*) from Transactions;
select * from Transactions;

select 
 sum(case when Invoice_No IS NULL THEN 1 ELSE 0 END) AS Null_Invoice_No,
 sum(case when Stock_Code IS NULL THEN 1 ELSE 0 END) AS Null_Stock_Code,
 sum(case when Description IS NULL THEN 1 ELSE 0 END) AS Null_Description,
 sum(case when Quantity IS NULL THEN 1 ELSE 0 END) AS Null_Quantity,
 sum(case when Invoice_Date IS NULL THEN 1 ELSE 0 END) AS Null_Invoice_Date,
 sum(case when Unit_Price IS NULL THEN 1 ELSE 0 END) AS Null_Unit_Price,
 sum(case when Customer_ID IS NULL THEN 1 ELSE 0 END) AS Null_Customer_ID,
 sum(case when Country IS NULL THEN 1 ELSE 0 END) AS Null_Country
 FROM Transactions;
 
SELECT COUNT(*) AS Negative_Quantity FROM Transactions WHERE Quantity<0;
SELECT COUNT(*) AS Bad_Prices FROM Transactions WHERE Unit_Price<=0; 
SELECT Invoice_No,Stock_Code,Quantity,COUNT(*) AS COUNT FROM Transactions group by Invoice_No,Stock_Code,Quantity HAVING COUNT(*)>1;

CREATE TABLE Transactions1 AS SELECT DISTINCT * FROM Transactions WHERE 
																 Quantity>0 AND
                                                                 Unit_Price>=0 AND
                                                                 Invoice_No NOT LIKE 'C%' AND
                                                                 Customer_ID IS NOT NULL AND Customer_ID !='';

ALTER TABLE Transactions1 ADD COLUMN Revenue Decimal(10,2);
SET SQL_SAFE_UPDATES = 0;
Update Transactions1 SET Revenue = Quantity*Unit_Price;                                                                   
SET SQL_SAFE_UPDATES = 1;                                         

#Compare row counts
SELECT 'Original' AS Table_Name, COUNT(*) AS Total FROM Transactions
UNION ALL
SELECT 'Cleaned', COUNT(*) FROM Transactions1;

SELECT * FROM Transactions1 LIMIT 10;

#### REVENUE TREND ANALYSIS
# 1. Monthly Revenue:
SELECT DATE_FORMAT(STR_TO_DATE(Invoice_Date,'%m/%d/%Y %H:%i'),'%Y-%m') AS Month,
	   ROUND(SUM(REVENUE),2) AS Monthly_Revenue,
       COUNT(DISTINCT Invoice_No) as Total_Orders,
       COUNT(DISTINCT Customer_ID) AS Unique_Customers FROM Transactions1 GROUP BY Month ORDER BY Month;

# 2. Monthly Revenue Growth %:
SELECT Month,Monthly_Revenue,
       ROUND((Monthly_Revenue-LAG(Monthly_Revenue) OVER (ORDER BY Month)) /LAG(Monthly_Revenue) OVER (ORDER BY Month)*100,2) AS Growth_Percentage
FROM (SELECT DATE_FORMAT(STR_TO_DATE(Invoice_Date,'%m/%d/%Y %H:%i'),'%Y-%m') AS Month,
      ROUND(SUM(Revenue), 2) AS Monthly_Revenue FROM Transactions1 GROUP BY Month) AS Monthly order by Month;

###### TOP PRODUCT ANALYSIS
# 1. Top 10 Products by Revenue:
SELECT Stock_Code, Description, ROUND(SUM(Revenue),2) AS Total_Revenue,
                                SUM(Quantity) AS Total_Units_Sold,
                                COUNT(DISTINCT Invoice_No) AS Times_Observed
FROM Transactions1 GROUP BY Stock_Code,Description ORDER BY Total_Revenue DESC LIMIT 10;

SELECT Stock_Code,Description,
    SUM(Quantity) AS Total_Quantity_Sold,
    ROUND(SUM(Revenue), 2) AS Total_Revenue,
    ROUND(AVG(Unit_Price), 2) AS Avg_Price
FROM Transactions1 GROUP BY Stock_Code, Description ORDER BY Total_Quantity_Sold DESC LIMIT 10;

#### Top Countries Analysis
# 1. Top 10 Countries by Revenue:							
# 2. Revenue Share by Country:
WITH Country_Revenue AS (
                          SELECT Country, ROUND(SUM(Revenue),2) AS Total_Revenue,
                          COUNT(DISTINCT Invoice_No) AS Total_Orders,
                          COUNT(DISTINCT Customer_ID) AS Unique_Customers,
                          ROUND(AVG(Unit_Price*Quantity),2) AS Avg_Order_Value
     FROM Transactions1 WHERE Country!='Unspecified' GROUP BY Country),
     Total AS(
			   SELECT SUM(Total_Revenue) AS Grand_Total FROM Country_Revenue)
SELECT Country, Total_Revenue, Total_Orders, Unique_Customers, Avg_Order_Value,
	   ROUND(Total_Revenue/Grand_Total*100,2) AS Revenue_Share_Percentage,
       RANK() OVER (ORDER BY Total_Revenue DESC) AS Revenue_Rank
FROM Country_Revenue, Total ORDER BY Revenue_Rank LIMIT 10;       

#### Customer Analysis 
# 1. Top 10 Customers by Revenue:
SELECT Customer_ID, Country, 
	   ROUND(SUM(Revenue),2) AS Total_Spent,
       COUNT(DISTINCT Invoice_No) AS Total_Orders,
       SUM(Quantity) AS Total_Items_Bought
FROM Transactions1 GROUP BY Customer_ID, Country ORDER BY Total_Spent DESC LIMIT 10;       

# 2. Average Customer Spending:
SELECT ROUND(AVG(Total_Spent),2) AS Average_Customer_Spending,
	   ROUND(MAX(Total_Spent),2) AS Highest_Spender,
       ROUND(MIN(Total_Spent),2) AS Lowest_Spender
FROM (
      SELECT Customer_ID, ROUND(SUM(Revenue),2) AS Total_Spent 
      FROM Transactions1 GROUP BY Customer_ID) AS Customer_Spents;
      
CREATE TABLE Customer AS SELECT Customer_ID, Country,
                                COUNT(DISTINCT Invoice_No) AS Total_Orders,
                                SUM(Quantity) AS Total_Items_Bought,
                                ROUND(SUM(Revenue),2) AS Total_Spent,
                                ROUND(AVG(Revenue),2) AS Average_Spent,
                                MIN(STR_TO_DATE(Invoice_Date,'%m/%d/%Y %H:%i')) AS First_Purchase,
                                MAX(STR_TO_DATE(Invoice_Date,'%m/%d/%Y %H:%i')) AS Last_Purchase FROM Transactions1 GROUP BY Customer_ID,Country;
SELECT * FROM Customer LIMIT 10;

SELECT 
    MIN(STR_TO_DATE(Invoice_Date, '%m/%d/%Y %H:%i')) AS First_Date,
    MAX(STR_TO_DATE(Invoice_Date, '%m/%d/%Y %H:%i')) AS Last_Date
FROM Transactions1;

#### RFM ANALYSIS
WITH RFM AS(
             SELECT Customer_ID, DATEDIFF('2011-12-10',MAX(STR_TO_DATE(Invoice_Date,'%m/%d/%Y %H:%i'))) AS Recency,
					COUNT(DISTINCT Invoice_No) AS Frequency,
                    ROUND(SUM(REVENUE),2) AS Monetary FROM Transactions1 GROUP BY Customer_ID),
RFM_Scores AS (
			   SELECT *,
                      NTILE(5) OVER(ORDER BY Recency ASC) AS R_Score,
                      NTILE(5) OVER(ORDER BY Frequency DESC) AS F_Score,
                      NTILE(5) OVER(ORDER BY Monetary DESC) AS M_Score FROM RFM)
SELECT *,
       ROUND((R_Score+F_Score+M_Score)/3,2) AS RFM_Score,
       CASE WHEN (R_Score+F_Score+M_Score)>= 13 THEN 'Champion'
            WHEN (R_Score+F_Score+M_Score)>=10 THEN 'Loyal Customer'
            WHEN (R_Score+F_Score+M_Score)>=7 THEN 'Potential Loyalist'
            WHEN (R_Score+F_Score+M_Score)>=5 THEN 'At Risk'
            ELSE 'Lost Customer'
       END AS Customer_Segment FROM RFM_Scores ORDER BY RFM_Score DESC;    
       

WITH RFM AS (
    SELECT 
        Customer_ID,
        DATEDIFF('2011-12-10', MAX(STR_TO_DATE(Invoice_Date, '%m/%d/%Y %H:%i'))) AS Recency,
        COUNT(DISTINCT Invoice_No) AS Frequency,
        ROUND(SUM(Revenue), 2) AS Monetary
    FROM Transactions1
    GROUP BY Customer_ID
),
RFM_Scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency ASC) AS R_Score,
        NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary DESC) AS M_Score
    FROM RFM
)
SELECT 
    CASE 
        WHEN (R_Score + F_Score + M_Score) >= 13 THEN 'Champion'
        WHEN (R_Score + F_Score + M_Score) >= 10 THEN 'Loyal Customer'
        WHEN (R_Score + F_Score + M_Score) >= 7 THEN 'Potential Loyalist'
        WHEN (R_Score + F_Score + M_Score) >= 5 THEN 'At Risk'
        ELSE 'Lost Customer'
    END AS Customer_Segment,
    COUNT(*) AS Total_Customers,
    ROUND(AVG(Monetary), 2) AS Avg_Spending,
    ROUND(AVG(Frequency), 2) AS Avg_Orders
FROM RFM_Scores
GROUP BY Customer_Segment
ORDER BY Avg_Spending DESC;
       
SELECT 
    Customer_ID,
    DATEDIFF('2011-12-10', MAX(STR_TO_DATE(Invoice_Date, '%m/%d/%Y %H:%i'))) AS Recency,
    COUNT(DISTINCT Invoice_No) AS Frequency,
    ROUND(SUM(Revenue), 2) AS Monetary
FROM Transactions1
GROUP BY Customer_ID;