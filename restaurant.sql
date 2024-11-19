CREATE TABLE IF NOT EXISTS `restaurant_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `restaurant_id` varchar(50) NOT NULL,
  `item` varchar(50) NOT NULL,
  `stock` int(11) NOT NULL DEFAULT 0,
  `price` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  UNIQUE KEY `restaurant_item` (`restaurant_id`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `restaurant_accounts` (
  `restaurant_id` varchar(50) NOT NULL,
  `money` decimal(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`restaurant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `restaurant_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `restaurant_id` varchar(50) NOT NULL,
  `type` varchar(20) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `description` varchar(255) NOT NULL,
  `employee_name` varchar(50) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `restaurant_storage` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `restaurant_id` varchar(50) NOT NULL,
  `item` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `storage_item` (`restaurant_id`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;