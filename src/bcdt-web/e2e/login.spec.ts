import { test, expect } from '@playwright/test'

const LOGIN_URL = '/login'
const BASE_URL = 'http://localhost:5173'

test.describe('B6 Login & Auth', () => {
  test('4. Trang đăng nhập có form username, password, nút đăng nhập', async ({ page }) => {
    await page.goto(LOGIN_URL)
    await expect(page.getByPlaceholder('Tên đăng nhập')).toBeVisible()
    await expect(page.getByPlaceholder('Mật khẩu')).toBeVisible()
    await expect(page.getByRole('button', { name: 'Đăng nhập' })).toBeVisible()
  })

  test('5. Login thành công → redirect', async ({ page }) => {
    await page.goto(LOGIN_URL)
    await page.getByPlaceholder('Tên đăng nhập').fill('admin')
    await page.getByPlaceholder('Mật khẩu').fill('Admin@123')
    await page.getByRole('button', { name: 'Đăng nhập' }).click()
    await expect(page).toHaveURL(/\/(organizations|$)/)
  })

  test('8. Chưa đăng nhập vào /organizations → redirect /login', async ({ context, page }) => {
    await context.clearCookies()
    await page.goto(`${BASE_URL}/organizations`)
    await expect(page).toHaveURL(/\/login/)
  })

  test('9. Logout → redirect /login', async ({ page }) => {
    await page.goto(LOGIN_URL)
    await page.getByPlaceholder('Tên đăng nhập').fill('admin')
    await page.getByPlaceholder('Mật khẩu').fill('Admin@123')
    await page.getByRole('button', { name: 'Đăng nhập' }).click()
    await expect(page).toHaveURL(/\/(organizations|$)/)
    await page.locator('header').getByRole('button').last().click()
    await page.getByRole('menuitem', { name: 'Đăng xuất' }).click()
    await expect(page).toHaveURL(/\/login/)
  })
})
