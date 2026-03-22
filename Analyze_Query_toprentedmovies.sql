--Shows a list of top rented movies for the last 30 days 

Explain (ANALYZE,BUFFERS)
SELECT
    f.film_id,
    f.title,
    COUNT(r.rental_id)                                           AS total_rentals
FROM bluebox.film f
JOIN bluebox.inventory  i  ON i.film_id      = f.film_id
JOIN bluebox.rental     r  ON r.inventory_id = i.inventory_id
GROUP BY f.film_id, f.title
ORDER BY total_rentals DESC NULLS LAST
limit 25;
