Pipeline
1. Data Cleaning (Python)

notebooks/cleaning_in_python.ipynb

Converts placeholder strings to proper nulls
Standardises date columns to datetime
Coerces numeric columns and removes invalid negatives
Fills missing text with Unknown and missing numerics with the median
Caps outliers using the IQR method
Exports supply_chain_dataset_full_cleaned.csv with all rows retained
2. Data Warehouse (MySQL)

sql/project_sql_file_updated.sql

The script runs in layers:

Layer	Objects	What it does
Raw	raw_supply_chain	All columns stored as VARCHAR, so nothing is rejected on load
Staging	stg_supply_chain_all, stg_supply_chain	Standardises suppliers, countries, shipping modes and statuses with CASE logic; maps products to categories; converts dates and data types; repairs supplier ↔ country; de-duplicates by order_id; nulls out impossible dates and sets a dates_adjusted flag
Dimensions	dim_supplier, dim_product, dim_warehouse, dim_destination, dim_shipping, dim_date	Descriptive attributes, including derived continents
Fact	fact_supply_chain	Surrogate keys to all dimensions plus all measures
Checks	Step 4 queries	Row-count reconciliation, join-loss check, duplicate check, Unknown counts, date-repair summary
Reporting	v_base view	One flat view joining the fact table and all dimensions
3. Dashboard (Power BI)

dashboard/dashboard.pbix

Six pages, each with Year, Quarter and Supplier slicers:

Page	Focus	Highlights
Overview	Executive summary	Total revenue, orders, profit margin %, profit by continent and category, monthly revenue, product table
Main Information	Financials and volume	Shipping cost, cost per unit, order value, quantity, profit trend vs previous year
Inventory & Warehouse	Stock and quality	Avg stock on hand, delay %, defect rate, high-defect orders
Delivery Performance	Logistics	On-time %, delay %, return %, cancellation %, performance by shipping mode and supplier, warehouse and supplier maps
Regional & Destination	Geography	Orders YoY %, delivered vs cancelled by country, cost decomposition tree, warehouse cost table
Time Intelligence	Period comparisons	Order value prior month, net profit prior year, best category, top supplier, average lead time
Data Model

Star schema: one central fact table surrounded by dimensions.

                 dim_supplier      dim_product
                        \             /
 dim_warehouse ─────  fact_supply_chain  ───── dim_destination
                        /             \
                 dim_shipping        dim_date
Table	Grain / key attributes
fact_supply_chain	One row per order; measures include unit price, quantity, order value, shipping cost, total cost, delay days, lead time, defect rate, stock on hand, reorder level
dim_supplier	Supplier name, country, continent
dim_product	Product, category
dim_warehouse	Warehouse, city, country, continent
dim_destination	City, country, continent
dim_shipping	Shipping mode, order status
dim_date	Date, year, quarter, month, week, weekday
KPIs and Measures
Area	Measures
Financial	Total Revenue, Total Profit, Profit Margin %, Total Cost, Shipping Cost, Cost per Unit
Volume	Total Orders, Total Quantity, Orders PY, Orders YoY %
Delivery	On-Time %, Delay %, Return %, Cancellation %, Avg Lead Time
Quality and inventory	Avg Defect Rate %, High-Defect Orders, Avg Stock on Hand
Time intelligence	Order Value Prior Month, Net Profit Prior Year, Revenue Rank (Country)

sql/dashboard_validation_queries.sql recomputes these measures in SQL so each dashboard number can be cross-checked against the warehouse.

How to Run
Prerequisites
Python 3.9+ with pandas and numpy (or Google Colab)
MySQL 8.0+ (window functions and recursive CTEs are required)
Power BI Desktop
Steps
Clean the data (optional, since the cleaned CSV is included): open notebooks/cleaning_in_python.ipynb, point it to data/supply_chain_dataset_unclean.csv and run all cells.
Create the database
sql
CREATE DATABASE supply_chain_dw;
Load the data into raw_supply_chain (the table is created by the script) using MySQL Workbench's Table Data Import Wizard or LOAD DATA, with data/supply_chain_dataset_full_cleaned.csv.
Build the warehouse by running sql/project_sql_file_updated.sql. Check that the reconciliation queries in Step 4 report zero rows lost in the fact join.
Validate the KPIs with sql/dashboard_validation_queries.sql.
Open the dashboard: open dashboard/dashboard.pbix, update the MySQL data source to your server under Transform data → Data source settings, then click Refresh.
Data Quality Notes and Limitations

Being transparent about the data:

Date repair: some date columns in the cleaned CSV contain logically impossible values (for example, expected delivery before order date). The SQL script sets these to NULL and flags the row in dates_adjusted instead of guessing a date.
Order date source: order_date_key is used as the order date, because the separate order_date column in the cleaned file has day and month swapped for some rows.
Imputation: missing numeric values (such as delay days and defect rate) were filled with the median in Python, so averages for those fields are approximate.
Outlier capping: IQR capping can alter extreme but legitimate values; review before using for pricing decisions.
Supplier repair: missing suppliers are inferred from country only where the mapping is one-to-one. Orders from India stay Unknown, because two suppliers are based there.
Profit definition: profit in the SQL view is order_value − total_cost. Confirm it matches the DAX Total Profit measure before comparing numbers.
Future Improvements
Move all date and outlier logic into the Python notebook so imputation happens in one place
Split order status into its own dimension instead of combining it with shipping mode

Add incremental loading and a scheduled refresh
Add data-quality tests (for example with pytest or Great Expectations)
Publish the report to Power BI Service with row-level security
