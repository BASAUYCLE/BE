package com.swp391.bike_platform.service;

import com.swp391.bike_platform.entity.Category;
import com.swp391.bike_platform.enums.ErrorCode;
import com.swp391.bike_platform.exception.AppException;
import com.swp391.bike_platform.repository.CategoryRepository;
import com.swp391.bike_platform.request.CategoryCreateRequest;
import com.swp391.bike_platform.request.CategoryUpdateRequest;
import com.swp391.bike_platform.response.admin.CategoryResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class CategoryService {
    private final CategoryRepository categoryRepository;

    public CategoryResponse createCategory(CategoryCreateRequest request) {
        log.info("Creating category: {}", request.getCategoryName());

        if (categoryRepository.existsByCategoryName(request.getCategoryName())) {
            throw new AppException(ErrorCode.CATEGORY_EXISTED);
        }

        Category category = new Category();
        category.setCategoryName(request.getCategoryName().trim());

        if (request.getCategoryDescription() != null) {
            category.setCategoryDescription(request.getCategoryDescription().trim());
        }

        Category savedCategory = categoryRepository.save(category);
        log.info("Category created successfully: {}", savedCategory.getCategoryName());

        return toCategoryResponse(savedCategory);
    }

    public List<CategoryResponse> getAllCategories() {
        return categoryRepository.findAll().stream()
                .map(this::toCategoryResponse)
                .collect(Collectors.toList());
    }

    public CategoryResponse getCategoryById(Long id) {
        return toCategoryResponse(categoryRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.CATEGORY_NOT_EXISTED)));
    }

    public CategoryResponse updateCategory(Long id, CategoryUpdateRequest request) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.CATEGORY_NOT_EXISTED));

        if (request.getCategoryName() != null) {
            if (!category.getCategoryName().equals(request.getCategoryName())
                    && categoryRepository.existsByCategoryName(request.getCategoryName())) {
                throw new AppException(ErrorCode.CATEGORY_EXISTED);
            }
            category.setCategoryName(request.getCategoryName().trim());
        }

        if (request.getCategoryDescription() != null) {
            category.setCategoryDescription(request.getCategoryDescription().trim());
        }

        return toCategoryResponse(categoryRepository.save(category));
    }

    public void deleteCategory(Long id) {
        if (!categoryRepository.existsById(id)) {
            throw new AppException(ErrorCode.CATEGORY_NOT_EXISTED);
        }
        categoryRepository.deleteById(id);
    }

    private CategoryResponse toCategoryResponse(Category category) {
        return CategoryResponse.builder()
                .categoryId(category.getCategoryId())
                .categoryName(category.getCategoryName())
                .categoryDescription(category.getCategoryDescription())
                .createdAt(category.getCreatedAt())
                .updatedAt(category.getUpdatedAt())
                .build();
    }
}
