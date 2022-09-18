import { Controller } from "@hotwired/stimulus"
import { VNode, Fragment, jsx, toVNode } from "snabbdom"
import Fuse from 'fuse.js'

import data from '../items.json'
import { patch } from "./instance"

const fuse = new Fuse<Data>(data, {
    keys: ["id", "displayName"],
})

interface Data {
    id: number;
    displayName: string;
    name: string;
    stackSize: number;
    enchantCategories?: string[];
    maxDurability?: number;
    repairWith?: string[];
}

export default class extends Controller {
    static targets = ["field", "out"]
    declare readonly fieldTarget: HTMLInputElement
    declare readonly outTarget: HTMLElement

    connect(): void {
        this.fieldTarget.addEventListener("input", (evt) => {
            this.rerender()
        })
        this.rerender()
    }
    rerender() {
        patch(this.outTarget.firstElementChild, this.render())
    }
    render(): VNode {
        if (data.some(item => item.name == this.fieldTarget.value)) {
            return <div></div>
        }

        const results = fuse.search(this.fieldTarget.value)
        return <div class={{"p-2": true, "bg-slate-50": true, "rounded": true, "mt-2": true}}>
            {results.slice(0, 5).map(obj => this.renderRow(obj.item))}
        </div>
    }
    renderRow(row: Data): VNode {
        return <div class={{"px-2": true, "py-1": true}} dataset={{id: row.name, action: "click->itemsel#select"}}>
            {row.displayName}
        </div>
    }
    select(event: Event) {
        const row = event.target as HTMLElement
        this.fieldTarget.value = row.dataset["id"]
        this.rerender()
    }
}