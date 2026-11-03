# 🎬 KỊCH BẢN QUAY VIDEO DEMO — PhimHay24h Mobile

> **Tổng thời lượng ước tính:** 12–15 phút
> **Cách dùng:** mở file này cạnh VS Code, quay từng phần theo số thứ tự. Cột **"CỬA SỔ CẦN MỞ"** là thứ bạn chỉ vào khi nói.
> **Nguyên tắc:** luôn nói *tại sao* chứ không chỉ *nó làm gì*. Giáo viên chấm điểm ở phần **lý do thiết kế** và **code đặc biệt đã học** (Generics) — đừng bỏ qua.

---

## PHẦN 0 — MỞ ĐẦU (30 giây)

**CỬA SỔ:** terminal mở repo `D:\dowload\mobile-main\mobile-main`, chạy `git log --oneline -5`

**NÓI:**

> "Xin chào, em là nhóm 4 — PhimHay24h Mobile. Đây là bản ứng dụng xem phim trực tuyến viết bằng Flutter, chạy được trên cả ba nền tảng: Android, Web PWA và iOS.
>
> Trong video này em sẽ trình bày theo 4 phần: **kiến trúc tổng thể**, **đi sâu vào từng file và một luồng hoàn chỉnh**, **bảo mật**, rồi **bộ kiểm thử** và **chạy thử trên giao diện**.
>
> Trước hết, đây là lịch sử commit của nhóm — app được build từ một codebase duy nhất, xuất ra cả APK lẫn Web."

**LƯU Ý:** không đọc thuộc lòng — nhìn camera, tự nhiên.

---

## PHẦN 1 — KIẾN TRÚC & LUỒNG HỆ THỐNG (3–4 phút)

### 1.1. Bức tranh tổng thể

**CỬA SỔ:** mở `docs/images/KTTongThe.drawio.png`

**NÓI:**

> "Đây là kiến trúc tổng thể của hệ thống. Nhóm em cố tình đặt 3 tầng tách biệt:
>
> **Tầng trên cùng — ứng dụng Flutter.** Chính là thư mục `cinema_app/` mà em sẽ mở sau. Nó chạy được trên Android, Web và iOS từ **một codebase duy nhất**.
>
> **Tầng giữa — Firebase.** Đây là điểm khác biệt lớn nhất so với bản web của nhóm. Bản web dùng NestJS + JWT + MySQL; bản mobile em **chuyển sang Firebase-native**: `firebase_auth` thay cho cơ chế JWT, `cloud_firestore` thay cho MySQL. Lý do em chọn hướng này là vì Firebase xử lý sẵn phần hạ tầng — không cần thuê server, không cần quản lý kết nối, và quan trọng nhất là **đẩy hết phân quyền xuống tầng server** bằng Firestore Rules.
>
> **Tầng ngoài cùng — các dịch vụ bên thứ ba:** Google Gemini cho trợ lý giọng nói, và **Render** để deploy bản Web."

### 1.2. Ba luồng nghiệp vụ chính

**CỬA SỔ:** mở `docs/images/ACLogin.png`, rồi `AC_ChonTapVaPhatVideo.png`

**NÓI:**

> "Về mặt nghiệp vụ, app có ba luồng chính. Đầu tiên là **đăng nhập** — người dùng nhập email hoặc username, hệ thống xác thực qua Firebase Auth, đồng thời kiểm tra tài khoản có bị khoá hay không.
>
> Luồng thứ hai là **xem phim** — chọn phim, chọn tập, phát video. Điểm em muốn nhấn mạnh ở đây là: trang chi tiết phim phải **phân biệt được ba trạng thái** — đang tải, lỗi mạng, và không tìm thấy phim. Không được gộp tất cả thành một màn hình trắng. Em sẽ giải thích cơ chế này ở Phần 2.
>
> Luồng thứ ba là luồng quản trị — Admin thêm phim, gắn tập, duyệt bình luận, khoá tài khoản."

### 1.3. Class Diagram — mô hình dữ liệu

**CỬA SỔ:** mở `docs/images/ClassDiagrams.drawio.png`

**NÓI:**

> "Về mô hình dữ liệu, đây là class diagram. Ở đây em đã học được một bài học rất rõ ràng khi làm **parse dữ liệu mềm** — em sẽ mở file model để giải thích chi tiết ở phần sau, vì đây là một trong những chỗ em tự hào nhất về kỹ thuật."

### 1.4. Sơ đồ Sequence — quy trình xem phim

**CỬA SỔ:** mở `docs/images/Se_XemChiTietPhim.png`

**NÓI:**

> "Đây là sequence diagram của luồng xem chi tiết phim. Nó đi qua 5 lớp: **Page** gọi **Provider**, Provider gọi **Repository**, Repository gọi **Service**, Service gọi Firestore, và dữ liệu quay ngược lại để dựng UI. Mỗi lớp một nhiệm vụ — đó là lý do em chọn mô hình **Repository Pattern** thay vì để Page gọi thẳng Firebase."

> 💡 **Mẹo dẫn:** nếu thấy mình nói dài, cắt ngay. "Như em đã nói ở trên, mô hình này chia 5 lớp, mỗi lớp một nhiệm vụ."

---

## PHẦN 2 — ĐI SÂU VÀO CODE (4–5 phút) ⭐ PHẦN QUAN TRỌNG NHẤT

### 2.1. Bản đồ thư mục

**CỬA SỔ:** VS Code mở `cinema_app/lib/` (sidebar), hoặc mở file `README.md` mục "📁 Cấu trúc dự án" đã có cây thư mục chi tiết từng file

**NÓI:**

> "Trước khi vào code, em xin tóm tắt bản đồ. Trong `lib/` có 9 nhóm, mỗi nhóm một tầng kiến trúc:
>
> - `models/` — cấu trúc dữ liệu
> - `services/` — gọi API / Firestore
> - `repositories/` — bắt lỗi, trả về giá trị an toàn
> - `providers/` — quản lý trạng thái
> - `pages/` — 18 màn hình
> - `widgets/` — 30 component dùng chung
> - `core/` — hạ tầng: bảo mật, tiện ích, Firebase, theme
> - `assistant/` — trợ lý giọng nói
> - `routes/` — định tuyến"

### 2.2. Các file chính và chức năng từng file

**CỬA SỔ:** lần lượt mở các file, giới thiệu ngắn gọn

| File | Nói gì |
|---|---|
| `lib/main.dart` | "Entry point: khởi tạo Firebase → đọc theme đã lưu → kiểm tra phiên đăng nhập → bắt deep link → `runApp`. Thứ tự này quan trọng vì nếu check auth sau `runApp` thì app sẽ nháy màn hình login rồi mới nhảy vào home." |
| `lib/models/movie_model.dart` | "Model phim. Điểm đặc biệt là `fromJson` — em giải thích ngay sau." |
| `lib/services/movie_service.dart` | "Lớp gọi dữ liệu thật: Firestore hoặc REST API. Nó **không** bắt lỗi — để lỗi bay lên." |
| `lib/repositories/movie_repository.dart` | "Lớp bắt lỗi. Đây là ranh giới quan trọng nhất." |
| `lib/providers/auth_provider.dart` | "Quản lý phiên đăng nhập, dùng `ChangeNotifier` + `ListenableBuilder`." |
| `lib/pages/home_page.dart` | "Trang chủ: banner xoay + trending + các hàng phim theo thể loại." |
| `lib/core/utils/` | "Bộ tiện ích dùng chung — em sẽ mở sâu phần này vì đây là phần code đặc biệt." |
| `lib/core/security/` | "3 lớp bảo mật client — sẽ nói ở Phần 3." |
| `lib/assistant/` | "Trợ lý giọng nói Lina/Seven: `speech_to_text` nghe → `gemini_client` hiểu → `flutter_tts` đọc lại → `assistant_tools` điều hướng mở màn hình." |

### 2.3. Ví dụ một luồng hoàn chỉnh: Đăng nhập → Trang chủ

**CỬA SỔ:** mở `lib/providers/auth_provider.dart`, tìm hàm `login()` (Ctrl+F "Future<bool> login")

**NÓI — đi từng bước:**

> "Em sẽ đi một luồng thật từ lúc user bấm Đăng nhập, để thấy 5 lớp hoạt động như thế nào.
>
> **Bước 1 — Provider chuẩn bị trạng thái.** Đầu hàm `login()`, em bật `_isLoading = true` và gọi `notifyListeners()`. `notifyListeners` chính là chỗ đẩy trạng thái xuống UI: mọi widget đang `ListenableBuilder` sẽ dựng lại, nên nút Đăng nhập quay spinner ngay.
>
> **Bước 2 — Tìm user trong Firestore.** Em query collection `users` theo email; nếu không có thì query theo username. Vì sao cần cả hai? Vì bản web cũ cho phép đăng nhập bằng username, và nhóm muốn giữ nguyên trải nghiệm đó.
>
> **Bước 3 — Kiểm tra tài khoản bị khoá.** Field `isBanned`. Nếu bị khoá thì dừng ngay, trả về thông báo cho admin.
>
> **Bước 4 — Xác thực.** Đây là điểm bảo mật quan trọng: em gọi `signInWithEmailAndPassword` của Firebase Auth. **Em không bao giờ so sánh mật khẩu plaintext trong Firestore** — mật khẩu chỉ nằm trong Firebase Auth dưới dạng hash + salt.
>
> Có một chi tiết hay: user cũ migrate từ MySQL sang chưa có trong Auth, Firebase trả lỗi `invalid-credential`. Khi đó em **tạo account Auth bằng đúng mật khẩu user vừa nhập** — không đọc mật khẩu cũ — để từ giờ user đi qua luồng Auth chuẩn.
>
> **Bước 5 — Đồng bộ `user_auth_map`.** Em ghi 1 document nối Firebase UID với `profileId` trong hồ sơ. Cần cái này vì Firestore Rules **không query được theo field** — Rules cần một document tra cứu để biết user đang đăng nhập sở hữu hồ sơ nào. Đây là điểm em học được rất rõ: *phân quyền phải được đẩy xuống server, không thể tin client*.
>
> **Bước 6 — Lưu token an toàn.** `SecureTokenStorage.saveTokens()` đưa ID token vào Keychain / EncryptedSharedPreferences.
>
> **Bước 7 — Cập nhật UI.** `_currentUser = ...`, tắt loading, `notifyListeners()` — UI tự vẽ lại."

**CỬA SỔ:** chuyển sang `lib/repositories/movie_repository.dart`

**NÓI:**

> "Bây giờ em muốn chỉ ra điểm khác biệt về **xử lý lỗi** giữa các lớp — đây là yêu cầu 8a.
>
> Ở `MovieRepository`, mỗi hàm có `try/catch ApiException`. Khi lỗi xảy ra, nó **không ném lỗi lên**, mà trả về giá trị an toàn: list rỗng, `null`, hay `PageResult.empty()`.
>
> Lý do: nếu lỗi bay thẳng lên Page, cả trang chủ sẽ crash hoặc hiện màn hình đỏ — người dùng mất toàn bộ danh sách chỉ vì một request lỗi. Với cách này, trang chủ vẫn hiện danh sách rỗng kèm thông báo 'chưa có phim'.
>
> **Nhưng em cố ý để một hàm không nuốt lỗi** — đây là `getMovieDetail`. Cái này em muốn nhấn mạnh vì đây là sự cân bằng, không phải sự lười. Trang xem phim cần **phân biệt ba trạng thái**: đang tải, lỗi mạng, và không tìm thấy phim. Nếu repository trả về `null` cho tất cả, UI không thể biết nên hiện thông báo nào. Vì vậy hàm này để lỗi bay lên để Page tự quyết định."

> 💡 **Mẹo dẫn:** đây là câu hỏi hay của giáo viên. Nếu bị hỏi "sao không bắt lỗi hết cho an toàn?" — trả lời đúng ý trên: *nuốt lỗi là đánh đổi giữa 'app không crash' và 'app vẫn hữu ích'. Với những nơi UI cần phân biệt trạng thái thì phải để lỗi lộ ra.*

### 2.4. ⭐ CODE ĐẶC BIỆT ĐÃ HỌC — GENERICS

**CỬA SỔ:** mở `lib/core/utils/generic_utils.dart`

**NÓI:**

> "Giờ em muốn nói đến phần code em **đặc biệt tự hào**, và là kiến thức em học được từ slide Generics của tuần 3.
>
> File này là bộ tiện ích generic dùng chung cho toàn app. Em chọn cách viết này thay vì viết riêng một hàm cho từng loại dữ liệu.
>
> **Hàm `firstWhereOrNull<T>`** — tìm phần tử đầu tiên thỏa điều kiện. Ở đây `<T>` là *type parameter*: hàm này viết một lần, dùng được cho **bất kỳ** kiểu dữ liệu nào. Nếu em viết không có generic, em sẽ phải viết `firstMovieWhereOrNull`, `firstEpisodeWhereOrNull`, `firstCommentWhereOrNull`... mỗi cái một hàm.
>
> **Hàm `searchBy<T>`** — tìm kiếm theo chuỗi. Tham số thứ ba là `String Function(T item) textOf` — đây là **callback**, tức là em đưa cho hàm một "cách lấy text" từ phần tử. Muốn tìm theo tên phim thì truyền `(m) => m.getName()`; muốn tìm theo tên tập thì truyền hàm khác. Hàm không cần biết phần tử là gì.
>
> **Hàm `sortedBy<T, K extends Comparable<K>>`** — đây là ví dụ **2 tham số generic**. `T` là kiểu phần tử, `K` là kiểu khóa sắp xếp, và ràng buộc `K extends Comparable<K>` nghĩa là khóa phải implement `Comparable` để có phép so sánh `<` và `>`. Nhờ vậy em dùng được cho cả `double` (sắp xếp theo điểm), `int` (theo năm), `String` (theo tên), chỉ với một hàm.
>
> **Điểm em muốn nhấn mạnh:** hàm `sortedBy` sắp xếp trên **bản copy** — `final copy = List<T>.from(items)`. Em cố tình không sắp xếp trực tiếp trên list gốc, vì nếu sắp xếp tại chỗ thì danh sách gốc trong bộ nhớ cũng bị đổi thứ tự — rất dễ gây bug khó tìm khi UI đang hiển thị.
>
> Ngoài ra còn `groupBy<T, K>` gom theo khóa, `chunk<T>` chia list thành nhóm nhỏ dùng cho phân trang, và `countWhere<T>`."

**NÓI thêm về model (nếu còn thời gian):**

**CỬA SỔ:** mở `lib/models/movie_model.dart`, tìm `fromJson`

> "Cùng tinh thần đó, ở Model em xử lý **parse mềm**. Dữ liệu migrate từ MySQL cũ sang Firestore không đồng nhất kiểu: `id` có thể là `int` hoặc `String`, `is_visible` có thể là `bool`, `int` hoặc `String`.
>
> Nếu em viết `json['id'] as int?` thì khi gặp String nó **throw TypeError**, và vì try/catch ở repository sẽ bỏ qua cả document đó — kết quả là admin đếm 71 phim trong Firestore nhưng app chỉ hiện một phần. Em đã gặp đúng lỗi này.
>
> Nên em viết 3 helper: `_parseIntField`, `_parseBoolField`, `_parseDoubleField` — nhận int, num, String số, bool, và trả về giá trị mặc định nếu không parse được. Nhờ vậy một document lỗi kiểu dữ liệu chỉ bị mất **một vài field**, thay vì mất **cả phim**."

> 💡 **Mẹo dẫn:** đây là câu chuyện "sửa bug thật" — thầy giáo rất thích nghe. Cứ kể chậm, có thêm: *"Đó là lúc em hiểu vì sao mấy anh chị ở nhóm bảo phải chạy app thật chứ không chỉ nhìn code."*

### 2.5. Trợ lý giọng nói (nếu còn thời gian)

**CỬA SỔ:** mở `lib/assistant/assistant_brain.dart` và `assistant_tools.dart`

**NÓI:**

> "Một tính năng em nghĩ là đáng chú ý nhất của bản mobile là trợ lý giọng nói Lina/Seven.
>
> Luồng hoạt động: `voice_assistant_service` nghe giọng nói qua `speech_to_text` → `text_normalizer` chuẩn hóa tiếng Việt cho STT → `gemini_client` gửi lên Gemini để hiểu ý → `assistant_brain` quyết định dùng tool nào → `assistant_tools` thực thi, ví dụ mở trang tìm kiếm với từ khoá → `flutter_tts` đọc kết quả lại cho user nghe.
>
> Điểm em thiết kế là `assistant_tools` tách riêng khỏi `assistant_brain`, để sau này thêm tool mới (ví dụ 'phim nào mới nhất') chỉ cần viết thêm hàm, không phải sửa lại logic hiểu lệnh."

---

## PHẦN 3 — BẢO MẬT (2–3 phút) ⭐

### 3.1. Bức tranh tổng thể

**CỬA SỔ:** mở `docs/images/` — dùng sơ đồ Mermaid trong README (mục "🛡️ Kiến trúc bảo mật"), hoặc mở tab README trên GitHub

**NÓI:**

> "Bảo mật là phần em đầu tư nhiều nhất. Nhóm em xây dựng **8 lớp bảo vệ**, trải từ client tới server."

### 3.2. Từng lớp — mở file thật

**CỬA SỔ:** mở `lib/core/security/input_sanitizer.dart`

> "**Lớp 2 — chống XSS.** `InputSanitizer.cleanText()` bỏ hết thẻ HTML bằng regex, gọn khoảng trắng, cắt còn tối đa 2000 ký tự.
>
> Nhóm em chọn cách này thay vì dùng thư viện `flutter_html`. Lý do: nếu app render HTML từ server, thì chỉ cần server trả về một chuỗi `<script>` là app tự chạy code của attacker. Giải pháp an toàn hơn là **UI chỉ dùng widget `Text`** — không bao giờ render HTML. `<script>` khi đó chỉ là chữ, vô hại.
>
> Ngoài ra `isSafeImageUrl` chỉ chấp nhận `https` hoặc đường dẫn asset nội bộ, chặn `file://`, `javascript:`, `data:`."

**CỬA SỔ:** mở `lib/core/security/secure_token_storage.dart`

> "**Lớp 3 — lưu token an toàn.** Đây là điểm em muốn giải thích kỹ vì nó là khác biệt cơ bản giữa web và mobile.
>
> Web có cookie `HttpOnly` — JavaScript không đọc được. Mobile thì không có, token buộc nằm trên máy. Nếu em lưu token trong `SharedPreferences` (file XML plaintext), thì bất kỳ app nào chạy được quyền root, hay chỉ cần backup máy, đều đọc được token.
>
> Nên em tách làm **hai kho**:
> - `flutter_secure_storage` → Keychain trên iOS, EncryptedSharedPreferences trên Android: chỉ dành cho **token** — thứ là bí mật.
> - `shared_preferences` → chỉ dành cho **theme_mode** và cache UI — thứ không nhạy cảm.
>
> Và em tuân thủ thêm một quy tắc: **không lưu token vào biến static toàn cục**, vì tiến trình bị dump bộ nhớ là lộ. Mọi lần đọc/ghi đều qua class này bằng `async`, và lỗi I/O được bắt ở ranh giới."

**CỬA SỔ:** mở `lib/core/security/rate_limiter.dart`

> "**Lớp 4 — chống spam.** `RateLimiter` giới hạn 1 hành động mỗi 1200ms cho cùng một key — chặn việc user bấm liên tục.
>
> Bên cạnh đó có `SearchDebouncer` với cơ chế **ticket counter** rất hay: mỗi lần gõ là tăng một ticket, đợi 400ms rồi mới chạy, nhưng chỉ ticket **mới nhất** mới được chạy. Các ticket cũ bị bỏ. Nhờ vậy gõ nhanh 10 chữ chỉ tốn 1 request thay vì 10 request."

**CỬA SỔ:** mở `lib/core/utils/video_source.dart`

> "**Lớp 5 — an toàn URL video.** Admin dán link phim vào. Em chuẩn hoá mọi dạng: YouTube `watch?v=`, `youtu.be/`, `shorts/`, `live/` đều ra cùng một dạng `/embed/ID`, và giữ lại tham số `?t=90` để nhảy đúng giây.
>
> Rồi `classify()` phân loại ra YouTube / HLS / direct video / iframe — để admin biết link đã nhận diện đúng chưa, và app chọn đúng player.
>
> Quan trọng: `isSupported()` **chặn các scheme nguy hiểm** `javascript:`, `data:`, `file:`, `blob:`. Vì sao lại cần chặn `javascript:`? Vì link này nằm trong WebView — nếu không chặn, attacker có thể thực thi JS trong ngữ cảnh app.
>
> Link `http` chỉ được phép với host local (`localhost`, `10.0.2.2` — emulator Android) để dev không bị vướng."

**CỬA SỔ:** mở `cinema_app/firestore.rules`

> "**Lớp 7 — phân quyền ở server, đây là lớp quan trọng nhất.**
>
> Firestore Rules có 4 hàm trợ giúp:
> - `isSignedIn()` — có đang đăng nhập không
> - `isAdmin()` — kiểm tra UID có nằm trong collection `admins` không
> - `ownsProfile(id)` — đọc `user_auth_map` để biết user này sở hữu hồ sơ nào
> - `hasNoPlaintextPassword()` — chặn document có chứa field `password`
>
> Và quan trọng nhất, dòng cuối cùng của file:
>
> ```
> match /{document=**} {
>   allow read, write: if false;
> }
> ```
>
> Nghĩa là **mặc định khóa tất cả**. Collection nào chưa được khai báo thì không ai truy cập được. Đây là nguyên tắc *default deny* — an toàn theo hướng mặc định, thay vì phải nhớ khóa từng chỗ."

**CỬA SỔ:** mở `lib/core/utils/validators.dart`

> "**Lớp 1 — validate đầu vào.** Các hàm `required`, `email`, `password`, `confirmPassword`, `rating` (1–10) trả về thông báo lỗi tiếng Việt. `merge()` gộp nhiều lỗi thành một chuỗi.
>
> Em tách riêng thành class `Validators` thay vì viết inline trong từng form — nhờ vậy quy tắc nhất quán, và test được độc lập."

### 3.3. Tổng kết bảo mật

**NÓI:**

> "Tóm lại, em xây dựng bảo mật theo nguyên tắc **phòng thủ nhiều lớp**: client lọc sớm để tiết kiệm RAM và data, nhưng **quyết định phân quyền luôn nằm ở server**. Nếu attacker bypass được app, Rules vẫn chặn.
>
> Và một đánh đổi em muốn nói rõ: mobile không có cookie HttpOnly nên token buộc nằm trên máy — em **chấp nhận** rủi ro đó nhưng giảm thiểu bằng cách mã hoá kho lưu trữ và xoá sạch token khi logout."

---

## PHẦN 4 — KIỂM THỬ (1.5–2 phút)

**CỬA SỔ:** terminal, `cd cinema_app` rồi `flutter test`

**NÓI (chạy test trước khi nói, để màn hình hiện kết quả):**

> "Phần này là **yêu cầu 8 đến 8e** — Kiểm thử và Kiểm định. Nhóm em viết **13 file test, 157 test case**, và tất cả đều pass.
>
> Em chia theo đúng 5 tiêu chí:
>
> **8a — Xử lý lỗi:** `repositories_test.dart` kiểm tra repository bắt `ApiException` ở biên và trả default an toàn, không crash.
>
> **8b — Unit test cho các lớp Core:** validators, sanitizer, video source, utils, rate limiter, models, page result.
>
> **8c — Full app flow:** `app_flow_test.dart` mô phỏng luồng Home → Search → Category → Favorite/Profile → Player.
>
> **8d — Thành công và thất bại:** mỗi service đều có cả case hợp lệ và case sai — sai định dạng, quá độ dài, URL độc, spam quá nhanh.
>
> **8e — Widget UI:** `common_widgets_test.dart` và `widget_test.dart` kiểm tra `SearchInput`, `CustomButton`, `LoadingSpinner`, `ConfirmDialog`, `Pagination`, `RatingStars`.
>
> Điểm em muốn lưu ý: nhóm em **không mock quá mức**. Em viết cả `Mock` lẫn `Shim` — Shim là một implementation thật, chỉ thay phần I/O, để test vẫn chạy được logic parse mềm mà em vừa nói ở Phần 2."

**CỬA SỔ:** mở `test/video_source_test.dart` (hoặc `generic_utils_test.dart`)

> "Ví dụ, đây là test cho `VideoSource` — em test cả trường hợp đúng: YouTube ID 11 ký tự được trích ra, `?t=90` được giữ lại; lẫn trường hợp sai: `javascript:` bị từ chối, `http` từ host lạ bị chặn."

---

## PHẦN 5 — GIAO DIỆN & CHẠY THỬ (2–3 phút)

### 5.1. Chạy app

**CỬA SỔ:** terminal

> "Để chạy app, em chỉ cần 2 lệnh:
>
> ```
> cd cinema_app
> flutter run
> ```
>
> Em xin nhấn mạnh: đây là **một codebase**, build ra cả ba thứ:
>
> - **Web PWA**: `flutter build web` → deploy Docker + Nginx lên Render, live tại `phimhay24h.onrender.com`
> - **APK Android**: `flutter build apk --release` → ra file ~59MB, và em có workflow GitHub Actions tự động build mỗi khi push lên `main`
> - **iOS**: `flutter build ios`"

### 5.2. Giới thiệu giao diện

**CỬA SỔ:** mở app (web trên trình duyệt, hoặc link VMOS)

**NÓI:**

> "Về giao diện, app dùng Material 3 với bảng màu cinema neon — nền tối, cam chủ đạt `#F26522`.
>
> **Bottom Navigation 5 tab:** Trang chủ, Tìm kiếm, Thể loại, Yêu thích, Tài khoản.
>
> **Trang chủ** có banner xoay phim nổi bật, dải trending, và các hàng phim theo thể loại."

> *(mở tab Tìm kiếm)*
>
> "**Tìm kiếm** — gõ là tìm, có debounce nên không dồn request."

> *(mở tab Thể loại)*
>
> "**Thể loại** — lọc kết hợp thể loại, quốc gia, năm, loại phim."

> *(mở một phim)*
>
> "**Chi tiết phim** — thông tin, chọn tập, bình luận có reply lồng nhau, chấm điểm 1–10."

> *(bấm play)*
>
> "**Trang xem phim** — phát video. Em xin nhấn mạnh 3 thứ ở đây:
> - Chọn được tập, chuyển tập mượt
> - **Xem tiếp**: tiến độ xem được lưu theo tập, mở app lần sau là gợi ý tiếp tục
> - Có nút **báo lỗi video** để user phản hồi khi phim không phát được — admin xử lý trong dashboard."

> *(mở tab Tài khoản)*
>
> "**Tài khoản** — đổi theme sáng/tối, xem thông tin cá nhân, đổi mật khẩu, đăng xuất."

### 5.3. Tính năng nổi bật: trợ lý giọng nói

**CỬA SỔ:** bấm nút orb trên app

> "Đây là trợ lý giọng nói Lina/Seven — nút orb nổi. Em bấm vào, nói: *'tìm phim hành động'*, và app tự mở trang tìm kiếm với từ khoá đó, rồi đọc kết quả lại bằng TTS."

### 5.4. Giao diện Admin

**CỬA SỔ:** mở `docs/images/web-admin.png`

> "Cuối cùng là phần Admin — dashboard quản trị. Admin đăng nhập bằng tài khoản riêng, vào được 5 tab: quản lý phim, quản lý user (khoá tài khoản), duyệt bình luận, quản lý thể loại/quốc gia, và gửi thông báo.
>
> Điểm bảo mật ở đây: Firestore Rules chỉ cho phép UID nằm trong collection `admins` ghi được `movies`, `episodes`, `genres` — user thường **không thể** ghi vào dữ liệu nội dung dù có hack client."

---

## PHẦN 6 — KẾT THÚC (20 giây)

**CỬA SỔ:** quay lại terminal hoặc màn hình app

> "Vậy là em đã trình bày xong toàn bộ dự án PhimHay24h Mobile:
>
> - Kiến trúc **3 tầng** với Firebase-native và phân quyền đẩy xuống server
> - Cấu trúc code **9 nhóm, tách bạch trách nhiệm**, theo Repository Pattern
> - Xử lý lỗi **có chủ đích** ở từng tầng, và code **Generics** được dùng lại cho toàn app
> - **8 lớp bảo mật**, nhiều lớp vẫn dùng được khi app bị bypass
> - **157 test case** pass, phủ đủ yêu cầu 8a–8e
> - Một codebase, ba nền tảng: Android, Web PWA, iOS
>
> Link demo app, web và video hướng dẫn đều có trong README trên GitHub. Em cảm ơn thầy và các bạn đã lắng nghe!"

---

# 📋 CHECKLIST TRƯỚC KHI QUAY

- [ ] `flutter pub get` đã chạy xong, `flutter test` pass sạch (quay màn hình này)
- [ ] App đã đăng nhập sẵn 1 tài khoản demo → không mất thời gian gõ
- [ ] Mở sẵn các tab: `main.dart`, `auth_provider.dart` (hàm `login`), `generic_utils.dart`, `movie_model.dart` (`fromJson`), `input_sanitizer.dart`, `secure_token_storage.dart`, `rate_limiter.dart`, `video_source.dart`, `firestore.rules`
- [ ] Mở sẵn ảnh: `KTTongThe.drawio.png`, `ACLogin.png`, `Se_XemChiTietPhim.png`, `web-admin.png`
- [ ] Tắt thông báo cá nhân trên máy (tránh lộ tên/email trong video)
- [ ] Test trợ lý giọng nói hoạt động (cần quyền mic — nếu lỗi thì bỏ qua phần này, nói "tính năng này em demo bằng video đã quay")
- [ ] Quay theo thứ tự Phần 0 → 6, **không cắt ghép** nếu không cần

# ⚠️ CÂU HỎI GIÁO VIÊN CÓ THỂ HỎI — CHUẨN B SẴN

| Câu hỏi | Trả lời |
|---|---|
| "Vì sao dùng Firestore thay MySQL?" | Firestore realtime, không cần thuê server, có sẵn Security Rules đẩy phân quyền xuống server — phù hợp bài mobile hơn là tự dựng backend. Bản web vẫn giữ NestJS + MySQL để đối chiếu kiến trúc. |
| "Generics dùng ở đâu, lợi ích?" | `core/utils/generic_utils.dart` — 1 bộ hàm dùng chung cho mọi model thay vì mỗi model một hàm riêng. Ràng buộc `K extends Comparable<K>` cho phép sắp xếp bằng 1 hàm cho double/int/String. |
| "Client có thể tự nâng lên admin không?" | Không. `user_auth_map` khóa `role`, client tự tạo bản ghi role 'admin' sẽ bị Rules chặn; admin phải do server/admin console ghi vào collection `admins`. |
| "Token lưu ở đâu, có an toàn không?" | `flutter_secure_storage` (Keychain/EncryptedSharedPreferences), tách khỏi SharedPreferences chỉ chứa theme. Logout xoá sạch. |
| "157 test là test thật hay mock hết?" | Cả hai: có Mock cho dependency ngoài, và Shim (implementation thật thay I/O) để logic parse mềm vẫn được kiểm chứng. |
| "Một codebase build ra 3 nền tảng thế nào?" | Flutter compile đa nền tảng; Web dùng `flutter build web` + Docker multi-stage (Flutter build → Nginx serve) deploy Render; Android dùng `flutter build apk --release` qua GitHub Actions artifact. |
| "Sửa bug gì đáng kể nhất?" | Lỗi parse mềm làm mất phim trên Firestore (`id`/`is_visible` khác kiểu) → viết helper parse mềm, một field lỗi không còn làm mất cả document. |
