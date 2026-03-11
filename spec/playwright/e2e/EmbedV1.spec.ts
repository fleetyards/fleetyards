describe("EmbedV1", () => {
  it("Default Workflow", () => {
    cy.visitApp("/embed-test");

    cy.get(".model-300i").should("have.length", 1);

    cy.get(".model-300i .top-metrics").should("be.visible");

    cy.selectElement("fleetview-details-button").click();

    cy.get(".model-300i .top-metrics").should("not.be.visible");

    cy.selectElement("fleetview-grouped-button").click();

    cy.get(".model-300i").should("have.length", 2);

    cy.selectElement("fleetview-fleetchart-button").click();

    cy.get(".model-300i").should("have.length", 2);

    cy.selectElement("fleetview-grouped-button").click();

    cy.get(".model-300i").should("have.length", 1);
  });
});
