# IMDb Movie Analysis
## Questions and Answers

**Auther**: Nileaysh Baban Jadhav <br />
**Email**: nileshjadhav991@gmail.com <br />
**LinkedIn**: https://www.linkedin.com/in/nileaysh-jadhav <br />
-- Segment 1: Database - Tables, Columns, Relationships

-- What are the different tables in the database and how are they connected to each other in the database?
-- ERD



-- Find the total number of rows in each table of the schema.

select table_name, table_rows from information_schema.tables where table_schema = 'imdb';



-- Identify which columns in the movie table have null values.

with cte as
	(
    select * from information_schema.columns where table_name = 'movies' and table_schema = 'imdb'
    )
select column_name from cte
where is_nullable = 'yes';



-- Segment 2: Movie Release Trends

-- Determine the total number of movies released each year and analyse the month-wise trend.
-- 1)Movies number each year

select year, count(*) as movies_number from movies
group by year;

-- 2)Month wise trend

with cte as
(select id, title, month(date_published) as movie_month, year from movies)
select movie_month, year, count(id) as movies_number from cte
group by movie_month, year
order by year, movie_month;



-- Calculate the number of movies produced in the USA or India in the year 2019.

select count(id) as movies_number from movies
where year = 2019
and (country like '%USA%'
or country like '%India%');



-- Segment 3: Production Statistics and Genre Analysis

-- Retrieve the unique list of genres present in the dataset.

select distinct genre from genre;



-- Identify the genre with the highest number of movies produced overall.

select genre, count(movie_id) as movies_number from genre
group by genre
order by movies_number desc
limit 1;



-- Determine the count of movies that belong to only one genre.

select genre_count, count(id) as single_genre_movies_count from
(
	select m.id, count(g.genre) as genre_count from movies m
	join genre g on m.id = g.movie_id
	group by m.id
)t
group by genre_count
having genre_count = 1;



-- Calculate the average duration of movies in each genre.

select genre, avg(duration) as avg_duration from movies m
left join genre g on g.movie_id = m.id
group by genre
order by avg_duration desc;



-- Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced.

select rank_, genre, movies_number from 
(
	with cte as
	(
		select genre, count(id) as movies_number from movies m
		join genre g on g.movie_id = m.id
		group by genre
	)
	select *, rank() over(order by movies_number desc) as rank_ from cte
)t
where genre = 'Thriller'
;



-- Segment 4: Ratings Analysis and Crew Members

-- Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).

select
min(avg_rating) as low_rating, max(avg_rating) as top_rating,
min(total_votes) as low_votes, max(total_votes) as top_votes,
min(median_rating) as low_median_rating, max(median_rating) as top_median_rating
from ratings;



-- Identify the top 10 movies based on average rating.

select *, rank() over (order by avg_rating desc, total_votes desc) as rank_ from
(
	select m.title, r.avg_rating, r.total_votes from movies m
	join ratings r on r.movie_id = m.id
)t
limit 10;



-- Summarise the ratings table based on movie counts by median ratings.

select median_rating, count(movie_id) as movie_count from ratings
group by median_rating
order by median_rating desc;



-- Identify the production house that has produced the most number of hit movies (average rating > 8).

select m.production_company, sum(r.total_votes) as total_votes_sum, count(m.id) as hit_movies from movies m
left join ratings r on m.id = r.movie_id
where avg_rating > 8
and production_company !=''
group by production_company
order by hit_movies desc, total_votes_sum desc
limit 10;



-- Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes.

select g.genre, count(m.id) as movies_number from movies m
join genre g on g.movie_id = m.id
join ratings r on r.movie_id = m.id
where total_votes>1000
and year = 2017
and month(date_published) = 3
and country like '%USA%'
group by g.genre
order by movies_number desc;



-- Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.

select g.genre, group_concat(m.title) as movies_ from movies m
join genre g on m.id = g.movie_id
join ratings r on m.id = r.movie_id
where r.avg_rating > 8
and m.title like 'The %'
group by g.genre;



-- Segment 5: Crew Analysis

-- Identify the columns in the names table that have null values.

select 
sum(case when id is null then 1 else 0 end) as id_null_count,
sum(case when name is null then 1 else 0 end) as name_null_count,
sum(case when height is null then 1 else 0 end) as height_null_count,
sum(case when date_of_birth is null then 1 else 0 end) as birth_date_null_count,
sum(case when known_for_movies is null then 1 else 0 end) as known_for_movies_null_count from names;



-- Determine the top three directors in the top three genres with movies having an average rating > 8.

with top_three_genre as
(
	select count(distinct m.id) as number_of_movies, g.genre, rank() over(order by count(distinct m.id) desc) as genre_rank from
	movies m
	join genre g on m.id = g.movie_id
	join ratings r on m.id = r.movie_id
	where r.avg_rating > 8
	group by g.genre
),
director_genre as
(
	select dm.movie_id, g.genre, n.name, dm.name_id from director_mapping dm
	join names n on dm.name_id = n.id
	join ratings r on dm.movie_id = r.movie_id
	join genre g on g.movie_id = dm.movie_id
	where avg_rating > 8
)
select * from
(
	select genre, name as director_name, count(movie_id) as num_movies,
	row_number() over (partition by genre order by count(movie_id) desc) as director_rank
	from director_genre 
	where genre in (select distinct genre from top_three_genre)
	group by genre, name
)t
where director_rank <= 3
order by genre, director_rank;



-- Find the top two actors whose movies have a median rating >= 8.

select name, count(id) as movies_number, round(avg(median_rating),2) as avg_rating, sum(total_votes) as overall_votes from
(select m.id, n.name, m.title, r.median_rating, r.total_votes from movies m
join ratings r on r.movie_id = m.id
join role_mapping rm on m.id = rm.movie_id
join names n on rm.name_id = n.id
where r.median_rating >= 8
and rm.category = 'actor')t
group by name
order by movies_number desc, avg_rating desc, overall_votes desc
limit 2;



-- Identify the top three production houses based on the number of votes received by their movies.

select rank() over(order by sum(r.total_votes) desc) as rank_, m.production_company, sum(r.total_votes) as sum_votes from movies m
join ratings r on m.id = r.movie_id
group by m.production_company
limit 3;



-- Rank actors based on their average ratings in Indian movies released in India.

with cte as
(
select m.id, n.name, r.avg_rating, m.country, rm.category from movies m
join ratings r on r.movie_id = m.id
join role_mapping rm on rm.movie_id = m.id
join names n on rm.name_id = n.id
where m.country like '%India%'
and rm.category = 'actor'
)
select dense_rank() over(order by round(avg(avg_rating),2) desc) as rank_, round(avg(avg_rating),2) as overall_avg_rating, name, category from cte
group by name;



-- Identify the top five actresses in Hindi movies released in India based on their average ratings.

select * from
	(
	with cte as
		(
		select m.id, rm.category, r.avg_rating, r.total_votes, rm.name_id, n.name from movies m
		join role_mapping rm on rm.movie_id = m.id
		join ratings r on r.movie_id = m.id
		join names n on rm.name_id = n.id
		where country like '%India%'
		and languages like '%Hindi%'
		and category = 'actress'
		)
	select dense_rank() over(order by round(avg(avg_rating),2) desc) as actress_rank, name, round(avg(avg_rating),2) as overall_avg_rating from cte
	group by name
	)t
where actress_rank <= 5;



-- Segment 6: Broader Understanding of Data

-- Classify thriller movies based on average ratings into different categories.

select m.title, m.production_company, r.avg_rating,
case when r.avg_rating >=9 then 'Superhit'
when r.avg_rating between 7 and 9 then 'Hit'
when r.avg_rating between 5 and 7 then 'Average'
else 'Flop'
end as movie_category
from movies m
join genre g on g.movie_id = m.id
join ratings r on r.movie_id = m.id
where g.genre = 'Thriller'
order by avg_rating desc;



-- analyse the genre-wise running total and moving average of the average movie duration.

select g.genre, sum(m.duration) as total_duration, avg(duration) as avg_duration,
round(sum(avg(duration)) over (order by genre),2) as running_total,
round(avg(avg(duration)) over (order by genre),2) as moving_avg
from movies m
join genre g on g.movie_id = m.id
group by g.genre
order by total_duration desc;



-- Identify the five highest-grossing movies of each year that belong to the top three genres.

with top_genre as
(
	select rank() over (order by count(movie_id) desc) as genre_rank, genre, count(movie_id) as movies_number from genre
	group by genre
	order by movies_number desc
	limit 3
),
top_income as
(
	select m.title, g.genre, m.year, m.worlwide_gross_income as gross_income_of_movie from movies m
	join genre g on g.movie_id = m.id
	order by gross_income_of_movie desc
)
select * from
(
	select row_number() over(partition by year, genre order by year, genre) as ranking, title, genre, year, gross_income_of_movie from top_income
)p
where ranking in (1,2,3,4,5)
and genre in (select genre from top_genre)
order by genre, year, ranking;



-- Determine the top two production houses that have produced the highest number of hits among multilingual movies.

select production_company,count(id) as movie_count from movies
where locate(',',languages) > 0
and id in (Select movie_id from ratings where avg_rating > 8)
and production_company is not null
group by production_company
order by movie_count desc
limit 2;



-- Identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.

select row_number() over(order by count(movie_id) desc, sum(total_votes) desc) as actress_rank,
name, count(movie_id) as superhit_movies_number, sum(total_votes) as final_votes from
(
	select r.total_votes, g.genre, g.movie_id, rm.name_id, n.name from movies m
	join genre g on g.movie_id = m.id
	join ratings r on r.movie_id = m.id
	join role_mapping rm on m.id = rm.movie_id
	join names n on n.id = rm.name_id
	where g.genre = 'Drama'
	and category = 'actress'
	and avg_rating > 8
)t
group by name
limit 3;



-- Retrieve details for the top nine directors based on the number of movies, including average inter-movie duration, ratings, and more.

select t.name_id, n.name, t.movie_count, t.avg_rating1, t.sum_votes, t.total_duration, t.min_rating, t.max_rating from
(
select dm.name_id,
count(dm.movie_id) as movie_count,
avg(m.duration) as avg_duration,
round(avg(r.avg_rating),2) as avg_rating1,
sum(r.total_votes) as sum_votes,
min(r.avg_rating) as min_rating,
max(r.avg_rating) as max_rating,
sum(m.duration) as total_duration
from director_mapping dm
join ratings r on r.movie_id = dm.movie_id
join movies m on dm.movie_id = m.id
join names n on dm.name_id = n.id
group by dm.name_id
)t
join names n on n.id = t.name_id
order by t.movie_count desc, t.avg_rating1 desc, t.sum_votes
limit 9;



-- Segment 7: Recommendations

-- Based on the analysis, provide recommendations for the types of content Bolly movies should focus on producing.

with a1 as
( 
	select genre.genre as Focus_Genre, rank() over(order by (count(genre.movie_id)) desc) as rank1, count(genre.movie_id) as hit_movies from genre
	join ratings on
	ratings.movie_id = genre.movie_id
	where avg_rating >= 7
	group by genre
),
a2 as
(
	select count(id), Month(date_published) as Focus_Month, rank() over(order by (count(id)) asc) as rank2 from movies
    group by month(date_published)
),
a3 as
(
	select count(movies) as top_movies_actors, Top_actor, row_number() over(order by count(movies) desc) as rank3
    from
	(
		select m.id as movies, n.name as Top_actor from movies m
		join ratings on
		m.id = ratings.movie_id
        join names n on
        m.id = n.known_for_movies
		where languages like '%hindi%'
		and avg_rating > 8
	)t
    group by Top_actor
),
a4 as
(
	select row_number() over(order by count(movie_id) desc, sum(total_votes) desc) as rank4,
	name as Top_actress, count(movie_id) as superhit_movies_number, sum(total_votes) as final_votes from
	(
		select r.total_votes, g.genre, g.movie_id, rm.name_id, n.name from movies m
		join genre g on g.movie_id = m.id
		join ratings r on r.movie_id = m.id
		join role_mapping rm on m.id = rm.movie_id
		join names n on n.id = rm.name_id
		where g.genre = 'Drama'
		and category = 'actress'
		and avg_rating > 8
	)t
	group by Top_actress
),
a5 as
(
	select production_company as Production_company,count(id) as movie_count,
	row_number() over(order by count(id) desc) as rank5 from movies
	where languages like '%hindi%'
	and id in (Select movie_id from ratings where avg_rating > 8)
	and production_company is not null
	group by production_company
	order by movie_count desc
),
a6 as
(
	select t.name_id, n.name as Director_name, t.movie_count, rank() over(order by movie_count desc,avg_rating1 desc) as rank6 from
	(
		select dm.name_id,
		count(dm.movie_id) as movie_count,
		avg(m.duration) as avg_duration,
		round(avg(r.avg_rating),2) as avg_rating1,
		sum(r.total_votes) as sum_votes,
		min(r.avg_rating) as min_rating,
		max(r.avg_rating) as max_rating,
		sum(m.duration) as total_duration
		from director_mapping dm
		join ratings r on r.movie_id = dm.movie_id
		join movies m on dm.movie_id = m.id
		join names n on dm.name_id = n.id
		group by dm.name_id
	)t
	join names n on n.id = t.name_id
	order by t.movie_count desc, t.avg_rating1 desc, t.sum_votes
)
select Focus_Genre, Focus_Month, Top_actor, Top_actress, Production_company, Director_name
from a1
join a2 on
a1.rank1 = a2.rank2
join a3 on
a1.rank1 = a3.rank3
join a4
on a1.rank1 = a4.rank4
join a5
on a1.rank1 = a5.rank5
join a6
on a1.rank1 = a6.rank6
where rank1 = '1';
