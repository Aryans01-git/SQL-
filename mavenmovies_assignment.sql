-- SECTION 1: SQL BASICS

CREATE TABLE employees (
    emp_id INT NOT NULL PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    age INT CHECK (age >= 18),
    email VARCHAR(255) UNIQUE,
    salary DECIMAL(10, 2) DEFAULT 30000.00
);

ALTER TABLE employees ADD CONSTRAINT age_check CHECK (age >= 18);
ALTER TABLE employees DROP CHECK age_check;

-- Violating constraint
INSERT INTO employees (emp_id, emp_name, age) VALUES (1, 'John', 16);

-- Modifying table
ALTER TABLE products ADD PRIMARY KEY (product_id);
ALTER TABLE products MODIFY price DECIMAL(10, 2) DEFAULT 50.00;

-- JOINS EXAMPLES
SELECT student_name, class_name FROM students INNER JOIN classes ON students.class_id = classes.class_id;
SELECT o.order_id, c.customer_name, p.product_name FROM products p LEFT JOIN orders o ON p.product_id = o.product_id LEFT JOIN customers c ON o.customer_id = c.customer_id;
SELECT p.product_name, SUM(o.amount) AS total_sales FROM products p INNER JOIN orders o ON p.product_id = o.product_id GROUP BY p.product_name;
SELECT o.order_id, c.customer_name, o.quantity FROM orders o INNER JOIN customers c ON o.customer_id = c.customer_id INNER JOIN products p ON o.product_id = p.product_id;

-- SECTION 2: SQL COMMANDS (MAVENMOVIES)

SELECT * FROM actor;
SELECT * FROM customer;
SELECT DISTINCT country FROM country;
SELECT * FROM customer WHERE active = 1;
SELECT rental_id FROM rental WHERE customer_id = 1;
SELECT * FROM film WHERE rental_duration > 5;
SELECT COUNT(*) FROM film WHERE replacement_cost BETWEEN 15 AND 20;
SELECT COUNT(DISTINCT first_name) FROM actor;
SELECT * FROM customer LIMIT 10;
SELECT * FROM customer WHERE first_name LIKE 'b%' LIMIT 3;
SELECT title FROM film WHERE rating = 'G' LIMIT 5;
SELECT * FROM customer WHERE first_name LIKE 'a%';
SELECT * FROM customer WHERE first_name LIKE '%a';
SELECT city FROM city WHERE city LIKE 'a%a' LIMIT 4;
SELECT * FROM customer WHERE first_name LIKE '%NI%';
SELECT * FROM customer WHERE first_name LIKE '_r%';
SELECT * FROM customer WHERE first_name LIKE 'a%' AND LENGTH(first_name) >= 5;
SELECT * FROM customer WHERE first_name LIKE 'a%o';
SELECT * FROM film WHERE rating IN ('PG', 'PG-13');
SELECT * FROM film WHERE length BETWEEN 50 AND 100;
SELECT * FROM actor LIMIT 50;
SELECT DISTINCT film_id FROM inventory;

-- SECTION 3: FUNCTIONS

SELECT COUNT(*) AS total_rentals FROM rental;
SELECT AVG(DATEDIFF(return_date, rental_date)) AS avg_duration FROM rental;
SELECT UPPER(first_name), UPPER(last_name) FROM customer;
SELECT rental_id, MONTH(rental_date) AS rental_month FROM rental;
SELECT customer_id, COUNT(*) AS rental_count FROM rental GROUP BY customer_id;
SELECT store_id, SUM(amount) AS total_revenue FROM payment GROUP BY store_id;

-- Rentals by category
SELECT c.name AS category, COUNT(*) AS rental_count
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name;

-- Avg rental rate by language
SELECT l.name AS language, AVG(f.rental_rate) AS avg_rate
FROM film f
JOIN language l ON f.language_id = l.language_id
GROUP BY l.name;

-- SECTION 4: JOINS

-- Movie title and customer name
SELECT f.title, c.first_name, c.last_name
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN customer c ON r.customer_id = c.customer_id;

-- Actor of a film
SELECT a.first_name, a.last_name
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
WHERE f.title = 'Gone with the Wind';

-- Customer total spent
SELECT c.first_name, c.last_name, SUM(p.amount) AS total_spent
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id;

-- London rentals
SELECT c.first_name, c.last_name, f.title
FROM customer c
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN rental r ON c.customer_id = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
WHERE ci.city = 'London';

-- SECTION 5: ADVANCED JOINS

-- Top 5 rented movies
SELECT f.title, COUNT(*) AS rental_count
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
GROUP BY f.title
ORDER BY rental_count DESC
LIMIT 5;

-- Customers who rented from both stores
SELECT customer_id
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
GROUP BY customer_id
HAVING COUNT(DISTINCT i.store_id) = 2;

-- SECTION 6: WINDOW FUNCTIONS

SELECT customer_id, SUM(amount) AS total_spent,
       RANK() OVER (ORDER BY SUM(amount) DESC) AS rank
FROM payment
GROUP BY customer_id;

SELECT f.title, p.payment_date,
       SUM(p.amount) OVER (PARTITION BY f.film_id ORDER BY p.payment_date) AS cum_revenue
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id;

SELECT film_id, title, length,
       AVG(rental_duration) OVER (PARTITION BY length) AS avg_duration
FROM film;

-- Top 3 movies by rental count per category
WITH film_rentals AS (
  SELECT fc.category_id, f.title, COUNT(*) AS rental_count,
         RANK() OVER (PARTITION BY fc.category_id ORDER BY COUNT(*) DESC) AS rank
  FROM rental r
  JOIN inventory i ON r.inventory_id = i.inventory_id
  JOIN film f ON i.film_id = f.film_id
  JOIN film_category fc ON f.film_id = fc.film_id
  GROUP BY fc.category_id, f.title
)
SELECT * FROM film_rentals WHERE rank <= 3;

-- Deviation from average rentals
WITH rental_counts AS (
  SELECT customer_id, COUNT(*) AS rental_count FROM rental GROUP BY customer_id
)
SELECT customer_id, rental_count,
       rental_count - AVG(rental_count) OVER () AS diff_from_avg
FROM rental_counts;

-- Monthly revenue
SELECT MONTH(payment_date) AS month, SUM(amount) AS revenue
FROM payment
GROUP BY MONTH(payment_date);

-- Top 20% customers
WITH ranked_customers AS (
  SELECT customer_id, SUM(amount) AS total_spent,
         NTILE(5) OVER (ORDER BY SUM(amount) DESC) AS spending_percentile
  FROM payment
  GROUP BY customer_id
)
SELECT * FROM ranked_customers WHERE spending_percentile = 1;

-- Running total per category
WITH cat_rentals AS (
  SELECT c.name, COUNT(*) AS rental_count
  FROM rental r
  JOIN inventory i ON r.inventory_id = i.inventory_id
  JOIN film f ON i.film_id = f.film_id
  JOIN film_category fc ON f.film_id = fc.film_id
  JOIN category c ON fc.category_id = c.category_id
  GROUP BY c.name
)
SELECT name, rental_count,
       SUM(rental_count) OVER (ORDER BY name) AS running_total
FROM cat_rentals;

-- SECTION 7: CTEs

-- Actor film count
WITH actor_films AS (
  SELECT actor_id, COUNT(film_id) AS film_count FROM film_actor GROUP BY actor_id
)
SELECT a.first_name, a.last_name, af.film_count
FROM actor a
JOIN actor_films af ON a.actor_id = af.actor_id;

-- Film info
WITH film_info AS (
  SELECT f.title, l.name AS language, f.rental_rate
  FROM film f
  JOIN language l ON f.language_id = l.language_id
)
SELECT * FROM film_info;

-- Customer total payments
WITH customer_payments AS (
  SELECT customer_id, SUM(amount) AS total_spent
  FROM payment
  GROUP BY customer_id
)
SELECT * FROM customer_payments;

-- Ranked films
WITH ranked_films AS (
  SELECT title, rental_duration,
         RANK() OVER (ORDER BY rental_duration DESC) AS rank
  FROM film
)
SELECT * FROM ranked_films;

-- Frequent customers
WITH frequent_customers AS (
  SELECT customer_id FROM rental
  GROUP BY customer_id HAVING COUNT(*) > 2
)
SELECT c.* FROM customer c
JOIN frequent_customers f ON c.customer_id = f.customer_id;

-- Monthly rentals
WITH monthly_rentals AS (
  SELECT MONTH(rental_date) AS month, COUNT(*) AS total_rentals
  FROM rental
  GROUP BY MONTH(rental_date)
)
SELECT * FROM monthly_rentals;

-- Actor pairs
WITH actor_pairs AS (
  SELECT fa1.actor_id AS actor1, fa2.actor_id AS actor2, fa1.film_id
  FROM film_actor fa1
  JOIN film_actor fa2 ON fa1.film_id = fa2.film_id AND fa1.actor_id < fa2.actor_id
)
SELECT a1.first_name AS actor1_fn, a2.first_name AS actor2_fn, film_id
FROM actor_pairs ap
JOIN actor a1 ON ap.actor1 = a1.actor_id
JOIN actor a2 ON ap.actor2 = a2.actor_id;

