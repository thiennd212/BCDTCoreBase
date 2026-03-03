import React, { Suspense } from 'react'
import { ConfigProvider } from 'antd'
import viVN from 'antd/locale/vi_VN'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AuthProvider } from './context/AuthContext'
import { RolePermissionsProvider } from './context/RolePermissionsContext'
import { ProtectedRoute } from './components/ProtectedRoute'
import { AppLayout } from './components/AppLayout'
import { PageLoading } from './components/PageLoading'
import { ErrorBoundary } from './components/ErrorBoundary'
import { ErrorPage } from './components/ErrorPage'
import { LoginPage } from './pages/LoginPage'
import { OrganizationsPage } from './pages/OrganizationsPage'
import { UsersPage } from './pages/UsersPage'
import { ReportingPeriodsPage } from './pages/ReportingPeriodsPage'
import { DashboardPage } from './pages/DashboardPage'
import { FormsPage } from './pages/FormsPage'
import { SubmissionsPage } from './pages/SubmissionsPage'
import { bcdtAntdTheme } from './theme/antdTheme'
import './App.css'

// Lazy load trang ít dùng để giảm bundle ban đầu (Perf-10)
const FormConfigPage = React.lazy(() => import('./pages/FormConfigPage').then(m => ({ default: m.FormConfigPage })))
const SubmissionDataEntryPage = React.lazy(() => import('./pages/SubmissionDataEntryPage').then(m => ({ default: m.SubmissionDataEntryPage })))
const IndicatorCatalogsPage = React.lazy(() => import('./pages/IndicatorCatalogsPage').then(m => ({ default: m.IndicatorCatalogsPage })))
const OrganizationTypesPage = React.lazy(() => import('./pages/OrganizationTypesPage').then(m => ({ default: m.OrganizationTypesPage })))
const NotificationsPage = React.lazy(() => import('./pages/NotificationsPage').then(m => ({ default: m.NotificationsPage })))
const WorkflowDefinitionsPage = React.lazy(() => import('./pages/WorkflowDefinitionsPage').then(m => ({ default: m.WorkflowDefinitionsPage })))
const ReportingFrequenciesPage = React.lazy(() => import('./pages/ReportingFrequenciesPage').then(m => ({ default: m.ReportingFrequenciesPage })))
const RolesPage = React.lazy(() => import('./pages/RolesPage').then(m => ({ default: m.RolesPage })))
const PermissionsPage = React.lazy(() => import('./pages/PermissionsPage').then(m => ({ default: m.PermissionsPage })))
const MenusPage = React.lazy(() => import('./pages/MenusPage').then(m => ({ default: m.MenusPage })))
const ReferenceEntitiesPage = React.lazy(() => import('./pages/ReferenceEntitiesPage').then(m => ({ default: m.ReferenceEntitiesPage })))
const ReferenceEntityTypesPage = React.lazy(() => import('./pages/ReferenceEntityTypesPage').then(m => ({ default: m.ReferenceEntityTypesPage })))
const SystemConfigPage = React.lazy(() => import('./pages/SystemConfigPage').then(m => ({ default: m.SystemConfigPage })))
const ProfilePage = React.lazy(() => import('./pages/ProfilePage').then(m => ({ default: m.ProfilePage })))
const SettingsPage = React.lazy(() => import('./pages/SettingsPage').then(m => ({ default: m.SettingsPage })))

// Perf-14: staleTime 1 phút cho query ít đổi (reporting-frequencies, organization-types, forms list…) – giảm refetch không cần thiết
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 0,
      staleTime: 60 * 1000, // 1 phút
    },
  },
})

function AppRoutes() {
  return (
    <Suspense fallback={<PageLoading tip="Đang tải trang..." fullScreen />}>
      <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <AppLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/organizations" replace />} />
        <Route path="organizations" element={<OrganizationsPage />} />
        <Route path="users" element={<UsersPage />} />
        <Route path="reporting-periods" element={<ReportingPeriodsPage />} />
        <Route path="dashboard" element={<DashboardPage />} />
        <Route path="forms" element={<FormsPage />} />
        <Route path="forms/:formId/config" element={<FormConfigPage />} />
        <Route path="indicator-catalogs" element={<IndicatorCatalogsPage />} />
        <Route path="organization-types" element={<OrganizationTypesPage />} />
        <Route path="notifications" element={<NotificationsPage />} />
        <Route path="submissions" element={<SubmissionsPage />} />
        <Route path="submissions/:submissionId/entry" element={<SubmissionDataEntryPage />} />
        <Route path="workflow-definitions" element={<WorkflowDefinitionsPage />} />
        <Route path="reporting-frequencies" element={<ReportingFrequenciesPage />} />
        <Route path="roles" element={<RolesPage />} />
        <Route path="permissions" element={<PermissionsPage />} />
        <Route path="menus" element={<MenusPage />} />
        <Route path="reference-entities" element={<ReferenceEntitiesPage />} />
        <Route path="reference-entity-types" element={<ReferenceEntityTypesPage />} />
        <Route path="system-config" element={<SystemConfigPage />} />
        <Route path="profile" element={<ProfilePage />} />
        <Route path="settings" element={<SettingsPage />} />
        <Route path="403" element={<ErrorPage type="403" />} />
        <Route path="500" element={<ErrorPage type="500" />} />
        <Route path="*" element={<ErrorPage type="404" />} />
      </Route>
      </Routes>
    </Suspense>
  )
}

function App() {
  return (
    <ErrorBoundary>
      <ConfigProvider theme={bcdtAntdTheme} locale={viVN}>
        <QueryClientProvider client={queryClient}>
          <AuthProvider>
            <RolePermissionsProvider>
              <BrowserRouter>
                <AppRoutes />
              </BrowserRouter>
            </RolePermissionsProvider>
          </AuthProvider>
        </QueryClientProvider>
      </ConfigProvider>
    </ErrorBoundary>
  )
}

export default App
