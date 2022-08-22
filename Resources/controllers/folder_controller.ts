import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

export default class extends Controller {
    push(event: Event) {
        event.preventDefault()
        const el = event.target as HTMLAnchorElement

        const it = document.createElement("turbo-frame")
        it.setAttribute("src", el.href)
        it.setAttribute("id", el.dataset["id"]!)
        it.classList.add("folder")

        this.element.appendChild(it)

        Turbo.visit(el.href)
    }
    pop(event: Event) {
        event.preventDefault()
        const el = event.target as HTMLAnchorElement
        const id = el.dataset["id"]
        let rem: HTMLElement
        
        while (rem = this.element.lastElementChild as HTMLElement) {
            if (rem.getAttribute("id") === id || rem.getAttribute("src") === el.href || rem === this.element.firstElementChild) {
                Turbo.visit(el.href)
                break
            } else {
                this.element.removeChild(rem)
            }
        }
    }
}