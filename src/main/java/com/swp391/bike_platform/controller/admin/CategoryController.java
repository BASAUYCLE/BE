package com.swp391.bike_platform.controller.admin;

import com.swp391.bike_platform.request.CategoryCreateRequest;
import com.swp391.bike_platform.request.CategoryUpdateRequest;
import com.swp391.bike_platform.response.admin.CategoryResponse;
import com.swp391.bike_platform.service.CategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/categories")
@RequiredArgsConstructor
public class CategoryController {
    private final CategoryService categoryService;

    @PostMapping
    CategoryResponse createCategory(@RequestBody CategoryCreateRequest request) {
        return categoryService.createCategory(request);
    }

    @GetMapping
    List<CategoryResponse> getAllCategories() {
        return categoryService.getAllCategories();
    }

    @GetMapping("/{categoryId}")
    CategoryResponse getCategoryById(@PathVariable Long categoryId) {
        return categoryService.getCategoryById(categoryId);
    }

    @PutMapping("/{categoryId}")
    CategoryResponse updateCategory(@PathVariable Long categoryId,
            @RequestBody CategoryUpdateRequest request) {
        return categoryService.updateCategory(categoryId, request);
    }

    @DeleteMapping("/{categoryId}")
    String deleteCategory(@PathVariable Long categoryId) {
        categoryService.deleteCategory(categoryId);
        return "Category has been deleted";
    }
}
