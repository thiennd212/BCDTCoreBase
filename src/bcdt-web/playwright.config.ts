import { defineConfig, devices } from '@playwright/test'

/**
 * E2E cho BCDT frontend (FE đã ghép BE).
 * Chạy: npm run test:e2e (trong src/bcdt-web).
 * Yêu cầu: API đang chạy tại http://localhost:5080 (dotnet run --project src/BCDT.Api --launch-profile http).
 * Nếu chưa chạy FE, Playwright sẽ tự start dev server (reuseExistingServer: true nếu đã chạy).
 */
export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: 'list',
  use: {
    baseURL: 'http://localhost:5173',
    trace: 'on-first-retry',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:5173',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
})
