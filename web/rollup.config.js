import resolve from "@rollup/plugin-node-resolve";

export default {
  input: "src/app.js",
  output: [
    {
      format: "esm",
      file: "dist/bundle.js",
    },
  ],
  plugins: [resolve()],
};