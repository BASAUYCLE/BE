# 📘 Hướng Dẫn Test API Cho Frontend Team

> **Base URL**: `http://localhost:8080`  
> **Swagger UI**: `http://localhost:8080/swagger-ui.html`  
> **OpenAPI Docs**: `http://localhost:8080/v3/api-docs`

---

## 🔐 Cách Sử Dụng Swagger với JWT Token

### Bước 1: Đăng nhập lấy Token

1. Mở Swagger UI: `http://localhost:8080/swagger-ui.html`
2. Tìm endpoint **POST /auth/login**
3. Click **Try it out**
4. Nhập body:
```json
{
  "email": "admin@example.com",
  "password": "password123"
}
```
5. Click **Execute**
6. Copy giá trị `token` trong response:
```json
{
  "code": 0,
  "result": {
    "token": "eyJhbGciOiJIUzUxMiJ9.xxxxxx...",
    "authenticated": true
  }
}
```

### Bước 2: Authorize Swagger

1. Click nút **🔓 Authorize** (góc phải trên)
2. Nhập: `Bearer <token_đã_copy>`
   - Ví dụ: `Bearer eyJhbGciOiJIUzUxMiJ9.xxxxxx...`
3. Click **Authorize** → **Close**

### Bước 3: Test các API cần token

Sau khi authorize, Swagger sẽ tự động gửi token trong header cho mọi request.

---

## 👥 Các Roles Trong Hệ Thống

| Role | Mô tả |
|------|-------|
| **MEMBER** | Người dùng thường, có thể đăng bài bán xe |
| **INSPECTOR** | Kiểm định viên, kiểm tra chất lượng xe |
| **ADMIN** | Quản trị viên, duyệt bài và quản lý hệ thống |

---

## 📋 Bảng API Chi Tiết

### 🔓 Legend (Chú thích)
- 🌍 **Public** = Không cần token
- 🔐 **Auth** = Cần token (bất kỳ role nào)
- 👤 **Member** = Chỉ role MEMBER
- 🔍 **Inspector** = Chỉ role INSPECTOR  
- 🛡️ **Admin** = Chỉ role ADMIN

---

## 1️⃣ Authentication APIs (`/auth`)

| Method | Endpoint | Auth | Mô tả | Request Body |
|--------|----------|------|-------|--------------|
| POST | `/auth/register` | 🌍 Public | Đăng ký tài khoản | `multipart/form-data` (email, password, fullName, phoneNumber, cccdFront, cccdBack) |
| POST | `/auth/login` | 🌍 Public | Đăng nhập | `{ "email": "", "password": "" }` |
| POST | `/auth/introspect` | 🌍 Public | Kiểm tra token hợp lệ | `{ "token": "" }` |

#### 📝 Lưu ý Register:
- Dùng **form-data** (không phải JSON) vì có upload ảnh CCCD
- `cccdFront`, `cccdBack` là file ảnh

---

## 2️⃣ User APIs (`/users`)

### 🔐 Endpoints cho Current User (Authenticated)

| Method | Endpoint | Auth | Mô tả | Request Body |
|--------|----------|------|-------|--------------|
| GET | `/users/myinfo` | 🔐 Auth | Lấy thông tin cá nhân | - |
| PUT | `/users/myinfo` | 🔐 Auth | Cập nhật thông tin cá nhân | `{ "fullName": "", "phoneNumber": "" }` |

### 🛡️ Admin Only

| Method | Endpoint | Auth | Mô tả | Request Body |
|--------|----------|------|-------|--------------|
| GET | `/users` | 🛡️ Admin | Lấy danh sách all users | - |
| GET | `/users/{userId}` | 🛡️ Admin | Lấy thông tin user theo ID | - |
| GET | `/users/email/{email}` | 🛡️ Admin | Lấy thông tin user theo email | - |
| PUT | `/users/{userId}` | 🛡️ Admin | Cập nhật user | `{ "fullName": "", "phoneNumber": "" }` |
| DELETE | `/users/{userId}` | 🛡️ Admin | Xóa user | - |

---

## 3️⃣ Bicycle Post APIs (`/posts`)

### 🌍 Public Endpoints

| Method | Endpoint | Auth | Mô tả | Response |
|--------|----------|------|-------|----------|
| GET | `/posts` | 🌍 Public | Lấy all posts (AVAILABLE, DEPOSITED, SOLD) | List |
| GET | `/posts/{postId}` | 🌍 Public | Lấy chi tiết bài đăng | Object |
| GET | `/posts/seller/{sellerId}` | 🌍 Public | Lấy bài đăng của seller (AVAILABLE, DEPOSITED, SOLD) | List |
| GET | `/posts/brand/{brandId}` | 🌍 Public | Lọc theo brand | List |
| GET | `/posts/category/{categoryId}` | 🌍 Public | Lọc theo category | List |
| GET | `/posts/size/{size}` | 🌍 Public | Lọc theo size | List |
| GET | `/posts/search?minPrice=&maxPrice=` | 🌍 Public | Tìm kiếm theo giá | List |

### 🔐 Authenticated Endpoints

| Method | Endpoint | Auth | Mô tả | Request Body |
|--------|----------|------|-------|--------------|
| POST | `/posts` | 🔐 Auth | Tạo bài đăng mới (status=PENDING) | Xem bên dưới |
| POST | `/posts/draft` | 🔐 Auth | Tạo bài nháp (status=DRAFTED) | Xem bên dưới |
| GET | `/posts/my-posts` | 🔐 Auth | Lấy tất cả bài của current user | - |
| GET | `/posts/drafts` | 🔐 Auth | Lấy bài nháp của current user | - |
| PUT | `/posts/{postId}` | 🔐 Auth | Sửa bài đăng (chỉ owner) | Xem bên dưới |
| DELETE | `/posts/{postId}` | 🔐 Auth | Xóa bài đăng (chỉ owner) | - |

#### 📝 Request Body cho Create/Update Post:
```json
{
  "sellerId": 1,
  "brandId": 1,
  "categoryId": 1,
  "bicycleName": "Giant TCR",
  "bicycleColor": "Red",
  "price": 25000000,
  "bicycleDescription": "Xe đạp road bike cao cấp",
  "groupset": "Shimano 105",
  "frameMaterial": "Carbon",
  "brakeType": "Disc Brake",
  "size": "M (53 - 55) / 165 - 175 cm",
  "modelYear": 2023
}
```

#### 📝 Lưu ý Size:
- `size` là field tự do, FE sử dụng dropdown nên BE không validate giá trị cụ thể.

## 4️⃣ Image APIs (`/images`)

| Method | Endpoint | Auth | Mô tả | Request |
|--------|----------|------|-------|---------|
| GET | `/images/{imageId}` | 🌍 Public | Lấy thông tin ảnh | - |
| GET | `/images/post/{postId}` | 🌍 Public | Lấy tất cả ảnh của bài đăng | - |
| POST | `/images` | 🔐 Auth | Upload ảnh mới | `multipart/form-data` |
| PUT | `/images/{imageId}` | 🔐 Auth | Cập nhật ảnh | `multipart/form-data` |
| DELETE | `/images/{imageId}` | 🔐 Auth | Xóa ảnh | - |

#### 📝 Form-data cho Upload Image:
- `postId`: Long
- `imageFile`: File
- `imageType`: String (`GENERAL`, `THUMBNAIL`)
- `isThumbnail`: Boolean

---

## 5️⃣ Brand APIs (`/brands`)

| Method | Endpoint | Auth | Mô tả | Request |
|--------|----------|------|-------|---------|
| GET | `/brands` | 🌍 Public | Lấy danh sách brands | - |
| GET | `/brands/{brandId}` | 🌍 Public | Lấy brand theo ID | - |
| POST | `/brands` | 🛡️ Admin | Tạo brand mới | `multipart/form-data` (brandName, brandLogo) |
| PUT | `/brands/{brandId}` | 🛡️ Admin | Cập nhật brand | `multipart/form-data` |
| DELETE | `/brands/{brandId}` | 🛡️ Admin | Xóa brand | - |

---

## 6️⃣ Category APIs (`/categories`)

| Method | Endpoint | Auth | Mô tả | Request Body |
|--------|----------|------|-------|--------------|
| GET | `/categories` | 🌍 Public | Lấy danh sách categories | - |
| GET | `/categories/{categoryId}` | 🌍 Public | Lấy category theo ID | - |
| POST | `/categories` | 🛡️ Admin | Tạo category | `{ "categoryName": "" }` |
| PUT | `/categories/{categoryId}` | 🛡️ Admin | Cập nhật category | `{ "categoryName": "" }` |
| DELETE | `/categories/{categoryId}` | 🛡️ Admin | Xóa category | - |

---

## 7️⃣ Admin Post Management APIs (`/admin/posts`)

> ⚠️ **Tất cả endpoints này đều yêu cầu role ADMIN**

| Method | Endpoint | Auth | Mô tả | Request Body |
|--------|----------|------|-------|--------------|
| GET | `/admin/posts` | 🛡️ Admin | Lấy TẤT CẢ bài đăng (mọi status) | - |
| GET | `/admin/posts/status/{status}` | 🛡️ Admin | Lọc theo status cụ thể | - |
| GET | `/admin/posts/pending` | 🛡️ Admin | Lấy bài chờ duyệt (PENDING) | - |
| PUT | `/admin/posts/{postId}/approve` | 🛡️ Admin | Duyệt bài (→ ADMIN_APPROVED) | - |
| PUT | `/admin/posts/{postId}/reject` | 🛡️ Admin | Từ chối bài (→ REJECTED) | - |
| PUT | `/admin/posts/{postId}/hide` | 🛡️ Admin | Ẩn bài - Soft delete (→ HIDDEN) | - |

#### 📝 Valid Status Values:
- `PENDING` - Chờ Admin duyệt
- `ADMIN_APPROVED` - Admin đã duyệt, chờ Inspector
- `AVAILABLE` - Đang bán
- `DEPOSITED` - Đã đặt cọc
- `SOLD` - Đã bán
- `REJECTED` - Bị từ chối
- `DRAFTED` - Bản nháp
- `HIDDEN` - Ẩn bài ( soft delete)
---

## 8️⃣ Admin User Management APIs (`/admin/users`)

> ⚠️ **Tất cả endpoints này đều yêu cầu role ADMIN**

| Method | Endpoint | Auth | Mô tả | Request Body |
|--------|----------|------|-------|--------------|
| GET | `/admin/users` | 🛡️ Admin | Lấy tất cả users | - |
| GET | `/admin/users/pending` | 🛡️ Admin | Lấy users chờ xác minh | - |
| GET | `/admin/users/{userId}` | 🛡️ Admin | Lấy user theo ID | - |
| POST | `/admin/users/verify` | 🛡️ Admin | Xác minh user (APPROVE/REJECT) | Xem bên dưới |

#### 📝 Request Body cho Verify User:
```json
{
  "userId": 1,
  "action": "APPROVE",    // hoặc "REJECT"
  "reason": "Lý do (bắt buộc nếu REJECT)"
}
```

---

## 9️⃣ Inspector APIs (`/inspection`)

> ⚠️ **Tất cả endpoints này đều yêu cầu role INSPECTOR**

| Method | Endpoint | Auth | Mô tả | Request Body |
|--------|----------|------|-------|--------------|
| GET | `/inspection/pending` | 🔍 Inspector | Lấy bài chờ kiểm định (ADMIN_APPROVED) | - |
| POST | `/inspection/{postId}/submit` | 🔍 Inspector | Nộp kết quả kiểm định | Xem bên dưới |

#### 📝 Request Body cho Submit Inspection:
```json
{
  "result": "PASS",           // hoặc "FAIL"
  "overallCondition": "EXCELLENT",  // EXCELLENT, GOOD, FAIR, POOR
  "notes": "Ghi chú của inspector"
}
```

---

## 🧪 Test Accounts (Nếu có seed data)

| Email | Password | Role |
|-------|----------|------|
| `admin@example.com` | `password123` | ADMIN |
| `inspector@example.com` | `password123` | INSPECTOR |
| `member@example.com` | `password123` | MEMBER |

---

## ⚠️ Error Codes

| Code | Message | HTTP Status |
|------|---------|-------------|
| 0 | Success | 200 |
| 1005 | User not existed | 404 |
| 1006 | Unauthenticated | 401 |
| 1007 | You do not have permission | 403 |
| 1008 | Token is invalid | 401 |
| 1009 | Token has expired | 401 |
| 1018 | Bicycle post not existed | 404 |
| 1020 | Cannot update post in current status | 400 |
| 1021 | Invalid bicycle size | 400 |

---

## 📊 Post Status Flow

```
      ┌─────────┐
      │ DRAFTED │ (Bản nháp)
      └────┬────┘
           │ Submit
           ▼
      ┌─────────┐
      │ PENDING │ (Chờ Admin duyệt)
      └────┬────┘
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
┌─────────┐  ┌──────────────┐
│REJECTED │  │ADMIN_APPROVED│ (Chờ Inspector)
└─────────┘  └──────┬───────┘
                    │
              ┌─────┴─────┐
              │           │
              ▼           ▼
         ┌─────────┐  ┌─────────┐
         │AVAILABLE│  │REJECTED │
         └────┬────┘  └─────────┘
              │
              ▼
         ┌─────────┐
         │DEPOSITED│ (Đã đặt cọc)
         └────┬────┘
              │
              ▼
         ┌─────────┐
         │  SOLD   │ (Đã bán)
         └─────────┘
```

---

## 💡 Tips Test

1. **Test flow hoàn chỉnh:**
   - Register → Login → Create Post → Admin Approve → Inspector Pass → Available

2. **Test permission:**
   - Dùng token MEMBER để gọi `/admin/**` → Phải trả về 403

3. **Test ownership:**
   - Dùng token User A để update/delete post của User B → Phải trả về 403

4. **Test public endpoints:**
   - Không gửi token khi gọi `GET /posts` → Phải hoạt động bình thường
