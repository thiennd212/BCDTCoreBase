# Task S2.5 BE – UserDelegation API (ủy quyền tạm thời)

**Ngày:** 2026-02-27
**Kết quả:** ✅ DONE – Build Pass
**Size:** MEDIUM (6 files mới)

## Việc đã làm

1. **Entity** `src/BCDT.Domain/Entities/Authorization/UserDelegation.cs`:
   - Properties: Id, FromUserId, ToUserId, DelegationType (Full|Partial), Permissions (string? JSON), OrganizationId?, Reason?, ValidFrom, ValidTo, IsActive, CreatedAt, CreatedBy, RevokedAt?, RevokedBy?, RevokedReason?

2. **AppDbContext.cs**: `DbSet<UserDelegation>`, EF mapping `ToTable("BCDT_UserDelegation")`, FK to User (From/To) + Organization, index `(ToUserId, IsActive)`

3. **DTOs** `src/BCDT.Application/DTOs/Authorization/UserDelegationDto.cs`:
   - `UserDelegationDto`, `CreateUserDelegationRequest`, `RevokeUserDelegationRequest`

4. **Interface** `src/BCDT.Application/Services/Authorization/IUserDelegationService.cs`

5. **Service** `src/BCDT.Infrastructure/Services/Authorization/UserDelegationService.cs`:
   - Validation: self-delegate, ValidTo>ValidFrom, Partial cần Permissions, user active, overlap conflict
   - Soft-revoke: IsActive=false + RevokedAt/By/Reason

6. **Controller** `src/BCDT.Api/Controllers/ApiV1/UserDelegationsController.cs`:
   - GET /user-delegations?fromUserId=&toUserId=&activeOnly=
   - GET /user-delegations/{id}
   - POST /user-delegations
   - DELETE /user-delegations/{id} (revoke)

7. **DI** trong Program.cs: `AddScoped<IUserDelegationService, UserDelegationService>()`

## DB Migration cần chạy

```sql
ALTER TABLE BCDT_UserDelegation ADD ... (script thủ công qua MCP)
```
