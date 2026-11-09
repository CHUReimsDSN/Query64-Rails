import {
  computeSidebar,
  computeVersion,
  computeIndexMd,
} from "vitepress-bigbang/scripts";

console.log("Compute started...");
computeSidebar();
computeVersion({ mode: 'ruby', fileToReadPath: '../lib/query64/version.rb' });
computeIndexMd();
console.log("🎉 Compute done");
