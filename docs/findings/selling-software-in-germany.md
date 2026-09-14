# Selling Premium Fleet Features in Germany — what the legal form actually requires

Research note for [`premium-fleet-features.md`](../exec-plans/premium-fleet-features.md) D15. Nothing
here is built yet and none of it blocks the plan. It exists so the decisions that *are* being taken now
are taken with the destination in view.

**This is not tax or legal advice.** It is a map of which rules exist so the conversation with a
Steuerberater and, for the consumer-law half, a Fachanwalt, is a short one.

## The core problem

A payment that grants software features is **consideration for a supply**, not a gift. The label on the
button does not decide this — the economic substance does. So the moment "donate and your fleet gets
contracts, events, logistics and tours" is stated as an exchange, it is a sale of an electronically
supplied service (*elektronisch erbrachte Dienstleistung*), regardless of the platform being called a
donation platform.

Everything below follows from that one reclassification.

## Where the exposure sits today

Not uniformly across the four funding links, which is the useful part:

| platform | who is the seller | VAT exposure |
|---|---|---|
| **Patreon** | Patreon, as merchant of record for EU memberships | Collects and remits EU VAT under the deemed-supplier rule for electronically supplied services (Implementing Regulation 282/2011 Art. 9a). Low. |
| **Ko-fi** | Ko-fi for its platform products | Similar in shape; confirm per product, since shop/membership/tip are treated differently. |
| **PayPal** | **you** | A direct supply with nothing in between. This is the exposed path. |
| **Buy Me a Coffee** | **you**, in most configurations | Same. |

The coverage stops at the platform's edge. This is a real argument for the plan's D7 keeping PayPal and
Buy Me a Coffee hand-entered and small rather than building them an automated path — the automated
paths are the ones that scale a liability.

## Umsatzsteuer

**Kleinunternehmerregelung (§ 19 UStG).** Since 1 January 2025 the thresholds are **€25,000** in the
prior year and **€100,000** in the current year, both net. Under them, no VAT is charged and none is
deducted. Exceeding €100,000 mid-year ends the status **immediately**, not at year end — so the
qualifying-amount figure in the plan's D4 and the growth it implies are worth watching against a real
number rather than a feeling.

**Place of supply.** For electronically supplied services the tax follows the *customer*, not the
seller:

- **B2C inside the EU** — taxed at the customer's rate. An EU-wide **€10,000** threshold covers small
  volumes; above it, registration in each destination state is required *or*, in practice, the
  **One-Stop-Shop (OSS)** at the Bundeszentralamt für Steuern, which takes one quarterly return and
  distributes the money. OSS is the entire reason this is survivable without 26 registrations.
- **B2B inside the EU** — **reverse charge**. Requires a valid USt-IdNr, validated against VIES and the
  validation retained, the invoice marked accordingly, and the turnover reported in the
  **Zusammenfassende Meldung**. A fleet is very often not a business, so most of this will be B2C — but
  an org that *is* one will ask.
- **Outside the EU** — generally not taxable in Germany, with the customer's own regime applying.

**Consequence for the product:** customer **location evidence** has to be collected and kept. Nothing
in Fleetyards does this today, and it is the one piece of data collection that a later migration cannot
reconstruct retroactively.

## Invoices

**Mandatory contents (§ 14 UStG)** — full name and address of both parties, the supplier's USt-IdNr or
Steuernummer, issue date, a unique sequential invoice number, quantity and nature of the supply, the
date of supply, the net amount, the rate and amount of tax (or a note on why none applies, e.g. reverse
charge or § 19), and any discounts agreed in advance.

**Kleinbetragsrechnung (§ 33 UStDV)** — simplified contents up to €250 gross.

**E-Rechnung**, the part with dates already running:

| from | obligation |
|---|---|
| 1 Jan 2025 | every German business must be able to **receive** structured e-invoices |
| 1 Jan 2027 | businesses with **> €800,000** prior-year turnover must **issue** them for domestic B2B |
| 1 Jan 2028 | **all** businesses must issue them for domestic B2B |

Accepted formats are **XRechnung** and **ZUGFeRD ≥ 2.0.1** (excluding the MINIMUM and BASIC-WL
profiles). A PDF is not an e-invoice. This applies to domestic **B2B** only — B2C is unaffected — but
"receive" already applies now.

**Retention** — invoices and accounting records under GoBD, in the original format, immutable and
machine-readable for the statutory period. A billing provider that holds them on your behalf does not
discharge the obligation.

## Consumer law — the half that is not about tax

This is the part most likely to be overlooked, because it bites at any revenue, including the first
euro.

- **Widerrufsrecht.** 14 days on distance contracts. For paid digital content it can be extinguished
  only by meeting **§ 356 Abs. 5 BGB**: the consumer expressly consents to performance beginning before
  the period ends *and* confirms they know this loses them the right. Without both, the right survives
  delivery.
- **Widerrufsbutton (§ 356a BGB)** — new, and **already in force**: an electronic withdrawal function
  on the online interface since 28 February 2026 generally, and since **19 June 2026** for traders
  concluding contracts through customer accounts. Fleetyards concludes everything through an account.
- **Kündigungsbutton (§ 312k BGB)** — a subscription concluded online needs a cancellation button that
  is continuously visible and reachable **without logging in**. In force since 2022 and heavily
  litigated.
- **Button-Lösung (§ 312j Abs. 3 BGB)** — the order button must be labelled unambiguously, e.g.
  *"zahlungspflichtig bestellen"*.
- **Preisangabenverordnung** — prices shown to consumers include VAT and say so.
- **Impressum (§ 5 DDG)** — note the DDG replaced the TMG in May 2024; any existing reference is stale.
- **AGB** covering term, renewal, cancellation, what happens to a fleet's data when a subscription ends.

The § 356a and § 312k obligations are the strongest practical argument for the plan's D15 constraint on
copy: **the moment the UI presents a purchase, all of this attaches.** A supporter contribution that
happens to unlock features for a nominated fleet is a materially different thing from a checkout, and
the difference is made in the wording and flow, not in the backend.

## The pragmatic route when this becomes real

**Use a merchant of record.** Paddle, FastSpring, Lemon Squeezy (Stripe-owned since 2024) and similar
become the legal seller: they set the price, collect the VAT at the customer's rate, file and remit it,
and issue compliant invoices. No OSS registration, no per-country thresholds, no VIES handling. Typical
cost is ~5% + a fixed fee, which buys the removal of an entire compliance surface.

Note the distinction: **Stripe Billing is not a merchant of record.** Stripe Tax calculates and helps
file, but you remain the seller and the liable party. That difference is the whole decision.

## What this means for the plan as written

Nothing needs rebuilding, and three things are already right:

1. **Entitlement is decoupled from payment.** `FleetSubscription` has a period and a `source` and says
   nothing about how money arrived, so a merchant of record arrives as a new `source` value plus a
   reconciler beside `Subscriptions::Sync`. D10's enforcement, D11's read and the four capabilities do
   not move.
2. **The exposed platforms are the manual ones.** D7's decision to leave PayPal and Buy Me a Coffee
   hand-entered keeps the liability where it is smallest.
3. **The copy constraint is in D15.** It costs nothing now and cannot be retrofitted, because it is
   what the customer was told they were doing.

One gap worth closing early if this is ever going to be real: **customer location evidence is not
collected anywhere**, and it is the only input above that cannot be reconstructed after the fact.

## Sources

- [§ 19 UStG thresholds from 2025 — IHK Region Stuttgart](https://www.ihk.de/stuttgart/fuer-unternehmen/recht-und-steuern/steuerrecht/umsatzsteuer-national/kleinunternehmerregelung-in-der-umsatzsteuer-1843632)
- [OSS and the €10,000 threshold — IHK München](https://www.ihk-muenchen.de/ratgeber/steuern/umsatzsteuer/oss-ioss/)
- [E-Rechnung FAQ — Bundesfinanzministerium](https://www.bundesfinanzministerium.de/Content/DE/FAQ/e-rechnung.html)
- [E-Rechnung deadlines 2025 / 2027 / 2028](https://www.e-rechnungen.org/e-rechnung-pflicht-fristen)
- [§ 312k BGB Kündigungsbutton — case law overview, Bird & Bird](https://www.twobirds.com/de/insights/2025/germany/k%C3%BCndigungsbutton-nach-%C2%A7-312k-bgb-%E2%80%93-eine-rechtsprechungs%C3%BCbersicht)
- [§ 356a BGB Widerrufsbutton from 2026](https://www.aufrecht.de/beitraege-unserer-anwaelte/wettbewerbsrecht/widerrufsbutton-wird-2026-pflicht-handlungsbedarf-fuer-shops-mit-kundenkonten)
- [Withdrawal rights for digital content — Heuking](https://www.heuking.de/de/news-events/newsletter-fachbeitraege/artikel/vorsicht-bei-widerrufsbelehrungen-bei-digitalen-inhalten-und-dienstleistungen.html)
- [How VAT works for creators on Patreon](https://support.patreon.com/hc/en-us/articles/205259549-How-VAT-works-for-creators-on-Patreon)
- [Platform liability under the deemed supplier rule](https://hellotax.com/blog/vat-on-digital-platforms/)
