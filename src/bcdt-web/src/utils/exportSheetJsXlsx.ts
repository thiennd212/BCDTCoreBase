/**
 * Export FortuneSheet data ra file Excel (.xlsx) bằng SheetJS (xlsx).
 * Tạo file chuẩn OOXML, mở bằng Excel không báo "Removed Part: styles" / "Repaired Records".
 * Chỉ ghi dữ liệu (giá trị ô), không style/merge/border.
 */

import * as XLSX from 'xlsx'
import type { Sheet } from '@fortune-sheet/core'

/** Lấy giá trị hiển thị từ ô FortuneSheet (Cell | null). */
function cellDisplayValue(cell: { v?: string | number | boolean; m?: string | number } | null): string | number | boolean | undefined {
  if (cell == null) return undefined
  const m = cell.m
  if (m !== undefined && m !== null && m !== '') return typeof m === 'number' ? m : String(m)
  const v = cell.v
  if (v !== undefined && v !== null) return v
  return undefined
}

/**
 * Chuyển một sheet FortuneSheet thành mảng 2 chiều (AOA) để ghi Excel.
 * Hỗ trợ cả .data (CellMatrix) và .celldata (sparse).
 */
function sheetToAoa(sheet: Sheet): (string | number | boolean | undefined)[][] {
  const data = sheet.data
  if (data != null && Array.isArray(data) && data.length > 0) {
    return data.map((row) => {
      if (row == null || !Array.isArray(row)) return []
      return row.map((cell) => cellDisplayValue(cell))
    })
  }
  const celldata = sheet.celldata
  if (celldata != null && Array.isArray(celldata) && celldata.length > 0) {
    let maxR = 0
    let maxC = 0
    for (const item of celldata) {
      if (item.r > maxR) maxR = item.r
      if (item.c > maxC) maxC = item.c
    }
    const rows: (string | number | boolean | undefined)[][] = []
    for (let r = 0; r <= maxR; r++) {
      const row: (string | number | boolean | undefined)[] = []
      for (let c = 0; c <= maxC; c++) row.push(undefined)
      rows.push(row)
    }
    for (const item of celldata) {
      const val = cellDisplayValue(item.v ?? null)
      if (rows[item.r] != null) rows[item.r][item.c] = val
    }
    return rows
  }
  return []
}

/**
 * Tạo file Excel (blob) từ danh sách sheet FortuneSheet.
 * @param sheets - Mảng sheet từ ref.getAllSheets() hoặc state
 */
export function exportFortuneSheetsToXlsxBlob(sheets: Sheet[]): Blob {
  const wb = XLSX.utils.book_new()
  for (const sheet of sheets) {
    const aoa = sheetToAoa(sheet)
    if (aoa.length === 0) {
      XLSX.utils.book_append_sheet(wb, XLSX.utils.aoa_to_sheet([[]]), sheet.name ?? 'Sheet1')
      continue
    }
    const ws = XLSX.utils.aoa_to_sheet(aoa)
    XLSX.utils.book_append_sheet(wb, ws, sheet.name ?? 'Sheet1')
  }
  const bookType: XLSX.BookType = 'xlsx'
  const wopts: XLSX.WritingOptions = { bookType, type: 'array' }
  const arr = XLSX.write(wb, wopts)
  return new Blob([arr], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
}

/**
 * Tải xuống file Excel từ FortuneSheet.
 * Gọi sau khi có ref: ref.current?.getAllSheets() -> exportFortuneSheetsToXlsxBlob -> saveAs.
 */
export function downloadFortuneSheetsAsXlsx(
  sheets: Sheet[],
  baseFileName: string = 'export'
): void {
  const blob = exportFortuneSheetsToXlsxBlob(sheets)
  const name = baseFileName.replace(/\.xlsx$/i, '') + '.xlsx'
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = name
  a.click()
  URL.revokeObjectURL(url)
}
