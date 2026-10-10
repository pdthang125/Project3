# Báo cáo dự án: OCR Expense Tracker & Receipt Parser

**Mini-Project 3 · Flutter và Dart**  
**Sinh viên:** Phan Đình Thắng · **Mã sinh viên:** 23IT.B207  
**Ngày cập nhật:** 11/10/2026  
**GitHub:** https://github.com/pdthang125/ocr-expense-tracker

---

## 1. Tóm tắt dự án

OCR Expense Tracker là ứng dụng quản lý chi tiêu từ hóa đơn. Người dùng chụp ảnh hoặc chọn ảnh hóa đơn, ứng dụng nhận dạng văn bản trực tiếp trên thiết bị, trích xuất số tiền, ngày giao dịch và tên cửa hàng, sau đó cho phép kiểm tra và chỉnh sửa trước khi lưu.

Ứng dụng lưu giao dịch và ảnh thu nhỏ trong cơ sở dữ liệu cục bộ. Màn hình tổng quan hiển thị chi tiêu theo danh mục và xu hướng theo tuần bằng các biểu đồ tự vẽ với `CustomPainter`.

### Công nghệ chính

| Thành phần | Công nghệ |
|---|---|
| Nền tảng | Flutter 3.x, Dart 3 |
| Quản lý trạng thái | Riverpod 2.x |
| Nhận dạng văn bản | Google ML Kit Text Recognition trên thiết bị |
| Cơ sở dữ liệu | SQLite qua `sqflite` |
| Biểu đồ | Flutter `CustomPainter` |
| Android tối thiểu | API 21 trở lên |

## 2. Kiến trúc

Mã nguồn được chia theo trách nhiệm để giao diện, xử lý nghiệp vụ và truy cập dữ liệu dễ bảo trì:

```text
Presentation
  Screens, widgets, Riverpod providers
       │
       ├── Camera/OCR ── ReceiptParser
       │
       ▼
TransactionRepository
       │
       ▼
TransactionDatasource ── SQLite
       │
       └── Thumbnail storage

Core
  Constants, theme, formatters, receipt parsing utilities
```

Các màn hình chính gồm Dashboard, Camera, Review và History. Riverpod cung cấp dữ liệu cho giao diện; repository phối hợp giữa datasource, cơ sở dữ liệu và dịch vụ xử lý ảnh/OCR.

### Cấu trúc thư mục chính

```text
lib/
├── core/           # Hằng số, giao diện chủ đề và tiện ích
├── data/           # Model, repository và datasource
├── services/       # OCR, cơ sở dữ liệu và xử lý ảnh
└── presentation/   # Providers, màn hình và widget
```

## 3. Chức năng

### 3.1 Chụp và xử lý ảnh hóa đơn

- Xem trước camera, bật/tắt đèn flash và chạm để lấy nét/phơi sáng.
- Chọn ảnh từ thư viện hoặc chụp ảnh trực tiếp.
- Hiển thị khung căn chỉnh khi chụp.
- Nén ảnh và lưu thumbnail trong thư mục dữ liệu của ứng dụng.

### 3.2 OCR và trích xuất dữ liệu

Ứng dụng dùng `google_mlkit_text_recognition` để nhận dạng văn bản ngay trên thiết bị. `ReceiptParser` kết hợp từ khóa và biểu thức chính quy để tìm:

- **Tổng tiền:** ưu tiên các dòng có từ khóa như “tổng cộng”, “thành tiền”, “phải trả” hoặc “total”; nếu không tìm thấy, xét các dòng số tiền hợp lệ.
- **Ngày giao dịch:** hỗ trợ các dạng ngày phổ biến như `DD/MM/YYYY`, `DD-MM-YYYY` và `DD.MM.YYYY`.
- **Tên cửa hàng:** lấy từ dòng đầu tiên phù hợp trong nội dung OCR.

Màn hình Review cho phép người dùng sửa dữ liệu nhận dạng trước khi lưu. Chỉ báo OCR thể hiện số trường được trích xuất; đây không phải điểm tin cậy do mô hình cung cấp.

### 3.3 Lưu trữ và quản lý giao dịch

SQLite lưu thông tin giao dịch gồm mã, số tiền, ngày, cửa hàng, danh mục, đường dẫn thumbnail và văn bản OCR gốc. Ứng dụng hỗ trợ thêm, xem, sửa và xóa giao dịch; lọc theo khoảng ngày; tổng hợp chi tiêu theo danh mục và theo tuần. Cơ sở dữ liệu có sáu danh mục mặc định.

Khi xóa giao dịch, thumbnail tương ứng cũng được dọn khỏi bộ nhớ ứng dụng.

### 3.4 Tổng quan và biểu đồ

- **Donut chart:** phân bổ chi tiêu theo danh mục, có chuyển động, màu chuyển sắc, chú giải và giá trị ở tâm biểu đồ.
- **Bar chart:** xu hướng chi tiêu theo tuần, có nhãn giá trị và hiệu ứng làm nổi bật cột cao nhất.
- Cả hai biểu đồ được vẽ bằng `CustomPainter`, không dùng thư viện biểu đồ bên ngoài.

### 3.5 Trải nghiệm người dùng

Ứng dụng sử dụng giao diện tối theo Material 3, kiểu chữ Outfit, bộ lọc danh mục và thao tác vuốt để xóa giao dịch. Phản hồi rung được dùng khi chụp ảnh trên thiết bị hỗ trợ.

## 4. Quy trình xử lý hóa đơn

```text
Chụp ảnh hoặc chọn ảnh
        ↓
Google ML Kit nhận dạng văn bản
        ↓
ReceiptParser phân tích số tiền, ngày và cửa hàng
        ↓
Người dùng kiểm tra, chỉnh sửa trên Review
        ↓
TransactionRepository lưu giao dịch và thumbnail
        ↓
SQLite cập nhật dữ liệu; Riverpod làm mới giao diện
```

### Quy tắc chuẩn hóa số tiền

Parser tìm các cụm số có dấu phân tách hàng nghìn như `150.000` hoặc `150,000`, sau đó loại bỏ dấu phân cách để lưu số tiền. Các dòng chứa thông tin dễ gây nhầm lẫn như VAT, giảm giá, tiền khách đưa, tiền thừa, số điện thoại hoặc mã hóa đơn được loại khỏi quá trình chọn tổng tiền.

OCR có thể đọc sai khi ảnh mờ, hóa đơn cong hoặc cách in không phổ biến. Vì vậy, người dùng cần kiểm tra kết quả trước khi lưu.

## 5. Cài đặt và chạy ứng dụng

Yêu cầu Flutter SDK và Dart SDK phiên bản 3 trở lên, cùng thiết bị hoặc trình giả lập phù hợp.

```bash
flutter pub get
flutter run
```

### Tạo APK phát hành

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=./debug-info
```

APK được tạo tại:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Có thể tạo APK riêng cho từng kiến trúc CPU bằng:

```bash
flutter build apk --split-per-abi --release
```

Nếu ký APK bằng keystore, không đưa keystore, mật khẩu hoặc thông tin ký phát hành vào kho mã nguồn công khai.

## 6. Thách thức và giải pháp

| Thách thức | Cách xử lý |
|---|---|
| Định dạng số tiền Việt Nam có thể dùng dấu chấm hoặc dấu phẩy | Kết hợp từ khóa, hậu tố tiền tệ và quy tắc chuẩn hóa số |
| OCR có thể nhận nhầm nội dung hóa đơn | Cho phép kiểm tra và chỉnh sửa dữ liệu trước khi lưu |
| Camera khởi tạo khác nhau giữa các thiết bị | Theo dõi vòng đời ứng dụng và thử khởi tạo lại khi cần |
| Biểu đồ cần chuyển động tùy biến | Tự vẽ bằng `CustomPainter` và bộ điều khiển animation |
| Thumbnail không nên tồn tại sau khi giao dịch bị xóa | Xóa ảnh liên quan cùng thao tác xóa giao dịch |

## 7. Thông số tham khảo

Các số liệu dưới đây là ước tính được ghi nhận trong tài liệu dự án; kết quả thực tế phụ thuộc thiết bị, ảnh đầu vào và cấu hình build.

| Hạng mục | Giá trị tham khảo |
|---|---:|
| Thời gian OCR trên thiết bị | khoảng 0,8–1,5 giây |
| Kích thước thumbnail | khoảng 30–80 KB ở chất lượng nén 60% |
| Truy vấn toàn bộ giao dịch | dưới 10 ms với bộ dữ liệu nhỏ |
| Kích thước APK release | khoảng 18–25 MB |

## 8. Kết luận

OCR Expense Tracker kết hợp camera, OCR chạy trên thiết bị, parser dành cho hóa đơn Việt Nam và SQLite để hỗ trợ ghi nhận chi tiêu từ hóa đơn. Người dùng có thể xem lại dữ liệu trước khi lưu, quản lý lịch sử giao dịch và theo dõi tổng quan chi tiêu bằng biểu đồ.

Báo cáo này mô tả các chức năng và cấu trúc hiện có trong dự án. Thư mục dự án hiện chưa có ảnh chụp màn hình giao diện; nên bổ sung ảnh thật từ ứng dụng trước khi nộp nếu yêu cầu bài tập cần minh họa.