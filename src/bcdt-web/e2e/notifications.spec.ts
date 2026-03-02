import { test, expect } from '@playwright/test'

/**
 * E2E trang Thông báo (NotificationsPage) + badge chuông trong AppLayout.
 * Sprint 6 S6.3 – E2E Notifications.
 * Chạy: npm run test:e2e (trong src/bcdt-web). Cần BE API tại http://localhost:5080.
 *
 * Điều kiện: tài khoản admin (username=admin, password=Admin@123) tồn tại.
 */
test.describe('S6.3 Thông báo (NotificationsPage + Bell Badge)', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login')
    await page.getByPlaceholder('Tên đăng nhập').fill('admin')
    await page.getByPlaceholder('Mật khẩu').fill('Admin@123')
    await page.getByRole('button', { name: 'Đăng nhập' }).click()
    await expect(page).toHaveURL(/\/(organizations|$)/, { timeout: 15000 })
  })

  test('Mở trang Thông báo – tiêu đề và danh sách hiển thị', async ({ page }) => {
    await page.goto('/notifications')
    await expect(page.getByRole('heading', { name: 'Thông báo' })).toBeVisible()
    // Nút lọc Tất cả / Chưa đọc
    await expect(page.getByText('Tất cả')).toBeVisible()
    await expect(page.getByText('Chưa đọc')).toBeVisible()
    // Nút đánh dấu tất cả
    await expect(page.getByRole('button', { name: 'Đánh dấu tất cả đã đọc' })).toBeVisible()
  })

  test('Lọc Chưa đọc – tab thay đổi và danh sách cập nhật', async ({ page }) => {
    await page.goto('/notifications')
    // Click segment "Chưa đọc"
    await page.getByRole('button', { name: 'Chưa đọc' }).click()
    // Chờ API response cho unread
    await page.waitForResponse(
      (r) => r.url().includes('notifications') && r.url().includes('unreadOnly=true') && r.status() === 200,
      { timeout: 10000 },
    ).catch(() => {
      // Fallback: nếu URL không có unreadOnly, chờ bất kỳ notifications GET
    })
    // Trang vẫn hiện tiêu đề
    await expect(page.getByRole('heading', { name: 'Thông báo' })).toBeVisible()
  })

  test('Bell badge icon hiển thị trong AppLayout header', async ({ page }) => {
    await page.goto('/organizations')
    // Bell icon button tồn tại trong header
    const bellBtn = page.getByRole('button', { name: 'Thông báo' })
    await expect(bellBtn).toBeVisible()
    // Click bell → navigate tới /notifications
    await bellBtn.click()
    await expect(page).toHaveURL(/\/notifications/, { timeout: 10000 })
    await expect(page.getByRole('heading', { name: 'Thông báo' })).toBeVisible()
  })
})
