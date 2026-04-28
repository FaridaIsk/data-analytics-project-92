-- считает общее количество покупателей в таблице customers
SELECT COUNT(*) AS customers_count
FROM customers;

-- топ-10 продавцов по суммарной выручке за все время
-- показывает продавца, количество сделок и общую выручку
SELECT
    CONCAT(
        TRIM(e.first_name),
        ' ',
        TRIM(e.last_name)
    ) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    TRIM(e.first_name),
    TRIM(e.last_name)
ORDER BY income DESC, seller ASC
LIMIT 10;


-- продавцы со средней выручкой ниже общей средней
-- показывает продавца и среднюю выручку за сделку
SELECT
    CONCAT(
        TRIM(e.first_name),
        ' ',
        TRIM(e.last_name)
    ) AS seller,
    FLOOR(AVG(s.quantity * p.price)) AS average_income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    TRIM(e.first_name),
    TRIM(e.last_name)
HAVING
    AVG(s.quantity * p.price) < (
        SELECT AVG(s2.quantity * p2.price)
        FROM sales AS s2
        INNER JOIN products AS p2
            ON s2.product_id = p2.product_id
    )
ORDER BY average_income ASC, seller ASC;


-- выручка по каждому продавцу и дню недели
-- показывает продавца, день недели и суммарную выручку
SELECT
    CONCAT(
        TRIM(e.first_name),
        ' ',
        TRIM(e.last_name)
    ) AS seller,
    LOWER(TO_CHAR(s.sale_date, 'FMDay')) AS day_of_week,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    TRIM(e.first_name),
    TRIM(e.last_name),
    EXTRACT(ISODOW FROM s.sale_date),
    LOWER(TO_CHAR(s.sale_date, 'FMDay'))
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),
    seller ASC;


-- количество покупателей по возрастным группам
-- показывает три категории и количество покупателей
WITH age_groups AS (
    SELECT
        CAST('16-25' AS TEXT) AS age_category,
        1 AS sort_order
    UNION ALL
    SELECT
        CAST('26-40' AS TEXT) AS age_category,
        2 AS sort_order
    UNION ALL
    SELECT
        CAST('40+' AS TEXT) AS age_category,
        3 AS sort_order
),

classified_customers AS (
    SELECT
        CASE
            WHEN age BETWEEN 16 AND 25 THEN '16-25'
            WHEN age BETWEEN 26 AND 40 THEN '26-40'
            WHEN age > 40 THEN '40+'
        END AS age_category
    FROM customers
    WHERE age IS NOT NULL
),

age_counts AS (
    SELECT
        cc.age_category,
        COUNT(*) AS age_count
    FROM classified_customers AS cc
    WHERE cc.age_category IS NOT NULL
    GROUP BY cc.age_category
)

SELECT
    ag.age_category,
    COALESCE(ac.age_count, 0) AS age_count
FROM age_groups AS ag
LEFT JOIN age_counts AS ac
    ON ag.age_category = ac.age_category
ORDER BY ag.sort_order;


-- количество уникальных покупателей и выручка по месяцам
-- показывает месяц, число покупателей и суммарную выручку
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY selling_month ASC;


-- покупатели, пришедшие через специальное предложение
-- специальное предложение: первая покупка товара с ценой 0
WITH ranked_sales AS (
    SELECT
        s.customer_id,
        p.price,
        CONCAT(
            TRIM(c.first_name),
            ' ',
            TRIM(c.last_name)
        ) AS customer,
        CAST(s.sale_date AS DATE) AS sale_date,
        CONCAT(
            TRIM(e.first_name),
            ' ',
            TRIM(e.last_name)
        ) AS seller,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.sale_date, s.sales_id
        ) AS rn
    FROM sales AS s
    INNER JOIN customers AS c
        ON s.customer_id = c.customer_id
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
)

SELECT
    customer,
    sale_date,
    seller
FROM ranked_sales
WHERE
    rn = 1
    AND price = 0
ORDER BY customer_id;