# NOTES.md - BidNile (short answers)

## 1. The 4 schemas, their tables, and why

| Schema         | Tables                      | Why together                                                                  |
| -------------- | --------------------------- | ----------------------------------------------------------------------------- |
| **Membership** | City, Member, Wallet        | Who uses the platform and where they live; a wallet is born with the account. |
| **Logistics**  | Warehouse, Employee         | The physical side: places that hold items and the staff who run them.         |
| **Catalog**    | Category, Item, ItemPhoto   | What is sold and how it is described.                                         |
| **Bidding**    | Auction, Bid, AuctionFollow | How it is sold: timed auctions, offers, followers.                            |

(3.12 later adds a 5th schema, **Marketing**, and moves `AuctionFollow` into it.)
Country is not a table: the business only keeps the 2-letter code (`CHECK ... IN ('EG','SA','AE')`).
Delivery tracking, chat, notifications and the marketing/OKR text are out of scope and have no tables.

### Relationship types

| Type            | Where                                                                                                                        | How it is mapped                                                                                                                                     |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1:1**         | Member - Wallet; Member - Employee                                                                                           | The child's PK _is_ the FK to Member (`Wallet.MemberId`, `Employee.MemberId`): a shared key makes a second wallet impossible.                        |
| **1:N**         | City-Member, City-Warehouse, Warehouse-Employee, Member-Item (seller), Category-Item, Item-Auction, Auction-Bid, Member-Bid  | FK on the "many" side.                                                                                                                               |
| **M:N**         | Member - Auction through **Bid** (many bids allowed, so Bid has its own `BidId`); Member - Auction through **AuctionFollow** | Junction table. Follow uses the composite PK `(MemberId, AuctionId)` so nobody follows twice.                                                        |
| **Recursive**   | Member invited by Member (`InvitedById`); Category parent (`ParentCategoryId`)                                               | FK to its own table, nullable (first member / top-level category). One inviter column = nobody is invited twice.                                     |
| **Circular**    | Warehouse <-> Employee: an employee works in a warehouse, and a warehouse is managed by an employee                          | `Employee.WarehouseId` NOT NULL, `Warehouse.ManagerId` NULL (+ `ManagerSince`). Manager is unique through a filtered unique index.                   |
| **Weak entity** | ItemPhoto                                                                                                                    | Identified by `(ItemId, Position)`, composite PK, FK to Item with `ON DELETE CASCADE`. `Position` is `1..20`, which also enforces "up to 20 photos". |

Also: Item has **two** FKs to Member (seller, inspector) and a CHECK that they differ.

## 2. Data-type choices

- **GUID for Member, BIGINT for Bid.** The phone app creates the member ID before the server sees the request, so it must be globally unique without asking the database: a GUID, with `DEFAULT NEWID()` when the app sends none. Bids arrive in the hundreds of millions per year, and `INT` stops at about 2.1 billion, so `BIGINT IDENTITY`.
- **FLOAT for GPS, DECIMAL for money.** GPS values are measurements, approximate by nature, so a tiny binary rounding error is irrelevant. Money must be exact: `FLOAT` can store 0.1 + 0.2 as 0.30000000000000004. `DECIMAL(12,2)` holds up to 9,999,999,999.99.
- **DATETIMEOFFSET for auctions.** Members are in +02:00, +03:00 and +04:00 and the start/end must keep their offset. `DATETIME2` would drop it. `EndsAt > StartsAt` compares real instants.
- Registration/bid times use `DATETIME2(3)` (milliseconds, no offset needed, stored as UTC through `SYSUTCDATETIME()`).

## 3. Why can't the circular relationship be created inside CREATE TABLE?

`Warehouse` needs `FK -> Employee` and `Employee` needs `FK -> Warehouse`. A FK can only reference a table that already exists, and whichever table is created first has nothing to point to yet. So both tables are created without that FK, and the FK is added later with `ALTER TABLE` (3.1). It also affects data: `Warehouse.ManagerId` must be NULL at first, and filled after the employees exist.

## 4. (The text of question 4 did not come through in the PDF extract - check your copy of the assignment and answer it here.)

## 5. Order the tables were filled, and why

FKs are already on, so a parent must exist before its child:

1. `City` (nothing depends on it first)
2. `Member` - inviters before the members they invited (or leave `InvitedById` empty and fill it in a second pass)
3. `Wallet` (needs Member)
4. `Warehouse` - with `ManagerId` / `ManagerSince` left **NULL**
5. `Employee` (needs Member and Warehouse)
6. Back to `Warehouse`: set `ManagerId` + `ManagerSince` (circular relationship closed)
7. `Category` - parents before children
8. `Item` (Seller, Category, Warehouse, Inspector must exist)
9. `ItemPhoto` (needs Item)
10. `Auction` (needs Item)
11. `Bid` and `AuctionFollow` (need Auction and Member)

## 6. The errors in 3.6 and 3.11

- **3.6**: `ALTER COLUMN MaxItems SMALLINT` fails with _Msg 5074 / 4922_: the CHECK constraint `CK_Warehouse_Capacity` depends on the column. Cause fixed by dropping the CHECK, altering the type, then re-adding the rule (`> 0`, plus `<= 30000`). Smallest type: `TINYINT` max 255 is too small, `SMALLINT` max 32,767 fits 30,000.
- **3.11**: `DROP COLUMN IsVerified` fails with _Msg 5074 / 4922_: the default constraint `DF_Member_IsVerified` is attached. Fixed by dropping that default first, then the column.

## 7. Hand trace of Task 5, input `[1, 2, 3, 4]`

`prefix[i]` = product of everything left of `i`; `suffix[i]` = product of everything right of `i`.

| i   | nums[i] | prefix[i] | suffix[i]  | answer = prefix x suffix |
| --- | ------- | --------- | ---------- | ------------------------ |
| 0   | 1       | 1         | 2x3x4 = 24 | 24                       |
| 1   | 2       | 1         | 3x4 = 12   | 12                       |
| 2   | 3       | 1x2 = 2   | 4          | 8                        |
| 3   | 4       | 1x2x3 = 6 | 1          | 6                        |

Result `[24, 12, 8, 6]`. The O(1)-space version stores the prefixes in `answer` (`[1,1,2,6]`), then walks right to left with a running `suffix` (1, 4, 12, 24) multiplying into each slot.
