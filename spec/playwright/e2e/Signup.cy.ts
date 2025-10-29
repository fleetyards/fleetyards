import { app, appFactories, appScenario } from "../support/on-rails";
import { test, expect } from "../support/commands";

test.describe("Signup", () => {
  test.beforeEach(async ({ page, acceptCookie }) => {
    await app("clean");

    await page.goto("/");

    await acceptCookie.accept();
  });

  test("Allows Signup/Login/Account deletion", async ({
    page,
    nav,
    notification,
  }) => {
    await nav.click("login");

    await expect(page).toHaveURL(/\/login/);

    await page.getByTestId("signup-link").click();

    await expect(page).toHaveURL(/\/sign-up/);

    await appFactories([["build", "user"]]).then(async ([user]) => {
      await page.locator("input[name='username']").fill(user.username);
      await page.locator("input[name='email']").fill(user.email);
      await page.locator("input[name='password']").fill(user.password);
      await page
        .locator("input[name='passwordConfirmation']")
        .fill(user.password);
      await page.getByTestId("submit-signup").click();

      await notification.success("Welcome to FleetYards.net");

      await nav.click("login");

      await page.locator("input[name='login']").fill(user.username);
      await page.locator("input[name='password']").fill(user.password);
      await page.getByTestId("submit-login").click();

      await expect(
        page.locator(".user-menu").getByText(user.username),
      ).toBeVisible();

      await nav.click("settings");

      await expect(page).toHaveURL(/\/settings/);
    });
  });

  // cy.get(".tabs a").contains("Account").click();

  // cy.url().should("include", "/settings/account");

  // cy.confirmAccess(userData.new.password);

  // cy.selectInput("username").should("have.value", userData.new.username);
  // cy.selectInput("email").should("have.value", userData.new.email);

  // cy.selectElement("destroy-account").click();

  // cy.acceptConfirm();

  // cy.location("pathname").should("eq", "/");

  // cy.success("Your Account has been destroyed");

  // cy.get("nav a").contains("nav a", "Login").should("exist");

  test("Validates all fields", async ({ page, nav, notification }) => {
    await nav.click("signup");

    await expect(page).toHaveURL(/\/sign-up/);

    await appFactories([["create", "user", { password: "password" }]]).then(
      async ([user]) => {
        const usernameInput = page.getByTestId("input-username");
        await usernameInput.fill(user.username);
        await expect(
          page.locator(".base-input").filter({ has: usernameInput }),
        ).toHaveClass("base-input--with_error");

        const emailInput = page.getByTestId("input-email");
        await emailInput.fill(user.email);
        await expect(
          page.locator(".base-input").filter({ has: emailInput }),
        ).toHaveClass("base-input--with_error");
        const invalidEmail = "foo";
        await emailInput.fill(invalidEmail);
        await expect(
          page.locator(".base-input").filter({ has: emailInput }),
        ).toHaveClass("base-input--with_error");
        await emailInput.fill("test@test.de");
        await expect(
          page.locator(".base-input").filter({ has: emailInput }),
        ).not.toHaveClass("base-input--with_error");

        const passwordInput = page.getByTestId("input-password");
        const tooShortPassword = "foo";
        await passwordInput.fill(tooShortPassword);
        await expect(
          page.locator(".base-input").filter({ has: passwordInput }),
        ).toHaveClass("base-input--with_error");
        await passwordInput.fill("password");
        await expect(
          page.locator(".base-input").filter({ has: passwordInput }),
        ).not.toHaveClass("base-input--with_error");

        await page
          .locator("input[name='passwordConfirmation']")
          .fill(user.password);
      },
    );
  });

  // cy.fixture("users").then((userData) => {
  //   cy.selectInput("username").type(userData.test.username);
  //   cy.selectInput("username")
  //     .parents(".form-input")
  //     .should("have.class", "has-error");

  //   cy.selectInput("email").type("foo").clear();
  //   cy.selectInput("email")
  //     .parents(".form-input")
  //     .should("have.class", "has-error");

  //   cy.selectInput("password").type("bar");
  //   cy.selectInput("password")
  //     .parents(".form-input")
  //     .should("have.class", "has-error");
  //   cy.selectInput("password").clear().type(userData.test.password);
  //   cy.selectInput("password")
  //     .parents(".form-input")
  //     .should("not.have.class", "has-error");

  //   cy.selectInput("passwordConfirmation").type("bar").clear();
  //   cy.selectInput("passwordConfirmation")
  //     .parents(".form-input")
  //     .should("have.class", "has-error");
  //   cy.selectInput("passwordConfirmation").type(userData.test.password);
  //   cy.selectInput("passwordConfirmation")
  //     .parents(".form-input")
  //     .should("not.have.class", "has-error");

  //   cy.selectElement("submit-signup").click();

  test("Validates all fields on submit", async ({
    page,
    nav,
    notification,
  }) => {
    await nav.click("signup");

    await expect(page).toHaveURL(/\/sign-up/);

    await page.getByTestId("submit-signup").click();
  });

  // cy.selectInput("username")
  //   .parents(".form-input")
  //   .should("have.class", "has-error");
  // cy.selectInput("email")
  //   .parents(".form-input")
  //   .should("have.class", "has-error");
  // cy.selectInput("password")
  //   .parents(".form-input")
  //   .should("have.class", "has-error");
  // cy.selectInput("passwordConfirmation")
  //   .parents(".form-input")
  //   .should("have.class", "has-error");
});
