import { useEffect } from 'react'

/**
 * Khi modal mở, scroll trang chính lên đầu (scroll chính bên ngoài) để modal hiển thị gần cạnh trên,
 * người dùng thấy được nhiều trường thông tin hơn.
 */
export function useScrollPageTopWhenModalOpen(open: boolean): void {
  useEffect(() => {
    if (!open) return
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }, [open])
}
