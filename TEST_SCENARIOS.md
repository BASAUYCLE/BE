# TEST SCENARIOS - BASAUYCLE Platform

## Mục Lục

1. [Authentication](#1-authentication)
2. [User Management](#2-user-management)
3. [Brand Management](#3-brand-management)
4. [Category Management](#4-category-management)
5. [Bicycle Posts](#5-bicycle-posts)
6. [Admin Post Management](#6-admin-post-management)
7. [Admin User Management](#7-admin-user-management)
8. [Inspector](#8-inspector)
9. [Bicycle Images](#9-bicycle-images)
10. [File Upload](#10-file-upload)

---

## Quy ước

| Ký hiệu | Nghĩa |
|---------|-------|
| 🔓 | Public (không cần auth) |
| 🔐 | Authenticated (cần token) |
| 👤 | Member only |
| 👨‍💼 | Admin only |
| 🔍 | Inspector only |

---

## 1. AUTHENTICATION

### 1.1 Đăng ký tài khoản 🔓

**Endpoint:** `POST /auth/register`

**Request (form-data):**
| Field | Type | Required | Example |
|-------|------|----------|---------|
| fullName | string | ✅ | Nguyễn Văn A |
| email | string | ✅ | nguyenvana@email.com |
| password | string | ✅ | Password123! |
| phoneNumber | string | ✅ | 0901234567 |
| cccdFront | file | ✅ | cccd_front.jpg |
| cccdBack | file | ✅ | cccd_back.jpg |

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Đăng ký thành công với đầy đủ thông tin | 200 - User created |
| 2 | Email đã tồn tại | 400 - USER_EXISTED (1002) |
| 3 | Email không hợp lệ (không có @) | 400 - INVALID_EMAIL (1011) |
| 4 | Password < 8 ký tự | 400 - INVALID_PASSWORD (1004) |
| 5 | Thiếu cccdFront | 400 - Bad Request |
| 6 | Thiếu cccdBack | 400 - Bad Request |
| 7 | Thiếu email | 400 - Bad Request |
| 8 | Thiếu password | 400 - Bad Request |
| 9 | File cccd không phải image | 400 - Bad Request |

---

### 1.2 Đăng nhập 🔓

**Endpoint:** `POST /auth/login`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Login thành công | 200 - JWT token (authenticated: true) |
| 2 | Email không tồn tại | 404 - USER_NOT_EXISTED (1005) |
| 3 | Sai password | 401 - UNAUTHENTICATED (1006) |
| 4 | User chưa được verify | 403 - UNAUTHORIZED (1007) |
| 5 | Thiếu email | 400 - Bad Request |
| 6 | Thiếu password | 400 - Bad Request |

---

### 1.3 Introspect Token 🔓

**Endpoint:** `POST /auth/introspect`

**Request:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Token hợp lệ | 200 - valid: true |
| 2 | Token hết hạn | 200 - valid: false |
| 3 | Token không hợp lệ (random string) | 200 - valid: false |
| 4 | Token rỗng | 200 - valid: false |

---

## 2. USER MANAGEMENT

### 2.1 Xem thông tin cá nhân 🔐

**Endpoint:** `GET /users/myinfo`

**Headers:** `Authorization: Bearer {token}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Token hợp lệ | 200 - User info |
| 2 | Không có token | 401 - Unauthorized |
| 3 | Token hết hạn | 401 - TOKEN_EXPIRED (1009) |
| 4 | Token không hợp lệ | 401 - INVALID_TOKEN (1008) |

---

### 2.2 Cập nhật thông tin cá nhân 🔐

**Endpoint:** `PUT /users/myinfo`

**Request:**
```json
{
  "fullName": "Nguyễn Văn A Updated",
  "email": "newemail@example.com",
  "phoneNumber": "0909876543",
  "address": "456 Đường XYZ, HCM"
}
```

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Cập nhật thành công (tất cả fields) | 200 - Updated user |
| 2 | Cập nhật chỉ fullName | 200 - Updated user |
| 3 | Cập nhật chỉ phoneNumber | 200 - Updated user |
| 4 | Cập nhật email thành email đã tồn tại | 400 - USER_EXISTED (1002) |
| 5 | Không có token | 401 - Unauthorized |

---

### 2.3 Lấy tất cả users 👨‍💼

**Endpoint:** `GET /users`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Admin request | 200 - List users |
| 2 | Member request | 403 - Forbidden |
| 3 | Không có token | 401 - Unauthorized |

---

### 2.4 Lấy user theo ID 👨‍💼

**Endpoint:** `GET /users/{userId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | User tồn tại | 200 - User info |
| 2 | User không tồn tại | 404 - USER_NOT_EXISTED (1005) |
| 3 | Member request | 403 - Forbidden |

---

### 2.5 Lấy user theo email 👨‍💼

**Endpoint:** `GET /users/email/{email}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Email tồn tại | 200 - User info |
| 2 | Email không tồn tại | 404 - USER_NOT_EXISTED (1005) |
| 3 | Member request | 403 - Forbidden |

---

### 2.6 Cập nhật user (Admin) 👨‍💼

**Endpoint:** `PUT /users/{userId}`

**Request:**
```json
{
  "fullName": "Admin Updated Name",
  "email": "updated@email.com",
  "phoneNumber": "0901111111",
  "address": "789 Đường DEF"
}
```

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Admin cập nhật thành công | 200 - Updated user |
| 2 | User không tồn tại | 404 - USER_NOT_EXISTED (1005) |
| 3 | Member cố cập nhật | 403 - Forbidden |

---

### 2.7 Xóa user 👨‍💼

**Endpoint:** `DELETE /users/{userId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Xóa thành công | 200 - "User has been deleted" |
| 2 | User không tồn tại | 404 - USER_NOT_EXISTED (1005) |
| 3 | Member cố xóa | 403 - Forbidden |

---

## 3. BRAND MANAGEMENT

### 3.1 Lấy tất cả brands 🔓

**Endpoint:** `GET /brands`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Có brands | 200 - List brands |
| 2 | Không có brands | 200 - [] |

---

### 3.2 Lấy brand theo ID 🔓

**Endpoint:** `GET /brands/{brandId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Brand tồn tại | 200 - Brand info |
| 2 | Brand không tồn tại | 404 - BRAND_NOT_EXISTED (1015) |

---

### 3.3 Tạo brand 👨‍💼

**Endpoint:** `POST /brands`

**Request (form-data):**
| Field | Type | Required | Example |
|-------|------|----------|---------|
| brandName | string | ✅ | Trek |
| brandLogo | file | ❌ | trek_logo.png |

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Admin tạo thành công (với logo) | 200 - Brand created |
| 2 | Admin tạo thành công (không logo) | 200 - Brand created |
| 3 | Brand đã tồn tại | 400 - BRAND_EXISTED (1014) |
| 4 | Member cố tạo | 403 - Forbidden |
| 5 | Không có token | 401 - Unauthorized |

---

### 3.4 Cập nhật brand 👨‍💼

**Endpoint:** `PUT /brands/{brandId}`

**Request (form-data):**
| Field | Type | Required |
|-------|------|----------|
| brandName | string | ❌ |
| brandLogo | file | ❌ |

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Admin cập nhật brandName | 200 - Updated brand |
| 2 | Admin cập nhật brandLogo | 200 - Updated brand |
| 3 | Admin cập nhật cả hai | 200 - Updated brand |
| 4 | Brand không tồn tại | 404 - BRAND_NOT_EXISTED (1015) |
| 5 | Member cố cập nhật | 403 - Forbidden |

---

### 3.5 Xóa brand 👨‍💼

**Endpoint:** `DELETE /brands/{brandId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Xóa thành công | 200 - "Brand has been deleted" |
| 2 | Brand không tồn tại | 404 - BRAND_NOT_EXISTED (1015) |
| 3 | Member cố xóa | 403 - Forbidden |

---

## 4. CATEGORY MANAGEMENT

### 4.1 Lấy tất cả categories 🔓

**Endpoint:** `GET /categories`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Có categories | 200 - List categories |
| 2 | Không có categories | 200 - [] |

---

### 4.2 Lấy category theo ID 🔓

**Endpoint:** `GET /categories/{categoryId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Category tồn tại | 200 - Category info |
| 2 | Category không tồn tại | 404 - CATEGORY_NOT_EXISTED (1017) |

---

### 4.3 Tạo category 👨‍💼

**Endpoint:** `POST /categories`

**Request:**
```json
{
  "categoryName": "Road Bike",
  "categoryDescription": "Xe đạp đua đường trường"
}
```

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Admin tạo thành công | 200 - Category created |
| 2 | Category đã tồn tại | 400 - CATEGORY_EXISTED (1016) |
| 3 | Member cố tạo | 403 - Forbidden |
| 4 | Thiếu categoryName | 400 - Bad Request |
| 5 | Không có token | 401 - Unauthorized |

---

### 4.4 Cập nhật category 👨‍💼

**Endpoint:** `PUT /categories/{categoryId}`

**Request:**
```json
{
  "categoryName": "Mountain Bike Updated",
  "categoryDescription": "Xe đạp leo núi - cập nhật"
}
```

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Admin cập nhật thành công | 200 - Updated category |
| 2 | Category không tồn tại | 404 - CATEGORY_NOT_EXISTED (1017) |
| 3 | Cập nhật thành tên đã tồn tại | 400 - CATEGORY_EXISTED (1016) |
| 4 | Member cố cập nhật | 403 - Forbidden |

---

### 4.5 Xóa category 👨‍💼

**Endpoint:** `DELETE /categories/{categoryId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Xóa thành công | 200 - "Category has been deleted" |
| 2 | Category không tồn tại | 404 - CATEGORY_NOT_EXISTED (1017) |
| 3 | Member cố xóa | 403 - Forbidden |

---

## 5. BICYCLE POSTS

### 5.1 Lấy tất cả posts 🔓

**Endpoint:** `GET /posts`

> **Note:** Chỉ trả về posts với status: AVAILABLE, DEPOSITED, SOLD

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Có posts | 200 - List posts (only AVAILABLE/DEPOSITED/SOLD) |
| 2 | Không có posts | 200 - [] |
| 3 | Verify PENDING posts không hiển thị | 200 - List không chứa PENDING |
| 4 | Verify DRAFTED posts không hiển thị | 200 - List không chứa DRAFTED |
| 5 | Verify HIDDEN posts không hiển thị | 200 - List không chứa HIDDEN |

---

### 5.2 Lấy post theo ID 🔓

**Endpoint:** `GET /posts/{postId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Post tồn tại | 200 - Post info (with images) |
| 2 | Post không tồn tại | 404 - POST_NOT_EXISTED (1018) |
| 3 | PostId không hợp lệ (string) | 400 - Bad Request |

---

### 5.3 Tạo post 🔐

**Endpoint:** `POST /posts`

**Request:**
```json
{
  "sellerId": 1,
  "brandId": 1,
  "categoryId": 1,
  "bicycleName": "Trek Madone SLR 9",
  "bicycleColor": "Black/Red",
  "price": 150000000,
  "bicycleDescription": "Xe đạp đường trường cao cấp",
  "groupset": "Shimano Dura-Ace Di2",
  "frameMaterial": "Carbon",
  "brakeType": "Disc",
  "size": "M (53 - 55) / 165 - 175 cm",
  "modelYear": 2024
}
```

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Tạo thành công | 200 - Post với status PENDING |
| 2 | Brand không tồn tại | 404 - BRAND_NOT_EXISTED (1015) |
| 3 | Category không tồn tại | 404 - CATEGORY_NOT_EXISTED (1017) |
| 4 | Thiếu bicycleName | 400 - MISSING_REQUIRED_FIELD (1022) |
| 5 | Thiếu price | 400 - MISSING_REQUIRED_FIELD (1022) |
| 6 | Thiếu sellerId | 400 - MISSING_REQUIRED_FIELD (1022) |
| 7 | Size không hợp lệ | 400 - INVALID_SIZE (1021) |
| 8 | Không có token | 401 - Unauthorized |

---

### 5.4 Lấy posts của tôi 🔐

**Endpoint:** `GET /posts/my-posts`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | User có posts | 200 - List posts (all statuses) |
| 2 | User không có posts | 200 - [] |
| 3 | Không có token | 401 - Unauthorized |

---

### 5.5 Tạo draft post 🔐

**Endpoint:** `POST /posts/draft`

**Request:**
```json
{
  "brandId": 1,
  "categoryId": 1,
  "bicycleName": "Trek Madone SLR",
  "bicycleColor": "Red",
  "price": 15000000,
  "bicycleDescription": "Xe đạp draft",
  "groupset": "Shimano Ultegra Di2",
  "frameMaterial": "Carbon",
  "brakeType": "Disc",
  "size": "M (53 - 55) / 165 - 175 cm",
  "modelYear": 2024
}
```

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Tạo thành công | 200 - Post với status DRAFTED |
| 2 | Brand không tồn tại | 404 - BRAND_NOT_EXISTED (1015) |
| 3 | Category không tồn tại | 404 - CATEGORY_NOT_EXISTED (1017) |
| 4 | Không có token | 401 - Unauthorized |

---

### 5.6 Lấy drafts của tôi 🔐

**Endpoint:** `GET /posts/drafts`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | User có drafts | 200 - List draft posts |
| 2 | User không có drafts | 200 - [] |
| 3 | Không có token | 401 - Unauthorized |

---

### 5.7 Lấy posts theo seller 🔓

**Endpoint:** `GET /posts/seller/{sellerId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Seller có posts | 200 - List posts |
| 2 | Seller không có posts | 404 - USER_HAS_NO_POSTS (1023) |
| 3 | Seller không tồn tại | 404 - USER_NOT_EXISTED (1005) |

---

### 5.8 Lấy posts theo brand 🔓

**Endpoint:** `GET /posts/brand/{brandId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Brand có posts | 200 - List posts |
| 2 | Brand không có posts | 404 - NO_POSTS_FOR_BRAND (1024) |
| 3 | Brand không tồn tại | 404 - BRAND_NOT_EXISTED (1015) |

---

### 5.9 Lấy posts theo category 🔓

**Endpoint:** `GET /posts/category/{categoryId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Category có posts | 200 - List posts |
| 2 | Category không có posts | 404 - NO_POSTS_FOR_CATEGORY (1025) |
| 3 | Category không tồn tại | 404 - CATEGORY_NOT_EXISTED (1017) |

---

### 5.10 Lấy posts theo size 🔓

**Endpoint:** `GET /posts/size/{size}`

> **Note:** Size cần URL encode. VD: `M%20(53%20-%2055)%20/%20165%20-%20175%20cm`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Size có posts | 200 - List posts |
| 2 | Size không có posts | 404 - NO_POSTS_FOR_SIZE (1026) |
| 3 | Size không hợp lệ | 400 - INVALID_SIZE (1021) |

---

### 5.11 Tìm kiếm theo giá 🔓

**Endpoint:** `GET /posts/search?minPrice=10000000&maxPrice=50000000`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Có posts trong khoảng giá | 200 - List posts |
| 2 | Không có posts trong khoảng giá | 404 - NO_POSTS_FOR_PRICE_RANGE (1028) |
| 3 | Chỉ có minPrice (thiếu maxPrice) | 200 - Trả tất cả posts |
| 4 | Chỉ có maxPrice (thiếu minPrice) | 200 - Trả tất cả posts |
| 5 | Không có params | 200 - Trả tất cả posts |
| 6 | minPrice > maxPrice | 200 - [] |

---

### 5.12 Cập nhật post 🔐

**Endpoint:** `PUT /posts/{postId}`

**Request:**
```json
{
  "brandId": 2,
  "categoryId": 2,
  "bicycleName": "Updated Bike Name",
  "bicycleColor": "Blue",
  "price": 20000000,
  "bicycleDescription": "Mô tả cập nhật",
  "groupset": "SRAM Red eTap",
  "frameMaterial": "Carbon",
  "brakeType": "Rim",
  "size": "L (55 - 58) / 175 - 185 cm",
  "modelYear": 2025
}
```

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Owner cập nhật post PENDING | 200 - Full update allowed (all fields) |
| 2 | Owner cập nhật post AVAILABLE | 200 - Limited update (price, description only) |
| 3 | Post DEPOSITED | 400 - POST_UPDATE_NOT_ALLOWED (1020) |
| 4 | Post SOLD | 400 - POST_UPDATE_NOT_ALLOWED (1020) |
| 5 | Không phải owner | 403 - Forbidden |
| 6 | Post không tồn tại | 404 - POST_NOT_EXISTED (1018) |
| 7 | Không có token | 401 - Unauthorized |

---

### 5.13 Xóa post 🔐

**Endpoint:** `DELETE /posts/{postId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Owner xóa post | 200 - "Bicycle post has been deleted" |
| 2 | Không phải owner | 403 - Forbidden |
| 3 | Post không tồn tại | 404 - POST_NOT_EXISTED (1018) |
| 4 | Không có token | 401 - Unauthorized |

---

## 6. ADMIN POST MANAGEMENT

### 6.1 Lấy tất cả posts 👨‍💼

**Endpoint:** `GET /admin/posts`

> **Note:** Trả về TẤT CẢ posts (mọi status)

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Admin request | 200 - List tất cả posts |
| 2 | Member request | 403 - Forbidden |
| 3 | Inspector request | 403 - Forbidden |
| 4 | Không có token | 401 - Unauthorized |

---

### 6.2 Lấy posts theo status 👨‍💼

**Endpoint:** `GET /admin/posts/status/{status}`

**Valid statuses:** DRAFTED, PENDING, ADMIN_APPROVED, AVAILABLE, DEPOSITED, SOLD, REJECTED, HIDDEN

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Status = PENDING | 200 - List pending posts |
| 2 | Status = AVAILABLE | 200 - List available posts |
| 3 | Status = DRAFTED | 200 - List drafted posts |
| 4 | Status không hợp lệ | 404 - NO_POSTS_FOR_STATUS (1027) |
| 5 | Member request | 403 - Forbidden |

---

### 6.3 Lấy posts chờ duyệt 👨‍💼

**Endpoint:** `GET /admin/posts/pending`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Có posts pending | 200 - List pending posts |
| 2 | Không có posts pending | 200 - [] |
| 3 | Member request | 403 - Forbidden |

---

### 6.4 Duyệt post 👨‍💼

**Endpoint:** `PUT /admin/posts/{postId}/approve`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Post PENDING → approve | 200 - Status → ADMIN_APPROVED |
| 2 | Post không PENDING | 400 - INVALID_POST_STATUS (1033) |
| 3 | Post không tồn tại | 404 - POST_NOT_EXISTED (1018) |
| 4 | Member request | 403 - Forbidden |

---

### 6.5 Từ chối post 👨‍💼

**Endpoint:** `PUT /admin/posts/{postId}/reject`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Post PENDING → reject | 200 - Status → REJECTED |
| 2 | Post không PENDING | 400 - INVALID_POST_STATUS (1033) |
| 3 | Post không tồn tại | 404 - POST_NOT_EXISTED (1018) |
| 4 | Member request | 403 - Forbidden |

---

### 6.6 Ẩn post 👨‍💼

**Endpoint:** `PUT /admin/posts/{postId}/hide`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Ẩn thành công | 200 - Status → HIDDEN |
| 2 | Post không tồn tại | 404 - POST_NOT_EXISTED (1018) |
| 3 | Member request | 403 - Forbidden |

---

## 7. ADMIN USER MANAGEMENT

### 7.1 Lấy tất cả users 👨‍💼

**Endpoint:** `GET /admin/users`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Admin request | 200 - List users (ApiResponse) |
| 2 | Member request | 403 - Forbidden |
| 3 | Không có token | 401 - Unauthorized |

---

### 7.2 Lấy users chờ verify 👨‍💼

**Endpoint:** `GET /admin/users/pending`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Có pending users | 200 - List pending users |
| 2 | Không có pending users | 200 - [] |
| 3 | Member request | 403 - Forbidden |

---

### 7.3 Verify user 👨‍💼

**Endpoint:** `POST /admin/users/verify`

**Request (APPROVE):**
```json
{
  "userId": 1,
  "action": "APPROVE"
}
```

**Request (REJECT):**
```json
{
  "userId": 1,
  "action": "REJECT",
  "reason": "CCCD không hợp lệ"
}
```

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Approve user chờ verify | 200 - User verified + Email sent |
| 2 | Reject user chờ verify | 200 - User rejected + Email sent |
| 3 | Action không hợp lệ (khác APPROVE/REJECT) | 400 - INVALID_VERIFY_ACTION (1030) |
| 4 | User đã verified rồi | 400 - USER_ALREADY_VERIFIED (1031) |
| 5 | User đã rejected rồi | 400 - USER_ALREADY_REJECTED (1032) |
| 6 | User không tồn tại | 404 - USER_NOT_EXISTED (1005) |
| 7 | Member request | 403 - Forbidden |
| 8 | Reject mà thiếu reason | 400 - Bad Request |

---

### 7.4 Lấy user theo ID 👨‍💼

**Endpoint:** `GET /admin/users/{userId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | User tồn tại | 200 - User info (ApiResponse) |
| 2 | User không tồn tại | 404 - USER_NOT_EXISTED (1005) |
| 3 | Member request | 403 - Forbidden |

---

## 8. INSPECTOR

### 8.1 Lấy posts chờ kiểm định 🔍

**Endpoint:** `GET /inspection/pending`

> **Note:** Trả về posts với status ADMIN_APPROVED

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Có posts chờ kiểm định | 200 - List BicyclePostSummaryResponse |
| 2 | Không có posts chờ | 200 - [] |
| 3 | Member request | 403 - Forbidden |
| 4 | Không có token | 401 - Unauthorized |

---

### 8.2 Submit kiểm định 🔍

**Endpoint:** `POST /inspection/{postId}/submit`

**Request:**
```json
{
  "result": "PASS",
  "overallCondition": "GOOD",
  "notes": "Xe trong tình trạng tốt, đúng mô tả"
}
```

**Valid values:**

| Field | Values |
|-------|--------|
| result | PASS, FAIL |
| overallCondition | EXCELLENT, GOOD, FAIR, POOR |

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | PASS → AVAILABLE | 200 - InspectionReportResponse, post status → AVAILABLE |
| 2 | FAIL → REJECTED | 200 - InspectionReportResponse, post status → REJECTED |
| 3 | Post không ADMIN_APPROVED | 400 - INVALID_POST_STATUS (1033) |
| 4 | Post không tồn tại | 404 - POST_NOT_EXISTED (1018) |
| 5 | Member request | 403 - Forbidden |
| 6 | Thiếu result | 400 - Bad Request |
| 7 | Result không hợp lệ (khác PASS/FAIL) | 400 - Bad Request |
| 8 | Không có token | 401 - Unauthorized |

---

## 9. BICYCLE IMAGES

### 9.1 Tạo image cho post 🔐

**Endpoint:** `POST /images`

**Request (form-data):**
| Field | Type | Required | Example |
|-------|------|----------|---------|
| postId | number | ✅ | 1 |
| image | file | ✅ | bike_photo.jpg |
| imageType | string | ❌ | MAIN |
| isThumbnail | boolean | ❌ | true |

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Upload thành công | 200 - BicycleImageResponse |
| 2 | Post không tồn tại | 404 - POST_NOT_EXISTED (1018) |
| 3 | Thiếu image file | 400 - Bad Request |
| 4 | Thiếu postId | 400 - Bad Request |
| 5 | File không phải image | 400 - Bad Request |
| 6 | Không có token | 401 - Unauthorized |

---

### 9.2 Lấy images theo post 🔓

**Endpoint:** `GET /images/post/{postId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Post có images | 200 - List BicycleImageResponse |
| 2 | Post không có images | 200 - [] |
| 3 | Post không tồn tại | 404 - POST_NOT_EXISTED (1018) |

---

### 9.3 Lấy image theo ID 🔓

**Endpoint:** `GET /images/{imageId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Image tồn tại | 200 - BicycleImageResponse |
| 2 | Image không tồn tại | 404 - IMAGE_NOT_EXISTED (1019) |

---

### 9.4 Cập nhật image 🔐

**Endpoint:** `PUT /images/{imageId}`

**Request (form-data):**
| Field | Type | Required |
|-------|------|----------|
| image | file | ❌ |
| imageType | string | ❌ |
| isThumbnail | boolean | ❌ |

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Cập nhật image file mới | 200 - Updated BicycleImageResponse |
| 2 | Cập nhật imageType | 200 - Updated BicycleImageResponse |
| 3 | Image không tồn tại | 404 - IMAGE_NOT_EXISTED (1019) |
| 4 | Không có token | 401 - Unauthorized |

---

### 9.5 Xóa image 🔐

**Endpoint:** `DELETE /images/{imageId}`

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Xóa image thành công | 200 - "Bicycle image has been deleted" |
| 2 | Image không tồn tại | 404 - IMAGE_NOT_EXISTED (1019) |
| 3 | Không có token | 401 - Unauthorized |

---

## 10. FILE UPLOAD

### 10.1 Upload image 🔐

**Endpoint:** `POST /api/upload/image`

**Request (form-data):**
| Field | Type | Required |
|-------|------|----------|
| file | file | ✅ |

**Test Cases:**

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Upload thành công | 200 - { success: "true", imageUrl: "...", message: "Image uploaded successfully" } |
| 2 | File rỗng | 400 - { success: "false", error: "File is empty" } |
| 3 | Không phải image | 400 - { success: "false", error: "File must be an image" } |
| 4 | IOException (file bị lỗi) | 400 - { success: "false", error: "Failed to read image file: ..." } |
| 5 | Cloudinary error | 500 - { success: "false", error: "..." } |
| 6 | Không có token | 401 - Unauthorized |

---

## SAMPLE cURL COMMANDS

### Register
```bash
curl -X POST "http://localhost:8080/auth/register" \
  -F "email=test@example.com" \
  -F "password=Password123!" \
  -F "fullName=Nguyễn Văn Test" \
  -F "phoneNumber=0901234567" \
  -F "cccdFront=@/path/to/cccd_front.jpg" \
  -F "cccdBack=@/path/to/cccd_back.jpg"
```

### Login
```bash
curl -X POST "http://localhost:8080/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}'
```

### Get My Info
```bash
curl -X GET "http://localhost:8080/users/myinfo" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Update My Info
```bash
curl -X PUT "http://localhost:8080/users/myinfo" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"fullName":"Updated Name","phoneNumber":"0909876543","address":"New Address"}'
```

### Create Post
```bash
curl -X POST "http://localhost:8080/posts" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sellerId": 1,
    "brandId": 1,
    "categoryId": 1,
    "bicycleName": "Test Bike",
    "bicycleColor": "Red",
    "price": 10000000,
    "bicycleDescription": "Test description",
    "groupset": "Shimano 105",
    "frameMaterial": "Aluminum",
    "brakeType": "Disc",
    "size": "M (53 - 55) / 165 - 175 cm",
    "modelYear": 2024
  }'
```

### Create Draft Post
```bash
curl -X POST "http://localhost:8080/posts/draft" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "brandId": 1,
    "categoryId": 1,
    "bicycleName": "Draft Bike",
    "bicycleColor": "Blue",
    "price": 5000000,
    "bicycleDescription": "Draft description",
    "groupset": "Shimano Tiagra",
    "frameMaterial": "Steel",
    "brakeType": "Rim",
    "size": "S (49 - 52) / 155 - 165 cm",
    "modelYear": 2023
  }'
```

### Get My Posts
```bash
curl -X GET "http://localhost:8080/posts/my-posts" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Get My Drafts
```bash
curl -X GET "http://localhost:8080/posts/drafts" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Search by Price Range
```bash
curl -X GET "http://localhost:8080/posts/search?minPrice=5000000&maxPrice=20000000"
```

### Create Brand (Admin)
```bash
curl -X POST "http://localhost:8080/brands" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -F "brandName=Giant" \
  -F "brandLogo=@/path/to/logo.png"
```

### Create Category (Admin)
```bash
curl -X POST "http://localhost:8080/categories" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"categoryName":"Mountain Bike","categoryDescription":"Xe đạp leo núi"}'
```

### Admin Approve Post
```bash
curl -X PUT "http://localhost:8080/admin/posts/1/approve" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

### Admin Reject Post
```bash
curl -X PUT "http://localhost:8080/admin/posts/1/reject" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

### Admin Verify User
```bash
curl -X POST "http://localhost:8080/admin/users/verify" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"action":"APPROVE"}'
```

### Inspector Submit Inspection
```bash
curl -X POST "http://localhost:8080/inspection/1/submit" \
  -H "Authorization: Bearer INSPECTOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"result":"PASS","overallCondition":"GOOD","notes":"Xe OK"}'
```

### Upload Image
```bash
curl -X POST "http://localhost:8080/api/upload/image" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/image.jpg"
```

### Upload Bicycle Image
```bash
curl -X POST "http://localhost:8080/images" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "postId=1" \
  -F "image=@/path/to/bike.jpg" \
  -F "imageType=MAIN" \
  -F "isThumbnail=true"
```

---

## ERROR CODES REFERENCE

| Code | Name | Message | HTTP Status |
|------|------|---------|-------------|
| 1001 | INVALID_KEY | Uncategorized error | 400 |
| 1002 | USER_EXISTED | User existed | 400 |
| 1003 | USERNAME_INVALID | Username must be at least 3 characters | 400 |
| 1004 | INVALID_PASSWORD | Password must be at least 8 characters | 400 |
| 1005 | USER_NOT_EXISTED | User not existed | 404 |
| 1006 | UNAUTHENTICATED | Unauthenticated | 401 |
| 1007 | UNAUTHORIZED | You do not have permission | 403 |
| 1008 | INVALID_TOKEN | Token is invalid | 401 |
| 1009 | TOKEN_EXPIRED | Token has expired | 401 |
| 1011 | INVALID_EMAIL | Invalid email address | 400 |
| 1012 | IMAGE_UPLOAD_FAILED | Failed to upload image | 500 |
| 1013 | TOKEN_CREATION_FAILED | Failed to create authentication token | 500 |
| 1014 | BRAND_EXISTED | Brand already existed | 400 |
| 1015 | BRAND_NOT_EXISTED | Brand not existed | 404 |
| 1016 | CATEGORY_EXISTED | Category already existed | 400 |
| 1017 | CATEGORY_NOT_EXISTED | Category not existed | 404 |
| 1018 | POST_NOT_EXISTED | Bicycle post not existed | 404 |
| 1019 | IMAGE_NOT_EXISTED | Bicycle image not existed | 404 |
| 1020 | POST_UPDATE_NOT_ALLOWED | Cannot update post in current status | 400 |
| 1021 | INVALID_SIZE | Invalid bicycle size | 400 |
| 1022 | MISSING_REQUIRED_FIELD | Missing required field | 400 |
| 1023 | USER_HAS_NO_POSTS | User has no posts | 404 |
| 1024 | NO_POSTS_FOR_BRAND | No posts found for this brand | 404 |
| 1025 | NO_POSTS_FOR_CATEGORY | No posts found for this category | 404 |
| 1026 | NO_POSTS_FOR_SIZE | No posts found for this size | 404 |
| 1027 | NO_POSTS_FOR_STATUS | No posts found for this status | 404 |
| 1028 | NO_POSTS_FOR_PRICE_RANGE | No posts found in this price range | 404 |
| 1029 | EMAIL_SEND_FAILED | Failed to send email | 500 |
| 1030 | INVALID_VERIFY_ACTION | Invalid action. Use APPROVE or REJECT | 400 |
| 1031 | USER_ALREADY_VERIFIED | User is already verified | 400 |
| 1032 | USER_ALREADY_REJECTED | User is already rejected | 400 |
| 1033 | INVALID_POST_STATUS | Invalid post status for this action | 400 |
| 9999 | UNCATEGORIZED_EXCEPTION | Uncategorized error | 500 |

---

## POST STATUS FLOW

```
DRAFTED → PENDING → ADMIN_APPROVED → AVAILABLE → DEPOSITED → SOLD
                 ↘ REJECTED         ↘ REJECTED
                                              ↘ HIDDEN (Admin hide)
```

| Status | Mô tả |
|--------|-------|
| DRAFTED | Bản nháp (chưa submit) |
| PENDING | Chờ Admin duyệt |
| ADMIN_APPROVED | Admin đã duyệt, chờ Inspector |
| AVAILABLE | Đang bán |
| DEPOSITED | Đã đặt cọc |
| SOLD | Đã bán |
| REJECTED | Bị từ chối |
| HIDDEN | Đã ẩn (soft delete) |

---

## USER VERIFICATION FLOW

```
PENDING → APPROVED (verified)
        ↘ REJECTED
```

| Status | Mô tả |
|--------|-------|
| PENDING | Chờ Admin verify CCCD |
| APPROVED | Đã verified, có thể đăng nhập |
| REJECTED | CCCD bị từ chối |
