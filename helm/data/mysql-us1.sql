# Create the RO specific users
CREATE USER 'web-us1-ro0'@'%' IDENTIFIED BY 'web-us1-ro0';
GRANT ALL PRIVILEGES ON `web-us1`.* TO 'web-us1-ro0'@'%';

CREATE USER 'web-us1-ro1'@'%' IDENTIFIED BY 'web-us1-ro1';
GRANT ALL PRIVILEGES ON `web-us1`.* TO 'web-us1-ro1'@'%';

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
('rick@us1.com', 'Rick', 'US1', 'this-should-be-hashed-but-who-cares'),
('nick@us1.com', 'Nick', 'US1', 'this-should-be-hashed-but-who-cares');
