# Đề xuất giải pháp tối ưu hiệu năng và mở rộng – BCDT

Tài liệu **đề xuất** các giải pháp tối ưu hiệu năng và hướng mở rộng (scalability) cho hệ thống BCDT. **Ưu tiên: giải pháp dài hạn** để tránh phải refactor/cập nhật kiến trúc sau này. Triển khai **cho khối chính phủ** — lưu ý ràng buộc (vd. không dùng CDN công cộng). Tham chiếu: [W16_PERFORMANCE_SECURITY.md](de_xuat_trien_khai/W16_PERFORMANCE_SECURITY.md), [04.GIAI_PHAP_KY_THUAT.md](script_core/04.GIAI_PHAP_KY_THUAT.md), [REVIEW_KIEN_TRUC_CODEBASE.md](REVIEW_KIEN_TRUC_CODEBASE.md).

**Ngày:** 2026-02-25

---

## 0. Giải pháp dài hạn – thiết kế tránh cập nhật sau (ưu tiên)

Mục này tập trung vào **quyết định kiến trúc và triển khai ngay từ đầu** để khi mở rộng (nhiều instance, dữ liệu lớn, hạ tầng chính phủ) **không phải thay đổi code/hạ tầng lớn**.

### 0.1. Nguyên tắc

- **Abstraction trước, implementation sau:** Cache, queue, storage dùng interface/abstraction; triển khai có thể thay (IMemoryCache → Redis, file → blob nội bộ) mà không đổi lớp nghiệp vụ.
- **Chuẩn hóa sớm:** Pagination, filter, sort cho mọi list API; index và partition strategy cho bảng tăng trưởng theo thời gian.
- **Khối chính phủ:** Không sử dụng CDN công cộng (bên thứ ba); static và cache phục vụ từ hạ tầng nội bộ / reverse proxy trong mạng chính phủ.

### 0.2. Cache: dùng IDistributedCache ngay từ đầu (dài hạn)

- **Lý do:** Khi chạy 1 instance có thể dùng `IDistributedCache` với implementation in-memory (MemoryDistributedCache); khi scale nhiều instance chỉ cần đổi sang Redis (hoặc Redis nội bộ) **không đổi code** service.
- **Cách làm:** Trong Application định nghĩa `ICacheService` (hoặc dùng trực tiếp `IDistributedCache`); Infrastructure implement với `MemoryDistributedCache` (dev/đơn instance) hoặc Redis (staging/prod). Service cache master data (ReportingFrequency, OrganizationType, DataSource, FilterDefinition, …) qua abstraction này.
- **Kết quả:** Tránh sau này phải thay IMemoryCache bằng Redis và sửa toàn bộ chỗ gọi cache.

### 0.3. Database: thiết kế sẵn cho partition và read replica

- **Partition-ready:** Bảng `BCDT_ReportDataRow`, `BCDT_ReportPresentation` có thể partition theo `ReportingPeriodId` hoặc năm (partition function/scheme); thiết kế index và query tránh scan toàn bảng. Có thể triển khai partition sau khi dữ liệu đạt ngưỡng nhưng **schema và naming** tránh thay đổi lớn.
- **Read replica–ready:** Tách sớm “query chỉ đọc” (dashboard, báo cáo, aggregate) và “ghi” (submission, presentation, workflow) trong code: dùng connection/cursor read khi có cấu hình ReadReplica, connection write cho command. Khi hạ tầng bật replica chỉ cần cấu hình connection string, không refactor service.
- **Archive policy:** Định nghĩa rõ (tài liệu + config) policy archive submission đã Approved quá hạn (vd. &gt; 2 năm); khi triển khai chỉ cần job + script chuyển sang bảng/DB archive, không đổi schema gốc.

### 0.4. API: pagination, timeout, health, nén

- **Pagination chuẩn:** Mọi list API hỗ trồ pageSize + pageNumber (hoặc cursor) và meta (totalCount, hasNext) ngay từ đầu; tránh sau này phải thêm và breaking change cho client.
- **Timeout & CancellationToken:** Mọi API dài (workbook-data, aggregate) nhận và lan truyền CancellationToken; cấu hình timeout Kestrel.
- **Health check:** Endpoint `/health` (và `/ready`) cho load balancer và giám sát; kiểm tra DB (và cache/Redis nếu có). Cần cho môi trường chính phủ (giám sát nội bộ).
- **Nén response:** Bật response compression (gzip/brotli) cho JSON; giảm bandwidth trên mạng nội bộ cũng có lợi.

### 0.5. Background job (Hangfire)

- **Pattern cố định:** Tác vụ nặng (export hàng loạt, aggregate lớn, gửi thông báo hàng loạt) luôn đẩy vào Hangfire; API trả jobId, client poll hoặc nhận kết quả qua SignalR. Tránh request HTTP giữ kết nối lâu và dễ scale worker sau này.
- **Lưu ý:** Hangfire storage (SQL Server) nằm trong hạ tầng chính phủ; không dùng dịch vụ queue đám mây công cộng nếu chính sách không cho phép.

### 0.6. Static assets & “CDN” trong khối chính phủ (không CDN công cộng)

- **Ràng buộc:** Khối chính phủ có thể **không được sử dụng CDN công cộng** (bên thứ ba, đa vùng công cộng). Tài nguyên tĩnh (JS, CSS, font) và cache phải phục vụ từ hạ tầng **nội bộ**.
- **Giải pháp thay thế:**
  - **Static trên server ứng dụng hoặc file server nội bộ:** Build FE ra thư mục static; host qua IIS/nginx trong mạng chính phủ; không đưa lên CDN công cộng.
  - **Reverse proxy cache (nginx / IIS / F5):** Đặt reverse proxy trước API + static; cấu hình cache HTTP (Cache-Control) cho static (vd. `max-age=31536000` cho file có hash). Giảm tải origin, vẫn nằm trong mạng nội bộ.
  - **Cache header:** Response header Cache-Control cho static (vd. long max-age cho asset có hash) do chính server ứng dụng hoặc reverse proxy trả về.
- **Không dùng:** Azure CDN, CloudFront, hoặc bất kỳ CDN công cộng bên thứ ba trừ khi có phê duyệt đặc biệt và đảm bảo tuân thủ quy định.

---

## 1. Hiện trạng (tóm tắt)

- **Baseline W16:** Các API đo được đều &lt; 3s (MVP đạt). GET /forms ~1.4s (cold); workbook-data ~26–76 ms (form đơn giản).
- **Đã làm:** Batch DataSource metadata trong BuildWorkbookFromSubmissionService; OWASP Pass.
- **Chưa làm:** MemoryCache, batch FilterDefinition/Resolve cột động, index tối ưu, tối ưu FE (lazy route, React Query cache), mở rộng scale (horizontal, read replica, queue).

---

## 2. Tối ưu hiệu năng

### 2.1. Backend – Database & truy vấn

| # | Giải pháp | Mô tả | Effort | Ưu tiên | Ghi chú |
|---|-----------|--------|--------|---------|---------|
| **2.1.1** | **Index thiếu** | Chạy `sys.dm_db_missing_index_details` trên DB BCDT; thêm index cho bảng/filter thường dùng: FormPlaceholderOccurrence (FormSheetId), FormPlaceholderColumnOccurrence (FormSheetId), FilterCondition (FilterDefinitionId), ReportDataRow (SubmissionId, SheetIndex, RowIndex), ReportSubmission (FormDefinitionId, OrganizationId, ReportingPeriodId, Status). | 0.5–1 ngày | Cao | Script migration tạo index, đo lại query plan. |
| **2.1.2** | **Batch FilterDefinition + FilterCondition** | Trong DataSourceQueryService (hoặc BuildWorkbook): load tất cả FilterDefinition + FilterCondition cần cho một request theo list filterDefinitionId (1–2 query), cache trong Dictionary; trong vòng lặp dùng cache thay vì gọi DB mỗi lần. | 0.5–1 ngày | Cao | Giảm N query khi form có nhiều placeholder. |
| **2.1.3** | **Batch resolve cột động (P8)** | Gom nhóm FormPlaceholderColumnOccurrence theo (DataSourceId, FilterDefinitionId); với mỗi cặp gọi QueryWithFilterAsync **một lần**, dùng chung kết quả cho mọi occurrence cùng cặp. | 1 ngày | Trung bình | Giảm số query khi nhiều cột động dùng chung nguồn/lọc. |
| **2.1.4** | **AsNoTracking nhất quán** | Đảm bảo mọi query chỉ đọc (list, get by id cho hiển thị) dùng `.AsNoTracking()` để EF không theo dõi entity → giảm memory và tăng tốc. | 0.5 ngày | Trung bình | Grep các truy vấn read-only, bổ sung AsNoTracking. |
| **2.1.5** | **Pagination chuẩn** | List API (forms, submissions, users, …) hỗ trợ pageSize + pageNumber hoặc cursor; trả về meta (totalCount, hasNext). Tránh trả toàn bộ bản ghi khi dataset lớn. | 1–2 ngày | Trung bình | Đã có ở một số API; mở rộng và thống nhất. |
| **2.1.6** | **Connection pooling** | SQL Server mặc định có connection pooling; kiểm tra connection string có `Pooling=true` (mặc định); tránh mở/đóng connection thủ công không cần thiết. | 0.5 ngày | Thấp | Kiểm tra cấu hình + số connection đồng thời. |

### 2.2. Backend – Cache

| # | Giải pháp | Mô tả | Effort | Ưu tiên | Ghi chú |
|---|-----------|--------|--------|---------|---------|
| **2.2.1** | **Cache master data (dài hạn: IDistributedCache)** | Cache dữ liệu ít thay đổi: ReportingFrequency, OrganizationType, IndicatorCatalog (list), DataSource metadata (theo id), FilterDefinition + FilterCondition (theo id). TTL 5–15 phút; invalidate khi CUD. **Dài hạn:** Dùng **IDistributedCache** (Application); Infrastructure implement bằng MemoryDistributedCache (đơn instance) hoặc Redis (nhiều instance). Tránh IMemoryCache thuần để sau không phải đổi code khi scale. | 1–2 ngày | Cao | Xem mục 0.2. |
| **2.2.2** | **Cache workbook-data (tùy chọn)** | Với submission Draft/Revision, workbook structure (form definition) ít đổi; có thể cache kết quả build theo (submissionId, formVersionId) với TTL ngắn (1–2 phút). Khi PUT presentation / sync-from-presentation → invalidate. Rủi ro: dữ liệu có thể lệch nếu nhiều tab cùng submission. | 1 ngày | Thấp | Chỉ áp dụng nếu đo được workbook-data là bottleneck. |
| **2.2.3** | **Response caching HTTP (GET)** | Với endpoint read-only ít đổi (vd. GET /reporting-frequencies, GET /organization-types): `[ResponseCache(Duration = 60)]` hoặc middleware cache response. Cẩn thận với dữ liệu theo user/org (RLS) → chỉ cache endpoint không phụ thuộc user. | 0.5 ngày | Thấp | Áp dụng cho danh mục dùng chung toàn hệ thống. |

### 2.3. Backend – API & ứng dụng

| # | Giải pháp | Mô tả | Effort | Ưu tiên | Ghi chú |
|---|-----------|--------|--------|---------|---------|
| **2.3.1** | **Nén response (gzip/brotli)** | Bật response compression cho JSON (và file tĩnh nếu có). Giảm bandwidth, đặc biệt với workbook-data (payload lớn). | 0.5 ngày | Trung bình | `AddResponseCompression`, `UseResponseCompression`; Brotli ưu tiên hơn gzip. |
| **2.3.2** | **Timeout & cancellation** | Đảm bảo API dài (workbook-data, aggregate) nhận CancellationToken và truyền xuống service; cấu hình timeout Kestrel hoặc middleware để tránh request treo. | 0.5 ngày | Trung bình | Đã có async/CancellationToken; kiểm tra lan truyền đầy đủ. |
| **2.3.3** | **Background job cho tác vụ nặng** | Export Excel/PDF hàng loạt, aggregate lớn: đẩy vào Hangfire (hoặc queue); API trả jobId, client poll hoặc SignalR thông báo khi xong. Tránh request HTTP giữ kết nối quá lâu. | 2–3 ngày | Trung bình | Cần Hangfire đã cấu hình; endpoint enqueue + endpoint get job status. |
| **2.3.4** | **Health check** | Endpoint `/health` (và `/ready` nếu cần) kiểm tra DB, cache (nếu có); dùng cho load balancer và monitoring. | 0.5 ngày | Thấp | `AddHealthChecks`, `MapHealthChecks`. |

### 2.4. Frontend

| # | Giải pháp | Mô tả | Effort | Ưu tiên | Ghi chú |
|---|-----------|--------|--------|---------|---------|
| **2.4.1** | **Lazy load route** | Dùng `React.lazy()` + `Suspense` cho các trang ít dùng (vd. FormConfig, IndicatorCatalogs, WorkflowDefinitions, Settings). Giảm bundle initial, tải nhanh lần đầu. | 1 ngày | Cao | Tách import page thành lazy; fallback loading (PageLoading). |
| **2.4.2** | **React Query: staleTime & cache** | Tăng `staleTime` cho query ít đổi (vd. reporting-frequencies, organization-types, forms list) để giảm refetch không cần thiết. Ví dụ: `staleTime: 60 * 1000` (1 phút). Cân bằng với tính cập nhật dữ liệu. | 0.5 ngày | Trung bình | QueryClient defaultOptions hoặc từng useQuery. |
| **2.4.3** | **Bundle analysis** | Chạy `vite build` + plugin phân tích bundle (rollup-plugin-visualizer hoặc tương đương); xác định thư viện nặng (Fortune-sheet, DevExtreme, xlsx). Cân nhắc dynamic import cho module nặng chỉ dùng ở 1–2 trang. | 0.5 ngày | Trung bình | Giảm initial bundle bằng lazy load trang/màn. |
| **2.4.4** | **Virtualization danh sách dài** | Trang có table/list rất dài (submissions, users, report data): dùng virtual scroll (Ant Design Table virtual, react-window, hoặc tương đương) để chỉ render phần visible → giảm DOM và re-render. | 1 ngày | Thấp | Áp dụng khi số dòng &gt; 100–200. |
| **2.4.5** | **Prefetch / preload** | Khi user hover vào link hoặc vào dashboard: prefetch query cho trang có khả năng mở tiếp (vd. forms list, submissions list). Giảm thời gian chờ khi chuyển trang. | 0.5 ngày | Thấp | useQueryClient().prefetchQuery. |

---

## 3. Mở rộng (scalability)

### 3.1. Mở rộng theo chiều ngang (horizontal scaling)

| # | Giải pháp | Mô tả | Effort | Ưu tiên | Ghi chú |
|---|-----------|--------|--------|---------|---------|
| **3.1.1** | **Stateless API** | API hiện đã stateless (JWT, không session in-memory). Đảm bảo không lưu state trong memory (cache nếu dùng nên là distributed cache khi scale nhiều instance). | Đã đạt | — | Chỉ cần lưu ý khi bật in-memory cache: chuyển sang Redis khi chạy &gt; 1 instance. |
| **3.1.2** | **Load balancer** | Đặt nhiều instance API phía sau load balancer (Azure Load Balancer, nginx, AWS ALB). Sticky session không bắt buộc vì JWT stateless. | 1–2 ngày (ops) | Khi cần scale | Cấu hình deploy + health check. |
| **3.1.3** | **Distributed cache (Redis)** | Khi chạy nhiều instance: dùng Redis làm cache chung. **Nếu đã dùng IDistributedCache từ đầu (0.2):** chỉ cần đổi implementation sang Redis (trong mạng nội bộ/chính phủ), không sửa code service. | 1–2 ngày (nếu đã có abstraction) | Khi scale &gt; 1 instance | Redis triển khai trên hạ tầng nội bộ; không bắt buộc dịch vụ đám mây công cộng. |

#### Triển khai Perf-19 – Load balancer (3.1.2, Ops)

Mục đích: Chạy nhiều instance API phía sau load balancer để tăng throughput và độ sẵn sàng. API BCDT **stateless** (JWT, không session in-memory) nên **sticky session không bắt buộc**; mỗi request có thể tới instance bất kỳ.

- **Health check:** Load balancer cần probe endpoint **GET /health** (đã có từ Perf-3). Khi instance không healthy (DB down, app crash) → LB loại instance đó khỏi pool. Cấu hình probe: interval 10–30s, timeout 5s, unhealthy threshold 2–3.
- **Cấu hình LB:** Trỏ traffic (vd. `/api`, `/health`) tới nhóm backend (nhiều instance API cùng port). Cân bằng tải: round-robin hoặc least connections. Không cần affinity/sticky nếu client gửi JWT mỗi request.
- **Ví dụ nginx upstream:**  
  `upstream bcdt_api { server 10.0.0.1:5080; server 10.0.0.2:5080; }`  
  `location /api/ { proxy_pass http://bcdt_api; proxy_http_version 1.1; proxy_set_header Host $host; proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; }`  
  `location /health { proxy_pass http://bcdt_api; }`
- **Hangfire:** Khi chạy nhiều instance, chỉ **một** instance nên chạy Hangfire Server. Trên các instance chỉ làm API (sau LB), đặt **Hangfire:ServerEnabled = false** (trong appsettings của instance đó hoặc biến môi trường `Hangfire__ServerEnabled=false`). Instance đó sẽ không gọi AddHangfireServer và không map dashboard `/hangfire`; vẫn gọi AddHangfire (storage) nên `BackgroundJob.Enqueue` từ API vẫn hoạt động, job sẽ do instance có ServerEnabled = true xử lý.
- **Redis (Perf-16):** Khi scale &gt; 1 instance, bắt buộc cấu hình **ConnectionStrings:Redis** để cache chia sẻ giữa các instance. Ứng dụng dùng StackExchange.Redis; chuỗi kết nối hỗ trợ **Single**, **Sentinel** và **Cluster** (xem mục "Redis – Connection string" bên dưới).
- **Kiểm tra:** Sau khi cấu hình LB, gọi GET /health nhiều lần → có thể trả 200 từ các IP khác nhau (nếu round-robin). Gọi API có JWT → 200 OK bất kể request đi tới instance nào.

#### Redis – Connection string (Single, Sentinel, Cluster)

**ConnectionStrings:Redis** được truyền trực tiếp vào StackExchange.Redis; **không cần cấu hình mode riêng**. Format chuỗi quyết định cách kết nối:

| Kiểu | Ví dụ ConnectionStrings:Redis | Ghi chú |
|------|-------------------------------|--------|
| **Single** | `localhost:6379` hoặc `redis-server:6379,password=xxx` | Một node Redis (mặc định port 6379). |
| **Sentinel** | `sentinel1:26379,sentinel2:26379,serviceName=mymaster,password=xxx` | Cổng Sentinel thường 26379. Có `serviceName=` thì client dùng Sentinel, tự discover master và failover. Có thể thêm `abortConnect=false` nếu cần. |
| **Cluster** | `node1:6379,node2:6379,node3:6379,password=xxx` | Nhiều endpoint (phân cách bằng dấu phẩy); StackExchange.Redis tự nhận cluster và dùng CLUSTER để discover topology. |

- **Lưu ý Sentinel:** Nếu gặp lỗi tie-breaker khi dùng Sentinel, có thể cấu hình thêm trong code (ConfigurationOptions, `TieBreaker = ""`) – hiện tại chỉ dùng chuỗi thì không set được; khi cần mới bổ sung đọc config và build ConfigurationOptions.
- **Lưu ý Cluster:** Cache (IDistributedCache) tương thích cluster; key được hash theo slot. Không cần thay code khi chuyển từ single sang Sentinel hoặc Cluster, chỉ đổi giá trị ConnectionStrings:Redis.

### 3.2. Database

| # | Giải pháp | Mô tả | Effort | Ưu tiên | Ghi chú |
|---|-----------|--------|--------|---------|---------|
| **3.2.1** | **Read replica (reporting)** | Tách đọc báo cáo / dashboard / aggregate sang read replica; ghi (submission, presentation, workflow) vẫn vào primary. Giảm tải primary, tăng throughput đọc. Cần phân tách connection string read/write trong ứng dụng. | 2–4 ngày | Khi tải đọc cao | EF Core có thể dùng hai DbContext (primary + replica) hoặc raw connection cho query chỉ đọc. |
| **3.2.2** | **Connection pool & limit** | Cấu hình Max Pool Size trong connection string; giám sát số connection đang dùng. Tránh connection leak (dispose DbContext/connection đúng). | 0.5 ngày | Trung bình | Kiểm tra và tài liệu hóa. |
| **3.2.3** | **Partition / archive dữ liệu cũ** | Bảng ReportDataRow, ReportPresentation tăng theo thời gian; cân nhắc partition theo ReportingPeriodId hoặc năm; hoặc archive submission đã Approved lâu sang bảng/DB khác để query nhanh hơn. | 3–5 ngày | Khi dữ liệu rất lớn | Migration + policy archive. |

### 3.3. Async & queue

| # | Giải pháp | Mô tả | Effort | Ưu tiên | Ghi chú |
|---|-----------|--------|--------|---------|---------|
| **3.3.1** | **Hangfire cho job nặng** | Đã có Hangfire (theo 02.KIEN_TRUC_TONG_QUAN): dùng cho tạo kỳ báo cáo, gửi thông báo hàng loạt, export lớn, aggregate theo đơn vị cấp trên. API chỉ enqueue job, trả jobId; client poll hoặc nhận thông báo qua SignalR. | 2–3 ngày | Trung bình | Mở rộng từ job hiện có (nếu đã có) hoặc thiết kế job mới. |
| **3.3.2** | **Message queue (Azure Service Bus / RabbitMQ)** | Khi cần tách tải giữa nhiều service (vd. API → Queue → Worker xử lý sync presentation, build summary): đẩy message vào queue, worker consume. Phù hợp khi số lượng job lớn hoặc cần retry/ch dead-letter. | 5+ ngày | Thấp (tương lai) | Kiến trúc đa service. |

### 3.4. Static assets & cache (khối chính phủ – không CDN công cộng)

| # | Giải pháp | Mô tả | Effort | Ưu tiên | Ghi chú |
|---|-----------|--------|--------|---------|---------|
| **3.4.1** | **Static trên hạ tầng nội bộ** | Deploy FE: build ra static (JS, CSS, font), host trên IIS/nginx/file server **trong mạng chính phủ**. Không dùng CDN công cộng (Azure CDN, CloudFront, …) trừ khi có phê duyệt. | 1–2 ngày (ops) | Khi deploy production | Đảm bảo tuân thủ quy định khối chính phủ. |
| **3.4.2** | **Reverse proxy cache** | Đặt reverse proxy (nginx, IIS ARR, F5) trước app; cấu hình cache HTTP cho static (Cache-Control, max-age cho file có hash). Giảm tải origin, vẫn trong mạng nội bộ. | 1 ngày (ops) | Trung bình | Thay thế CDN công cộng bằng cache tại proxy nội bộ. |
| **3.4.3** | **Cache header cho static** | Response header Cache-Control cho file tĩnh (vd. max-age=31536000 cho file có hash). Do server ứng dụng hoặc reverse proxy trả về. | 0.5 ngày | Trung bình | Áp dụng ngay khi deploy static. |

#### Triển khai Perf-6 – Static & cache nội bộ (hướng dẫn)

- **Ràng buộc:** Không dùng CDN công cộng (Azure CDN, CloudFront, …). Static và cache phục vụ từ hạ tầng **nội bộ** (mạng chính phủ).
- **Bước 1 – Build FE ra static:** Trong `src/bcdt-web`: `npm run build`. Output (vd. `dist/`) chứa JS/CSS có hash trong tên file (Vite mặc định).
- **Bước 2 – Host static nội bộ:** Copy thư mục build lên IIS/nginx/file server **trong mạng nội bộ**. Cấu hình server trỏ document root tới thư mục static; API có thể chạy riêng (CORS đã cấu hình) hoặc reverse proxy trước cả API và static.
- **Bước 3 – Cache-Control:** Với file có hash (vd. `assets/index-abc123.js`): trả header `Cache-Control: public, max-age=31536000, immutable`. Với `index.html`: `Cache-Control: no-cache` hoặc `max-age=0` để luôn revalidate. Cấu hình trên reverse proxy (vd. nginx) hoặc server static.
- **Ví dụ nginx (reverse proxy + cache static):**
  - Location cho static: `alias /path/to/bcdt-web/dist;` + `add_header Cache-Control "public, max-age=31536000, immutable"` cho `~* \.(js|css|woff2?)$`.
  - Location cho `index.html`: `add_header Cache-Control "no-cache";`.
  - Proxy pass API: `proxy_pass http://backend_api;` (API chạy riêng).
- **Kiểm tra:** Sau khi deploy, gọi GET một file static (vd. JS có hash) → response header phải có **Cache-Control** phù hợp; không dùng domain CDN công cộng.

#### Triển khai Perf-15 – Reverse proxy cache (3.4.2, Ops)

Mục đích: Đặt reverse proxy (nginx, IIS ARR, F5) trước ứng dụng; cấu hình cache HTTP (Cache-Control, proxy_cache) cho static và tùy chọn cho API GET ít đổi. Giảm tải origin, **toàn bộ trong mạng nội bộ** – không dùng CDN công cộng.

- **Ràng buộc:** Không dùng Azure CDN, CloudFront hay CDN bên thứ ba. Cache và static phục vụ từ reverse proxy / file server trong mạng chính phủ.

- **Static (bắt buộc khi deploy production):**
  - File có hash (vd. `assets/index-abc123.js`, `*.css`, `*.woff2`): `Cache-Control: public, max-age=31536000, immutable`.
  - `index.html`: `Cache-Control: no-cache` hoặc `max-age=0` để client luôn revalidate (đảm bảo lấy HTML mới khi có bản deploy).

- **API GET ít đổi (tùy chọn):** Có thể cache tại reverse proxy một số endpoint read-only, ít thay đổi (vd. GET `/api/v1/reporting-frequencies`, `/api/v1/organization-types` nếu không phụ thuộc user/RLS). **Không cache** endpoint có dữ liệu theo user/đơn vị (RLS) hoặc thường xuyên thay đổi. Nếu cache API: dùng TTL ngắn (vd. 1–5 phút) và key theo URI (và Host).

- **Ví dụ nginx – cache static + proxy pass API:**
  - Cache static: `location ~* \.(js|css|woff2?)$ { alias /path/to/bcdt-web/dist; add_header Cache-Control "public, max-age=31536000, immutable"; }`
  - `index.html`: `location = /index.html { add_header Cache-Control "no-cache"; ... }`
  - API: `location /api/ { proxy_pass http://backend_bcdt_api; proxy_http_version 1.1; proxy_set_header Host $host; proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; }` (không cache API mặc định, trừ khi cấu hình proxy_cache cho location cụ thể).

- **Ví dụ nginx – cache API GET ít đổi (tùy chọn):**  
  `proxy_cache_path /var/cache/nginx/bcdt keys_zone=bcdt_api:10m max_size=100m inactive=5m;`  
  Trong `location` cho `/api/v1/reporting-frequencies` (và tương tự): `proxy_cache bcdt_api; proxy_cache_key $request_uri; proxy_cache_valid 200 1m; proxy_cache_use_stale error timeout;` (chỉ áp dụng cho endpoint không cần auth hoặc public read-only).

- **IIS (ARR – Application Request Routing):** Bật Output Caching; rule cache theo extension (`.js`, `.css`) với long max-age; rule cho API (nếu dùng) theo path và duration ngắn. Chi tiết tham khảo tài liệu IIS Output Caching / ARR Cache.

- **Kiểm tra:** Sau khi cấu hình, gọi GET file static (có hash) → response header có `Cache-Control: public, max-age=31536000, immutable` (hoặc tương đương). Gọi GET `index.html` → `Cache-Control: no-cache` hoặc `max-age=0`. Không dùng domain CDN công cộng.

---

## 4. Thứ tự ưu tiên đề xuất (tập trung dài hạn)

Ưu tiên **triển khai sớm các giải pháp dài hạn** (mục 0) để tránh refactor sau; các mục ngắn/trung hạn bổ sung tối ưu cụ thể.

### 4.1. Ưu tiên 1 – Giải pháp dài hạn (làm sớm, tránh cập nhật sau)

1. **Cache: IDistributedCache ngay từ đầu (0.2)** – Abstraction cache; triển khai MemoryDistributedCache (đơn instance), sau đổi Redis không sửa code nghiệp vụ.
2. **Pagination chuẩn cho mọi list API (0.4, 2.1.5)** – pageSize, pageNumber/cursor, meta; tránh breaking change sau.
3. **Health check (0.4, 2.3.4)** – `/health`, `/ready` cho LB và giám sát (đặc biệt quan trọng trong hạ tầng chính phủ).
4. **Timeout & CancellationToken (0.4, 2.3.2)** – API dài lan truyền cancellation; cấu hình timeout.
5. **Nén response (0.4, 2.3.1)** – gzip/brotli cho JSON.
6. **Static & cache trong mạng nội bộ (0.6, 3.4)** – Không CDN công cộng; static host nội bộ + reverse proxy cache + Cache-Control. Áp dụng ngay khi deploy production.

### 4.2. Ưu tiên 2 – Tối ưu hiệu năng (1–2 sprint)

7. **Index thiếu (2.1.1)** – Rủi ro thấp, lợi ích khi dữ liệu tăng.
8. **Batch FilterDefinition (2.1.2)** – Giảm N query workbook-data.
9. **Cache master data qua IDistributedCache (2.2.1)** – ReportingFrequency, OrganizationType, DataSource, FilterDefinition (dùng abstraction mục 0.2).
10. **Lazy load route FE (2.4.1)** – Cải thiện FCP/LCP.
11. **Thiết kế partition-ready & read replica–ready (0.3)** – Schema và tách read/write trong code; triển khai partition/replica khi hạ tầng sẵn sàng.

### 4.3. Ưu tiên 3 – Trung hạn (3–6 tháng)

12. **Batch resolve cột động (2.1.3)**, **AsNoTracking (2.1.4)**.
13. **Background job (Hangfire) cho export/aggregate (0.5, 2.3.3)** – Pattern cố định; storage trong hạ tầng nội bộ.
14. **React Query staleTime (2.4.2)**, **Bundle analysis (2.4.3)**.
15. **Reverse proxy cache (3.4.2)** nếu chưa có.

### 4.4. Khi quy mô tăng (sau này, ít thay đổi code nhờ thiết kế sớm)

16. **Redis (3.1.3)** – Chỉ đổi implementation IDistributedCache sang Redis; không refactor service.
17. **Read replica (3.2.1)** – Bật connection read khi hạ tầng có replica; code đã tách sẵn.
18. **Partition/archive (3.2.3)** – Thực hiện theo policy đã định nghĩa; schema đã partition-ready.
19. **Load balancer (3.1.2)** – Nhiều instance API; stateless + health check đã sẵn.

---

## 5. Checklist triển khai (gợi ý)

Khi triển khai từng mục:

- [ ] Đo baseline (response time, số query) trước khi sửa.
- [ ] Triển khai thay đổi (code, config, migration).
- [ ] Đo lại sau khi sửa; so sánh trước/sau.
- [ ] Cập nhật tài liệu (RUNBOOK, W16, hoặc doc riêng) và checklist "Kiểm tra cho AI" nếu có.
- [ ] (Tùy chọn) Load test khi thay đổi ảnh hưởng throughput (cache, index, connection).

### 5.1. Kiểm tra cho AI – Perf-1 (IDistributedCache)

Sau khi triển khai cache master data qua IDistributedCache (ReportingFrequency, OrganizationType, DataSource, FilterDefinition, IndicatorCatalog):

1. **Build BE:** Tắt process BCDT.Api (nếu đang chạy), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → **Pass**.
2. **API lần 1 vs lần 2:** Khởi chạy API; gọi `GET /api/v1/reporting-frequencies` (và nếu có token: `GET /api/v1/organization-types`) hai lần liên tiếp. Lần 2 có thể nhanh hơn hoặc tương đương (cache hit).
3. **Invalidate sau CUD:** Thực hiện Create hoặc Update một entity (vd. đổi tên một ReportingFrequency); gọi lại `GET /api/v1/reporting-frequencies`. Response phải trả **dữ liệu mới** (tên đã đổi), không còn bản cũ → **Pass**.
4. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.2. Kiểm tra cho AI – Perf-3 (Health check)

Sau khi thêm AddHealthChecks (Db) và MapHealthChecks("/health"):

1. **Build BE:** Tắt process BCDT.Api (nếu đang chạy), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → **Pass**.
2. **GET /health khi DB khả dụng:** Khởi chạy API; gọi `GET http://localhost:5080/health` (hoặc port cấu hình). Kỳ vọng: **200 OK**, body chứa `"status":"Healthy"` (hoặc tương đương). Không cần header Authorization.
3. **(Tùy chọn)** Khi DB không kết nối được: đổi connection string sai hoặc tắt SQL → gọi `/health` → **503** hoặc body status Unhealthy.
4. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.3. Kiểm tra cho AI – Perf-5 (Nén response)

Sau khi bật AddResponseCompression (Brotli, Gzip) và UseResponseCompression:

1. **Build BE:** Tắt process BCDT.Api (nếu đang chạy), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → **Pass**.
2. **Content-Encoding:** Khởi chạy API; gọi một endpoint trả JSON (vd. GET /api/v1/reporting-frequencies với Authorization, hoặc GET /health) với header `Accept-Encoding: br` hoặc `Accept-Encoding: gzip`. Kỳ vọng: response có header **Content-Encoding: br** (Brotli) hoặc **Content-Encoding: gzip**.
3. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.4. Kiểm tra cho AI – Perf-4 (Timeout & CancellationToken)

Sau khi đảm bảo API dài lan truyền CancellationToken và cấu hình Kestrel:

1. **Build BE:** Tắt process BCDT.Api (nếu đang chạy), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → **Pass**.
2. **Lan truyền CancellationToken:** API workbook-data (GET .../workbook-data) và aggregate (POST .../aggregate) đã nhận CancellationToken từ controller và truyền xuống service → EF (FirstOrDefaultAsync, ToListAsync, SaveChangesAsync). Không cần sửa code nếu đã đúng.
3. **Kestrel Limits:** appsettings.json có mục Kestrel:Limits (RequestHeadersTimeout, KeepAliveTimeout) để tránh kết nối treo.
4. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.5. Kiểm tra cho AI – Perf-2 (Pagination chuẩn)

Sau khi triển khai pagination cho list API (forms, submissions) với `pageSize`, `pageNumber` và meta `totalCount`, `hasNext`:

1. **Build BE:** Tắt process BCDT.Api (nếu đang chạy), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → **Pass**.
2. **GET forms có paging:** Gọi `GET /api/v1/forms?pageSize=10&pageNumber=1` (kèm Authorization). Kỳ vọng: **200 OK**, body `data` có `items` (mảng), `totalCount`, `pageNumber`, `pageSize`, `hasNext`. Không có `pageSize`/`pageNumber` thì trả list như cũ (data là mảng trực tiếp).
3. **GET submissions có paging:** Gọi `GET /api/v1/submissions?pageSize=10&pageNumber=1` (kèm Authorization). Kỳ vọng: **200 OK**, body `data` có `items`, `totalCount`, `pageNumber`, `pageSize`, `hasNext`.
4. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.6. Kiểm tra cho AI – Perf-7 (Index thiếu)

Sau khi thêm script migration index (vd. `docs/script_core/sql/v2/26.perf7_missing_indexes.sql`):

1. **Script chạy thành công:** Chạy script trên DB BCDT (hoặc môi trường dev). Kỳ vọng: không lỗi; PRINT báo "26.perf7_missing_indexes.sql completed" (và "Created IX_..." nếu tạo mới).
2. **Index tồn tại:** Query `SELECT name FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.BCDT_ReportSubmission') AND name = 'IX_ReportSubmission_Form_Org_Period_Status'` trả 1 dòng (hoặc kiểm tra bảng có index mới).
3. **(Tùy chọn)** Chạy `sys.dm_db_missing_index_details` trên DB BCDT sau khi có workload để xem gợi ý index thêm; bổ sung script nếu cần.
4. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.7. Kiểm tra cho AI – Perf-8 (Batch FilterDefinition + FilterCondition)

Sau khi triển khai batch load FilterDefinition + FilterCondition trong BuildWorkbookFromSubmissionService và DataSourceQueryService:

1. **Build BE:** Tắt process BCDT.Api (nếu đang chạy), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → **Pass**.
2. **workbook-data:** Gọi GET `/api/v1/submissions/{id}/workbook-data` với submission có form dùng placeholder dòng hoặc cột có FilterDefinitionId. Kỳ vọng: **200 OK**, response có cấu trúc workbook (sheets, dynamic regions/column regions). Số lần gọi DB cho FilterDefinition/FilterCondition giảm (1–2 query theo list id thay vì N lần GetById theo từng occurrence).
3. **(Tùy chọn)** Dùng MCP user-mssql hoặc SQL Profiler để xác nhận số query FilterDefinition/FilterCondition trong một request workbook-data.
4. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.8. Kiểm tra cho AI – Perf-6 (Static & cache nội bộ)

Sau khi triển khai static & cache theo mục 0.6, 3.4 và hướng dẫn "Triển khai Perf-6" trong DE_XUAT:

1. **Không dùng CDN công cộng:** Xác nhận static (JS, CSS, font) **không** được tải từ Azure CDN, CloudFront hay CDN bên thứ ba; được host từ server/reverse proxy **nội bộ**.
2. **Cache-Control cho file có hash:** Gọi GET một file static có hash trong tên (vd. `/assets/index-xxxxx.js` sau khi deploy). Kỳ vọng: response header có **Cache-Control** (vd. `public, max-age=31536000, immutable` hoặc tương đương).
3. **index.html:** Có Cache-Control no-cache hoặc max-age=0 để client revalidate khi cần.
4. **Báo Pass/Fail từng bước** trước khi báo xong task. *(Task Perf-6 chủ yếu là tài liệu + hướng dẫn; khi deploy production mới áp dụng đủ bước trên.)*

### 5.9. Kiểm tra cho AI – Perf-9 (Cache master data qua IDistributedCache)

**Perf-9 đạt được bởi triển khai Perf-1:** Master data (ReportingFrequency, OrganizationType, DataSource, FilterDefinition, IndicatorCatalog) đã được cache qua ICacheService/IDistributedCache; TTL 10 phút; invalidate khi CUD. Kiểm tra theo **mục 5.1** (Build BE; gọi API list 2 lần; CUD rồi gọi lại → dữ liệu mới). Không cần thay đổi code thêm cho Perf-9.

### 5.10. Kiểm tra cho AI – Perf-10 (Lazy load route FE)

Sau khi triển khai React.lazy + Suspense cho trang ít dùng (DE_XUAT 2.4.1):

1. **Build FE:** Trong `src/bcdt-web` chạy `npm run build` → **Pass**. Output có các chunk riêng cho trang lazy (vd. FormConfigPage-*.js, SubmissionDataEntryPage-*.js, SettingsPage-*.js, …) và main index-*.js nhỏ hơn so với trước (không gộp toàn bộ trang vào bundle chính).
2. **Route lazy load:** Mở app (dev hoặc build), đăng nhập; chuyển sang trang ít dùng (vd. Cấu hình biểu mẫu, Loại thực thể, Quy trình phê duyệt, Cài đặt). Kỳ vọng: lần đầu vào trang có thể thấy fallback "Đang tải trang..." (PageLoading) rồi nội dung hiển thị; không lỗi console.
3. **E2E (khi BE chạy tại 5080):** Chạy `npm run test:e2e` trong `src/bcdt-web`. Báo Pass/Fail từng file spec. *Lưu ý: E2E cần API backend; nếu không chạy BE thì test login/redirect có thể Fail (môi trường), không phải do lazy load.*
4. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.11. Kiểm tra cho AI – Perf-11 (Partition-ready, Read replica–ready, Archive policy)

Sau khi triển khai tài liệu và script mẫu theo [PERF11_PARTITION_REPLICA_ARCHIVE.md](de_xuat_trien_khai/PERF11_PARTITION_REPLICA_ARCHIVE.md):

1. **Build BE:** Tắt process BCDT.Api (nếu đang chạy), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → **Pass**.
2. **Tài liệu:** File PERF11_PARTITION_REPLICA_ARCHIVE.md có đủ 3 phần: Partition-ready (bảng, chiến lược, query tránh full scan), Read replica–ready (tách read/write, cấu hình connection, appsettings mẫu), Archive policy (định nghĩa, config ArchivePolicy).
3. **Script mẫu:** File `docs/script_core/sql/v2/27.perf11_partition_sample.sql` tồn tại; tạo partition function/scheme mẫu (PF_BCDT_Year, PS_BCDT_Year, PF_BCDT_ReportingPeriodId, PS_BCDT_ReportingPeriodId); có ghi chú không chạy trực tiếp lên production.
4. **Config:** appsettings.json có section `ArchivePolicy` (ArchiveEnabled, RetentionYears, BatchSize).
5. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.12. Kiểm tra cho AI – Perf-12 (Batch resolve cột động, AsNoTracking)

Sau khi triển khai batch resolve cột động (2.1.3) và rà soát AsNoTracking (2.1.4):

1. **Build BE:** Tắt process BCDT.Api (nếu đang chạy), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → **Pass**.
2. **Batch cột động:** Trong BuildWorkbookFromSubmissionService, với form có nhiều FormPlaceholderColumnOccurrence dùng cùng (DataSourceId, FilterDefinitionId), QueryWithFilterAsync được gọi **một lần** cho mỗi cặp (cache columnDataSourceCache); ResolveColumnLabelsAsync dùng cache khi có. Số lần gọi QueryWithFilterAsync cho cột động ≤ số cặp (DataSourceId, FilterDefinitionId) duy nhất trên sheet.
3. **workbook-data:** Gọi GET `/api/v1/submissions/{id}/workbook-data` với submission có form P8 (placeholder cột động). Kỳ vọng: **200 OK**, workbook có đúng cấu trúc; không tăng số query so với trước (hoặc giảm khi nhiều cột dùng chung nguồn/lọc).
4. **AsNoTracking:** Các query chỉ đọc (list, get by id hiển thị) trong Infrastructure đã dùng `.AsNoTracking()` nhất quán (BuildWorkbookFromSubmissionService, FilterDefinitionService, ReportSubmissionService, FormDefinitionService, …); không cần sửa thêm trừ khi phát hiện đường dẫn read-only còn thiếu.
5. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.13. Kiểm tra cho AI – Perf-13 (Hangfire – background job)

Sau khi triển khai Hangfire (0.5, 2.3.3):

1. **Build BE:** Tắt process BCDT.Api (nếu đang chạy), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → **Pass**.
2. **Hangfire cấu hình:** Program.cs có AddHangfire (SQL Server storage); AddHangfireServer và MapHangfireDashboard chỉ chạy khi **Hangfire:ServerEnabled** = true (mặc định true). Trên instance chỉ làm API (sau LB), đặt `Hangfire:ServerEnabled = false` để chỉ một instance chạy job (xem mục Triển khai Perf-19). Path dashboard từ Hangfire:DashboardPath, mặc định /hangfire. Bảng Hangfire trong DB được tạo tự động khi chạy API lần đầu.
3. **Endpoint enqueue:** POST `/api/v1/jobs/aggregate-submission` body `{ "submissionId": 123 }` (JWT) → **200 OK**, response `{ "data": { "jobId": "..." } }`.
4. **Endpoint get status:** GET `/api/v1/jobs/{jobId}` (JWT) → **200 OK**, response có `state` (Enqueued, Processing, Succeeded, Failed), `createdAt`. Client poll cho đến khi Succeeded hoặc Failed.
5. **Job mẫu:** AggregateSubmissionJob (Infrastructure/Jobs) gọi IAggregationService.AggregateSubmissionAsync; [AutomaticRetry(Attempts = 2)].
6. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.14. Kiểm tra cho AI – Perf-14 (React Query staleTime + Bundle analysis)

Sau khi triển khai React Query staleTime (2.4.2) và Bundle analysis (2.4.3):

1. **Build FE:** Trong `src/bcdt-web` chạy `npm run build` → **Pass**.
2. **staleTime:** Trong `src/bcdt-web/src/App.tsx`, QueryClient có `defaultOptions.queries.staleTime: 60 * 1000` (1 phút) – giảm refetch không cần thiết cho query ít đổi.
3. **Bundle analysis:** Sau `npm run build`, file `src/bcdt-web/dist/stats.html` tồn tại; mở bằng browser để xem treemap/sunburst (thư viện nặng: Fortune-sheet, DevExtreme, xlsx).
4. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.15. Kiểm tra cho AI – Perf-15 (Reverse proxy cache)

Sau khi bổ sung tài liệu/hướng dẫn Triển khai Perf-15 (DE_XUAT mục 3.4.2 và "Triển khai Perf-15"):

1. **Tài liệu đủ cho Ops:** DE_XUAT có mục "Triển khai Perf-15 – Reverse proxy cache" với: mục đích; Cache-Control cho static (file hash = long max-age, index.html = no-cache); tùy chọn cache GET API ít đổi (và lưu ý không cache API RLS/user); ví dụ nginx (static + proxy pass API, tùy chọn proxy_cache cho API); ví dụ IIS ARR ngắn; ràng buộc không CDN công cộng; bước kiểm tra.
2. **RUNBOOK:** Mục 8.3 tham chiếu Perf-15 và DE_XUAT 5.15 (để Ops tìm hướng dẫn chi tiết).
3. **Báo Pass/Fail** trước khi báo xong task. *(Task Perf-15 chỉ là tài liệu; không cần build code.)*

### 5.16. Kiểm tra cho AI – Perf-16 (Redis khi scale > 1 instance)

Sau khi cấu hình optional Redis (đổi DI từ MemoryDistributedCache sang StackExchangeRedis khi có ConnectionStrings:Redis):

1. **Build BE:** Tắt process BCDT.Api (nếu đang chạy), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → **Pass**.
2. **Khi không cấu hình Redis (ConnectionStrings:Redis trống hoặc thiếu):** Ứng dụng dùng MemoryDistributedCache; API list (vd. GET /api/v1/reporting-frequencies) 2 lần liên tiếp và invalidate sau CUD hoạt động như Perf-1 (cache hit, invalidate đúng).
3. **Khi cấu hình Redis (ConnectionStrings:Redis có giá trị, vd. localhost:6379):** Ứng dụng dùng Redis; cache được chia sẻ giữa nhiều instance API. Kiểm tra tương tự: API list 2 lần (lần 2 có thể nhanh hơn hoặc từ cache); sau CUD entity tương ứng, response trả dữ liệu mới. **Chuỗi kết nối** hỗ trợ Single, Sentinel (serviceName=...) và Cluster (nhiều host:port); xem mục "Redis – Connection string (Single, Sentinel, Cluster)" trong tài liệu này.
4. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.17. Kiểm tra cho AI – Perf-17 (Read replica)

Sau khi cấu hình optional read replica (ConnectionStrings:ReadReplica và AppReadOnlyDbContext):

1. **Build BE:** Tắt process BCDT.Api (nếu đang chạy), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → **Pass**.
2. **Khi không cấu hình ReadReplica:** Ứng dụng dùng cùng connection (primary) cho AppReadOnlyDbContext; Dashboard (GET /dashboard/admin/stats, GET /dashboard/user/tasks) hoạt động bình thường.
3. **Khi cấu hình ReadReplica (connection string secondary):** DashboardService dùng AppReadOnlyDbContext → truy vấn chỉ đọc đi tới replica; ghi (submission, workflow, …) vẫn qua AppDbContext (primary). Kiểm tra: gọi GET /dashboard/admin/stats (JWT) → 200 OK; khi hạ tầng có replica, có thể xác nhận connection đọc tới replica (vd. theo log hoặc SQL Profiler).
4. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.18. Kiểm tra cho AI – Perf-18 (Partition/archive)

Sau khi triển khai script mẫu và tài liệu archive (DE_XUAT 3.2.3, PERF11):

1. **Build BE:** (Không bắt buộc nếu không sửa code.) Tắt process BCDT.Api (nếu đang chạy), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → **Pass**.
2. **Script mẫu:** File `docs/script_core/sql/v2/28.perf18_archive_sample.sql` tồn tại; tạo bảng *_Archive (ReportSubmission, ReportPresentation, ReportDataRow, ReportSummary, ReportDataAudit) và stored procedure `sp_BCDT_ArchiveSubmissions_Batch` (@RetentionYears, @BatchSize). Script đánh dấu mẫu – không chạy trực tiếp production.
3. **Tài liệu:** PERF11 có mục "Triển khai Perf-18 – Archive" (bước chạy script, gọi proc, Hangfire job); DE_XUAT 3.2.3 và config ArchivePolicy (đã có từ Perf-11) đủ để Ops triển khai khi cần.
4. **Báo Pass/Fail từng bước** trước khi báo xong task.

### 5.19. Kiểm tra cho AI – Perf-19 (Load balancer)

Sau khi bổ sung tài liệu/hướng dẫn Triển khai Perf-19 (DE_XUAT 3.1.2 và "Triển khai Perf-19 – Load balancer"):

1. **Tài liệu đủ cho Ops:** DE_XUAT có mục "Triển khai Perf-19 – Load balancer" với: mục đích (nhiều instance sau LB); health check GET /health; JWT stateless → sticky không bắt buộc; ví dụ nginx upstream; lưu ý Hangfire (một instance server); Redis khi scale &gt; 1; bước kiểm tra.
2. **Báo Pass/Fail** trước khi báo xong task. *(Task Perf-19 chỉ là tài liệu Ops; không cần build code.)*

---

## 6. Tham chiếu

- [W16_PERFORMANCE_SECURITY.md](de_xuat_trien_khai/W16_PERFORMANCE_SECURITY.md) – Baseline, batch DataSource, OWASP, index/cache đề xuất.
- [PERF11_PARTITION_REPLICA_ARCHIVE.md](de_xuat_trien_khai/PERF11_PARTITION_REPLICA_ARCHIVE.md) – Partition-ready, Read replica–ready, Archive policy (Perf-11).
- [04.GIAI_PHAP_KY_THUAT.md](script_core/04.GIAI_PHAP_KY_THUAT.md) – Hybrid storage, RLS, SaveOrchestrator.
- [REVIEW_KIEN_TRUC_CODEBASE.md](REVIEW_KIEN_TRUC_CODEBASE.md) – Kiến trúc hiện tại, đề xuất cache/CQRS.
- [02.KIEN_TRUC_TONG_QUAN.md](script_core/02.KIEN_TRUC_TONG_QUAN.md) – Stack, URL, Hangfire, SignalR.

**Lưu ý triển khai khối chính phủ:** Toàn bộ đề xuất trong tài liệu này ưu tiên hạ tầng nội bộ; **không sử dụng CDN công cộng** (mục 0.6, 3.4). Cache (Redis), queue (Hangfire), static và reverse proxy triển khai trong mạng chính phủ; tuân thủ quy định bảo mật và đặt máy chủ trong nước khi có yêu cầu.
