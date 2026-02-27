import { useEffect, type RefObject } from 'react'

const FOCUS_DELAY_MS = 150

/**
 * Khi modal mở, focus vào trường nhập đầu tiên (input/select không disabled) trong container.
 * Gọi sau khi modal đã render (delay nhỏ).
 */
export function useFocusFirstInModal(open: boolean, containerRef: RefObject<HTMLElement | null>): void {
  useEffect(() => {
    if (!open) return
    const t = setTimeout(() => {
      const el = containerRef.current?.querySelector<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>(
        'input:not([disabled]):not([type="hidden"]), select:not([disabled]), textarea:not([disabled])'
      )
      el?.focus()
    }, FOCUS_DELAY_MS)
    return () => clearTimeout(t)
  }, [open, containerRef])
}
