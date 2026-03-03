import { test, expect } from '@playwright/test'

/**
 * E2E trang Ủy quyền người dùng (UserDelegationsPage).
 * Sprint 5 S5.4 – UserDelegation UX + CRUD E2E.
 * Chạy: npm run test:e2e (trong src/bcdt-web). Cần BE API tại http://localhost:5080.
 *
 * Điều kiện: tài khoản admin (username=admin, password=Admin@123) tồn tại,
 * và có ít nhất 2 user active trong DB.
 */
test.describe('S5.3/S5.4 Ủy quyền người dùng (UserDelegationsPage)', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login')
    await page.getByPlaceholder('Tên đăng nhập').fill('admin')
    await page.getByPlaceholder('Mật khẩu').fill('Admin@123')
    await page.getByRole('button', { name: 'Đăng nhập' }).click()
    await expect(page).toHaveURL(/\/(organizations|$)/, { timeout: 15000 })
  })

  test('Mở trang – tiêu đề và nút Thêm ủy quyền', async ({ page }) => {
    await page.goto('/user-delegations')
    await expect(page.getByRole('heading', { name: 'Ủy quyền người dùng' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Thêm ủy quyền' })).toBeVisible()
    await expect(page.getByRole('table')).toBeVisible()
  })

  test('Mở trang – bảng có cột Người ủy quyền và Người nhận (tên, không phải ID)', async ({ page }) => {
    await page.goto('/user-delegations')
    const table = page.getByRole('table')
    await expect(table).toBeVisible()
    // Kiểm tra header cột tên thay vì ID
    await expect(table.getByRole('columnheader', { name: 'Người ủy quyền' })).toBeVisible()
    await expect(table.getByRole('columnheader', { name: 'Người nhận' })).toBeVisible()
    await expect(table.getByRole('columnheader', { name: 'Trạng thái' })).toBeVisible()
  })

  test('Mở modal Thêm ủy quyền – form đầy đủ các trường', async ({ page }) => {
    await page.goto('/user-delegations')
    await page.getByRole('button', { name: 'Thêm ủy quyền' }).click()
    const dialog = page.getByRole('dialog')
    await expect(dialog.getByText('Thêm ủy quyền')).toBeVisible()
    await expect(dialog.getByLabel('Người ủy quyền')).toBeVisible()
    await expect(dialog.getByLabel('Người nhận ủy quyền')).toBeVisible()
    await expect(dialog.getByLabel('Loại ủy quyền')).toBeVisible()
    await expect(dialog.getByLabel('Thời gian hiệu lực')).toBeVisible()
    // Nút Tạo và Hủy
    await expect(dialog.getByRole('button', { name: 'Tạo' })).toBeVisible()
    await expect(dialog.getByRole('button', { name: 'Hủy' })).toBeVisible()
  })

  test('Đóng modal bằng nút Hủy', async ({ page }) => {
    await page.goto('/user-delegations')
    await page.getByRole('button', { name: 'Thêm ủy quyền' }).click()
    await expect(page.getByRole('dialog')).toBeVisible()
    await page.getByRole('dialog').getByRole('button', { name: 'Hủy' }).click()
    await expect(page.getByRole('dialog')).toBeHidden({ timeout: 5000 })
  })
})
