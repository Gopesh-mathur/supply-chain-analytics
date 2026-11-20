USE supply_chain_dw;
DROP TABLE IF EXISTS raw_supply_chain;

CREATE TABLE raw_supply_chain (
  order_id VARCHAR(50), order_date VARCHAR(30), supplier VARCHAR(100),
  supplier_country VARCHAR(50), category VARCHAR(50), product VARCHAR(100),
  unit_price VARCHAR(30), quantity VARCHAR(30), warehouse VARCHAR(100),
  warehouse_city VARCHAR(50), warehouse_country VARCHAR(50),
  shipping_mode VARCHAR(30), destination_city VARCHAR(50),
  destination_country VARCHAR(50), ship_date VARCHAR(30),
  expected_delivery_date VARCHAR(30), delivery_date VARCHAR(30),
  delay_days VARCHAR(30), lead_time_days VARCHAR(30), order_value VARCHAR(30),
  shipping_cost VARCHAR(30), total_cost VARCHAR(30), defect_rate_pct VARCHAR(30),
  stock_on_hand VARCHAR(30), reorder_level VARCHAR(30), status VARCHAR(30),
  order_date_key VARCHAR(30)
);
SELECT COUNT(*) FROM raw_supply_chain;   


DROP TABLE IF EXISTS fact_supply_chain;
DROP TABLE IF EXISTS dim_supplier;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_warehouse;
DROP TABLE IF EXISTS dim_destination;
DROP TABLE IF EXISTS dim_shipping;
DROP TABLE IF EXISTS stg_supply_chain;



CREATE TABLE stg_supply_chain AS
SELECT DISTINCT
  TRIM(order_id) AS order_id,

  CASE
    WHEN LOWER(TRIM(supplier)) LIKE 'apex%'      THEN 'Apex Components'
    WHEN LOWER(TRIM(supplier)) LIKE 'atlas%'     THEN 'Atlas Chemicals'
    WHEN LOWER(TRIM(supplier)) LIKE 'bosphorus%' THEN 'Bosphorus Trading'
    WHEN LOWER(TRIM(supplier)) LIKE 'delta%'     THEN 'Delta Metals'
    WHEN LOWER(TRIM(supplier)) LIKE 'globex%'    THEN 'Globex Industrial'
    WHEN LOWER(TRIM(supplier)) LIKE 'kiran%'     THEN 'Kiran Polymers'
    WHEN LOWER(TRIM(supplier)) LIKE 'maple%'     THEN 'Maple Leaf Supply'
    WHEN LOWER(TRIM(supplier)) LIKE 'meridian%'  THEN 'Meridian Foods'
    WHEN LOWER(TRIM(supplier)) LIKE 'nordic%'    THEN 'Nordic Parts AB'
    WHEN LOWER(TRIM(supplier)) LIKE 'orion%'     THEN 'Orion Electronics'
    WHEN LOWER(TRIM(supplier)) LIKE 'pacific%'   THEN 'Pacific Packaging'
    WHEN LOWER(TRIM(supplier)) LIKE 'sunrise%'   THEN 'Sunrise Textiles'
    ELSE 'Unknown'
  END AS supplier,
  
  
  CASE
    WHEN LOWER(TRIM(supplier_country)) IN ('india','indai','india.')           THEN 'India'
    WHEN LOWER(TRIM(supplier_country)) IN ('usa','us','u.s.a','united states') THEN 'USA'
    WHEN LOWER(TRIM(supplier_country)) = 'bangladesh' THEN 'Bangladesh'
    WHEN LOWER(TRIM(supplier_country)) = 'brazil'     THEN 'Brazil'
    WHEN LOWER(TRIM(supplier_country)) = 'canada'     THEN 'Canada'
    WHEN LOWER(TRIM(supplier_country)) = 'china'      THEN 'China'
    WHEN LOWER(TRIM(supplier_country)) = 'germany'    THEN 'Germany'
    WHEN LOWER(TRIM(supplier_country)) = 'sweden'     THEN 'Sweden'
    WHEN LOWER(TRIM(supplier_country)) = 'taiwan'     THEN 'Taiwan'
    WHEN LOWER(TRIM(supplier_country)) = 'turkey'     THEN 'Turkey'
    WHEN LOWER(TRIM(supplier_country)) = 'vietnam'    THEN 'Vietnam'
    ELSE 'Unknown'
  END AS supplier_country,

  TRIM(product) AS product,




  CASE
    WHEN TRIM(product) IN ('Adhesive Pack','Resin Drum','Solvent Can')          THEN 'Chemicals'
    WHEN TRIM(product) IN ('Battery Pack','Circuit Board','Sensor Module')      THEN 'Electronics'
    WHEN TRIM(product) IN ('Edible Oil Drum','Grain Sack','Sugar Bag')          THEN 'Food & Beverage'
    WHEN TRIM(product) IN ('Aluminium Coil','Copper Wire Spool','Steel Sheet')  THEN 'Metals'
    WHEN TRIM(product) IN ('Corrugated Box','Pallet','Plastic Wrap Roll')       THEN 'Packaging'
    WHEN TRIM(product) IN ('Cotton Fabric Roll','Denim Bale','Polyester Yarn')  THEN 'Textiles'
    ELSE 'Unknown'
  END AS category,

  CONCAT(TRIM(warehouse_city), ' WH') AS warehouse,
  TRIM(warehouse_city)    AS warehouse_city,
  TRIM(warehouse_country) AS warehouse_country,
  
  
  CASE
    WHEN LOWER(TRIM(shipping_mode)) IN ('air','airr')  THEN 'Air'
    WHEN LOWER(TRIM(shipping_mode)) IN ('rail','rial') THEN 'Rail'
    WHEN LOWER(TRIM(shipping_mode)) IN ('road','rod')  THEN 'Road'
    WHEN LOWER(TRIM(shipping_mode)) IN ('sea','see')   THEN 'Sea'
    ELSE 'Unknown'
  END AS shipping_mode,



 CASE
    WHEN LOWER(TRIM(status)) IN ('delivered','deliverd','delivred') THEN 'Delivered'
    WHEN LOWER(TRIM(status)) IN ('delayed','delaid','delyed')       THEN 'Delayed'
    WHEN LOWER(TRIM(status)) = 'cancelled'                          THEN 'Cancelled'
    WHEN LOWER(TRIM(status)) = 'returned'                           THEN 'Returned'
    ELSE 'Unknown'
  END AS status,

  CASE WHEN TRIM(destination_city) IN ('','Unknown') THEN 'Unknown'
       ELSE TRIM(destination_city) END AS destination_city,

  STR_TO_DATE(TRIM(REPLACE(order_date_key,'\r','')),'%d-%m-%Y') AS order_date,
  STR_TO_DATE(TRIM(ship_date),'%d-%m-%Y')              AS ship_date,
  STR_TO_DATE(TRIM(expected_delivery_date),'%d-%m-%Y') AS expected_delivery_date,
  STR_TO_DATE(TRIM(delivery_date),'%d-%m-%Y')          AS delivery_date,

  CAST(unit_price AS DECIMAL(12,2))      AS unit_price,
  CAST(quantity AS UNSIGNED)             AS quantity,
  CAST(delay_days AS DECIMAL(5,1))       AS delay_days,
  CAST(lead_time_days AS UNSIGNED)       AS lead_time_days,
  CAST(order_value AS DECIMAL(14,2))     AS order_value,
  CAST(shipping_cost AS DECIMAL(12,2))   AS shipping_cost,
  CAST(total_cost AS DECIMAL(14,2))      AS total_cost,
  CAST(defect_rate_pct AS DECIMAL(5,2))  AS defect_rate_pct,
  CAST(stock_on_hand AS SIGNED)          AS stock_on_hand,
  CAST(reorder_level AS SIGNED)          AS reorder_level
FROM raw_supply_chain;




/* =========================================================
   STEP 2: DIMENSION TABLES
   ========================================================= */
/* DIM 1: SUPPLIER (+ continent) */
CREATE TABLE dim_supplier (
  supplier_key INT AUTO_INCREMENT PRIMARY KEY,
  supplier_name VARCHAR(100),
  supplier_country VARCHAR(50),
  supplier_continent VARCHAR(30)
);
INSERT INTO dim_supplier (supplier_name, supplier_country, supplier_continent)
SELECT DISTINCT supplier, supplier_country,
  CASE supplier_country
    WHEN 'India' THEN 'Asia'      WHEN 'China' THEN 'Asia'
    WHEN 'Bangladesh' THEN 'Asia' WHEN 'Taiwan' THEN 'Asia'
    WHEN 'Vietnam' THEN 'Asia'    WHEN 'Turkey' THEN 'Asia'
    WHEN 'Germany' THEN 'Europe'  WHEN 'Sweden' THEN 'Europe'
    WHEN 'USA' THEN 'North America' WHEN 'Canada' THEN 'North America'
    WHEN 'Brazil' THEN 'South America'
    ELSE 'Unknown'
  END
FROM stg_supply_chain;


/* DIM 2: PRODUCT */
CREATE TABLE dim_product (
  product_key INT AUTO_INCREMENT PRIMARY KEY,
  product_name VARCHAR(100),
  category VARCHAR(50)
);
INSERT INTO dim_product (product_name, category)
SELECT DISTINCT product, category FROM stg_supply_chain;






/* DIM 3: WAREHOUSE (+ continent from city) */
CREATE TABLE dim_warehouse (
  warehouse_key INT AUTO_INCREMENT PRIMARY KEY,
  warehouse_name VARCHAR(100),
  warehouse_city VARCHAR(50),
  warehouse_country VARCHAR(50),
  warehouse_continent VARCHAR(30)
);
INSERT INTO dim_warehouse (warehouse_name, warehouse_city, warehouse_country, warehouse_continent)
SELECT DISTINCT warehouse, warehouse_city, warehouse_country,
  CASE warehouse_city
    WHEN 'Chicago'   THEN 'North America'
    WHEN 'Delhi'     THEN 'Asia'
    WHEN 'Mumbai'    THEN 'Asia'
    WHEN 'Dubai'     THEN 'Asia'
    WHEN 'Singapore' THEN 'Asia'
    WHEN 'Frankfurt' THEN 'Europe'
    WHEN 'Rotterdam' THEN 'Europe'
    ELSE 'Unknown'
  END
FROM stg_supply_chain;



/* DIM 4: DESTINATION (+ country and continent from city) */
CREATE TABLE dim_destination (
  destination_key INT AUTO_INCREMENT PRIMARY KEY,
  destination_city VARCHAR(50),
  destination_country VARCHAR(50),
  destination_continent VARCHAR(30)
);




INSERT INTO dim_destination (destination_city, destination_country, destination_continent)
SELECT city,
  CASE
    WHEN city IN ('Bengaluru','Chennai','Hyderabad','Jaipur','Kolkata') THEN 'India'
    WHEN city IN ('Dallas','Los Angeles','New York') THEN 'USA'
    WHEN city = 'Berlin'    THEN 'Germany'
    WHEN city = 'London'    THEN 'UK'
    WHEN city = 'Paris'     THEN 'France'
    WHEN city = 'Dubai'     THEN 'UAE'
    WHEN city = 'Singapore' THEN 'Singapore'
    WHEN city = 'Tokyo'     THEN 'Japan'
    WHEN city = 'Sydney'    THEN 'Australia'
    WHEN city = 'Toronto'   THEN 'Canada'
    ELSE 'Unknown'
  END,
  CASE
    WHEN city IN ('Bengaluru','Chennai','Hyderabad','Jaipur','Kolkata',
                  'Dubai','Singapore','Tokyo')                  THEN 'Asia'
    WHEN city IN ('Berlin','London','Paris')                    THEN 'Europe'
    WHEN city IN ('Dallas','Los Angeles','New York','Toronto')  THEN 'North America'
    WHEN city = 'Sydney'                                        THEN 'Oceania'
    ELSE 'Unknown'
  END
FROM (SELECT DISTINCT destination_city AS city FROM stg_supply_chain) c;



/* DIM 5: SHIPPING (mode + status) */
CREATE TABLE dim_shipping (
  shipping_key INT AUTO_INCREMENT PRIMARY KEY,
  shipping_mode VARCHAR(30),
  status VARCHAR(30)
);
INSERT INTO dim_shipping (shipping_mode, status)
SELECT DISTINCT shipping_mode, status FROM stg_supply_chain;








/* =========================================================
   STEP 3: FACT TABLE
   ========================================================= */
CREATE TABLE fact_supply_chain (
  fact_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id VARCHAR(50),
  supplier_key INT,
  product_key INT,
  warehouse_key INT,
  destination_key INT,
  shipping_key INT,
  order_date DATE,
  ship_date DATE,
  expected_delivery_date DATE,
  delivery_date DATE,
  unit_price DECIMAL(12,2),
  quantity INT,
  order_value DECIMAL(14,2),
  shipping_cost DECIMAL(12,2),
  total_cost DECIMAL(14,2),
  delay_days DECIMAL(5,1),
  lead_time_days INT,
  defect_rate_pct DECIMAL(5,2),
  stock_on_hand INT,
  reorder_level INT,
  FOREIGN KEY (supplier_key)    REFERENCES dim_supplier(supplier_key),
  FOREIGN KEY (product_key)     REFERENCES dim_product(product_key),
  FOREIGN KEY (warehouse_key)   REFERENCES dim_warehouse(warehouse_key),
  FOREIGN KEY (destination_key) REFERENCES dim_destination(destination_key),
  FOREIGN KEY (shipping_key)    REFERENCES dim_shipping(shipping_key)
);


INSERT INTO fact_supply_chain
  (order_id, supplier_key, product_key, warehouse_key, destination_key, shipping_key,
   order_date, ship_date, expected_delivery_date, delivery_date,
   unit_price, quantity, order_value, shipping_cost, total_cost,
   delay_days, lead_time_days, defect_rate_pct, stock_on_hand, reorder_level)
SELECT
  s.order_id, ds.supplier_key, dp.product_key, dw.warehouse_key,
  dd.destination_key, dsh.shipping_key,
  s.order_date, s.ship_date, s.expected_delivery_date, s.delivery_date,
  s.unit_price, s.quantity, s.order_value, s.shipping_cost, s.total_cost,
  s.delay_days, s.lead_time_days, s.defect_rate_pct, s.stock_on_hand, s.reorder_level
FROM stg_supply_chain s
JOIN dim_supplier    ds  ON ds.supplier_name = s.supplier AND ds.supplier_country = s.supplier_country
JOIN dim_product     dp  ON dp.product_name = s.product AND dp.category = s.category
JOIN dim_warehouse   dw  ON dw.warehouse_name = s.warehouse
JOIN dim_destination dd  ON dd.destination_city = s.destination_city
JOIN dim_shipping    dsh ON dsh.shipping_mode = s.shipping_mode AND dsh.status = s.status;



/* =========================================================
   STEP 4: CHECKS
   ========================================================= */
SELECT 'raw rows'    AS check_name, COUNT(*) AS rows_count FROM raw_supply_chain
UNION ALL
SELECT 'staged rows' , COUNT(*) FROM stg_supply_chain
UNION ALL
SELECT 'fact rows'   , COUNT(*) FROM fact_supply_chain;   -- fact rows must equal staged rows

SELECT d.destination_continent, COUNT(*) AS orders
FROM fact_supply_chain f
JOIN dim_destination d ON d.destination_key = f.destination_key
GROUP BY d.destination_continent;






