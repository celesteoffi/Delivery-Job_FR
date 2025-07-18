
CREATE TABLE IF NOT EXISTS `rk_jobdelivery` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `player_identifier` varchar(50) NOT NULL,
    `player_name` varchar(50) NOT NULL,
    `job_status` enum('active', 'completed', 'abandoned') NOT NULL DEFAULT 'active',
    `current_delivery` int(11) NOT NULL DEFAULT 1,
    `total_deliveries` int(11) NOT NULL,
    `deliveries_completed` int(11) NOT NULL DEFAULT 0,
    `vehicle_model` varchar(50) NOT NULL,
    `vehicle_coords` text NOT NULL,
    `start_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `end_time` timestamp NULL DEFAULT NULL,
    `total_earnings` int(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
);

