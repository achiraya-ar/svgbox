export function downloadSvg(svgCode: string, filename: string) {
  const blob = new Blob([svgCode], { type: 'image/svg+xml' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${filename}.svg`
  a.click()
  URL.revokeObjectURL(url)
}

export function copySvgToClipboard(svgCode: string): Promise<void> {
  return navigator.clipboard.writeText(svgCode)
}

export function sanitizeSvg(svgCode: string): string {
  // Basic sanitization - remove script tags and event handlers
  return svgCode
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/on\w+="[^"]*"/gi, '')
    .replace(/on\w+='[^']*'/gi, '')
    .replace(/javascript:/gi, '')
}

/**
 * Background options supported by the export pipeline.
 *  - 'transparent'  : no background fill (PNG alpha = 0, JPEG becomes white)
 *  - 'white'        : solid #ffffff
 *  - 'black'        : solid #000000
 *  - 'checkerboard' : semi-transparent checker pattern (preview only — exported
 *                     PNG keeps the alpha so the checker shows through in
 *                     viewers that honour transparency)
 */
export type ExportBackground =
  | 'transparent'
  | 'white'
  | 'black'
  | 'checkerboard'

export interface ExportOptions {
  width: number
  height: number
  format: 'png' | 'jpeg'
  background: ExportBackground
  /** JPEG quality 0..1 (ignored for PNG). */
  quality?: number
  /** Filename WITHOUT extension. */
  filename: string
}

/**
 * Normalize a raw SVG string so it can be safely rasterized by the browser.
 *
 * The user may paste:
 *   1. A complete `<svg ...>...</svg>`  (most common)
 *   2. Just the inner content without a wrapper  (e.g. `<rect .../>`)
 *   3. A snippet with a `viewBox` but no `width`/`height`
 *
 * This helper:
 *   - Wraps bare inner content in a default `<svg>` so the browser can render it
 *   - Strips any existing `width`/`height` from the root so the caller can set
 *     them deterministically (avoids duplicate-attribute quirks)
 *   - Ensures the `xmlns` namespace is present
 *   - Derives a viewBox from the original width/height if the snippet has none
 *
 * Returns the normalized SVG string.  Throws when the input cannot be turned
 * into a valid SVG.
 */
export function normalizeSvgForExport(
  rawSvg: string,
  targetWidth: number,
  targetHeight: number,
): string {
  let svg = rawSvg.trim()
  if (!svg) throw new Error("SVG is empty")

  const hasRoot = /<svg[\s>]/i.test(svg)

  if (!hasRoot) {
    // Wrap bare inner content in a minimal <svg> so it can be rendered.
    svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${targetWidth} ${targetHeight}">${svg}</svg>`
  } else {
    // Ensure xmlns is present — required for the Image element to parse it
    if (!/xmlns\s*=\s*["']http:\/\/www\.w3\.org\/2000\/svg["']/i.test(svg)) {
      svg = svg.replace(/<svg/i, '<svg xmlns="http://www.w3.org/2000/svg"')
    }
    // Strip any existing width / height from the root so our injected
    // values aren't duplicated (browsers take the last one, but it's
    // safer to have a single source of truth).
    svg = svg.replace(
      /<svg([^>]*)>/i,
      (_match, attrs: string) => {
        const cleaned = attrs
          .replace(/\swidth\s*=\s*["'][^"']*["']/i, "")
          .replace(/\sheight\s*=\s*["'][^"']*["']/i, "")
        return `<svg${cleaned}>`
      },
    )
  }

  // Inject explicit width / height + preserve or default the viewBox.
  const viewBoxMatch = svg.match(/<svg[^>]*\bviewBox\s*=\s*["']([^"']+)["']/i)
  if (!viewBoxMatch) {
    const wh = svg.match(
      /<svg[^>]*\bwidth\s*=\s*["']?(\d+(?:\.\d+)?)/i,
    )
    const hh = svg.match(
      /<svg[^>]*\bheight\s*=\s*["']?(\d+(?:\.\d+)?)/i,
    )
    const w = wh ? parseFloat(wh[1]) : targetWidth
    const h = hh ? parseFloat(hh[1]) : targetHeight
    svg = svg.replace(
      /<svg/i,
      `<svg width="${targetWidth}" height="${targetHeight}" viewBox="0 0 ${w} ${h}"`,
    )
  } else {
    svg = svg.replace(
      /<svg/i,
      `<svg width="${targetWidth}" height="${targetHeight}"`,
    )
  }

  return svg
}

/**
 * Convert a raw SVG string to a raster image and trigger a browser download.
 *
 * Pipeline:
 *  1. Normalize the SVG (wrap bare content, ensure xmlns, set width/height).
 *  2. Serialize to a Blob URL and load it into an offscreen Image.
 *  3. Draw onto a Canvas.  The background is filled before drawImage unless
 *     `background === 'transparent'`.  JPEG is forced onto a white surface
 *     because the format has no alpha channel.
 *  4. Encode via canvas.toDataURL / toBlob and trigger an <a download>.
 */
export async function exportSvgToImage(
  rawSvg: string,
  options: ExportOptions,
): Promise<void> {
  const { width, height, format, background, quality, filename } = options

  const svgWithSize = normalizeSvgForExport(rawSvg, width, height)

  const svgBlob = new Blob([svgWithSize], {
    type: "image/svg+xml;charset=utf-8",
  })
  const svgUrl = URL.createObjectURL(svgBlob)

  const canvas = document.createElement("canvas")
  canvas.width = width
  canvas.height = height
  const ctx = canvas.getContext("2d")
  if (!ctx) throw new Error("Unable to get canvas 2D context")

  try {
    await new Promise<void>((resolve, reject) => {
      const img = new Image()
      img.onload = () => {
        // ── Background ────────────────────────────────────────────────
        // For transparent + PNG: leave the canvas blank so the alpha channel
        // stays 0 and the PNG keeps its see-through pixels.
        // For everything else: fill the surface before drawing the SVG.
        if (!(background === "transparent" && format === "png")) {
          if (background === "white" || format === "jpeg") {
            ctx.fillStyle = "#FFFFFF"
          } else if (background === "black") {
            ctx.fillStyle = "#000000"
          } else {
            // checkerboard → we still need a solid surface for JPEG and a
            // neutral gray for PNG (so the alpha is preserved; the SVG sits
            // on top of this solid color).  The actual checker pattern is only
            // shown in the on-screen preview.
            ctx.fillStyle = "#F1F3F5"
          }
          ctx.fillRect(0, 0, width, height)
        }

        ctx.drawImage(img, 0, 0, width, height)
        resolve()
      }
      img.onerror = () => {
        reject(new Error("Failed to load SVG into image"))
      }
      img.src = svgUrl
    })

    const mime = format === "jpeg" ? "image/jpeg" : "image/png"
    const ext = format === "jpeg" ? "jpg" : "png"

    const dataUrl = canvas.toDataURL(mime, quality)
    const a = document.createElement("a")
    a.download = `${filename}-${width}px.${ext}`
    a.href = dataUrl
    a.click()
  } finally {
    URL.revokeObjectURL(svgUrl)
  }
}
