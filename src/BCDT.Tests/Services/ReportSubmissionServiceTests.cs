using BCDT.Application.DTOs.Data;
using BCDT.Application.Services.Data;
using BCDT.Domain.Entities.Data;
using BCDT.Domain.Entities.Form;
using BCDT.Domain.Entities.Organization;
using BCDT.Domain.Entities.ReportingPeriod;
using BCDT.Infrastructure.Persistence;
using BCDT.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace BCDT.Tests.Services;

public class ReportSubmissionServiceTests
{
    private static AppDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static async Task<(AppDbContext db, int formId, int versionId, int orgId, int periodId)> SeedForSubmissionAsync(AppDbContext db)
    {
        var orgType = new OrganizationType { Id = 1, Code = "OT1", Name = "Type1" };
        db.OrganizationTypes.Add(orgType);
        db.Organizations.Add(new Organization
        {
            Id = 1,
            Code = "O1",
            Name = "Org 1",
            OrganizationTypeId = 1,
            TreePath = "/1/",
            Level = 1,
            IsDeleted = false
        });
        db.ReportingFrequencies.Add(new ReportingFrequency
        {
            Id = 1,
            Code = "M",
            Name = "Monthly",
            CreatedAt = DateTime.UtcNow
        });
        db.ReportingPeriods.Add(new ReportingPeriod
        {
            Id = 1,
            ReportingFrequencyId = 1,
            PeriodCode = "2024-01",
            PeriodName = "T1/2024",
            StartDate = DateTime.UtcNow.AddDays(-30),
            EndDate = DateTime.UtcNow,
            Deadline = DateTime.UtcNow.AddDays(1),
            Status = "Open",
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 1
        });
        var form = new FormDefinition
        {
            Id = 1,
            Code = "F1",
            Name = "Form 1",
            FormType = "Input",
            IsDeleted = false,
            AllowLateSubmission = true,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 1
        };
        db.FormDefinitions.Add(form);
        await db.SaveChangesAsync();
        var version = new FormVersion
        {
            Id = 1,
            FormDefinitionId = 1,
            VersionNumber = 1,
            VersionName = "v1",
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 1
        };
        db.FormVersions.Add(version);
        await db.SaveChangesAsync();
        return (db, 1, 1, 1, 1);
    }

    [Fact]
    public async Task CreateAsync_Success_ReturnsDraftSubmission()
    {
        await using var db = CreateContext();
        await SeedForSubmissionAsync(db);
        var sut = new ReportSubmissionService(db);

        var request = new CreateReportSubmissionRequest
        {
            FormDefinitionId = 1,
            FormVersionId = 1,
            OrganizationId = 1,
            ReportingPeriodId = 1,
            Status = "Draft"
        };
        var result = await sut.CreateAsync(request, createdBy: 1);

        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Data);
        Assert.True(result.Data.Id > 0);
        Assert.Equal("Draft", result.Data.Status);
    }

    [Fact]
    public async Task GetByIdAsync_Found_ReturnsData()
    {
        await using var db = CreateContext();
        await SeedForSubmissionAsync(db);
        db.ReportSubmissions.Add(new ReportSubmission
        {
            Id = 100,
            FormDefinitionId = 1,
            FormVersionId = 1,
            OrganizationId = 1,
            ReportingPeriodId = 1,
            Status = "Draft",
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 1
        });
        await db.SaveChangesAsync();
        var sut = new ReportSubmissionService(db);

        var result = await sut.GetByIdAsync(100);

        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Data);
        Assert.Equal(100L, result.Data.Id);
        Assert.Equal("Draft", result.Data.Status);
    }

    [Fact]
    public async Task UpdateAsync_SetStatusToSubmitted_Succeeds()
    {
        await using var db = CreateContext();
        await SeedForSubmissionAsync(db);
        db.ReportSubmissions.Add(new ReportSubmission
        {
            Id = 200,
            FormDefinitionId = 1,
            FormVersionId = 1,
            OrganizationId = 1,
            ReportingPeriodId = 1,
            Status = "Draft",
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 1
        });
        await db.SaveChangesAsync();
        var sut = new ReportSubmissionService(db);

        var result = await sut.UpdateAsync(200, new UpdateReportSubmissionRequest { Status = "Submitted" }, updatedBy: 1);

        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Data);
        Assert.Equal("Submitted", result.Data.Status);
        Assert.NotNull(result.Data.SubmittedAt);
    }

    [Fact]
    public async Task UpdateAsync_SetStatusToApproved_Succeeds()
    {
        await using var db = CreateContext();
        await SeedForSubmissionAsync(db);
        db.ReportSubmissions.Add(new ReportSubmission
        {
            Id = 300,
            FormDefinitionId = 1,
            FormVersionId = 1,
            OrganizationId = 1,
            ReportingPeriodId = 1,
            Status = "Submitted",
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 1
        });
        await db.SaveChangesAsync();
        var sut = new ReportSubmissionService(db);

        var result = await sut.UpdateAsync(300, new UpdateReportSubmissionRequest { Status = "Approved" }, updatedBy: 1);

        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Data);
        Assert.Equal("Approved", result.Data.Status);
    }

    [Fact]
    public async Task UpdateAsync_SetStatusToRejected_Succeeds()
    {
        await using var db = CreateContext();
        await SeedForSubmissionAsync(db);
        db.ReportSubmissions.Add(new ReportSubmission
        {
            Id = 400,
            FormDefinitionId = 1,
            FormVersionId = 1,
            OrganizationId = 1,
            ReportingPeriodId = 1,
            Status = "Submitted",
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 1
        });
        await db.SaveChangesAsync();
        var sut = new ReportSubmissionService(db);

        var result = await sut.UpdateAsync(400, new UpdateReportSubmissionRequest { Status = "Rejected" }, updatedBy: 1);

        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Data);
        Assert.Equal("Rejected", result.Data.Status);
    }
}
