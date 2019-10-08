package com.ripcitysoftware.productservice;


import lombok.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@Slf4j
public class ProductController {

    @GetMapping("/products/{id}")
    @CrossOrigin
    @ResponseBody
    public Optional<Product> getProduct(@PathVariable("id") Long id) {
        log.info("/products/{} invoked!", id);
        return Optional.of(Product.builder()
                .id(1L)
                .companyName("sample company")
                .gtin("0123456789012")
                .labelDescription("KitKat is a perfect balance of chocolate and wafer first launched in the UK")
                .build());
    }
}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@ToString
class Product {
    private Long id;
    private String gtin;
    private String companyName;
    private String labelDescription;
    private String mediumImageUrl;
}

