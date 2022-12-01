import { Controller } from "@hotwired/stimulus"

function slugify(value: string): string {
    return value
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9 ]/g, '')
        .replace(/\s+/g, '-')
}

export default class extends Controller {
    static targets = ["output"]
    declare readonly outputTarget: HTMLInputElement

    make(event: Event) {
        const el = event.target as HTMLInputElement
        this.outputTarget.value = slugify(el.value)
    }
}