--# Sample code to demo how to break up huge updates and delete operation using automated while loops

DELIMITER $$
DROP PROCEDURE IF EXISTS updateCrews;
CREATE PROCEDURE updateCrews(forDate DATETIME)
BEGIN
    DECLARE effectedCount INT;
    DECLARE updateDate DATETIME;
    
    -- Record the current_date() as based on the system date, this will be used in the update later
    SET updateDate := CURRENT_TIMESTAMP();

    -- Repeat the Updates for 10k rows until no more rows available for the old date
    REPEAT 
        -- Update the test_table with dummy random values except for the creation_date which gets updated byu the current_date()
        UPDATE tab SET `status` = round(rand()*125, 0), 
                                http_status = round(rand()*100000000,0), 
                                result = concat('Data - ', round(rand()*100000000, 0)),
                                creation_date = updateDate
        WHERE CREATION_DATE = forDate
        LIMIT 10000;

        -- Get the number of rows effected by the above update statement
        SET effectedCount := ROW_COUNT();

    -- Check if the effected rows are more than 0 then continue else exit the repeat loop
    UNTIL effectedCount = 0 END REPEAT;
END$$
DELIMITER ;

DELIMITER $$
DROP PROCEDURE IF EXISTS deleteCrews;
CREATE PROCEDURE updateCrews(forDate DATETIME)
BEGIN
    DECLARE effectedCount INT;
    
    -- Record the current_date() as based on the system date, this will be used in the update later
    SET updateDate := CURRENT_TIMESTAMP();

    -- Repeat the Updates for 10k rows until no more rows available for the old date
    REPEAT 
        -- Update the test_table with dummy random values except for the creation_date which gets updated byu the current_date()
        DELETE FROM tab WHERE CREATION_DATE = forDate
        LIMIT 10000;

        -- Get the number of rows effected by the above update statement
        SET effectedCount := ROW_COUNT();

    -- Check if the effected rows are more than 0 then continue else exit the repeat loop
    UNTIL effectedCount = 0 END REPEAT;
END$$
DELIMITER ;
