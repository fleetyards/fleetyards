describe("EmbedV2Username", () => {
  it("Default Workflow", () => {
    cy.visitApp("/embed-v2-username-test");

    cy.get(".model-freelancer").should("have.length", 1);

    cy.get(".model-freelancer .top-metrics").should("be.visible");

    cy.selectElement("fleetview-details-button").click();

    cy.get(".model-freelancer .top-metrics").should("not.be.visible");

    cy.selectElement("fleetview-grouped-button").click();

    cy.get(".model-freelancer").should("have.length", 2);

    cy.selectElement("fleetview-fleetchart-button").click();

    cy.get(".model-freelancer").should("have.length", 2);

    cy.selectElement("fleetview-grouped-button").click();

    cy.get(".model-freelancer").should("have.length", 1);
  });
});
