package com.swp391.bike_platform;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableAsync
@EnableScheduling
public class BikePlatformApplication {

	public static void main(String[] args) {
		SpringApplication.run(BikePlatformApplication.class, args);
	}

}
