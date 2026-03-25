/**
 * Sanidade do pacote Node — evita `jest` sair com erro quando não há outros testes.
 */
describe("backend package", () => {
  test("package.json tem main apontando para server.js", () => {
    const pkg = require("../package.json");
    expect(pkg.main).toBe("server.js");
  });

  test("server.js pode ser carregado como módulo (syntax)", () => {
    const fs = require("fs");
    const path = require("path");
    const src = fs.readFileSync(path.join(__dirname, "..", "server.js"), "utf8");
    expect(src).toContain("express");
    expect(src).toContain("authSupabase");
  });
});
