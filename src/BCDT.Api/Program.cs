using System.Text;
using System.Text.Json;
using System.Threading.RateLimiting;
using BCDT.Api.Common;
using BCDT.Api.Middleware;
using BCDT.Api.Services;
using BCDT.Application.Validators.Auth;
using BCDT.Application.Services;
using BCDT.Application.Services.Data;
using BCDT.Application.Services.Form;
using BCDT.Application.Services.Organization;
using BCDT.Application.Services.User;
using BCDT.Application.Services.ReportingPeriod;
using BCDT.Application.Services.Dashboard;
using BCDT.Application.Services.Notification;
using BCDT.Application.Services.Workflow;
using BCDT.Application.Services.Role;
using BCDT.Application.Services.Permission;
using BCDT.Application.Services.Menu;
using BCDT.Application.Services.ReferenceEntity;
using BCDT.Application.Services.SystemConfig;
using BCDT.Infrastructure.Services.Menu;
using BCDT.Infrastructure.Services.ReferenceEntity;
using BCDT.Infrastructure.Services.SystemConfig;
using BCDT.Infrastructure.Persistence;
using BCDT.Application.Services.Cache;
using BCDT.Infrastructure.Services;
using BCDT.Infrastructure.Services.Cache;
using BCDT.Infrastructure.Services.Data;
using BCDT.Infrastructure.Services.Dashboard;
using BCDT.Infrastructure.Services.Notification;
using BCDT.Infrastructure.Services.ReportingPeriod;
using BCDT.Infrastructure.Services.Workflow;
using BCDT.Infrastructure.Services.Role;
using BCDT.Infrastructure.Services.Permission;
using BCDT.Application.Common.Authorization;
using BCDT.Infrastructure.Authorization;
using BCDT.Application.Services.Authorization;
using BCDT.Infrastructure.Services.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Caching.StackExchangeRedis;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using FluentValidation;
using FluentValidation.AspNetCore;
using Hangfire;
using Hangfire.SqlServer;
using BCDT.Infrastructure.Jobs;

// One-off: sinh BCrypt hash cho mật khẩu (dotnet run -- hash-password "Admin@123")
if (args.Length >= 2 && args[0] == "hash-password")
{
    var password = args[1];
    var hash = BCrypt.Net.BCrypt.HashPassword(password);
    Console.WriteLine(hash);
    return;
}

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers(options =>
{
    // Tránh 406 khi trả file (Excel template): client không gửi formatter tương ứng.
    options.ReturnHttpNotAcceptable = false;
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(ConfigureSwagger);

// Prod-5 (R5): FluentValidation cho Request DTO – validators từ Application, auto-validation trong pipeline
builder.Services.AddValidatorsFromAssemblyContaining<LoginRequestValidator>();
builder.Services.AddFluentValidationAutoValidation();

// Prod-10 (R6): ICurrentUserService thay thế GetCurrentUserId/GetUserId trùng lặp trong controller
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUserService, CurrentUserService>();

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? new[] { "http://localhost:5173" })
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();
    });
});

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("ConnectionStrings:DefaultConnection is required.");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(connectionString));

// Perf-17: Read replica – khi có ConnectionStrings:ReadReplica thì query chỉ đọc (dashboard, …) dùng replica; không có thì dùng primary
var readReplicaConnection = builder.Configuration.GetConnectionString("ReadReplica");
var readConnection = !string.IsNullOrWhiteSpace(readReplicaConnection) ? readReplicaConnection : connectionString;
builder.Services.AddDbContext<AppReadOnlyDbContext>(options =>
    options.UseSqlServer(readConnection));

// Prod-6 (R12): Health Redis – khi có ConnectionStrings:Redis thì /health bao gồm check Redis (LB/ops)
var redisConnectionForHealth = builder.Configuration.GetConnectionString("Redis");
var healthBuilder = builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>("db", failureStatus: Microsoft.Extensions.Diagnostics.HealthChecks.HealthStatus.Unhealthy);
if (!string.IsNullOrWhiteSpace(redisConnectionForHealth))
    healthBuilder.AddRedis(redisConnectionForHealth, name: "redis", failureStatus: Microsoft.Extensions.Diagnostics.HealthChecks.HealthStatus.Unhealthy);

builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
    options.Providers.Add<BrotliCompressionProvider>();
    options.Providers.Add<GzipCompressionProvider>();
});

// Perf-16: Redis khi scale > 1 instance – nếu có ConnectionStrings:Redis thì dùng Redis, không thì Memory (đơn instance)
var redisConnection = builder.Configuration.GetConnectionString("Redis");
if (!string.IsNullOrWhiteSpace(redisConnection))
{
    builder.Services.AddStackExchangeRedisCache(options => options.Configuration = redisConnection);
}
else
{
    builder.Services.AddDistributedMemoryCache();
}
builder.Services.AddSingleton<ICacheService, DistributedCacheService>();

// Perf-13: Hangfire – background job cho tác vụ nặng (export/aggregate)
// Perf-19: Hangfire:ServerEnabled = false trên instance chỉ làm API → chỉ 1 instance chạy job (tránh trùng job)
builder.Services.AddHangfire(config => config
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UseSqlServerStorage(connectionString, new SqlServerStorageOptions
    {
        CommandBatchMaxTimeout = TimeSpan.FromMinutes(5),
        SlidingInvisibilityTimeout = TimeSpan.FromMinutes(5),
        QueuePollInterval = TimeSpan.Zero,
        UseRecommendedIsolationLevel = true,
        DisableGlobalLocks = true
    }));
var hangfireServerEnabled = builder.Configuration.GetValue<bool>("Hangfire:ServerEnabled", true);
if (hangfireServerEnabled)
    builder.Services.AddHangfireServer();

var jwtSection = builder.Configuration.GetSection(JwtOptions.SectionName);
builder.Services.Configure<JwtOptions>(jwtSection);
var jwtOptions = jwtSection.Get<JwtOptions>() ?? new JwtOptions();
var key = Encoding.UTF8.GetBytes(jwtOptions.SecretKey);

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateIssuer = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidateAudience = true,
            ValidAudience = jwtOptions.Audience,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };
        options.Events = new Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerEvents
        {
            OnTokenValidated = async ctx =>
            {
                var userIdClaim = ctx.Principal?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                var iatStr = ctx.Principal?.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Iat)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || string.IsNullOrEmpty(iatStr))
                    return;
                if (!int.TryParse(userIdClaim, out var userId))
                    return;
                if (!long.TryParse(iatStr, out var iatUnix))
                    return;
                var tokenIssuedAt = DateTimeOffset.FromUnixTimeSeconds(iatUnix).UtcDateTime;
                var db = ctx.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
                var user = await db.Users.AsNoTracking()
                    .Where(u => u.Id == userId)
                    .Select(u => new { u.LastLogoutAt })
                    .FirstOrDefaultAsync(ctx.HttpContext.RequestAborted);
                if (user?.LastLogoutAt is { } lastLogout && tokenIssuedAt < lastLogout)
                {
                    ctx.Fail("Token was revoked by logout.");
                }
            }
        };
    });
builder.Services.AddScoped<Microsoft.AspNetCore.Authorization.IAuthorizationHandler, PermissionAuthorizationHandler>();
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("FormStructureAdmin", policy =>
        policy.RequireRole("SYSTEM_ADMIN", "FORM_ADMIN"));
    options.AddPolicy("AdminManageUsers", policy =>
        policy.RequireRole("SYSTEM_ADMIN"));
    options.AddPolicy("AdminManageRoles", policy =>
        policy.RequireRole("SYSTEM_ADMIN"));
    options.AddPolicy("AdminManageOrg", policy =>
        policy.RequireRole("SYSTEM_ADMIN"));
    options.AddPolicy("Form.View", policy =>
        policy.Requirements.Add(new PermissionRequirement("Form.View")));
    options.AddPolicy("Form.Edit", policy =>
        policy.Requirements.Add(new PermissionRequirement("Form.Edit")));
    options.AddPolicy("Submission.Submit", policy =>
        policy.Requirements.Add(new PermissionRequirement("Submission.Submit")));
});

// Prod-13 (R7): Rate limiting theo IP / user để chống abuse
var permitLimit = builder.Configuration.GetValue("RateLimiting:PermitLimit", 200);
var windowSeconds = builder.Configuration.GetValue("RateLimiting:WindowSeconds", 60);
builder.Services.AddRateLimiter(options =>
{
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
    {
        var path = context.Request.Path.Value ?? "";
        if (path == "/health" || path == "/" ||
            path.StartsWith("/swagger", StringComparison.OrdinalIgnoreCase) ||
            path.StartsWith("/hangfire", StringComparison.OrdinalIgnoreCase))
            return RateLimitPartition.GetNoLimiter("excluded");
        var userId = context.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var key = !string.IsNullOrEmpty(userId) ? "u:" + userId : "ip:" + (context.Connection.RemoteIpAddress?.ToString() ?? "unknown");
        return RateLimitPartition.GetFixedWindowLimiter(key, _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = permitLimit,
            Window = TimeSpan.FromSeconds(windowSeconds)
        });
    });
    options.OnRejected = async (context, token) =>
    {
        context.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;
        context.HttpContext.Response.ContentType = "application/json";
        var response = new ApiErrorResponse("RATE_LIMIT_EXCEEDED", "Vượt quá giới hạn request, vui lòng thử lại sau.");
        var json = JsonSerializer.Serialize(new { success = false, errors = response.Errors },
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        await context.HttpContext.Response.WriteAsync(json, token);
    };
});

builder.Services.AddScoped<IOrganizationTypeService, OrganizationTypeService>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IOrganizationService, OrganizationService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IUserDelegationService, UserDelegationService>();
builder.Services.AddScoped<IFormDefinitionService, FormDefinitionService>();
builder.Services.AddScoped<IFormSheetService, FormSheetService>();
builder.Services.AddScoped<IFormColumnService, FormColumnService>();
builder.Services.AddScoped<IFormDataBindingService, FormDataBindingService>();
builder.Services.AddScoped<IFormColumnMappingService, FormColumnMappingService>();
builder.Services.AddScoped<IFormDynamicRegionService, FormDynamicRegionService>();
builder.Services.AddScoped<IIndicatorCatalogService, IndicatorCatalogService>();
builder.Services.AddScoped<IIndicatorService, IndicatorService>();
builder.Services.AddScoped<IDataSourceService, DataSourceService>();
builder.Services.AddScoped<IFilterDefinitionService, FilterDefinitionService>();
builder.Services.AddScoped<IDataSourceQueryService, DataSourceQueryService>();
builder.Services.AddScoped<IFormPlaceholderOccurrenceService, FormPlaceholderOccurrenceService>();
builder.Services.AddScoped<IFormDynamicColumnRegionService, FormDynamicColumnRegionService>();
builder.Services.AddScoped<IFormPlaceholderColumnOccurrenceService, FormPlaceholderColumnOccurrenceService>();
builder.Services.AddScoped<IFormRowService, FormRowService>();
builder.Services.AddScoped<IColumnLayoutService, ColumnLayoutService>();
builder.Services.AddScoped<IFormulaInjectionService, FormulaInjectionService>();
builder.Services.AddScoped<IFormRowFormulaScopeService, FormRowFormulaScopeService>();
builder.Services.AddScoped<IFormCellFormulaService, FormCellFormulaService>();
builder.Services.AddScoped<ISubmissionDynamicIndicatorService, SubmissionDynamicIndicatorService>();
builder.Services.AddScoped<IDataBindingResolver, DataBindingResolver>();
builder.Services.AddScoped<IFormTemplateService, FormTemplateService>();
builder.Services.AddScoped<IReportSubmissionService, ReportSubmissionService>();
builder.Services.AddScoped<IReportPresentationService, ReportPresentationService>();
builder.Services.AddScoped<ISubmissionExcelService, SubmissionExcelService>();
builder.Services.AddScoped<ISyncFromPresentationService, SyncFromPresentationService>();
builder.Services.AddScoped<IBuildWorkbookFromSubmissionService, BuildWorkbookFromSubmissionService>();
builder.Services.AddScoped<IWorkflowDefinitionService, WorkflowDefinitionService>();
builder.Services.AddScoped<IWorkflowStepService, WorkflowStepService>();
builder.Services.AddScoped<IFormWorkflowConfigService, FormWorkflowConfigService>();
builder.Services.AddScoped<IWorkflowExecutionService, WorkflowExecutionService>();
builder.Services.AddScoped<IReportingFrequencyService, ReportingFrequencyService>();
builder.Services.AddScoped<IReportingPeriodService, ReportingPeriodService>();
builder.Services.AddScoped<IAggregationService, AggregationService>();
builder.Services.AddScoped<IReportSummaryService, ReportSummaryService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<ISubmissionPdfService, SubmissionPdfService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IAuditService, AuditService>();
// Email: dùng SmtpEmailService khi SmtpHost được cấu hình, fallback MockEmailSender (log only)
if (!string.IsNullOrWhiteSpace(builder.Configuration["Email:SmtpHost"]))
    builder.Services.AddScoped<IEmailSender, SmtpEmailService>();
else
    builder.Services.AddScoped<IEmailSender, MockEmailSender>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<IPermissionService, PermissionService>();
builder.Services.AddScoped<IMenuService, MenuService>();
builder.Services.AddScoped<ISystemConfigService, SystemConfigService>();
builder.Services.AddScoped<IReferenceEntityTypeService, ReferenceEntityTypeService>();
builder.Services.AddScoped<IReferenceEntityService, ReferenceEntityService>();
builder.Services.AddScoped<BCDT.Infrastructure.Jobs.AggregateSubmissionJob>();
builder.Services.AddScoped<BCDT.Infrastructure.Jobs.AutoCreateReportingPeriodJob>();
builder.Services.AddScoped<BCDT.Infrastructure.Jobs.NotificationDispatchJob>();

var app = builder.Build();

// Prod-12 (R11): RequestId/TraceId đầu pipeline để mọi log có TraceId; response header X-Request-Id
app.UseMiddleware<RequestTraceMiddleware>();
app.UseMiddleware<BCDT.Api.Middleware.ExceptionMiddleware>();

app.UseResponseCompression();

if (app.Environment.IsDevelopment())
    app.UseSwagger().UseSwaggerUI(c => c.EnablePersistAuthorization());

app.UseHttpsRedirection();
app.UseCors();
app.UseAuthentication();
// Prod-13 (R7): Rate limiting sau Authentication để partition theo user khi đã đăng nhập
app.UseRateLimiter();
app.UseMiddleware<SessionContextMiddleware>();
app.UseAuthorization();
app.MapControllers();

// Dashboard chỉ map khi ServerEnabled (instance chạy job); instance khác vẫn enqueue được nhưng không có /hangfire
var hangfirePath = builder.Configuration["Hangfire:DashboardPath"] ?? "/hangfire";
if (hangfireServerEnabled)
{
    app.MapHangfireDashboard(hangfirePath);

    // CK-02: Recurring job tự động tạo kỳ báo cáo – chạy hàng ngày lúc 1:00 AM UTC
    var recurringJobs = app.Services.GetRequiredService<IRecurringJobManager>();
    recurringJobs.AddOrUpdate<AutoCreateReportingPeriodJob>(
        "auto-create-reporting-period",
        job => job.ExecuteAsync(CancellationToken.None),
        "0 1 * * *",    // daily at 01:00 UTC
        new RecurringJobOptions { TimeZone = TimeZoneInfo.Utc });
}

app.MapGet("/", () => Results.Redirect("/health"));
app.MapHealthChecks("/health");

app.Run();

static void ConfigureSwagger(SwaggerGenOptions options)
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "BCDT API", Version = "v1" });
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        In = ParameterLocation.Header,
        Description = "JWT Bearer. Nhập token nhận từ /api/v1/auth/login."
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
}
