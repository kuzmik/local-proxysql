# Create the RO specific user
CREATE USER 'persona-web-us1-ro1'@'%' IDENTIFIED BY 'persona-web-us1-ro1';
GRANT ALL PRIVILEGES ON `persona-web-us1`.* TO 'persona-web-us1-ro1'@'%';
GRANT FILE ON *.* TO 'persona-web-us1'@'%';

CREATE USER 'persona-web-us1-ro2'@'%' IDENTIFIED BY 'persona-web-us1-ro2';
GRANT ALL PRIVILEGES ON `persona-web-us1`.* TO 'persona-web-us1-ro2'@'%';

# Create a users table and some test users, just so we can visually see that the shards have different data.
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  first_name VARCHAR(255) NOT NULL,
  middle_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL
);

INSERT INTO users (email, first_name, middle_name, last_name, password)
VALUES ('rick@persona-us1.com', 'Rick', 'US1', 'Song', 'this-should-be-hashed-but-who-cares');

INSERT INTO users (email, first_name, middle_name, last_name, password)
VALUES ('nick@persona-us1.com', 'Nick', 'US1', 'Kuzmik', 'this-should-be-hashed-but-who-cares');
