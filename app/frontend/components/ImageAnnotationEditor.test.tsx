// app/frontend/components/ImageAnnotationEditor.test.tsx

import { fireEvent, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"
import ImageAnnotationEditor from "./ImageAnnotationEditor"

const asset = { annotation: { focal_x: 0.5, focal_y: 0.5, label: "Subject" }, id: 1, saveUrl: "/save", title: "Portrait", url: "/image.png" }
const context = { arc: vi.fn(), beginPath: vi.fn(), clearRect: vi.fn(), drawImage: vi.fn(), fill: vi.fn(), fillStyle: "", lineWidth: 0, strokeRect: vi.fn(), strokeStyle: "" }

beforeEach(() => {
  vi.spyOn(HTMLCanvasElement.prototype, "getContext").mockReturnValue(context as unknown as CanvasRenderingContext2D)
  vi.stubGlobal("Image", class { onload = () => undefined; set src(_value: string) { this.onload() } })
})
afterEach(() => { vi.restoreAllMocks(); vi.unstubAllGlobals() })

describe("ImageAnnotationEditor", () => {
  it("supports responsive pointer and keyboard focal changes", () => {
    render(<ImageAnnotationEditor assets={[asset]} />)
    const canvas = screen.getByRole("img")
    vi.spyOn(canvas, "getBoundingClientRect").mockReturnValue({ bottom: 450, height: 450, left: 0, right: 800, top: 0, width: 800, x: 0, y: 0, toJSON: () => ({}) })
    fireEvent.pointerDown(canvas, { clientX: 200, clientY: 225 })
    expect(screen.getByLabelText("focal x")).toHaveValue(0.25)
    fireEvent.keyDown(canvas, { key: "ArrowRight" })
    expect(screen.getByLabelText("focal x")).toHaveValue(0.26)
    fireEvent.keyDown(canvas, { key: "Escape" })
  })

  it("persists canonical metadata and reports errors", async () => {
    const user = userEvent.setup(); const fetch = vi.spyOn(globalThis, "fetch")
    fetch.mockResolvedValueOnce(new Response(JSON.stringify({ focal_x: 0.2, focal_y: 0.3, label: "Logo" }), { status: 200 }))
    render(<ImageAnnotationEditor assets={[asset]} />)
    await user.selectOptions(screen.getByLabelText("Label"), "Logo")
    await user.click(screen.getByRole("button", { name: "Save normalized metadata" }))
    expect(await screen.findByRole("status")).toHaveTextContent("saved")
    fetch.mockResolvedValueOnce(new Response(JSON.stringify({ error: "Coordinates invalid" }), { status: 422 }))
    await user.click(screen.getByRole("button", { name: "Save normalized metadata" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Coordinates invalid")
    fetch.mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
    await user.click(screen.getByRole("button", { name: "Save normalized metadata" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Annotation could not be saved")
  })

  it("draws an optional normalized region and edits every fallback field", async () => {
    const user = userEvent.setup(); const region = { ...asset, annotation: { focal_x: 0.5, focal_y: 0.5, label: "Product", region_height: 0.2, region_width: 0.3, region_x: 0.1, region_y: 0.2 } }
    render(<ImageAnnotationEditor assets={[region]} />)
    expect(context.strokeRect).toHaveBeenCalled()
    for (const label of ["focal y", "region x", "region y", "region width", "region height"]) {
      await user.clear(screen.getByLabelText(label)); await user.type(screen.getByLabelText(label), "0.4")
    }
    const canvas = screen.getByRole("img")
    fireEvent.keyDown(canvas, { key: "ArrowLeft" }); fireEvent.keyDown(canvas, { key: "ArrowUp" }); fireEvent.keyDown(canvas, { key: "ArrowDown" })
    expect(screen.getByLabelText("region height")).toHaveValue(0.4)
  })

  it("supports image replacement selection and empty state", async () => {
    const user = userEvent.setup(); const second = { ...asset, id: 2, title: "Replacement", url: "/two.png" }
    const { rerender } = render(<ImageAnnotationEditor assets={[asset, second]} />)
    await user.selectOptions(screen.getByLabelText("Image"), "2")
    expect(screen.getByLabelText("Image")).toHaveValue("2")
    rerender(<ImageAnnotationEditor assets={[]} />)
    expect(screen.getByText("No synthetic image assets are available.")).toBeVisible()
  })

  it("uses the canonical focal fallback when stored values are absent", () => {
    const absent = { ...asset, annotation: { focal_x: null, focal_y: null, label: "Subject" } as unknown as typeof asset.annotation }
    render(<ImageAnnotationEditor assets={[absent]} />)
    expect(context.arc).toHaveBeenCalledWith(400, 225, 9, 0, Math.PI * 2)
  })
})
