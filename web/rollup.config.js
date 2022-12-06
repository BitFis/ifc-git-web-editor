import resolve from "@rollup/plugin-node-resolve";
import copy from 'rollup-plugin-copy'
import styles from "rollup-plugin-styles";

export default {
  input: "src/app.js",
  output: [
    {
      format: "esm",
      file: "dist/public/bundle.js",
      assetFileNames: "[name]-[hash][extname]",
    },
  ],
  plugins: [resolve(),
  copy({
    targets: [
      { src: "node_modules/web-ifc/web-ifc.wasm", dest: 'dist/public' },
      { src: "src/styles.css", dest: 'dist/public' },
      { src: "examples", dest: 'dist/public' },
    ]
  }), styles()
  ],
};