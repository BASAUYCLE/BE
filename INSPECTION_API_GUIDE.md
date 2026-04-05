# API Changes: Nâng cấp Inspection — Hệ thống chấm điểm 6 tiêu chí

> Tài liệu dành cho team FrontEnd để tích hợp tính năng kiểm định xe mới.

---

## 1. Tổng quan thay đổi

Hệ thống kiểm định **KHÔNG còn** yêu cầu Inspector chọn PASS/FAIL thủ công.  
Thay vào đó, Inspector chấm điểm **6 tiêu chí**, Backend tự động:

- Tính **conditionPercent** (% tình trạng xe)
- Gán nhãn **overallCondition** (EXCELLENT / GOOD / FAIR / POOR)
- Xác định **PASS / FAIL**
- Hoàn phí đăng bài cho seller (trong mọi trường hợp)

---

## 2. Thang điểm (Rubric — cho Inspector UI)

Mỗi tiêu chí chỉ được nhập 1 trong 4 giá trị sau:

| Điểm | Mức | Ý nghĩa |
|------|-----|---------|
| **10** | 🟢 Như mới | Không có dấu hiệu sử dụng nhiều |
| **7** | 🟡 Tốt | Nguyên bản, có dấu hiệu sử dụng nhẹ |
| **3** | 🟠 Tạm ổn | Có dấu hiệu thay thế hoặc chỉnh sửa |
| **0** | 🔴 Hỏng | Hư hỏng nặng, khả năng sử dụng thấp |

> ⚠️ **Chỉ cho phép 0, 3, 7, 10**. Nhập giá trị khác sẽ trả lỗi `1089`.

---

## 3. Trọng số 6 tiêu chí

| Field name | Trọng số | Mô tả | Ghi chú |
|------------|----------|-------|---------|
| `colorScore` | 10% | Sơn, thẩm mỹ tổng thể | |
| `frameScore` | 30% | Khung xe | ⚠️ Nếu = 0 → auto FAIL |
| `groupsetScore` | 25% | Bộ truyền động | |
| `brakeScore` | 15% | Phanh | ⚠️ Nếu = 0 → auto FAIL |
| `controlScore` | 10% | Ghi-đông, tay lái | |
| `wheelScore` | 10% | Bánh xe, lốp | |

---

## 4. Logic tính toán (FE có thể preview trước khi submit)

```
conditionPercent = (colorScore/10 × 10 + frameScore/10 × 30 + groupsetScore/10 × 25 
                  + brakeScore/10 × 15 + controlScore/10 × 10 + wheelScore/10 × 10) %

Nếu conditionPercent = 100% → tự động giảm xuống 99% (xe cũ không thể 100%)
```

### Quy tắc gán nhãn:

| conditionPercent | overallCondition |
|-----------------|------------------|
| ≥ 90% | EXCELLENT |
| 70% – 89% | GOOD |
| 50% – 69% | FAIR |
| < 50% | POOR |

### Quy tắc PASS/FAIL:

- **FAIL** nếu: `conditionPercent < 50` HOẶC `frameScore == 0` HOẶC `brakeScore == 0`
- **PASS** nếu ngược lại

---

## 5. API Endpoint

### `POST /inspection/{postId}/submit`

**Auth**: Bearer Token (Inspector role)

#### Request Body:

```json
{
  "colorScore": 7,
  "frameScore": 10,
  "groupsetScore": 7,
  "brakeScore": 10,
  "controlScore": 7,
  "wheelScore": 7,
  "notes": "Xe còn tốt, sơn có chút trầy xước nhẹ ở phần dưới ghi-đông"
}
```

| Field | Type | Bắt buộc | Giá trị hợp lệ |
|-------|------|----------|-----------------|
| `colorScore` | Integer | ✅ | 0, 3, 7, 10 |
| `frameScore` | Integer | ✅ | 0, 3, 7, 10 |
| `groupsetScore` | Integer | ✅ | 0, 3, 7, 10 |
| `brakeScore` | Integer | ✅ | 0, 3, 7, 10 |
| `controlScore` | Integer | ✅ | 0, 3, 7, 10 |
| `wheelScore` | Integer | ✅ | 0, 3, 7, 10 |
| `notes` | String | ❌ | Tùy chọn |

#### Response (thành công):

```json
{
  "code": 1000,
  "result": {
    "reportId": 1,
    "postId": 5,
    "postTitle": "Xe Đạp Địa Hình GIANT Talon 29 4",
    "inspectorId": 3,
    "inspectorName": "Nguyễn Văn A",
    "inspectorEmail": "inspector@gmail.com",
    "result": "PASS",
    "overallCondition": "GOOD",
    "colorScore": 7,
    "frameScore": 10,
    "groupsetScore": 7,
    "brakeScore": 10,
    "controlScore": 7,
    "wheelScore": 7,
    "conditionPercent": 79.0,
    "notes": "Xe còn tốt, sơn có chút trầy xước nhẹ ở phần dưới ghi-đông",
    "postStatus": "AVAILABLE",
    "createdAt": "2026-04-04T15:30:00"
  }
}
```

#### Response (lỗi validation — điểm không hợp lệ):

```json
{
  "code": 1089,
  "message": "Inspection score must be 0, 3, 7, or 10"
}
```

#### Response (lỗi — post không ở trạng thái ADMIN_APPROVED):

```json
{
  "code": 1033,
  "message": "Invalid post status for this action"
}
```

---

## 6. API lấy lịch sử kiểm định (không thay đổi endpoint, chỉ thêm field)

### `GET /admin/inspection/reports` (Admin)
### `GET /inspection/my-history` (Inspector)

Response giờ có thêm 7 field mới trong mỗi report:

```json
{
  "colorScore": 7,
  "frameScore": 10,
  "groupsetScore": 7,
  "brakeScore": 10,
  "controlScore": 7,
  "wheelScore": 7,
  "conditionPercent": 79.0
}
```

---

## 7. Ví dụ test case cho FE

| Kịch bản | colorScore | frameScore | groupsetScore | brakeScore | controlScore | wheelScore | Kết quả |
|----------|------------|------------|---------------|------------|--------------|------------|---------|
| PASS - EXCELLENT | 10 | 10 | 10 | 10 | 10 | 10 | PASS, 99%, EXCELLENT |
| PASS - GOOD | 7 | 10 | 7 | 10 | 7 | 7 | PASS, 79%, GOOD |
| PASS - FAIR | 3 | 7 | 7 | 7 | 3 | 3 | PASS, 55.5%, FAIR |
| FAIL - tổng thấp | 3 | 3 | 3 | 3 | 3 | 3 | FAIL, 30%, POOR |
| FAIL - khung hỏng | 10 | 0 | 10 | 10 | 10 | 10 | FAIL, 70%, GOOD |
| FAIL - phanh hỏng | 10 | 10 | 10 | 0 | 10 | 10 | FAIL, 85%, GOOD |
| Lỗi validation | 5 | 8 | 10 | 10 | 10 | 10 | 400 - Error 1089 |

---

## 8. Gợi ý UI cho FrontEnd

### Form kiểm định (Inspector):
- Mỗi tiêu chí hiển thị dạng **radio button** hoặc **button group** với 4 lựa chọn: 0 / 3 / 7 / 10
- Hiển thị tooltip/label giải thích ý nghĩa mỗi mức điểm
- Có thể tính preview `conditionPercent` realtime khi chọn điểm
- Hiển thị cảnh báo nếu `frameScore = 0` hoặc `brakeScore = 0` (sẽ auto FAIL)
- Textarea cho `notes`

### Hiển thị kết quả (Admin/Inspector history):
- Hiển thị bảng chi tiết 6 điểm
- Thanh progress bar cho `conditionPercent`
- Badge màu cho `overallCondition` (🟢 EXCELLENT, 🟡 GOOD, 🟠 FAIR, 🔴 POOR)
- Badge cho `result` (✅ PASS, ❌ FAIL)
