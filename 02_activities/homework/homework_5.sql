-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

SELECT v.vendor_name
, p.product_name
, SUM(cj.expected_revenue) AS total_expected_revenue
FROM (SELECT DISTINCT vi.vendor_id
					, vi.product_id
					, c.customer_id -- to effectivelly applicate the CROSS JOIN
					, (vi.original_price * 5) AS expected_revenue -- as there are 5 units per product
				FROM vendor_inventory vi
					CROSS JOIN customer c) cj
	JOIN vendor v ON cj.vendor_id = v.vendor_id
	JOIN product p ON cj.product_id = p.product_id
GROUP BY cj.vendor_id, cj.product_id
ORDER BY 1, 2

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS product_units;
CREATE TABLE product_units AS
SELECT *
, CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product 
WHERE  product_qty_type = 'unit'

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units
SELECT product_id
, product_name
, product_size
, product_category_id
, product_qty_type
, CURRENT_TIMESTAMP
 FROM product_units
 WHERE  product_id = 10
 LIMIT 1 -- Get exactly one

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

 DELETE 
 FROM product_units
 WHERE product_id = 10 
	AND snapshot_timestamp = '2024-09-23 17:45:50' -- make sure we only delete the older record

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD current_quantity INT;
	
WITH last_seen AS (SELECT vi.product_id
, MAX(vi.market_date) AS market_date 
FROM vendor_inventory vi
GROUP BY product_id), product_qty AS (SELECT pu.product_id, coalesce(vi.quantity, 0) AS last_qty
FROM vendor_inventory vi
	JOIN last_seen ls ON vi.product_id = ls.product_id AND vi.market_date = ls.market_date
	RIGHT JOIN product_units pu ON vi.product_id = pu.product_id)
	
UPDATE product_units 
SET current_quantity = (SELECT  last_qty FROM product_qty WHERE product_qty.product_id = product_units.product_id)

