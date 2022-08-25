module.exports = {
	content: [
		"Resources/Views/**/*.leaf",
		"Sources/**/*.swift",
	],
	darkMode: 'media',
	theme: {},
	variants: {},
	plugins: [
		require("@tailwindcss/typography"),
		require("@tailwindcss/forms"),
	]
}
