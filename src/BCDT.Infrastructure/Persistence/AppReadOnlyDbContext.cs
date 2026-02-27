using BCDT.Domain.Entities.Authentication;
using BCDT.Domain.Entities.Authorization;
using BCDT.Domain.Entities.Data;
using BCDT.Domain.Entities.Form;
using BCDT.Domain.Entities.Notification;
using BCDT.Domain.Entities.Organization;
using BCDT.Domain.Entities.ReferenceData;
using BCDT.Domain.Entities.ReportingPeriod;
using BCDT.Domain.Entities.Workflow;
using BCDT.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Persistence;

public class AppReadOnlyDbContext : DbContext
{
    public AppReadOnlyDbContext(DbContextOptions<AppReadOnlyDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<Permission> Permissions => Set<Permission>();
    public DbSet<RolePermission> RolePermissions => Set<RolePermission>();
    public DbSet<Menu> Menus => Set<Menu>();
    public DbSet<RoleMenu> RoleMenus => Set<RoleMenu>();
    public DbSet<OrganizationType> OrganizationTypes => Set<OrganizationType>();
    public DbSet<Organization> Organizations => Set<Organization>();
    public DbSet<UserOrganization> UserOrganizations => Set<UserOrganization>();
    public DbSet<FormDefinition> FormDefinitions => Set<FormDefinition>();
    public DbSet<FormVersion> FormVersions => Set<FormVersion>();
    public DbSet<FormSheet> FormSheets => Set<FormSheet>();
    public DbSet<FormColumn> FormColumns => Set<FormColumn>();
    public DbSet<FormRow> FormRows => Set<FormRow>();
    public DbSet<FormDataBinding> FormDataBindings => Set<FormDataBinding>();
    public DbSet<FormColumnMapping> FormColumnMappings => Set<FormColumnMapping>();
    public DbSet<IndicatorCatalog> IndicatorCatalogs => Set<IndicatorCatalog>();
    public DbSet<Indicator> Indicators => Set<Indicator>();
    public DbSet<FormDynamicRegion> FormDynamicRegions => Set<FormDynamicRegion>();
    public DbSet<DataSource> DataSources => Set<DataSource>();
    public DbSet<FilterDefinition> FilterDefinitions => Set<FilterDefinition>();
    public DbSet<FilterCondition> FilterConditions => Set<FilterCondition>();
    public DbSet<FormPlaceholderOccurrence> FormPlaceholderOccurrences => Set<FormPlaceholderOccurrence>();
    public DbSet<FormDynamicColumnRegion> FormDynamicColumnRegions => Set<FormDynamicColumnRegion>();
    public DbSet<FormPlaceholderColumnOccurrence> FormPlaceholderColumnOccurrences => Set<FormPlaceholderColumnOccurrence>();
    public DbSet<ReportDynamicIndicator> ReportDynamicIndicators => Set<ReportDynamicIndicator>();
    public DbSet<ReportingFrequency> ReportingFrequencies => Set<ReportingFrequency>();
    public DbSet<ReportingPeriod> ReportingPeriods => Set<ReportingPeriod>();
    public DbSet<ReportSubmission> ReportSubmissions => Set<ReportSubmission>();
    public DbSet<ReportPresentation> ReportPresentations => Set<ReportPresentation>();
    public DbSet<ReportDataRow> ReportDataRows => Set<ReportDataRow>();
    public DbSet<ReportSummary> ReportSummaries => Set<ReportSummary>();
    public DbSet<ReportDataAudit> ReportDataAudits => Set<ReportDataAudit>();
    public DbSet<WorkflowDefinition> WorkflowDefinitions => Set<WorkflowDefinition>();
    public DbSet<WorkflowStep> WorkflowSteps => Set<WorkflowStep>();
    public DbSet<FormWorkflowConfig> FormWorkflowConfigs => Set<FormWorkflowConfig>();
    public DbSet<WorkflowInstance> WorkflowInstances => Set<WorkflowInstance>();
    public DbSet<WorkflowApproval> WorkflowApprovals => Set<WorkflowApproval>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<SystemConfig> SystemConfigs => Set<SystemConfig>();
    public DbSet<ReferenceEntityType> ReferenceEntityTypes => Set<ReferenceEntityType>();
    public DbSet<ReferenceEntity> ReferenceEntities => Set<ReferenceEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(e =>
        {
            e.ToTable("BCDT_User");
            e.HasKey(x => x.Id);
            e.Property(x => x.Username).HasMaxLength(50);
            e.Property(x => x.PasswordHash).HasMaxLength(500);
            e.Property(x => x.Email).HasMaxLength(100);
            e.Property(x => x.FullName).HasMaxLength(200);
            e.Property(x => x.AuthProvider).HasMaxLength(50);
        });

        modelBuilder.Entity<RefreshToken>(e =>
        {
            e.ToTable("BCDT_RefreshToken");
            e.HasKey(x => x.Id);
            e.Property(x => x.Token).HasMaxLength(500);
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
        });

        modelBuilder.Entity<Role>(e =>
        {
            e.ToTable("BCDT_Role");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(50);
            e.Property(x => x.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<UserRole>(e =>
        {
            e.ToTable("BCDT_UserRole");
            e.HasKey(x => x.Id);
            e.HasOne<User>().WithMany().HasForeignKey(x => x.UserId);
            e.HasOne<Role>().WithMany().HasForeignKey(x => x.RoleId);
            e.HasOne<Organization>().WithMany().HasForeignKey(x => x.OrganizationId).IsRequired(false);
        });

        modelBuilder.Entity<Permission>(e =>
        {
            e.ToTable("BCDT_Permission");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(100);
            e.Property(x => x.Name).HasMaxLength(200);
            e.Property(x => x.Module).HasMaxLength(50);
            e.Property(x => x.Action).HasMaxLength(50);
            e.Property(x => x.Description).HasMaxLength(500);
            e.HasIndex(x => x.Code).IsUnique();
        });

        modelBuilder.Entity<RolePermission>(e =>
        {
            e.ToTable("BCDT_RolePermission");
            e.HasKey(x => x.Id);
            e.HasOne(x => x.Role).WithMany().HasForeignKey(x => x.RoleId);
            e.HasOne(x => x.Permission).WithMany().HasForeignKey(x => x.PermissionId);
            e.HasIndex(x => new { x.RoleId, x.PermissionId }).IsUnique();
        });

        modelBuilder.Entity<Menu>(e =>
        {
            e.ToTable("BCDT_Menu");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(50);
            e.Property(x => x.Name).HasMaxLength(100);
            e.Property(x => x.Url).HasMaxLength(200);
            e.Property(x => x.Icon).HasMaxLength(50);
            e.Property(x => x.RequiredPermission).HasMaxLength(100);
            e.HasOne(x => x.Parent).WithMany(x => x.Children).HasForeignKey(x => x.ParentId).IsRequired(false);
            e.HasIndex(x => x.Code).IsUnique();
        });

        modelBuilder.Entity<RoleMenu>(e =>
        {
            e.ToTable("BCDT_RoleMenu");
            e.HasKey(x => x.Id);
            e.HasOne(x => x.Role).WithMany().HasForeignKey(x => x.RoleId);
            e.HasOne(x => x.Menu).WithMany().HasForeignKey(x => x.MenuId);
            e.HasIndex(x => new { x.RoleId, x.MenuId }).IsUnique();
        });

        modelBuilder.Entity<UserOrganization>(e =>
        {
            e.ToTable("BCDT_UserOrganization");
            e.HasKey(x => x.Id);
            e.HasOne<User>().WithMany().HasForeignKey(x => x.UserId);
            e.HasOne<Organization>().WithMany().HasForeignKey(x => x.OrganizationId);
        });

        modelBuilder.Entity<OrganizationType>(e =>
        {
            e.ToTable("BCDT_OrganizationType");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(20);
            e.Property(x => x.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<Organization>(e =>
        {
            e.ToTable("BCDT_Organization");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(50);
            e.Property(x => x.Name).HasMaxLength(200);
            e.Property(x => x.ShortName).HasMaxLength(100);
            e.Property(x => x.TreePath).HasMaxLength(500);
            e.Property(x => x.Address).HasMaxLength(500);
            e.Property(x => x.Phone).HasMaxLength(20);
            e.Property(x => x.Email).HasMaxLength(100);
            e.Property(x => x.TaxCode).HasMaxLength(20);
            e.HasOne<OrganizationType>().WithMany().HasForeignKey(x => x.OrganizationTypeId);
            e.HasOne<Organization>().WithMany().HasForeignKey(x => x.ParentId).IsRequired(false);
        });

        modelBuilder.Entity<ReportingFrequency>(e =>
        {
            e.ToTable("BCDT_ReportingFrequency");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(20);
            e.Property(x => x.Name).HasMaxLength(100);
            e.Property(x => x.NameEn).HasMaxLength(50);
            e.Property(x => x.CronExpression).HasMaxLength(50);
            e.Property(x => x.Description).HasMaxLength(500);
        });

        modelBuilder.Entity<ReportingPeriod>(e =>
        {
            e.ToTable("BCDT_ReportingPeriod");
            e.HasKey(x => x.Id);
            e.Property(x => x.PeriodCode).HasMaxLength(20);
            e.Property(x => x.PeriodName).HasMaxLength(100);
            e.Property(x => x.Status).HasMaxLength(20);
            e.HasOne(x => x.ReportingFrequency).WithMany().HasForeignKey(x => x.ReportingFrequencyId).IsRequired();
            e.HasIndex(x => new { x.ReportingFrequencyId, x.PeriodCode }).IsUnique();
        });

        modelBuilder.Entity<FormDefinition>(e =>
        {
            e.ToTable("BCDT_FormDefinition");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(50);
            e.Property(x => x.Name).HasMaxLength(200);
            e.Property(x => x.Description).HasMaxLength(1000);
            e.Property(x => x.FormType).HasMaxLength(20);
            e.Property(x => x.TemplateFileName).HasMaxLength(255);
            e.Property(x => x.Status).HasMaxLength(20);
            e.HasOne<ReportingFrequency>().WithMany().HasForeignKey(x => x.ReportingFrequencyId).IsRequired(false);
        });

        modelBuilder.Entity<FormVersion>(e =>
        {
            e.ToTable("BCDT_FormVersion");
            e.HasKey(x => x.Id);
            e.Property(x => x.VersionName).HasMaxLength(100);
            e.Property(x => x.ChangeDescription).HasMaxLength(1000);
            e.Property(x => x.TemplateFileName).HasMaxLength(255);
            e.HasOne<FormDefinition>().WithMany().HasForeignKey(x => x.FormDefinitionId);
        });

        modelBuilder.Entity<FormSheet>(e =>
        {
            e.ToTable("BCDT_FormSheet");
            e.HasKey(x => x.Id);
            e.Property(x => x.SheetName).HasMaxLength(100);
            e.Property(x => x.DisplayName).HasMaxLength(200);
            e.Property(x => x.Description).HasMaxLength(500);
            e.HasOne<FormDefinition>().WithMany().HasForeignKey(x => x.FormDefinitionId);
        });

        modelBuilder.Entity<FormColumn>(e =>
        {
            e.ToTable("BCDT_FormColumn");
            e.HasKey(x => x.Id);
            e.Property(x => x.ColumnCode).HasMaxLength(50);
            e.Property(x => x.ColumnName).HasMaxLength(200);
            e.Property(x => x.ColumnGroupName).HasMaxLength(200);
            e.Property(x => x.ColumnGroupLevel2).HasMaxLength(200);
            e.Property(x => x.ColumnGroupLevel3).HasMaxLength(200);
            e.Property(x => x.ColumnGroupLevel4).HasMaxLength(200);
            e.Property(x => x.ExcelColumn).HasMaxLength(10);
            e.Property(x => x.DataType).HasMaxLength(20);
            e.Property(x => x.DefaultValue).HasMaxLength(500);
            e.Property(x => x.Formula).HasMaxLength(1000);
            e.Property(x => x.ValidationRule).HasMaxLength(500);
            e.Property(x => x.ValidationMessage).HasMaxLength(500);
            e.Property(x => x.Format).HasMaxLength(100);
            e.HasOne<FormSheet>().WithMany().HasForeignKey(x => x.FormSheetId);
            e.HasOne<FormColumn>().WithMany().HasForeignKey(x => x.ParentId).IsRequired(false);
            e.HasOne<Indicator>().WithMany().HasForeignKey(x => x.IndicatorId).IsRequired(true);
        });

        modelBuilder.Entity<FormRow>(e =>
        {
            e.ToTable("BCDT_FormRow");
            e.HasKey(x => x.Id);
            e.Property(x => x.RowCode).HasMaxLength(50);
            e.Property(x => x.RowName).HasMaxLength(200);
            e.Property(x => x.RowType).HasMaxLength(20);
            e.HasOne<FormSheet>().WithMany().HasForeignKey(x => x.FormSheetId);
            e.HasOne<FormRow>().WithMany().HasForeignKey(x => x.ParentRowId).IsRequired(false);
            e.HasOne<FormDynamicRegion>().WithMany().HasForeignKey(x => x.FormDynamicRegionId).IsRequired(false);
        });

        modelBuilder.Entity<IndicatorCatalog>(e =>
        {
            e.ToTable("BCDT_IndicatorCatalog");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(50);
            e.Property(x => x.Name).HasMaxLength(200);
            e.Property(x => x.Description).HasMaxLength(500);
            e.Property(x => x.Scope).HasMaxLength(20);
        });

        modelBuilder.Entity<Indicator>(e =>
        {
            e.ToTable("BCDT_Indicator");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(50);
            e.Property(x => x.Name).HasMaxLength(200);
            e.Property(x => x.Description).HasMaxLength(500);
            e.Property(x => x.DataType).HasMaxLength(20);
            e.Property(x => x.Unit).HasMaxLength(50);
            e.Property(x => x.FormulaTemplate).HasMaxLength(1000);
            e.Property(x => x.ValidationRule).HasMaxLength(500);
            e.Property(x => x.DefaultValue).HasMaxLength(500);
            e.HasOne<IndicatorCatalog>().WithMany().HasForeignKey(x => x.IndicatorCatalogId).IsRequired(false);
            e.HasOne<Indicator>().WithMany().HasForeignKey(x => x.ParentId).IsRequired(false);
        });

        modelBuilder.Entity<FormDynamicRegion>(e =>
        {
            e.ToTable("BCDT_FormDynamicRegion");
            e.HasKey(x => x.Id);
            e.Property(x => x.ExcelColName).HasMaxLength(10);
            e.Property(x => x.ExcelColValue).HasMaxLength(10);
            e.HasOne<FormSheet>().WithMany().HasForeignKey(x => x.FormSheetId);
            e.HasOne<IndicatorCatalog>().WithMany().HasForeignKey(x => x.IndicatorCatalogId).IsRequired(false);
        });

        modelBuilder.Entity<DataSource>(e =>
        {
            e.ToTable("BCDT_DataSource");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(50);
            e.Property(x => x.Name).HasMaxLength(200);
            e.Property(x => x.SourceType).HasMaxLength(20);
            e.Property(x => x.SourceRef).HasMaxLength(500);
            e.Property(x => x.DisplayColumn).HasMaxLength(100);
            e.Property(x => x.ValueColumn).HasMaxLength(100);
            e.HasOne<IndicatorCatalog>().WithMany().HasForeignKey(x => x.IndicatorCatalogId).IsRequired(false);
        });

        modelBuilder.Entity<FilterDefinition>(e =>
        {
            e.ToTable("BCDT_FilterDefinition");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(50);
            e.Property(x => x.Name).HasMaxLength(200);
            e.Property(x => x.LogicalOperator).HasMaxLength(3);
            e.HasOne<DataSource>().WithMany().HasForeignKey(x => x.DataSourceId).IsRequired(false);
        });

        modelBuilder.Entity<FilterCondition>(e =>
        {
            e.ToTable("BCDT_FilterCondition");
            e.HasKey(x => x.Id);
            e.Property(x => x.Field).HasMaxLength(100);
            e.Property(x => x.Operator).HasMaxLength(20);
            e.Property(x => x.ValueType).HasMaxLength(20);
            e.Property(x => x.Value).HasMaxLength(500);
            e.Property(x => x.Value2).HasMaxLength(500);
            e.Property(x => x.DataType).HasMaxLength(20);
            e.HasOne<FilterDefinition>().WithMany().HasForeignKey(x => x.FilterDefinitionId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<FormPlaceholderOccurrence>(e =>
        {
            e.ToTable("BCDT_FormPlaceholderOccurrence");
            e.HasKey(x => x.Id);
            e.HasOne<FormSheet>().WithMany().HasForeignKey(x => x.FormSheetId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne<FormDynamicRegion>().WithMany().HasForeignKey(x => x.FormDynamicRegionId);
            e.HasOne<FilterDefinition>().WithMany().HasForeignKey(x => x.FilterDefinitionId).IsRequired(false);
            e.HasOne<DataSource>().WithMany().HasForeignKey(x => x.DataSourceId).IsRequired(false);
        });

        modelBuilder.Entity<FormDynamicColumnRegion>(e =>
        {
            e.ToTable("BCDT_FormDynamicColumnRegion");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(50);
            e.Property(x => x.Name).HasMaxLength(200);
            e.Property(x => x.ColumnSourceType).HasMaxLength(30);
            e.Property(x => x.ColumnSourceRef).HasMaxLength(500);
            e.Property(x => x.LabelColumn).HasMaxLength(100);
            e.HasOne<FormSheet>().WithMany().HasForeignKey(x => x.FormSheetId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<FormPlaceholderColumnOccurrence>(e =>
        {
            e.ToTable("BCDT_FormPlaceholderColumnOccurrence");
            e.HasKey(x => x.Id);
            e.HasOne<FormSheet>().WithMany().HasForeignKey(x => x.FormSheetId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne<FormDynamicColumnRegion>().WithMany().HasForeignKey(x => x.FormDynamicColumnRegionId);
            e.HasOne<FilterDefinition>().WithMany().HasForeignKey(x => x.FilterDefinitionId).IsRequired(false);
        });

        modelBuilder.Entity<ReportDynamicIndicator>(e =>
        {
            e.ToTable("BCDT_ReportDynamicIndicator");
            e.HasKey(x => x.Id);
            e.Property(x => x.IndicatorName).HasMaxLength(500);
            e.Property(x => x.IndicatorValue).HasMaxLength(-1);
            e.Property(x => x.DataType).HasMaxLength(20);
            e.HasOne<ReportSubmission>().WithMany().HasForeignKey(x => x.SubmissionId);
            e.HasOne<FormDynamicRegion>().WithMany().HasForeignKey(x => x.FormDynamicRegionId);
            e.HasOne<Indicator>().WithMany().HasForeignKey(x => x.IndicatorId).IsRequired(false);
        });

        modelBuilder.Entity<FormDataBinding>(e =>
        {
            e.ToTable("BCDT_FormDataBinding");
            e.HasKey(x => x.Id);
            e.Property(x => x.BindingType).HasMaxLength(30);
            e.Property(x => x.SourceTable).HasMaxLength(100);
            e.Property(x => x.SourceColumn).HasMaxLength(100);
            e.Property(x => x.SourceCondition).HasMaxLength(500);
            e.Property(x => x.ApiEndpoint).HasMaxLength(500);
            e.Property(x => x.ApiMethod).HasMaxLength(10);
            e.Property(x => x.ApiResponsePath).HasMaxLength(200);
            e.Property(x => x.Formula).HasMaxLength(1000);
            e.Property(x => x.ReferenceDisplayColumn).HasMaxLength(100);
            e.Property(x => x.DefaultValue).HasMaxLength(500);
            e.Property(x => x.TransformExpression).HasMaxLength(500);
            e.HasOne<FormColumn>().WithMany().HasForeignKey(x => x.FormColumnId);
        });

        modelBuilder.Entity<FormColumnMapping>(e =>
        {
            e.ToTable("BCDT_FormColumnMapping");
            e.HasKey(x => x.Id);
            e.Property(x => x.TargetColumnName).HasMaxLength(50);
            e.Property(x => x.AggregateFunction).HasMaxLength(20);
            e.HasOne<FormColumn>().WithMany().HasForeignKey(x => x.FormColumnId);
        });

        modelBuilder.Entity<ReportSubmission>(e =>
        {
            e.ToTable("BCDT_ReportSubmission");
            e.HasKey(x => x.Id);
            e.Property(x => x.Status).HasMaxLength(20);
            e.HasOne<FormDefinition>().WithMany().HasForeignKey(x => x.FormDefinitionId);
            e.HasOne<FormVersion>().WithMany().HasForeignKey(x => x.FormVersionId);
            e.HasOne<Organization>().WithMany().HasForeignKey(x => x.OrganizationId);
            e.HasOne<ReportingPeriod>().WithMany().HasForeignKey(x => x.ReportingPeriodId);
            e.HasIndex(x => new { x.FormDefinitionId, x.OrganizationId, x.ReportingPeriodId }).IsUnique();
        });

        modelBuilder.Entity<ReportPresentation>(e =>
        {
            e.ToTable("BCDT_ReportPresentation");
            e.HasKey(x => x.Id);
            e.Property(x => x.WorkbookHash).HasMaxLength(64);
            e.HasOne<ReportSubmission>().WithMany().HasForeignKey(x => x.SubmissionId);
            e.HasIndex(x => x.SubmissionId).IsUnique();
        });

        modelBuilder.Entity<ReportDataRow>(e =>
        {
            e.ToTable("BCDT_ReportDataRow");
            e.HasKey(x => x.Id);
            e.Property(x => x.TextValue1).HasMaxLength(500);
            e.Property(x => x.TextValue2).HasMaxLength(500);
            e.Property(x => x.TextValue3).HasMaxLength(500);
            e.HasOne<ReportSubmission>().WithMany().HasForeignKey(x => x.SubmissionId);
            e.HasIndex(x => new { x.SubmissionId, x.SheetIndex, x.RowIndex }).IsUnique();
        });

        modelBuilder.Entity<ReportSummary>(e =>
        {
            e.ToTable("BCDT_ReportSummary");
            e.HasKey(x => x.Id);
            e.HasOne<ReportSubmission>().WithMany().HasForeignKey(x => x.SubmissionId);
            e.HasIndex(x => new { x.SubmissionId, x.SheetIndex }).IsUnique();
        });

        modelBuilder.Entity<ReportDataAudit>(e =>
        {
            e.ToTable("BCDT_ReportDataAudit");
            e.HasKey(x => x.Id);
            e.Property(x => x.CellAddress).HasMaxLength(20);
            e.Property(x => x.ColumnName).HasMaxLength(50);
            e.Property(x => x.ChangeType).HasMaxLength(20);
            e.Property(x => x.IpAddress).HasMaxLength(50);
            e.Property(x => x.UserAgent).HasMaxLength(500);
            e.HasOne<ReportSubmission>().WithMany().HasForeignKey(x => x.SubmissionId);
        });

        modelBuilder.Entity<WorkflowDefinition>(e =>
        {
            e.ToTable("BCDT_WorkflowDefinition");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(50);
            e.Property(x => x.Name).HasMaxLength(200);
            e.Property(x => x.Description).HasMaxLength(1000);
        });

        modelBuilder.Entity<WorkflowStep>(e =>
        {
            e.ToTable("BCDT_WorkflowStep");
            e.HasKey(x => x.Id);
            e.Property(x => x.StepName).HasMaxLength(100);
            e.Property(x => x.StepDescription).HasMaxLength(500);
            e.HasOne<WorkflowDefinition>().WithMany().HasForeignKey(x => x.WorkflowDefinitionId);
            e.HasOne<Role>().WithMany().HasForeignKey(x => x.ApproverRoleId).IsRequired(false);
            e.HasOne<User>().WithMany().HasForeignKey(x => x.ApproverUserId).IsRequired(false);
            e.HasIndex(x => new { x.WorkflowDefinitionId, x.StepOrder }).IsUnique();
        });

        modelBuilder.Entity<FormWorkflowConfig>(e =>
        {
            e.ToTable("BCDT_FormWorkflowConfig");
            e.HasKey(x => x.Id);
            e.HasOne<FormDefinition>().WithMany().HasForeignKey(x => x.FormDefinitionId);
            e.HasOne<WorkflowDefinition>().WithMany().HasForeignKey(x => x.WorkflowDefinitionId);
            e.HasOne<OrganizationType>().WithMany().HasForeignKey(x => x.OrganizationTypeId).IsRequired(false);
        });

        modelBuilder.Entity<WorkflowInstance>(e =>
        {
            e.ToTable("BCDT_WorkflowInstance");
            e.HasKey(x => x.Id);
            e.Property(x => x.Status).HasMaxLength(20);
            e.HasOne<ReportSubmission>().WithMany().HasForeignKey(x => x.SubmissionId);
            e.HasOne<WorkflowDefinition>().WithMany().HasForeignKey(x => x.WorkflowDefinitionId);
        });

        modelBuilder.Entity<WorkflowApproval>(e =>
        {
            e.ToTable("BCDT_WorkflowApproval");
            e.HasKey(x => x.Id);
            e.Property(x => x.Action).HasMaxLength(20);
            e.Property(x => x.Comments).HasMaxLength(2000);
            e.Property(x => x.IpAddress).HasMaxLength(50);
            e.Property(x => x.SignatureId).HasMaxLength(32);
            e.HasOne<WorkflowInstance>().WithMany().HasForeignKey(x => x.WorkflowInstanceId);
            e.HasOne<User>().WithMany().HasForeignKey(x => x.ApproverId);
        });

        modelBuilder.Entity<Notification>(e =>
        {
            e.ToTable("BCDT_Notification");
            e.HasKey(x => x.Id);
            e.Property(x => x.Type).HasMaxLength(50);
            e.Property(x => x.Title).HasMaxLength(200);
            e.Property(x => x.Message).HasMaxLength(2000);
            e.Property(x => x.Priority).HasMaxLength(20);
            e.Property(x => x.EntityType).HasMaxLength(50);
            e.Property(x => x.EntityId).HasMaxLength(50);
            e.Property(x => x.ActionUrl).HasMaxLength(500);
            e.Property(x => x.Channels).HasMaxLength(100);
            e.HasOne<User>().WithMany().HasForeignKey(x => x.UserId);
        });

        modelBuilder.Entity<SystemConfig>(e =>
        {
            e.ToTable("BCDT_SystemConfig");
            e.HasKey(x => x.Id);
            e.Property(x => x.ConfigKey).HasMaxLength(100);
            e.Property(x => x.ConfigValue).HasMaxLength(-1);
            e.Property(x => x.DataType).HasMaxLength(20);
            e.Property(x => x.Description).HasMaxLength(500);
            e.HasIndex(x => x.ConfigKey).IsUnique();
        });

        modelBuilder.Entity<ReferenceEntityType>(e =>
        {
            e.ToTable("BCDT_ReferenceEntityType");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(50);
            e.Property(x => x.Name).HasMaxLength(200);
            e.Property(x => x.Description).HasMaxLength(1000);
            e.Property(x => x.TableName).HasMaxLength(100);
            e.Property(x => x.ApiEndpoint).HasMaxLength(500);
            e.Property(x => x.DisplayTemplate).HasMaxLength(500);
            e.Property(x => x.SearchColumns).HasMaxLength(500);
            e.Property(x => x.OrderByColumn).HasMaxLength(100);
        });

        modelBuilder.Entity<ReferenceEntity>(e =>
        {
            e.ToTable("BCDT_ReferenceEntity");
            e.HasKey(x => x.Id);
            e.Property(x => x.Code).HasMaxLength(50);
            e.Property(x => x.Name).HasMaxLength(500);
            e.HasOne(x => x.EntityType).WithMany().HasForeignKey(x => x.EntityTypeId);
            e.HasOne(x => x.Parent).WithMany(x => x.Children).HasForeignKey(x => x.ParentId).OnDelete(DeleteBehavior.Restrict);
        });
    }
}
