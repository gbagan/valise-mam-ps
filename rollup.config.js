import purs from "rollup-plugin-purs";

export default {
    input: "src/Main.purs",
    output: {
        file: "bundle.js",
        format: "iife"
    },
    plugins: [
        purs()
    ]
};