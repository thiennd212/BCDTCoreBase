using BCDT.Application.Common;
using BCDT.Application.DTOs.Workflow;
using BCDT.Application.Services.Notification;
using BCDT.Application.Services.Workflow;
using BCDT.Domain.Entities.Data;
using BCDT.Domain.Entities.Organization;
using BCDT.Domain.Entities.Workflow;
using BCDT.Infrastructure.Persistence;
using BCDT.Infrastructure.Services.Workflow;
using Hangfire;
using Microsoft.EntityFrameworkCore;
using Moq;
using Xunit;

namespace BCDT.Tests.Services;

public class WorkflowExecutionServiceTests
{
    private static AppDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static WorkflowExecutionService CreateSut(AppDbContext db, IFormWorkflowConfigService? configService = null)
    {
        configService ??= new Mock<IFormWorkflowConfigService>().Object;
        var notificationService = new Mock<INotificationService>();
        var backgroundJobs = new Mock<IBackgroundJobClient>();
        return new WorkflowExecutionService(db, configService, notificationService.Object, backgroundJobs.Object);
    }

    private static Mock<IFormWorkflowConfigService> ConfigReturning(int wfId)
    {
        var mock = new Mock<IFormWorkflowConfigService>();
        mock.Setup(s => s.GetWorkflowDefinitionIdForFormAsync(It.IsAny<int>(), It.IsAny<int?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Ok<int?>(wfId));
        return mock;
    }

    private static Mock<IFormWorkflowConfigService> ConfigReturningNoConfig()
    {
        var mock = new Mock<IFormWorkflowConfigService>();
        mock.Setup(s => s.GetWorkflowDefinitionIdForFormAsync(It.IsAny<int>(), It.IsAny<int?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result.Ok<int?>(null));
        return mock;
    }

    private static Organization MakeOrganization(int id = 1, int orgTypeId = 1) => new()
    {
        Id = id,
        Code = $"ORG{id}",
        Name = $"Org {id}",
        OrganizationTypeId = orgTypeId,
        TreePath = $"/{id}",
        Level = 1,
    };

    private static WorkflowDefinition MakeWorkflowDefinition(int id = 1, byte totalSteps = 1) => new()
    {
        Id = id,
        Code = $"WF{id}",
        Name = $"Workflow {id}",
        TotalSteps = totalSteps,
        IsActive = true,
        CreatedAt = DateTime.UtcNow,
        CreatedBy = 1,
    };

    private static ReportSubmission MakeSubmission(long id = 1, string status = "Draft", int orgId = 1, int formDefId = 1, int? submittedBy = null) => new()
    {
        Id = id,
        FormDefinitionId = formDefId,
        FormVersionId = 1,
        OrganizationId = orgId,
        ReportingPeriodId = 1,
        Status = status,
        SubmittedBy = submittedBy,
        CreatedAt = DateTime.UtcNow,
        CreatedBy = 1,
        IsDeleted = false,
    };

    private static WorkflowInstance MakeInstance(int id = 1, string status = "Pending", long submissionId = 1, int wfDefId = 1, byte currentStep = 1) => new()
    {
        Id = id,
        SubmissionId = submissionId,
        WorkflowDefinitionId = wfDefId,
        CurrentStep = currentStep,
        Status = status,
        StartedAt = DateTime.UtcNow,
        CreatedBy = 1,
    };

    // ── SubmitSubmissionAsync ────────────────────────────────────────────────

    [Fact]
    public async Task SubmitAsync_SubmissionNotFound_ReturnsNotFound()
    {
        await using var db = CreateContext();
        var sut = CreateSut(db);

        var result = await sut.SubmitSubmissionAsync(submissionId: 999, submittedBy: 1);

        Assert.False(result.IsSuccess);
        Assert.Equal("NOT_FOUND", result.Code);
    }

    [Fact]
    public async Task SubmitAsync_NotDraft_ReturnsValidationFailed()
    {
        await using var db = CreateContext();
        db.Organizations.Add(MakeOrganization());
        db.ReportSubmissions.Add(MakeSubmission(status: "Submitted"));
        await db.SaveChangesAsync();
        var sut = CreateSut(db);

        var result = await sut.SubmitSubmissionAsync(submissionId: 1, submittedBy: 1);

        Assert.False(result.IsSuccess);
        Assert.Equal("VALIDATION_FAILED", result.Code);
    }

    [Fact]
    public async Task SubmitAsync_NoWorkflowConfig_ReturnsNotFound()
    {
        await using var db = CreateContext();
        db.Organizations.Add(MakeOrganization());
        db.ReportSubmissions.Add(MakeSubmission());
        await db.SaveChangesAsync();
        var sut = CreateSut(db, ConfigReturningNoConfig().Object);

        var result = await sut.SubmitSubmissionAsync(submissionId: 1, submittedBy: 1);

        Assert.False(result.IsSuccess);
        Assert.Equal("NOT_FOUND", result.Code);
    }

    [Fact]
    public async Task SubmitAsync_Valid_CreatesInstanceAndUpdatesSubmission()
    {
        await using var db = CreateContext();
        db.Organizations.Add(MakeOrganization());
        db.WorkflowDefinitions.Add(MakeWorkflowDefinition());
        db.ReportSubmissions.Add(MakeSubmission());
        await db.SaveChangesAsync();
        var sut = CreateSut(db, ConfigReturning(wfId: 1).Object);

        var result = await sut.SubmitSubmissionAsync(submissionId: 1, submittedBy: 5);

        Assert.True(result.IsSuccess);
        Assert.Equal("Pending", result.Data!.Status);
        var sub = await db.ReportSubmissions.FindAsync(1L);
        Assert.Equal("Submitted", sub!.Status);
        Assert.Equal(5, sub.SubmittedBy);
        Assert.Equal(1, await db.WorkflowInstances.CountAsync());
    }

    // ── ApproveAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task ApproveAsync_InstanceNotFound_ReturnsNotFound()
    {
        await using var db = CreateContext();
        var sut = CreateSut(db);

        var result = await sut.ApproveAsync(workflowInstanceId: 999, approverId: 1, request: null);

        Assert.False(result.IsSuccess);
        Assert.Equal("NOT_FOUND", result.Code);
    }

    [Fact]
    public async Task ApproveAsync_NotPending_ReturnsValidationFailed()
    {
        await using var db = CreateContext();
        db.WorkflowDefinitions.Add(MakeWorkflowDefinition());
        db.ReportSubmissions.Add(MakeSubmission(status: "Submitted", submittedBy: 1));
        db.WorkflowInstances.Add(MakeInstance(status: "Approved"));
        await db.SaveChangesAsync();
        var sut = CreateSut(db);

        var result = await sut.ApproveAsync(workflowInstanceId: 1, approverId: 2, request: null);

        Assert.False(result.IsSuccess);
        Assert.Equal("VALIDATION_FAILED", result.Code);
    }

    [Fact]
    public async Task ApproveAsync_FinalStep_SetsApprovedStatus()
    {
        await using var db = CreateContext();
        db.WorkflowDefinitions.Add(MakeWorkflowDefinition(totalSteps: 1));
        db.ReportSubmissions.Add(MakeSubmission(status: "Submitted", submittedBy: 5));
        db.WorkflowInstances.Add(MakeInstance(currentStep: 1)); // TotalSteps=1, so this is final
        await db.SaveChangesAsync();
        var sut = CreateSut(db);

        var result = await sut.ApproveAsync(workflowInstanceId: 1, approverId: 2, request: null);

        Assert.True(result.IsSuccess);
        Assert.Equal("Approved", result.Data!.Status);
        var sub = await db.ReportSubmissions.FindAsync(1L);
        Assert.Equal("Approved", sub!.Status);
        Assert.Equal(2, sub.ApprovedBy);
        var approval = await db.WorkflowApprovals.FirstAsync();
        Assert.Equal("Approve", approval.Action);
    }

    // ── RejectAsync ──────────────────────────────────────────────────────────

    [Fact]
    public async Task RejectAsync_InstanceNotFound_ReturnsNotFound()
    {
        await using var db = CreateContext();
        var sut = CreateSut(db);

        var result = await sut.RejectAsync(workflowInstanceId: 999, approverId: 1, request: null);

        Assert.False(result.IsSuccess);
        Assert.Equal("NOT_FOUND", result.Code);
    }

    [Fact]
    public async Task RejectAsync_Pending_SetsRejectedStatus()
    {
        await using var db = CreateContext();
        db.WorkflowDefinitions.Add(MakeWorkflowDefinition());
        db.ReportSubmissions.Add(MakeSubmission(status: "Submitted", submittedBy: 5));
        db.WorkflowInstances.Add(MakeInstance());
        await db.SaveChangesAsync();
        var sut = CreateSut(db);

        var result = await sut.RejectAsync(workflowInstanceId: 1, approverId: 3,
            request: new WorkflowActionRequest { Comments = "Sai dữ liệu" });

        Assert.True(result.IsSuccess);
        Assert.Equal("Rejected", result.Data!.Status);
        var sub = await db.ReportSubmissions.FindAsync(1L);
        Assert.Equal("Rejected", sub!.Status);
        var approval = await db.WorkflowApprovals.FirstAsync();
        Assert.Equal("Reject", approval.Action);
        Assert.Equal("Sai dữ liệu", approval.Comments);
    }
}
