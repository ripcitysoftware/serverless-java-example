package com.ripcitysoftware.productservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Import;

@SpringBootApplication
@Import({ProductController.class})
public class ProductServivce {

	public static void main(String[] args) {
		SpringApplication.run(ProductServivce.class, args);
	}

}
