-- CS4400: Introduction to Database Systems: Monday, March 3, 2025
-- Simple Airline Management System Course Project Mechanics [TEMPLATE] (v0)
-- Views, Functions & Stored Procedures

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'flight_tracking';
use flight_tracking;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [_] supporting functions, views and stored procedures
-- -----------------------------------------------------------------------------
/* Helpful library capabilities to simplify the implementation of the required
views and procedures. */
-- -----------------------------------------------------------------------------
drop function if exists leg_time;
delimiter //
create function leg_time (ip_distance integer, ip_speed integer)
	returns time reads sql data
begin
	declare total_time decimal(10,2);
    declare hours, minutes integer default 0;
    set total_time = ip_distance / ip_speed;
    set hours = truncate(total_time, 0);
    set minutes = truncate((total_time - hours) * 60, 0);
    return maketime(hours, minutes, 0);
end //
delimiter ;

-- [1] add_airplane()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airplane.  A new airplane must be sponsored
by an existing airline, and must have a unique tail number for that airline.
username.  An airplane must also have a non-zero seat capacity and speed. An airplane
might also have other factors depending on it's type, like the model and the engine.  
Finally, an airplane must have a new and database-wide unique location
since it will be used to carry passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airplane;
delimiter //
create procedure add_airplane (in ip_airlineID varchar(50), in ip_tail_num varchar(50),
	in ip_seat_capacity integer, in ip_speed integer, in ip_locationID varchar(50),
    in ip_plane_type varchar(100), in ip_maintenanced boolean, in ip_model varchar(50),
    in ip_neo boolean)
sp_main: begin

	-- Ensure that the plane type is valid: Boeing, Airbus, or neither
    -- Ensure that the type-specific attributes are accurate for the type
    -- Ensure that the airplane and location values are new and unique
    -- Add airplane and location into respective tables
    declare cnt int;
    
    -- checking type is valid
    if not(ip_plane_type = 'Boeing' or ip_plane_type = 'Airbus' or ip_plane_type is null) then
		leave sp_main;
	end if;
        
	-- checking to see if airplane is unique
	select count(*) into cnt from airplane where airlineID = ip_airlineID and tail_num = ip_tail_num;
	if cnt > 0 then 
		leave sp_main;
	end if;
        
	-- checking to see if airline exists or not
	select count(*) into cnt from airline where airlineID = ip_airlineID;
    if cnt = 0 then
		leave sp_main;
	end if;
        
	-- checking to see if airline's location is unique
	select count(*) into cnt from location where locationID = ip_locationID;
    if cnt > 0 then
		leave sp_main;
	end if;
        
	-- checking to see if the respective airplane has a non-zero seat capacity andspeed
    if not(ip_speed > 0 and ip_seat_capacity > 0) then
		leave sp_main;
	end if;
        
	if (ip_plane_type = 'Boeing' and not (ip_maintenanced is not null and ip_model is not null and ip_neo is NULL)) 
		OR (ip_plane_type = 'Airbus' and not (ip_maintenanced is null and ip_model is null and ip_neo is not NULL))
        OR (ip_plane_type is NULL and not (ip_maintenanced is null and ip_model is null and ip_neo is NULL))
        then
		leave sp_main;
	end if;
	
    INSERT INTO location VALUES (ip_locationID);
    
    INSERT INTO airplane VALUES
		(ip_airlineID, ip_tail_num, ip_seat_capacity, ip_speed, ip_locationID, ip_plane_type, ip_maintenanced, ip_model, ip_neo);
		
end //
delimiter ;

-- [2] add_airport()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airport.  A new airport must have a unique
identifier along with a new and database-wide unique location if it will be used
to support airplane takeoffs and landings.  An airport may have a longer, more
descriptive name.  An airport must also have a city, state, and country designation. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airport;
delimiter //
create procedure add_airport (in ip_airportID char(3), in ip_airport_name varchar(200),
    in ip_city varchar(100), in ip_state varchar(100), in ip_country char(3), in ip_locationID varchar(50))
sp_main: begin

	-- Ensure that the airport and location values are new and unique
    -- Add airport and location into respective tables
    declare cnt int;
    
	-- checking to see if airportID is unique
	select count(*) into cnt from airport where airportID = ip_airportID;
	if cnt > 0 then 
		leave sp_main;
	end if;
    
	-- checking to see if airportname is unique
	select count(*) into cnt from airport where airport_name = ip_airport_name;
	if cnt > 0 then 
		leave sp_main;
	end if;

	-- checking to see if airport's location is unique
	select count(*) into cnt from location where locationID = ip_locationID;
    if cnt > 0 then
		leave sp_main;
	end if;
    
    -- An airport must also have a city, state, and country designation.
    if ip_city is null or ip_state is null or ip_country is null then
		leave sp_main;
	end if;
    
    INSERT INTO location VALUES (ip_locationID);
    INSERT INTO airport VALUES (ip_airportID,ip_airport_name,ip_city,ip_state,ip_country,ip_locationID);

end //
delimiter ;

-- [3] add_person()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new person.  A new person must reference a unique
identifier along with a database-wide unique location used to determine where the
person is currently located: either at an airport, or on an airplane, at any given
time.  A person must have a first name, and might also have a last name.

A person can hold a pilot role or a passenger role (exclusively).  As a pilot,
a person must have a tax identifier to receive pay, and an experience level.  As a
passenger, a person will have some amount of frequent flyer miles, along with a
certain amount of funds needed to purchase tickets for flights. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_person;
delimiter //
create procedure add_person (in ip_personID varchar(50), in ip_first_name varchar(100),
    in ip_last_name varchar(100), in ip_locationID varchar(50), in ip_taxID varchar(50),
    in ip_experience integer, in ip_miles integer, in ip_funds integer)
sp_main: begin

	-- Ensure that the location is valid
    -- Ensure that the persion ID is unique
    -- Ensure that the person is a pilot or passenger
    -- Add them to the person table as well as the table of their respective role
    
    declare cnt int;
    declare check_passenger boolean;
    declare check_pilot boolean;
    
    -- first name needs to be not null - last name can be null
    if ip_first_name is null then
		leave sp_main;
	end if;
    
    -- checking the location is valid
    select count(*) into cnt from location where locationID = ip_locationID;
    if cnt = 0 then
		leave sp_main;
	end if;
    
    -- checking the person_id
    select count(*) into cnt from person where personID = ip_personID;
    if cnt > 0 then
		leave sp_main;
	end if;
    
    -- checking to see if the person is a pilot or a passenger
    -- checking for a passenger
    set check_passenger = 
    (ip_personID is not null and ip_miles is not null and ip_funds is not null and ip_taxID is null and ip_experience is null) ;
    
    -- checking for pilot
    set check_pilot = ip_personID is not null and ip_taxID is not null and ip_experience is not null and ip_miles is  null and ip_funds is  null;
    
   -- this way im checking that it is has to be either pilot or passenger
   if (check_passenger and check_pilot) or (not check_passenger and not check_pilot) then 
		leave sp_main;
	end if;
    
    -- check for passenger
    /*
     As a
	passenger, a person will have some amount of frequent flyer miles, along with a
	certain amount of funds needed to purchase tickets for flights. 
    */
    
    if check_passenger then 
		if ip_personID is null or ip_miles is null or ip_funds is null then
			leave sp_main;
		end if;
        
        if ip_miles < 0 or ip_funds < 0 then 
			leave sp_main;
		end if;
        
        insert into person values (ip_personID,ip_first_name,ip_last_name,ip_locationID);
        insert into passenger values (ip_personID,ip_miles,ip_funds);
	end if;
        
	-- check pilot
    /*
    As a pilot,
	a person must have a tax identifier to receive pay, and an experience level
	*/
    
    if check_pilot then
    
		if ip_personID is null or ip_taxID is null or ip_experience is null then
			leave sp_main;
		end if;
        
        select count(*) into cnt from pilot where taxID = ip_taxID;
			if cnt > 0 then 
				leave sp_main;
			end if;
		
        
        insert into person values (ip_personID,ip_first_name,ip_last_name,ip_locationID);
        insert into pilot values (ip_personID,ip_taxID,ip_experience,null);
	end if;
	

end //
delimiter ;

-- [4] grant_or_revoke_pilot_license()
-- -----------------------------------------------------------------------------
/* This stored procedure inverts the status of a pilot license.  If the license
doesn't exist, it must be created; and, if it aready exists, then it must be removed. */
-- -----------------------------------------------------------------------------
drop procedure if exists grant_or_revoke_pilot_license;
delimiter //
create procedure grant_or_revoke_pilot_license (in ip_personID varchar(50), in ip_license varchar(100))
sp_main: begin

	-- Ensure that the person is a valid pilot
    -- If license exists, delete it, otherwise add the license
    declare cnt int;
    declare lic int;
    
    if ip_personID is null or ip_license is null then
		leave sp_main;
	end if;
    
    -- checking to see if this is a valid person or not
	select count(*) into cnt from pilot where personID = ip_personID;
    if cnt = 0 then
		leave sp_main;
	end if;
    
    select count(*) into lic from pilot_licenses where personID = ip_personID and license = ip_license;
    
    -- if license exists
    if lic > 0 then
		delete from pilot_licenses where personID = ip_personID and license = ip_license;
	end if;
    
    -- if license doesn't exist
	if lic = 0 then
		insert into pilot_licenses values (ip_personID, ip_license);
	end if;
		
		
    
end //
delimiter ;

-- [5] offer_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new flight.  The flight can be defined before
an airplane has been assigned for support, but it must have a valid route.  And
the airplane, if designated, must not be in use by another flight.  The flight
can be started at any valid location along the route except for the final stop,
and it will begin on the ground.  You must also include when the flight will
takeoff along with its cost. */
-- -----------------------------------------------------------------------------
drop procedure if exists offer_flight;
delimiter //
create procedure offer_flight (in ip_flightID varchar(50), in ip_routeID varchar(50),
    in ip_support_airline varchar(50), in ip_support_tail varchar(50), in ip_progress integer,
    in ip_next_time time, in ip_cost integer)
sp_main: begin

	-- Ensure that the airplane exists
    -- Ensure that the route exists
    -- Ensure that the progress is less than the length of the route
    -- Create the flight with the airplane starting in on the ground
    
    declare route_exists int;
    declare airplane_exists int;
    declare airplane_in_use int;
    declare route_length int;

    -- Check if route exists
    select count(*) into route_exists from route
    where routeID = ip_routeID;

    if route_exists = 0 then
        leave sp_main;
    end if;

    -- If airplane isnt null, check if it exists and is not already used
    if ip_support_airline is not null and ip_support_tail is not null then
        select count(*) into airplane_exists from airplane
        where airlineID = ip_support_airline and tail_num = ip_support_tail;

        if airplane_exists = 0 then
            leave sp_main;
        end if;

        select count(*) into airplane_in_use from flight
        where support_airline = ip_support_airline and support_tail = ip_support_tail;

        if airplane_in_use > 0 then
            leave sp_main;
        end if;

    end if;

    -- Check if progress is less than route length
    select count(*) into route_length from route_path
    where routeID = ip_routeID;

    if ip_progress >= route_length then
        leave sp_main;
    end if;

    -- Insert the flight
    insert into flight values (ip_flightID, ip_routeID, ip_support_airline, ip_support_tail, ip_progress, 'on_ground', ip_next_time, ip_cost);

end //
delimiter ;

-- [6] flight_landing()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight landing at the next airport
along it's route.  The time for the flight should be moved one hour into the future
to allow for the flight to be checked, refueled, restocked, etc. for the next leg
of travel.  Also, the pilots of the flight should receive increased experience, and
the passengers should have their frequent flyer miles updated. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_landing;
delimiter //
create procedure flight_landing (in ip_flightID varchar(50))
sp_main: begin

	-- Ensure that the flight exists
    -- Ensure that the flight is in the air

    -- Increment the pilot's experience by 1
    -- Increment the frequent flyer miles of all passengers on the plane
    -- Update the status of the flight and increment the next time to 1 hour later
		-- Hint: use addtime()
        
	declare route_id varchar(50);
    declare current_progress int;
    declare leg_id varchar(50);
    declare dist int;
    declare plane_location varchar(50);

    -- Ensure the flight exists and is in the air
    select routeID, progress into route_id, current_progress from flight
    where flightID = ip_flightID and airplane_status = 'in_flight';

    if route_id is null then
        leave sp_main;
    end if;

    -- Get the current leg
    select legID into leg_id from route_path
    where routeID = route_id and sequence = current_progress;

    if leg_id is null then
        leave sp_main;
    end if;

    -- Get distance
    select distance into dist from leg
    where legID = leg_id;

    -- Update pilot experience
    update pilot
    set experience = experience + 1
    where commanding_flight = ip_flightID;

    -- Get airplane's location 
    select locationID into plane_location from airplane
    where (airlineID, tail_num) in 
    (select support_airline, support_tail from flight where flightID = ip_flightID);

    -- Update passenger miles on that plane
    update passenger
    set miles = miles + dist where personID in 
    (select personID from person where locationID = plane_location);

    -- Update the flight
    update flight
    set airplane_status = 'on_ground', next_time = addtime(next_time, '01:00:00')
    where flightID = ip_flightID;

end //
delimiter ;

-- [7] flight_takeoff()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight taking off from its current
airport towards the next airport along it's route.  The time for the next leg of
the flight must be calculated based on the distance and the speed of the airplane.
And we must also ensure that Airbus and general planes have at least one pilot
assigned, while Boeing must have a minimum of two pilots. If the flight cannot take
off because of a pilot shortage, then the flight must be delayed for 30 minutes. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_takeoff;
delimiter //
create procedure flight_takeoff (in ip_flightID varchar(50))
sp_main: begin

	-- Ensure that the flight exists
    -- Ensure that the flight is on the ground
    -- Ensure that the flight has another leg to fly
    -- Ensure that there are enough pilots (1 for Airbus and general, 2 for Boeing)
		-- If there are not enough, move next time to 30 minutes later
        
	-- Increment the progress and set the status to in flight
    -- Calculate the flight time using the speed of airplane and distance of leg
    -- Update the next time using the flight time
	
    declare route_id varchar(50);
    declare current_leg int;
    declare max_leg int;
    declare leg_id varchar(50);
    declare leg_distance int;
    declare ptype varchar(100);
    declare airline_id varchar(50);
    declare tail_id varchar(50);
    declare plane_speed int;
    declare pilot_count int;
    declare flight_duration time;

    -- Check flight exists and is on the ground
    select routeID, progress, support_airline, support_tail into route_id, current_leg, airline_id, tail_id from flight
    where flightID = ip_flightID and airplane_status = 'on_ground';

    if route_id is null then
        leave sp_main;
    end if;

    -- Get max leg count
    select count(*) into max_leg from route_path
    where routeID = route_id;

    if current_leg >= max_leg then
        leave sp_main;
    end if;

    -- Get current legID (progress + 1)
    select legID into leg_id from route_path
    where routeID = route_id and sequence = current_leg + 1;

    if leg_id is null then
        leave sp_main;
    end if;

    -- Get distance for the leg
    select distance into leg_distance from leg
    where legID = leg_id;

    -- Get airplane speed and type
    select speed, plane_type into plane_speed, ptype from airplane
    where airlineID = airline_id and tail_num = tail_id;

    -- Count qualified pilots
    select count(*) into pilot_count from pilot p
    join pilot_licenses pl on p.personID = pl.personID
    where p.commanding_flight = ip_flightID and (pl.license = ptype or pl.license = 'general');

    -- Check if enough pilots and if not, delay by 30 mins
    if (ptype = 'Boeing' and pilot_count < 2) or ((ptype = 'Airbus' or ptype is null) and pilot_count < 1) then
        update flight
        set next_time = addtime(next_time, '00:30:00')
        where flightID = ip_flightID;
        leave sp_main;
    end if;

    -- Calculate duration and update flight
    set flight_duration = leg_time(leg_distance, plane_speed);

    update flight
    set progress = progress + 1, airplane_status = 'in_flight', next_time = addtime(next_time, flight_duration)
    where flightID = ip_flightID;

end //
delimiter ;

-- [8] passengers_board()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting on a flight at
its current airport.  The passengers must be at the same airport as the flight,
and the flight must be heading towards that passenger's desired destination.
Also, each passenger must have enough funds to cover the flight.  Finally, there
must be enough seats to accommodate all boarding passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_board;
delimiter //
create procedure passengers_board (in ip_flightID varchar(50))
sp_main: begin

	declare cnt int;
    declare current_status varchar(100);
    declare curr_leg int;
    declare max_legs int;
    declare num_passengers int;
    declare airport_loc varchar(50);
    declare airport_arrival_loc varchar(50);
    declare passenger_loc varchar(50);
    declare seats int;
    declare flight_loc varchar(50);
    declare flight_cost int;
    declare airport_locID varchar(50);
    
	-- Ensure the flight exists
    select count(*) into cnt from flight where flightID = ip_flightID;
    if cnt = 0 then
		leave sp_main;
	end if;
    
    -- Ensure that the flight is on the ground
    select airplane_status into current_status from flight where flightID = ip_flightID;
    if current_status not like 'on_ground' then
		leave sp_main;
	end if;
    
    -- Ensure that the flight has further legs to be flown
    select count(routeID) into max_legs from route_path where routeID in 
    (select routeID from flight where flightID = ip_flightID);
    
    select progress into curr_leg from flight where flightID = ip_flightID;
    if curr_leg >= max_legs then
		leave sp_main;
	end if;

    -- Determine the number of passengers attempting to board the flight
    -- Use the following to check:
		-- The airport the airplane is currently located at
        if curr_leg = 0 then
			select l.departure into airport_loc from leg l join route_path rp on rp.legID = l.legID join flight f on f.routeID = rp.routeID where
			f.flightID = ip_flightID and f.progress + 1 = rp.sequence;
		else
			select l.arrival into airport_loc from leg l join route_path rp on rp.legID = l.legID join flight f on f.routeID = rp.routeID where
			f.flightID = ip_flightID and f.progress = rp.sequence;
		end if;
        
        -- The passengers are located at that airport
        -- The passenger's immediate next destination matches that of the flight
         select l.arrival into airport_arrival_loc from leg l join route_path rp on rp.legID = l.legID join flight f on f.routeID = rp.routeID where
         f.flightID = ip_flightID and f.progress + 1 = rp.sequence;
        -- The passenger has enough funds to afford the flight
        select cost into flight_cost from flight where flightID = ip_flightID;
        select locationID into airport_locID from airport where airportID = airport_loc;
        
		select count(p.personID) into num_passengers from person p join airport a on a.locationID = p.locationID join passenger_vacations pv on p.personID = pv.personID 
        join passenger pass on pass.personID = p.personID
        where p.locationID = airport_locID and pv.airportID = airport_arrival_loc and pass.funds >= flight_cost and pv.sequence = curr_leg + 1;
        
	-- Check if there enough seats for all the passengers
		-- If not, do not add board any passengers
        -- If there are, board them and deduct their funds
		select a.seat_capacity into seats from airplane a join flight f on f.support_tail = a.tail_num where f.flightID = ip_flightID;
        
        if num_passengers > seats then
			leave sp_main;
		end if;
		
        select a.locationID into flight_loc from airplane a join flight f on f.support_tail = a.tail_num where f.flightID = ip_flightID;
        

        update passenger p join person pers on p.personID = pers.personID join passenger_vacations pv on p.personID = pv.personID 
        set p.funds = p.funds - flight_cost
        where pers.locationID = airport_locID and pv.airportID = airport_arrival_loc and p.funds >= flight_cost;
        
		update person p join passenger pass on p.personID = pass.personID join passenger_vacations pv on pv.personID = p.personID 
        set p.locationID = flight_loc where p.locationID = airport_locID
        and pv.airportID = airport_arrival_loc;
end //
delimiter ;

-- [9] passengers_disembark()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting off of a flight
at its current airport.  The passengers must be on that flight, and the flight must
be located at the destination airport as referenced by the ticket. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_disembark;
delimiter //
create procedure passengers_disembark (in ip_flightID varchar(50))
sp_main: begin

	declare cnt int;
    declare num_passengers int;
    declare plane_loc varchar(50);
    declare next_dest varchar(50);
    declare curr_leg int;
    
    
	-- Ensure the flight exists
    -- Ensure that the flight is in the air
    
    select count(*) into cnt from flight where flightID = ip_flightID and airplane_status = 'on_ground';
    if cnt = 0 then
		leave sp_main;
	end if;
    
    -- Determine the list of passengers who are disembarking
	-- Use the following to check:
		-- Passengers must be on the plane supporting the flight
        -- Passenger has reached their immediate next destionation airport
	select a.locationID into plane_loc from airplane a join flight f on f.support_tail = a.tail_num where f.flightID = ip_flightID;
    
    select arrival into next_dest from leg l join route_path rp on rp.legID = l.legID join flight f on rp.routeID = f.routeID where flightID = ip_flightID
    and rp.sequence = f.progress;
  
        
	-- Move the appropriate passengers to the airport
    update person p join passenger_vacations pv on p.personID = pv.personID 
    set p.locationID = (select locationID from airport where airportID = next_dest) 
    where p.locationID = plane_loc and pv.airportID = next_dest;
    
    -- Update the vacation plans of the passengers
    select progress into curr_leg from flight where flightID = ip_flightID;
    
    delete pv from passenger_vacations pv join person p on p.personID = pv.personID where p.locationID = plane_loc and pv.airportID = next_dest;

end //
delimiter ;

-- [10] assign_pilot()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a pilot as part of the flight crew for a given
flight.  The pilot being assigned must have a license for that type of airplane,
and must be at the same location as the flight.  Also, a pilot can only support
one flight (i.e. one airplane) at a time.  The pilot must be assigned to the flight
and have their location updated for the appropriate airplane. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_pilot;
delimiter //
create procedure assign_pilot (in ip_flightID varchar(50), ip_personID varchar(50))
sp_main: begin

	declare cnt int;
    declare max_legs int;
    declare curr_leg int;
    declare ptype varchar(50);
    declare license_type varchar(50);
    declare airport_id varchar(50);
    declare airport_loc varchar(50);
    declare flight_loc varchar(50);
    
	-- Ensure the flight exists
	-- Ensure that the flight is on the ground

    select count(*) into cnt from flight where flightID = ip_flightID and airplane_status = 'on_ground';
    if cnt = 0 then
		leave sp_main;
	end if;
    
    -- Ensure that the flight has further legs to be flown
    select count(routeID) into max_legs from route_path where routeID in 
    (select routeID from flight where flightID = ip_flightID);
    
    select progress into curr_leg from flight where flightID = ip_flightID;
    if curr_leg = max_legs then
		leave sp_main;
	end if;
    
    -- Ensure that the pilot exists and is not already assigned
	-- Ensure that the pilot has the appropriate license
    select a.plane_type into ptype from airplane a join flight f on f.support_tail = a.tail_num where f.flightID = ip_flightID;
    
    -- Ensure the pilot is located at the airport of the plane that is supporting the flight
    select l.departure into airport_id from leg l join route_path rp on rp.legID = l.legID join flight f on f.routeID = rp.routeID where
	f.flightID = ip_flightID and f.progress + 1 = rp.sequence;
    select locationID into airport_loc from airport where airportID = airport_id;
    
    select count(*) into cnt from pilot p join pilot_licenses pl on p.personID = pl.personID join person pers on p.personID = pers.personID
    where p.personID = ip_personID and (pl.license = ptype or pl.license = 'general') and p.commanding_flight is null
    and pers.locationID = airport_loc;
    if cnt = 0 then
		leave sp_main;
	end if;
    
    -- Assign the pilot to the flight and update their location to be on the plane
    select a.locationID into flight_loc from airplane a join flight f on f.support_tail = a.tail_num where f.flightID = ip_flightID;
    
    update pilot set commanding_flight = ip_flightID where personID = ip_personID;
    update person set locationID = flight_loc where personID = ip_personID;
    

end //
delimiter ;

-- [11] recycle_crew()
-- -----------------------------------------------------------------------------
/* This stored procedure releases the assignments for a given flight crew.  The
flight must have ended, and all passengers must have disembarked. */
-- -----------------------------------------------------------------------------
drop procedure if exists recycle_crew;
delimiter //
create procedure recycle_crew (in ip_flightID varchar(50))
sp_main: begin

	-- Ensure that the flight is on the ground
    -- Ensure that the flight does not have any more legs
    
    -- Ensure that the flight is empty of passengers
    
    -- Update assignements of all pilots
    -- Move all pilots to the airport the plane of the flight is located at
    
    DECLARE flight_exists BOOLEAN;
    DECLARE on_ground VARCHAR(100);
    DECLARE route_id VARCHAR(50);
    DECLARE final_leg INT;
    DECLARE final_leg_id VARCHAR(50);
    DECLARE current_leg INT;
    DECLARE location_id VARCHAR(50);
    DECLARE num_passengers INT;
    DECLARE arrival_airport_location_id VARCHAR(50);
    DECLARE support_airline_id VARCHAR(50);
    DECLARE support_tail_id VARCHAR(50);
    
    -- check if the flight exists
    SELECT COUNT(*) INTO flight_exists FROM flight WHERE flightID = ip_flightID;
    IF flight_exists = 0 THEN
		leave sp_main;
	END IF;
    
    -- flight on ground
    SELECT airplane_status, routeID, progress, support_airline, support_tail
	INTO on_ground, route_id, current_leg, support_airline_id, support_tail_id
	FROM flight WHERE flightID = ip_flightID;
    
    IF on_ground != 'on_ground' THEN
		leave sp_main;
	END IF;
    
    -- no legs left/on final leg
	SELECT sequence, legID INTO final_leg, final_leg_id
	FROM route_path
    WHERE routeID = route_id
	ORDER BY sequence DESC 
    LIMIT 1;    
    
	IF current_leg < final_leg THEN
		leave sp_main;
	END IF;
    
    
    -- get location id of the airplane
    SELECT locationID into location_id
    FROM airplane
    WHERE tail_num = support_tail_id;
    
    
    
    -- no passengers are on flight
    SELECT COUNT(*) INTO num_passengers
    FROM person
		INNER JOIN passenger -- only account for passengers, not pilotss
        ON person.personID = passenger.personID
	WHERE person.locationID = location_id;
    
    IF num_passengers > 0 THEN
		leave sp_main;
	END IF;
    
    
	-- set all pilots commanding flight to NULL
    UPDATE pilot SET commanding_flight = NULL WHERE commanding_flight = ip_flightID;
    
    
    -- set location to the airport that the airplane landed at
    -- get location of the airport
	SELECT locationID INTO arrival_airport_location_id
    FROM airport
    WHERE airportID = (SELECT arrival FROM leg WHERE legID = final_leg_id);
    -- this is going to be valid bc not dependent on user param
    
    UPDATE person SET locationID = arrival_airport_location_id
    WHERE locationID = location_id;
    -- for all persons that have location on the flight, which is only pilots
end //
delimiter ;

-- [12] retire_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a flight that has ended from the system.  The
flight must be on the ground, and either be at the start its route, or at the
end of its route.  And the flight must be empty - no pilots or passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists retire_flight;
delimiter //
create procedure retire_flight (in ip_flightID varchar(50))
sp_main: begin

	-- Ensure that the flight is on the ground
    -- Ensure that the flight does not have any more legs
    
    -- Ensure that there are no more people on the plane supporting the flight
    
    -- Remove the flight from the system
	DECLARE flight_exists BOOLEAN;
    DECLARE on_ground VARCHAR(100);
    DECLARE route_id VARCHAR(50);
    DECLARE final_leg INT;
    DECLARE final_leg_id VARCHAR(50);
    DECLARE current_leg INT;
    DECLARE location_id VARCHAR(50);
    DECLARE num_people INT;
    DECLARE arrival_airport_location_id VARCHAR(50);
    DECLARE support_airline_id VARCHAR(50);
    DECLARE support_tail_id VARCHAR(50);
    
    -- check if the flight exists
    SELECT COUNT(*) INTO flight_exists FROM flight WHERE flightID = ip_flightID;
    IF flight_exists = 0 THEN
		leave sp_main;
	END IF;
    
    -- check if flight is on ground
    SELECT airplane_status, routeID, progress, support_airline, support_tail
	INTO on_ground, route_id, current_leg, support_airline_id, support_tail_id
	FROM flight WHERE flightID = ip_flightID;
    
    IF on_ground != 'on_ground' THEN
		leave sp_main;
	END IF;
    
    -- no more legs (PDF also says if at start of route)
    SELECT sequence, legID INTO final_leg, final_leg_id
	FROM route_path
    WHERE routeID = route_id
	ORDER BY sequence DESC 
    LIMIT 1;    
    
	IF current_leg < final_leg and current_leg > 0 THEN
		leave sp_main;
	END IF;
    
    
    -- get location id of the airplane
    SELECT locationID into location_id
    FROM airplane
    WHERE airlineID = support_airline_id AND tail_num = support_tail_id;
    
    -- no people on flight
    SELECT COUNT(*) INTO num_people
    FROM person
	WHERE person.locationID = location_id;
    
    IF num_people > 0 THEN
		leave sp_main;
	END IF;
    
    DELETE FROM flight WHERE flightID = ip_flightID;
    
end //
delimiter ;

-- [13] simulation_cycle()
-- -----------------------------------------------------------------------------
/* This stored procedure executes the next step in the simulation cycle.  The flight
with the smallest next time in chronological order must be identified and selected.
If multiple flights have the same time, then flights that are landing should be
preferred over flights that are taking off.  Similarly, flights with the lowest
identifier in alphabetical order should also be preferred.

If an airplane is in flight and waiting to land, then the flight should be allowed
to land, passengers allowed to disembark, and the time advanced by one hour until
the next takeoff to allow for preparations.

If an airplane is on the ground and waiting to takeoff, then the passengers should
be allowed to board, and the time should be advanced to represent when the airplane
will land at its next location based on the leg distance and airplane speed.

If an airplane is on the ground and has reached the end of its route, then the
flight crew should be recycled to allow rest, and the flight itself should be
retired from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists simulation_cycle;
delimiter //
create procedure simulation_cycle ()
sp_main: begin

	-- Identify the next flight to be processed
    
    -- If the flight is in the air:
		-- Land the flight and disembark passengers
        -- If it has reached the end:
			-- Recycle crew and retire flight
            
	-- If the flight is on the ground:
		-- Board passengers and have the plane takeoff
        
	-- Hint: use the previously created procedures
	
    DECLARE next_flight_id VARCHAR(50);
    DECLARE next_flight_status VARCHAR(100);
    declare flight_progress int;
    declare route_ID varchar(50);
	declare max_leg int;
    
    -- get flight with smallest next time
    -- prioritize landing flights; meaning prioritize flights that are in_flight
    -- since only 2 possible values are 'in_flight' and 'on_ground'
    -- i < o, so sort by airplane_status ascending
    -- then prioritize flightID alphanumerically
    SELECT flightID, airplane_status, progress, routeID
    INTO next_flight_id, next_flight_status, flight_progress, route_ID
    FROM flight
    WHERE next_time = (SELECT MIN(next_time) FROM flight)
	ORDER BY airplane_status asc, flightID ASC limit 1;
    
    select max(sequence) into max_leg from route_path where routeID = route_ID;
    
    if next_flight_id is null then
		leave sp_main;
	end if;
    
    -- flight in air
    IF next_flight_status = 'in_flight' THEN
		CALL flight_landing(next_flight_id);
        CALL passengers_disembark(next_flight_id);
        
		select progress into flight_progress from flight where flightID = next_flight_id;
          
        if flight_progress >= max_leg then
            CALL recycle_crew(next_flight_id);
			CALL retire_flight(next_flight_id);
		end if;
        -- the following 2 methods already check to see if the flight is over
	elseif next_flight_status = 'on_ground' then
			CALL passengers_board(next_flight_id);
			CALL flight_takeoff(next_flight_id);
	else
		leave sp_main;
	end if;
	
end //
delimiter ;

-- [14] flights_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where flights that are currently airborne are located. 
We need to display what airports these flights are departing from, what airports 
they are arriving at, the number of flights that are flying between the 
departure and arrival airport, the list of those flights (ordered by their 
flight IDs), the earliest and latest arrival times for the destinations and the 
list of planes (by their respective flight IDs) flying these flights. */
-- -----------------------------------------------------------------------------
create or replace view flights_in_the_air (departing_from, arriving_at, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as
select l.departure, l.arrival, count(f.flightID), 
group_concat(distinct f.flightID order by f.flightID asc), min(f.next_time), max(f.next_time),
group_concat(distinct a.locationID order by f.flightID) from flight f join route_path rp on f.routeId = rp.routeID join leg l on rp.legID = l.legID
join airplane a on f.support_tail = a.tail_num where f.airplane_status = 'in_flight' and f.progress = rp.sequence group by l.departure, l.arrival;


-- [15] flights_on_the_ground()
-- ------------------------------------------------------------------------------
/* This view describes where flights that are currently on the ground are 
located. We need to display what airports these flights are departing from, how 
many flights are departing from each airport, the list of flights departing from 
each airport (ordered by their flight IDs), the earliest and latest arrival time 
amongst all of these flights at each airport, and the list of planes (by their 
respective flight IDs) that are departing from each airport.*/
-- ------------------------------------------------------------------------------
create or replace view flights_on_the_ground (departing_from, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as 
select l.departure, count(f.flightID), 
group_concat(distinct f.flightID order by f.flightID asc), min(f.next_time), max(f.next_time),
group_concat(distinct a.locationID order by f.flightID) from flight f left join route_path rp on f.routeId = rp.routeID left join leg l on l.legID = rp.legID
left join airplane a on f.support_tail = a.tail_num 
where f.airplane_status = 'on_ground' and (rp.sequence = f.progress + 1) 
group by l.legID
union
select l.arrival, count(f.flightID), 
group_concat(distinct f.flightID order by f.flightID asc), min(f.next_time), max(f.next_time),
group_concat(distinct a.locationID order by f.flightID) from flight f left join route_path rp on f.routeId = rp.routeID left join leg l on l.legID = rp.legID
left join airplane a on f.support_tail = a.tail_num where f.airplane_status = 'on_ground' and rp.sequence = f.progress group by l.legID;

-- [16] people_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently airborne are located. We 
need to display what airports these people are departing from, what airports 
they are arriving at, the list of planes (by the location id) flying these 
people, the list of flights these people are on (by flight ID), the earliest 
and latest arrival times of these people, the number of these people that are 
pilots, the number of these people that are passengers, the total number of 
people on the airplane, and the list of these people by their person id. */
-- -----------------------------------------------------------------------------
create or replace view people_in_the_air (departing_from, arriving_at, num_airplanes,
	airplane_list, flight_list, earliest_arrival, latest_arrival, num_pilots,
	num_passengers, joint_pilots_passengers, person_list) as
select leg.departure as departing_from, leg.arrival as arriving_at, COUNT(DISTINCT airplane.airlineID, airplane.tail_num) as num_airplanes, group_concat(distinct airplane.locationID) as airplane_list, group_concat(DISTINCT flight.flightID) as flight_list, MIN(flight.next_time) as earliest_arrival, MAX(flight.next_time) as latest_arrival, COUNT(DISTINCT pilot.personID) as num_pilots, COUNT(DISTINCT passenger.personID) as num_passengers, COUNT(DISTINCT person.personID) as joint_pilot_passengers, group_concat(DISTINCT person.personID) as person_list
FROM (person
	INNER JOIN airplane ON person.locationID = airplane.locationID
    INNER JOIN flight ON (airplane.airlineID = flight.support_airline AND airplane.tail_num = flight.support_tail)
    INNER JOIN route_path ON (route_path.routeID = flight.routeID AND route_path.sequence = flight.progress)
    INNER JOIN leg ON route_path.legID = leg.legID)
    LEFT JOIN pilot on person.personID = pilot.personID
    LEFT JOIN passenger on person.personID = passenger.personID
WHERE flight.airplane_status = 'in_flight'
GROUP BY leg.departure, leg.arrival;

-- [17] people_on_the_ground()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently on the ground and in an 
airport are located. We need to display what airports these people are departing 
from by airport id, location id, and airport name, the city and state of these 
airports, the number of these people that are pilots, the number of these people 
that are passengers, the total number people at the airport, and the list of 
these people by their person id. */
-- -----------------------------------------------------------------------------
create or replace view people_on_the_ground (departing_from, airport, airport_name,
	city, state, country, num_pilots, num_passengers, joint_pilots_passengers, person_list) as
select airport.airportID as departing_from, airport.locationID as airport, airport.airport_name as airport_name, airport.city as city, airport.state as state, airport.country as country, COUNT(DISTINCT pilot.personID) as num_pilots, COUNT(DISTINCT passenger.personID) as num_passengers, COUNT(DISTINCT person.personID) as joint_pilot_passengers, group_concat(DISTINCT person.personID) as person_list
FROM airport
	INNER JOIN person ON person.locationID = airport.locationID
    LEFT JOIN pilot on person.personID = pilot.personID
    LEFT JOIN passenger on person.personID = passenger.personID
GROUP BY airport.airportID;

-- select leg.departure as departing_from, airport.locationID as airport, airport.airport_name as airport_name, airport.city as city, airport.state as state, airport.country as country, COUNT(DISTINCT pilot.personID) as num_pilots, COUNT(DISTINCT passenger.personID) as num_passengers, COUNT(DISTINCT person.personID) as joint_pilot_passengers, group_concat(DISTINCT person.personID) as person_list
-- FROM (person
-- 	INNER JOIN airplane ON person.locationID = airplane.locationID
--     INNER JOIN flight ON (airplane.airlineID = flight.support_airline AND airplane.tail_num = flight.support_tail)
--     INNER JOIN route_path ON (route_path.routeID = flight.routeID AND route_path.sequence = flight.progress)
--     INNER JOIN leg ON route_path.legID = leg.legID
--     INNER JOIN airport ON airport.airportID = leg.departure)
--     LEFT JOIN pilot on person.personID = pilot.personID
--     LEFT JOIN passenger on person.personID = passenger.personID
-- WHERE flight.airplane_status = 'on_ground'
-- GROUP BY leg.departure;

-- [18] route_summary()
-- -----------------------------------------------------------------------------
/* This view will give a summary of every route. This will include the routeID, 
the number of legs per route, the legs of the route in sequence, the total 
distance of the route, the number of flights on this route, the flightIDs of 
those flights by flight ID, and the sequence of airports visited by the route. */
-- -----------------------------------------------------------------------------
create or replace view route_summary (route, num_legs, leg_sequence, route_length,
	num_flights, flight_list, airport_sequence) as
select r.routeID as route,
(select count(*) from route_path where routeID = r.routeID) as num_legs,
(select group_concat(legID order by sequence) from route_path where routeID = r.routeID) as leg_sequence,
(select sum(l.distance) from route_path rp join leg l on rp.legID = l.legID where rp.routeID = r.routeID) as route_length,
(select count(*) from flight where routeID = r.routeID) as num_flights,
(select group_concat(flightID order by flightID) from flight where routeID = r.routeID) as flight_list,
(select group_concat(concat(l.departure, '->', l.arrival) order by rp.sequence) from route_path rp 
join leg l on rp.legID = l.legID where rp.routeID = r.routeID) as airport_sequence 
from route r;


-- [19] alternative_airports()
-- -----------------------------------------------------------------------------
/* This view displays airports that share the same city and state. It should 
specify the city, state, the number of airports shared, and the lists of the 
airport codes and airport names that are shared both by airport ID. */
-- -----------------------------------------------------------------------------
create or replace view alternative_airports (city, state, country, num_airports,
	airport_code_list, airport_name_list) as
select city, state, country, count(airportID) as 'num_airports', 
group_concat(distinct airportID) as 'airport_code_list',
group_concat(distinct airport_name order by airportID) as 'airport_name_list'
from airport group by city, state, country having count(airportID) > 1 
order by count(airportID) desc;
