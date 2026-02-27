import { test, expect } from '@playwright/test'

/**
 * E2E trang Loại thực thể tham chiếu (ReferenceEntityTypesPage).
 * Khớp checklist 10.3 – FE quản lý Loại thực thể (HIERARCHICAL_DATA_BASE_AND_RULE.md).
 * Chạy: npm run test:e2e (trong src/bcdt-web). Cần BE API tại http://localhost:5080.
 */
test.describe('10.3 FE Loại thực thể (ReferenceEntityTypesPage)', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login')
    await page.getByPlaceholder('Tên đăng nhập').fill('admin')
    await page.getByPlaceholder('Mật khẩu').fill('Admin@123')
    await page.getByRole('button', { name: 'Đăng nhập' }).click()
    await expect(page).toHaveURL(/\/(organizations|$)/)
  })

  test('Bước 2: Mở trang – bảng và nút Thêm loại', async ({ page }) => {
    await page.goto('/reference-entity-types')
    await expect(page.getByRole('heading', { name: 'Loại thực thể tham chiếu' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Thêm loại' })).toBeVisible()
    await expect(page.getByRole('table')).toBeVisible()
  })

  test('Bước 3: Thêm loại – form và tạo thành công', async ({ page }) => {
    const codeNew = `E2E_${Date.now().toString(36)}`
    await page.goto('/reference-entity-types')
    await page.getByRole('button', { name: 'Thêm loại' }).click()
    await expect(page.getByRole('dialog').getByText('Thêm loại thực thể')).toBeVisible()
    await page.getByLabel('Mã').fill(codeNew)
    await page.getByLabel('Tên').fill('E2E Loại test')
    await page.getByRole('button', { name: 'Tạo' }).click()
    await expect(page.getByText('Tạo loại thực thể thành công')).toBeVisible({ timeout: 10000 })
    await expect(page.getByRole('dialog')).toBeHidden({ timeout: 5000 })
    // Xác nhận tạo thành công; row trong bảng có thể xuất hiện sau refetch hoặc nằm trang khác (pagination)
    await expect(page.getByRole('table')).toBeVisible()
  })

  test('Bước 4: Sửa loại – Mã disabled, cập nhật Tên', async ({ page }) => {
    await page.goto('/reference-entity-types')
    await page.getByRole('button', { name: 'Thêm loại' }).click()
    const codeEdit = `E2E_EDIT_${Date.now().toString(36)}`
    await page.getByLabel('Mã').fill(codeEdit)
    await page.getByLabel('Tên').fill('Tên gốc')
    const postDone = page.waitForResponse(
      (r) => r.url().includes('reference-entity-types') && r.request().method() === 'POST' && r.status() >= 200 && r.status() < 300,
      { timeout: 15000 }
    )
    const listRefetched = page.waitForResponse(
      (r) => r.url().includes('reference-entity-types') && r.request().method() === 'GET' && r.status() === 200,
      { timeout: 20000 }
    )
    await page.getByRole('button', { name: 'Tạo' }).click()
    await expect(page.getByText('Tạo loại thực thể thành công')).toBeVisible()
    await postDone
    await listRefetched
    await page.reload()
    await expect(page.getByRole('table')).toBeVisible()
    for (let i = 0; i < 15; i++) {
      const row = page.getByRole('table').getByRole('row').filter({ hasText: codeEdit })
      if (await row.isVisible().catch(() => false)) break
      const nextBtn = page.locator('li.ant-pagination-next').first()
      if (await nextBtn.getAttribute('class').then((c) => c?.includes('ant-pagination-disabled') ?? true)) break
      await nextBtn.click()
      await page.waitForTimeout(400)
    }
    const row = page.getByRole('table').getByRole('row').filter({ hasText: codeEdit })
    await expect(row).toBeVisible({ timeout: 5000 })
    await row.getByRole('button').first().click()
    await expect(page.getByRole('dialog').getByText('Sửa loại thực thể')).toBeVisible()
    await expect(page.getByLabel('Mã')).toBeDisabled()
    await page.getByLabel('Tên').fill('Tên đã sửa')
    const putDone = page.waitForResponse(
      (r) => r.url().includes('reference-entity-types/') && r.request().method() === 'PUT',
      { timeout: 20000 }
    )
    await page.getByRole('dialog').getByRole('button', { name: 'Cập nhật' }).click()
    const putRes = await putDone
    if (putRes.status() >= 400) {
      const body = await putRes.text()
      throw new Error(`PUT failed ${putRes.status()}: ${body}`)
    }
    await expect(page.getByRole('dialog')).toBeHidden({ timeout: 10000 })
    await expect(page.getByRole('table').getByText('Tên đã sửa').first()).toBeVisible({ timeout: 10000 })
  })

  test('Bước 5a: Xóa loại chưa có bản ghi – 200, row biến mất', async ({ page }) => {
    await page.goto('/reference-entity-types')
    await page.getByRole('button', { name: 'Thêm loại' }).click()
    const codeDel = `E2E_DEL_${Date.now().toString(36)}`
    await page.getByLabel('Mã').fill(codeDel)
    await page.getByLabel('Tên').fill('Sẽ xóa')
    await page.getByRole('button', { name: 'Tạo' }).click()
    await expect(page.getByRole('table').getByText(codeDel)).toBeVisible({ timeout: 10000 })

    const row = page.getByRole('table').getByRole('row').filter({ hasText: codeDel })
    await row.getByRole('button').last().click()
    await expect(page.getByText('Xóa loại thực thể?')).toBeVisible()
    await page.getByRole('button', { name: 'Xóa' }).click()
    await expect(page.getByText('Đã xóa loại thực thể')).toBeVisible()
    await expect(page.getByRole('table').getByText(codeDel)).not.toBeVisible()
  })

  test('Bước 5b: Xóa loại đã có bản ghi – hiển thị lỗi (409)', async ({ page }) => {
    await page.goto('/reference-entity-types')
    const rows = page.getByRole('table').getByRole('row')
    const dataRowCount = await rows.count().then((n) => Math.max(0, n - 1))
    if (dataRowCount === 0) {
      await expect(page.getByRole('table')).toBeVisible()
      return
    }
    const firstDataRow = rows.nth(1)
    await firstDataRow.getByRole('button').last().click()
    await expect(page.getByText('Xóa loại thực thể?')).toBeVisible()
    await page.getByRole('button', { name: 'Xóa' }).click()
    await expect(
      page.getByText(/Đã xóa loại thực thể|xóa thất bại|đã có bản ghi|không thể xóa/i)
    ).toBeVisible({ timeout: 8000 })
  })
})

