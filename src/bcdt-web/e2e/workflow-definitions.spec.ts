import { test, expect } from '@playwright/test'

/**
 * E2E trang Quy trình phê duyệt (WorkflowDefinitionsPage).
 * Khớp B9_WORKFLOW.md mục 7.2 – FE Quy trình phê duyệt.
 * Chạy: npm run test:e2e (trong src/bcdt-web). Cần BE API tại http://localhost:5080.
 */
test.describe('B9 FE Quy trình phê duyệt (WorkflowDefinitionsPage)', () => {
  const codeWf = `E2E_WF_${Date.now().toString(36)}`

  test.beforeEach(async ({ page }) => {
    await page.goto('/login')
    await page.getByPlaceholder('Tên đăng nhập').fill('admin')
    await page.getByPlaceholder('Mật khẩu').fill('Admin@123')
    await page.getByRole('button', { name: 'Đăng nhập' }).click()
    await expect(page).toHaveURL(/\/(organizations|$)/)
  })

  test('Mở trang – bảng và nút Thêm quy trình', async ({ page }) => {
    await page.goto('/workflow-definitions')
    await expect(page.getByRole('heading', { name: 'Quy trình phê duyệt' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Thêm quy trình' })).toBeVisible()
    await expect(page.getByRole('table')).toBeVisible()
  })

  test('Thêm quy trình – form và tạo thành công', async ({ page }) => {
    await page.goto('/workflow-definitions')
    await page.getByRole('button', { name: 'Thêm quy trình' }).click()
    await expect(page.getByRole('dialog').getByText('Thêm quy trình')).toBeVisible()
    await page.getByLabel('Mã quy trình').fill(codeWf)
    await page.getByLabel('Tên quy trình').fill('E2E Quy trình test')
    await page.getByLabel('Số bước duyệt').fill('2')
    await page.getByRole('button', { name: 'Tạo' }).click()
    await expect(page.getByText('Tạo quy trình thành công')).toBeVisible({ timeout: 10000 })
    await expect(page.getByRole('dialog')).toBeHidden({ timeout: 5000 })
    await expect(page.getByRole('table')).toBeVisible()
  })

  test('Chọn quy trình – card Các bước duyệt và nút Thêm bước duyệt', async ({ page }) => {
    await page.goto('/workflow-definitions')
    await page.getByRole('button', { name: 'Thêm quy trình' }).click()
    const code = `E2E_SEL_${Date.now().toString(36)}`
    await page.getByLabel('Mã quy trình').fill(code)
    await page.getByLabel('Tên quy trình').fill('Quy trình để chọn')
    await page.getByLabel('Số bước duyệt').fill('1')
    const postDone = page.waitForResponse(
      (r) => r.url().includes('workflow-definitions') && !r.url().includes('/steps') && r.request().method() === 'POST' && r.status() >= 200 && r.status() < 300,
      { timeout: 15000 }
    )
    const listRefetched = page.waitForResponse(
      (r) => r.url().includes('workflow-definitions') && !r.url().includes('/steps') && r.request().method() === 'GET' && r.status() === 200,
      { timeout: 20000 }
    )
    await page.getByRole('button', { name: 'Tạo' }).click()
    await expect(page.getByText('Tạo quy trình thành công')).toBeVisible({ timeout: 10000 })
    await postDone
    await listRefetched
    await page.reload()
    await expect(page.getByRole('table')).toBeVisible()
    for (let i = 0; i < 15; i++) {
      const row = page.getByRole('table').getByRole('row').filter({ hasText: code })
      if (await row.isVisible().catch(() => false)) break
      const nextBtn = page.locator('li.ant-pagination-next').first()
      if (await nextBtn.getAttribute('class').then((c) => c?.includes('ant-pagination-disabled') ?? true)) break
      await nextBtn.click()
      await page.waitForTimeout(400)
    }
    await expect(page.getByRole('table').getByText(code)).toBeVisible({ timeout: 5000 })
    await page.getByRole('table').getByRole('row').filter({ hasText: code }).click()
    await expect(page.getByText('Các bước duyệt')).toBeVisible({ timeout: 5000 })
    await expect(page.getByRole('button', { name: 'Thêm bước duyệt' })).toBeVisible()
  })

  test('Thêm bước duyệt – form và tạo thành công', async ({ page }) => {
    await page.goto('/workflow-definitions')
    await page.getByRole('button', { name: 'Thêm quy trình' }).click()
    const code = `E2E_STEP_${Date.now().toString(36)}`
    await page.getByLabel('Mã quy trình').fill(code)
    await page.getByLabel('Tên quy trình').fill('Quy trình có bước')
    await page.getByLabel('Số bước duyệt').fill('2')
    const postDone = page.waitForResponse(
      (r) => r.url().includes('workflow-definitions') && !r.url().includes('/steps') && r.request().method() === 'POST' && r.status() >= 200 && r.status() < 300,
      { timeout: 15000 }
    )
    const listRefetched = page.waitForResponse(
      (r) => r.url().includes('workflow-definitions') && !r.url().includes('/steps') && r.request().method() === 'GET' && r.status() === 200,
      { timeout: 20000 }
    )
    await page.getByRole('button', { name: 'Tạo' }).click()
    await expect(page.getByText('Tạo quy trình thành công')).toBeVisible({ timeout: 10000 })
    await postDone
    await listRefetched
    await page.reload()
    await expect(page.getByRole('table')).toBeVisible()
    for (let i = 0; i < 15; i++) {
      const row = page.getByRole('table').getByRole('row').filter({ hasText: code })
      if (await row.isVisible().catch(() => false)) break
      const nextBtn = page.locator('li.ant-pagination-next').first()
      if (await nextBtn.getAttribute('class').then((c) => c?.includes('ant-pagination-disabled') ?? true)) break
      await nextBtn.click()
      await page.waitForTimeout(400)
    }
    await expect(page.getByRole('table').getByText(code)).toBeVisible({ timeout: 5000 })
    await page.getByRole('table').getByRole('row').filter({ hasText: code }).click()
    await expect(page.getByRole('button', { name: 'Thêm bước duyệt' })).toBeVisible({ timeout: 5000 })
    await page.getByRole('button', { name: 'Thêm bước duyệt' }).click()
    await expect(page.getByRole('dialog').getByText('Thêm bước duyệt')).toBeVisible()
    await page.getByLabel('Thứ tự bước').fill('1')
    await page.getByLabel('Tên bước').fill('Bước E2E test')
    await page.getByRole('button', { name: 'Tạo' }).click()
    await expect(page.getByText('Tạo bước duyệt thành công')).toBeVisible({ timeout: 10000 })
    await expect(page.getByRole('dialog')).toBeHidden({ timeout: 5000 })
    await expect(page.getByText('Bước E2E test')).toBeVisible({ timeout: 10000 })
  })
})
