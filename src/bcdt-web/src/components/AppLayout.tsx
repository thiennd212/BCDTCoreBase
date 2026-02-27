import { useState, useMemo, useCallback, useEffect } from 'react'
import { Outlet, useNavigate, useLocation, Link } from 'react-router-dom'
import { Layout, Menu, Button, Typography, Space, Drawer, Dropdown, Avatar, Modal, Radio } from 'antd'
import type { MenuProps } from 'antd'
import {
  MenuOutlined,
  LogoutOutlined,
  TeamOutlined,
  UserOutlined,
  AppstoreOutlined,
  CalendarOutlined,
  DashboardOutlined,
  FileTextOutlined,
  UnorderedListOutlined,
  BookOutlined,
  BellOutlined,
  ApartmentOutlined,
  NodeIndexOutlined,
  ClockCircleOutlined,
  SafetyCertificateOutlined,
  KeyOutlined,
  SettingOutlined,
  FolderOutlined,
  BarChartOutlined,
  FormOutlined,
  SwapOutlined,
} from '@ant-design/icons'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '../context/AuthContext'
import { useIsMobile } from '../hooks/useBreakpoint'
import { menusApi } from '../api/menusApi'
import { authApi } from '../api/authApi'
import type { MenuDto } from '../types/menu.types'
import type { UserRoleItemDto } from '../types/auth.types'

const { Header, Sider, Content, Footer } = Layout
const { Text } = Typography

// Icon map for dynamic rendering
const ICON_MAP: Record<string, React.ReactNode> = {
  DashboardOutlined: <DashboardOutlined />,
  TeamOutlined: <TeamOutlined />,
  UserOutlined: <UserOutlined />,
  FileTextOutlined: <FileTextOutlined />,
  SettingOutlined: <SettingOutlined />,
  SafetyCertificateOutlined: <SafetyCertificateOutlined />,
  KeyOutlined: <KeyOutlined />,
  MenuOutlined: <MenuOutlined />,
  CalendarOutlined: <CalendarOutlined />,
  BellOutlined: <BellOutlined />,
  FolderOutlined: <FolderOutlined />,
  BarChartOutlined: <BarChartOutlined />,
  FormOutlined: <FormOutlined />,
  UnorderedListOutlined: <UnorderedListOutlined />,
  ApartmentOutlined: <ApartmentOutlined />,
  AppstoreOutlined: <AppstoreOutlined />,
  BookOutlined: <BookOutlined />,
  ClockCircleOutlined: <ClockCircleOutlined />,
  NodeIndexOutlined: <NodeIndexOutlined />,
}

type MenuItem = Required<MenuProps>['items'][number]

/** Convert MenuDto tree to Ant Design Menu items */
function buildMenuItems(menus: MenuDto[], onNavigate: (url: string) => void): MenuItem[] {
  return menus
    .filter((m) => m.isVisible)
    .map((menu) => {
      const icon = menu.icon ? ICON_MAP[menu.icon] : undefined
      const hasChildren = menu.children && menu.children.length > 0
      const hasUrl = !!menu.url

      if (hasChildren) {
        // Parent menu with children - use SubMenu
        return {
          key: menu.url || `menu-${menu.id}`,
          icon,
          label: menu.name,
          children: buildMenuItems(menu.children!, onNavigate),
        }
      }

      // Leaf menu item
      return {
        key: menu.url || `menu-${menu.id}`,
        icon,
        label: menu.name,
        onClick: hasUrl ? () => onNavigate(menu.url!) : undefined,
      }
    })
}

export function AppLayout() {
  const { user, logout, currentRole, setCurrentRole } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const queryClient = useQueryClient()
  const isMobile = useIsMobile()
  const [drawerOpen, setDrawerOpen] = useState(false)
  const [openKeys, setOpenKeys] = useState<string[]>([])
  const [switchRoleModalOpen, setSwitchRoleModalOpen] = useState(false)
  const [selectedRoleIndex, setSelectedRoleIndex] = useState<number | null>(null)

  // Fetch menus theo vai trò hiện tại (BE lọc theo RoleMenu)
  const { data: menus = [] } = useQuery({
    queryKey: ['menus-sidebar', currentRole?.id ?? null],
    queryFn: () => menusApi.getAll({ roleId: currentRole?.id }),
    staleTime: 2 * 60 * 1000, // 2 phút
  })

  const handleNavigate = useCallback((url: string) => {
    navigate(url)
    setDrawerOpen(false)
  }, [navigate])

  // Find all URLs for selected key matching (định nghĩa trước menuItems vì menuItems dùng nó)
  const findAllUrls = useCallback((items: MenuDto[]): string[] => {
    const urls: string[] = []
    for (const item of items) {
      if (item.url) urls.push(item.url)
      if (item.children) urls.push(...findAllUrls(item.children))
    }
    return urls
  }, [])

  const allUrls = useMemo(() => findAllUrls(menus), [menus, findAllUrls])

  // Chỉ dùng menu từ database (API), không tự thêm fallback
  const menuItems = useMemo(() => buildMenuItems(menus, handleNavigate), [menus, handleNavigate])

  const selectedKey = (allUrls.includes(location.pathname) || location.pathname === '/system-config')
    ? location.pathname
    : '/dashboard'

  // Find parent keys for current path and set open keys
  const findParentKeys = useCallback((items: MenuDto[], targetUrl: string, parents: string[] = []): string[] => {
    for (const item of items) {
      const itemKey = item.url || `menu-${item.id}`
      if (item.url === targetUrl) return parents
      if (item.children) {
        const found = findParentKeys(item.children, targetUrl, [...parents, itemKey])
        if (found.length > 0) return found
      }
    }
    return []
  }, [])

  // Set initial open keys when menus load or location changes (dùng useEffect, không setState trong useMemo)
  useEffect(() => {
    if (location.pathname === '/system-config') {
      setOpenKeys(prev => (prev.includes('menu-system-group') ? prev : [...prev, 'menu-system-group']))
      return
    }
    if (menus.length > 0) {
      const parentKeys = findParentKeys(menus, location.pathname)
      if (parentKeys.length > 0) {
        setOpenKeys(prev => {
          const next = [...new Set([...prev, ...parentKeys])]
          return next.length === prev.length && next.every((k, i) => k === prev[i]) ? prev : next
        })
      }
    }
  }, [menus, location.pathname, findParentKeys])

  const { data: myRoles = [], isLoading: myRolesLoading } = useQuery({
    queryKey: ['auth', 'my-roles'],
    queryFn: () => authApi.getMyRoles(),
    enabled: switchRoleModalOpen && !!user,
  })

  const handleSwitchRoleConfirm = useCallback(() => {
    if (selectedRoleIndex != null && myRoles[selectedRoleIndex]) {
      setCurrentRole(myRoles[selectedRoleIndex])
      setSwitchRoleModalOpen(false)
      queryClient.invalidateQueries()
      navigate('/dashboard')
    }
  }, [selectedRoleIndex, myRoles, setCurrentRole, queryClient, navigate])

  useEffect(() => {
    if (switchRoleModalOpen) {
      const idx = currentRole
        ? myRoles.findIndex((r) => r.id === currentRole.id && (r.organizationId ?? null) === (currentRole.organizationId ?? null))
        : 0
      setSelectedRoleIndex(idx >= 0 ? idx : (myRoles.length ? 0 : null))
    }
  }, [switchRoleModalOpen, currentRole, myRoles])

  // User dropdown menu items
  const userMenuItems: MenuProps['items'] = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: 'Thông tin tài khoản',
      onClick: () => navigate('/profile'),
    },
    {
      key: 'settings',
      icon: <SettingOutlined />,
      label: 'Cài đặt',
      onClick: () => navigate('/settings'),
    },
    {
      key: 'switch-role',
      icon: <SwapOutlined />,
      label: 'Chuyển vai trò',
      onClick: () => setSwitchRoleModalOpen(true),
    },
    { type: 'divider' },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: 'Đăng xuất',
      danger: true,
      onClick: logout,
    },
  ]

  const menuContent = (
    <Menu
      mode={isMobile ? 'vertical' : 'inline'}
      selectedKeys={[selectedKey]}
      openKeys={openKeys}
      onOpenChange={setOpenKeys}
      items={menuItems}
      style={{ height: '100%', borderRight: 0 }}
    />
  )

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0 16px 0 12px',
          gap: 16,
          position: 'sticky',
          top: 0,
          zIndex: 100,
          boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        }}
      >
        <Space size="middle">
          {isMobile && (
            <Button
              type="text"
              icon={<MenuOutlined />}
              onClick={() => setDrawerOpen(true)}
              aria-label="Mở menu"
            />
          )}
          <Link to="/organizations" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <AppstoreOutlined style={{ fontSize: 20, color: 'var(--ant-color-primary)' }} />
            <Text strong style={{ fontSize: 18, color: '#1f2937' }}>
              BCDT
            </Text>
          </Link>
        </Space>
        <Dropdown menu={{ items: userMenuItems }} placement="bottomRight" trigger={['click']}>
          <Button type="text" style={{ height: 'auto', padding: '4px 8px' }}>
            <Space wrap={false}>
              <Avatar size="small" icon={<UserOutlined />} style={{ backgroundColor: 'var(--ant-color-primary)' }} />
              <Space direction="vertical" size={0} style={{ lineHeight: 1.2, alignItems: 'flex-start' }}>
                <Text style={{ fontSize: 13, maxWidth: 150 }} ellipsis>
                  {user?.fullName ?? user?.username}
                </Text>
                {currentRole && (
                  <Text type="secondary" style={{ fontSize: 11 }}>
                    {currentRole.organizationName ? `${currentRole.name} (${currentRole.organizationName})` : currentRole.name}
                  </Text>
                )}
              </Space>
            </Space>
          </Button>
        </Dropdown>
      </Header>

      <Layout>
        {!isMobile && (
          <Sider
            width={220}
            breakpoint="lg"
            collapsedWidth={0}
            style={{ background: '#fff', borderRight: '1px solid #e5e7eb' }}
          >
            {menuContent}
          </Sider>
        )}

        <Drawer
          title="Danh mục"
          placement="left"
          open={drawerOpen}
          onClose={() => setDrawerOpen(false)}
          styles={{ body: { padding: 0 } }}
          size={260}
        >
          {menuContent}
        </Drawer>

        <Modal
          title="Chuyển vai trò"
          open={switchRoleModalOpen}
          onCancel={() => setSwitchRoleModalOpen(false)}
          onOk={handleSwitchRoleConfirm}
          okText="Áp dụng"
          cancelText="Hủy"
          destroyOnClose
        >
          <Typography.Paragraph type="secondary" style={{ marginBottom: 16 }}>
            Chọn vai trò hiển thị (áp dụng cho phiên làm việc hiện tại).
          </Typography.Paragraph>
          {myRolesLoading ? (
            <Typography.Text type="secondary">Đang tải...</Typography.Text>
          ) : myRoles.length === 0 ? (
            <Typography.Text type="secondary">Bạn chưa được gán vai trò nào.</Typography.Text>
          ) : (
            <Radio.Group
              value={selectedRoleIndex}
              onChange={(e) => setSelectedRoleIndex(e.target.value)}
              style={{ width: '100%', display: 'flex', flexDirection: 'column', gap: 8 }}
            >
              {myRoles.map((r: UserRoleItemDto, index: number) => (
                <Radio key={index} value={index}>
                  <span>{r.organizationName ? `${r.name} (${r.organizationName})` : r.name}</span>
                  <Typography.Text type="secondary" style={{ marginLeft: 8, fontSize: 12 }}>
                    ({r.code})
                  </Typography.Text>
                </Radio>
              ))}
            </Radio.Group>
          )}
        </Modal>

        <Content
          style={{
            padding: '24px',
            minHeight: 'calc(100vh - 56px - 64px)',
            overflow: 'auto',
          }}
        >
          <Outlet />
        </Content>
      </Layout>

      <Footer
        style={{
          textAlign: 'center',
          padding: '16px 24px',
          borderTop: '1px solid #e5e7eb',
          background: '#fff',
        }}
      >
        <Text type="secondary" style={{ fontSize: 12 }}>
          BCDT © {new Date().getFullYear()} – Hệ thống báo cáo
        </Text>
      </Footer>
    </Layout>
  )
}
