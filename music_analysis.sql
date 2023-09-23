-- EASY

--1 Who is the senior most employee based on job title ?

SELECT TOP 1 title, last_name, first_name
FROM employee
ORDER BY levels DESC;

--2 Which countries have the most Invoices ?

SELECT TOP 1 WITH TIES COUNT(*) AS c, billing_country
FROM invoice
GROUP BY billing_country
ORDER BY c DESC;


--3 What are top 3 values of total invoice 

SELECT TOP 3 total
FROM invoice
ORDER BY total DESC;


--4 Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. Write a QUERY
-- that returns one city that has the highest sum of invoice totals. Return both the city name and sum of all invoice totals

SELECT TOP 1 billing_city, SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC;


--5 Who is the best customer? The customer who has spent the most money will be declared the best customer. 
-- Write a query that returns the person who has spent the most money.

SELECT TOP 1 WITH TIES c.customer_id, c.first_name, c.last_name, SUM(total) AS total_spending
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spending DESC;

-- MODRATE

-- Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
-- Return your list ordered alphabetically by email starting with A.



SELECT DISTINCT TOP (100) PERCENT c.email, c.first_name, c.last_name, g.name AS Genre
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email;


-- Q2: Let's invite the artists who have written the most rock music in our dataset. 
-- Write a query that returns the Artist name and total track count of the top 10 rock bands. 

SELECT TOP 10 a.artist_id, a.name AS ArtistName, COUNT(t.track_id) AS TrackCount
FROM track t
JOIN album al ON t.album_id = al.album_id
JOIN artist a ON al.artist_id = a.artist_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY a.artist_id, a.name
ORDER BY TrackCount DESC;


-- Q3: Return all the track names that have a song length longer than the average song length. 
-- Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. 

SELECT name, milliseconds
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC;

-- HARD

-- Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

-- Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
-- which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
-- Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
-- so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
-- for each artist. 

WITH ArtistSales AS (
    SELECT a.artist_id, a.name AS artist_name, SUM(il.unit_price * il.quantity) AS total_sales
    FROM invoice_line il
    JOIN track t ON t.track_id = il.track_id
    JOIN album al ON al.album_id = t.album_id
    JOIN artist a ON a.artist_id = al.artist_id
    GROUP BY a.artist_id, a.name
    ORDER BY total_sales DESC
    OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
)
SELECT c.customer_id, c.first_name, c.last_name, ArtistSales.artist_name, SUM(il.unit_price * il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN ArtistSales ON al.artist_id = ArtistSales.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, ArtistSales.artist_name
ORDER BY amount_spent DESC;



--  Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
-- with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
-- the maximum number of purchases is shared return all Genres. 

-- Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. 



WITH GenrePopularity AS (
    SELECT c.country, g.name AS genre_name, COUNT(il.quantity) AS purchase_count,
           ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS RowNo
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.name
)
SELECT gp.country, gp.genre_name
FROM GenrePopularity gp
WHERE gp.RowNo = 1
UNION ALL
SELECT gp.country, gp.genre_name
FROM GenrePopularity gp
WHERE gp.RowNo > 1
    AND NOT EXISTS (
        SELECT 1
        FROM GenrePopularity sub
        WHERE sub.country = gp.country AND sub.RowNo = 1
    );




-- Q3: Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount. 

-- Steps to Solve:  Similar to the above question. There are two parts in question- 
-- first find the most spent on music for each country and second filter the data for respective customers. 



WITH CustomerSpending AS (
    SELECT c.customer_id, c.first_name, c.last_name, c.country, SUM(i.total) AS total_spent,
           RANK() OVER (PARTITION BY c.country ORDER BY SUM(i.total) DESC) AS spending_rank
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.country
)
SELECT cs.country, cs.first_name, cs.last_name, cs.total_spent
FROM CustomerSpending cs
WHERE cs.spending_rank = 1
UNION ALL
SELECT cs.country, cs.first_name, cs.last_name, cs.total_spent
FROM CustomerSpending cs
WHERE cs.spending_rank > 1
    AND NOT EXISTS (
        SELECT 1
        FROM CustomerSpending sub
        WHERE sub.country = cs.country AND sub.spending_rank = 1
    );



