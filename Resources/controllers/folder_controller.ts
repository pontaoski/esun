import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

export default class extends Controller {
    static targets = ["stack", "escape"]
    declare readonly hasStackTarget: boolean
    declare readonly stackTarget: HTMLElement
    declare readonly escapeTarget: HTMLElement

    updateEscape() {
        if (!this.hasStackTarget)
            return

        let text = this.stackTarget.lastElementChild?.previousElementSibling?.firstElementChild?.textContent
        if (text != null) {
            this.escapeTarget.textContent = `ESC: ${text}`
        } else {
            this.escapeTarget.textContent = `ESC: Nothing`
        }
    }
    handleEscapeKey(event: KeyboardEvent) {
        event = event || window.event as KeyboardEvent

        let isEscape = false
        if ("key" in event) {
            isEscape = (event.key === "Escape" || event.key === "Esc")
        } else {
            isEscape = (event.keyCode === 27)
        }

        if (isEscape) {
            this.popOne()
        }
    }
    connect() {
        this.updateEscape()
        document.addEventListener("keydown", (evt) => this.handleEscapeKey(evt))
    }
    disconnect() {
        document.removeEventListener("keydown", (evt) => this.handleEscapeKey(evt))
    }
    push(event: Event) {
        event.preventDefault()
        const el = event.target as HTMLAnchorElement

        const it = document.createElement("turbo-frame")
        it.setAttribute("src", el.href)
        it.setAttribute("id", el.dataset["id"]!)
        it.classList.add("folder")

        this.stackTarget.appendChild(it)

        Turbo.visit(el.href)
    }
    popOne() {
        if (this.stackTarget.firstElementChild == this.stackTarget.lastElementChild)
            return

        let rem = this.stackTarget.lastElementChild
        if (rem != null) {
            this.stackTarget.removeChild(rem)
        }

        rem = this.stackTarget.lastElementChild!
        if ("src" in (rem as any)) {
            Turbo.visit((rem as any).src)
        }
    }
    pop(event: Event) {
        event.preventDefault()
        const el = event.target as HTMLAnchorElement
        const id = el.dataset["id"]
        let rem: HTMLElement

        while (rem = this.stackTarget.lastElementChild as HTMLElement) {
            if (rem.getAttribute("id") === id || rem.getAttribute("src") === el.href || rem === this.stackTarget.firstElementChild) {
                Turbo.visit(el.href)
                break
            } else {
                this.stackTarget.removeChild(rem)
            }
        }
    }
}