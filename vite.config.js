import { defineConfig } from "vite"

export default defineConfig({
	root: "./Resources/",
	base: "/Public/",
	build: {
		manifest: true,
		emptyOutDir: true,
		assetsDir: "",
		outDir: "../Public/",
		rollupOptions: {
			input: {
				code: "./Resources/app.js"
			}
		}
	}
})
