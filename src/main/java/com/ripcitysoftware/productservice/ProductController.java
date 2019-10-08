package com.ripcitysoftware.productservice;


import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.PagingAndSortingRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;
import org.springframework.stereotype.Repository;
import org.springframework.web.bind.annotation.*;

import javax.persistence.*;
import java.util.List;
import java.util.Optional;

@RestController
@Slf4j
public class ProductController {

    private final ProductRepository productRepository;

    public ProductController(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    @GetMapping("/products/{id}")
    @CrossOrigin
    @ResponseBody
    public Optional<Product> getProduct(@PathVariable("id") Long id) {
        log.info("/products/{} invoked!", id);
        return productRepository.findById(id);
    }
}

@Repository
@RepositoryRestResource
interface ProductRepository extends JpaRepository<Product, Long> {}

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@ToString
@Entity
@JsonIgnoreProperties
class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "product_id")
    private Long id;
    private String gtin;
    @Column(name = "company_name")
    private String companyName;
    @Column(name = "label_description")
    private String labelDescription;
    @Column(name = "medium_image_url")
    private String mediumImageUrl;
}

@Entity
class Person {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private long id;

    private String firstName;
    private String lastName;

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }
}

@RepositoryRestResource(collectionResourceRel = "people", path = "people")
interface PersonRepository extends PagingAndSortingRepository<Person, Long> {

    List<Person> findByLastName(@Param("name") String name);

}
