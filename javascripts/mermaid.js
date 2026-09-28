// Initializes Mermaid diagrams on every page (incl. dark/light theme awareness).
document$.subscribe(() => {
  const isDark = document.body.getAttribute("data-md-color-scheme") === "slate";
  mermaid.initialize({
    startOnLoad: true,
    theme: isDark ? "dark" : "default",
    securityLevel: "loose"
  });
  if (typeof mermaid.run === "function") {
    mermaid.run({ nodes: document.querySelectorAll(".mermaid") });
  }
});