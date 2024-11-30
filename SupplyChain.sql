--Exploring the data
SELECT * FROM DataCoSupplyChainDataset ;
--Checking for null values (Repeat for each column)
SELECT * FROM DataCoSupplyChainDataset
WHERE Shipping_Mode iS NULL ;
--Replacing missing values in Customer_Lname column
UPDATE DataCoSupplyChainDataset
SET Customer_Lname = Customer_Fname
WHERE Customer_Lname IS NULL ;
--Replacing missing values in Customer_Zipcode column
UPDATE DataCoSupplyChainDataset
SET Customer_City = 'Elk Grove',
Customer_State = 'CA',
Customer_Zipcode = '95758'
WHERE Customer_Zipcode IS NULL AND Customer_State = '95758'	
UPDATE DataCoSupplyChainDataset
SET Customer_City = 'El Monte',
Customer_State = 'CA',
Customer_Zipcode = '91732'
WHERE Customer_Zipcode IS NULL AND Customer_State = '91732' ;
--Handling null values
SELECT
    COUNT(*) AS total_rows,
	SUM(CASE WHEN Order_Zipcode IS NULL THEN 1 ELSE 0 END) AS Order_Zipcode_nulls,
    SUM(CASE WHEN Product_Description IS NULL THEN 1 ELSE 0 END) AS Product_Description_nulls
FROM DataCoSupplyChainDataset ;
--Replacing missing values in Order_Zipcode column
WITH ZipcodeInference AS (
	SELECT Order_City, Order_State, Order_Zipcode, COUNT(*) AS Zipcode_Count,
	ROW_NUMBER() OVER (PARTITION BY Order_City, Order_State ORDER BY COUNT(*) DESC) AS RN
	FROM DataCoSupplyChainDataset 
	WHERE Order_Zipcode IS NOT NULL
	GROUP BY Order_City, Order_State, Order_Zipcode
)
UPDATE DataCoSupplyChainDataset 
SET Order_Zipcode = (
	SELECT Order_Zipcode FROM ZipcodeInference
	WHERE ZipcodeInference.Order_City = DataCoSupplyChainDataset.Order_City 
	AND ZipcodeInference.Order_State = DataCoSupplyChainDataset.Order_State
	AND RN = 1
)
WHERE Order_Zipcode IS NULL;
--Validating data in (Order Item Total) and (Order Item Profit Ratio) columns
--UPDATE DataCoSupplyChainDataset
--SET Order_Item_Total = Order_Item_Product_Price - Order_Item_Discount
--UPDATE DataCoSupplyChainDataset
--SET	Order_Item_Profit_Ratio = Order_Profit_Per_Order / Order_Item_Product_Price ;

--Deleting column (Benefit_per_order) as it have the dame values in column (Order_Profit_Per_Order)
--SELECT * 
--FROM DataCoSupplyChainDatase
--WHERE Order_Profit_Per_Order <> Benefit_per_order
--ALTER TABLE DataCoSupplyChainDatase
--DROP COLUMN Benefit_per_order;
--Deleting column (Sales_per_customer) as it have the dame values in column (Order_Item_Total)
--SELECT * 
--FROM DataCoSupplyChainDatase
--WHERE Order_Item_Total <> Sales_per_customer
--ALTER TABLE DataCoSupplyChainDatase
--DROP COLUMN Sales_per_customer;
--Deleting columns with no data or useless
ALTER TABLE DataCoSupplyChainDataset
DROP COLUMN Customer_Email, Customer_Password, Product_Description, Product_Image ;


----------------------------------------------------------------

-----------------------*Listing the KPIs*-----------------------
--1. Order Accuracy Rate
SELECT 
CONCAT(COUNT(DISTINCT Order_Id) * 100 / (SELECT COUNT(DISTINCT Order_Id) FROM DataCoSupplyChainDataset),'%') AS "Order Accuracy Rate"
FROM DataCoSupplyChainDataset
WHERE Order_Status IN ('COMPLETE', 'CLOSED');
--2. On-time Delivery Rate
SELECT
CONCAT(COUNT(DISTINCT Order_Id) * 100 / (SELECT COUNT(DISTINCT Order_Id) FROM DataCoSupplyChainDataset),'%') AS "On-time Delivery Rate"
FROM DataCoSupplyChainDataset
WHERE Days_for_shipping_real <= Days_for_shipment_scheduled;
--3. Perfect Order Rate
SELECT 
CONCAT(COUNT(DISTINCT Order_Id) * 100 / (SELECT COUNT(DISTINCT Order_Id) FROM DataCoSupplyChainDataset), '%') AS "On-time Delivery Rate"
FROM DataCoSupplyChainDataset
WHERE Order_Status IN ('COMPLETE', 'CLOSED')
AND Days_for_shipping_real <= Days_for_shipment_scheduled;
--4. Order Lead Time
SELECT 
AVG(DATEDIFF(DAY, order_date_DateOrders, shipping_date_DateOrders)) AS "Average Order Lead Time" 
FROM DataCoSupplyChainDataset;
--5. Order Cycle Time
SELECT
AVG(DATEDIFF(DAY, order_date_DateOrders, DATEADD(DAY, Days_for_shipping_real, shipping_date_DateOrders))) AS "Average Order Cycle Time" 
FROM DataCoSupplyChainDataset;
--Late Orders
SELECT Department_Name,  
COUNT(Late_delivery_risk) as "Late Delivery"
FROM DataCoSupplyChainDataset
WHERE Late_delivery_risk = 1
GROUP BY Department_Name
ORDER BY "Late Delivery" DESC;
 
--Real Shipping Days per Shipping Mode
SELECT Shipping_Mode,
AVG(Days_for_shipping_real) AS "Average Real Shipping Days"
FROM DataCoSupplyChainDataset
GROUP BY Shipping_Mode
ORDER BY "Average Real Shipping Days";

--Scheduled Shipping Days per Shipping Mode
SELECT Shipping_Mode,
AVG(Days_for_shipment_scheduled) AS "Average Scheduled Shipping Days"
FROM DataCoSupplyChainDataset
GROUP BY Shipping_Mode
ORDER BY "Average Scheduled Shipping Days";

--6. Total Sales and Orders
SELECT 
FORMAT(SUM(Order_Item_Total), 'C', 'en-US') AS "Total Sales", 
COUNT(Order_Id) AS "Total Orders"
FROM DataCoSupplyChainDataset;

--Total Sales and Orders by Type
SELECT Type,
FORMAT(SUM(Order_Item_Total), 'C', 'en-US') AS "Total Sales", 
COUNT(Order_Id) AS "Total Orders"
FROM DataCoSupplyChainDataset
GROUP BY Type
ORDER BY SUM(Order_Item_Total) DESC;

--Total Sales and Orders per Category Name
SELECT Category_Name,
FORMAT(SUM(Order_Item_Total), 'C', 'en-US') AS "Total Sales", 
COUNT(Order_Id) AS "Total Orders"
FROM DataCoSupplyChainDataset
GROUP BY Category_Name
ORDER BY SUM(Order_Item_Total) DESC;

--Total Sales and Orders per Customer Segment
SELECT Customer_Segment,
FORMAT(SUM(Order_Item_Total), 'C', 'en-US') AS "Total Sales", 
COUNT(Order_Id) AS "Total Orders"
FROM DataCoSupplyChainDataset
GROUP BY Customer_Segment
ORDER BY SUM(Order_Item_Total) DESC;

--Total Sales and Orders by Region
SELECT Order_Region,
FORMAT(SUM(Order_Item_Total), 'C', 'en-US') AS "Total Sales", 
COUNT(Order_Id) AS "Total Orders"
FROM DataCoSupplyChainDataset
GROUP BY Order_Region
ORDER BY SUM(Order_Item_Total) DESC;

--Total Sales and Orders by Department
SELECT Department_Name,
FORMAT(SUM(Order_Item_Total), 'C', 'en-US') AS "Total Sales", 
COUNT(Order_Id) AS "Total Orders"
FROM DataCoSupplyChainDataset
GROUP BY Department_Name
ORDER BY SUM(Order_Item_Total) DESC;

--Average Order Value (AOV)
SELECT 
FORMAT(SUM(Order_Item_Total) / COUNT(DISTINCT Order_ID), 'C', 'en-US') AS "Average Order Value"
FROM DataCoSupplyChainDataset;

--Lost Sales
SELECT FORMAT(SUM(Order_Item_Total), 'C', 'en-US') AS "Lost Sales"
FROM DataCoSupplyChainDataset
WHERE Order_Status = 'CANCELED';

--7.Return Rate
SELECT
COUNT(Order_Id) AS "Total Returned Orders",
FORMAT(SUM(Order_Profit_Per_Order), 'C', 'en-US') AS "Total Returned Money",
CONCAT(COUNT(DISTINCT Order_Id) * 100 / (SELECT COUNT(DISTINCT Order_Id) FROM DataCoSupplyChainDataset), '%') AS "Return Rate"
FROM DataCoSupplyChainDataset
WHERE Order_Profit_Per_Order < 0 
--AND Delivery_Status <> 'Shipping Canceled';

--Return Rate per Category Name
SELECT TOP(5)
Category_Name,
FORMAT(SUM(Order_Profit_Per_Order), 'C', 'en-US') AS "Total Returned Money",
CONCAT(COUNT(DISTINCT Order_Id) * 100 / (SELECT COUNT(DISTINCT Order_Id) FROM DataCoSupplyChainDataset), '%') AS "Return Rate"
FROM DataCoSupplyChainDataset
WHERE Order_Profit_Per_Order < 0 
--AND Delivery_Status <> 'Shipping Canceled'
GROUP BY Category_Name
ORDER BY "Return Rate" DESC;

--Return Rate per Shipping Mode
SELECT 
Shipping_Mode,
FORMAT(SUM(Order_Profit_Per_Order), 'C', 'en-US') AS "Total Returned Money",
CONCAT(COUNT(DISTINCT Order_Id) * 100 / (SELECT COUNT(DISTINCT Order_Id) FROM DataCoSupplyChainDataset), '%') AS "Return Rate"
FROM DataCoSupplyChainDataset
WHERE Order_Profit_Per_Order < 0 
--AND Delivery_Status <> 'Shipping Canceled'
GROUP BY Shipping_Mode
ORDER BY SUM(Order_Profit_Per_Order) ;


