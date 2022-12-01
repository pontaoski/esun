import { classModule, styleModule, init, VNode, propsModule } from "snabbdom";

const CAPS_REGEX = /[A-Z]/g;
function updateDataset(oldVnode: VNode, vnode: VNode) {
    const elm = vnode.elm as HTMLElement;
    let oldDataset = oldVnode.data.dataset;
    let dataset = vnode.data.dataset;
    let key;
    if (!oldDataset && !dataset)
        return;
    if (oldDataset === dataset)
        return;
    oldDataset = oldDataset || {};
    dataset = dataset || {};
    for (key in oldDataset) {
        if (!dataset[key]) {
            elm.removeAttribute("data-" + key.replace(CAPS_REGEX, "-$&").toLowerCase());
        }
    }
    for (key in dataset) {
        if (oldDataset[key] !== dataset[key]) {
            elm.setAttribute("data-" + key.replace(CAPS_REGEX, "-$&").toLowerCase(), dataset[key]);
        }
    }
}
export const datasetModule = {
    create: updateDataset,
    update: updateDataset,
};

export const patch = init([classModule, styleModule, datasetModule, propsModule]);

export function createElement(node: VNode): HTMLElement {
    const emptyChild = document.createElement("div")
    patch(emptyChild, node)
    return emptyChild
}
