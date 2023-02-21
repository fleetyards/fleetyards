Cypress.Commands.add("visitApp", (url) => {
  cy.visit(url);
  cy.document().then((document) => {
    const node = document.createElement("style");
    node.innerHTML = "html { scroll-behavior: inherit !important; }";
    document.body.appendChild(node);
  });
});

Cypress.Commands.add("selectElement", (id, options = {}) =>
  cy.get(`[data-test="${id}"]`, options)
);
Cypress.Commands.add("selectInput", (id) =>
  cy.get(`[data-test="input-${id}"]`)
);

Cypress.Commands.add("confirmAccess", (password) => {
  cy.selectInput("password").type(password);

  cy.selectElement("submit-confirm-access").click();

  cy.selectElement("confirm-access").should("not.exist");
});

Cypress.Commands.add("waitForPageToLoad", () => {
  cy.selectElement(`loader`).should("not.exist");
});

Cypress.Commands.add("clickNav", (name, subName = null) => {
  cy.selectElement(`nav-${name}`).click();

  if (subName) {
    cy.selectElement(`nav-${subName}`, { timeout: 10000 }).then(($subMenu) => {
      cy.get($subMenu).click();
    });
  }
});

Cypress.Commands.add("acceptConfirm", () => {
  cy.get("#noty-confirm .noty_buttons button:first-child").click();
});

Cypress.Commands.add("cancelConfirm", () => {
  cy.get("#noty-confirm .noty_buttons button:last-child").click();
});

Cypress.Commands.add("alert", (message) => {
  cy.get(".noty_type__error .noty_body", { timeout: 10000 }).then(($noty) => {
    expect($noty).to.contain(message);
  });
});

Cypress.Commands.add("success", (message) => {
  cy.get(".noty_type__success .noty_body", { timeout: 10000 }).then(($noty) => {
    expect($noty).to.contain(message);
    cy.get($noty).click();
  });
});

Cypress.Commands.add("addToHangar", (ship, wanted = false) => {
  cy.get(`.model-panel#${ship} [data-test="add-to-hangar"]`).click();
  if (wanted) {
    cy.get(`[data-test="add-to-hangar-as-wanted"]`).click();
  } else {
    cy.get(`[data-test="add-to-hangar-as-normal"]`).click();
  }
});

Cypress.Commands.add("openContextMenu", (ship) => {
  cy.get(`.fleetchart-item.fleetchart-item-${ship}`).first().click();
});

Cypress.Commands.add("openShipMenuFromContext", (entry = null) => {
  cy.get('[data-test="context-menu"] [data-test="vehicle-menu"]').click();

  if (entry) {
    cy.get(`[data-test="context-menu"] [data-test="vehicle-${entry}"]`).click();
  }
});

Cypress.Commands.add("openShipMenu", (ship, entry = null) => {
  cy.get(`.model-panel.model-panel-${ship} [data-test="vehicle-menu"]`)
    .first()
    .click();

  if (entry) {
    cy.get(`.model-panel.model-panel-${ship} [data-test="vehicle-${entry}"]`)
      .first()
      .click();
  }
});

Cypress.Commands.add("removeShip", () => {
  cy.selectElement("vehicle-remove").click();
});

Cypress.Commands.add("saveShip", () => {
  cy.selectElement("vehicle-save").click();
});

Cypress.Commands.add("acceptCookies", () => {
  cy.selectElement("accept-cookies").should("exist");
  cy.selectElement("accept-cookies").click({ force: true });
  cy.selectElement("accept-cookies").should("not.exist");
});

Cypress.Commands.add("login", () => {
  cy.url().should("include", "/login");

  cy.wait(500);

  cy.fixture("users").then((userData) => {
    cy.selectInput("login").type(userData.test.username);
    cy.selectInput("password").type(userData.test.password);

    cy.selectElement("submit-login").click();

    cy.contains(".user-menu", userData.test.username).should("exist");
  });
});
