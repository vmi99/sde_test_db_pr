/*создание таблицы результатов results*/

create table results (
	id INT,
	response TEXT
);

/*1. Вывести максимальное количество человек в одном бронировании*/

insert into results
select '1'::integer, count(passenger_id) as c_pas
from tickets t
group by book_ref
order by count(passenger_id) desc
limit 1;

/*2. Вывести количество бронирований с количеством людей
 больше среднего значения людей на одно бронирование*/

with passengers_count as (
	select count(passenger_id) as c_pas, book_ref as b_ref
	from tickets t
	group by book_ref
	)
insert into results
select '2'::integer, count(b_ref) as c_ref
from passengers_count
where c_pas > (
	select avg(c_pas)
	from passengers_count
);

/* 3. Вывести количество бронирований, у которых состав пассажиров
 повторялся два и более раза, среди бронирований с максимальным количеством людей (п.1)?*/

--?????????????????????? состав должен совпадать полностью
with max_passengers_count as (
	select count(passenger_id) as c_pas
	from tickets t
	group by book_ref
	order by count(passenger_id) desc
	limit 1
),
passengers_count as (
	select count(passenger_id) as c_pas, book_ref as b_ref
	from tickets t
	group by book_ref
),
all_max as (
	select b_ref
	from passengers_count
	where c_pas = (
		select c_pas
		from max_passengers_count
	)
),
in_book_ref as (
	select t1.book_ref, t1.passenger_id
	from all_max join tickets t1
	on all_max.b_ref = t1.book_ref
)
insert into results
select '3'::integer, t1.book_ref as refs
from in_book_ref t1 join in_book_ref t2
on t1.book_ref <> t2.book_ref
and t1.passenger_id = t2.passenger_id
join in_book_ref t3
on t1.book_ref  <> t3.book_ref
and t2.book_ref <> t3.book_ref
and t2.passenger_id = t3.passenger_id;

/*4. Вывести номера брони и контактную информацию по пассажирам в брони
 (passenger_id, passenger_name, contact_data) с количеством людей в брони = 3*/

with b_ref as (
	select book_ref, count(passenger_id)
	from tickets t
	group by book_ref
	having count(passenger_id) = 3
)
insert into results
select '4'::integer, b_r||'|'||passenger_id ||'|'||passenger_name ||'|'||contact_data
from (
	select b_ref.book_ref as b_r, passenger_id, passenger_name, contact_data
	from b_ref join tickets
	on b_ref.book_ref = tickets.book_ref
	order by tickets.book_ref asc, passenger_id asc, passenger_name asc, contact_data asc
) s;

/*5. Вывести максимальное количество перелётов на бронь*/

insert into results
select '5'::integer, count(flight_id) as c_flights
from tickets t join ticket_flights tf
on t.ticket_no = tf.ticket_no
group by book_ref
order by count(flight_id) desc
limit 1;

/*6. Вывести максимальное количество перелётов на пассажира в одной брони*/

insert into results
select '6'::integer, count(flight_id) as c_flights
from tickets t join ticket_flights tf
on t.ticket_no = tf.ticket_no
group by book_ref, passenger_id
order by count(flight_id) desc
limit 1;

/*7. Вывести максимальное количество перелётов на пассажира*/

insert into results
select '7'::integer, count(flight_id) as c_flights
from tickets t join ticket_flights tf
on t.ticket_no = tf.ticket_no
group by passenger_id
order by count(flight_id) desc
limit 1;

/*8. Вывести контактную информацию по пассажиру(ам)
 (passenger_id, passenger_name, contact_data) и общие траты на билеты,
 для пассажира потратившего минимальное количество денег на перелеты*/

with sum_amount as (
	select passenger_id, passenger_name, contact_data, sum(amount) as total_amount
	from tickets t join ticket_flights tf
	on t.ticket_no = tf.ticket_no
	join flights f
	on tf.flight_id = f.flight_id
	where f.status <> 'Cancelled'
	group by passenger_id, passenger_name, contact_data
	order by sum(amount) asc
)
insert into results
select '8'::integer, passenger_id||'|'||passenger_name||'|'||contact_data||'|'||total_amount
from
(select passenger_id, passenger_name, contact_data,total_amount
from sum_amount
where total_amount = (
	select min(total_amount) as min_total_amount
	from sum_amount
)
order by passenger_id, passenger_name, contact_data asc) tt;

/*9. Вывести контактную информацию по пассажиру(ам)
 (passenger_id, passenger_name, contact_data) и общее время в полётах,
 для пассажира, который провёл максимальное время в полётах*/

with flight_time as (
	select passenger_id, passenger_name, contact_data, sum(actual_duration) as total_flight_time
	from flights_v fv join ticket_flights tf
	on fv.flight_id = tf.flight_id
	join tickets tk
	on tk.ticket_no  = tf.ticket_no
	where fv.status = 'Arrived'
	group by passenger_id, passenger_name, contact_data
)
insert into results
select '9'::integer, passenger_id||'|'||passenger_name||'|'||contact_data||'|'||total_flight_time
from (
	select passenger_id, passenger_name, contact_data, total_flight_time
	from flight_time ft
	where total_flight_time = (
		select max(total_flight_time) as max_flight_time
		from flight_time
	)
	order by passenger_id asc, passenger_name asc, contact_data asc
) s;

/*10. Вывести город(а) с количеством аэропортов больше одного*/

insert into results
select '10'::integer, city
from airports a
group by city
having count(airport_code) > 1
order by city asc;

/*11. Вывести город(а), у которого самое меньшее количество городов прямого сообщения*/

with cities_count as (
	select departure_city, count(distinct arrival_city) as c_count
	from routes r
	group by departure_city
)
insert into results
select '11'::integer, departure_city
from cities_count
where c_count = (
	select min(c_count)
	from cities_count
)
order by departure_city asc;

/*12. Вывести пары городов, у которых нет прямых сообщений
 исключив реверсные дубликаты*/

-- реверсные дубликаты????????????????????????????
with direct as (
	select distinct departure_city as depart, arrival_city as arrive
	from flights_v fv
)
insert into results
select '12'::integer, s1.depart||'|'||s2.arrive
from direct s1 join direct s2
on (s1.arrive = s2.depart and s1.depart <> s2.arrive)
order by s1.depart asc, s2.arrive asc;

/*13. Вывести города, до которых нельзя добраться без пересадок из Москвы*/

insert into results
select distinct '13'::integer, r1.arrival_city
from routes r1
where r1.arrival_city NOT IN (select r2.arrival_city from routes r2 where r2.departure_city = 'Москва')
order by arrival_city asc;

/*14. Вывести модель самолета, который выполнил больше всего рейсов*/

with flights_count as (
	select model, count(flight_id) as c_flights
	from aircrafts a join flights f
	on a.aircraft_code = f.aircraft_code
	where f.status = 'Arrived'
	group by model
)
insert into results
select '14'::integer, model
from flights_count
where c_flights = (
	select max(c_flights)
	from flights_count
)
order by model asc;

/*15. Вывести модель самолета, который перевез больше всего пассажиров*/

with passengers_count as (
	select model, count(passenger_id) as c_pas
	from aircrafts a join flights f
	on a.aircraft_code = f.aircraft_code
	join ticket_flights tf
	on f.flight_id = tf.flight_id
	join tickets t
	on t.ticket_no = tf.ticket_no
	where f.status = 'Arrived'
	group by model
)
insert into results
select '15'::integer, model
from passengers_count
where c_pas = (
	select max(c_pas)
	from passengers_count
)
order by model asc;

/*16. Вывести отклонение в минутах суммы запланированного времени
 перелета от фактического по всем перелётам*/

with sums as (
	select sum(scheduled_duration) as sum_shed, sum(actual_duration) as sum_act
	from flights_v fv
	where status = 'Arrived'
)
insert into results
select '16'::integer, ABS(EXTRACT(epoch FROM sum_act - sum_shed) / 60)
from sums;

/*17. Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2016-09-13*/

insert into results
select distinct '17'::integer,  arrival_city
from flights_v fv
where (status = 'Arrived' or status = 'Departed')
	  and departure_city = 'Санкт-Петербург'
	  and date(actual_departure) = '2016-09-13'
order by arrival_city asc;

/*18. Вывести перелёт(ы) с максимальной стоимостью всех билетов*/

with sum_amount as (
	select f.flight_id, sum(amount) as sum_a
	from ticket_flights tf join flights f
	on tf.flight_id = f.flight_id
	where f.status <> 'Cancelled'
	group by f.flight_id
)
insert into results
select '18'::integer, flight_id
from sum_amount
where sum_a = (
	select max(sum_a)
	from sum_amount
)
order by flight_id asc;

/*19. Выбрать дни в которых было осуществлено минимальное количество перелётов*/

with count_flights as (
	select date(actual_departure) as depart_date, count(flight_id) as c_flights
	from flights f
	where status <> 'Cancelled'
		  and actual_departure is not null
	group by date(actual_departure)
)
insert into results
select '19'::integer, depart_date
from count_flights
where c_flights = (
	select min(c_flights)
	from count_flights
);

/*20. Вывести среднее количество вылетов в день из Москвы за 09 месяц 2016 года*/

insert into results
select '20'::integer, count(flight_id) / 30
from flights f
where (status = 'Departed' or status = 'Arrived')
and date(actual_departure) between '2016-09-01' and '2016-09-30'
group by to_char(actual_departure, 'YYYY-MM');

/*21. Вывести топ 5 городов у которых среднее время перелета
 до пункта назначения больше 3 часов*/

insert into results
select '21'::integer, departure_city
from (
	select avg(actual_duration), departure_city
	from flights_v fv
	where actual_duration is not null
	and actual_duration > '03:00:00'
	group by departure_city
	order by avg(actual_duration) desc
	limit 5
) s
order by departure_city asc;