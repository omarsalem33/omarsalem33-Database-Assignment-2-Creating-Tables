# BidNile Online Auctions - Database Design & SQL Server DDL

Simulation Academy - .NET Diploma - Cycle 1 - Individual assignment

**Name:** Omar Salem **Group:** 3

## What is here

```
database/BidNile.sql        Task 2 (CREATE) + Task 3 (ALTER 3.1-3.12), one F5 on a fresh server
database/BidNile_Data.sql   Task 4 - YOU generate it from SSMS (see WALKTHROUGH.md, Part 4)
docs/mapping.png            Task 1 relational mapping, drawn as 4 schema groups
docs/screenshots/           Task 4 error screenshots + Task 5 "Accepted" screenshot (yours)
dsa/ProductExceptSelf.cs    Task 5 - LeetCode 238, both versions
NOTES.md                    Section 03 short answers

```

## The solution in one minute

- **11 tables in 4 schemas:** `Membership` (City, Member, Wallet), `Logistics` (Warehouse, Employee), `Catalog` (Category, Item, ItemPhoto), `Bidding` (Auction, Bid, AuctionFollow). Nothing in `dbo`.
- **Every constraint is named** `PK_`, `UQ_`, `CK_`, `DF_`, `FK_` so Task 3 can drop and replace them.
- **Task 2** has every FK column but no FK constraint. **Task 3.1** adds all 18 FKs; only `ItemPhoto -> Item` cascades.
- **Type decisions:** GUID member key with `DEFAULT NEWID()`, `BIGINT` bid key, `DECIMAL(12,2)` money, `FLOAT` GPS, `DATETIMEOFFSET` auctions, JSON as `NVARCHAR(MAX)` + `CHECK (ISJSON(...) = 1)`.
- **Tricky spots handled:** circular Warehouse/Employee (manager FK added late, manager column nullable), filtered unique index so several warehouses can have no manager yet, Item inspector <> seller, held <= balance, unique `(AuctionId, Amount)` per bid.
- **3.6 and 3.11** fail on purpose first (dependent CHECK / DEFAULT); the script shows the error as a comment and then the fix.

## Workflow (Git)

1. Repo comes from simulationeg.com: do not create or rename it.
2. `git checkout -b <exact branch name from the website>` before touching anything. Never commit to `main`.
3. Commit per task: mapping, CREATE, ALTER, data + screenshots, DSA, notes.
4. Open a PR into `main` using the exact title from the website (copy and paste).

## How to run

Open `database/BidNile.sql` in SSMS 20+ against SQL Server 2019+ and press **F5**. The script drops and recreates `BidNile` if it exists, so it can be re-run.

## Notes about the diagram

`docs/mapping.png` shows the design as created in Task 2 (before Task 3): it still has `IsVerified` and `Capacity`, and `AuctionFollow` is still in Bidding. Redraw it if your instructor wants the final state.
