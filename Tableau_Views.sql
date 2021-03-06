CREATE VIEW VW_DIM_CHANNEL AS
(
SELECT DIMCHANNELID, SOURCECHANNELID, SOURCECHANNELCATEGORYID, CHANNELNAME, CHANNELCATEGORY
FROM DIM_CHANNEL
);

CREATE VIEW VW_DIM_CUSTOMER AS
(
SELECT DIMCUSTOMERID, DIMLOCATIONID, SOURCECUSTOMERID, FULLNAME, FIRSTNAME, LASTNAME, GENDER, EMAILADDRESS, PHONENUMBER
FROM DIM_CUSTOMER  
);

CREATE VIEW VW_DIM_LOCATION AS
(
SELECT DIMLOCATIONID, ADDRESS, CITY, REGION, COUNTRY, POSTALCODE
FROM DIM_LOCATION 
);

CREATE VIEW VW_DIM_PRODUCT AS
(
SELECT DIMPRODUCTID, SOURCEPRODUCTID, SOURCEPRODUCTTYPEID, SOURCEPRODUCTCATEGORYID, PRODUCTNAME, PRODUCTTYPE, PRODUCTCATEGORY,
  PRODUCTRETAILPRICE, PRODUCTWHOLESALEPRICE, PRODUCTCOST, PRODUCTRETAILPROFIT, PRODUCTWHOLESALEUNITPROFIT,
  PRODUCTPROFITMARGINUNITPERCENT
FROM DIM_PRODUCT
);

CREATE VIEW VW_DIM_RESELLER AS
(
SELECT DIMRESELLERID, DIMLOCATIONID, SOURCERESELLERID, RESELLERNAME, CONTACTNAME, PHONENUMBER, EMAIL
FROM DIM_RESELLER
);

CREATE VIEW VW_DIM_STORE AS
(
SELECT DIMSTOREID,DIMLOCATIONID, SOURCESTOREID, STORENUMBER, STOREMANAGER
FROM DIM_STORE
);

CREATE VIEW VW_FACT_SALES AS
(
SELECT SALESHEADERID,SALESDETAILID, DIMPRODUCTID, DIMSTOREID, DIMRESELLERID, DIMCUSTOMERID, DIMCHANNELID, DATE_PKEY, DIMLOCATIONID,
  SALE_AMOUNT, SALE_QUANTITY, SALE_UNIT_PRICE, SALE_EXTENDED_COST, SALE_TOTAL_PROFIT
FROM FACT_SALES
);

CREATE VIEW VW_FACT_PRODUCT_TARGET AS
(
SELECT DIMPRODUCTID, DATE_PKEY, PRODUCT_TARGET_SALES_QUANTITY
FROM FACT_PRODUCT_SALES_TARGET
);

CREATE VIEW VW_FACT_SRC_TARGET AS
(
SELECT DIMSTOREID, DIMRESELLERID, DIMCHANNELID, DATE_PKEY, SALES_TARGET_AMOUNT
FROM FACT_SRC_SALES_TARGET
);




-----VIEW 1
CREATE VIEW VW_STORE_PERFORMANCE_CUMMULATIVE AS
(
SELECT YEAR,MONTH_NAME,MONTH_NUM_IN_YEAR as MONTH_NUMBER, STORENUMBER,
SUM(ACT_AMT) OVER (PARTITION BY STORENUMBER ORDER BY MONTH_NUM_IN_YEAR ASC) AS ACT_CUMMULATIVE_SALE,
SUM(TARGET_AMT) OVER (PARTITION BY STORENUMBER ORDER BY MONTH_NUM_IN_YEAR ASC) AS TARGET_CUMMULATIVE_SALE
FROM
(
SELECT YEAR, MONTH_NAME, MONTH_NUM_IN_YEAR, STORENUMBER, SUM(TARGET_AMT) AS TARGET_AMT, SUM(ACT_AMT) AS ACT_AMT
FROM 
(
SELECT DD.Year,DD.MONTH_NAME, DD.MONTH_NUM_IN_YEAR, DS.STORENUMBER, SUM(FS.SALES_TARGET_AMOUNT) TARGET_AMT, 0 AS ACT_AMT
FROM FACT_SRC_SALES_TARGET FS
INNER JOIN DIM_STORE DS ON FS.DIMSTOREID = DS.DIMSTOREID
INNER JOIN DIM_DATE DD ON FS.DATE_PKEY = DD.DATE_PKEY
WHERE YEAR = 2014 AND STORENUMBER in (10,21)
GROUP BY DD.Year,DD.MONTH_NAME, DD.MONTH_NUM_IN_YEAR, DS.STORENUMBER

UNION 

SELECT DD.Year, DD.MONTH_NAME, DD.MONTH_NUM_IN_YEAR, DS.STORENUMBER, 0 AS TARGET_AMT, SUM(FS.SALE_AMOUNT) AS ACT_AMT
FROM FACT_SALES FS
INNER JOIN DIM_STORE DS ON FS.DIMSTOREID = DS.DIMSTOREID
INNER JOIN DIM_DATE DD ON FS.DATE_PKEY = DD.DATE_PKEY
WHERE YEAR = 2014 AND STORENUMBER in (10,21)
GROUP BY DD.Year, DD.MONTH_NAME, DD.MONTH_NUM_IN_YEAR, DS.STORENUMBER
)
GROUP BY YEAR, MONTH_NAME, MONTH_NUM_IN_YEAR, STORENUMBER
)
ORDER BY MONTH_NUM_IN_YEAR , STORENUMBER
);  

CREATE VIEW VW_STORE_PERFORMANCE AS
(
SELECT YEAR, MONTH_NAME, MONTH_NUM_IN_YEAR AS MONTH_NUMBER, STORENUMBER, SUM(TARGET_AMT) AS TARGET_AMT, SUM(ACT_AMT) AS ACT_AMT, 
ROUND((SUM(ACT_AMT)/SUM(TARGET_AMT))*100,2) AS PERCENT_TARGET_ACHIEVED
FROM 
(
SELECT DD.Year,DD.MONTH_NAME, DD.MONTH_NUM_IN_YEAR, DS.STORENUMBER, SUM(FS.SALES_TARGET_AMOUNT) TARGET_AMT, 0 AS ACT_AMT
FROM FACT_SRC_SALES_TARGET FS
INNER JOIN DIM_STORE DS ON FS.DIMSTOREID = DS.DIMSTOREID
INNER JOIN DIM_DATE DD ON FS.DATE_PKEY = DD.DATE_PKEY
WHERE YEAR = 2014 AND STORENUMBER in (10,21)
GROUP BY DD.Year,DD.MONTH_NAME, DD.MONTH_NUM_IN_YEAR, DS.STORENUMBER

UNION 

SELECT DD.Year, DD.MONTH_NAME, DD.MONTH_NUM_IN_YEAR, DS.STORENUMBER, 0 AS TARGET_AMT, SUM(FS.SALE_AMOUNT) AS ACT_AMT
FROM FACT_SALES FS
INNER JOIN DIM_STORE DS ON FS.DIMSTOREID = DS.DIMSTOREID
INNER JOIN DIM_DATE DD ON FS.DATE_PKEY = DD.DATE_PKEY
WHERE YEAR = 2014 AND STORENUMBER in (10,21)
GROUP BY DD.Year, DD.MONTH_NAME, DD.MONTH_NUM_IN_YEAR, DS.STORENUMBER
)
GROUP BY YEAR, MONTH_NAME, MONTH_NUM_IN_YEAR, STORENUMBER
ORDER BY YEAR,MONTH_NUM_IN_YEAR 
);

-----VIEW 2
CREATE VIEW VW_BONUS_SHARE AS
(
SELECT YEAR, STORENUMBER, SUM(TARGET_AMT) AS TARGET_AMT, SUM(ACT_AMT) AS ACT_AMT, 
ROUND((SUM(ACT_AMT)/SUM(TARGET_AMT))*100,2) AS PERCENT_TARGET_ACHIEVED
FROM 
(
SELECT DD.Year, DS.STORENUMBER, SUM(FS.SALES_TARGET_AMOUNT) TARGET_AMT, 0 AS ACT_AMT
FROM FACT_SRC_SALES_TARGET FS
INNER JOIN DIM_STORE DS ON FS.DIMSTOREID = DS.DIMSTOREID
INNER JOIN DIM_DATE DD ON FS.DATE_PKEY = DD.DATE_PKEY
WHERE YEAR = 2013 AND STORENUMBER in (10,21)
GROUP BY DD.Year, DS.STORENUMBER

UNION 

SELECT DD.Year, DS.STORENUMBER, 0 AS TARGET_AMT, SUM(FS.SALE_AMOUNT) AS ACT_AMT
FROM FACT_SALES FS
INNER JOIN DIM_STORE DS ON FS.DIMSTOREID = DS.DIMSTOREID
INNER JOIN DIM_DATE DD ON FS.DATE_PKEY = DD.DATE_PKEY
WHERE YEAR = 2013 AND STORENUMBER in (10,21)
GROUP BY DD.Year, DS.STORENUMBER
)
GROUP BY YEAR, STORENUMBER
ORDER BY YEAR
);




-----View 3
CREATE VIEW VW_PRODUCT_SALES AS
(
SELECT DD.DAY_NAME, DD.DAY_NUM_IN_WEEK as DAY_NUMBER, DS.STORENUMBER, DP.PRODUCTNAME, DP.PRODUCTTYPE, DP.PRODUCTCATEGORY, 
SUM(FS.SALE_QUANTITY) AS QUANTITY, SUM(FS.SALE_AMOUNT) AS SALE, SUM(FS.SALE_TOTAL_PROFIT) AS PROFIT
FROM FACT_SALES FS
INNER JOIN DIM_DATE DD ON FS.DATE_PKEY = DD.DATE_PKEY
INNER JOIN DIM_STORE DS ON FS.DIMSTOREID = DS.DIMSTOREID
INNER JOIN DIM_PRODUCT DP ON FS.DIMPRODUCTID = DP.DIMPRODUCTID
WHERE STORENUMBER IN (10,21)
GROUP BY DD.DAY_NAME,DD.DAY_NUM_IN_WEEK, DS.STORENUMBER, DP.PRODUCTNAME, DP.PRODUCTTYPE, DP.PRODUCTCATEGORY
ORDER BY DAY_NUMBER, DS.STORENUMBER, DP.PRODUCTNAME
);


-----View 4
CREATE VIEW VW_STATE_PERFORMANCE AS
(
SELECT DD.DATE, DD.DAY_NAME, DD.YEAR, DD.MONTH_NAME, DL.REGION, Z.STORE_COUNT,
DP.PRODUCTNAME, DP.PRODUCTTYPE, DP.PRODUCTCATEGORY,
SUM(FS.SALE_QUANTITY) AS QUANTITY, SUM(FS.SALE_AMOUNT) AS SALE, SUM(FS.SALE_TOTAL_PROFIT) AS PROFIT
FROM FACT_SALES FS
INNER JOIN DIM_STORE DS ON FS.DIMSTOREID = DS.DIMSTOREID
INNER JOIN DIM_LOCATION DL ON DS.DIMLOCATIONID = DL.DIMLOCATIONID
INNER JOIN DIM_DATE DD ON FS.DATE_PKEY = DD.DATE_PKEY
INNER JOIN DIM_PRODUCT DP ON FS.DIMPRODUCTID = DP.DIMPRODUCTID
LEFT JOIN 
(
SELECT DL.REGION, COUNT(DS.STORENUMBER) STORE_COUNT
FROM DIM_STORE DS
INNER JOIN DIM_LOCATION DL ON DS.DIMLOCATIONID = DL.DIMLOCATIONID
WHERE DL.REGION <> 'UNKNOWN'  
GROUP BY DL.REGION
) Z ON DL.REGION = Z.REGION
WHERE DL.REGION <> 'UNKNOWN'  
GROUP BY DD.DATE, DD.DAY_NAME, DD.YEAR, DD.MONTH_NAME, DL.REGION, Z.STORE_COUNT,
DP.PRODUCTNAME, DP.PRODUCTTYPE, DP.PRODUCTCATEGORY
);

