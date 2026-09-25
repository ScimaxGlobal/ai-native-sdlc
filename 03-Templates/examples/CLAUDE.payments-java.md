# payments-service

Authorizes and settles card payments for the checkout and invoicing services.

## Commands

| Task | Command | Healthy output |
|---|---|---|
| Build | `./gradlew build -x test` | `BUILD SUCCESSFUL` |
| Test | `./gradlew test integrationTest` | `0 failures` in both reports |
| Lint | `./gradlew spotlessCheck checkstyleMain` | no violations |
| Run locally | `docker compose up -d kafka postgres && ./gradlew bootRun` | `Started PaymentsApplication` |

## Architecture

- Java 21, Spring Boot 3.
- `api/` — REST controllers and DTOs only. No business logic.
- `core/` — domain model and services. No Spring web or Kafka imports here.
- `adapters/` — Postgres repositories, Kafka producers/consumers, card-network clients.
- Kafka message classes are **generated** from `schemas/*.avsc` by `./gradlew generateAvro`. Never hand-edit files under `build/generated/`.

## Conventions

- Money is always `BigDecimal` with an explicit `RoundingMode.HALF_EVEN`. Never `double`/`float`, never `new BigDecimal(double)`.
- Currency travels with the amount (`Money` value object in `core/money`).
- Every REST endpoint has at least one integration test in `src/integrationTest/` using Testcontainers.
- Constructor injection only; no field `@Autowired`.

## Do not

- Do not bump dependency versions. Dependency upgrades go through the platform team's Renovate PRs.
- Do not change anything under `api/v1/` — the v1 API is frozen for external partners. New behavior goes in `api/v2/`.
- Do not log PAN, CVV, or full cardholder names. Use `MaskedCard.toString()`.

## Verification (required before saying "done")

- Build prints `BUILD SUCCESSFUL`; tests and integration tests show `0 failures`; lint clean.
- Run all three and paste the output before reporting complete.
- Never `@Disabled` or delete a failing test. Fix the code; if the test is wrong, stop and say so.

## Common mistakes

- (2026-07-02) Used `BigDecimal.equals` to compare amounts — use `compareTo` (scale differs).
- (2026-08-19) Added a Kafka field in Java instead of the `.avsc` schema — edit the schema and regenerate.

## Workflow artifacts

Intent, spec and plan for each change live in `work/<ID>-<slug>/`. Non-trivial work starts in plan mode.
