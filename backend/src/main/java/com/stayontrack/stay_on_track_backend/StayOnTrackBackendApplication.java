package com.stayontrack.stay_on_track_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = "com.stayontrack")
public class StayOnTrackBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(StayOnTrackBackendApplication.class, args);
	}

}
