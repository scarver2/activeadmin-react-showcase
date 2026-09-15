// app/frontend/components/ImageAnnotationEditor.test.tsx

import { fireEvent, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"
import ImageAnnotationEditor from "./ImageAnnotationEditor"

const edit = { brightness: 1, contrast: 1, crop_height: 1, crop_width: 1, crop_x: 0, crop_y: 0, flip_x: false, flip_y: false, grayscale: false, rotation: 0, saturation: 1, sepia: false }
const asset = { annotation: { edit_specification: edit, focal_x: 0.5, focal_y: 0.5, label: "Subject" }, id: 1, saveUrl: "/save", title: "Workshop study", url: "/image.png" }
const context = {
  arc: vi.fn(), beginPath: vi.fn(), clearRect: vi.fn(), drawImage: vi.fn(), fill: vi.fn(), fillRect: vi.fn(),
  fillStyle: "", filter: "", lineWidth: 0, restore: vi.fn(), rotate: vi.fn(), save: vi.fn(), scale: vi.fn(),
  setLineDash: vi.fn(), strokeRect: vi.fn(), strokeStyle: "", translate: vi.fn()
}

beforeEach(() => {
  vi.spyOn(HTMLCanvasElement.prototype, "getContext").mockReturnValue(context as unknown as CanvasRenderingContext2D)
  vi.stubGlobal("Image", class { naturalHeight = 675; naturalWidth = 1200; onload = () => undefined; set src(_value: string) { this.onload() } })
})
afterEach(() => { vi.restoreAllMocks(); vi.unstubAllGlobals() })

describe("ImageAnnotationEditor", () => {
  it("drags a normalized crop and retains focal pointer and keyboard editing", async () => {
    const user = userEvent.setup()
    render(<ImageAnnotationEditor assets={[asset]} />)
    const canvas = screen.getByRole("img", { name: /Source image editor/ })
    vi.spyOn(canvas, "getBoundingClientRect").mockReturnValue({ bottom: 450, height: 450, left: 0, right: 800, top: 0, width: 800, x: 0, y: 0, toJSON: () => ({}) })
    fireEvent.pointerMove(canvas, { clientX: 100, clientY: 100 })
    fireEvent.pointerDown(canvas, { clientX: 80, clientY: 45, pointerId: 1 })
    fireEvent.pointerMove(canvas, { clientX: 640, clientY: 360, pointerId: 1 })
    fireEvent.pointerUp(canvas, { pointerId: 1 })
    fireEvent.pointerUp(canvas, { pointerId: 1 })
    expect(screen.getByText(/Crop 0.70 × 0.70/)).toBeVisible()
    await user.click(screen.getByRole("button", { name: "Focal-point tool" }))
    fireEvent.pointerDown(canvas, { clientX: 200, clientY: 225 })
    expect(screen.getByLabelText("focal x")).toHaveValue(0.25)
    fireEvent.keyDown(canvas, { key: "ArrowRight" })
    expect(screen.getByLabelText("focal x")).toHaveValue(0.26)
    fireEvent.keyDown(canvas, { key: "Escape" })
    await user.click(screen.getByRole("button", { name: "Crop tool" }))
  })

  it("applies bounded editing controls, aspect presets, reset, and revert", async () => {
    const user = userEvent.setup()
    render(<ImageAnnotationEditor assets={[asset]} />)
    await user.selectOptions(screen.getByLabelText("Crop aspect preset"), "16:9")
    expect(screen.getByText(/Crop 0.80 × 0.80/)).toBeVisible()
    await user.selectOptions(screen.getByLabelText("Crop aspect preset"), "Free")
    await user.click(screen.getByRole("button", { name: "Rotate right" }))
    await user.click(screen.getByRole("button", { name: "Rotate left" }))
    await user.click(screen.getByRole("button", { name: "Flip horizontal" }))
    await user.click(screen.getByRole("button", { name: "Flip vertical" }))
    await user.click(screen.getByLabelText("Grayscale / B&W"))
    await user.click(screen.getByLabelText("Sepia"))
    fireEvent.change(screen.getByRole("slider", { name: "Brightness" }), { target: { value: "1.25" } })
    fireEvent.change(screen.getByRole("slider", { name: "Contrast" }), { target: { value: "1.10" } })
    fireEvent.change(screen.getByRole("slider", { name: "Saturation" }), { target: { value: "0" } })
    expect(screen.getByText("1.25")).toBeVisible()
    await user.click(screen.getByRole("button", { name: "Reset transformations" }))
    expect(screen.getByText(/Crop 1.00 × 1.00/)).toBeVisible()
    await user.click(screen.getByRole("button", { name: "Revert unsaved changes" }))
    expect(screen.getByText("Reverted to the saved recipe.")).toBeVisible()
  })

  it("persists the canonical recipe and reports server failures", async () => {
    const user = userEvent.setup()
    const fetch = vi.spyOn(globalThis, "fetch")
    const saved = { ...asset.annotation, edit_specification: { ...edit, brightness: 1.2, grayscale: true }, label: "Logo" }
    fetch.mockResolvedValueOnce(new Response(JSON.stringify(saved), { status: 200 }))
    render(<ImageAnnotationEditor assets={[asset]} />)
    await user.selectOptions(screen.getByLabelText("Label"), "Logo")
    await user.click(screen.getByLabelText("Grayscale / B&W"))
    fireEvent.change(screen.getByRole("slider", { name: "Brightness" }), { target: { value: "1.2" } })
    await user.click(screen.getByRole("button", { name: "Save edit recipe" }))
    expect(await screen.findByText("Image recipe saved.")).toBeVisible()
    expect(JSON.parse(String(fetch.mock.calls[0][1]?.body))).toMatchObject({ edit_specification: { brightness: "1.2", grayscale: true }, label: "Logo" })
    fetch.mockResolvedValueOnce(new Response(JSON.stringify({ error: "Crop invalid" }), { status: 422 }))
    await user.click(screen.getByRole("button", { name: "Save edit recipe" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Crop invalid")
    fetch.mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
    await user.click(screen.getByRole("button", { name: "Save edit recipe" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Image recipe could not be saved")
  })

  it("draws source annotations and transformed previews", () => {
    const region = { ...asset, annotation: { ...asset.annotation, edit_specification: { ...edit, flip_x: true, flip_y: true, grayscale: true, rotation: 90, sepia: true }, region_height: 0.2, region_width: 0.3, region_x: 0.1, region_y: 0.2 } }
    render(<ImageAnnotationEditor assets={[region]} />)
    expect(context.strokeRect).toHaveBeenCalled()
    expect(context.setLineDash).toHaveBeenCalledWith([12, 8])
    expect(context.rotate).toHaveBeenCalledWith(Math.PI / 2)
    expect(context.scale).toHaveBeenCalledWith(-1, -1)
    expect(context.filter).toContain("grayscale(1) sepia(1)")
  })

  it("edits annotation fields, changes assets, and renders the empty state", async () => {
    const user = userEvent.setup()
    const second = { ...asset, id: 2, title: "Replacement", url: "/two.png" }
    const { rerender } = render(<ImageAnnotationEditor assets={[asset, second]} />)
    for (const label of ["focal y", "region x", "region y", "region width", "region height"]) {
      await user.clear(screen.getByLabelText(label)); await user.type(screen.getByLabelText(label), "0.4")
    }
    await user.selectOptions(screen.getByLabelText("Image"), "2")
    expect(screen.getByLabelText("Image")).toHaveValue("2")
    rerender(<ImageAnnotationEditor assets={[]} />)
    expect(screen.getByText("No synthetic image assets are available.")).toBeVisible()
  })

  it("uses canonical fallbacks when optional values are absent", () => {
    const absent = { ...asset, annotation: { focal_x: null, focal_y: null, label: "Subject" } as unknown as typeof asset.annotation }
    render(<ImageAnnotationEditor assets={[absent]} />)
    expect(context.arc).toHaveBeenCalledWith(400, 225, 9, 0, Math.PI * 2)
    expect(context.filter).toContain("brightness(1)")
  })
})
