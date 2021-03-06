DROP FUNCTION IF EXISTS fCalculateLine ;

DELIMITER //

CREATE FUNCTION fCalculateLine (pNumberLine VARCHAR(50))
RETURNS INTEGER
NOT DETERMINISTIC READS SQL DATA
BEGIN

    DECLARE vIdLine INTEGER DEFAULT 0;


    SELECT

        idLine

    FROM

        phoneLines pl

    WHERE

        pl.numberLine = pNumberLine

    GROUP BY

        idLine, numberLine

    INTO

        vIdLine

    ;

    IF (vIdLine = 0) THEN

         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error finding line for number specified', MYSQL_ERRNO = '1';

    END IF;    


    RETURN vIdLine;

END//

DELIMITER ;
