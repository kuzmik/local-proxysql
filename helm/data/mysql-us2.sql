# Create the RO specific user
CREATE USER 'persona-web-us2-ro1'@'%' IDENTIFIED BY 'persona-web-us2-ro1';
GRANT ALL PRIVILEGES ON `persona-web-us2`.* TO 'persona-web-us2-ro1'@'%';

CREATE USER 'persona-web-us2-ro2'@'%' IDENTIFIED BY 'persona-web-us2-ro2';
GRANT ALL PRIVILEGES ON `persona-web-us2`.* TO 'persona-web-us2-ro2'@'%';

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
VALUES ('charles@persona-us2.com', 'Charles', 'US2', 'Yeh', 'this-should-be-hashed-but-who-cares');

INSERT INTO users (email, first_name, middle_name, last_name, password)
VALUES ('ian@persona-us2.com', 'Ian', 'US2', 'Chesal', 'this-should-be-hashed-but-who-cares');
