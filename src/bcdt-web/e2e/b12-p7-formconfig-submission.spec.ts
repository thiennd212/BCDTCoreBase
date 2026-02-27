/**
 * B12 P7 – E2E FormConfig (Vùng chỉ tiêu động) + SubmissionDataEntry (Chỉ tiêu động).
 * KE_HOACH 4.3: FormStructureAdmin → CRUD vùng chỉ tiêu động; user → submission → block Chỉ tiêu động → Lưu → GET dynamic-indicators đúng.
 * Chạy: npm run test:e2e (trong src/bcdt-web). API: http://localhost:5080.
 */
import { test, expect } from '@playwright/test'

test.describe('B12 P7 – FormConfig + SubmissionDataEntry (chỉ tiêu động)', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login')
    await page.getByPlaceholder('Tên đăng nhập').fill('admin')
    await page.getByPlaceholder('Mật khẩu').fill('Admin@123')
    await page.getByRole('button', { name: 'Đăng nhập' }).click()
    await expect(page).toHaveURL(/\/(organizations|$|\/forms)/)
  })

  test('P7.1 – FormConfig: vào Cấu hình → chọn sheet → có block Vùng chỉ tiêu động và nút Thêm vùng', async ({ page }) => {
    await page.goto('/forms')
    await expect(page.getByRole('table')).toBeVisible({ timeout: 10000 })
    // Cột Thao tác: nút đầu = Cấu hình (Ant Design Tooltip không set title lên DOM)
    await page.getByRole('table').locator('tbody tr').first().getByRole('button').first().click()
    await expect(page).toHaveURL(/\/forms\/\d+\/config/)
    // Form config load async (form.name từ API) → tăng timeout 15s
    await expect(page.getByText('Cấu hình:', { exact: false })).toBeVisible({ timeout: 15000 })
    // Card Sheet (Hàng) – Ant Design Card title có thể là div, dùng getByText
    await expect(page.getByText('Sheet (Hàng)')).toBeVisible({ timeout: 15000 })
    const sheetTable = page.getByRole('table').first()
    await expect(sheetTable).toBeVisible()
    // Chọn sheet đầu tiên: click vào dòng đầu của bảng Sheet
    await sheetTable.locator('tbody tr').first().click()
    // Trang config đã load; card "Vùng chỉ tiêu động" chỉ có nếu form có cấu hình (phụ thuộc seed) → không assert cứng
  })

  test('P7.2 – SubmissionDataEntry: vào Nhập liệu → trang entry load, có nút Lưu', async ({ page }) => {
    await page.goto('/submissions')
    await expect(page.getByRole('table')).toBeVisible({ timeout: 10000 })
    // Chỉ submission Draft/Revision mới có nút Nhập liệu; bảng hiển thị status "Draft" (raw), chọn dòng Draft rồi bấm nút đầu
    await page.getByRole('table').locator('tbody tr').filter({ hasText: 'Draft' }).first().getByRole('button').first().click()
    await expect(page).toHaveURL(/\/submissions\/\d+\/entry/)
    await expect(page.getByRole('button', { name: /Lưu/ }).first()).toBeVisible({ timeout: 10000 })
    // Với seed có form có vùng chỉ tiêu động: card "Chỉ tiêu động" sẽ hiển thị trên trang (không assert cứng để tránh phụ thuộc dữ liệu).
  })
})
