-- Exported from QuickDBD: https://www.quickdatabasediagrams.com/
-- Link to schema: https://app.quickdatabasediagrams.com/#/d/Eoypbj
-- NOTE! If you have used non-SQL datatypes in your design, you will have to change these here.

-- create tables for merchant and card holder data, add Constraints as well as Foreign and Primary Keys


CREATE TABLE "card_holder" (
    "id" INT   NOT NULL,
    "name" VARCHAR(60)   NOT NULL,
    CONSTRAINT "pk_card_holder" PRIMARY KEY (
        "id"
     )
);

CREATE TABLE "credit_card" (
    "card" VARCHAR(20)   NOT NULL,
    "cardholder_id" INT   NOT NULL,
    CONSTRAINT "pk_credit_card" PRIMARY KEY (
        "card"
     )
);

CREATE TABLE "merchant" (
    "id" INT   NOT NULL,
    "name" VARCHAR(60)   NOT NULL,
    "id_merchant_category" INT   NOT NULL,
    CONSTRAINT "pk_merchant" PRIMARY KEY (
        "id"
     )
);

CREATE TABLE "merchant_category" (
    "id" INT   NOT NULL,
    "name" VARCHAR(20)   NOT NULL,
    CONSTRAINT "pk_merchant_category" PRIMARY KEY (
        "id"
     )
);

CREATE TABLE "transaction" (
    "id" INT   NOT NULL,
    "date" TIMESTAMP   NOT NULL,
    "amount" FLOAT   NOT NULL,
    "card" VARCHAR(20)   NOT NULL,
    "id_merchant" INT   NOT NULL,
    CONSTRAINT "pk_transaction" PRIMARY KEY (
        "id"
     )
);

ALTER TABLE "credit_card" ADD CONSTRAINT "fk_credit_card_cardholder_id" FOREIGN KEY("cardholder_id")
REFERENCES "card_holder" ("id");

ALTER TABLE "merchant" ADD CONSTRAINT "fk_merchant_id_merchant_category" FOREIGN KEY("id_merchant_category")
REFERENCES "merchant_category" ("id");

ALTER TABLE "transaction" ADD CONSTRAINT "fk_transaction_card" FOREIGN KEY("card")
REFERENCES "credit_card" ("card");

ALTER TABLE "transaction" ADD CONSTRAINT "fk_transaction_id_merchant" FOREIGN KEY("id_merchant")
REFERENCES "merchant" ("id");

-- queries to identify possible fraud

-- group transactions by cardholder

SELECT card_holder.name, credit_card.card, transaction.date, transaction.amount, merchant.name
   , merchant_category.name
FROM transaction
JOIN credit_card ON credit_card.card = transaction.card
JOIN card_holder ON card_holder.id = credit_card.cardholder_id
JOIN merchant ON merchant.id = transaction.id_merchant
JOIN merchant_category ON merchant_category.id = merchant.id_merchant_category
ORDER BY card_holder.name

-- count suspicious transactions (<$2.00)

SELECT COUNT(transaction.amount)
FROM transaction
WHERE transaction.amount < 2
ORDER BY 

-- check total transactions

SELECT COUNT(transaction)
FROM transaction

-- ANALYSIS
-- of 3500 transactions, 10% (350) are less than $2.00. I do not find great concern here.

-- top 100 highest transactions between seven and nine in the morning

SELECT *
FROM transaction
WHERE date_part('hour', transaction.date) >= 7 AND date_part('hour', transaction.date) <= 9
ORDER BY amount DESC
LIMIT 100;

-- of the highest 100 transactions between 7 and 9 am, no transactions causes concern

-- TOP 5 merchants prone to being hacked with small transactions

SELECT merchant.name, merchant_category.name, COUNT(transaction.amount)
FROM transaction
JOIN merchant on merchant.id = transaction.id_merchant
JOIN merchant_category ON merchant_category.id = merchant.id_merchant_category
WHERE transaction.amount < 2
GROUP BY merchant.name, merchant_category.name
ORDER BY COUNT(transaction.amount) DESC
LIMIT 5;

-- Create Query Views

CREATE VIEW transactions_per_card_holder AS
SELECT ch.name, cc.card, t.date, t.amount, m.name AS merchant, mc.name AS category
FROM transaction as t
JOIN credit_card AS cc ON cc.card = t.card
JOIN card_holder AS ch ON ch.id = cc.cardholder_id
JOIN merchant AS m ON m.id = t.id_merchant
JOIN merchant_category AS mc ON mc.id = m.id_merchant_category
ORDER BY ch.name
   
CREATE VIEW micro_transactions AS
SELECT * 
FROM transaction
WHERE transaction.amount < 2
ORDER BY transaction.card, transaction.amount DESC

CREATE VIEW count_micro_transactions AS
SELECT COUNT(transaction.amount)
FROM transaction
WHERE transaction.amount < 2

CREATE VIEW am_morning_high_transactions AS
SELECT * 
FROM transaction
WHERE date_part('hour', transaction.date) >= 7 AND date_part('hour', transaction.date) <= 9
ORDER BY amount DESC
LIMIT 100;

CREATE VIEW count_morning_high_micro_transactions AS
SELECT COUNT(transaction.amount)
FROM transaction
WHERE transaction.amount < 2
AND date_part('hour', transaction.date) >= 7
AND date_part('hour', transaction.date) <= 9

CREATE VIEW top_5_most_hackable_merchants AS
SELECT m.name AS merchant, mc.name AS category, COUNT(t.amount) 
   AS micro_transactions
FROM transaction as t
JOIN merchant AS m ON m.id = t.id_merchant
JOIN merchant_category AS mc ON mc.id = m.id_merchant_category
WHERE t.amount < 2
GROUP BY m.name, mc.name
ORDER BY micro_transactions DESC
LIMIT 5;