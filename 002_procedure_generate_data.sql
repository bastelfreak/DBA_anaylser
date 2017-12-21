DELIMITER $$
DROP PROCEDURE IF EXISTS generate_data$$
CREATE PROCEDURE generate_data()
BEGIN
  DECLARE count INT DEFAULT 0;
  WHILE count < 100000 DO
    INSERT INTO bigdata.datasets (dataset) VALUES  (
      JSON_OBJECT('Birthday',
        (SELECT FROM_UNIXTIME(FLOOR(UNIX_TIMESTAMP(NOW() - INTERVAL 45 YEAR) + RAND() * (UNIX_TIMESTAMP(NOW() - INTERVAL 20 YEAR) - UNIX_TIMESTAMP(NOW() - INTERVAL 45 YEAR))))),
        'Gender',
        (SELECT
            name
          FROM
            genders
          ORDER BY RAND()
          LIMIT 1),
        'car_manufacturer',
        (SELECT
            name
          FROM
            car_manufacturers
          ORDER BY RAND()
          LIMIT 1),
        'federate_state',
        (SELECT
            name
          FROM
            federate_states
          ORDER BY RAND()
          LIMIT 1)));
   SET count = count + 1;
   END WHILE;
END$$
