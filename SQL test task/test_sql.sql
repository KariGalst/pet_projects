-- создание и заполнение данными таблицы Users

CREATE TABLE Users(
  	userId  serial PRIMARY KEY,
	age int
);

INSERT INTO Users (age)
SELECT FLOOR(random() * (75 - 18 + 1) + 18)::int
FROM generate_series(1, 100);

-- создание и заполнение данными таблицы Purchases

CREATE TABLE Purchases(
 	purchaseId serial PRIMARY KEY,
  	userId int,
  	itemId int,
  	date DATE
);
  
INSERT INTO Purchases (date)
SELECT * FROM generate_series('2021-01-01'::date, '2023-12-31'::date, '3 days') AS date;

Update Purchases
SET
userid = FLOOR(random() * (100 - 1 + 1) + 1),
itemId = FLOOR(random() * (50 - 1 + 1) + 1);

-- создание и заполнение данными таблицы Items

CREATE TABLE Items(
 	itemId serial PRIMARY KEY,
  	price int
);

INSERT INTO Items (price)
SELECT FLOOR(RANDOM() * (10000 - 150 + 1) + 150)::int
FROM generate_series(1, 50);

-- А) средняя сумма покупок в месяц для возрастных категорий от 18 до 25 лет и от 26 до 35 лет

WITH
profiles AS
(
SELECT *,
	CASE
    	WHEN  age >= 18 AND age <= 25 THEN '18-25'
        WHEN  age >= 26 AND age <= 35 THEN '26-35'
        ELSE 'others'
	END AS age_category,
  	date_trunc('month', date) AS month_tr
FROM purchases
JOIN users USING(userid)
JOIN items USING(itemid)
),

month_cost AS
(
  SELECT age_category, month_tr, AVG(price) AS avg_cost
  FROM profiles
  WHERE age_category <> 'others'
  GROUP BY age_category, month_tr
)

SELECT age_category, ROUND(AVG(avg_cost)) AS avg_month_cost
FROM month_cost
GROUP BY age_category;

-- Б) в каком месяце года выручка от пользователей в возрастном диапазоне 35+ самая большая

WITH
profiles AS
(
SELECT *,
	CASE
    	WHEN  age >= 18 AND age <= 25 THEN '18-25'
        WHEN  age >= 26 AND age <= 35 THEN '26-35'
        ELSE 'others'
	END AS age_category,
  	date_trunc('month', date) AS month_tr,
  	EXTRACT(month FROM date) AS month_nmb
FROM purchases
JOIN users USING(userid)
JOIN items USING(itemid)
),

month_revenue AS
(
  SELECT DISTINCT
  	month_tr,
  	SUM(price) OVER (PARTITION BY month_tr) AS month_revenue,
  	month_nmb
  FROM profiles
  WHERE age_category = 'others'
)  

SELECT month_nmb, round(AVG(month_revenue)) AS avg_month_revenue
FROM month_revenue
GROUP BY month_nmb
ORDER BY avg_month_revenue DESC
LIMIT 1;

-- В) какой товар обеспечивает наибольший вклад в выручку за последний год

WITH
profiles AS
(
SELECT *,
	CASE
    	WHEN  age >= 18 AND age <= 25 THEN '18-25'
        WHEN  age >= 26 AND age <= 35 THEN '26-35'
        ELSE 'others'
	END AS age_category,
  	EXTRACT(YEAR FROM date) AS year_tr
FROM purchases
JOIN users USING(userid)
JOIN items USING(itemid)
)

SELECT itemid, SUM(price) AS item_revenue
FROM profiles
WHERE YEAR_tr = (SELECT MAX(year_tr) FROM profiles)
GROUP BY itemid
ORDER BY item_revenue DESC
LIMIT 1;

-- Г) топ-3 товаров по выручке и их доля в общей выручке за любой год
WITH
profiles AS
(
SELECT *,
	CASE
    	WHEN  age >= 18 AND age <= 25 THEN '18-25'
        WHEN  age >= 26 AND age <= 35 THEN '26-35'
        ELSE 'others'
	END AS age_category,
  	EXTRACT(YEAR FROM date) AS year_tr
FROM purchases
JOIN users USING(userid)
JOIN items USING(itemid)
),

item_revenue_list AS
(
SELECT itemid, year_tr, SUM(price) AS item_revenue,
	ROW_NUMBER() OVER (PARTITION BY year_tr ORDER BY SUM(price) DESC) AS rn
FROM profiles
GROUP BY itemid, year_tr
ORDER BY year_tr, rn
),

annual_revenue AS
(
   SELECT year_tr,
      SUM(price) AS annual_revenue
  FROM profiles
  GROUP BY year_tr
)

SELECT itemid, year_tr,
item_revenue,
round(100 * item_revenue / annual_revenue) AS annual_share
FROM annual_revenue
right JOIN item_revenue_list USING(year_tr)
WHERE rn <= 3
ORDER BY year_tr, item_revenue DESC;
