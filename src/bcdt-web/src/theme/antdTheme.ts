import type { ThemeConfig } from 'antd'

/**
 * Theme Ant Design BCDT – hiện đại, cân đối, đầy đủ khối, responsive.
 * Dùng cho toàn bộ UI (login, layout, đơn vị, user). DevExpress chỉ dùng cho module Excel.
 */
export const bcdtAntdTheme: ThemeConfig = {
  token: {
    colorPrimary: '#1668dc',
    colorSuccess: '#52c41a',
    colorWarning: '#faad14',
    colorError: '#ff4d4f',
    colorInfo: '#1668dc',
    colorText: '#1f2937',
    colorTextSecondary: '#6b7280',
    colorBorder: '#e5e7eb',
    colorBgLayout: '#f8fafc',
    colorBgContainer: '#ffffff',
    colorBgElevated: '#ffffff',
    borderRadius: 8,
    borderRadiusLG: 10,
    fontFamily:
      "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif",
    fontSize: 14,
    fontSizeHeading1: 28,
    fontSizeHeading2: 22,
    fontSizeHeading3: 18,
    lineHeight: 1.5715,
    controlHeight: 40,
    padding: 16,
    paddingContentVerticalLG: 24,
    paddingContentHorizontalLG: 24,
    boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
    boxShadowSecondary: '0 4px 6px -1px rgba(0, 0, 0, 0.08), 0 2px 4px -2px rgba(0, 0, 0, 0.06)',
  },
  components: {
    Layout: {
      headerBg: '#ffffff',
      headerHeight: 56,
      siderBg: '#ffffff',
      bodyBg: '#f8fafc',
    },
    Card: {
      borderRadiusLG: 10,
      boxShadowTertiary: '0 1px 3px 0 rgba(0, 0, 0, 0.06), 0 1px 2px -1px rgba(0, 0, 0, 0.06)',
    },
    Table: {
      headerBg: '#f8fafc',
      headerColor: '#374151',
    },
    Menu: {
      itemBorderRadius: 6,
      itemSelectedBg: '#eff6ff',
      itemSelectedColor: '#1668dc',
      itemHoverColor: '#1668dc',
    },
    Button: {
      primaryShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
      borderRadius: 8,
    },
    Input: {
      activeBorderColor: '#1668dc',
      hoverBorderColor: '#60a5fa',
      borderRadius: 8,
    },
  },
}
