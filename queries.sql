-- считает общее количество покупателей в таблице customers
SELECT COUNT(*) AS customers_count
FROM customers;

-- топ-10 продавцов по суммарной выручке за все время.
-- показывает имя и фамилию продавца, количество сделок и общую выручку.
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales s
JOIN employees e
    ON s.sales_person_id = e.employee_id
JOIN products p
    ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    TRIM(e.first_name),
    TRIM(e.last_name)
ORDER BY income DESC, seller ASC
LIMIT 10;


-- продавцы, у которых средняя выручка за сделку ниже
-- средней выручки за сделку по всем продавцам.
-- показывает имя и фамилию продавца и среднюю выручку за сделку.
WITH seller_avg AS (
    SELECT
        e.employee_id,
        CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
        AVG(s.quantity * p.price) AS avg_income
    FROM sales s
    JOIN employees e
        ON s.sales_person_id = e.employee_id
    JOIN products p
        ON s.product_id = p.product_id
    GROUP BY
        e.employee_id,
        TRIM(e.first_name),
        TRIM(e.last_name)
)
SELECT
    seller,
    FLOOR(avg_income) AS average_income
FROM seller_avg
WHERE avg_income < (
    SELECT AVG(avg_income)
    FROM seller_avg
)
ORDER BY average_income ASC, seller ASC;


-- выручка по каждому продавцу и дню недели.
-- показывает имя и фамилию продавца, день недели на английском языке и суммарную выручку по этому дню недели.
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    LOWER(TO_CHAR(s.sale_date, 'FMDay')) AS day_of_week,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales s
JOIN employees e
    ON s.sales_person_id = e.employee_id
JOIN products p
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