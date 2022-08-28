module.exports = {
	content: [
		"Resources/Views/**/*.leaf",
		"Sources/**/*.swift",
	],
	darkMode: 'media',
	theme: {
		extend: {
			backgroundImage: {
				'gradient-radial-from-top': 'radial-gradient(ellipse at top, var(--tw-gradient-stops))'
			}
		}
	},
	variants: {},
	plugins: [
		require("@tailwindcss/typography"),
		require("@tailwindcss/forms"),
	]
}
