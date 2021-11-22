/*
	Create table to store available units
*/
CREATE TABLE IF NOT EXISTS units (
	u_id SMALLINT PRIMARY KEY NOT NULL,
	u_name varchar(40) NOT NULL,
	u_ident char(1) NOT NULL
);

/*
	Create table to store KPIs
*/
CREATE TABLE IF NOT EXISTS kpis  (
	k_id SERIAL PRIMARY KEY NOT NULL,
    k_equipment char(10) NOT NULL,
	k_timestamp timestamptz NOT NULL,
	k_name VARCHAR(40) NOT NULL,
	k_unit SMALLINT NOT NULL,
	k_value NUMERIC(5,2) NOT NULL,
	FOREIGN KEY (k_unit) REFERENCES units (u_id)
);

/*
	Create table to store images
*/
CREATE TABLE IF NOT EXISTS images (
	i_id serial PRIMARY KEY NOT NULL,
    i_equipment char(10) NOT NULL,
	i_timestamp timestamptz NOT NULL,
	i_url varchar(255) NOT NULL
);

-- insert data for units
INSERT INTO units (u_id, u_name, u_ident)
VALUES 
(1, 'Degree Celcius', 'C'),
(2, 'Kelvin', 'K'),
(3, 'Fahrenheit', 'F'),
(4, 'Newton', 'N'),
(5, 'Kilogram', 'K'),
(6, 'Gram', 'G');