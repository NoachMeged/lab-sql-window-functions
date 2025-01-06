-- Rank films by their length and create an output table that includes the title, length, and rank columns only. Filter out any rows with null or zero values in the length column.

SELECT title, length, RANK() OVER (ORDER BY length DESC) AS `rank`
FROM film;

-- Rank films by length within the rating category and create an output table that includes the title, length, rating and rank columns only. Filter out any rows with null or zero values in the length column.

SELECT title, length, rating, RANK() OVER (PARTITION BY rating ORDER BY length DESC) AS `rank`
FROM film
WHERE length IS NOT NULL AND length > 0;

-- Produce a list that shows for each film in the Sakila database, the actor or actress who has acted in the greatest number of films, as well as the total number of films in which they have acted. Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.


-- the actor or actress who has acted in the greatest number
WITH actor_film_count AS (
    SELECT fa.actor_id, a.first_name, a.last_name, COUNT(fa.film_id) AS total_films
    FROM film_actor fa
    JOIN actor a ON fa.actor_id = a.actor_id
    GROUP BY fa.actor_id, a.first_name, a.last_name
),

-- Stap 2: Zoek de acteur met de meeste films voor elke film
film_top_actor AS (
    SELECT f.film_id, f.title, afc.first_name, afc.last_name, afc.total_films
    FROM film f
    JOIN film_actor fa ON f.film_id = fa.film_id
    JOIN actor_film_count afc ON fa.actor_id = afc.actor_id
    ORDER BY f.film_id, afc.total_films DESC
)

-- Stap 3: Selecteer het resultaat
SELECT DISTINCT film_id, title, first_name, last_name, total_films
FROM film_top_actor;


-- Step 1. Retrieve the number of monthly active customers, i.e., the number of unique customers who rented a movie in each month.
WITH monthly_active_customers AS (
    SELECT
        DATE_FORMAT(r.rental_date, '%Y-%m') AS month, -- Format month as 'YYYY-MM'
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM rental r
    GROUP BY DATE_FORMAT(r.rental_date, '%Y-%m') -- Group by the formatted month
)
SELECT * FROM monthly_active_customers;


-- Step 2: Number of active customers in the previous month
WITH monthly_active_customers AS (
    SELECT
        EXTRACT(YEAR_MONTH FROM r.rental_date) AS month,
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM rental r
    GROUP BY EXTRACT(YEAR_MONTH FROM r.rental_date)
),
monthly_with_previous AS (
    SELECT
        month,
        active_customers,
        LEAD(active_customers) OVER (ORDER BY month) AS previous_month_active_customers
    FROM monthly_active_customers
)
SELECT * FROM monthly_with_previous;

-- Step 3: Calculate the percentage change in active customers
WITH monthly_active_customers AS (
    SELECT
        EXTRACT(YEAR_MONTH FROM r.rental_date) AS month,
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM rental r
    GROUP BY EXTRACT(YEAR_MONTH FROM r.rental_date)
),
monthly_with_previous AS (
    SELECT
        month,
        active_customers,
        LEAD(active_customers) OVER (ORDER BY month) AS previous_month_active_customers
    FROM monthly_active_customers
)
SELECT 
    month,
    active_customers,
    previous_month_active_customers,
    ROUND(((active_customers - previous_month_active_customers) / previous_month_active_customers) * 100, 2) AS percentage_change
FROM monthly_with_previous;


-- Step 4: Calculate the number of retained customers
WITH monthly_active_customers AS (
    SELECT
        EXTRACT(YEAR_MONTH FROM r.rental_date) AS month,
        r.customer_id
    FROM rental r
    GROUP BY EXTRACT(YEAR_MONTH FROM r.rental_date), r.customer_id
),
previous_month_active_customers AS (
    SELECT
        customer_id,
        EXTRACT(YEAR_MONTH FROM r.rental_date) AS previous_month
    FROM rental r
    GROUP BY EXTRACT(YEAR_MONTH FROM r.rental_date), r.customer_id
),
retained_customers AS (
    SELECT
        mac.month,
        COUNT(DISTINCT mac.customer_id) AS retained_customers
    FROM monthly_active_customers mac
    JOIN previous_month_active_customers pmac
        ON mac.customer_id = pmac.customer_id
        AND mac.month = (pmac.previous_month + 1) -- Previous month and current month
    GROUP BY mac.month
)
SELECT * FROM retained_customers;
