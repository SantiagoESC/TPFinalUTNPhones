DROP DATABASE IF EXISTS test;

CREATE DATABASE IF NOT EXISTS test;


USE test;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS provinces; 
CREATE TABLE IF NOT EXISTS provinces (
    idProvince INTEGER AUTO_INCREMENT,
    nameProvince VARCHAR(50) NOT NULL,
    CONSTRAINT pk_provinces PRIMARY KEY (idProvince),
    CONSTRAINT unq_name_province UNIQUE (nameProvince)
);



DROP TABLE IF EXISTS cities;
CREATE TABLE IF NOT EXISTS cities (
    idCity INTEGER AUTO_INCREMENT,
    nameCity VARCHAR(50) NOT NULL,
    prefix VARCHAR(5) NOT NULL,
    idProvince INTEGER NOT NULL,
    CONSTRAINT pk_cities PRIMARY KEY (idCity),
    CONSTRAINT unq_prefix_city UNIQUE (prefix),
    CONSTRAINT fk_city_province FOREIGN KEY (idProvince)
        REFERENCES provinces (idProvince)
);



DROP TABLE IF EXISTS rates ;
CREATE TABLE IF NOT EXISTS rates (
    idRate INTEGER AUTO_INCREMENT,
    idCityOrigin INTEGER NOT NULL,
    idCityDestination INTEGER NOT NULL,
    pricePerMinute FLOAT NOT NULL,
    CONSTRAINT pk_rates PRIMARY KEY (idRate),
    CONSTRAINT fk_origin_cities FOREIGN KEY (idCityOrigin)
        REFERENCES cities (idCity),
    CONSTRAINT fk_destination_cities FOREIGN KEY (idCityDestination)
        REFERENCES cities (idCity)
);



DROP TABLE IF EXISTS users;
CREATE TABLE IF NOT EXISTS users (
    idUser INTEGER AUTO_INCREMENT,
    username VARCHAR(25) NOT NULL,
    password VARCHAR(25) NOT NULL,
    firstName VARCHAR(25) NOT NULL,
    lastName VARCHAR(25) NOT NULL,
    dni VARCHAR(25) NOT NULL,
    userType ENUM('CLIENT', 'EMPLOYEE') NOT NULL,
    idCity INTEGER NOT NULL,
    CONSTRAINT pk_users PRIMARY KEY (idUser),
    CONSTRAINT unq_username UNIQUE (username),
    CONSTRAINT unq_dni UNIQUE (dni),
    CONSTRAINT fk_cities_rates FOREIGN KEY (idCity)
        REFERENCES cities (idCity)
);


DROP TABLE IF EXISTS phoneLines ;
CREATE TABLE IF NOT EXISTS phoneLines (
    idLine INTEGER AUTO_INCREMENT,
    numberLine VARCHAR(50) NOT NULL,
    typeLine ENUM('RESIDENTIAL', 'MOVILE') NOT NULL DEFAULT 'MOVILE',
    statusLine ENUM('ACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
    idUser INTEGER NOT NULL,
    CONSTRAINT pk_phonelines PRIMARY KEY (idLine),
    CONSTRAINT unq_numberLine UNIQUE (numberLine),
    CONSTRAINT fk_user_phoneLines FOREIGN KEY (idUser)
        REFERENCES users (idUser)
);



DROP TABLE IF EXISTS bills;
CREATE TABLE IF NOT EXISTS bills (
    idBill INTEGER AUTO_INCREMENT,
    idUser INTEGER NOT NULL ,
    idLine INTEGER NOT NULL,
    quantityOfCalls INTEGER NOT NULL DEFAULT 0,
    totalCost FLOAT NOT NULL DEFAULT 0,
    totalPrice FLOAT NOT NULL DEFAULT 0,
    dateBill DATETIME NOT NULL DEFAULT NOW(),
    dateExpiration DATETIME NOT NULL DEFAULT (CURRENT_DATE + INTERVAL 15 DAY),
    isPaidBill BOOLEAN NOT NULL DEFAULT FALSE,


    CONSTRAINT pk_bills PRIMARY KEY (idBill),
    CONSTRAINT fk_users_bills FOREIGN KEY(idUser) REFERENCES users(idUser),
    CONSTRAINT fk_line_bills FOREIGN KEY(idLine) REFERENCES phoneLines(idLine)
);


DROP TABLE IF EXISTS calls;
CREATE TABLE IF NOT EXISTS calls (
    idCall INTEGER AUTO_INCREMENT,
    idBill INTEGER,
    numberOrigin VARCHAR(15) NOT NULL,
    numberDestination VARCHAR(15) NOT NULL,
    idCityOrigin INTEGER NOT NULL,
    idCityDestination INTEGER NOT NULL,
    durationInSeconds INTEGER NOT NULL,
    pricePerMinute FLOAT NOT NULL,
    costPerMinute FLOAT NOT NULL DEFAULT 0.5,
    priceTotal FLOAT NOT NULL,
    dateCall DATETIME NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_calls PRIMARY KEY (idCall),
    CONSTRAINT fk_bills_calls FOREIGN KEY (idBill)
        REFERENCES bills (idBill),
    CONSTRAINT fk_origin_cities_calls FOREIGN KEY (idCityOrigin)
        REFERENCES cities (idCity),
    CONSTRAINT fk_destination_cities_calls FOREIGN KEY (idCityDestination)
        REFERENCES cities (idCity)
);



SET FOREIGN_KEY_CHECKS = 1;

DROP FUNCTION IF EXISTS fGetCostPerMinute;


DELIMITER //

CREATE FUNCTION  fGetCostPerMinute()
RETURNS FLOAT
DETERMINISTIC
BEGIN

    RETURN 1;

END//


DELIMITER ; 


DROP FUNCTION IF EXISTS fCalculateCity;

DELIMITER //
CREATE FUNCTION  fCalculateCity (pNumber VARCHAR(25) )
RETURNS INTEGER
 NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE vIdCity INTEGER DEFAULT 0;
    DECLARE vPrefix VARCHAR(5) DEFAULT '';


                SELECT
                    c.idCity, c.prefix  
                FROM
                    cities c
                WHERE
                    pNumber LIKE CONCAT(c.prefix, '%')

                GROUP BY

                    c.idCity,c.prefix  

                ORDER BY
                    LENGTH(c.prefix) DESC
                LIMIT
                    1
                INTO
                    vIdCity, vPrefix
                ;

        IF (vIdCity = 0) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error finding city to match prefix of number', MYSQL_ERRNO = '1';
        END IF;

RETURN vIdCity;
END//
DELIMITER ; 

DROP FUNCTION IF EXISTS fCalculatePrice;

DELIMITER //
CREATE FUNCTION  fCalculatePrice (pIdOrigin INTEGER, pIdDestination INTEGER)
RETURNS INTEGER
NOT DETERMINISTIC READS SQL DATA
BEGIN
    
    DECLARE vPrice FLOAT DEFAULT 0;

        SELECT 
            r.pricePerMinute 
            
        FROM 
                rates r 
                
        WHERE
        
         r.idCityOrigin = pIdOrigin AND r.idCityDestination = pIdDestination

        GROUP BY

            r.pricePerMinute

        INTO vPrice;

    IF (vPrice = 0) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error finding price per minute to apply to new call', MYSQL_ERRNO = '1';
    END IF;

    RETURN vPrice;

END//
DELIMITER ; 

DROP FUNCTION IF EXISTS fCalculateUser ;

DELIMITER //

CREATE FUNCTION fCalculateUser (pIdLine INTEGER)
RETURNS INTEGER
NOT DETERMINISTIC READS SQL DATA
BEGIN

    DECLARE vIdUser INTEGER DEFAULT 0;

    SELECT

        pl.idUser

    FROM

        phoneLines pl

    WHERE

        pl.idLine = pIdLine

    GROUP BY

        pl.idUser


    INTO

        vIdUser
    ;

    IF(vIdUser = 0) THEN
        SET @asd = CONCAT('Error findig user of line: ',pIdLine);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @asd , MYSQL_ERRNO = '1';  

    END IF;

    RETURN vIdUser;

END//

DELIMITER ;

DROP TRIGGER IF EXISTS tbiCalculateInsertCall;

DELIMITER //

CREATE TRIGGER tbiCalculateInsertCall BEFORE INSERT ON calls FOR EACH ROW
BEGIN

    SET NEW.idCityOrigin = fCalculateCity(NEW.numberOrigin);
    SET NEW.idCityDestination = fCalculateCity(NEW.numberDestination);
    SET NEW.pricePerMinute = fCalculatePrice(NEW.idCityOrigin, NEW.idCityDestination);
    SET NEW.costPerMinute = fGetCostPerMinute();
    SET NEW.priceTotal = (NEW.durationInSeconds/60)*NEW.pricePerMinute;


END//

DELIMITER ;


CREATE INDEX idxPhoneLines ON
phoneLines (numberLine, idUser ) USING HASH;


CREATE  INDEX idxCallDate ON calls(dateCall) USING BTREE;


DROP PROCEDURE IF EXISTS pliquidateLine;


DELIMITER // 

CREATE PROCEDURE pliquidateLine (pIdline int) 
BEGIN 
DECLARE vTotal float;

DECLARE vTotalCost float;

DECLARE vIdbill int;

DECLARE vIdcall int;

DECLARE vCant int DEFAULT 0;

DECLARE vFinished int DEFAULT 0;

DECLARE vSuma float DEFAULT 0;

DECLARE vSumaCost float DEFAULT 0;

DECLARE vDummy int;

DECLARE curbill CURSOR FOR
SELECT
    idCall,
    priceTotal,
    (costPerMinute * durationInSeconds / 60) AS costTotal
FROM
    calls c
    INNER JOIN phoneLines pl ON c.numberOrigin = pl.numberLine
WHERE
    idBill IS NULL && pl.idLine = pIdline
GROUP BY
    idCall,
    priceTotal;

DECLARE CONTINUE HANDLER FOR NOT FOUND
SET
    vFinished = 1;


INSERT INTO
    bills(idLine, dateBill, idUser, totalPrice)
VALUES
    (pIdline, NOW(), fCalculateUser(pIdline), 0);

#Se toma el idbill
SET
    vIdbill = LAST_INSERT_ID();

OPEN curbill;

FETCH curbill INTO vIdcall,
vTotal,
vTotalCost;

WHILE (vFinished = 0) DO
SET
    vSumaCost = vSumaCost + vTotalCost;

SET
    vSuma = vSuma + vTotal;

SET
    vCant = vCant + 1;

UPDATE calls 
SET 
    idBill = vIdbill
WHERE
    idCall = vIdcall;

FETCH curbill INTO vIdcall,
vTotal,
vTotalCost;

END WHILE;

UPDATE bills 
SET 
    quantityOfCalls = vCant,
    totalPrice = vSuma,
    totalCost = vSumaCost
WHERE
    idbill = vIdbill;

CLOSE curbill;

END // 
DELIMITER ;


DROP PROCEDURE IF EXISTS pliquidateActiveLines;
DELIMITER //
CREATE PROCEDURE  pliquidateActiveLines ()
BEGIN
    
    DECLARE vIdLine INTEGER;
    DECLARE vFinished INTEGER DEFAULT 0;
    DECLARE curLines CURSOR FOR SELECT idLine FROM phoneLines pl WHERE pl.statusLine ='ACTIVE' GROUP BY idLine ;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET vFinished = 1;
 

    OPEN curLines;
    FETCH curLines INTO vIdLine ;
    WHILE (vFinished=0) DO
        START TRANSACTION;
            CALL pliquidateLine(vIdLine);
        COMMIT;
        FETCH curLines INTO vIdLine;
    END WHILE;

    CLOSE curLines;
END//

DELIMITER ;

INSERT INTO
    provinces (nameProvince)
VALUES
    ('Buenos Aires');

INSERT INTO
    provinces (nameProvince)
VALUES
    ('Cordoba');

INSERT INTO
    cities (nameCity, prefix, idProvince)
VALUES
    ('Mar del Plata', '223', 1),
    ('Miramar ', '2234', 1),
    ('CABA', '11', 1),
    ('Cordoba', '543', 2);

INSERT INTO
    rates (idCityOrigin, idCityDestination, pricePerMinute)
SELECT
    O.idCity,
    D.idCity,
    10
FROM
    cities AS O,
    cities AS D;

INSERT INTO
    users (
        username,
        PASSWORD,
        firstName,
        lastName,
        dni,
        userType,
        idCity
    )
VALUES
    (
        'abulzomi',
        '1234',
        'Agustin',
        'Bulzomi',
        '42587965',
        'EMPLOYEE',
        1
    ),
    (
        'sescribas',
        '1234',
        'Santiago',
        'Escribas',
        '40256492',
        'EMPLOYEE',
        1
    );

INSERT INTO
    phoneLines (numberLine, typeLine, statusLine, idUser)
VALUES
    ('2235863779', 'MOVILE', 'ACTIVE', 1),
    ('2234211434', 'MOVILE', 'ACTIVE', 2);

INSERT INTO
    calls (
        numberOrigin,
        numberDestination,
        durationInseconds,
        dateCall
    )
VALUES
    ('2235863779', '2234211434', 180, '2020-03-15'),
    ('2234211434', '2235863779', 240, NOW()),
    ('2235863779', '2234211434', 60, NOW()),
    ('2235863779', '2234211434', 120, NOW());


DROP VIEW  IF EXISTS vCallReport;
CREATE VIEW vCallReport AS
    SELECT 
        ca.numberOrigin,
        co.nameCity AS cityOrigin,
        ca.numberDestination,
        cd.nameCity AS cityDestination,
        ca.priceTotal,
        ca.durationInSeconds AS DurationCall,
        ca.dateCall,
        pl.idUser
    FROM
        calls ca
            INNER JOIN
        cities co ON ca.idCityOrigin = co.idCity
            INNER JOIN
        cities cd ON ca.idCityDestination = cd.idCity
            INNER JOIN
        phoneLines pl ON pl.numberLine = ca.numberOrigin
;

SET GLOBAL event_scheduler = ON;
DROP EVENT IF EXISTS eLiquidateActiveLines ;

CREATE EVENT eLiquidateActiveLines
ON SCHEDULE EVERY 1 MONTH
STARTS '2020-08-01'
ENDS CURRENT_TIMESTAMP + INTERVAL 1 YEAR
ON COMPLETION PRESERVE
DO

    call pliquidateActiveLines();



