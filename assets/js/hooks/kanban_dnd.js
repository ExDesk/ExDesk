const KanbanDnD = {
  mounted() {
    this.dragging = null

    this.onDragStart = e => {
      const item = e.target.closest("[data-ticket-id]")
      if (!item) return

      const ticketId = item.dataset.ticketId
      const fromColumn = item.dataset.kanbanColumn
      if (!ticketId || !fromColumn) return

      this.dragging = {ticketId, fromColumn}
      e.dataTransfer.effectAllowed = "move"
      e.dataTransfer.setData("text/plain", ticketId)
      item.classList.add("opacity-60")
    }

    this.onDragEnd = e => {
      const item = e.target.closest("[data-ticket-id]")
      if (item) item.classList.remove("opacity-60")
      this.dragging = null
      this.clearDropHighlights()
    }

    this.onDragOver = e => {
      const zone = e.currentTarget
      if (!zone || !this.dragging) return
      e.preventDefault()

      zone.classList.add("ring-2", "ring-primary/30")

      const draggedEl = document.getElementById(`kanban-ticket-${this.dragging.ticketId}`)
      if (!draggedEl) return

      const after = this.getDragAfterElement(zone, e.clientY)
      if (!after) {
        zone.appendChild(draggedEl)
      } else {
        zone.insertBefore(draggedEl, after)
      }
    }

    this.onDrop = e => {
      const zone = e.currentTarget
      if (!zone || !this.dragging) return
      e.preventDefault()

      const toColumn = zone.dataset.kanbanColumn
      const fromColumn = this.dragging.fromColumn
      const ticketId = this.dragging.ticketId

      const fromZone = this.el.querySelector(`[data-kanban-dropzone][data-kanban-column="${fromColumn}"]`)
      const toZone = this.el.querySelector(`[data-kanban-dropzone][data-kanban-column="${toColumn}"]`)

      const payload = {
        ticket_id: ticketId,
        from_column: fromColumn,
        to_column: toColumn,
        from_ordered_ids: fromZone ? this.orderedIds(fromZone) : [],
        to_ordered_ids: toZone ? this.orderedIds(toZone) : [],
      }

      this.pushEvent("kanban_drop", payload)
    }

    this.el.addEventListener("dragstart", this.onDragStart)
    this.el.addEventListener("dragend", this.onDragEnd)

    this.dropzones().forEach(zone => {
      zone.addEventListener("dragover", this.onDragOver)
      zone.addEventListener("drop", this.onDrop)
    })
  },

  destroyed() {
    this.el.removeEventListener("dragstart", this.onDragStart)
    this.el.removeEventListener("dragend", this.onDragEnd)
    this.dropzones().forEach(zone => {
      zone.removeEventListener("dragover", this.onDragOver)
      zone.removeEventListener("drop", this.onDrop)
    })
  },

  dropzones() {
    return Array.from(this.el.querySelectorAll("[data-kanban-dropzone]"))
  },

  clearDropHighlights() {
    this.dropzones().forEach(zone => {
      zone.classList.remove("ring-2", "ring-primary/30")
    })
  },

  orderedIds(zone) {
    return Array.from(zone.children)
      .map(el => el.id)
      .filter(id => id && id.startsWith("kanban-ticket-"))
      .map(id => id.replace("kanban-ticket-", ""))
  },

  getDragAfterElement(container, y) {
    const elements = Array.from(container.querySelectorAll('[id^="kanban-ticket-"]'))
    return elements
      .filter(el => el !== document.querySelector(".opacity-60"))
      .reduce(
        (closest, child) => {
          const box = child.getBoundingClientRect()
          const offset = y - box.top - box.height / 2
          if (offset < 0 && offset > closest.offset) {
            return {offset, element: child}
          }
          return closest
        },
        {offset: Number.NEGATIVE_INFINITY, element: null},
      ).element
  },
}

export default KanbanDnD
