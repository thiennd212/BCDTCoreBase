---
name: bcdt-entity-crud
description: Generate full CRUD code for a new entity in BCDT project. Creates Controller, Service, Repository, DTOs, and Validator following project patterns. Use when user says "tạo entity", "tạo CRUD cho", "create entity", or wants to add a new domain entity with full stack code.
---

# BCDT Entity CRUD Generator

Generate complete CRUD stack for a new entity.

## Workflow

1. **Gather requirements**:
   - Entity name (PascalCase, singular)
   - Properties (name, type, required, validation)
   - Relationships (foreign keys)
   - Soft delete required? (default: yes)

2. **Generate files** in this order:

### Domain Entity
```csharp
// src/BCDT.Domain/Entities/{Entity}.cs
public class {Entity} : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    // Properties...
    
    // Navigation properties
    public virtual Organization? Organization { get; set; }
}
```

### DTOs
```csharp
// src/BCDT.Application/DTOs/{Entity}Dto.cs
public record {Entity}Dto(int Id, string Name, ...);

// src/BCDT.Application/DTOs/{Entity}Request.cs
public record Create{Entity}Request(string Name, ...);
public record Update{Entity}Request(string Name, ...);
```

### Validator
```csharp
// src/BCDT.Application/Validators/{Entity}Validator.cs
public class Create{Entity}Validator : AbstractValidator<Create{Entity}Request>
{
    public Create{Entity}Validator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(200);
    }
}
```

### Service Interface & Implementation
```csharp
// src/BCDT.Application/Services/I{Entity}Service.cs
public interface I{Entity}Service
{
    Task<Result<{Entity}Dto>> GetByIdAsync(int id);
    Task<Result<PagedList<{Entity}Dto>>> GetListAsync({Entity}Filter filter);
    Task<Result<{Entity}Dto>> CreateAsync(Create{Entity}Request request);
    Task<Result<{Entity}Dto>> UpdateAsync(int id, Update{Entity}Request request);
    Task<Result> DeleteAsync(int id);
}

// src/BCDT.Application/Services/{Entity}Service.cs
public class {Entity}Service : I{Entity}Service { ... }
```

### Repository (if needed)
```csharp
// src/BCDT.Infrastructure/Repositories/{Entity}Repository.cs
public class {Entity}Repository : BaseRepository<{Entity}>, I{Entity}Repository { }
```

### Controller
```csharp
// src/BCDT.Api/Controllers/{Entity}sController.cs
[ApiController]
[Route("api/v1/[controller]")]
[Authorize]
public class {Entity}sController : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedList<{Entity}Dto>>>> GetList([FromQuery] {Entity}Filter filter)
    
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<{Entity}Dto>>> Get(int id)
    
    [HttpPost]
    public async Task<ActionResult<ApiResponse<{Entity}Dto>>> Create(Create{Entity}Request request)
    
    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<{Entity}Dto>>> Update(int id, Update{Entity}Request request)
    
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
}
```

### SQL Script
```sql
-- sql/migrations/{timestamp}_{Entity}.sql
CREATE TABLE BCDT_{Entity} (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    -- columns...
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    CreatedBy INT NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy INT NULL,
    IsDeleted BIT NOT NULL DEFAULT 0
);
```

3. **Register DI**:
```csharp
// Add to DI registration
services.AddScoped<I{Entity}Service, {Entity}Service>();
```

## Verify / Build
- **Trước khi chạy `dotnet build`:** Kiểm tra và **hủy process BCDT.Api** nếu đang chạy để tránh lỗi file/DLL bị lock (PowerShell: `Get-Process -Name "BCDT.Api" -ErrorAction SilentlyContinue | Stop-Process -Force`). Sau đó mới build. Xem RUNBOOK mục 6.1.

## Checklist
- [ ] Entity with BaseEntity inheritance
- [ ] DTOs (Dto, CreateRequest, UpdateRequest)
- [ ] FluentValidation validators
- [ ] Service interface + implementation
- [ ] Controller with all CRUD endpoints
- [ ] SQL CREATE TABLE script
- [ ] DI registration
- [ ] DbContext DbSet added
- [ ] Trước build BE: đã hủy process BCDT.Api nếu đang chạy
