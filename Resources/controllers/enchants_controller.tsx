import { Controller } from "@hotwired/stimulus"
import { Fragment, jsx } from "snabbdom"

import data from '../items.json'
import { createElement, patch } from "./instance"

export default class extends Controller {
    static targets = ["out"]
    declare readonly outTarget: HTMLElement

    nextIndex() {
        let children = Array.from(this.outTarget.children)
        let arr = children.map(child => (child as HTMLElement).dataset["index"]).map(Number)
        if (arr.length < 1) {
            return 0
        }
        return Math.max(...arr) + 1
    }
    add(event: Event) {
        event.preventDefault()

        const index = this.nextIndex()
        const el = <div dataset={{"index": String(index), "controller": "enchantsel"}} class={{"flex": true, "flex-row": true, "space-x-2": true}}>
            <div>
                <input dataset={{"enchantsel-target": "field"}} props={{type: "text", name:`enchants[${index}][name]`}} />
                <div dataset={{"enchantsel-target": "out"}} class={{"absolute": true, "drop-shadow": true}}>
                    <div></div>
                </div>
            </div>
            <input dataset={{"enchantsel-target": "level"}} props={{type: "number", name:`enchants[${index}][level]`}} />
        </div>

        const it = createElement(el)
        this.outTarget.appendChild(it)
    }
}