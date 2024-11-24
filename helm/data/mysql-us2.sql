# Create the RO specific user
CREATE USER 'web-us2-ro1'@'%' IDENTIFIED BY 'web-us2-ro1';
GRANT ALL PRIVILEGES ON `web-us2`.* TO 'web-us2-ro1'@'%';
GRANT FILE ON *.* TO 'web-us2'@'%';

CREATE USER 'web-us2-ro2'@'%' IDENTIFIED BY 'web-us2-ro2';
GRANT ALL PRIVILEGES ON `web-us2`.* TO 'web-us2-ro2'@'%';

# Create a users table and some test users, just so we can visually see that the shards have different data.
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL
);

INSERT INTO users (email, first_name, last_name, password)
VALUES
('charles@us2.com', 'Charles', 'US2', 'this-should-be-hashed-but-who-cares'),
('ian@us2.com', 'Ian', 'US2', 'this-should-be-hashed-but-who-cares');
