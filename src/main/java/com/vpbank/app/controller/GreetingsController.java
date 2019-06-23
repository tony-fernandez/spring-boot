package com.vpbank.app.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController("/greetings")
public class GreetingsController {

	@GetMapping
	public ResponseEntity<String> sayHello () {
		return ResponseEntity.ok("hello");
	}
	
}
