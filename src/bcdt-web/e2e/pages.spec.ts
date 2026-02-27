import { test, expect } from '@playwright/test'

test.describe('B6 Trang list (sau khi login)', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login')
    await page.getByPlaceholder('Tên đăng nhập').fill('admin')
    await page.getByPlaceholder('Mật khẩu').fill('Admin@123')
    await page.getByRole('button', { name: 'Đăng nhập' }).click()
    await expect(page).toHaveURL(/\/(organizations|$)/)
  })

  test('6. Trang quản lý đơn vị có bảng, nút Thêm đơn vị', async ({ page }) => {
    await page.goto('/organizations')
    await expect(page.getByRole('button', { name: 'Thêm đơn vị' })).toBeVisible()
    await expect(page.getByRole('table')).toBeVisible()
  })

  test('7. Trang quản lý user có bảng, nút Thêm người dùng', async ({ page }) => {
    await page.goto('/users')
    await expect(page.getByRole('button', { name: 'Thêm người dùng' })).toBeVisible()
    await expect(page.getByRole('table')).toBeVisible()
  })
})
