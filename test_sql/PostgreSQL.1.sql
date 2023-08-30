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