describe("EmbedV2", () => {
  it("Default Workflow", () => {
    cy.visitApp("/embed-v2-test");

    cy.get(".model-600i-explorer").should("have.length", 1);

    cy.get(".model-600i-explorer .top-metrics").should("be.visible");

    cy.selectElement("fleetview-details-button").click();

    cy.get(".model-600i-explorer .top-metrics").should("not.be.visible");

    cy.selectElement("fleetview-grouped-button").click();

    cy.get(".model-600i-explorer").should("have.length", 2);

    cy.selectElement("fleetview-fleetchart-button").click();

    cy.get(".model-600i-explorer").should("have.length", 2);

    cy.selectElement("fleetview-grouped-button").click();

    cy.get(".model-600i-explorer").should("have.length", 1);
  });
});
