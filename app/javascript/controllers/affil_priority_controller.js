import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mappings", "row"]

  addRow() {
    const index = this.rowTargets.length
    const row = document.createElement("div")
    row.className = "d-flex gap-2 mb-2 align-items-center"
    row.setAttribute("data-affil-priority-target", "row")
    row.innerHTML = `
      <input type="text" name="affil_priority_settings[mappings][${index}][affiliation]"
             class="form-control" style="max-width: 240px;" placeholder="例: faculty">
      <select name="affil_priority_settings[mappings][${index}][priority]" class="form-select" style="width: auto">
        <option value="1">優先度 1</option>
        <option value="2">優先度 2</option>
        <option value="3" selected>優先度 3</option>
        <option value="4">優先度 4</option>
        <option value="5">優先度 5</option>
      </select>
      <button type="button" class="btn btn-outline-danger btn-sm"
              data-action="affil-priority#removeRow">削除</button>
    `
    this.mappingsTarget.appendChild(row)
  }

  removeRow(event) {
    event.currentTarget.closest("[data-affil-priority-target='row']").remove()
    this.#renumberRows()
  }

  #renumberRows() {
    this.rowTargets.forEach((row, i) => {
      row.querySelectorAll("input, select").forEach(el => {
        el.name = el.name.replace(/\[mappings\]\[\d+\]/, `[mappings][${i}]`)
      })
    })
  }
}
