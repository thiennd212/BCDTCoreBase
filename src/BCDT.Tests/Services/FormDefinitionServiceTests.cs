using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using BCDT.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace BCDT.Tests.Services;

public class FormDefinitionServiceTests
{
    private static AppDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    [Fact]
    public async Task CreateAsync_Success_ReturnsFormDefinitionWithValidId()
    {
        await using var db = CreateContext();
        var sut = new FormDefinitionService(db);

        var request = new CreateFormDefinitionRequest
        {
            Code = "FM01",
            Name = "Biểu mẫu 01",
            FormType = "Input"
        };
        var result = await sut.CreateAsync(request, createdBy: 1);

        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Data);
        Assert.True(result.Data.Id > 0);
        Assert.Equal("FM01", result.Data.Code);
        Assert.Equal("Biểu mẫu 01", result.Data.Name);
    }

    [Fact]
    public async Task CreateAsync_DuplicateCode_ReturnsConflict()
    {
        await using var db = CreateContext();
        db.FormDefinitions.Add(new FormDefinition
        {
            Code = "FM01",
            Name = "Existing",
            FormType = "Input",
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 1
        });
        await db.SaveChangesAsync();
        var sut = new FormDefinitionService(db);

        var request = new CreateFormDefinitionRequest
        {
            Code = "FM01",
            Name = "Another",
            FormType = "Input"
        };
        var result = await sut.CreateAsync(request, createdBy: 1);

        Assert.False(result.IsSuccess);
        Assert.Equal("CONFLICT", result.Code);
    }

    [Fact]
    public async Task GetByIdAsync_Found_ReturnsData()
    {
        await using var db = CreateContext();
        db.FormDefinitions.Add(new FormDefinition
        {
            Id = 42,
            Code = "F1",
            Name = "Form 1",
            FormType = "Input",
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 1
        });
        await db.SaveChangesAsync();
        var sut = new FormDefinitionService(db);

        var result = await sut.GetByIdAsync(42);

        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Data);
        Assert.Equal(42, result.Data.Id);
        Assert.Equal("F1", result.Data.Code);
    }

    [Fact]
    public async Task GetByIdAsync_NotFound_ReturnsNotFoundResult()
    {
        await using var db = CreateContext();
        var sut = new FormDefinitionService(db);

        var result = await sut.GetByIdAsync(999);

        Assert.False(result.IsSuccess);
        Assert.Equal("NOT_FOUND", result.Code);
        Assert.Null(result.Data);
    }

    [Fact]
    public async Task GetListPagedAsync_ReturnsCorrectCount()
    {
        await using var db = CreateContext();
        for (int i = 1; i <= 5; i++)
        {
            db.FormDefinitions.Add(new FormDefinition
            {
                Code = $"C{i}",
                Name = $"N{i}",
                FormType = "Input",
                IsDeleted = false,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = 1
            });
        }
        await db.SaveChangesAsync();
        var sut = new FormDefinitionService(db);

        var result = await sut.GetListPagedAsync(null, null, includeInactive: true, pageSize: 2, pageNumber: 1);

        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Data);
        Assert.Equal(2, result.Data.Items.Count);
        Assert.Equal(5, result.Data.TotalCount);
    }
}
