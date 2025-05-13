-- Create the database and use it
CREATE DATABASE retail_sales;
USE retail_sales;

-- View the initial datasets
SELECT * FROM customer_profile_dataset;
SELECT * FROM products_dataset;
SELECT * FROM purchase_history_dataset;

-- Check for duplicate customer IDs
SELECT 
    (SELECT COUNT(customer_id) FROM customer_profile_dataset) -
    (SELECT COUNT(DISTINCT customer_id) FROM customer_profile_dataset) AS dif_count;

-- If no duplicates, set customer_id as PRIMARY KEY
ALTER TABLE customer_profile_dataset ADD PRIMARY KEY (customer_id);

-- Check for NULL values in first_name and last_name
SELECT first_name FROM customer_profile_dataset WHERE first_name IS NULL;
SELECT last_name FROM customer_profile_dataset WHERE last_name IS NULL;

-- View distinct gender values
SELECT DISTINCT(gender) FROM customer_profile_dataset;

-- Convert date_of_birth to proper DATE format
SELECT date_of_birth FROM customer_profile_dataset;
UPDATE customer_profile_dataset
SET date_of_birth = DATE(date_of_birth);
ALTER TABLE customer_profile_dataset MODIFY date_of_birth DATE;

-- Check for NULL emails
SELECT COUNT(*) FROM customer_profile_dataset WHERE email IS NULL;

-- View and validate phone_number format
SELECT phone_number FROM customer_profile_dataset;
SELECT * FROM customer_profile_dataset 
WHERE phone_number NOT REGEXP '^[0-9]{3}-[0-9]{3}-[0-9]{4}$';

-- Add CHECK constraint for phone_number format
ALTER TABLE customer_profile_dataset 
ADD CHECK (phone_number REGEXP '^[0-9]{3}-[0-9]{3}-[0-9]{4}$');

-- Convert signup_date to TIMESTAMP format
SELECT signup_date FROM customer_profile_dataset;
UPDATE customer_profile_dataset 
SET signup_date = TIMESTAMP(signup_date);
ALTER TABLE customer_profile_dataset 
MODIFY signup_date TIMESTAMP;

-- Separate signup_date into date and time columns
SELECT 
    DATE(signup_date) AS date_1, 
    TIME(signup_date) AS time_1 
FROM customer_profile_dataset;

ALTER TABLE customer_profile_dataset 
ADD COLUMN sign_up_date DATE AFTER signup_date,
ADD COLUMN sign_up_time TIME AFTER sign_up_date;

UPDATE customer_profile_dataset 
SET sign_up_date = DATE(signup_date),
    sign_up_time = TIME(signup_date);

-- Drop original signup_date column
ALTER TABLE customer_profile_dataset DROP COLUMN signup_date;

-- Check for NULL or distinct values in city, state, and zip_code
SELECT DISTINCT(city) FROM customer_profile_dataset;
SELECT * FROM customer_profile_dataset WHERE city IS NULL;

SELECT DISTINCT(state) FROM customer_profile_dataset;
SELECT * FROM customer_profile_dataset WHERE state IS NULL;

SELECT DISTINCT(zip_code) FROM customer_profile_dataset;

-- Add CHECK constraint for zip_code to ensure it's 5-digit and doesn't start with 0
ALTER TABLE customer_profile_dataset 
ADD CONSTRAINT zip_code_check 
CHECK (zip_code REGEXP '^[1-9][0-9]{4}$');

-- Check for duplicate records based on name and phone number
SELECT sub.first_name 
FROM (
    SELECT first_name, last_name, phone_number,
           ROW_NUMBER() OVER (PARTITION BY first_name, last_name, phone_number) AS row_num
    FROM customer_profile_dataset
) AS sub
WHERE row_num > 1;

-- Going through the second dataset 
SELECT DISTINCT(product_name) FROM products_dataset;
SELECT DISTINCT(brand) FROM products_dataset;

-- Clean up brand data
UPDATE products_dataset SET brand = SUBSTRING(brand, 6);
SELECT DISTINCT(category) FROM products_dataset;
SELECT product_name, category FROM products_dataset ORDER BY product_name;

-- Handling mismatched category, creating a new table for correcting records
CREATE TABLE products_dataset_1 (
    product_id INT PRIMARY KEY,
    product_name TEXT,
    brand TEXT,
    category TEXT,
    price_per_unit TEXT
);

INSERT INTO products_dataset_1 (
    product_id,
    product_name,
    brand,
    category,
    price_per_unit
)
SELECT 
    j.product_id,
    j.product_name,
    j.brand,
    d.category,
    j.price_per_unit
FROM 
    products_dataset j
INNER JOIN (
    SELECT   
        p.product_id,
        sub.category
    FROM 
        products_dataset p  
    INNER JOIN (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY product_name) AS counting,
            p1.category AS category,
            p2.product_name AS product_name 
        FROM 
            (SELECT DISTINCT category FROM products_dataset) AS p1
        CROSS JOIN 
            (SELECT DISTINCT product_name FROM products_dataset) AS p2
    ) AS sub 
    ON p.product_name = sub.product_name
    WHERE 
        sub.counting IN (4, 5, 11, 16, 18, 23, 27, 29, 34, 40)
    ORDER BY 
        p.product_id
) AS d 
ON j.product_id = d.product_id
ORDER BY 
    d.product_id;

-- View the newly inserted records
SELECT * FROM products_dataset_1;

-- Modify the price_per_unit column
ALTER TABLE products_dataset_1 MODIFY price_per_unit DOUBLE;

-- Working on the purchase history dataset
-- View existing records
SELECT * FROM purchase_history_dataset;

-- Add primary key constraint to the 'purchase_id' column
ALTER TABLE purchase_history_dataset  
ADD CONSTRAINT pk3 PRIMARY KEY (purchase_id);

-- Add foreign key constraint for 'customer_id' referencing 'customer_profile_dataset'
ALTER TABLE purchase_history_dataset  
ADD CONSTRAINT fk1 FOREIGN KEY (customer_id) 
REFERENCES customer_profile_dataset(customer_id);

-- Add foreign key constraint for 'product_id' referencing 'products_dataset_1'
ALTER TABLE purchase_history_dataset  
ADD CONSTRAINT fk2 FOREIGN KEY (product_id) 
REFERENCES products_dataset_1(product_id);

-- Modify the 'purchase_date' column to timestamp type
ALTER TABLE purchase_history_dataset  
MODIFY purchase_date TIMESTAMP;

-- Select purchase_date along with its date and time parts
SELECT 
    purchase_date, 
    DATE(purchase_date) AS only_date, 
    TIME(purchase_date) AS only_time 
FROM 
    purchase_history_dataset;

-- Add new column 'purchase_date_m' (DATE) after 'purchase_date'
ALTER TABLE purchase_history_dataset  
ADD purchase_date_m DATE AFTER purchase_date;

-- Add new column 'purchase_time_m' (TIME) after 'purchase_date_m'
ALTER TABLE purchase_history_dataset  
ADD purchase_time_m TIME AFTER purchase_date_m;

-- Update 'purchase_date_m' with the DATE part of 'purchase_date'
UPDATE purchase_history_dataset  
SET purchase_date_m = DATE(purchase_date);

-- Update 'purchase_time_m' with the TIME part of 'purchase_date'
UPDATE purchase_history_dataset  
SET purchase_time_m = TIME(purchase_date);

-- Drop the original 'purchase_date' column
ALTER TABLE purchase_history_dataset  
DROP COLUMN purchase_date;

-- Update total_amount with calculated values
UPDATE purchase_history_dataset AS phd
JOIN (
    SELECT 
        phd.purchase_id,
        (pd.price_per_unit * phd.quantity) AS total_quantity
    FROM 
        purchase_history_dataset AS phd
    INNER JOIN 
        products_dataset_1 AS pd ON phd.product_id = pd.product_id
    INNER JOIN 
        customer_profile_dataset AS cpd ON phd.customer_id = cpd.customer_id
) AS sub ON phd.purchase_id = sub.purchase_id
SET phd.total_amount = sub.total_quantity;

-- View the final records in purchase_history_dataset
SELECT * FROM purchase_history_dataset;

-- Modify total_amount to decimal type with precision and scale
ALTER TABLE purchase_history_dataset MODIFY total_amount DECIMAL(10,2);
# creating a average table of each product of each brand 
UPDATE products_dataset_1 AS p
JOIN (
    SELECT 
        product_id,
        AVG(price_per_unit) OVER (PARTITION BY product_name, brand) AS price_per_unit_avg
    FROM products_dataset_1
) AS sub
ON p.product_id = sub.product_id
SET p.price_per_unit = sub.price_per_unit_avg;
-- change the column double length 
alter table products_dataset_1 modify price_per_unit decimal(10,2);
-- applying of the trigger to automatically writing of the category 
DELIMITER $$

DELIMITER $$

CREATE TRIGGER tk1 
BEFORE INSERT ON products_dataset_1 
FOR EACH ROW 
BEGIN 
    DECLARE existing_category TEXT;

    -- Try to find an existing category and price for the same product_name
    SELECT category
    INTO existing_category
    FROM products_dataset_1
    WHERE product_name = NEW.product_name
    LIMIT 1;

    -- If we found category and price
    IF existing_category IS NOT NULL THEN
        SET NEW.category = existing_category;
        
    END IF;
END $$

DELIMITER ;
drop trigger tk1 ;

DELIMITER $$

CREATE EVENT price_checking 
ON SCHEDULE EVERY 30 SECOND
DO
BEGIN 
    UPDATE products_dataset_1 pd 
    JOIN (
        SELECT product_name, brand, AVG(price_per_unit) AS price_amount
        FROM products_dataset_1 
        GROUP BY product_name, brand
    ) AS sub 
    ON pd.product_name = sub.product_name AND pd.brand = sub.brand
    SET pd.price_per_unit = sub.price_amount;
END $$
DELIMITER ;

-- creating a trigger for the calculation of the total amount ,purchase_date , paurchase_time 
DELIMITER $$

CREATE TRIGGER tk2 
BEFORE INSERT ON purchase_history_dataset 
FOR EACH ROW 
BEGIN
    DECLARE fetched_price DOUBLE;

    -- Get the price for the product being inserted
    SELECT price_per_unit 
    INTO fetched_price 
    FROM products_dataset_1 
    WHERE product_id = NEW.product_id 
    LIMIT 1;

    SET NEW.purchase_date_m = DATE(NOW());
    SET NEW.purchase_time_m = TIME(NOW());
    SET NEW.total_amount = NEW.quantity * fetched_price;
END $$

DELIMITER ;
alter table purchase_history_dataset add constraint chk_1 check (quantity>0);
alter table purchase_history_dataset add constraint chk_2 check (total_amount>0);
-- writing the table name is to hard bcs it has too lonng name 
delimiter $$
create procedure calling_table (table_number int)
BEGIN 
    IF table_number =1  THEN select * from customer_profile_dataset;
    ELSEIF table_number = 2  THEN select * from products_dataset_1 ;
    ELSEIF table_number =3  THEN select * from purchase_history_dataset ; 
    ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This table_number out of range .';
END IF ;
END $$
 delimiter ;

call calling_table(3);
-- insights from the table 
DELETE FROM purchase_history_dataset
WHERE (customer_id, purchase_id, purchase_date_m, purchase_time_m) IN (
    SELECT customer_id, purchase_id, purchase_date_m, purchase_time_m
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY customer_id, purchase_id, purchase_date_m ORDER BY purchase_time_m) AS row_num
        FROM purchase_history_dataset
    ) AS sub
    WHERE row_num > 1 
); -- for the checking of the duplicates 

-- the customerid and their product_name and the purchase_count 
SELECT 
    customer_id,
    purchase_id,
    quantity,
    SUM(quantity) OVER (PARTITION BY customer_id ORDER BY purchase_id) AS rolling_count
FROM 
    purchase_history_dataset;
-- getting  the product that is max puurchase by the customer 
SELECT 
    phd.customer_id AS customer_id,
    cpd.first_name AS customer_name ,
    pd.product_name AS product_name,
    MAX(phd.quantity) AS max_product_purchased
FROM 
    purchase_history_dataset phd
INNER JOIN 
    products_dataset_1 pd 
    ON phd.product_id = pd.product_id
INNER JOIN 
	customer_profile_dataset cpd
    ON phd.customer_id = cpd.customer_id 
GROUP BY 
    phd.customer_id,
    pd.product_name
ORDER BY 
    max_product_purchased DESC,
    customer_id ASC;
    -- sorting the customer_on the basis of veg non and the dairy purchase 
   SELECT 
    category, 
    COUNT(*) AS max_product_purchase
FROM 
    products_dataset_1
GROUP BY 
    category
ORDER BY 
    max_product_purchase DESC;
   
-- category with the highest revenue 
SELECT 
    pd1.category AS category,
    SUM(total_amount) AS total_revenue_per_category
FROM 
    products_dataset_1 pd1
INNER JOIN 
    purchase_history_dataset phd 
    ON pd1.product_id = phd.product_id
GROUP BY 
    pd1.category
ORDER BY 
    total_revenue_per_category DESC;
  


   -- Product Variety: Count how many unique products are available in each category.
SELECT 
    category, 
    product_name, 
    COUNT(*) AS total_count_per_category_per_product
FROM 
    products_dataset_1
GROUP BY 
    category, 
    product_name
ORDER BY 
    total_count_per_category_per_product DESC;
    -- per year total sales of the  each product product 
   SELECT 
    product_name,
    YEAR(purchase_date_m) AS year_,
    SUM(phd.total_amount) AS total_amount
FROM 
    products_dataset_1 pd1
INNER JOIN 
    purchase_history_dataset phd 
    ON pd1.product_id = phd.product_id
GROUP BY 
    YEAR(purchase_date_m), 
    product_name
ORDER BY 
    product_name, 
    year_;
    --  which brand is doing the great with which product_name  and its category
SELECT 
    brand,
    product_name,
    total_amount
FROM (
    SELECT 
        brand,
        product_name,
        SUM(total_amount) AS total_amount,
        RANK() OVER (PARTITION BY brand ORDER BY SUM(total_amount) DESC) AS rank_number
    FROM 
        products_dataset_1 pd1
    INNER JOIN 
        purchase_history_dataset phd 
        ON pd1.product_id = phd.product_id
    GROUP BY 
        brand, product_name
) AS sub
WHERE 
    rank_number = 1;
    -- Which brands generate the most revenue?
    SELECT 
    brand, 
    SUM(total_amount) AS total_revenue_per_brand
FROM 
    products_dataset_1 pd1
INNER JOIN 
    purchase_history_dataset phd 
    ON pd1.product_id = phd.product_id
GROUP BY 
    brand
ORDER BY 
    total_revenue_per_brand DESC;
-- customer per state PER CITY THE total customer count only 3 
SELECT 
    state, city ,
    COUNT(*) AS customer_count_per_city
FROM 
    customer_profile_dataset
GROUP BY 
    state,city
ORDER BY 
    customer_count_per_city DESC LIMIT 3; 
    -- the ppl on the top city in the texas purchase what the most product 
   select* from (SELECT 
    sub1.city,
    pd1.product_name,
    COUNT(*) AS count_per_product,
    RANK() OVER (PARTITION BY sub1.city ORDER BY COUNT(*) DESC) AS rank_per_city
FROM (
    SELECT 
        sub.customer_id, 
        sub.city, 
        phd.product_id
    FROM (
        SELECT 
            customer_id, 
            city
        FROM 
            customer_profile_dataset 
        WHERE 
            state = 'TX' 
            AND city IN ('Chicago', 'San Antonio', 'Philadelphia')
    ) AS sub
    INNER JOIN 
        purchase_history_dataset phd 
        ON sub.customer_id = phd.customer_id
) AS sub1
INNER JOIN 
    products_dataset_1 pd1 
    ON sub1.product_id = pd1.product_id
GROUP BY 
    sub1.city, pd1.product_name
ORDER BY 
    sub1.city, rank_per_city) as sub2 where rank_per_city = 1  order by city;
    -- count of the age_group in the retail_sales 
    
   SELECT group_age ,count(*) from (SELECT 
    sub.age, 
    CASE 
        WHEN sub.age <= 20 THEN 'TEENAGER'
        WHEN sub.age > 20 AND sub.age <= 50 THEN 'MIDDLE AGED'
        WHEN sub.age > 50 THEN 'ADULT'
    END AS group_age 
FROM (
    SELECT 
        customer_id, 
        first_name, 
        last_name, 
        ROUND(DATEDIFF(CURRENT_DATE, date_of_birth) / 365) AS age  
    FROM customer_profile_dataset
) AS sub) As sub1 group by sub1.group_age;
-- products purchased  by the each category 
    SELECT 
    sub1.group_age,
    pd.product_name,
    COUNT(*) AS age_group_purchase
FROM (
    SELECT 
        sub.customer_id,
        phd.product_id,
        CASE 
            WHEN sub.age <= 20 THEN 'TEENAGER'
            WHEN sub.age > 20 AND sub.age <= 50 THEN 'MIDDLE AGED'
            WHEN sub.age > 50 THEN 'ADULT'
        END AS group_age
    FROM (
        SELECT 
            customer_id, 
            first_name, 
            last_name, 
            ROUND(DATEDIFF(CURRENT_DATE, date_of_birth) / 365) AS age  
        FROM 
            customer_profile_dataset
    ) AS sub
    INNER JOIN 
        purchase_history_dataset phd 
        ON sub.customer_id = phd.customer_id
) AS sub1
INNER JOIN 
    products_dataset_1 pd 
    ON sub1.product_id = pd.product_id
GROUP BY 
    sub1.group_age,
    pd.product_name
ORDER BY 
    age_group_purchase DESC;
